/* eslint-disable */
const functions = require('firebase-functions');
const fetch     = require('node-fetch');

// NO runWith, no secrets block – plain Gen-1 function
exports.chatBot = functions.https.onRequest(async (req, res) => {
  const data = req.body;
  const messages = data.messages;

  if (!Array.isArray(messages)) {
    return res.status(400).json({
      error: `Expected { messages:[…] } but got ${JSON.stringify(data)}`
    });
  }

  // Read key from functions:config
  const openaiKey = functions.config().openai.key;

  const payload = {
    model: 'gpt-3.5-turbo',
    messages: messages.map(m => ({ role: m.role, content: m.content }))
  };

  const r = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${openaiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(payload)
  });
  if (!r.ok) {
    const t = await r.text();
    return res.status(500).json({ error: t });
  }
  const jr = await r.json();
  const reply = jr.choices?.[0]?.message?.content || '';
  return res.json({ text: reply });
});