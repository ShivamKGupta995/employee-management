const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const admin = require("firebase-admin");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

// 🔔 Notification Function
exports.sendAnnouncementNotification = onDocumentCreated(
  "announcements/{docId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();

    const payload = {
      notification: {
        title:
          data.category === "Urgent"
            ? "🚨 Urgent Update"
            : "New Announcement",
        body: data.title,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        message: data.message ?? "",
      },
      topic: "all_employees",
    };

    await getMessaging().send(payload);
    console.log("✅ Notification sent");
  }
);

// 🧹 45-DAY LOCATION HISTORY CLEANUP
exports.cleanupOldLocationHistory = onSchedule(
  {
    schedule: "every 24 hours",
    timeZone: "Asia/Kolkata",
  },
  async () => {
    const db = admin.firestore();

    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 45 * 24 * 60 * 60 * 1000)
    );

    const users = await db.collection("user").get();

    for (const user of users.docs) {
      const oldDocs = await db
        .collection("user")
        .doc(user.id)
        .collection("location_history")
        .where("timestamp", "<", cutoff)
        .limit(500)
        .get();

      if (oldDocs.empty) continue;

      const batch = db.batch();
      oldDocs.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }

    console.log("✅ 45-day location history cleanup done");
  }
);
