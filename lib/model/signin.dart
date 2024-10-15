import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SigninPage extends StatefulWidget {
  @override
  _SigninPageState createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final _formKey = GlobalKey<FormState>();
  String firstname = '';
  String lastname = '';
  String email = '';
  String password = '';
  String cPassword = '';
  String errorMessage = '';
  String successMessage = '';


  Future<void> _signin() async {
    final response = await http.post(
      Uri.parse('http://10.5.50.62/phunsap/Energy_Monitoring_System/signin.php'), // เปลี่ยน URL ให้ตรง
      body: {
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
        'password': password,
        'c_password': cPassword,
      },
    );

    final responseBody = json.decode(response.body);
    
    if (response.statusCode == 200) {
      if (responseBody['success']) {
        setState(() {
          successMessage = responseBody['message'];
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage = responseBody['message'];
          successMessage = '';
        });
      }
    } else {
      setState(() {
        errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('สมัครสมาชิก')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'ชื่อ'),
                onChanged: (value) => firstname = value,
                validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อ' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'นามสกุล'),
                onChanged: (value) => lastname = value,
                validator: (value) => value!.isEmpty ? 'กรุณากรอกนามสกุล' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'อีเมล'),
                onChanged: (value) => email = value,
                validator: (value) => value!.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value) 
                    ? 'กรุณากรอกอีเมลที่ถูกต้อง' 
                    : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'รหัสผ่าน'),
                obscureText: true,
                onChanged: (value) => password = value,
                validator: (value) {
                  if (value!.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                  if (value.length < 5 || value.length > 20) {
                    return 'รหัสผ่านต้องมีความยาวระหว่าง 5 ถึง 20 ตัวอักษร';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'ยืนยันรหัสผ่าน'),
                obscureText: true,
                onChanged: (value) => cPassword = value,
                validator: (value) => value != password ? 'รหัสผ่านไม่ตรงกัน' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _signin();
                  }
                },
                child: Text('สมัครสมาชิก'),
              ),
              if (errorMessage.isNotEmpty) ...[
                SizedBox(height: 10),
                Text(errorMessage, style: TextStyle(color: Colors.red)),
              ],
              if (successMessage.isNotEmpty) ...[
                SizedBox(height: 10),
                Text(successMessage, style: TextStyle(color: Colors.green)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
