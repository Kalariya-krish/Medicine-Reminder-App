import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medicine_reminder_system/widgets/custom_button.dart';
import 'package:medicine_reminder_system/services/firebase_auth_service.dart';
import 'package:toastification/toastification.dart';
import 'package:intl/intl.dart'; // For formatting date

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

  // Function to pick date
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate =
        DateTime.now().subtract(const Duration(days: 365 * 18));
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

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
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
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
                    validator: (value) {
                      if (value!.isEmpty) return "Please enter username";
                      if (value.length < 3) return "Minimum 3 characters";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email
                  buildLabel("Email"),
                  buildTextField(
                    controller: _emailController,
                    hint: "Enter your email",
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value!.isEmpty) return "Please enter email";
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return "Enter a valid email";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  buildLabel("Password"),
                  buildTextField(
                    controller: _passwordController,
                    hint: "Enter password",
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) return "Please enter password";
                      if (value.length < 6) return "Minimum 6 characters";
                      if (!RegExp(
                              r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&]).{6,}$')
                          .hasMatch(value)) {
                        return "Password must contain letter, number & special char";
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
                      if (value!.isEmpty) return "Confirm your password";
                      if (value != _passwordController.text)
                        return "Passwords do not match";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // DOB
                  buildLabel("Date of Birth"),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: buildTextField(
                        controller: _dobController,
                        hint: "Select your DOB",
                        validator: (value) {
                          if (value!.isEmpty) return "Please select DOB";
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mobile Number
                  buildLabel("Mobile Number"),
                  buildTextField(
                    controller: _mobileController,
                    hint: "Enter mobile no",
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value!.isEmpty) return "Please enter mobile number";
                      if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                        return "Enter valid 10-digit number";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Sign up button
                  CustomButton(
                    text: "Sign up",
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          await FirebaseAuthService.registerUser(
                            username: _usernameController.text.trim(),
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                            dob: _dobController.text.trim(),
                            mobile: _mobileController.text.trim(),
                          );

                          toastification.show(
                              title: const Text('Registration successful'),
                              icon: const Icon(Icons.check),
                              alignment: Alignment.topCenter,
                              style: ToastificationStyle.fillColored,
                              type: ToastificationType.success,
                              autoCloseDuration:
                                  const Duration(milliseconds: 1500));

                          Navigator.pushReplacementNamed(context, '/home');
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'email-already-in-use') {
                            toastification.show(
                                title: const Text('Email already registered'),
                                icon: const Icon(Icons.check),
                                alignment: Alignment.topCenter,
                                style: ToastificationStyle.fillColored,
                                type: ToastificationType.error,
                                autoCloseDuration:
                                    const Duration(milliseconds: 1500));
                          } else {
                            toastification.show(
                                title: const Text('Registration failed'),
                                icon: const Icon(Icons.check),
                                alignment: Alignment.topCenter,
                                style: ToastificationStyle.fillColored,
                                type: ToastificationType.error,
                                autoCloseDuration:
                                    const Duration(milliseconds: 1500));
                          }
                        } catch (e) {
                          toastification.show(
                              title: const Text('Something went wrong'),
                              icon: const Icon(Icons.check),
                              alignment: Alignment.topCenter,
                              style: ToastificationStyle.fillColored,
                              type: ToastificationType.success,
                              autoCloseDuration:
                                  const Duration(milliseconds: 1500));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: RichText(
                        text: TextSpan(
                          text: "Already a member? ",
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
