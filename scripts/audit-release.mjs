import { readdir, readFile, stat } from "node:fs/promises";
import { extname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("..", import.meta.url));
const forbiddenDirectories = new Set([".git", ".workbuddy", "node_modules", "_private-reference"]);
const forbiddenNames = /^(state|session|transition)\.json$|^(controller-start-request|controller-handshake)\.json$|\.log$/i;
const forbiddenBinaries = new Set([".exe", ".dll", ".asar", ".icns", ".bin"]);
const privateFragments = [
  ["C:", "Users", "Administrator"].join("\\"),
  ["E:", "AI"].join("\\"),
  "WeiJing",
];
const secretPatterns = [
  /gh[pousr]_[A-Za-z0-9_]{20,}/g,
  /github_pat_[A-Za-z0-9_]{20,}/g,
  /sk-[A-Za-z0-9_-]{20,}/g,
  /AKIA[0-9A-Z]{16}/g,
  /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/g,
];
const textExtensions = new Set(["", ".md", ".json", ".mjs", ".js", ".ps1", ".bat", ".txt", ".yml", ".yaml"]);
const findings = [];
const files = [];

async function walk(directory) {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    if (forbiddenDirectories.has(entry.name)) {
      findings.push(`forbidden directory: ${relative(root, join(directory, entry.name))}`);
      continue;
    }
    const path = join(directory, entry.name);
    if (entry.isDirectory()) await walk(path);
    else if (entry.isFile()) files.push(path);
  }
}
await walk(root);

for (const path of files) {
  const rel = relative(root, path).replaceAll("\\", "/");
  const extension = extname(path).toLowerCase();
  if (forbiddenNames.test(rel.split("/").at(-1))) findings.push(`forbidden runtime file: ${rel}`);
  if (forbiddenBinaries.has(extension)) findings.push(`forbidden binary: ${rel}`);
  if (!textExtensions.has(extension) || rel === "scripts/audit-release.mjs") continue;
  const info = await stat(path);
  if (info.size > 5 * 1024 * 1024) findings.push(`oversized text file: ${rel}`);
  const text = await readFile(path, "utf8");
  for (const fragment of privateFragments) if (text.includes(fragment)) findings.push(`private path/name in ${rel}`);
  for (const pattern of secretPatterns) if (pattern.test(text)) findings.push(`secret-like value in ${rel}`);
}

const visualFiles = files
  .map((path) => relative(root, path).replaceAll("\\", "/"))
  .filter((path) => /\.(png|jpe?g|webp|gif|svg)$/i.test(path));
if (visualFiles.length !== 1 || visualFiles[0] !== "themes/open-source-placeholder/hero.png") {
  findings.push(`unexpected visual assets: ${visualFiles.join(", ")}`);
}

if (findings.length) {
  process.stderr.write(`${findings.join("\n")}\n`);
  process.exitCode = 1;
} else {
  process.stdout.write(`release audit passed: ${files.length} files; ${visualFiles.length} approved visual asset\n`);
}
