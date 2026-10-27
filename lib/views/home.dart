import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khuje_pai/components/post.dart';
import 'package:khuje_pai/widget/post_tile.dart';
import 'package:khuje_pai/views/request.dart';
import 'package:khuje_pai/views/notifications.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  Future<String> _currentCollegeCode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return "";
    final userDoc = await FirebaseFirestore.instance.collection("User").doc(uid).get();
    if (!userDoc.exists) return "";
    return (userDoc.data()?["collegeCode"] ?? "").toString().trim();
  }

  DateTime _parseCreatedAt(dynamic createdAt) {
    if (createdAt is Timestamp) return createdAt.toDate();
    if (createdAt is String) return DateTime.tryParse(createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset('images/logo_new.png', height: 28),
            const SizedBox(width: 8),
            Text(
              'ReClaim',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestPage()));
            },
            icon: const Icon(Icons.add_circle_outline),
            tooltip: "Report Lost Item",
          ),
          IconButton(
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
            },
            icon: const Icon(Icons.notifications_none),
            tooltip: "Notifications",
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search posts by caption...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
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
            return const Center(
              child: Text(
                "Error loading posts!",
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            );
          }
          final code = codeSnap.data!.trim();
          final Query<Map<String, dynamic>> query = code.isEmpty
              ? FirebaseFirestore.instance.collection("Post")
              : FirebaseFirestore.instance
              .collection("Post")
              .where("collegeCode", isEqualTo: code);
          return StreamBuilder(
            stream: query.snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    "Error loading posts!",
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                );
              }
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                final filteredPosts = snapshot.data!.docs.where((doc) {
                  final raw = doc.data() as Map<String, dynamic>;
                  final caption = (raw['caption'] ?? "").toString().toLowerCase();
                  return caption.contains(_searchQuery);
                }).toList()
                  ..sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aCreatedAt = _parseCreatedAt(aData["createdAt"]);
                    final bCreatedAt = _parseCreatedAt(bData["createdAt"]);
                    return bCreatedAt.compareTo(aCreatedAt);
                  });
                if (filteredPosts.isNotEmpty) {
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final postData = filteredPosts[index].data() as Map<String, dynamic>;
                      Post post = Post.fromJson(postData);
                      return PostTile(post: post);
                    },
                  );
                } else {
                  return const Center(
                    child: Text(
                      "No posts found!",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }
              }
              return const Center(
                child: Text(
                  "No posts available!",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
