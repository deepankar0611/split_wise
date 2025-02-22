const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendReminderNotification = functions.firestore
    .document("splits/{splitId}/reminders/{reminderId}")
    .onCreate(async (snap, context) => {
      const reminder = snap.data();
      const senderUid = reminder.sentBy;
      const participants = reminder.participants;
      const splitId = reminder.splitId;

      const senderDoc = await admin.firestore()
          .collection("users")
          .doc(senderUid)
          .get();
      const senderName = senderDoc.data().name || "Unknown";

      const splitDoc = await admin.firestore()
          .collection("splits")
          .doc(splitId)
          .get();
      const description = splitDoc.data().description || "No description";

      const message = {
        notification: {
          title: `${senderName} sent a reminder`,
          body: `Split details of "${description}"`,
        },
        data: {
          splitId: splitId,
        },
      };

      const tokens = [];
      for (const uid of participants) {
        if (uid !== senderUid) {
          const userDoc = await admin.firestore()
              .collection("users")
              .doc(uid)
              .get();
          const token = userDoc.data().fcmToken;
          if (token) {
            tokens.push(token);
          }
        }
      }

      if (tokens.length > 0) {
        return admin.messaging().sendMulticast({
          tokens: tokens,
          notification: message.notification,
          data: message.data,
        });
      }
      return null;
    });
