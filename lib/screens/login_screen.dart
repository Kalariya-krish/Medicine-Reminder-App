import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medicine_reminder_system/widgets/custom_button.dart';
import 'package:toastification/toastification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // GlobalKey is correctly defined for FormState
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            // --- The SingleChildScrollView should NOT have the key ---
            child: Form(
              // <--- WRAP THE COLUMN WITH A FORM WIDGET
              key: _formKey, // <--- ASSIGN THE GLOBAL KEY TO THE FORM
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
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

                  // --- Email Field ---
                  Text(
                    "Email",
                    style: GoogleFonts.montserrat(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Enter your email",
                      hintStyle: GoogleFonts.montserrat(fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your email";
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return "Please enter a valid email";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // --- Password Field ---
                  Text(
                    "Password",
                    style: GoogleFonts.montserrat(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: "Enter your password",
                      hintStyle: GoogleFonts.montserrat(fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your password";
                      }
                      if (value.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  // --- Sign In Button ---
                  CustomButton(
                    text: "Sign in",
                    onPressed: () {
                      // 1. Check if the Form is valid
                      if (_formKey.currentState!.validate()) {
                        // 2. Show success toast (UX feedback)
                        toastification.show(
                            title: const Text('Logging in...'),
                            icon: const Icon(Icons.check),
                            alignment: Alignment.topCenter,
                            style: ToastificationStyle.fillColored,
                            type: ToastificationType.success,
                            autoCloseDuration:
                                const Duration(milliseconds: 1500));

                        // 3. Navigate after the toast has a chance to be seen
                        Future.delayed(const Duration(seconds: 1), () {
                          if (!context.mounted) return;

                          // Use pushReplacementNamed to prevent coming back to Login
                          Navigator.pushReplacementNamed(context, '/home');

                          // Note: I replaced your original pushNamed with pushReplacementNamed
                          // as that is standard for login. If you meant to use the other,
                          // simply change it back.
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Forget Password
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/forgetpassword');
                      },
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
                      onTap: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Not a member ? ",
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

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
