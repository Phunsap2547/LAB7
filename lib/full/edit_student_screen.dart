import 'dart:convert';
import 'package:flutter/material.dart';
import '../model/student.dart';
import 'package:http/http.dart' as http;

class EditStudentScreen extends StatefulWidget {
  final Student? student;
  const EditStudentScreen({
    super.key,
    this.student,
  });

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  Student? student;
  TextEditingController nameController = TextEditingController();
  TextEditingController codeController = TextEditingController();
  String dropdownValue = "";

  @override
  void initState() {
    super.initState();
    student = widget.student;
    codeController.text = student!.studentCode;
    nameController.text = student!.studentName;
    dropdownValue = student!.gender;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Student"),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                int statusCode = await updateStudent(Student(
                  studentCode: student!.studentCode,
                  studentName: nameController.text,
                  gender: dropdownValue,
                ));
                if (statusCode == 200) {
                  Navigator.pop(context);
                } else {
                  // Handle unexpected status codes here
                }
              } catch (e) {
                // Handle exceptions (e.g., show an error message)
                print('Error: $e');
              }
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextField(
              controller: codeController,
              enabled: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Student Code',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Student Name',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: dropdownValue,
              onChanged: (String? value) {
                setState(() {
                  dropdownValue = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
              items: [
                'F',
                'M',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<int> updateStudent(Student student) async {
    final response = await http.put(
      Uri.parse('http://127.0.0.1/api/student.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'student_code': student.studentCode,
        'student_name': student.studentName,
        'gender': student.gender,
      }),
    );

    if (response.statusCode == 200) {
      return response.statusCode;
    } else {
      throw Exception(
          'Failed to update student. Status code: ${response.statusCode}');
    }
  }
}
