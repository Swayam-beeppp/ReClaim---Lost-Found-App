import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> createPostNotification({
    required String postId,
    required String collegeCode,
    required String userId,
    String? caption,
    String? location,
  }) async {
    await FirebaseFirestore.instance.collection("Notifications").add({
      "type": "post",
      "title": "New item found",
      "message": (caption ?? "").trim().isEmpty
          ? "A new found-item post was added."
          : "New found item: ${caption!.trim()}",
      "post_id": postId,
      "location": (location ?? "").trim(),
      "collegeCode": collegeCode,
      "sourceUserId": userId,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  static Future<void> createRequestNotification({
    required String requestId,
    required String collegeCode,
    required String userId,
    required String description,
  }) async {
    await FirebaseFirestore.instance.collection("Notifications").add({
      "type": "request",
      "title": "New lost item reported",
      "message": description,
      "request_id": requestId,
      "collegeCode": collegeCode,
      "sourceUserId": userId,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  static Future<void> createRequestMatchNotification({
    required String requestId,
    required String postId,
    required String collegeCode,
    required String targetUserId,
    required String message,
    required double score,
  }) async {
    await FirebaseFirestore.instance.collection("Notifications").add({
      "type": "request_match",
      "title": "Possible match found",
      "message": message,
      "request_id": requestId,
      "post_id": postId,
      "collegeCode": collegeCode,
      "targetUserId": targetUserId,
      "score": score,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }
}
