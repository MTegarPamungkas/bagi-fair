// Bagi Fair — receipt OCR Edge Function.
//
// Requires these function secrets (never shipped to the app):
//   GEMINI_API_KEY   free-tier key from https://aistudio.google.com/apikey
//   GEMINI_MODEL     optional, defaults to gemini-2.0-flash
//
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected by Supabase.
// Every request is authenticated, membership-checked, rate-limited per user
// (10 scans/hour), then sent to Gemini. The API key never reaches the client.

import { createClient } from "npm:@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const MAX_IMAGE_BYTES = 6 * 1024 * 1024;
const HOURLY_LIMIT = 10;
const ZERO_DECIMAL = new Set(["IDR", "JPY", "KRW", "VND"]);
const SUPPORTED_MIME = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
]);

type Json = Record<string, unknown>;

function json(body: Json, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

function decimalsFor(currency: string): number {
  return ZERO_DECIMAL.has(currency.toUpperCase()) ? 0 : 2;
}

function toMinor(value: unknown, currency: string): number {
  const numeric = typeof value === "number"
    ? value
    : Number.parseFloat(String(value ?? "").replace(/[^0-9.-]/g, ""));
  if (!Number.isFinite(numeric)) return 0;
  const factor = decimalsFor(currency) === 0 ? 1 : 100;
  return Math.max(0, Math.round(numeric * factor));
}

function normaliseDate(value: unknown): string {
  const raw = String(value ?? "").trim();
  if (!raw) return new Date().toISOString();
  const parsed = new Date(/^\d{4}-\d{2}-\d{2}$/.test(raw) ? `${raw}T12:00:00` : raw);
  if (Number.isNaN(parsed.getTime())) return new Date().toISOString();
  return parsed.toISOString();
}

function stripFence(text: string): string {
  const trimmed = text.trim();
  const fenced = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fenced) return fenced[1].trim();
  const start = trimmed.indexOf("{");
  const end = trimmed.lastIndexOf("}");
  if (start >= 0 && end > start) return trimmed.slice(start, end + 1);
  return trimmed;
}

