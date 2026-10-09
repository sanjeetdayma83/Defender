import { readFile, readdir } from "node:fs/promises";
import path from "node:path";
import { prisma } from "../src/config/prisma.js";

type TableRow = { table_name: string };
type ColumnRow = {
  table_name: string;
  column_name: string;
  data_type: string;
  is_nullable: string;
};

async function walk(dir: string): Promise<string[]> {
  const entries = await readdir(dir, { withFileTypes: true });
  const files: string[] = [];

  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (["node_modules", "dist", ".git"].includes(entry.name)) continue;
      files.push(...await walk(full));
    } else if (/\.(ts|sql)$/.test(entry.name)) {
      files.push(full);
    }
  }
  return files;
}

async function main() {
  const schema = await readFile("prisma/schema.prisma", "utf8");

  const modelTables = new Set<string>();
  for (const match of schema.matchAll(/model\s+\w+\s*\{([\s\S]*?)\n\}/g)) {
    const body = match[1];
    const mapped = body.match(/@@map\("([^"]+)"\)/);
    const modelName = match[0].match(/^model\s+(\w+)/)?.[1];
    if (mapped) modelTables.add(mapped[1]);
    else if (modelName) modelTables.add(modelName);
  }

  const files = [
    ...(await walk("src")),
    ...(await walk("prisma")),
  ];

  const sourceTables = new Set<string>();
  for (const file of files) {
    const content = await readFile(file, "utf8");
    for (const match of content.matchAll(/\bpublic\.(?:"([^"]+)"|([A-Za-z_][A-Za-z0-9_]*))/g)) {
      sourceTables.add(match[1] ?? match[2]);
    }
  }

  const dbTables = await prisma.$queryRawUnsafe<TableRow[]>(`
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE'
    ORDER BY table_name
  `);

  const dbColumns = await prisma.$queryRawUnsafe<ColumnRow[]>(`
    SELECT table_name, column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_schema = 'public'
    ORDER BY table_name, ordinal_position
  `);

  const actual = new Set(dbTables.map(x => x.table_name));
  const missingFromDb = [...new Set([...modelTables, ...sourceTables])]
    .filter(name => !actual.has(name))
    .sort();

  const dbOnly = [...actual]
    .filter(name => !modelTables.has(name))
    .sort();

  console.log("\n========== READ-ONLY DATABASE AUDIT ==========");
  console.log("\nDATABASE TABLES:");
  console.log([...actual].sort().join("\n") || "(none)");

  console.log("\nPRISMA MODEL TABLES ABSENT FROM DATABASE:");
  console.log([...modelTables].filter(x => !actual.has(x)).sort().join("\n") || "(none)");

  console.log("\nEXPLICIT public.* REFERENCES ABSENT FROM DATABASE:");
  console.log([...sourceTables].filter(x => !actual.has(x)).sort().join("\n") || "(none)");

  console.log("\nCOMBINED MISSING TABLE CANDIDATES:");
  console.log(missingFromDb.join("\n") || "(none)");

  console.log("\nDATABASE TABLES NOT REPRESENTED BY A PRISMA MODEL:");
  console.log(dbOnly.join("\n") || "(none)");

  console.log("\nDATABASE COLUMN INVENTORY:");
  for (const table of [...actual].sort()) {
    const cols = dbColumns
      .filter(c => c.table_name === table)
      .map(c => `${c.column_name}:${c.data_type}${c.is_nullable === "NO" ? " NOT NULL" : ""}`);
    console.log(`\n${table}\n  ${cols.join("\n  ")}`);
  }

  console.log("\n========== AUDIT COMPLETE; NO DATABASE WRITES ==========");
}

main()
  .catch(error => {
    console.error("AUDIT FAILED:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
