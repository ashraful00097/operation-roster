const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();

// =====================================================
// NEW INTERCHANGE REQUEST
// =====================================================

exports.sendInterchangeNotification = onDocumentCreated(
    "interchange_requests/{requestId}",
    async (event) => {
      console.log("====================================");
      console.log("NEW INTERCHANGE REQUEST");
      console.log("====================================");

      const snapshot = event.data;

      if (!snapshot) {
        console.log("No request data found.");
        return;
      }

      const request = snapshot.data();

      console.log("Request:", request);

      // -------------------------------------------------
      // RECEIVER USER ID
      // -------------------------------------------------

      const toUserId = request.toUserId;

      if (!toUserId) {
        console.log("toUserId is missing.");
        return;
      }

      // -------------------------------------------------
      // GET RECEIVER PROFILE
      // -------------------------------------------------

      const userSnapshot = await db
          .collection("users")
          .doc(toUserId)
          .get();

      if (!userSnapshot.exists) {
        console.log(
            "Receiver profile not found:",
            toUserId,
        );

        return;
      }

      const userData = userSnapshot.data();

      // -------------------------------------------------
      // GET FCM TOKEN
      // -------------------------------------------------

      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log(
            "Receiver does not have an FCM token.",
        );

        return;
      }

      console.log(
          "FCM token found for:",
          userData.name || toUserId,
      );

      // -------------------------------------------------
      // REQUEST INFORMATION
      // -------------------------------------------------

      const fromName =
        request.fromName || "Someone";

      const fromGroup =
        request.fromGroup || "";

      const toGroup =
        request.toGroup || "";

      const duty =
        request.duty || "";

      const date =
        request.dateText ||
        request.date ||
        "";

      // -------------------------------------------------
      // FCM MESSAGE
      // -------------------------------------------------

      const message = {
        token: fcmToken,

        notification: {
          title: "New Interchange Request",
          body:
            `${fromName} (${fromGroup}) sent you an interchange request.`,
        },

        data: {
          type: "interchange_request",
          requestId: event.params.requestId,
          fromName: String(fromName),
          fromGroup: String(fromGroup),
          toGroup: String(toGroup),
          duty: String(duty),
          date: String(date),
        },

        android: {
          priority: "high",

          notification: {
            channelId: "interchange_requests",
            sound: "default",
          },
        },
      };

      // -------------------------------------------------
      // SEND PUSH NOTIFICATION
      // -------------------------------------------------

      try {
        const response =
          await getMessaging().send(message);

        console.log(
            "====================================",
        );

        console.log(
            "NOTIFICATION SENT SUCCESSFULLY",
        );

        console.log(
            "Message ID:",
            response,
        );

        console.log(
            "====================================",
        );
      } catch (error) {
        console.error(
            "====================================",
        );

        console.error(
            "FCM SEND ERROR:",
            error,
        );

        console.error(
            "====================================",
        );
      }
    },
);
