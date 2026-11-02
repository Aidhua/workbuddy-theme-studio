const EXACT_MAIN_URL = "app://-/index.html";

export function classifyCodexTarget(target) {
  let type;
  let value;
  try {
    type = target?.type;
    value = target?.url;
  } catch {
    return "unknown";
  }
  if (type !== "page" || typeof value !== "string") return "unknown";
  if (value === EXACT_MAIN_URL) return "main";
  if (value.includes("#")) return "unknown";

  let url;
  try { url = new URL(value); } catch { return "unknown"; }
  if (
    url.protocol !== "app:" ||
    url.hostname !== "-" ||
    url.pathname !== "/index.html" ||
    url.username ||
    url.password ||
    url.port ||
    url.hash ||
    !url.search
  ) {
    return "unknown";
  }
  const keys = [...url.searchParams.keys()];
  if (
    keys.length === 1 &&
    keys[0] === "initialRoute" &&
    url.searchParams.get("initialRoute") === "/avatar-overlay"
  ) {
    return "overlay";
  }
  return "unknown";
}

export function classifyCodexTargets(targets) {
  if (!Array.isArray(targets)) throw new TypeError("Codex targets 必须是数组");
  return targets.map((target) => ({
    ...target,
    kind: classifyCodexTarget(target),
  }));
}

// WorkBuddy 的 renderer 走 loadFile，落在 app.asar 里。macOS 与 Windows 的
// 安装根可以变化，但产品目录和 renderer 相对入口固定；只认这两个精确后缀。
const WORKBUDDY_MAIN_SUFFIXES = Object.freeze([
  "/workbuddy.app/contents/resources/app.asar/renderer/index.html",
  "/workbuddy/resources/app.asar/renderer/index.html",
]);

export function classifyWorkBuddyTarget(target) {
  let type;
  let value;
  try {
    type = target?.type;
    value = target?.url;
  } catch {
    return "unknown";
  }
  if (type !== "page" || typeof value !== "string") return "unknown";

  let url;
  try { url = new URL(value); } catch { return "unknown"; }
  if (
    url.protocol !== "file:" ||
    url.hostname ||
    url.username ||
    url.password ||
    url.port
  ) {
    return "unknown";
  }
  // query 和 fragment 一律放行，不参与身份判断。WorkBuddy 5.5.2 会用 query 传启动快照，
  // 并继续用 hash 路由。身份只看下面这个解码后的 pathname，两者都影响不到 url.pathname，
  // 也从不落到文件系统。像 file:///tmp/evil.html#/WorkBuddy.app/…/index.html 这种构造，
  // pathname 仍然是 /tmp/evil.html，照样被后缀检查挡掉。真机核对自 WorkBuddy 5.3.11
  // 解码后再比对，挡住 %2e%2e 之类绕过后缀检查的构造
  let pathname;
  try { pathname = decodeURIComponent(url.pathname); } catch { return "unknown"; }
  const normalizedPathname = pathname.toLowerCase();
  if (
    normalizedPathname.includes("..") ||
    !WORKBUDDY_MAIN_SUFFIXES.some((suffix) => normalizedPathname.endsWith(suffix))
  ) return "unknown";
  return "main";
}

export function classifyWorkBuddyTargets(targets) {
  if (!Array.isArray(targets)) throw new TypeError("WorkBuddy targets 必须是数组");
  return targets.map((target) => ({
    ...target,
    kind: classifyWorkBuddyTarget(target),
  }));
}

const CLASSIFIERS = new Map([
  ["codex", classifyCodexTargets],
  ["workbuddy", classifyWorkBuddyTargets],
]);

// 注入层只认这一个入口，产品换了不改调用点
export function classifyTargetsFor(productId, targets) {
  const classify = CLASSIFIERS.get(productId ?? "codex");
  if (!classify) throw new Error(`未知产品：${String(productId)}`);
  return classify(targets);
}
