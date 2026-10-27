# Bagi Fair — cloud / RLS smoke test against the linked Supabase project.
#
# Creates two throwaway users, exercises the real REST API, then deletes them.
# Requires: supabase CLI linked, curl.exe on PATH, and the service-role key in
# the environment (used only for cleanup, never written to disk).
#
#   $env:SUPABASE_SERVICE_ROLE_KEY = '<service-role-key>'
#   powershell -File scripts/cloud-smoke.ps1
#
# Optional overrides: SUPABASE_URL / SUPABASE_ANON_KEY (otherwise env.json).

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$configPath = Join-Path $root 'env.json'

if ((Test-Path $configPath) -and -not $env:SUPABASE_URL) {
  $config = Get-Content $configPath -Raw | ConvertFrom-Json
  $env:SUPABASE_URL = $config.SUPABASE_URL
  $env:SUPABASE_ANON_KEY = $config.SUPABASE_ANON_KEY
}

$base = if ($env:SUPABASE_URL) { $env:SUPABASE_URL.TrimEnd('/') } else { '' }
$anon = $env:SUPABASE_ANON_KEY
$svc = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $base -or -not $anon) { throw 'SUPABASE_URL / SUPABASE_ANON_KEY not set (env.json is git-ignored).' }
if (-not $svc) { throw 'SUPABASE_SERVICE_ROLE_KEY is required so the test can delete its users.' }

$work = Join-Path ([IO.Path]::GetTempPath()) "bagifair-smoke-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Force -Path $work | Out-Null

$results = New-Object System.Collections.Generic.List[string]
function Check($name, $ok, $detail = '') {
  $script:results.Add(('{0}  {1}  {2}' -f $(if ($ok) { 'PASS' } else { 'FAIL' }), $name, $detail))
}

function Req($method, $url, $token, $json, $prefer) {
  $bodyFile = Join-Path $work 'req.json'
  $outFile = Join-Path $work 'resp.json'
  if (Test-Path $outFile) { Remove-Item $outFile -Force }
  if ($json) { [IO.File]::WriteAllText($bodyFile, $json, (New-Object System.Text.UTF8Encoding($false))) }

  $curl = @('-s', '-o', $outFile, '-w', '%{http_code}', '-X', $method, $url, '-H', "apikey: $anon")
  if ($token) { $curl += @('-H', "Authorization: Bearer $token") }
  if ($json) { $curl += @('-H', 'Content-Type: application/json', '--data-binary', "@$bodyFile") }
  if ($prefer) { $curl += @('-H', "Prefer: $prefer") }

  $code = & curl.exe @curl
  $body = if (Test-Path $outFile) { [IO.File]::ReadAllText($outFile) } else { '' }
  return [pscustomobject]@{ status = [int]$code; body = $body }
}

$tag = [guid]::NewGuid().ToString('N').Substring(0, 8)
$emailA = "smoke.a.$tag@bagifair.app"
$emailB = "smoke.b.$tag@bagifair.app"
$password = 'Rahasia123!'
$uidA = $null
$uidB = $null

