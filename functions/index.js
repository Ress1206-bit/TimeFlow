/* eslint-disable */

const functions = require('firebase-functions');
const fetch = require('node-fetch');

exports.chatBot = functions.https.onRequest(async (req, res) => {
  try {
    // 1) Expect { messages: [ { role, content }, … ] } in the request body
    const { messages } = req.body;
    if (!Array.isArray(messages)) {
      return res
        .status(400)
        .json({ error: 'Expected { messages: [ { role, content }, … ] }' });
    }

    // 2) Build the OpenAI request payload using the key from config
    const openaiKey = functions.config().openai.key;
    const payload = {
      model: 'gpt-4o-mini',
      messages: messages.map((m) => ({
        role: m.role,
        content: m.content,
      })),
    };

    // 3) Call OpenAI’s Chat Completion endpoint
    const response = await fetch(
      'https://api.openai.com/v1/chat/completions',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${openaiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      }
    );

    if (!response.ok) {
      const text = await response.text();
      return res.status(response.status).json({ error: text });
    }

    const data = await response.json();

    // 4) Safely extract data.choices[0].message.content
    let assistantMessage = '';
    if (
      Array.isArray(data.choices) &&
      data.choices.length > 0 &&
      data.choices[0].message &&
      typeof data.choices[0].message.content === 'string'
    ) {
      assistantMessage = data.choices[0].message.content;
    }

    // 5) Return just the assistant’s reply text
    return res.json({ text: assistantMessage });
  } catch (err) {
    console.error('chatBot error:', err);
    return res.status(500).json({ error: err.message });
  }
});