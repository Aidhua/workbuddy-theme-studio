import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { DEFAULT_THEME_ID } from "../src/constants.mjs";
import { productProfile } from "../src/products.mjs";
import { validateThemeManifest } from "../src/theme-schema.mjs";
import { parseImageMetadata } from "../src/image-metadata.mjs";
import { buildWorkBuddySkinCss } from "../src/skin-css-workbuddy.mjs";
import { runCli } from "../src/cli.mjs";

const root = fileURLToPath(new URL("..", import.meta.url));

test("WorkBuddy is isolated on 9342 and placeholder is the default", () => {
  assert.equal(DEFAULT_THEME_ID, "open-source-placeholder");
  assert.equal(productProfile("workbuddy").defaultCdpPort, 9342);
  assert.equal(productProfile("codex").defaultCdpPort, 9341);
});

test("placeholder theme validates and builds WorkBuddy CSS", async () => {
  const raw = JSON.parse(await readFile(`${root}/themes/open-source-placeholder/theme.json`, "utf8"));
  const theme = validateThemeManifest(raw);
  const metadata = parseImageMetadata(await readFile(`${root}/themes/open-source-placeholder/hero.png`));
  assert.equal(theme.id, DEFAULT_THEME_ID);
  assert.equal(metadata.mime, "image/png");
  const css = buildWorkBuddySkinCss({ theme, heroDataUrl: "data:image/png;base64,AA==" });
  assert.match(css, /HEIGE_WORKBUDDY_SKIN:open-source-placeholder/);
  assert.match(css, /--cb-bg-primary/);
});

test("background tasks are headless and recover every minute", async () => {
  const scheduled = await readFile(`${root}/scripts/windows/lib/scheduled-task.ps1`, "utf8");
  const session = await readFile(`${root}/scripts/windows/lib/workbuddy-session.ps1`, "utf8");
  assert.match(scheduled, /conhost\.exe/);
  assert.match(scheduled, /--headless/);
  assert.match(scheduled, /RepetitionInterval = "PT1M"/);
  assert.match(session, /--headless/);
});

test("public entrypoints never target Codex port 9341", async () => {
  const names = ["install.ps1", "apply-theme.ps1", "enable-persistence.ps1", "disable-persistence.ps1", "restore-official.ps1", "uninstall.ps1"];
  for (const name of names) {
    const text = await readFile(`${root}/scripts/windows/${name}`, "utf8");
    assert.doesNotMatch(text, /(?:--port|LocalPort|\bPort\s*=)\s*9341/i, name);
  }
});

test("CLI rejects Codex and every port except 9342", async () => {
  await assert.rejects(runCli(["status", "--app", "codex"]), /WorkBuddy/);
  await assert.rejects(runCli(["status", "--app", "workbuddy", "--port", "9341"]), /9342/);
  await assert.rejects(runCli(["install-pet"]), /专用发行版/);
});