try {
  $r = Req 'GET' "$base/rest/v1/groups?select=id" $null $null $null
  Check 'anon cannot read groups' ($r.status -eq 200 -and $r.body.Trim() -eq '[]')

  $sa = (Req 'POST' "$base/auth/v1/signup" $null (@{ email = $emailA; password = $password } | ConvertTo-Json -Compress) $null).body | ConvertFrom-Json
  $tokenA = $sa.access_token; $uidA = $sa.user.id
  Check 'signup returns a session immediately' ([bool]$tokenA)

  $sb = (Req 'POST' "$base/auth/v1/signup" $null (@{ email = $emailB; password = $password } | ConvertTo-Json -Compress) $null).body | ConvertFrom-Json
  $tokenB = $sb.access_token; $uidB = $sb.user.id

  $r = Req 'GET' "$base/rest/v1/profiles?select=id,user_id" $tokenA $null $null
  $profiles = @($r.body | ConvertFrom-Json)
  Check 'handle_new_user trigger created a profile' ($profiles.Count -eq 1 -and $profiles[0].id -eq $uidA)

  $r = Req 'POST' "$base/rest/v1/profiles?on_conflict=user_id" $tokenA (@{
    user_id = $uidA; display_name = 'Smoke Renamed'; email = $emailA
    default_currency = 'IDR'; locale = 'id'
  } | ConvertTo-Json -Compress) 'resolution=merge-duplicates,return=representation'
  Check 'profile upsert edits the existing row' ($r.status -in 200, 201 -and @($r.body | ConvertFrom-Json).Count -eq 1 -and $r.body -match 'Smoke Renamed')

  $groupId = [guid]::NewGuid().ToString()
  $r = Req 'POST' "$base/rest/v1/groups" $tokenA (@{
    id = $groupId; name = 'Smoke Trip'; description = 'ci'; emoji = 'X'
    type = 'trip'; currency = 'IDR'; owner_id = $uidA
  } | ConvertTo-Json -Compress) 'return=representation'
  Check 'owner can insert a group and read it back' ($r.status -eq 201 -and $r.body -match $groupId)

  $r = Req 'POST' "$base/rest/v1/group_members" $tokenA (@{
    id = [guid]::NewGuid().ToString(); group_id = $groupId; user_id = $uidA
    display_name = 'Owner A'; email = $emailA; role = 'owner'
  } | ConvertTo-Json -Compress) 'return=representation'
  Check 'owner can insert and read back own membership' ($r.status -eq 201)

  $r = Req 'GET' "$base/rest/v1/groups?select=id" $tokenB $null $null
  Check 'outsider cannot see the group' ($r.body.Trim() -eq '[]')

  $r = Req 'POST' "$base/rest/v1/expenses" $tokenB (@{
    id = [guid]::NewGuid().ToString(); group_id = $groupId; title = 'Nasi'; category = 'food'
    amount_minor = 50000; amount_base_minor = 50000; currency = 'IDR'; fx_rate = 1
    paid_by = $uidB; split_mode = 'equal'; created_by = $uidB
  } | ConvertTo-Json -Compress) $null
  Check 'outsider cannot insert an expense' ($r.status -in 401, 403)

  $r = Req 'POST' "$base/rest/v1/group_members" $tokenB (@{
    id = [guid]::NewGuid().ToString(); group_id = $groupId; user_id = $uidB
    display_name = 'B'; role = 'member'
  } | ConvertTo-Json -Compress) $null
  Check 'outsider cannot self-join by group UUID' ($r.status -in 401, 403)

  $r = Req 'POST' "$base/rest/v1/rpc/create_group_invite" $tokenA (@{ p_group_id = $groupId; p_days = 7 } | ConvertTo-Json -Compress) $null
  $code = $r.body.Trim('"')
  Check 'create_group_invite returns a 7-char code' ($r.status -eq 200 -and $code -match '^[A-Z0-9]{7}$') "code=$code"

  $r = Req 'POST' "$base/rest/v1/rpc/join_group_by_code" $tokenB (@{ p_code = $code } | ConvertTo-Json -Compress) $null
  Check 'join_group_by_code returns the group id' ($r.status -eq 200 -and $r.body.Trim('"') -eq $groupId)

  $r = Req 'GET' "$base/rest/v1/groups?select=id" $tokenB $null $null
  Check 'new member can see the group' (@($r.body | ConvertFrom-Json).Count -eq 1)

  $r = Req 'GET' "$base/rest/v1/group_members?select=user_id&group_id=eq.$groupId" $tokenB $null $null
  Check 'joiner has a membership row' (@($r.body | ConvertFrom-Json | Where-Object { $_.user_id -eq $uidB }).Count -eq 1)

  $r = Req 'GET' "$base/rest/v1/groups?select=member_count&id=eq.$groupId" $tokenB $null $null
  $gc = @($r.body | ConvertFrom-Json)
  Check 'member_count trigger reports 2' ($gc.Count -eq 1 -and $gc[0].member_count -eq 2)

  $r = Req 'POST' "$base/rest/v1/expenses" $tokenB (@{
    id = [guid]::NewGuid().ToString(); group_id = $groupId; title = 'Kopi'; category = 'food'
    amount_minor = 20000; amount_base_minor = 20000; currency = 'IDR'; fx_rate = 1
    paid_by = $uidA; split_mode = 'equal'; created_by = $uidB
  } | ConvertTo-Json -Compress) 'return=representation'
  Check 'member can insert an expense' ($r.status -eq 201)

  $groupId2 = [guid]::NewGuid().ToString()
  $null = Req 'POST' "$base/rest/v1/groups" $tokenA (@{ id = $groupId2; name = 'Other'; type = 'other'; currency = 'IDR'; owner_id = $uidA } | ConvertTo-Json -Compress) $null
  $null = Req 'POST' "$base/rest/v1/group_members" $tokenA (@{ id = [guid]::NewGuid().ToString(); group_id = $groupId2; user_id = $uidA; display_name = 'Owner A'; role = 'owner' } | ConvertTo-Json -Compress) $null
  $r = Req 'GET' "$base/rest/v1/expenses?select=id,group_id" $tokenB $null $null
  $expenses = @($r.body | ConvertFrom-Json)
  Check 'second group stays invisible to a non-member' ($expenses.Count -eq 1 -and -not ($expenses | Where-Object { $_.group_id -eq $groupId2 }))

  $r = Req 'POST' "$base/rest/v1/rpc/claim_ai_scan" $tokenB (@{ p_user_id = $uidB } | ConvertTo-Json -Compress) $null
  Check 'claim_ai_scan is not callable by clients' ($r.status -in 401, 403, 404)

  $r = Req 'POST' "$base/functions/v1/scan-receipt" $null '{}' $null
  Check 'scan-receipt rejects unauthenticated calls' ($r.status -eq 401)

  $r = Req 'GET' "$base/rest/v1/receipts?select=id" $tokenB $null $null
  Check 'receipts table respects membership' ($r.status -eq 200 -and $r.body.Trim() -eq '[]')

  $r = Req 'POST' "$base/rest/v1/notifications" $tokenA (@{
    id = [guid]::NewGuid().ToString(); user_id = $uidA; group_id = $groupId
    actor_id = $uidA; actor_name = 'A'; kind = 'reminder'; title = 'Tes'; body = 'Halo'
  } | ConvertTo-Json -Compress) $null
  Check 'member can notify another member' ($r.status -eq 201)
}
catch {
  Check 'script aborted' $false $_.Exception.Message
}
finally {
  $adminHeaders = @{ apikey = $svc; Authorization = "Bearer $svc" }
  foreach ($uid in @($uidA, $uidB)) {
    if (-not $uid) { continue }
    try { $null = Invoke-RestMethod -Method Delete -Uri "$base/auth/v1/admin/users/$uid" -Headers $adminHeaders }
    catch { Write-Output "cleanup failed for ${uid}: $($_.Exception.Message)" }
  }
  Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue

  $results | ForEach-Object { Write-Output $_ }
  $failed = @($results | Where-Object { $_ -like 'FAIL*' }).Count
  Write-Output ''
  Write-Output ("{0} passed, {1} failed" -f (@($results).Count - $failed), $failed)
  if ($failed -gt 0) { exit 1 }
}
