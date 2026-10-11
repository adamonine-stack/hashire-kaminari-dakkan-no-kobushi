// Private one-HP checkpoint; actual attacks, released runtime and real scene flow.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const fs=require('fs'),path=require('path'),http=require('http');
const base=process.argv[2]||'http://127.0.0.1:8160/';
const out=path.resolve('evidence/web',process.argv[3]||'leon_ending');
let server,browser;
async function run(){
fs.mkdirSync(out,{recursive:true});
if(new URL(base).hostname==='127.0.0.1'){
 const web=path.resolve('tmp/web');server=http.createServer((req,res)=>{const f=path.join(web,new URL(req.url,base).pathname.replace(/^\//,'')||'index.html');if(!fs.existsSync(f)){res.writeHead(404);return res.end();}res.setHeader('Content-Type',{'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm'}[path.extname(f)]||'application/octet-stream');fs.createReadStream(f).pipe(res);});await new Promise(r=>server.listen(Number(new URL(base).port),'127.0.0.1',r));
}
let fixture='[run]\nversion=2\nscene="res://scenes/Battle.tscn"\ncurrent_enemy_index=7\n';
for(const [i,id] of ['player_01_akky','player_02_gou','player_03_seiya'].entries())fixture+=`[player_${i}]\ncharacter_id="${id}"\ncurrent_health=${[100,120,90][i]}\nis_defeated=false\nis_available=true\nspecial_gauge=100.0\n`;
for(let i=0;i<8;i++)fixture+=`[enemy_${i}]\ncurrent_health=${i===7?1:0}\nis_defeated=${i!==7}\n`;
browser=await chromium.launch({channel:'msedge',headless:true,args:['--enable-unsafe-swiftshader']});
const context=await browser.newContext({viewport:{width:844,height:390},hasTouch:true});const page=await context.newPage();
let logs=[],errors=[],build='',injected=false;
page.on('console',m=>{logs.push(m.text());fs.appendFileSync(path.join(out,'console.log'),m.text()+'\n');});page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.status()>=400)errors.push(r.status()+' '+r.url());});
await page.route(/index\.html/,async route=>{const response=await route.fetch();let html=await response.text();build=(html.match(/"executable":"([^"]+)"/)||[])[1]||'';if(!injected){injected=true;const marker='const engine = new Engine(GODOT_CONFIG);';if(!html.includes(marker))throw Error('bootstrap missing');html=html.replace(marker,marker+`const qaStart=engine.startGame.bind(engine);engine.startGame=async(...args)=>{await engine.init(GODOT_CONFIG.executable);engine.copyToFS('/userfs/godot/app_userdata/HashireIkazuchi/save.cfg',new TextEncoder().encode(${JSON.stringify(fixture)}).buffer);return qaStart(...args);};`);}await route.fulfill({response,body:html});});
const ready=async()=>{await page.waitForFunction(()=>!document.getElementById('status'),null,{timeout:180000});await page.waitForTimeout(1800);};
await page.goto(base+'index.html?leon_ending='+Date.now(),{timeout:120000});await page.mouse.click(10,10);await ready();
await page.touchscreen.tap(422,212);await page.waitForTimeout(2500);await page.touchscreen.tap(422,286);
for(let i=0;i<60&&!logs.some(v=>v.includes('Battle Start:')&&v.includes('enemy_08_leon_crow'));i++){await page.keyboard.press('Enter');await page.waitForTimeout(250);}
if(!logs.some(v=>v.includes('Battle Start:')&&v.includes('enemy_08_leon_crow')))throw Error('Leon battle missing');
await page.screenshot({path:path.join(out,'leon_combat.png')});
await page.keyboard.down('ArrowRight');await page.waitForTimeout(1150);await page.keyboard.up('ArrowRight');
for(let i=0;i<35&&!logs.some(v=>v.includes('ENDING route=G'));i++){await page.keyboard.press('j',{delay:60});await page.keyboard.press('k',{delay:60});await page.keyboard.press('l',{delay:60});await page.waitForTimeout(250);}
if(!logs.some(v=>v.includes('Enemy defeated: enemy_08_leon_crow')))throw Error('Actual Leon KO missing');
if(!logs.some(v=>v.includes('ENDING route=G')))throw Error('All-survivor ending missing');
await page.waitForTimeout(1500);await page.screenshot({path:path.join(out,'all_survivor_rescue.png')});
if(logs.some(v=>v.includes('TITLE -> OPENING')))throw Error('Unexpected opening after KO');
// Inspect only this fresh context's IndexedDB. A reload must use the saved ending.
const readSave=async()=>page.evaluate(async()=>{for(const info of await indexedDB.databases()){const db=await new Promise((r,j)=>{const q=indexedDB.open(info.name);q.onsuccess=()=>r(q.result);q.onerror=()=>j(q.error);});if(!db.objectStoreNames.contains('FILE_DATA')){db.close();continue;}const rows=await new Promise((r,j)=>{const q=db.transaction('FILE_DATA').objectStore('FILE_DATA').getAll();q.onsuccess=()=>r(q.result);q.onerror=()=>j(q.error);});db.close();for(const row of rows){if(!row.contents)continue;const text=new TextDecoder().decode(row.contents);if(text.includes('scene="res://scenes/Stage8Ending.tscn"'))return text;}}return '';});
let saved='';for(let i=0;i<30&&!saved;i++){saved=await readSave();if(!saved)await page.waitForTimeout(500);}
if(!saved)throw Error('Ending checkpoint was not persisted');
const before=logs.length;await page.reload({timeout:120000});await ready();await page.touchscreen.tap(422,212);
const until=Date.now()+30000;while(Date.now()<until&&!logs.slice(before).some(v=>v.includes('ENDING route=G')))await page.waitForTimeout(200);
if(!logs.slice(before).some(v=>v.includes('ENDING route=G')))throw Error('Reload continue did not restore ending');
await page.screenshot({path:path.join(out,'reload_resumed_ending.png')});
for(let i=0;i<110&&!logs.slice(before).some(v=>v.includes('Battle Start:')&&v.includes('enemy_09_seiya'));i++){await page.keyboard.press('Enter');await page.waitForTimeout(220);}
if(!logs.slice(before).some(v=>v.includes('Battle Start:')&&v.includes('enemy_09_seiya')))throw Error('Resumed ending did not enter TRUE battle');
await page.screenshot({path:path.join(out,'true_final_battle.png')});
if(logs.some(v=>/^SCRIPT ERROR:|^ERROR:/.test(v))||errors.length)throw Error(JSON.stringify(errors));
if(process.env.EXPECTED_BUILD&&build!==process.env.EXPECTED_BUILD)throw Error('Unexpected build '+build);
fs.writeFileSync(path.join(out,'result.json'),JSON.stringify({success:true,build,viewport:{width:844,height:390},saved,scenario:'Actual attacks defeat one-HP Leon, all-survivor rescue, IndexedDB persistence, reload Continue, TRUE Seiya battle. Automated Edge touch viewport; physical iPhone untested.'},null,2));
console.log('LEON_ENDING_WEB_OK '+build);await context.close();
}
run().catch(e=>{console.error(e);process.exitCode=1;}).finally(async()=>{if(browser)await browser.close();if(server)await new Promise(r=>server.close(r));});
