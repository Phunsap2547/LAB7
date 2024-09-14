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
    print("initState"); // สำหรับทดสอบ
    super.initState();
    courses = (widget.courses ?? []).toList();
    examResults = fetchExamResults(courses!.first.courseCode);
  }

  void _refreshData(String courseCode) {
    setState(() {
      print("setState"); // สำหรับทดสอบ
      examResults = fetchExamResults(courseCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Result'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
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
                          child: DropdownMenu<String>(
                            initialSelection: courses!.first.courseCode,
                            onSelected: (String? value) {
                              // This is called when the user selects an item.
                              setState(() {
                                dropdownValue = value!;
                                _refreshData(dropdownValue);
                              });
                            },
                            dropdownMenuEntries: courses!
                                .map<DropdownMenuEntry<String>>((Course value) {
                              return DropdownMenuEntry<String>(
                                  value: value.courseCode,
                                  label: value.courseCode);
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
