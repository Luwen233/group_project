import 'package:flutter/material.dart';
import 'package:project_br/login/signup_page.dart';
import 'package:project_br/staff/pages/linkpage.dart';
import 'package:project_br/student/widget_tree.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final Color mainColor = Color(0xFF3C9CBF);
  bool obscurePassword = true;
  @override
  Widget build(BuildContext context) {

    void login() {
      if (usernameController.text == "staff" &&
          passwordController.text == "1234") { ///testing staff
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RoomApp(),
          ), 
        );
      }
      else if (usernameController.text == "lender" &&
          passwordController.text == "1234") { ///testing lender
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const WidgetTree(),
          ), 
        );
      }
      else if (usernameController.text == "student" &&
          passwordController.text == "1234") { ///testing
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const WidgetTree(),
          ), 
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid username or password")),
        );
      }
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: 250,
            decoration: BoxDecoration(
              color: mainColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "R",
                  style: TextStyle(fontSize: 100, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Reservation",
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(hintText: 'Username'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: login,
                  child: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpPage()),
                        );
                      },
                      child: const Text(
                        "Sign up",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
