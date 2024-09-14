import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../model/course.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CourseScreenState();
  }
}

class _CourseScreenState extends State<CourseScreen> {
  late Future<List<Course>> courses;

  @override
  void initState() {
    super.initState();
    courses = fetchCourses();
  }

  void _refreshData() {
    setState(() {
      courses = fetchCourses();
    });
  }

  Future<void> _showUpdateDialog(Course course) async {
    TextEditingController nameController =
        TextEditingController(text: course.courseName);
    TextEditingController creditController =
        TextEditingController(text: course.credit.toString());

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Course'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Course Name',
                  ),
                ),
                TextField(
                  controller: creditController,
                  decoration: const InputDecoration(
                    labelText: 'Credit',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                Course updatedCourse = Course(
                  courseCode: course.courseCode,
                  courseName: nameController.text,
                  credit: int.parse(creditController.text),
                );
                await updateCourse(updatedCourse);
                _refreshData();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
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
        title: const Text('Course'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
        ],
      ),
      body: Center(
        child: FutureBuilder<List<Course>>(
          future: courses,
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
                        Text(
                          'Total ${snapshot.data!.length} items',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: snapshot.data!.isNotEmpty
                        ? ListView.separated(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(snapshot.data![index].courseName),
                                subtitle:
                                    Text(snapshot.data![index].courseCode),
                                trailing: Wrap(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        _showUpdateDialog(
                                            snapshot.data![index]);
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
                                                "Do you want to delete: ${snapshot.data![index].courseCode}",
                                              ),
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                ),
                                                onPressed: () async {
                                                  await deleteCourse(
                                                      snapshot.data![index]);
                                                  _refreshData();
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
                        : const Center(
                            child: Text('No items'),
                          ),
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

// สรัางฟังก์ชั่นดึงข้อมูล คืนค่ากลับมาเป็นข้อมูล Future ประเภท List ของ Course
Future<List<Course>> fetchCourses() async {
  // ทำการดึงข้อมูลจาก server ตาม url ที่กำหนด
  final response = await http.get(Uri.parse('http://127.0.0.1/api/course.php'));

  // เมื่อมีข้อมูลกลับมา
  if (response.statusCode == 200) {
    // ส่งข้อมูลที่เป็น JSON String data ไปทำการแปลง เป็นข้อมูล List<Course
    // โดยใช้คำสั่ง compute ทำงานเบื้องหลัง เรียกใช้ฟังก์ชั่นชื่อ parsecourses
    // ส่งข้อมูล JSON String data ผ่านตัวแปร response.body
    return compute(parseCourses, response.body);
  } else {
    // กรณี error
    throw Exception('Failed to load Course');
  }
}

Future<int> deleteCourse(Course course) async {
  final response = await http.delete(
    Uri.parse(
        'http://127.0.0.1/api/course.php?course_code=${course.courseCode}'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  if (response.statusCode == 200) {
    // If the server returns a 200 OK response, return the status code.
    return response.statusCode;
  } else {
    // If the server does not return a 200 OK response, throw an exception.
    throw Exception('Failed to delete course.');
  }
}

Future<int> updateCourse(Course course) async {
  final response = await http.put(
    Uri.parse('http://127.0.0.1/api/course.php'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'course_code': course.courseCode,
      'course_name': course.courseName,
      'credit': course.credit,
    }),
  );

  if (response.statusCode == 200) {
    // If the server returns a 200 OK response, parse the JSON.
    return response.statusCode;
  } else {
    // If the server does not return a 200 OK response, throw an exception.
    throw Exception('Failed to update course.');
  }
}

// ฟังก์ชั่นแปลงข้อมูล JSON String data เป็น เป็นข้อมูล List<Course>
List<Course> parseCourses(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Course>((json) => Course.fromJson(json)).toList();
}
