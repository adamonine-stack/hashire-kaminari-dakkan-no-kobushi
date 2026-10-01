const {chromium}=require('playwright');
const fs=require('fs'),path=require('path'),http=require('http');
const base=process.argv[2]||'http://127.0.0.1:8142/';
const mode=process.argv[3]||'capture';
const mobile=process.argv[4]==='mobile';
const out=path.resolve(__dirname,'../evidence/seiya');
const prefix=(base.includes('127.0.0.1')?'local':'public')+(mobile?'_mobile':'_desktop');
let server;
function saveFixture(){let s='[run]\nversion=1\nscene="res://scenes/TrueBattle.tscn"\ncurrent_enemy_index=8\n';
 for(const [i,id] of ['player_01_akky','player_02_gou'].entries())s+=`[player_${i}]\ncharacter_id="${id}"\ncurrent_health=${i?65:50}\nis_defeated=false\nis_available=true\nspecial_gauge=100.0\n`;
 for(let i=0;i<9;i++)s+=`[enemy_${i}]\ncurrent_health=${i===8?180:0}\nis_defeated=${i!==8}\n`;
 return s;
}
async function run(){
 fs.mkdirSync(out,{recursive:true});fs.mkdirSync(path.resolve(__dirname,'../logs'),{recursive:true});
 if(base.includes('127.0.0.1'))server=http.createServer((req,res)=>{
  const file=path.join(__dirname,'../tmp/web',req.url.split('?')[0].replace(/^\//,'')||'index.html');
  if(!fs.existsSync(file)){res.writeHead(404);res.end();return;}
  res.setHeader('Content-Type',{'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm'}[path.extname(file)]||'application/octet-stream');fs.createReadStream(file).pipe(res);
 }).listen(Number(new URL(base).port),'127.0.0.1');
 const browser=await chromium.launch({channel:'msedge',headless:true,args:['--enable-unsafe-swiftshader']});
 const context=await browser.newContext({viewport:mobile?{width:844,height:390}:{width:1280,height:720},hasTouch:mobile});
 const page=await context.newPage(),logs=[],errors=[];
 page.on('console',m=>{logs.push(m.text());if(/DARK_AURA|Battle Start|ERROR|failures/.test(m.text()))console.log(m.text());});
 page.on('pageerror',e=>errors.push(e.message));
 page.on('response',r=>{if(r.status()>=400)errors.push(r.status()+' '+r.url());});
 // Prepare a save in a fresh browser context. Published PCK/JS/WASM untouched.
 await page.route(/index\.html/,async route=>{
  const response=await route.fetch();let html=await response.text();
  html=html.replace('const engine = new Engine(GODOT_CONFIG);',`const engine = new Engine(GODOT_CONFIG);const originalStart=engine.startGame.bind(engine);engine.startGame=async (...args)=>{await engine.init(GODOT_CONFIG.executable);engine.copyToFS('/userfs/godot/app_userdata/HashireIkazuchi/save.cfg',new TextEncoder().encode(${JSON.stringify(saveFixture())}).buffer);return originalStart(...args);};`);
  await route.fulfill({response,body:html});
 });
 const snap=async name=>page.screenshot({path:path.join(out,prefix+'_'+name+'.png')});
 await page.goto(base+'index.html?seiyaqa='+Date.now());
 await page.waitForFunction(()=>typeof Engine==='function');
 await page.waitForTimeout(14000);await snap('title');
 await page.mouse.click(mobile?422:640,mobile?212:390,{delay:90});
 await page.waitForTimeout(2500);await snap('select');
 if(mode!=='capture'){
  await page.mouse.click(mobile?422:640,mobile?286:528,{delay:90});
  for(let i=0;i<30&&!logs.some(t=>t.includes('VS enemy_09_seiya'));i++)await page.waitForTimeout(300);
  if(!logs.some(t=>t.includes('VS enemy_09_seiya')))throw Error('True battle did not start');
  let shots=0;
  // Stay far enough to observe actual AI's telegraphed special and one contact.
  for(let i=0;i<45&&!logs.some(t=>t.includes('DARK_AURA_HIT'));i++){
    if(logs.some(t=>t.includes('DARK_AURA_START'))&&shots===0){await snap('charge');shots++;}
    if(logs.some(t=>t.includes('DARK_AURA_WARNING'))&&shots===1){await snap('warning');shots++;}
    await page.waitForTimeout(80);
  }
  await snap('pillar');
  if(!logs.some(t=>t.includes('DARK_AURA_HIT count=1')))throw Error('AI pillar did not contact once');
  // Real movement/jump/attacks after the special; screenshots show the real build.
  await page.keyboard.down('ArrowRight');await page.waitForTimeout(600);await page.keyboard.up('ArrowRight');
  await page.keyboard.press('ArrowUp',{delay:80});await page.waitForTimeout(200);await snap('jump');
  await page.keyboard.press('j',{delay:80});await page.keyboard.press('k',{delay:80});
  await page.waitForTimeout(400);await snap('combat');
  const starts=logs.filter(t=>t.includes('DARK_AURA_START')).length;
  if(starts>1)throw Error('AI repeated special inside cooldown');
 }
 const runtime=logs.filter(t=>/^SCRIPT ERROR:|^ERROR:/.test(t));
 fs.writeFileSync(path.resolve(__dirname,'../logs',prefix+'_dark_seiya.log'),logs.join('\n'));
 if(errors.length||runtime.length)throw Error(JSON.stringify({errors,runtime}));
 console.log('DARK_SEIYA_WEB_OK '+mode+' '+base+' '+prefix);
 await context.close();await browser.close();if(server)server.close();
}
run().catch(e=>{console.error(e);if(server)server.close();process.exit(1);});
