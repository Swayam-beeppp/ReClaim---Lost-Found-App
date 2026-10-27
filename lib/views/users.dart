import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../user_model.dart';
import 'chat.dart';
import 'profile.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  Future<String> _currentCollegeCode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return "";
    final userDoc = await FirebaseFirestore.instance.collection("User").doc(uid).get();
    if (!userDoc.exists) return "";
    return (userDoc.data()?["collegeCode"] ?? "").toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Users',
          style: GoogleFonts.poppins(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<String>(
        future: _currentCollegeCode(),
        builder: (context, codeSnap) {
          if (codeSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (codeSnap.hasError || !codeSnap.hasData) {
            return const Center(child: Text("Failed to load users"));
          }
          final code = codeSnap.data!.trim();
          if (code.isEmpty) {
            return const Center(child: Text("College not set for this account"));
          }
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("User")
                .where("collegeCode", isEqualTo: code)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Failed to load users"));
              }
              final docs = snapshot.data?.docs ?? [];
              final users = docs
                  .map((d) => UserModel.fromJson(d.data() as Map<String, dynamic>))
                  .where((u) => (u.id ?? "").isNotEmpty && (u.id ?? "") != currentUid)
                  .toList();
              if (users.isEmpty) {
                return const Center(child: Text("No other users found"));
              }
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final u = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: u.imgUrl != null && u.imgUrl!.isNotEmpty
                          ? NetworkImage(u.imgUrl!)
                          : const AssetImage("images/default_profile.png") as ImageProvider,
                    ),
                    title: Text(u.name ?? "User"),
                    subtitle: Text(u.email ?? ""),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfilePage(profileUser: u)),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.chat_bubble, color: Colors.green),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChatPage(otherUserId: u.id ?? "")),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
