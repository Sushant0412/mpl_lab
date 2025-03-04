import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<Map<String, String?>> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: user.email)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        var userData = querySnapshot.docs.first;
        return {
          'name': userData['name'],
          'email': userData['email'],
          'phone': userData['phone'].toString(),
        };
      }
    }
    return {'name': 'Unknown', 'email': 'N/A', 'phone': 'N/A'};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<Map<String, String?>>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error loading data'));
          }
          final userData = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                      'https://media.istockphoto.com/id/1338134319/photo/portrait-of-young-indian-businesswoman-or-school-teacher-pose-indoors.jpg?s=612x612&w=0&k=20&c=Dw1nKFtnU_Bfm2I3OPQxBmSKe9NtSzux6bHqa9lVZ7A='),
                ),
                const SizedBox(height: 20),
                Text(
                  userData['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Assistant Professor',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                _InfoCard(
                  icon: Icons.email,
                  title: 'Email',
                  subtitle: userData['email'] ?? 'N/A',
                ),
                _InfoCard(
                  icon: Icons.phone,
                  title: 'Phone',
                  subtitle: userData['phone'] ?? 'N/A',
                ),
                const _InfoCard(
                  icon: Icons.location_on,
                  title: 'Location',
                  subtitle: 'Mumbai, INDIA',
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
