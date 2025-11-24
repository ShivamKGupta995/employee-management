const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.sendAnnouncementNotification = onDocumentCreated("announcements/{docId}", async (event) => {
    // In Gen 2, the data is inside 'event.data'
    const snapshot = event.data;
    
    if (!snapshot) {
        console.log("No data associated with the event");
        return;
    }

    const data = snapshot.data();

    const payload = {
        notification: {
            title: data.category === 'Urgent' ? '🚨 Urgent Update' : 'New Announcement',
            body: data.title,
        },
        data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            message: data.message
        },
        topic: 'all_employees'
    };

    try {
        await getMessaging().send(payload);
        console.log("Notification sent successfully");
    } catch (error) {
        console.error("Error sending notification:", error);
    }
});