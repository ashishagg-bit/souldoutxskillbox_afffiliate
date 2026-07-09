import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/admin_auth_provider.dart';
import '../../shared/app_colors.dart';

/// Direct port of `features/admin/admin-login.component.ts`.
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _controller = TextEditingController();
  bool _error = false;

  void _submit() {
    final ok = context.read<AdminAuthProvider>().login(_controller.text);
    if (ok) {
      Navigator.of(context).pushReplacementNamed('/admin');
    } else {
      setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('SKILLBOX INTERNAL',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.faint, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  const Text('Admin sign-in', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  const SizedBox(height: 8),
                  const Text('Enter the reviewer passphrase to continue.', style: TextStyle(fontSize: 13.5, color: AppColors.muted)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    obscureText: true,
                    autofocus: true,
                    onChanged: (_) => setState(() => _error = false),
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Passphrase',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _error ? AppColors.red600 : AppColors.line)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _error ? AppColors.red600 : AppColors.line)),
                    ),
                  ),
                  if (_error) ...[
                    const SizedBox(height: 8),
                    const Text('Incorrect passphrase.', style: TextStyle(fontSize: 13, color: AppColors.red600)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Sign in', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "This is a client-side placeholder gate, not real authentication — it only deters casual access to a public demo link. Real staff accounts come with the Laravel backend.",
                    style: TextStyle(fontSize: 12, color: AppColors.faint, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
