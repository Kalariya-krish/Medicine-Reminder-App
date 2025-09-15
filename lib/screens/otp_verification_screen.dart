import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../widgets/custom_button.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Verification OTP",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // OTP Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 40,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      decoration: const InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "";
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Custom Button
              CustomButton(
                text: "Verify",
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    String otp = _otpControllers
                        .map((controller) => controller.text)
                        .join();
                    if (otp.length == 6) {
                      toastification.show(
                          title: Text('Otp Verified'),
                          icon: Icon(Icons.check),
                          alignment: Alignment.topCenter,
                          style: ToastificationStyle.fillColored,
                          type: ToastificationType.success,
                          autoCloseDuration: Duration(milliseconds: 1500));
                      Future.delayed(Duration(seconds: 2), () {
                        if (!context.mounted) return;
                        Navigator.pushNamed(context, '/home');
                      });
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
