import 'package:mpl_lab/Pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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
  Map<String, int> totalLectures = {};
  DocumentReference? classRef;

  @override
  void initState() {
    super.initState();
    classRef =
        FirebaseFirestore.instance.collection('classes').doc(widget.classId);
    _fetchClassDetails();
    _fetchTimetable();
    _fetchTotalLectures();
  }

  Future<void> _fetchTotalLectures() async {
    if (selectedSubject == null) return;

    try {
      DocumentSnapshot lectureDoc =
          await classRef!.collection('totalLectures').doc('subjects').get();

      if (lectureDoc.exists) {
        Map<String, dynamic> data = lectureDoc.data() as Map<String, dynamic>;
        setState(() {
          totalLectures = {};
          data.forEach((key, value) {
            if (value is num) {
              totalLectures[key] = value.toInt();
            } else if (value is Map) {
              // If the value is a map, try to get the count from it
              var count = value['count'];
              if (count is num) {
                totalLectures[key] = count.toInt();
              } else {
                totalLectures[key] = 0;
              }
            } else {
              totalLectures[key] = 0;
            }
          });
        });
      }
    } catch (e) {
      debugPrint('Error fetching total lectures: $e');
    }
  }

  Widget attendancePercentageWidget(int attendance, int totalLectures) {
    return Text(
      "(${((attendance / totalLectures) * 100).toStringAsFixed(1)}%)",
      style: GoogleFonts.montserrat(
        fontSize: 14,
        color: Colors.green.shade700,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> _updateTotalLectures(String subject, int count) async {
    try {
      if (classRef == null) return;

      DocumentReference lectureRef =
          classRef!.collection('totalLectures').doc(subject);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot lectureDoc = await transaction.get(lectureRef);

        Map<String, dynamic> data = lectureDoc.exists
            ? (lectureDoc.data() as Map<String, dynamic>)
            : {};

        data[subject] = count;

        transaction.set(lectureRef, data);
      });
    } catch (e) {
      debugPrint('Error updating total lectures: $e');
    }
  }

  Future<void> _fetchClassDetails({bool preserveSelection = false}) async {
    try {
      DocumentSnapshot classDoc = await classRef!.get();

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
    String teacherId = await fetchAndPrintTeacherId();
    //print(teacherId);

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
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        title: Text(
          "$className - ($room)",
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          if (subjects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButton<String>(
                  value: selectedSubject,
                  dropdownColor: Colors.blue.shade600,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                  underline: Container(),
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedSubject = newValue;
                    });
                  },
                  items:
                      subjects.map<DropdownMenuItem<String>>((String subject) {
                    return DropdownMenuItem<String>(
                      value: subject,
                      child: Text(subject),
                    );
                  }).toList(),
                ),
              ),
            ),
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.blue.shade700),
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
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
              ),
              child: Column(
                children: [
                  // Timetable Section
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: Colors.blue.shade700),
                            SizedBox(width: 8),
                            Text(
                              "Today's Timetable",
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        Divider(color: Colors.blue.shade100, thickness: 1),
                        timetable.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    "No classes scheduled for today!",
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: timetable
                                    .map((entry) => Container(
                                          margin:
                                              EdgeInsets.symmetric(vertical: 6),
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.blue.shade100),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade100,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(Icons.schedule,
                                                    color:
                                                        Colors.blue.shade700),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      entry['subject']
                                                          .toUpperCase(),
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Colors
                                                            .blue.shade800,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      "Class: ${entry['room']} | Time: ${entry['time']}",
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        fontSize: 14,
                                                        color: Colors
                                                            .grey.shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ),
                      ],
                    ),
                  ),

                  // Students Section
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people, color: Colors.blue.shade700),
                              SizedBox(width: 8),
                              Text(
                                "Students",
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              Spacer(),
                              if (selectedSubject != null)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        selectedSubject!,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon:
                                                  Icon(Icons.remove, size: 16),
                                              onPressed: () {
                                                setState(() {
                                                  int newCount = (totalLectures[
                                                              selectedSubject!] ??
                                                          0) -
                                                      1;
                                                  if (newCount < 0)
                                                    newCount = 0;
                                                  totalLectures[
                                                          selectedSubject!] =
                                                      newCount;
                                                  _updateTotalLectures(
                                                      selectedSubject!,
                                                      newCount);
                                                });
                                              },
                                              padding: EdgeInsets.all(4),
                                              constraints: BoxConstraints(
                                                  minWidth: 24, minHeight: 24),
                                            ),
                                            Text(
                                              '${totalLectures[selectedSubject!] ?? 0}',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.add, size: 16),
                                              onPressed: () {
                                                setState(() {
                                                  int newCount = (totalLectures[
                                                              selectedSubject!] ??
                                                          0) +
                                                      1;
                                                  totalLectures[
                                                          selectedSubject!] =
                                                      newCount;
                                                  _updateTotalLectures(
                                                      selectedSubject!,
                                                      newCount);
                                                });
                                              },
                                              padding: EdgeInsets.all(4),
                                              constraints: BoxConstraints(
                                                  minWidth: 24, minHeight: 24),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          Divider(color: Colors.blue.shade100, thickness: 1),
                          Expanded(
                            child: students.isEmpty
                                ? Center(
                                    child: Text(
                                      "No students found in $className.",
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.only(top: 8),
                                    itemCount: students.length,
                                    itemBuilder: (context, index) {
                                      students.sort((a, b) =>
                                          a['roll'].compareTo(b['roll']));
                                      final student = students[index];
                                      final attendance = student['attendance']
                                              [selectedSubject] ??
                                          0;

                                      return Card(
                                        elevation: 0,
                                        margin: EdgeInsets.only(bottom: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: BorderSide(
                                              color: Colors.blue.shade100),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor:
                                                    Colors.blue.shade100,
                                                child: Text(
                                                  student['name']
                                                      .substring(0, 1)
                                                      .toUpperCase(),
                                                  style: GoogleFonts.montserrat(
                                                    color: Colors.blue.shade700,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "${student['name']} (${student['roll']})",
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(height: 2),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "Attendance: $attendance",
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            fontSize: 12,
                                                            color: Colors.grey,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        SizedBox(width: 6),
                                                        Text(
                                                          "(${((attendance / (totalLectures[selectedSubject!] ?? 1)) * 100).toStringAsFixed(1)}%)",
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .green.shade700,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                        Icons
                                                            .remove_circle_outline,
                                                        color: Colors
                                                            .red.shade400),
                                                    onPressed: () =>
                                                        updateAttendance(
                                                            student['id'],
                                                            false),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                        Icons
                                                            .add_circle_outline,
                                                        color: Colors
                                                            .green.shade400),
                                                    onPressed: () =>
                                                        updateAttendance(
                                                            student['id'],
                                                            true),
                                                  ),
                                                ],
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
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
