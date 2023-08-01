const express = require('express');
const app = express();
const bodyParser = require('body-parser');
const cors = require('cors');

app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(cors());

let caregiverConfirmation = false; // Flag to track caregiver confirmation

// Endpoint to handle caregiver confirmation request
app.post('/confirm-caregiver', (req, res) => {
  // Extract the caregiver data from the request
  const { name, caregiverId } = req.body;

  // Display confirmation dialog to the patient (implement your own logic here)

  // Set the caregiver confirmation flag to true
  caregiverConfirmation = true;

  // Send a response back to the caregiver
  res.sendStatus(200);
});

// Endpoint to check caregiver confirmation status
app.get('/check-confirmation', (req, res) => {
  // Send the caregiver confirmation status in the response
  res.json({ confirmed: caregiverConfirmation });
});

app.listen(3000, () => {
  console.log('Patient server is running on port 3000');
});
