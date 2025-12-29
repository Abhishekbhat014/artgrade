import 'package:artgrade/features/student/courses/student_course_screen.dart';
import 'package:artgrade/features/student/subjects/student_subjects_screen.dart';
import 'package:flutter/material.dart';

class StudentCoursesNavigator extends StatefulWidget {
  const StudentCoursesNavigator({super.key});

  @override
  State<StudentCoursesNavigator> createState() =>
      _StudentCoursesNavigatorState();
}

class _StudentCoursesNavigatorState extends State<StudentCoursesNavigator> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  void _openSubjects(String courseId, String courseTitle) {
    _navKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) =>
            SubjectsScreen(courseId: courseId, courseTitle: courseTitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navKey,
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => StudentCoursesScreen(onOpenCourse: _openSubjects),
      ),
    );
  }
}
