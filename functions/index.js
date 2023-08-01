const functions = require("firebase-functions");
const express = require("express");
const admin = require("firebase-admin");

admin.initializeApp(); // Initialize Firebase Admin SDK

const app = express();

// Define the QR scan acknowledgment endpoint
app.post("/acknowledge-scan", async (req, res) => {
  try {
    const {name, email, caregiverId} = req.body;

    // Validate the data
    if (!name || !email || !caregiverId) {
      return res.status(400).send("Missing required fields");
    }

    const database = admin.firestore();
    const acknowledgmentRef = database.collection("acknowledgments").doc();
    await acknowledgmentRef.set({
      name,
      email,
      caregiverId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send the appropriate response
    res.status(200).send("QR scan acknowledged");
  } catch (error) {
    console.error("Error acknowledging QR scan:", error);
    res.status(500).send("An error occurred while acknowledging the QR scan");
  }
});

// Export the Express app as a Firebase Cloud Function
exports.api = functions.https.onRequest(app);
