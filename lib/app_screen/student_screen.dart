import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'edit_student_screen.dart';
import 'package:http/http.dart' as http;

import '../model/student.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _StudentScreenState();
  }
}

class _StudentScreenState extends State<StudentScreen> {
  late Future<List<Student>> students;

  @override
  void initState() {
    super.initState();
    students = fetchStudents();
  }

  void _refreshData() {
    setState(() {
      students = fetchStudents();
    });
  }

  Future<void> _showAddStudentDialog() async {
    final studentCodeController = TextEditingController();
    final studentNameController = TextEditingController();
    String? selectedGender; // This will hold the selected gender value

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Student'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: studentCodeController,
                  decoration: const InputDecoration(hintText: 'Student Code'),
                ),
                TextField(
                  controller: studentNameController,
                  decoration: const InputDecoration(hintText: 'Student Name'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(hintText: 'Gender'),
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('Male')),
                    DropdownMenuItem(value: 'F', child: Text('Female')),
                  ],
                  onChanged: (String? newValue) {
                    selectedGender = newValue;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                final student = Student(
                  studentCode: studentCodeController.text,
                  studentName: studentNameController.text,
                  gender: selectedGender ??
                      '', // Handle the case where no gender is selected
                );
                await insertStudent(student);
                _refreshData();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddStudentDialog,
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<List<Student>>(
          future: students,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasData) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      color: Colors.teal.withAlpha(100),
                    ),
                    child: Row(
                      children: [
                        Text('Total ${snapshot.data!.length} items'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: snapshot.data!.isNotEmpty
                        ? ListView.separated(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(snapshot.data![index].studentName),
                                subtitle:
                                    Text(snapshot.data![index].studentCode),
                                trailing: Wrap(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditStudentScreen(
                                                    student:
                                                        snapshot.data![index]),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.edit),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        await showDialog(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              AlertDialog(
                                            title: const Text('Confirm Delete'),
                                            content: Expanded(
                                              child: Text(
                                                  "Do you want to delete: ${snapshot.data![index].studentCode}"),
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                ),
                                                onPressed: () async {
                                                  await deleteStudent(
                                                      snapshot.data![index]);
                                                  setState(() {
                                                    students = fetchStudents();
                                                  });
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Delete'),
                                              ),
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  backgroundColor:
                                                      Colors.blueGrey,
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Close'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.delete),
                                    ),
                                  ],
                                ),
                              );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const Divider(),
                          )
                        : const Center(child: Text('No items')),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

Future<List<Student>> fetchStudents() async {
  final response =
      await http.get(Uri.parse('http://127.0.0.1/api/student.php'));

  if (response.statusCode == 200) {
    return compute(parsestudents, response.body);
  } else {
    throw Exception('Failed to load Student');
  }
}

Future<int> deleteStudent(Student student) async {
  final response = await http.delete(
    Uri.parse(
        'http://127.0.0.1/api/student.php?student_code=${student.studentCode}'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  if (response.statusCode == 200) {
    return response.statusCode;
  } else {
    throw Exception('Failed to update student.');
  }
}

Future<int> insertStudent(Student student) async {
  final response = await http.post(
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
        'Failed to post student. Status code: ${response.statusCode}');
  }
}

Future<List<String>> fetchStudentCodes() async {
  final response =
      await http.get(Uri.parse('http://127.0.0.1/api/student.php'));

  if (response.statusCode == 200) {
    // Assuming the API returns a list of student codes
    final List<dynamic> data = jsonDecode(response.body);
    return data.map<String>((item) => item['student_code'] as String).toList();
  } else {
    throw Exception('Failed to load student codes');
  }
}

List<Student> parsestudents(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Student>((json) => Student.fromJson(json)).toList();
}
