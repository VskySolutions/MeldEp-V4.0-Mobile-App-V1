import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/widgets/snackbar/custom_snackbar.dart';
import 'package:test_project/features/auth/auth_services.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // --------------------------------------------------------------------------
  // Form & State
  // --------------------------------------------------------------------------
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------------
  void _onFieldChanged(String value) {
    setState(() {
      _emailError = value.trim().isEmpty ? 'Email is required' : null;
    });
  }

  void _onSubmitPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      _forgotPassword(context);
    }
  }

  // --------------------------------------------------------------------------
  // API
  // --------------------------------------------------------------------------
  Future<void> _forgotPassword(BuildContext context) async {
    final email = _emailController.text.trim();
    final payload = {'email': email};

    String? _msgFrom(dynamic data) {
      if (data is String && data.trim().isNotEmpty) return data.trim();
      if (data is Map && data['message'] is String)
        return (data['message'] as String).trim();
      return null;
    }

    try {
      setState(() => _isLoading = true);

      final res = await AuthServices.instance.forgotPassword(payload);
      final status = res.statusCode ?? 0;
      final msg = _msgFrom(res.data) ??
          (status >= 200 && status < 300
              ? 'Password reset link sent to email.'
              : 'Request failed ($status)');

      if (status >= 200 && status < 300) {
        showCustomSnackBar(context, message: msg, durationSeconds: 3);
        // Consider navigating back or to a success screen
      } else {
        showCustomSnackBar(context,
            message: msg, backgroundColor: AppColors.ERROR);
      }
    } on DioError catch (e) {
      final status = e.response?.statusCode;
      final msg = _msgFrom(e.response?.data) ??
          (status != null ? 'Request failed ($status)' : 'Request failed');
      showCustomSnackBar(context,
          message: msg, backgroundColor: AppColors.ERROR);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final spacing = size.height * 0.02;

    return Scaffold(
      // appBar: AppBar(
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back),
      //     onPressed: () => context.pop(),
      //   ),
      //   title: const Text('Forgot Password'),
      // ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.07,
                vertical: size.height * 0.04,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Centered title
                    Text(
                      'Vsky Solutions',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: size.height * 0.04),

                    // Left-aligned section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Forgot Password',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Please enter your registered email address below. We will send you an email with instructions on how to reset your password.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.04),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      onChanged: _onFieldChanged,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: 'Email Address*',
                        hintText: 'Enter email address',
                        errorText: _emailError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (val) {
                        final text = val?.trim() ?? '';
                        if (text.isEmpty) return 'Email is required';
                        final emailRegex =
                            RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(text)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _onSubmitPressed(),
                    ),

                    SizedBox(height: spacing * 2),

                    // Submit row (left label + circular button on right)

                    SizedBox(
                      width: double
                          .infinity, 
                      child: _SubmitButton(
                        isLoading: _isLoading,
                        onPressed: _onSubmitPressed,
                      ),
                    ),

                    SizedBox(height: size.height * 0.03),

                    // Back to Login
                    TextButton(
                      onPressed: _isLoading ? null : () => context.pop(),
                      child: const Text(
                        'BACK TO LOGIN',
                        style: TextStyle(
                          color: Color.fromRGBO(83, 109, 254, 1),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF536DFE),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Submit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
