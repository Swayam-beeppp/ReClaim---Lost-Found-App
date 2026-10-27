import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:khuje_pai/services/notification_service.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final TextEditingController _desc = TextEditingController();
  File? _pickedImage;
  String _imageUrl = "";
  bool _loading = false;
  String _botReply = "Describe what you lost, optionally attach an image, and I will check similar found-item posts.";
  List<Map<String, dynamic>> _matches = [];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final file = File(picked.path);
      setState(() {
        _pickedImage = file;
      });
    }
  }

  Set<String> _tokens(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  double _similarity(String a, String b) {
    final aw = _tokens(a);
    final bw = _tokens(b);
    if (aw.isEmpty || bw.isEmpty) return 0;
    final inter = aw.intersection(bw).length.toDouble();
    final uni = aw.union(bw).length.toDouble();
    if (uni == 0) return 0;
    return inter / uni;
  }

  double _imageHintScore(String requestImageUrl, String postImageUrl) {
    if (requestImageUrl.isEmpty || postImageUrl.isEmpty) return 0;
    final reqName = requestImageUrl.split("/").last.split("?").first;
    final postName = postImageUrl.split("/").last.split("?").first;
    return _similarity(reqName, postName);
  }

  Future<String> _uploadImage(File image) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
    if (cloudName.isEmpty) throw Exception("Cloudinary not configured");
    final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/raw/upload");
    final request = http.MultipartRequest("POST", uri);
    final fileBytes = await image.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: image.path.split("/").last,
    ));
    request.fields['upload_preset'] = "preset-for-post-img-upload";
    request.fields['resource_type'] = "raw";
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw Exception("Image upload failed (${response.statusCode})");
    }
    final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
    return (jsonResponse["secure_url"] ?? "").toString();
  }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final desc = _desc.text.trim();
    if (desc.isEmpty) return;
    setState(() {
      _loading = true;
    });
    try {
      String code = "";
      final userDoc = await FirebaseFirestore.instance.collection("User").doc(uid).get();
      if (userDoc.exists) {
        code = (userDoc.data()?["collegeCode"] ?? "").toString();
      }
      if (code.trim().isEmpty) {
        throw Exception("College code missing for this account");
      }
      if (_pickedImage != null) {
        _imageUrl = await _uploadImage(_pickedImage!);
      }

      final reqId = FirebaseFirestore.instance.collection("Requests").doc().id;
      await FirebaseFirestore.instance.collection("Requests").doc(reqId).set({
        "id": reqId,
        "user_id": uid,
        "collegeCode": code,
        "description": desc,
        "image": _imageUrl,
        "status": "open",
        "createdAt": FieldValue.serverTimestamp(),
      });
      await NotificationService.createRequestNotification(
        requestId: reqId,
        collegeCode: code,
        userId: uid,
        description: desc,
      );

      final postsSnap = await FirebaseFirestore.instance
          .collection("Post")
          .where("collegeCode", isEqualTo: code)
          .get();
      final ranked = postsSnap.docs.map((d) {
        final data = d.data();
        final cap = (data["caption"] ?? "").toString();
        final loc = (data["location"] ?? "").toString();
        final img = (data["imgUrl"] ?? "").toString();
        final textScore = _similarity("$cap $loc", desc);
        final imageScore = _imageHintScore(_imageUrl, img);
        final score = (textScore * 0.85) + (imageScore * 0.15);
        return {"doc": d, "score": score};
      }).where((e) => (e["score"] as double) >= 0.25).toList()
        ..sort((a, b) => (b["score"] as double).compareTo(a["score"] as double));

      final matches = ranked.take(5).map((e) => e["doc"] as QueryDocumentSnapshot).toList();
      if (matches.isNotEmpty) {
        final best = matches.first.data() as Map<String, dynamic>;
        final bestScore = ranked.first["score"] as double;
        await NotificationService.createRequestMatchNotification(
          requestId: reqId,
          postId: (best["id"] ?? "").toString(),
          collegeCode: code,
          targetUserId: uid,
          score: bestScore,
          message: "We found a possible match for your request. Check latest found-item posts.",
        );
      }
      if (mounted) {
        setState(() {
          _matches = matches
              .map((m) => (m.data() as Map<String, dynamic>))
              .toList();
          _botReply = matches.isEmpty
              ? "Request posted. I could not find a strong match yet, but I will keep notifying you when new related found-item posts appear."
              : "Request posted. I found ${matches.length} possible match(es) based on description/image hints.";
          _desc.clear();
          _pickedImage = null;
          _imageUrl = "";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lost-item request submitted")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not submit request: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Report Lost Item"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _desc,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Describe the lost item",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text("Add Image"),
                ),
                const SizedBox(width: 12),
                if (_pickedImage != null) const Text("Image selected"),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Assistant",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xfff4f6fb),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_botReply),
            ),
            if (_matches.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  itemCount: _matches.length,
                  itemBuilder: (context, i) {
                    final m = _matches[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: Text((m["caption"] ?? "Found item").toString()),
                        subtitle: Text((m["location"] ?? "").toString()),
                      ),
                    );
                  },
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Submit"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
