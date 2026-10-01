// Usage: PLAYWRIGHT_MODULE=path/to/playwright node tools/stage8_web_check.cjs URL ABCDEFG [mobile]
// Fresh browser contexts. Only the HTML bootstrap receives a checkpoint fixture.
// The published PCK, engine JS and WASM remain unchanged.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs=require('fs'),path=require('path'),http=require('http');
const base=process.argv[2]||'http://127.0.0.1:8139/';
const routes=process.argv[3]||'A';
const mobile=process.argv[4]==='mobile';
let server;
if(base.includes('127.0.0.1')) server=http.createServer((req,res)=>{
 const file=path.join(__dirname,'../tmp/web',req.url.split('?')[0].replace(/^\//,'')||'index.html');
 res.writeHead(200,{'Content-Type':{'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm'}[path.extname(file)]||'application/octet-stream'});fs.createReadStream(file).pipe(res);
}).listen(Number(new URL(base).port),'127.0.0.1');
const masks={A:1,B:2,C:4,D:3,E:5,F:6,G:7};
function fixture(route){let s='[run]\nversion=1\nscene="res://scenes/Battle.tscn"\ncurrent_enemy_index=7\n';
 ['player_01_akky','player_02_gou','player_03_seiya'].forEach((id,i)=>{const alive=!!(masks[route]&(1<<i));s+=`[player_${i}]\ncharacter_id="${id}"\ncurrent_health=${alive?50:0}\nis_defeated=${!alive}\nis_available=${alive}\nspecial_gauge=100.0\n`;});
 for(let i=0;i<8;i++)s+=`[enemy_${i}]\ncurrent_health=${i===7?1:0}\nis_defeated=${i!==7}\n`;return s;}
(async()=>{
 fs.mkdirSync(path.join(__dirname,'../evidence/stage8'),{recursive:true});
 fs.mkdirSync(path.join(__dirname,'../logs'),{recursive:true});
 const browser=await chromium.launch({channel:'msedge',headless:true,args:['--enable-unsafe-swiftshader']});
 for(const route of routes){
  const context=await browser.newContext({viewport:mobile?{width:844,height:390}:{width:1280,height:720},hasTouch:mobile});const page=await context.newPage();const logs=[];
  page.on('console',m=>{logs.push(m.text());if(/STAGE8_|Battle Start|Continued|ERROR/.test(m.text()))console.log(route+' '+m.text());});page.on('pageerror',e=>logs.push('PAGEERROR '+e.message));
  await page.route(/index\.html/,async r=>{const response=await r.fetch();let html=await response.text();html=html.replace('const engine = new Engine(GODOT_CONFIG);',`const engine = new Engine(GODOT_CONFIG);const originalStart=engine.startGame.bind(engine);engine.startGame=async (...args)=>{await engine.init(GODOT_CONFIG.executable);engine.copyToFS('/userfs/godot/app_userdata/HashireIkazuchi/save.cfg',new TextEncoder().encode(${JSON.stringify(fixture(route))}).buffer);return originalStart(...args);};`);await r.fulfill({response,body:html});});
  await page.goto(base+'index.html?qa='+Date.now());await page.waitForTimeout(14000);
  const out=name=>path.join(__dirname,'../evidence/stage8',`${base.includes('127')?'local':'public'}_${route}_${mobile?'mobile':'desktop'}_${name}.png`);
  await page.screenshot({path:out('title')});
  await page.mouse.click(mobile?422:640,mobile?212:390,{delay:90});await page.waitForTimeout(2500);
  await page.screenshot({path:out('select')});
  await page.mouse.click(mobile?422:640,mobile?286:528,{delay:90});await page.waitForTimeout(1800);
  for(let i=0;i<60&&!logs.some(t=>t.includes('Battle Start:'));i++){
    await page.mouse.click(mobile?422:640,mobile?336:620,{delay:60});await page.waitForTimeout(220);
  }
  await page.waitForTimeout(300);
  await page.screenshot({path:out('fight')});
  // Approach the actual final Stage 8 opponent, then hit his one-HP fixture.
  await page.keyboard.down('ArrowRight');await page.waitForTimeout(1100);await page.keyboard.up('ArrowRight');
  for(let i=0;i<15&&!logs.some(t=>t.includes('ENDING route='));i++){await page.keyboard.press('j',{delay:80});await page.keyboard.press('k',{delay:80});await page.waitForTimeout(500);}
  for(let i=0;i<12&&!logs.some(t=>t.includes('ENDING route='));i++)await page.waitForTimeout(500);
  await page.waitForTimeout(600);await page.screenshot({path:out('rescue')});
  if(!logs.some(t=>t.includes('ENDING route='+route))){fs.writeFileSync(path.join(__dirname,'../logs',`web_failed_${route}.log`),logs.join('\n'));throw new Error(route+' did not enter ending');}
  const count=route==='G'?380:route==='C'?20:85;
  for(let i=0;i<count;i++){if(mobile)await page.touchscreen.tap(671,364);else await page.keyboard.press('Enter',{delay:60});await page.waitForTimeout(210);if(logs.some(t=>t.includes('VS enemy_09_seiya')||t.includes('END_CARD')))break;}
  await page.waitForTimeout(1500);await page.screenshot({path:out('end')});
  if(route==='G'&&!logs.some(t=>t.includes('VS enemy_09_seiya')))throw new Error('G true battle missing');
  if(route!=='G'&&!logs.some(t=>t.includes('END_CARD route='+route)))throw new Error(route+' end card missing');
  if(logs.some(t=>/^SCRIPT ERROR:|^ERROR:|PAGEERROR/.test(t)))throw new Error(route+' runtime error');
  fs.writeFileSync(path.join(__dirname,'../logs',`web_fixture_${base.includes('127')?'local':'public'}_${route}.log`),logs.join('\n'));
  console.log('WEB_FIXTURE_OK '+route+' '+base);await context.close();
 }
 await browser.close();if(server)server.close();
})().catch(e=>{console.error(e);if(server)server.close();process.exit(1);});
