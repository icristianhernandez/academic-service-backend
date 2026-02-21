#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

const TBLS_DIR = path.join(__dirname, "..", "docs", "db", "tbls");

const CATPPUCCIN_FRAPPE_INIT = `%%{init: {
  "theme": "base",
  "themeVariables": {
    "primaryColor": "#3b3f51",
    "primaryTextColor": "#c6d0f5",
    "primaryBorderColor": "#414559",
    "lineColor": "#8caaee",
    "secondaryColor": "#414559",
    "tertiaryColor": "#303446",
    "background": "#303446",
    "mainBkg": "#3b3f51",
    "nodeBorder": "#414559",
    "clusterBkg": "#3b3f51",
    "clusterBorder": "#414559",
    "titleColor": "#eebebe",
    "edgeLabelBackground": "#3b3f51"
  },
  "themeCSS": ".er.entityBox { fill: #3b3f51; stroke: #414559; } .er.entityBoxTitle { fill: #eebebe; } .er.attributeBoxEven { fill: #3b3f51; } .er.attributeBoxOdd { fill: #303446; } .er.attributeText { fill: #c6d0f5; } .er.attributeTextNPT { fill: #a5adce; } .er.relationshipLine { stroke: #8caaee; } .er.relationshipLabel { fill: #c6d0f5; } .er.relationshipLabelBox { fill: #3b3f51; }"
}}%%
`;

function processMermaidFile(filePath) {
  let content = fs.readFileSync(filePath, "utf8");

  if (content.startsWith("%%{init:")) {
    return;
  }

  content = CATPPUCCIN_FRAPPE_INIT + content;
  fs.writeFileSync(filePath, content, "utf8");
  console.log(`Styled: ${path.basename(filePath)}`);
}

function generateTableMermaid(schemaJson, tableName, tables) {
  const table = schemaJson.tables.find(t => t.name === tableName);
  if (!table) return null;

  const parentRelations = schemaJson.relations.filter(r => r.parent_table === tableName);
  const childRelations = schemaJson.relations.filter(r => r.table === tableName);

  const relatedTables = new Set();
  parentRelations.forEach(r => relatedTables.add(r.table));
  childRelations.forEach(r => relatedTables.add(r.parent_table));
  relatedTables.delete(tableName);

  const allTables = [tableName, ...relatedTables];

  let mermaid = "erDiagram\n\n";

  parentRelations.forEach(r => {
    mermaid += `"${r.table}" }o--|| "${r.parent_table}" : "${r.def || ''}"\n`;
  });

  childRelations.forEach(r => {
    mermaid += `"${r.table}" }o--|| "${r.parent_table}" : "${r.def || ''}"\n`;
  });

  mermaid += "\n";

  allTables.forEach(t => {
    const tbl = schemaJson.tables.find(x => x.name === t);
    if (!tbl) return;

    mermaid += `"${tbl.name}" {\n`;
    (tbl.columns || []).forEach(col => {
      const type = col.type || "unknown";
      const name = col.name || "unknown";
      let key = "";
      if (col.isPrimaryKey) key += "PK";
      if (col.isForeignKey) key += (key ? ", " : "") + "FK";
      mermaid += `  ${type} ${name} ${key}\n`;
    });
    mermaid += "}\n\n";
  });

  return mermaid;
}

function generateIndividualMermaidFiles() {
  const schemaPath = path.join(TBLS_DIR, "schema.json");
  if (!fs.existsSync(schemaPath)) {
    console.log("schema.json not found, skipping individual mermaid generation");
    return;
  }

  const schemaJson = JSON.parse(fs.readFileSync(schemaPath, "utf8"));
  const tables = schemaJson.tables || [];

  console.log(`Generating individual mermaid files for ${tables.length} tables...`);

  tables.forEach(table => {
    const mermaid = generateTableMermaid(schemaJson, table.name, tables);
    if (mermaid) {
      const fileName = `${table.name}.mmd`;
      const filePath = path.join(TBLS_DIR, fileName);
      fs.writeFileSync(filePath, mermaid, "utf8");
      processMermaidFile(filePath);
    }
  });

  console.log(`Generated ${tables.length} individual mermaid files`);
}

function main() {
  if (!fs.existsSync(TBLS_DIR)) {
    console.error(`Directory not found: ${TBLS_DIR}`);
    process.exit(1);
  }

  generateIndividualMermaidFiles();

  const files = fs.readdirSync(TBLS_DIR);
  const mmdFiles = files.filter((f) => f.endsWith(".mmd"));

  if (mmdFiles.length === 0) {
    console.log("No .mmd files found to style.");
    return;
  }

  console.log(`Applying Catppuccin Frappé styling to ${mmdFiles.length} mermaid files...`);

  for (const file of mmdFiles) {
    const filePath = path.join(TBLS_DIR, file);
    processMermaidFile(filePath);
  }

  console.log("Done!");
}

main();
