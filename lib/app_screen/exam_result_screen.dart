import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../model/course.dart';
import '../model/exam_result.dart';

import 'package:http/http.dart' as http;

class ExamResultScreen extends StatefulWidget {
  final List<Course>? courses;
  const ExamResultScreen({
    super.key,
    this.courses,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  List<Course>? courses;
  late Future<List<ExamResult>> examResults;
  String dropdownValue = "";

  @override
  void initState() {
    super.initState();
    courses = (widget.courses ?? []).toList();
    dropdownValue = courses!.isNotEmpty ? courses!.first.courseCode : "";
    examResults = fetchExamResults(dropdownValue);
  }

  void _refreshData(String courseCode) {
    setState(() {
      print("setState"); // สำหรับทดสอบ
      examResults = fetchExamResults(courseCode);
    });
  }

  Future<void> _showAddExamResultDialog() async {
    final studentCodeController = TextEditingController();
    final pointController = TextEditingController();
    String? selectedCourseCode = courses!.isNotEmpty
        ? courses!.first.courseCode
        : null; // Default to the first course code in the list

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Exam Result'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: studentCodeController,
                  decoration: const InputDecoration(hintText: 'Student Code'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCourseCode,
                  decoration: const InputDecoration(hintText: 'Course Code'),
                  items:
                      courses!.map<DropdownMenuItem<String>>((Course course) {
                    return DropdownMenuItem<String>(
                      value: course.courseCode,
                      child: Text(course.courseCode),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCourseCode = newValue!;
                    });
                  },
                ),
                TextField(
                  controller: pointController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Point'),
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
                final examResult = ExamResult(
                  studentCode: studentCodeController.text,
                  courseCode: selectedCourseCode!,
                  point: double.parse(pointController.text),
                );
                await insertExamResult(examResult);
                _refreshData(examResult.courseCode); // Refresh the list
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<int> insertExamResult(ExamResult examResult) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1/api/exam_result.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'student_code': examResult.studentCode,
        'course_code': examResult.courseCode,
        'point': examResult.point,
      }),
    );

    if (response.statusCode == 200) {
      return response.statusCode;
    } else {
      throw Exception('Failed to insert exam result');
    }
  }

  Future<void> _showEditExamResultDialog(ExamResult examResult) async {
    final studentCodeController =
        TextEditingController(text: examResult.studentCode);
    final courseCodeController =
        TextEditingController(text: examResult.courseCode);
    final pointController =
        TextEditingController(text: examResult.point.toString());

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Exam Result'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: studentCodeController,
                  decoration: const InputDecoration(hintText: 'Student Code'),
                ),
                TextField(
                  controller: courseCodeController,
                  decoration: const InputDecoration(hintText: 'Course Code'),
                ),
                TextField(
                  controller: pointController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Point'),
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
              child: const Text('Update'),
              onPressed: () async {
                final updatedExamResult = ExamResult(
                  studentCode: studentCodeController.text,
                  courseCode: courseCodeController.text,
                  point: double.parse(pointController.text),
                );
                await updateExamResult(updatedExamResult);
                _refreshData(updatedExamResult
                    .courseCode); // Refresh the list with the new courseCode
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<int> updateExamResult(ExamResult examResult) async {
    final response = await http.put(
      Uri.parse('http://127.0.0.1/api/exam_result.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'student_code': examResult.studentCode,
        'course_code': examResult.courseCode,
        'point': examResult.point,
      }),
    );

    if (response.statusCode == 200) {
      return response.statusCode;
    } else {
      throw Exception('Failed to update exam result');
    }
  }

  Future<void> _deleteExamResult(ExamResult examResult) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this exam result?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                await deleteExamResult(examResult);
                _refreshData(examResult.courseCode);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<int> deleteExamResult(ExamResult examResult) async {
    final response = await http.delete(
      Uri.parse(
          'http://127.0.0.1/api/exam_result.php?student_code=${examResult.studentCode}&course_code=${examResult.courseCode}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return response.statusCode;
    } else {
      throw Exception('Failed to delete exam result');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddExamResultDialog(); // Open the dialog to add a new result
            },
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<List<ExamResult>>(
          // ชนิดของข้อมูล
          future: examResults, // ข้อมูล Future
          builder: (context, snapshot) {
            print("builder"); // สำหรับทดสอบ
            print(snapshot.connectionState); // สำหรับทดสอบ
            // กรณีสถานะเป็น waiting ยังไม่มีข้อมูล แสดงตัว loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasData) {
              // กรณีมีข้อมูล
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text("Course:"),
                        ),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: dropdownValue.isEmpty
                                ? courses!.first.courseCode
                                : dropdownValue,
                            decoration: const InputDecoration(
                                hintText: 'Select Course Code'),
                            onChanged: (String? newValue) {
                              setState(() {
                                dropdownValue = newValue!;
                                _refreshData(dropdownValue);
                              });
                            },
                            items: courses!
                                .map<DropdownMenuItem<String>>((Course course) {
                              return DropdownMenuItem<String>(
                                value: course.courseCode,
                                child: Text(course.courseCode),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    // สร้างส่วน header ของลิสรายการ
                    padding: const EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      color: Colors.teal.withAlpha(100),
                    ),
                    child: Row(
                      children: [
                        Text(
                            'Total ${snapshot.data!.length} items'), // แสดงจำนวนรายการ
                      ],
                    ),
                  ),
                  Expanded(
                    // ส่วนของลิสรายการ
                    child: snapshot.data!.isNotEmpty // กำหนดเงื่อนไขตรงนี้
                        ? ListView.separated(
                            // กรณีมีรายการ แสดงปกติ
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(snapshot.data![index].studentCode),
                                subtitle: Text(
                                    snapshot.data![index].point.toString()),
                                trailing: Wrap(
                                  spacing: 12, // Adds space between buttons
                                  children: <Widget>[
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        _showEditExamResultDialog(
                                            snapshot.data![index]);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        _deleteExamResult(
                                            snapshot.data![index]);
                                      },
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
                            child: Text('No items')), // กรณีไม่มีรายการ
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              // กรณี error
              return Text('${snapshot.error}');
            }
            // กรณีสถานะเป็น waiting ยังไม่มีข้อมูล แสดงตัว loading
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}

// สรัางฟังก์ชั่นดึงข้อมูล คืนค่ากลับมาเป็นข้อมูล Future ประเภท List ของ Course
Future<List<ExamResult>> fetchExamResults(String courseCode) async {
  // ทำการดึงข้อมูลจาก server ตาม url ที่กำหนด
  final response = await http.get(Uri.parse(
      'http://127.0.0.1/api/exam_result.php?course_code=$courseCode'));

  // เมื่อมีข้อมูลกลับมา
  if (response.statusCode == 200) {
    // ส่งข้อมูลที่เป็น JSON String data ไปทำการแปลง เป็นข้อมูล List<Course
    // โดยใช้คำสั่ง compute ทำงานเบื้องหลัง เรียกใช้ฟังก์ชั่นชื่อ parsecourses
    // ส่งข้อมูล JSON String data ผ่านตัวแปร response.body
    return compute(parseExamResults, response.body);
  } else {
    // กรณี error
    throw Exception('Failed to load Course');
  }
}

// ฟังก์ชั่นแปลงข้อมูล JSON String data เป็น เป็นข้อมูล List<Course>
List<ExamResult> parseExamResults(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<ExamResult>((json) => ExamResult.fromJson(json)).toList();
}
