import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medicine_reminder_system/widgets/custom_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toastification/toastification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false; // For loading indicator

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to handle login
  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Sign in with email & password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      toastification.show(
          title: const Text('Logged in successfully!'),
          icon: const Icon(Icons.check),
          alignment: Alignment.topCenter,
          style: ToastificationStyle.fillColored,
          type: ToastificationType.success,
          autoCloseDuration: const Duration(milliseconds: 1500));

      // Navigate to home screen
      Future.delayed(const Duration(seconds: 1), () {
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      });
    } on FirebaseAuthException catch (e) {
      // Handle Firebase login errors
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = "Invalid email format!";
          break;
        case 'user-not-found':
          errorMessage = "No user found with this email!";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password!";
          break;
        case 'user-disabled':
          errorMessage = "User account is disabled!";
          break;
        default:
          errorMessage = "Login failed. Try again!";
      }

      toastification.show(
          title: const Text('Error, Invalid Credential !'),
          icon: const Icon(Icons.check),
          alignment: Alignment.topCenter,
          style: ToastificationStyle.fillColored,
          type: ToastificationType.error,
          autoCloseDuration: const Duration(milliseconds: 1500));
    } catch (e) {
      toastification.show(
          title: const Text('Something went wrong!'),
          icon: const Icon(Icons.check),
          alignment: Alignment.topCenter,
          style: ToastificationStyle.fillColored,
          type: ToastificationType.error,
          autoCloseDuration: const Duration(milliseconds: 1500));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      "Sign in",
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email Field
                  buildLabel("Email"),
                  buildTextField(
                    controller: _emailController,
                    hint: "Enter your email",
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Please enter your email";
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                        return "Enter a valid email";
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  buildLabel("Password"),
                  buildTextField(
                    controller: _passwordController,
                    hint: "Enter your password",
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Please enter your password";
                      if (value.length < 6)
                        return "Password must be at least 6 characters";
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Login Button
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : CustomButton(
                          text: "Sign in",
                          onPressed: _loginUser,
                        ),

                  const SizedBox(height: 16),

                  // Forget Password
                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, '/forgetpassword'),
                      child: Text(
                        "Forget Password",
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: const Color(0xFFEF6A6A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Register Now
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/register'),
                      child: RichText(
                        text: TextSpan(
                          text: "Not a member? ",
                          style: GoogleFonts.montserrat(
                              color: Colors.black, fontSize: 14),
                          children: [
                            TextSpan(
                              text: "Register Now",
                              style: GoogleFonts.montserrat(
                                color: const Color(0xFFEF6A6A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}
