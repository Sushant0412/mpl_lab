import 'package:mpl_lab/Pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ClassDetail extends StatefulWidget {
  final String classId;

  const ClassDetail({super.key, required this.classId});

  @override
  _ClassDetailState createState() => _ClassDetailState();
}

class _ClassDetailState extends State<ClassDetail> {
  bool _isLoading = true;
  String className = "";
  String room = "";
  List<String> subjects = [];
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> timetable = [];
  String? selectedSubject;

  @override
  void initState() {
    super.initState();
    _fetchClassDetails();
    _fetchTimetable();
  }

  Future<void> _fetchClassDetails({bool preserveSelection = false}) async {
    try {
      DocumentSnapshot classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();

      if (classDoc.exists) {
        className = classDoc['Name'];
        room = classDoc['Room'];
        List<String> newSubjects =
            List<String>.from(classDoc['subjects'] ?? []);

        if (!preserveSelection || !newSubjects.contains(selectedSubject)) {
          selectedSubject = newSubjects.isNotEmpty ? newSubjects.first : null;
        }

        subjects = newSubjects;
      }

      QuerySnapshot studentDocs = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .get();

      students = studentDocs.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'roll': doc['roll'],
          'attendance': Map<String, dynamic>.from(doc['attendance'] ?? {}),
        };
      }).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Error fetching data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<String?> getTeacherDocumentId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null; // Ensure user is logged in

    String email = user.email ?? ""; // Use email to query Firestore

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('teachers')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id; // Return the document ID
    } else {
      return null; // No matching document found
    }
  }

  Future<String> fetchAndPrintTeacherId() async {
    String? docId = await getTeacherDocumentId();
    if (docId != null) {
      return docId;
    } else {
      return "";
    }
  }

  Future<void> _fetchTimetable() async {
    String today = DateFormat('EEEE').format(DateTime.now()); // Get today's day
    //String userId = getUserId(); // Replace with actual user ID
    //print(userId);
    String teacherId = await fetchAndPrintTeacherId();
    print(teacherId);

    try {
      QuerySnapshot timetableDocs = await FirebaseFirestore.instance
          .collection('timetables')
          .where('day', isEqualTo: today)
          .where('classID', isEqualTo: widget.classId)
          .where('teacherId', isEqualTo: teacherId)
          .get(); // Fetch all documents

      List<Map<String, dynamic>> filteredTimetable = timetableDocs.docs
          .map((doc) => {
                'time': doc['time'] ?? 'N/A',
                'subject': doc['subject'] ?? 'Unknown',
                'room': doc['class'] ?? 'N/A',
              })
          .toList();

      setState(() {
        timetable = filteredTimetable;
      });
    } catch (e) {
      print("Error fetching timetable: $e");
    }
  }

  Future<void> updateAttendance(String studentId, bool increase) async {
    if (selectedSubject == null) return;

    DocumentReference studentRef = FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('students')
        .doc(studentId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot studentDoc = await transaction.get(studentRef);

      if (studentDoc.exists) {
        Map<String, dynamic> attendanceData =
            Map<String, dynamic>.from(studentDoc['attendance'] ?? {});

        int currentAttendance = (attendanceData[selectedSubject!] ?? 0);

        attendanceData[selectedSubject!] = increase
            ? currentAttendance + 1
            : (currentAttendance > 0 ? currentAttendance - 1 : 0);

        transaction.update(studentRef, {'attendance': attendanceData});
      }
    });

    _fetchClassDetails(preserveSelection: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$className - ($room)",
          style: TextStyle(
              fontFamily: "Roboto", fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (subjects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: DropdownButton<String>(
                value: selectedSubject,
                dropdownColor: Colors.white,
                style: TextStyle(color: Colors.black, fontSize: 16),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSubject = newValue;
                  });
                },
                items: subjects.map<DropdownMenuItem<String>>((String subject) {
                  return DropdownMenuItem<String>(
                    value: subject,
                    child: Text(subject),
                  );
                }).toList(),
              ),
            ),
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Today's Timetable",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                timetable.isEmpty
                    ? Center(
                        child: Text(
                          "No college today!",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      )
                    : Column(
                        children: timetable
                            .map((entry) => ListTile(
                                  title: Text(
                                    entry['subject'].toUpperCase(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  subtitle: Text(
                                    "Class: ${entry['room']} | Time: ${entry['time']}",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  leading:
                                      Icon(Icons.schedule, color: Colors.blue),
                                ))
                            .toList(),
                      ),
                Divider(),
                Expanded(
                  child: students.isEmpty
                      ? Center(
                          child: Text(
                            "No students found in $className.",
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            return Card(
                              elevation: 2,
                              child: ListTile(
                                leading: Icon(Icons.person, color: Colors.blue),
                                title: Text(
                                  "${student['roll']}. ${student['name']}",
                                  style: TextStyle(
                                      fontFamily: "Roboto", fontSize: 16),
                                ),
                                subtitle: Text(
                                  "Attendance in ${selectedSubject ?? 'Subject'}: ${student['attendance'][selectedSubject] ?? 0}",
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.check_circle,
                                          color: Colors.green),
                                      onPressed: () =>
                                          updateAttendance(student['id'], true),
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.cancel, color: Colors.red),
                                      onPressed: () => updateAttendance(
                                          student['id'], false),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
