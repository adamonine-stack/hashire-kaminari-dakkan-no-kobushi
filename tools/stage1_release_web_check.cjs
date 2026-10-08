// Use unchanged engine/PCK/WASM with a checkpoint save in a fresh QA context.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs=require('fs'),path=require('path'),http=require('http');
const base=process.argv[2];
const tag=process.argv[3] || 'public';
const mobile=process.argv[4]==='mobile';
const hero=Number(process.argv[6]||0);
const stages=(process.argv[5] || '5,6,7,8').split(',').map(Number);
const out=path.resolve(__dirname,'../evidence/web',tag+(mobile?'_mobile':'_desktop'));
function fixture(stage){
 let s=`[run]\nversion=1\nscene="res://scenes/Battle.tscn"\ncurrent_enemy_index=${stage-1}\n`;
 ['player_01_akky','player_02_gou','player_03_seiya'].forEach((id,i)=>s+=`[player_${i}]\ncharacter_id="${id}"\ncurrent_health=${[100,120,90][i]}\nis_defeated=false\nis_available=true\nspecial_gauge=100.0\n`);
 for(let i=0;i<8;i++)s+=`[enemy_${i}]\ncurrent_health=${i<stage-1?0:180}\nis_defeated=${i<stage-1}\n`;
 return s;
}
(async()=>{
 fs.mkdirSync(out,{recursive:true});
 let server;
 if(base.includes('127.0.0.1')){
  server=http.createServer((req,res)=>{
   const file=path.join(__dirname,'../tmp/web',req.url.split('?')[0].replace(/^\//,'')||'index.html');
   if(!fs.existsSync(file)){res.writeHead(404);res.end();return;}
   res.setHeader('Content-Type',{'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm'}[path.extname(file)]||'application/octet-stream');
   fs.createReadStream(file).pipe(res);
  });
  await new Promise(resolve=>server.listen(Number(new URL(base).port),'127.0.0.1',resolve));
 }
 const browser=await chromium.launch({channel:'msedge',headless:true,args:['--enable-unsafe-swiftshader']});
 try {
 for(const stage of stages){
  const context=await browser.newContext({viewport:mobile?{width:844,height:390}:{width:1280,height:720},hasTouch:mobile});
  try {
   const page=await context.newPage(),logs=[],errors=[];
   page.on('console',m=>logs.push(m.text()));
   page.on('pageerror',e=>errors.push(e.message));
   page.on('response',r=>{if(r.status()>=400)errors.push(r.status()+' '+r.url());});
   let build='';
   await page.route(/index\.html/,async route=>{
    const response=await route.fetch();let html=await response.text();
    build=(html.match(/"executable":"([^"]+)"/)||[])[1] || '';
    const marker='const engine = new Engine(GODOT_CONFIG);';
    if(!html.includes(marker))throw Error('bootstrap marker missing');
    html=html.replace(marker,`${marker}const originalStart=engine.startGame.bind(engine);engine.startGame=async (...args)=>{await engine.init(GODOT_CONFIG.executable);engine.copyToFS('/userfs/godot/app_userdata/HashireIkazuchi/save.cfg',new TextEncoder().encode(${JSON.stringify(fixture(stage))}).buffer);return originalStart(...args);};`);
    await route.fulfill({response,body:html});
   });
   const snap=name=>page.screenshot({path:path.join(out,`stage${stage}_${name}.png`)});
   await page.goto(base+'index.html?st_action_qa='+Date.now());
   await page.waitForFunction(()=>!document.getElementById('status'),{},{timeout:90000});
   await page.waitForTimeout(1800);
   await snap('title');
   await page.mouse.click(mobile?422:640,mobile?212:390,{delay:90});
   for(let i=0;i<80&&!logs.some(t=>t.includes('[SAVE] Continued from stage '+stage));i++)await page.waitForTimeout(250);
   if(!logs.some(t=>t.includes('[SAVE] Continued from stage '+stage))){fs.writeFileSync(path.join(out,`stage${stage}.log`),logs.join('\n'));await snap('select_failed');throw Error('checkpoint was not resumed for stage '+stage);}
   await page.waitForTimeout(1000);
   await snap('select');
   await page.mouse.click(mobile?[287,422,556][hero]:[435,640,845][hero],mobile?100:151,{delay:90});
   await page.mouse.click(mobile?422:640,mobile?286:528,{delay:90});
   await page.waitForTimeout(1500);
   await snap('intro');
   for(let i=0;i<65&&!logs.some(t=>t.includes('Battle Start:'));i++){
    await page.keyboard.press('Enter',{delay:40});await page.waitForTimeout(160);
   }
   if(!logs.some(t=>t.includes('Battle Start:')))throw Error('stage '+stage+' did not start');
   await snap('idle');
   await page.keyboard.down('ArrowRight');await page.waitForTimeout(240);await snap('walk');await page.keyboard.up('ArrowRight');
   await page.keyboard.press('ArrowUp',{delay:65});await page.waitForTimeout(130);await snap('jump');
   await page.waitForTimeout(500);await page.keyboard.press('j',{delay:50});await page.waitForTimeout(100);await snap('attack');
   const usedSpecial=()=>logs.some(t=>t.includes('[Special] started id=player'+(hero+1)+'_special'));
   for(let i=0;i<12&&!usedSpecial();i++){
    await page.waitForTimeout(350);await page.keyboard.press('l',{delay:70});
   }
   await page.waitForTimeout(100);await snap('special');
   fs.writeFileSync(path.join(out,`stage${stage}.log`),logs.join('\n'));
   if(!usedSpecial())throw Error('player special did not consume MAX gauge on stage '+stage);
   const runtime=logs.filter(t=>/^SCRIPT ERROR:|^ERROR:/.test(t));
   if(errors.length||runtime.length)throw Error(JSON.stringify({errors,runtime}));
   console.log('ST_ACTION_WEB_STAGE_OK '+stage+' '+tag+' '+build);
  }finally{await context.close();}
 }
 }finally{await browser.close();if(server)server.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
