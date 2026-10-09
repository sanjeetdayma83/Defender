import "dotenv/config";
import { Client } from "pg";

const client = new Client({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

async function main() {
  if (!process.env.DATABASE_URL) {
    throw new Error("DATABASE_URL is not loaded.");
  }

  await client.connect();

  const result = await client.query(`
    SELECT
      id,
      migration_name,
      started_at,
      finished_at,
      rolled_back_at,
      applied_steps_count,
      logs
    FROM "_prisma_migrations"
    ORDER BY started_at ASC, migration_name ASC
  `);

  console.log(JSON.stringify(result.rows, null, 2));
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await client.end().catch(() => {});
  });
