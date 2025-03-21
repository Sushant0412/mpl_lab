import 'package:mpl_lab/Widgets/class.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  User? user = FirebaseAuth.instance.currentUser;
  String username = '';
  List<Map<String, String>> classes = []; // Store classId and className

  @override
  void initState() {
    super.initState();
    _fetchOrCreateTeacher();
  }

  Future<void> _fetchOrCreateTeacher() async {
    if (user == null) {
      print("No authenticated user found.");
      return;
    }

    String email = user!.email ?? '';
    print("Fetching teacher with email: $email");

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('teachers')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isEmpty) {
      print("No teacher found. Creating new teacher profile...");
      DocumentReference newTeacherRef =
          FirebaseFirestore.instance.collection('teachers').doc();
      await newTeacherRef.set({
        'name': email.split('@')[0],
        'email': email,
        'classes': [],
      });
      setState(() {
        username = email.split('@')[0];
      });

      setState(() {
        classes = [];
      });
    } else {
      var doc = querySnapshot.docs.first;
      print("Teacher document found: ${doc.id}");
      setState(() {
        username = doc['name'] ?? email.split('@')[0];
      });

      List<dynamic>? classRefs = doc['classes'];

      if (classRefs == null || classRefs.isEmpty) {
        print("No classes assigned to this teacher.");
        setState(() {
          classes = [];
        });
        return;
      }

      print("Classes assigned to teacher: $classRefs");

      List<Map<String, String>> tempClasses = [];

      for (String classId in classRefs) {
        print("Fetching details for class ID: $classId");
        DocumentSnapshot classDoc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .get();

        if (classDoc.exists) {
          print("Class found: ${classDoc['Name']}, Room: ${classDoc['Room']}");
          tempClasses.add({
            'id': classId,
            'name': classDoc['Name'] ?? 'Unknown',
            'room': classDoc['Room'] ?? 'N/A',
          });
        } else {
          print("Class ID $classId does not exist in Firestore.");
        }
      }

      setState(() {
        classes = tempClasses;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Home Page",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Hello, $username",
                style: TextStyle(fontSize: 60),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              "Your Classes",
              style: TextStyle(fontSize: 24),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                return MyClass(
                  classId: classes[index]['id']!,
                  className: classes[index]['name']!,
                  room: classes[index]['room']!,
                );
              },
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "©️ Copyright - Sushant 2025",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
