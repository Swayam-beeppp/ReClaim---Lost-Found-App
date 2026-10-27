const admin = require("firebase-admin");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");

admin.initializeApp();

exports.sendPushForNotification = onDocumentCreated(
  "Notifications/{notificationId}",
  async (event) => {
    const data = event.data ? event.data.data() : null;
    if (!data) return;

    const type = (data.type || "").toString();
    const title = (data.title || "ReClaim").toString();
    const body = (data.message || type || "New update").toString();
    const collegeCode = (data.collegeCode || "").toString();
    const targetUserId = (data.targetUserId || "").toString();

    let topic = "";
    if (targetUserId) {
      topic = `user_${targetUserId}`;
    } else if (collegeCode) {
      topic = `college_${collegeCode}`;
    } else {
      return;
    }

    const payload = {
      topic,
      notification: {
        title,
        body,
      },
      data: {
        type,
        postId: (data.post_id || "").toString(),
        requestId: (data.request_id || "").toString(),
        score: (data.score || "").toString(),
      },
      android: {
        priority: "high",
        notification: {
          channelId: "reclaim_alerts",
          priority: "max",
          defaultSound: true,
        },
      },
    };

    await admin.messaging().send(payload);
  }
);
