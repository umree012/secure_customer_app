// Load environment variables FIRST
require('dotenv').config();

const express = require("express");
const mysql = require("mysql");
const cors = require("cors");
const { v4: uuidv4 } = require("uuid");

// Debug: Check if .env loaded correctly
console.log("=== ENVIRONMENT VARIABLES ===");
console.log("DB_HOST:", process.env.DB_HOST);
console.log("DB_USER:", process.env.DB_USER);
console.log("DB_NAME:", process.env.DB_NAME);
console.log("PORT:", process.env.PORT);
console.log("=============================");

const app = express();
app.use(cors());
app.use(express.json());

// MySQL Connection
const db = mysql.createConnection({
  host: process.env.DB_HOST || "localhost",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "mydb5",
});

db.connect((err) => {
  if (err) {
    console.error("Database connection failed:", err.message);
    console.error("Please check:");
    console.error("1. MySQL is running in XAMPP/WAMP");
    console.error("2. Database 'mydb5' exists");
    console.error("3. Username/password are correct");
    return;
  }
  console.log("✅ MySQL connected successfully");
});

function runQuery(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.query(sql, params, (err, result) => {
      if (err) reject(err);
      else resolve(result);
    });
  });
}

app.get("/", (req, res) => {
  res.json({ message: "Flutter Node.js MySQL API is running", endpoints: ["POST /generate-api-key", "GET /customers"] });
});

app.post("/generate-api-key", async (req, res) => {
  try {
    const apiKey = uuidv4();
    const appName = req.body.app_name || "Flutter Lab App";
    await runQuery("INSERT INTO api_keys (api_key, app_name) VALUES (?, ?)", [apiKey, appName]);
    res.status(201).json({ message: "API key generated successfully", apiKey: apiKey });
  } catch (err) {
    console.error("Error generating API key:", err);
    res.status(500).json({ message: "Failed to generate API key", error: err.message });
  }
});

async function verifyApiKey(req, res, next) {
  try {
    const apiKey = req.headers["x-api-key"];
    if (!apiKey) {
      return res.status(401).json({ message: "API key is missing" });
    }
    const result = await runQuery("SELECT * FROM api_keys WHERE api_key = ? AND is_active = 1", [apiKey]);
    if (result.length === 0) {
      return res.status(403).json({ message: "Invalid or inactive API key" });
    }
    next();
  } catch (err) {
    console.error("API key verification error:", err);
    res.status(500).json({ message: "API key verification failed", error: err.message });
  }
}

app.get("/customers", verifyApiKey, async (req, res) => {
  try {
    const customers = await runQuery("SELECT * FROM customers4 ORDER BY id DESC");
    res.json({ message: "Customers fetched successfully", count: customers.length, data: customers });
  } catch (err) {
    console.error("Database error:", err);
    res.status(500).json({ message: "Database error", error: err.message });
  }
});

app.post("/customers", verifyApiKey, async (req, res) => {
  try {
    const { name, address } = req.body;
    if (!name || !address) {
      return res.status(400).json({ message: "name and address are required" });
    }
    const result = await runQuery("INSERT INTO customers4 (name, address) VALUES (?, ?)", [name, address]);
    res.status(201).json({ message: "Customer added successfully", insertedId: result.insertId });
  } catch (err) {
    console.error("Insert error:", err);
    res.status(500).json({ message: "Insert failed", error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});