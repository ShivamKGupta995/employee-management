Perfect 👍
Below is the **ENTIRE `function-detail.md` file** wrapped in **one single code block**, so you can **copy–paste directly** without editing anything.

---

```md
# 🔥 Firebase Cloud Functions – Location History Cleanup (45 Days Retention)

This document explains **from scratch** how our Firebase Cloud Functions are set up to:

1. Send push notifications for announcements  
2. Automatically delete employee GPS location history older than **45 days**  
3. Keep the system **fast, compliant, and scalable**

This project uses **Firebase Cloud Functions Gen-2**.

---

## 📌 Why This Exists

Employee GPS tracking generates a **large amount of data**.

Keeping unlimited history:
- ❌ Increases Firestore costs
- ❌ Slows down queries
- ❌ Violates data-retention best practices

### ✅ Solution
We retain **only the last 45 days** of location history and delete older data **once per day** automatically.

---

## 🧠 Architecture Overview

```

Employee App (Flutter)
└─ Writes GPS →
Firestore
└─ user/{uid}
├─ current_lat
├─ current_lng
├─ last_seen
└─ location_history/
└─ {autoId}
├─ lat
├─ lng
└─ timestamp

Cloud Function (Scheduler)
└─ Runs every 24 hours
└─ Deletes location_history older than 45 days

```

---

## ⚙️ Technologies Used

- Firebase Cloud Functions **Gen-2**
- Firebase Admin SDK
- Firestore
- Firebase Scheduler
- Node.js

---

## 📁 File Structure

```

functions/
├── index.js
├── package.json
├── node_modules/

````

---

## 🚀 Step-by-Step Setup (From Scratch)

### 1️⃣ Navigate to the functions directory

```bash
cd functions
````

---

### 2️⃣ Install required dependencies

```bash
npm install firebase-functions@latest firebase-admin@latest
```

---

### 3️⃣ `index.js` – Complete Implementation

```js
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const admin = require("firebase-admin");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

/**
 * 🔔 ANNOUNCEMENT NOTIFICATION
 * Triggered when a new announcement is created
 */
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

/**
 * 🧹 LOCATION HISTORY CLEANUP
 * Runs once every 24 hours
 * Deletes GPS data older than 45 days
 */
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

    console.log("✅ 45-day location history cleanup completed");
  }
);
```

---

## 🕒 How the Cleanup Works

* Calculates **today − 45 days**
* Deletes only documents **older than cutoff**
* Leaves:

  * Live location
  * Recent history
  * Contacts
  * Uploads
  * Attendance

---

## 🔐 Safety & Best Practices

* ✔ Batch deletes (safe + efficient)
* ✔ Firestore limit respected (500)
* ✔ Server timestamps
* ✔ Runs once daily
* ✔ No client dependency

---

## 🚀 Deploy the Functions

```bash
firebase deploy --only functions
```

---

## 🔍 Verify Deployment

```bash
firebase functions:list
```

Expected:

* `sendAnnouncementNotification`
* `cleanupOldLocationHistory`

---

## 📊 Cost & Performance

* Very low Firestore cost
* Prevents database bloat
* Keeps admin map fast
* Scales automatically

---

## ✅ Final Status

| Feature              | Status    |
| -------------------- | --------- |
| Push Notifications   | ✅ Enabled |
| 45-Day GPS Retention | ✅ Enabled |
| Auto Cleanup         | ✅ Enabled |
| Production Ready     | ✅ Yes     |
| Gen-2 Compatible     | ✅ Yes     |

---

## 🔮 Future Enhancements

* Per-user retention policy
* Manual cleanup trigger
* Admin reports
* Backup before deletion

---

**Maintained by:**
Employee System Engineering Team

```

---

If you want, next I can:
- Add **diagram images**
- Add **company compliance wording**
- Add **admin SOP**
- Add **monitoring & alerts**

Just say the word 👍
```
ss