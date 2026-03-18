const express = require("express");
const { pool, query } = require("./db");

const app = express();
const port = Number(process.env.PORT || 80);

app.use(express.json());

async function initSchema() {
  await query(`
    CREATE TABLE IF NOT EXISTS visits (
      id INTEGER PRIMARY KEY,
      total BIGINT NOT NULL DEFAULT 0,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);

  await query(`
    INSERT INTO visits (id, total)
    VALUES (1, 0)
    ON CONFLICT (id) DO NOTHING
  `);
}

app.get("/api/health", async (_req, res) => {
  try {
    await query("SELECT 1");
    res.status(200).json({ status: "ok", database: "connected" });
  } catch (error) {
    res.status(500).json({ status: "error", database: "disconnected", message: error.message });
  }
});

app.get("/api/visits", async (_req, res) => {
  try {
    const result = await query(`
      UPDATE visits
      SET total = total + 1,
          updated_at = NOW()
      WHERE id = 1
      RETURNING total, updated_at
    `);

    res.json({
      message: "Backend connected to RDS successfully",
      visits: Number(result.rows[0].total),
      updated_at: result.rows[0].updated_at,
    });
  } catch (error) {
    res.status(500).json({ message: "Failed to read/write from RDS", error: error.message });
  }
});

app.get("/api/config", (_req, res) => {
  res.json({
    db_host: process.env.DB_HOST || null,
    db_port: process.env.DB_PORT || null,
    db_name: process.env.DB_NAME || null,
    db_user: process.env.DB_USER || null,
  });
});

async function start() {
  try {
    await initSchema();
    app.listen(port, () => {
      console.log(`Backend listening on port ${port}`);
    });
  } catch (error) {
    console.error("Failed to start backend", error);
    await pool.end();
    process.exit(1);
  }
}

start();
