// server.js
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const PORT = 8000;

// Middleware
app.use(bodyParser.json());
app.use(cors()); // Enable CORS for all routes

// 1st endpoint: POST and print the data
app.post('/getuserinfo', (req, res) => {
    console.log('Received data:', req.body);
    res.json({
        "statusCode": 200,
        "msg": "Are you a beneficiary or a donor?",
        "buttons": [
            {
                "label": "🔎 Beneficiary",
                "action": "start_chat_as_beneficiary",
                "payload": {
                    "template": "beneficiary"
                }
            },
            {
                "label": "💰 Donor",
                "action": "start_chat_as_donor",
                "payload": {
                    "template": "donor"
                }
            }
        ],
        "data": {
            "id": 4,
            "first_name": "test4",
            "last_name": "test",
            "email": "test4@test.com",
            "phone": "456456456",
            "balance": 12000,
            "wallet_address": "suydilkjhfdfhdhyj85sdfs47453df3sdf45sdf",
            "created_at": null
        }
    });
});

// 2nd endpoint: POST and give static data
app.post('/chat', (req, res) => {
    res.json({ "statusCode": 200, "msg": "Here's your donation summary:\n\n| Field                | Details            |\n|----------------------|--------------------|\n| Recipient            | @simon             |\n| Amount               | 20.00 ETHIQ        |\n| Purpose              | other              |\n| Crisis               | other              |\n| Anonymous            | Yes                |\n\nPlease reply with confirmed: true (or say 'confirm') if everything looks good to proceed.", "buttons": [], "data": null });
});

app.listen(PORT, () => {
    console.log(`Server is running at http://localhost:${PORT}`);
});
