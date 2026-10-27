import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../user_model.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.otherUserId});
  final String otherUserId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  String _chatId(String a, String b) {
    final list = [a, b]..sort();
    return "${list[0]}_${list[1]}";
  }

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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sending = true;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final cid = _chatId(uid, widget.otherUserId);
      final chatRef = FirebaseFirestore.instance.collection("Chats").doc(cid);
      await chatRef.set({
        "id": cid,
        "user_ids": [uid, widget.otherUserId],
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final msgRef = FirebaseFirestore.instance
          .collection("Chats")
          .doc(cid)
          .collection("messages")
          .doc();
      await msgRef.set({
        "id": msgRef.id,
        "sender_id": uid,
        "text": text,
        "createdAt": FieldValue.serverTimestamp(),
      });
      await chatRef.update({
        "updatedAt": FieldValue.serverTimestamp(),
      });
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
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final cid = _chatId(currentUid, widget.otherUserId);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: FutureBuilder<UserModel?>(
          future: _fetchUser(widget.otherUserId),
          builder: (context, snap) {
            final name = snap.data?.name ?? "Chat";
            return Text(
              name,
              style: GoogleFonts.poppins(fontSize: 25, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("Chats")
                  .doc(cid)
                  .collection("messages")
                  .orderBy("createdAt", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final msgs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final data = msgs[index].data() as Map<String, dynamic>;
                    final isMe = data["sender_id"] == currentUid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data["text"] ?? "",
                          style: TextStyle(color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
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
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sending ? null : _sendMessage,
                  child: _sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Send"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