function buildPrompt(locale: string): string {
  const language = locale === "en" ? "English" : "Indonesian";
  return `You are a meticulous receipt OCR engine for a split-bill app.
Read the attached receipt image and return ONLY a JSON object (no markdown).
Use ${language} for merchant and item names when possible, but keep them faithful to the receipt.

Schema:
{
  "merchant": string,
  "currency": ISO-4217 code (e.g. IDR, USD, EUR, SGD),
  "occurred_at": "YYYY-MM-DD",
  "items": [
    {
      "name": string,
      "quantity": number,
      "unit_price": number,
      "total": number
    }
  ],
  "subtotal": number,
  "tax": number,
  "service": number,
  "total": number,
  "confidence": number between 0 and 1,
  "raw_text": short plain-text transcription (max 1500 chars)
}

Rules:
- All monetary values are in MAJOR units, plain numbers without thousands separators or currency symbols (e.g. 45000, 12.50).
- Sum item totals. Include every purchased line item; ignore loyalty points, change, and payment lines.
- Tax (PB1/PPN/GST/VAT) and service charge are separate fields. Use 0 when absent.
- If a field is unreadable, estimate from context rather than inventing unrelated values.
- total should equal subtotal + tax + service unless the receipt shows a discount or rounding; in that case keep the printed total.
- occurred_at is the printed transaction date; default to today when missing.`;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const geminiKey = Deno.env.get("GEMINI_API_KEY");
  const model = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.0-flash";

  if (!supabaseUrl || !serviceKey) {
    return json({ error: "server_not_configured" }, 500);
  }
  if (!geminiKey) {
    return json({ error: "ai_not_configured", message: "GEMINI_API_KEY missing" }, 503);
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) {
    return json({ error: "unauthorized" }, 401);
  }

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: userData, error: userError } = await admin.auth.getUser(token);
  const user = userData?.user;
  if (userError || !user) {
    return json({ error: "unauthorized" }, 401);
  }

  let payload: Json;
  try {
    payload = await req.json();
  } catch (_) {
    return json({ error: "invalid_json" }, 400);
  }

  const groupId = String(payload.group_id ?? "").trim();
  const mimeType = String(payload.mime_type ?? "image/jpeg").toLowerCase();
  const locale = String(payload.locale ?? "id");
  const imageBase64 = String(payload.image_base64 ?? "");

  if (!groupId || !imageBase64) {
    return json({ error: "missing_fields" }, 400);
  }
  if (!SUPPORTED_MIME.has(mimeType)) {
    return json({ error: "unsupported_image" }, 415);
  }

  let imageBytes: Uint8Array;
  try {
    imageBytes = Uint8Array.from(atob(imageBase64), (char) => char.charCodeAt(0));
  } catch (_) {
    return json({ error: "invalid_image" }, 400);
  }
  if (imageBytes.byteLength === 0) {
    return json({ error: "invalid_image" }, 400);
  }
  if (imageBytes.byteLength > MAX_IMAGE_BYTES) {
    return json({ error: "image_too_large", max_bytes: MAX_IMAGE_BYTES }, 413);
  }

  // Membership check: users may only scan receipts for groups they belong to.
  const { data: membership, error: membershipError } = await admin
    .from("group_members")
    .select("user_id")
    .eq("group_id", groupId)
    .eq("user_id", user.id)
    .is("deleted_at", null)
    .maybeSingle();

  if (membershipError) {
    return json({ error: "membership_check_failed" }, 500);
  }
  if (!membership) {
    return json({ error: "not_a_member" }, 403);
  }

  // Per-user quota, enforced server-side before spending an AI request.
  const { data: quota, error: quotaError } = await admin.rpc("claim_ai_scan", {
    p_user_id: user.id,
    p_limit: HOURLY_LIMIT,
  });
  if (quotaError) {
    return json({ error: "quota_check_failed" }, 500);
  }
  if (!quota?.allowed) {
    return json(
      {
        error: "rate_limited",
        retry_after_seconds: quota?.retry_after_seconds ?? 3600,
      },
      429,
    );
  }

  const prompt = buildPrompt(locale);
  const endpoint =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiKey}`;

  let geminiResponse: Response;
  try {
    geminiResponse = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [
          {
            role: "user",
            parts: [
              { text: prompt },
              {
                inline_data: {
                  mime_type: mimeType,
                  data: imageBase64,
                },
              },
            ],
          },
        ],
        generationConfig: {
          temperature: 0.1,
          topP: 0.9,
          maxOutputTokens: 2048,
          responseMimeType: "application/json",
        },
      }),
    });
  } catch (error) {
    console.error("Gemini request failed", error);
    return json({ error: "ai_unreachable" }, 502);
  }

  if (!geminiResponse.ok) {
    const detail = await geminiResponse.text();
    console.error("Gemini error", geminiResponse.status, detail.slice(0, 500));
    return json({ error: "scan_failed", status: geminiResponse.status }, 502);
  }

  const geminiJson = await geminiResponse.json();
  const text = geminiJson?.candidates?.[0]?.content?.parts
    ?.map((part: Json) => String(part.text ?? ""))
    .join("") ?? "";

  if (!text.trim()) {
    return json({ error: "empty_ai_response" }, 502);
  }

  let parsed: Json;
  try {
    parsed = JSON.parse(stripFence(text));
  } catch (error) {
    console.error("Could not parse AI JSON", String(error), text.slice(0, 400));
    return json({ error: "invalid_ai_response" }, 502);
  }

  const currency = String(parsed.currency ?? "IDR").toUpperCase().slice(0, 3);
  const rawItems = Array.isArray(parsed.items) ? parsed.items : [];

  const items = rawItems
    .map((item: unknown, index: number) => {
      const row = (item ?? {}) as Json;
      const quantityRaw = Number(row.quantity ?? 1);
      const quantity = Number.isFinite(quantityRaw) && quantityRaw > 0
        ? Math.round(quantityRaw)
        : 1;
      const totalMinor = toMinor(row.total, currency);
      const unitMinor = row.unit_price != null
        ? toMinor(row.unit_price, currency)
        : quantity > 0
        ? Math.round(totalMinor / quantity)
        : totalMinor;
      return {
        id: `item_${index}`,
        name: String(row.name ?? `Item ${index + 1}`).trim().slice(0, 160),
        quantity,
        unit_price_minor: unitMinor,
        total_minor: totalMinor > 0 ? totalMinor : unitMinor * quantity,
      };
    })
    .filter((item: Json) => String(item.name).length > 0);

  const subtotalMinor = parsed.subtotal != null
    ? toMinor(parsed.subtotal, currency)
    : items.reduce(
      (sum: number, item: Json) => sum + Number(item.total_minor ?? 0),
      0,
    );
  const taxMinor = toMinor(parsed.tax, currency);
  const serviceMinor = toMinor(parsed.service, currency);
  const printedTotal = toMinor(parsed.total, currency);

  return json({
    merchant: String(parsed.merchant ?? "").trim().slice(0, 160),
    currency,
    occurred_at: normaliseDate(parsed.occurred_at),
    items,
    subtotal_minor: subtotalMinor,
    tax_minor: taxMinor,
    service_minor: serviceMinor,
    total_minor: printedTotal > 0
      ? printedTotal
      : subtotalMinor + taxMinor + serviceMinor,
    raw_text: String(parsed.raw_text ?? "").slice(0, 2000),
    confidence: Math.min(
      1,
      Math.max(0, Number(parsed.confidence ?? 0.7) || 0.7),
    ),
    quota: { used: quota?.used ?? null, limit: HOURLY_LIMIT },
  });
});
