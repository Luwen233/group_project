import 'package:flutter/material.dart';
import 'package:project_br/lecturer/lecturer_widget_tree.dart';
import 'package:project_br/login/signup_page.dart';
import 'package:project_br/widget_tree.dart';

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
    // ⭐️ 2. แก้ไขฟังก์ชัน login() ทั้งหมด
    void login() {
      String username = usernameController.text;
      String password = passwordController.text;

      // --- 1. ตรวจสอบ Lecturer ---
      if (username == "admin" && password == "1234") {
        // ถ้าเป็น "admin" (Lecturer)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LecturerWidgetTree(), // <--- ไปหน้า Lecturer
          ),
        );

        // --- 2. เพิ่มการตรวจสอบ Student (นี่คือตัวอย่าง) ---
      } else if (username == "student" && password == "1234") {
        // ถ้าเป็น "student" (คุณต้องเปลี่ยน "student" และ "1234" เป็น user/pass ของนักเรียน)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const WidgetTree(), // <--- ไปหน้า Student
          ),
        );

        // --- 3. ถ้าผิดหมด ---
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
                  onPressed: login, // <--- เรียกใช้ฟังก์ชัน login ที่เราแก้แล้ว
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
