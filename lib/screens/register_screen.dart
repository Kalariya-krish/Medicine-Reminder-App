import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medicine_reminder_system/widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Center(
                    child: Text(
                      "Sign up",
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Username
                  buildLabel("Username"),
                  buildTextField(
                    controller: _usernameController,
                    hint: "Enter your username",
                    validator: (value) =>
                        value!.isEmpty ? "Please enter your username" : null,
                  ),

                  const SizedBox(height: 16),

                  // Email
                  buildLabel("Email"),
                  buildTextField(
                    controller: _emailController,
                    hint: "Enter your email",
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value!.isEmpty) return "Please enter your email";
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return "Please enter a valid email";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password
                  buildLabel("Password"),
                  buildTextField(
                    controller: _passwordController,
                    hint: "Enter your password",
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) return "Please enter your password";
                      if (value.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Confirm Password
                  buildLabel("Confirm Password"),
                  buildTextField(
                    controller: _confirmPasswordController,
                    hint: "Confirm password",
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Please confirm your password";
                      }
                      if (value != _passwordController.text) {
                        return "Passwords do not match";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // DOB
                  buildLabel("Date of Birth"),
                  buildTextField(
                    controller: _dobController,
                    hint: "Enter your DOB",
                    keyboardType: TextInputType.datetime,
                    validator: (value) =>
                        value!.isEmpty ? "Please enter your DOB" : null,
                  ),

                  const SizedBox(height: 16),

                  // Mobile Number
                  buildLabel("Mobile Number"),
                  buildTextField(
                    controller: _mobileController,
                    hint: "Enter your mobile no",
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value!.isEmpty)
                        return "Please enter your mobile number";
                      if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                        return "Enter a valid 10-digit number";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  // Sign up button
                  CustomButton(
                    text: "Sign up",
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Registering...")),
                        );
                        // TODO: Add your signup logic
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Already member? Login
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: RichText(
                        text: TextSpan(
                          text: "Already a member ? ",
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: "Login",
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

  // Reusable label
  Widget buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // Reusable textfield
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}
