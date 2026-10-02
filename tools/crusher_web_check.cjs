// Published PCK/WASM are unchanged. A private bootstrap argument runs the QA battle scenario.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const fs=require('fs'),path=require('path');
const base=process.argv[2],mobile=process.argv[3]==='mobile';
const out=path.resolve(__dirname,'../evidence/web/crusher_'+(mobile?'mobile':'desktop'));
(async()=>{
 fs.mkdirSync(out,{recursive:true});
 const browser=await chromium.launch({channel:'msedge',headless:true,args:['--enable-unsafe-swiftshader']});
 const context=await browser.newContext({viewport:mobile?{width:844,height:390}:{width:1280,height:720},hasTouch:mobile});
 const page=await context.newPage(),logs=[],errors=[],shots=[];
 let build='';
 page.on('console',msg=>{
  const t=msg.text();logs.push(t);
  if(t.startsWith('CRUSHER_CAPTURE ') && /_impact$|_down$|_guard_|crusher_ai/.test(t)) {
   const label=t.slice('CRUSHER_CAPTURE '.length).replace(/[^\w-]/g,'_');
   shots.push(page.screenshot({path:path.join(out,label+'.png')}).catch(e=>errors.push(e.message)));
  }
 });
 page.on('pageerror',e=>errors.push(e.message));
 page.on('response',r=>{if(r.status()>=400)errors.push(r.status()+' '+r.url());});
 await page.route(/index\.html/,async route=>{
  const response=await route.fetch();let html=await response.text();
  build=(html.match(/"executable":"([^"]+)"/)||[])[1]||'';
  const marker='const engine = new Engine(GODOT_CONFIG);';
  if(!html.includes(marker))throw Error('Missing bootstrap marker');
  html=html.replace(marker,`${marker}\nconst qaStart=engine.startGame.bind(engine);engine.startGame=(options={})=>qaStart({...options,args:['--script','res://tests/crusher_reversal_presentation_check.gd']});`);
  await route.fulfill({response,body:html});
 });
 try {
  await page.goto(base+'index.html?crusher_qa='+Date.now());
  const deadline=Date.now()+240000;
  while(Date.now()<deadline&&!logs.some(t=>t.includes('SPECIAL_LAUNCH_REACTION_CHECK failures=')))await page.waitForTimeout(500);
  await Promise.all(shots);
  fs.writeFileSync(path.join(out,'console.log'),logs.join('\n'));
  fs.writeFileSync(path.join(out,'errors.json'),JSON.stringify(errors,null,2));
  if(!logs.some(t=>t.includes('SPECIAL_LAUNCH_REACTION_CHECK failures=[]')))throw Error('Published battle QA did not pass');
  if(errors.length||logs.some(t=>/SCRIPT ERROR:|^ERROR:/.test(t)))throw Error('Published battle QA has errors');
  fs.writeFileSync(path.join(out,'result.json'),JSON.stringify({build,mobile,scenario:'controlled Enemy-to-Player actual Battle.tscn contacts; not manual gameplay',screenshots:shots.length,success:true},null,2));
  console.log('CRUSHER_PUBLIC_WEB_OK '+build+' '+(mobile?'mobile':'desktop')+' screenshots='+shots.length);
 } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exit(1)});
