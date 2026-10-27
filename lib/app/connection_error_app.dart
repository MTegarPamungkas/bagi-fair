import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/brand_mark.dart';
import 'package:bagi_fair/core/widgets/fair_background.dart';
import 'package:bagi_fair/core/widgets/state_views.dart';
import 'package:flutter/material.dart';

/// Shown only when the Supabase client itself cannot be created.
class ConnectionErrorApp extends StatelessWidget {
  const ConnectionErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bagi Fair',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Builder(
        builder: (context) => Scaffold(
          body: FairBackground(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FairLogo(size: 68),
                        const SizedBox(height: AppSpacing.xl),
                        ErrorState(
                          title: 'Tidak bisa terhubung ke Supabase',
                          message:
                              'Data Bagi Fair disimpan di Supabase. '
                              'Periksa koneksi, lalu buka ulang aplikasi.\n\n'
                              '$message',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
