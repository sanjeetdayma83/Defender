import "dotenv/config";
import pg from "pg";

const { Client } = pg;

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error("DATABASE_URL is not configured.");
}

const client = new Client({ connectionString });

async function main() {
  await client.connect();

  try {
    console.log("\n===== DATABASE =====");

    const db = await client.query(`
      SELECT
        current_database() AS database,
        current_schema() AS schema,
        version() AS version
    `);

    console.table(db.rows);

    console.log("\n===== ALL PUBLIC TABLES =====");

    const tables = await client.query(`
      SELECT
        table_schema,
        table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE'
      ORDER BY table_name
    `);

    console.table(tables.rows);

    console.log("\n===== USER / COMPANY / WAREHOUSE TABLE STRUCTURE =====");

    const columns = await client.query(`
      SELECT
        table_name,
        ordinal_position,
        column_name,
        data_type,
        is_nullable,
        column_default
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name IN (
          'User',
          'Company',
          'Warehouse',
          'users',
          'companies',
          'warehouses'
        )
      ORDER BY table_name, ordinal_position
    `);

    console.table(columns.rows);

  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error("\n===== DATABASE INSPECTION FAILED =====");
  console.error(error);
  process.exit(1);
});
