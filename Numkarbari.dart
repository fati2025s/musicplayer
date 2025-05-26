import 'package:flutter/material.dart';
import 'ChangePassword.dart';

void main() {
  runApp(const Numkarbari());
}
class Numkarbari extends StatelessWidget {
  const Numkarbari({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: karbariHome(),
    );
  }
}

class karbariHome extends StatelessWidget {
  const karbariHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF00CCFF),
                Color(0xFFFFFFFF),
              ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.1, 1.0],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Change Password',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 100),

                SizedBox(
                  width: 290,
                  child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Email or Phonenumber',
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                ),
                const SizedBox(height: 250),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePassword(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF001490),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: const Text('Continue',
                    style: TextStyle(
                      fontSize: 16,
                      color:Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}