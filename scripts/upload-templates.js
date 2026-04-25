const { createClient } = require("@supabase/supabase-js");
const fs = require("fs");
const path = require("path");

const supabase = createClient(
  "http://127.0.0.1:54321",
  "sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz",
);

async function uploadTemplates() {
  const templatesDir = path.join(__dirname, "..", "templates");

  if (!fs.existsSync(templatesDir)) {
    console.error("Templates directory not found at:", templatesDir);
    return;
  }

  const files = fs.readdirSync(templatesDir);
  console.log(`Found ${files.length} files in templates directory.`);

  for (const filename of files) {
    const filePath = path.join(templatesDir, filename);
    const fileStats = fs.statSync(filePath);

    if (fileStats.isFile()) {
      const fileBuffer = fs.readFileSync(filePath);
      console.log(`Uploading ${filename}...`);

      const { data, error } = await supabase.storage
        .from('guides')
        .upload(filename, fileBuffer, {
          upsert: true,
          contentType: getContentType(filename)
        });

      if (error) {
        console.error(`Failed to upload ${filename}:`, error.message);
      } else {
        console.log(`Successfully uploaded ${filename}`);
      }
    }
  }
}

function getContentType(filename) {
  const ext = path.extname(filename).toLowerCase();
  switch (ext) {
    case '.pdf': return 'application/pdf';
    case '.doc': return 'application/msword';
    case '.docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case '.xls': return 'application/vnd.ms-excel';
    case '.xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case '.png': return 'image/png';
    case '.jpg':
    case '.jpeg': return 'image/jpeg';
    default: return 'application/octet-stream';
  }
}

uploadTemplates().then(() => {
  console.log("Upload process finished.");
}).catch(err => {
  console.error("Fatal error:", err);
});
