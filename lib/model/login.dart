import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // นำเข้าไลบรารี http



class Login extends StatelessWidget {
  const Login({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LoginPage(); // คืนค่าหน้าล็อกอิน
  }
}

class LoginService {
  Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('http://10.5.50.62/phunsap/Energy_Monitoring_System/login.php?'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return null; // ระบุว่าล็อกอินสำเร็จ
      } else {
        return data['error']; // คืนค่าข้อความผิดพลาดจากเซิร์ฟเวอร์
      }
    } else {
      return 'Something went wrong. Please try again.';
    }
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String? _email;
  String? _password;
  String? _errorMessage;

  final LoginService _loginService = LoginService();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      String? error = await _loginService.login(_email!, _password!);
      if (error != null) {
        setState(() {
          _errorMessage = error;
        });
      } else {
        // นำทางไปยังหน้าที่เหมาะสมตามบทบาทของผู้ใช้ (admin/user)
        // ตัวอย่าง: Navigator.pushNamed(context, 'home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เข้าสู่ระบบ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกอีเมล';
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'รูปแบบอีเมลไม่ถูกต้อง';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _email = value;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกรหัสผ่าน';
                      } else if (value.length < 5 || value.length > 20) {
                        return 'รหัสผ่านต้องมีความยาวระหว่าง 5 ถึง 20 ตัวอักษร';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _password = value;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _login,
                    child: Text('Login'),
                  ),
                  TextButton(
                    onPressed: () {
                      // Handle forgot password
                    },
                    child: Text('Forgot password?'),
                  ),
                  SizedBox(height: 20),
                  Text("Don't have an account?"),
                  
                  ElevatedButton(
                  onPressed: () {
                Navigator.pushNamed(context, '/signin'); // นำทางไปยังหน้า Signin
              },
              child: const Text('signin'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
