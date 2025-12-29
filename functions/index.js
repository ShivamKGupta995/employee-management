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

// ======================================================
// 3️⃣ 🎉 BIRTHDAY / WORK / MARRIAGE ANNIVERSARY NOTIFIER
// ======================================================

exports.sendCelebrationNotifications = onSchedule(
  {
    schedule: "every day 00:01",
    timeZone: "Asia/Kolkata",
  },
  async () => {
    const today = new Date();
    const todayDay = today.getDate();
    const todayMonth = today.getMonth() + 1;
    const currentYear = today.getFullYear();

    console.log("🎉 Celebration check started");

    const usersSnap = await admin.firestore().collection("user").get();

    for (const doc of usersSnap.docs) {
      const user = doc.data();
      if (!user || !user.name) continue;

      const messages = [];

      // 🎂 BIRTHDAY (ONLY IF dob EXISTS)
      if (typeof user.dob === "string" && user.dob.trim() !== "") {
        const dob = new Date(user.dob);

        if (
          dob.getDate() === todayDay &&
          dob.getMonth() + 1 === todayMonth
        ) {
          messages.push({
            title: "🎂 Happy Birthday!",
            body: `🎉 Wishing ${user.name} a very Happy Birthday!`,
          });
        }
      }

      // 🎉 WORK ANNIVERSARY (ONLY IF joiningDate EXISTS)
      if (typeof user.joiningDate === "string" && user.joiningDate.trim() !== "") {
        const joinDate = new Date(user.joiningDate);
        const years = currentYear - joinDate.getFullYear();

        if (
          joinDate.getDate() === todayDay &&
          joinDate.getMonth() + 1 === todayMonth &&
          years > 0
        ) {
          messages.push({
            title: "🎉 Work Anniversary!",
            body: `👏 Congratulations ${user.name} on completing ${years} year${years > 1 ? "s" : ""} with us!`,
          });
        }
      }

      // 💍 MARRIAGE ANNIVERSARY (ONLY IF marriageDate EXISTS)
      if (
        typeof user.marriageDate === "string" &&
        user.marriageDate.trim() !== ""
      ) {
        const marriageDate = new Date(user.marriageDate);
        const years = currentYear - marriageDate.getFullYear();

        if (
          marriageDate.getDate() === todayDay &&
          marriageDate.getMonth() + 1 === todayMonth
        ) {
          messages.push({
            title: "💍 Happy Anniversary!",
            body: `💖 Warm wishes to ${user.name} on your ${
              years > 0 ? years + " year " : ""
            }marriage anniversary!`,
          });
        }
      }

      // 🚀 SEND ONLY IF THERE IS SOMETHING TO SEND
      if (messages.length === 0) continue;

      for (const msg of messages) {
        await getMessaging().send({
          topic: "all_employees",
          notification: {
            title: msg.title,
            body: msg.body,
          },
          data: {
            type: "celebration",
            userId: doc.id,
          },
        });
      }
    }

    console.log("✅ Celebration notifications completed");
  }
);
