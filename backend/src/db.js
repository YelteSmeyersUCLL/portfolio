const { Pool } = require("pg");

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || "postgres://databasement:databasement@localhost:5432/databasement",
});

module.exports = { pool };
