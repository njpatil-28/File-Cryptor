import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/encryption_service.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import 'login_screen.dart';

class EmailConfirmationScreen extends StatefulWidget {
  final String email;

  const EmailConfirmationScreen({super.key, required this.email});

  @override
  State<EmailConfirmationScreen> createState() =>
      _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  final _supabase = Supabase.instance.client;
  final _encryptionService = EncryptionService();
  bool _isResending = false;
  bool _isChecking = false;

  Future<void> _resendConfirmation() async {
    setState(() => _isResending = true);

    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
      _showSuccess('Confirmation email sent!');
    } catch (e) {
      _showError('Failed to resend email: ${e.toString()}');
    } finally {
      setState(() => _isResending = false);
    }
  }

  Future<void> _checkConfirmation() async {
    setState(() => _isChecking = true);

    try {
      // Try to sign in to check if email is verified
      final response = await _supabase.auth.signInWithPassword(
        email: widget.email,
        password:
            'dummy', // This will fail but that's ok, we just need to check the error
      );

      // If we get here, credentials might be wrong but email could be verified
      // This shouldn't happen with 'dummy' password
    } catch (e) {
      // Check the error message
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('email not confirmed') ||
          errorMessage.contains('email confirmation')) {
        _showError(
            'Email not confirmed yet. Please check your inbox and click the confirmation link.');
      } else if (errorMessage.contains('invalid') ||
          errorMessage.contains('credentials')) {
        // Email is confirmed (password was wrong, but that means email verification passed)
        if (mounted) {
          _showSuccess('Email confirmed! Please login with your password.');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
        return;
      } else {
        _showError(
            'Unable to verify confirmation status. Please try logging in.');
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.primary),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.peach,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 40,
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We sent a confirmation email to:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.skyBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Please check your inbox and click the confirmation link to activate your account.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'After confirming, come back and click "Continue to Login"',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: 'Continue to Login',
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isResending ? null : _resendConfirmation,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isResending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Resend Confirmation Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
