import { chromium } from "playwright";

const url = process.argv[2] || "http://127.0.0.1:65345/candy_sky_islands.html";
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
const logs = [];
page.on("console", (msg) => logs.push({ type: msg.type(), text: msg.text() }));
page.on("pageerror", (err) => logs.push({ type: "pageerror", text: err.message }));

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

async function pageAlive(label) {
  const state = await Promise.race([
    page.evaluate(() => {
      const canvas = document.querySelector("canvas");
      let webglOk = false;
      if (canvas) {
        webglOk = !!(
          canvas.getContext("webgl2") ||
          canvas.getContext("webgl") ||
          canvas.getContext("experimental-webgl")
        );
      }
      return {
        readyState: document.readyState,
        canvasCount: document.querySelectorAll("canvas").length,
        canvasWidth: canvas ? canvas.clientWidth : 0,
        canvasHeight: canvas ? canvas.clientHeight : 0,
        webglOk,
        bodyText: document.body ? document.body.innerText : "",
      };
    }),
    new Promise((_, reject) => setTimeout(() => reject(new Error(`${label}: page evaluate timeout`)), 3000)),
  ]);
  assert(state.readyState === "complete", `${label}: document not complete`);
  assert(state.canvasCount >= 1, `${label}: canvas missing`);
  assert(state.canvasWidth > 0 && state.canvasHeight > 0, `${label}: canvas has no size`);
  assert(state.webglOk, `${label}: WebGL context unavailable`);
  return state;
}

async function skipUsernameIfPresent() {
  await page.mouse.click(535, 468);
  await page.waitForTimeout(300);
}

async function forceFallOnce(index) {
  await page.mouse.click(640, 360);
  await page.keyboard.down("KeyW");
  await page.waitForTimeout(2600);
  await page.keyboard.up("KeyW");
  await page.waitForTimeout(2200);
  await pageAlive(`after fall ${index}`);
}

await page.goto(url, { waitUntil: "load", timeout: 60000 });
await page.waitForSelector("canvas", { timeout: 60000 });
await page.waitForTimeout(2500);
await skipUsernameIfPresent();
await pageAlive("after load");

for (let i = 1; i <= 4; i += 1) {
  await forceFallOnce(i);
}

const badLogs = logs.filter((entry) => {
  if (entry.type === "warning") {
    return false;
  }
  return /error|exception|abort|uncaught|runtimeerror|webgl context lost/i.test(entry.text) || entry.type === "pageerror";
});

await browser.close();

if (badLogs.length > 0) {
  console.error(JSON.stringify(badLogs, null, 2));
  process.exit(1);
}

console.log("smoke_candy_death_web: PASS");
