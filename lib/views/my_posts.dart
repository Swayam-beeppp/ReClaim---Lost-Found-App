import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khuje_pai/components/post.dart';
import 'package:khuje_pai/widget/post_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  Future<String> _currentCollegeCode(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection("User").doc(uid).get();
    if (!userDoc.exists) return "";
    return (userDoc.data()?["collegeCode"] ?? "").toString().trim();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user's ID
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(
        child: Text(
          "User not logged in!",
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'My Posts',
          style: GoogleFonts.poppins(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
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
        future: _currentCollegeCode(currentUser.uid),
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
          if (code.isEmpty) {
            return const Center(
              child: Text(
                "College not set for this account!",
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            );
          }
          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("Post")
                .where("user_id", isEqualTo: currentUser.uid)
                .where("collegeCode", isEqualTo: code)
                .snapshots(),
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
                  final data = doc.data() as Map<String, dynamic>;
                  final caption = (data['caption'] ?? "").toString().toLowerCase();
                  return caption.contains(_searchQuery);
                }).toList();

                if (filteredPosts.isNotEmpty) {
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final postData = filteredPosts[index].data() as Map<String, dynamic>;
                      final post = Post.fromJson(postData);
                      return PostTile(post: post, deleteOption: true);
                    },
                  );
                }

                return const Center(
                  child: Text(
                    "No posts found!",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
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
