import { deflateSync } from "node:zlib";
import { writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";

const width = 1600;
const height = 900;
const table = new Uint32Array(256);
for (let n = 0; n < 256; n += 1) {
  let value = n;
  for (let bit = 0; bit < 8; bit += 1) value = value & 1 ? 0xedb88320 ^ (value >>> 1) : value >>> 1;
  table[n] = value >>> 0;
}
function crc32(buffer) {
  let value = 0xffffffff;
  for (const byte of buffer) value = table[(value ^ byte) & 0xff] ^ (value >>> 8);
  return (value ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const name = Buffer.from(type, "ascii");
  const output = Buffer.alloc(12 + data.length);
  output.writeUInt32BE(data.length, 0);
  name.copy(output, 4);
  data.copy(output, 8);
  output.writeUInt32BE(crc32(Buffer.concat([name, data])), 8 + data.length);
  return output;
}
const rows = Buffer.alloc((width * 4 + 1) * height);
for (let y = 0; y < height; y += 1) {
  const row = y * (width * 4 + 1);
  for (let x = 0; x < width; x += 1) {
    const offset = row + 1 + x * 4;
    const wave = Math.sin(x / 115 + y / 90) * 0.5 + 0.5;
    const glow = Math.max(0, 1 - Math.hypot(x - 1180, y - 300) / 760);
    rows[offset] = Math.round(10 + 32 * wave + 45 * glow);
    rows[offset + 1] = Math.round(18 + 82 * wave + 100 * glow);
    rows[offset + 2] = Math.round(38 + 120 * wave + 90 * glow);
    rows[offset + 3] = 255;
  }
}
const header = Buffer.alloc(13);
header.writeUInt32BE(width, 0);
header.writeUInt32BE(height, 4);
header[8] = 8;
header[9] = 6;
const png = Buffer.concat([
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
  chunk("IHDR", header),
  chunk("IDAT", deflateSync(rows, { level: 9 })),
  chunk("IEND", Buffer.alloc(0)),
]);
const destination = fileURLToPath(new URL("../themes/open-source-placeholder/hero.png", import.meta.url));
await writeFile(destination, png);
process.stdout.write(`generated ${destination} (${png.length} bytes)\n`);
