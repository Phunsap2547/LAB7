import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../model/course.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<StatefulWidget> createState() => _CourseScreenState();
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

  Future<void> _showCourseDialog({Course? course}) async {
    TextEditingController codeController =
        TextEditingController(text: course?.courseCode ?? '');
    TextEditingController nameController =
        TextEditingController(text: course?.courseName ?? '');
    TextEditingController creditController =
        TextEditingController(text: course?.credit.toString() ?? '');

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(course == null ? 'Create Course' : 'Update Course'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Course Code',
                  ),
                  keyboardType: TextInputType.text,
                  readOnly: course != null,
                ),
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
              child: Text(course == null ? 'Create' : 'Update'),
              onPressed: () async {
                try {
                  Course newOrUpdatedCourse = Course(
                    courseCode: codeController.text,
                    courseName: nameController.text,
                    credit: int.parse(creditController.text),
                  );

                  if (course == null) {
                    await createCourse(newOrUpdatedCourse);
                  } else {
                    await updateCourse(newOrUpdatedCourse);
                  }

                  _refreshData();
                  Navigator.of(context).pop();
                } catch (e) {
                  // Handle parse or network errors
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Error'),
                      content: Text('An error occurred: $e'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('OK'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  );
                }
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
        title: const Text('Courses'),
        actions: [
          IconButton(
            onPressed: () => _showCourseDialog(),
            icon: const Icon(Icons.add),
          ),
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
                                  spacing: 8.0,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        _showCourseDialog(
                                            course: snapshot.data![index]);
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
                                            content: Text(
                                                "Do you want to delete: ${snapshot.data![index].courseCode}?"),
                                            actions: <Widget>[
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                ),
                                                onPressed: () async {
                                                  try {
                                                    await deleteCourse(
                                                        snapshot.data![index]);
                                                    _refreshData();
                                                    Navigator.pop(context);
                                                  } catch (e) {
                                                    // Handle network error
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                              context) =>
                                                          AlertDialog(
                                                        title:
                                                            const Text('Error'),
                                                        content: Text(
                                                            'An error occurred: $e'),
                                                        actions: <Widget>[
                                                          TextButton(
                                                            child: const Text(
                                                                'OK'),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }
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
                                                child: const Text('Cancel'),
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
              return Text('Error: ${snapshot.error}');
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCourseDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Function to fetch courses from the server
Future<List<Course>> fetchCourses() async {
  final response = await http.get(Uri.parse('http://127.0.0.1/api/course.php'));

  if (response.statusCode == 200) {
    return compute(parseCourses, response.body);
  } else {
    throw Exception('Failed to load courses');
  }
}

// Function to delete a course
Future<void> deleteCourse(Course course) async {
  final response = await http.delete(
    Uri.parse(
        'http://127.0.0.1/api/course.php?course_code=${course.courseCode}'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to delete course');
  }
}

// Function to update a course
Future<void> updateCourse(Course course) async {
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

  if (response.statusCode != 200) {
    throw Exception('Failed to update course');
  }
}

// Function to create a new course
Future<void> createCourse(Course course) async {
  final response = await http.post(
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

  if (response.statusCode != 200) {
    throw Exception('Failed to create course');
  }
}

// Function to parse JSON response and return a list of courses
List<Course> parseCourses(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Course>((json) => Course.fromJson(json)).toList();
}
