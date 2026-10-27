import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/post.dart';
import '../user_model.dart';
import 'profile.dart';

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key, required this.post});
  final Post post;

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  Future<UserModel?> _fetchUser(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("User")
          .doc(uid)
          .get();
      if (snap.exists) {
        return UserModel.fromJson(snap.data() as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _addComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sending = true;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final commentId = FirebaseFirestore.instance.collection("Comment").doc().id;
      await FirebaseFirestore.instance.collection("Comment").doc(commentId).set({
        "id": commentId,
        "post_id": widget.post.id,
        "user_id": uid,
        "text": text,
        "createdAt": FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance
          .collection("Post")
          .doc(widget.post.id)
          .update({"comment_cnt": FieldValue.increment(1)});
      _controller.clear();
    } catch (_) {
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          "Comments",
          style: GoogleFonts.poppins(fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("Comment")
                  .where("post_id", isEqualTo: widget.post.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Failed to load comments"));
                }
                final docs = List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? []);
                docs.sort((a, b) {
                  final at = (a.data() as Map<String, dynamic>)["createdAt"];
                  final bt = (b.data() as Map<String, dynamic>)["createdAt"];
                  final aTs = at is Timestamp ? at : null;
                  final bTs = bt is Timestamp ? bt : null;
                  if (aTs == null && bTs == null) return 0;
                  if (aTs == null) return -1;
                  if (bTs == null) return 1;
                  return aTs.compareTo(bTs);
                });
                if (docs.isEmpty) {
                  return const Center(child: Text("No comments yet"));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final uid = data["user_id"] as String? ?? "";
                    final text = data["text"] as String? ?? "";
                    return FutureBuilder<UserModel?>(
                      future: _fetchUser(uid),
                      builder: (context, userSnap) {
                        final user = userSnap.data;
                        return ListTile(
                          leading: GestureDetector(
                            onTap: () {
                              if (user != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfilePage(profileUser: user),
                                  ),
                                );
                              }
                            },
                            child: CircleAvatar(
                              backgroundImage: user?.imgUrl != null && user!.imgUrl!.isNotEmpty
                                  ? NetworkImage(user.imgUrl!)
                                  : const AssetImage("images/default_profile.png") as ImageProvider,
                            ),
                          ),
                          title: Text(user?.name ?? "User"),
                          subtitle: Text(text),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Write a comment...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sending ? null : _addComment,
                  child: _sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Send"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
