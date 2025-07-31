const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { OpenAI } = require("openai");

admin.initializeApp();

const openai = new OpenAI({
  apiKey: functions.config().openai.key,
});

exports.chatWithAI = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  const authHeader = req.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  const idToken = authHeader.split("Bearer ")[1];

  try {
    await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    return res.status(401).json({ error: "Invalid or expired token" });
  }

  try {
    const prompt = req.body.prompt;
    const model = req.body.model || "gpt-4o";

    if (!prompt) {
      return res.status(400).json({ error: "Prompt is required" });
    }

    const chat = await openai.chat.completions.create({
      model,
      messages: [
        { role: "system", content: "You are TimeFlow, an AI day-planner." },
        { role: "user", content: prompt },
      ],
    });

    res.json({
      content: chat.choices[0].message.content,
      usage: chat.usage,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal server error" });
  }
});
