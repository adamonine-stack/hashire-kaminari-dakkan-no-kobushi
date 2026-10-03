// Published PCK/WASM are unchanged. A private fresh-browser fixture runs the QA battle scenario.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const fs=require('fs'),path=require('path');
const base=process.argv[2],mobile=process.argv[3]==='mobile';
const out=path.resolve(__dirname,'../evidence/web/stage9_'+(mobile?'mobile':'desktop'));
(async()=>{
 fs.mkdirSync(out,{recursive:true});
 const browser=await chromium.launch({channel:'msedge',headless:true,args:['--enable-unsafe-swiftshader']});
 const context=await browser.newContext({viewport:mobile?{width:844,height:390}:{width:1280,height:720},hasTouch:mobile});
 const page=await context.newPage(),logs=[],errors=[],shots=[];
 fs.writeFileSync(path.join(out,'console.log'),'');
 if(fs.existsSync(path.join(out,'result.json')))fs.unlinkSync(path.join(out,'result.json'));
 let build='',screenshotCount=0;
 page.on('console',msg=>{
  const t=msg.text();logs.push(t);fs.appendFileSync(path.join(out,'console.log'),t+'\n');
  if(t.startsWith('STAGE9_CAPTURE ')) {
   const label=t.slice('STAGE9_CAPTURE '.length).replace(/[^\w-]/g,'_');
   const capture=async()=>{
    {
     await page.screenshot({path:path.join(out,label+'.png')});screenshotCount++;
    }
    await page.evaluate(value=>{window.stage9CaptureDone=value;},label);
   };
   shots.push(capture().catch(e=>errors.push(e.message)));
  }
 });
 page.on('pageerror',e=>errors.push(e.message));
 page.on('response',r=>{if(r.status()>=400)errors.push(r.status()+' '+r.url());});
 await page.route(/index\.html/,async route=>{
  const response=await route.fetch();let html=await response.text();
  build=(html.match(/"executable":"([^"]+)"/)||[])[1]||'';
  const marker='const engine = new Engine(GODOT_CONFIG);';
  if(!html.includes(marker))throw Error('Missing bootstrap marker');
  html=html.replace(marker,`${marker}\nconst qaStart=engine.startGame.bind(engine);engine.startGame=async (options={})=>{await engine.init(GODOT_CONFIG.executable);engine.copyToFS('/userfs/godot/app_userdata/HashireIkazuchi/qa/stage9_motion.flag',new TextEncoder().encode('stage9_motion_v1').buffer);return qaStart(options);};`);
  await route.fulfill({response,body:html});
 });
 try {
  await page.goto(base+'index.html?stage9_qa='+Date.now());
  await page.mouse.click(10,10); // Give the browser a gesture before its audio runtime starts.
  const deadline=Date.now()+900000;
  while(Date.now()<deadline&&!logs.some(t=>t.includes('STAGE9_TWO_HIT_RESULT')||/SCRIPT ERROR:|^ERROR:/.test(t)))await page.waitForTimeout(500);
  await Promise.all(shots);
  fs.writeFileSync(path.join(out,'console.log'),logs.join('\n'));
  fs.writeFileSync(path.join(out,'errors.json'),JSON.stringify(errors,null,2));
  if(!logs.some(t=>t.includes('STAGE9_TWO_HIT_RESULT')&&t.includes('failures=[]')))throw Error('Published battle QA did not pass');
  if(!logs.some(t=>t.includes('STAGE9_TWO_HIT_RESULT cases=54 frames=322')))throw Error('Incomplete Stage9 coverage');
  if(process.env.EXPECTED_BUILD&&build!==process.env.EXPECTED_BUILD)throw Error('Unexpected published build '+build);
  if(errors.length||logs.some(t=>/SCRIPT ERROR:|^ERROR:/.test(t)))throw Error('Published battle QA has errors');
  fs.writeFileSync(path.join(out,'result.json'),JSON.stringify({build,mobile,scenario:'Stage9 all frames and 54 two-hit boss/hero cases plus normal pillar; not manual gameplay',screenshots:screenshotCount,webglDiagnostics:logs.filter(t=>/WebGL.*INVALID_|GL_INVALID/.test(t)).length,success:true},null,2));
  console.log('STAGE9_PUBLIC_WEB_OK '+build+' '+(mobile?'mobile':'desktop')+' screenshots='+screenshotCount);
 } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exit(1)});
