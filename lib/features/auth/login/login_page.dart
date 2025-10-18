import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

import 'package:test_project/boot/auth.dart';
import 'package:test_project/core/flavor/flavor.dart';
import 'package:test_project/core/services/local_storage.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/widgets/snackbar/custom_snackbar.dart';
import 'package:test_project/features/auth/auth_services.dart';
import 'package:test_project/features/auth/login/login_strings.dart';
import 'package:test_project/states/model/logInCred.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --------------------------------------------------------------------------------------------------------------------------------------------------
  // Variable Declarations
  // --------------------------------------------------------------------------------------------------------------------------------------------------

  // Form
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State flags
  bool _isLoading = false;
  bool _isPasswordObscured = true;
  bool _isRememberMeChecked = true;

  // Validation errors
  String? _usernameError;
  String? _passwordError;

  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Lifecycle
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------------------------------------------------------------------------------
  // API Calls
  // --------------------------------------------------------------------------------------------------------------------------------------------------

  // Performs the login API call, persists credentials, and navigates on success.
  Future<void> _login(BuildContext context) async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();
    final loginData = {'username': username, 'password': password};

    try {
      setState(() => _isLoading = true);

      final response = await AuthServices.instance.login(loginData);

      if (response.statusCode == 200) {
        final data = response.data;
        LogInCred responseData = LogInCred.fromJson(data);
        if (responseData.employeeId.isNotEmpty) {
          await AuthService.instance
              .login(responseData.token, _isRememberMeChecked);
          // await LocalStorage.setRememberMe(_isRememberMeChecked);
          await LocalStorage.setEmployeeId(responseData.employeeId);
          await LocalStorage.setEmployeeName(
            '${responseData.firstName} ${responseData.lastName}',
          );
          await LocalStorage.setRoles(responseData.roles);

          showCustomSnackBar(
            context,
            message: 'Logged in successfully!',
            durationSeconds: 2,
          );
          context.go('/main/home');
        } else {
          showCustomSnackBar(
            context,
            message: 'Login failed: Required employee data not found',
            backgroundColor: AppColors.ERROR,
          );
        }
      } else {
        showCustomSnackBar(
          context,
          message: 'Login failed.',
          backgroundColor: AppColors.ERROR,
        );
      }
    } on DioError catch (e) {
      final errorMessage = e.response?.data?['message'] ?? e.message;
      showCustomSnackBar(
        context,
        message: 'Login error: $errorMessage',
        backgroundColor: AppColors.ERROR,
      );
    } catch (e) {
      showCustomSnackBar(
        context,
        message: 'Unexpected error: $e',
        backgroundColor: AppColors.ERROR,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --------------------------------------------------------------------------------------------------------------------------------------------------
  // Actions & Event Handlers
  // --------------------------------------------------------------------------------------------------------------------------------------------------

  // Handles login button press by validating the form and invoking _login.
  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      _login(context);
    }
  }

  void _onFieldChanged(String value, String type) {
    setState(() {
      if (type == "username") {
        _usernameError = value.isEmpty ? "Username is required" : null;
      } else if (type == "password") {
        _passwordError = value.isEmpty ? "Password is required" : null;
      }
    });
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// UI
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final spacing = size.height * 0.02; // 2% of screen height

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.03,
                  // vertical: size.height * 0.04, // 4% of screen height
                ),
                child: Card(
                  color: Colors.white,
                  elevation: 3,
                  child: Form(
                    key: _formKey,
                    child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                          vertical: size.height * 0.06,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildHeader(theme),
                            SizedBox(
                                height: size.height * 0.08), // header spacing
                            _buildUsernameField(theme),
                            SizedBox(height: spacing),
                            _buildPasswordField(theme),
                            SizedBox(height: spacing * 0.8),
                            _buildRememberMeAndForgotPassword(context),
                            SizedBox(height: size.height * 0.05),
                            _buildLoginButton(size),
                            // SizedBox(height: size.height * 0.08),
                            if (false)
                              ElevatedButton(
                                // icon: Icon(Icons.crop),
                                child: Text('Eye Glasses AR'),
                                onPressed: () {
                                  context.go('/eyeGlassesAR');
                                },
                              ),
                          ],
                        )),
                  ),
                )),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------------------------------------------------------------------------------
  // UI Helpers
  // --------------------------------------------------------------------------------------------------------------------------------------------------

  // Builds the header title and subtitle.
  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          height: 40,
          child: Image.asset('assets/images/meld-epLogo.png'),
        ),
        const SizedBox(height: 24),
        Text(
          LoginStrings.welcomeTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          LoginStrings.welcomeSubtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Builds the username text field
  Widget _buildUsernameField(ThemeData theme) {
    return TextFormField(
      controller: _usernameController,
      enabled: !_isLoading,
      onChanged: (value) => _onFieldChanged(value, "username"),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: LoginStrings.usernameLabel,
        hintText: LoginStrings.usernameHint,
        errorText: _usernameError,
        border: _buildInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: (val) {
        // keep simple validation compatible with existing logic
        if (val == null || val.trim().isEmpty) return 'Username is required';
        return null;
      },
    );
  }

  // Builds the password text field with show/hide behavior.
  Widget _buildPasswordField(ThemeData theme) {
    return TextFormField(
      controller: _passwordController,
      enabled: !_isLoading,
      obscureText: _isPasswordObscured, // kept same as original semantics
      onChanged: (value) => _onFieldChanged(value, "password"),
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        errorText: _passwordError,
        labelText: LoginStrings.passwordLabel,
        hintText: LoginStrings.passwordHint,
        prefixIcon: IconButton(
          icon: Icon(
            _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _isPasswordObscured = !_isPasswordObscured;
            });
          },
        ),
        border: _buildInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Password is required';
        return null;
      },
      onFieldSubmitted: (_) => _onLoginPressed(),
    );
  }

  // Builds the remember-me checkbox and forgot-password link row.
  Widget _buildRememberMeAndForgotPassword(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _isRememberMeChecked,
              onChanged: (value) {
                setState(() {
                  _isRememberMeChecked = value ?? false;
                });
              },
            ),
            const Text(
              LoginStrings.rememberMe,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            context.push('/forgotPassword');
          },
          child: const Text(
            LoginStrings.forgotPassword,
            style: TextStyle(
              color: Color.fromRGBO(83, 109, 254, 1),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  // Builds the login button row with progress indicator.
  Widget _buildLoginButton(Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          LoginStrings.loginText,
          style: TextStyle(
            fontSize: size.width * 0.06,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF536DFE),
          ),
        ),
        _LoginButton(isLoading: _isLoading, onPressed: _onLoginPressed),
      ],
    );
  }

  // --------------------------------------------------------------------------------------------------------------------------------------------------
  // Utilities
  // --------------------------------------------------------------------------------------------------------------------------------------------------

  // Builds a standard input border used by form fields.
  OutlineInputBorder _buildInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade400),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoginButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFF536DFE),
        ),
        child: isLoading
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Icon(Icons.arrow_forward, size: 28, color: Colors.white),
      ),
    );
  }
}
