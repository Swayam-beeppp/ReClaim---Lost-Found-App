import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Future<Map<String, String>> _viewerContext() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return {"uid": "", "collegeCode": ""};
    final doc = await FirebaseFirestore.instance.collection("User").doc(uid).get();
    if (!doc.exists) return {"uid": uid, "collegeCode": ""};
    final code = (doc.data()?["collegeCode"] ?? "").toString();
    return {"uid": uid, "collegeCode": code};
  }

  DateTime _createdAt(Map<String, dynamic> data) {
    final value = data["createdAt"];
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _viewerContext(),
      builder: (context, viewerSnap) {
        if (viewerSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final viewer = viewerSnap.data ?? {"uid": "", "collegeCode": ""};
        final uid = viewer["uid"] ?? "";
        final code = viewer["collegeCode"] ?? "";
        final query = code.isEmpty
            ? FirebaseFirestore.instance.collection("Notifications")
            : FirebaseFirestore.instance
                .collection("Notifications")
                .where("collegeCode", isEqualTo: code);
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text("Notifications"),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Failed to load notifications"));
              }
              final docs = (snapshot.data?.docs ?? []).where((d) {
                final data = d.data() as Map<String, dynamic>;
                final target = (data["targetUserId"] ?? "").toString();
                return target.isEmpty || target == uid;
              }).toList()
                ..sort((a, b) {
                  final ad = a.data() as Map<String, dynamic>;
                  final bd = b.data() as Map<String, dynamic>;
                  return _createdAt(bd).compareTo(_createdAt(ad));
                });
              if (docs.isEmpty) {
                return const Center(child: Text("No notifications"));
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final type = (data["type"] ?? "").toString();
                  final title = (data["title"] ?? "").toString();
                  final message = (data["message"] ?? "").toString();
                  IconData icon = Icons.notifications_none;
                  if (type == "post") icon = Icons.inventory_2;
                  if (type == "request") icon = Icons.report;
                  if (type == "request_match") icon = Icons.smart_toy_outlined;
                  return ListTile(
                    leading: Icon(icon),
                    title: Text(title),
                    subtitle: Text(message.isEmpty ? type : message),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
