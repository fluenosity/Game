const fs = require("fs");
const path = require("path");

const ROOT_DIR = process.cwd();

const IGNORE_DIRS = new Set([
  "node_modules",
  ".next",
  "dist",
  ".git",
]);

let totalLines = 0;
let totalFiles = 0;

function isBinaryFile(buffer) {
  // crude but effective: check for null bytes
  return buffer.includes(0);
}

function countLinesInFile(filePath) {
  try {
    const buffer = fs.readFileSync(filePath);
    if (isBinaryFile(buffer)) return;

    const content = buffer.toString("utf8");
    const lines = content.split("\n").length;

    totalLines += lines;
    totalFiles++;
  } catch (err) {
    // ignore unreadable files
  }
}

function walk(dir) {
  let entries;

  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);

    // Skip ignored folders anywhere in tree
    if (entry.isDirectory() && IGNORE_DIRS.has(entry.name)) {
      continue;
    }

    if (entry.isDirectory()) {
      walk(fullPath);
    } else if (entry.isFile()) {
      countLinesInFile(fullPath);
    }
  }
}

// Run
console.time("Scan Time");
walk(ROOT_DIR);
console.timeEnd("Scan Time");

console.log("Files scanned:", totalFiles);
console.log("Total lines:", totalLines);