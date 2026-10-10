// A fresh-context save fixture only changes the HTML bootstrap.
// Released engine JS, WASM and PCK are never intercepted or changed.
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs = require('fs'), path = require('path'), http = require('http');
const base = process.argv[2] || 'http://127.0.0.1:8153/';
const mobile = process.argv[3] === 'mobile';
const local = new URL(base).hostname === '127.0.0.1';
const out = path.resolve(__dirname, '../evidence/web/true_ending_' + (local ? 'local_' : 'public_') + (mobile ? 'mobile' : 'desktop'));
const web = path.resolve(process.env.WEB_QA_BUILD_DIR || path.join(__dirname, '../tmp/web'));
let server, browser;
function fixture() {
  let save = '[run]\nversion=1\nscene="res://scenes/TrueBattle.tscn"\ncurrent_enemy_index=8\n';
  for (const [i, id] of ['player_01_akky', 'player_02_gou'].entries())
    save += `[player_${i}]\ncharacter_id="${id}"\ncurrent_health=${i ? 130 : 115}\nis_defeated=false\nis_available=true\nspecial_gauge=100.0\n`;
  for (let i = 0; i < 9; i++) save += `[enemy_${i}]\ncurrent_health=${i === 8 ? 1 : 0}\nis_defeated=${i !== 8}\n`;
  return save;
}
async function main() {
  fs.mkdirSync(out, { recursive: true });
  fs.writeFileSync(path.join(out, 'console.log'), '');
  if (local) {
    server = http.createServer((req, res) => {
      const file = path.resolve(web, '.' + (new URL(req.url, base).pathname === '/' ? '/index.html' : new URL(req.url, base).pathname));
      if (!file.startsWith(web + path.sep) || !fs.existsSync(file)) { res.writeHead(404); res.end(); return; }
      res.setHeader('Content-Type', { '.html': 'text/html', '.js': 'application/javascript', '.wasm': 'application/wasm' }[path.extname(file)] || 'application/octet-stream');
      fs.createReadStream(file).pipe(res);
    }).listen(Number(new URL(base).port), '127.0.0.1');
  }
  browser = await chromium.launch({ channel: 'msedge', headless: true, args: ['--enable-unsafe-swiftshader'] });
  const context = await browser.newContext({ viewport: mobile ? { width: 844, height: 390 } : { width: 1280, height: 720 }, hasTouch: mobile });
  const page = await context.newPage(), logs = [], errors = [], beats = [], pending = [], network = [];
  let build = '', running = false, saved = '';
  const screenshot = name => page.screenshot({ path: path.join(out, name + '.png') });
  page.on('console', msg => {
    const value = msg.text(); logs.push(value);
    fs.appendFileSync(path.join(out, 'console.log'), value + '\n');
    if (value.startsWith('[TRUE_ENDING] ')) {
      const beat = value.slice('[TRUE_ENDING] '.length).trim(); beats.push(beat);
      console.log('WEB_TRUE_ENDING_BEAT ' + beat);
      if (beat !== 'complete') pending.push((async () => {
        await page.waitForTimeout(beat === 'defeat' ? 3500 : beat === 'credits' ? 4000 : beat === 'switch' ? 2200 : 1100);
        await screenshot(beat.replace(/\W+/g, '_'));
      })().catch(e => errors.push(e.message)));
    }
  });
  page.on('pageerror', e => errors.push(e.message));
  page.on('response', r => { network.push({ url: r.url(), status: r.status() }); if (r.status() >= 400) errors.push(r.status() + ' ' + r.url()); });
  await page.route(/index\.html/, async route => {
    const response = await route.fetch(); let html = await response.text();
    build = (html.match(/"executable":"([^"]+)"/) || [])[1] || '';
    const marker = 'const engine = new Engine(GODOT_CONFIG);';
    if (!html.includes(marker)) throw Error('Missing engine bootstrap');
    html = html.replace(marker, `${marker}\nwindow.trueEndingQaEngine=engine;const qaStart=engine.startGame.bind(engine);engine.startGame=async (...args)=>{await engine.init(GODOT_CONFIG.executable);engine.copyToFS('/userfs/godot/app_userdata/HashireIkazuchi/save.cfg',new TextEncoder().encode(${JSON.stringify(fixture())}).buffer);return qaStart(...args);};`);
    await route.fulfill({ response, body: html });
  });
  await page.goto(base + 'index.html?true_ending_qa=' + Date.now());
  await page.mouse.click(10, 10); // Browser audio gesture.
  await page.waitForFunction(() => !document.getElementById('status'), {}, { timeout: 120000 });
  await page.waitForTimeout(1800);
  await screenshot('title_before');
  const tap = async (x, y) => mobile ? page.touchscreen.tap(x, y) : page.mouse.click(x, y, { delay: 70 });
  await tap(mobile ? 422 : 640, mobile ? 212 : 390);
  await page.waitForTimeout(2200);
  await screenshot('selection');
  if (logs.some(v => v.includes('VS enemy_09_seiya'))) throw Error('True boss auto-started without fighter selection');
  // Choose a fighter on the actual selection screen, including touch-sized viewports.
  await tap(mobile ? 422 : 640, mobile ? 286 : 528);
  if (!logs.some(v => v.includes('VS enemy_09_seiya'))) await page.keyboard.press('Enter');
  for (let i = 0; i < 40 && !logs.some(v => v.includes('VS enemy_09_seiya')); i++) await page.waitForTimeout(300);
  if (!logs.some(v => v.includes('VS enemy_09_seiya'))) throw Error('Checkpoint did not enter true boss combat');
  await screenshot('combat');
  await page.keyboard.down('ArrowRight'); await page.waitForTimeout(1150); await page.keyboard.up('ArrowRight');
  for (let i = 0; i < 30 && !beats.includes('defeat'); i++) {
    await page.keyboard.press('j', { delay: 60 });
    await page.keyboard.press('k', { delay: 60 });
    await page.waitForTimeout(450);
  }
  if (!beats.includes('defeat')) throw Error('Real attacks did not reach true ending');
  running = true;
  // Inputs must neither pause nor skip the autonomous movie.
  await page.keyboard.press('Escape'); await tap(20, 20);
  const deadline = Date.now() + 240000;
  while (Date.now() < deadline && !beats.includes('complete') && !logs.some(v => /^SCRIPT ERROR:|^ERROR:/.test(v))) await page.waitForTimeout(500);
  await Promise.all(pending);
  await page.waitForTimeout(1600);
  await screenshot('title_after');
  const expected = ['defeat', 'departure', 'switch', 'escape', 'pier', 'boat', 'detonation', 'dawn', 'BLACK SPARROW', 'TRUE ENDING', 'credits', 'complete'];
  if (JSON.stringify(beats) !== JSON.stringify(expected)) throw Error('Incomplete film: ' + JSON.stringify(beats));
  if (!logs.some(v => v.includes('HP: 0')) || !logs.some(v => v.includes('TRUE BOSS SEIYA DEFEATED'))) throw Error('Missing real boss KO evidence');
  if (process.env.EXPECTED_BUILD && build !== process.env.EXPECTED_BUILD) throw Error('Unexpected deployed build ' + build);
  // Inspect only the private browser's own IndexedDB save, not a user profile.
  saved = await page.evaluate(async () => {
    const names = await indexedDB.databases();
    for (const info of names) {
      const db = await new Promise((resolve, reject) => { const q = indexedDB.open(info.name); q.onsuccess = () => resolve(q.result); q.onerror = () => reject(q.error); });
      if (!db.objectStoreNames.contains('FILE_DATA')) { db.close(); continue; }
      const rows = await new Promise((resolve, reject) => { const tx = db.transaction('FILE_DATA'), req = tx.objectStore('FILE_DATA').getAll(); req.onsuccess = () => resolve(req.result); req.onerror = () => reject(req.error); });
      db.close();
      for (const row of rows) {
        if (!row.contents) continue;
        const text = new TextDecoder().decode(row.contents);
        if (text.includes('true_ending_unlocked')) return text;
      }
    }
    return '';
  });
  if (!saved.includes('true_ending_unlocked=true')) throw Error('True ending not persisted to browser save');
  if (errors.length || logs.some(v => /^SCRIPT ERROR:|^ERROR:/.test(v))) throw Error(JSON.stringify(errors));
  fs.writeFileSync(path.join(out, 'result.json'), JSON.stringify({ build, mobile, success: true, beats, save: saved, network, scenario: 'Private one-HP checkpoint, real attacks and unchanged released PCK/JS/WASM; automated browser execution, not full manual campaign or physical phone.' }, null, 2));
  console.log('TRUE_ENDING_PUBLIC_WEB_OK ' + build + ' ' + (mobile ? 'mobile' : 'desktop'));
  await context.close();
}
main().catch(e => { console.error(e); process.exitCode = 1; }).finally(async () => { if (browser) await browser.close(); if (server) server.close(); });
