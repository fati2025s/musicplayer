import 'package:flutter/material.dart';
import 'package:untitled/screens/Login.dart' show Login;
import 'package:untitled/screens/Signup.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red,
              Colors.white,
              Colors.black,
            ],
            stops: [
              0.1,
              0.5,
              1.0,
            ],
          ),
        ),

        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Welcome to ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Text(
                    'MC20',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(
                    height: 500,
                    child: Image.asset(
                      'assets/images/not.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  //const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Login()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8A0000),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        elevation: 3,
                      ),
                      child: const Text('Login', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Signup()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8A0000),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        elevation: 3,
                      ),
                      child: const Text('Sign up', style: TextStyle(fontSize: 16)),
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
}
