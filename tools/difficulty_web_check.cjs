const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const fs=require('fs'),path=require('path'),http=require('http');
const base=process.argv[2],mobile=process.argv[3]==='mobile';
const out=path.resolve(__dirname,'../evidence/web/difficulty_'+(base.includes('127.0.0.1')?'local_':'public_')+(mobile?'mobile':'desktop'));
(async()=>{
 fs.mkdirSync(out,{recursive:true});let server;
 if(base.includes('127.0.0.1')){
  const web=path.resolve(__dirname,'../tmp/web');
  server=http.createServer((req,res)=>{const file=path.join(web,new URL(req.url,base).pathname.replace(/^\//,'')||'index.html');if(!file.startsWith(web+path.sep)||!fs.existsSync(file)){res.writeHead(404);return res.end();}res.setHeader('Content-Type',{'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm'}[path.extname(file)]||'application/octet-stream');fs.createReadStream(file).pipe(res);});
  await new Promise(r=>server.listen(Number(new URL(base).port),'127.0.0.1',r));
 }
 const browser=await chromium.launch({channel:'msedge',headless:true,args:['--enable-unsafe-swiftshader']});
 const errors=[],logs=[];let build='';
 try{
  const context=await browser.newContext({viewport:mobile?{width:844,height:390}:{width:1280,height:720},hasTouch:mobile});
  const page=await context.newPage();page.on('console',m=>logs.push(m.text()));page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.status()>=400)errors.push(r.status()+' '+r.url());});
  await page.route(/index\.html/,async route=>{const response=await route.fetch();let html=await response.text();build=(html.match(/"executable":"([^"]+)"/)||[])[1]||'';const marker='const engine = new Engine(GODOT_CONFIG);';if(!html.includes(marker))throw Error('bootstrap missing');html=html.replace(marker,marker+"const qaStart=engine.startGame.bind(engine);engine.startGame=async (...args)=>{await engine.init(GODOT_CONFIG.executable);engine.copyToFS('/userfs/godot/app_userdata/HashireIkazuchi/difficulty_qa.txt',new TextEncoder().encode('difficulty_v1').buffer);return qaStart(...args);};");await route.fulfill({response,body:html});});
  await page.goto(base+'index.html?difficulty_qa='+Date.now(),{waitUntil:'domcontentloaded',timeout:120000});
  await page.waitForFunction(()=>window.difficultyQAResult,null,{timeout:180000});
  const result=await page.evaluate(()=>window.difficultyQAResult);
  if(result.code||result.failures.length||!result.hard_unlocked||!result.saved_normal_clear||result.mode!=='hard')throw Error(JSON.stringify(result));
  await page.waitForTimeout(6000);await page.screenshot({path:path.join(out,'unlocked_hard.png')});
  await page.unroute(/index\.html/);await page.reload({waitUntil:'domcontentloaded',timeout:120000});
  await page.waitForFunction(()=>!document.getElementById('status'),null,{timeout:120000});await page.waitForTimeout(1800);
  await page.screenshot({path:path.join(out,'persisted_normal.png')});
  const before=logs.length;
  if(mobile)await page.touchscreen.tap(422,155);else await page.mouse.click(640,285);
  await page.waitForTimeout(500);
  if(!logs.slice(before).some(t=>t.includes('[Difficulty] selected=hard unlocked=true')))throw Error('Persisted unlock or mode button failed after page reload');
  await page.screenshot({path:path.join(out,'persisted_hard.png')});
  if(process.env.EXPECTED_BUILD&&build!==process.env.EXPECTED_BUILD)throw Error('Wrong release '+build);
  if(errors.length)throw Error(JSON.stringify(errors));
  fs.writeFileSync(path.join(out,'result.json'),JSON.stringify({base,build,mobile,result,persisted_after_reload:true,errors},null,2));
  console.log('DIFFICULTY_PUBLIC_WEB_OK '+JSON.stringify({build,mobile,result,persisted_after_reload:true}));
 }finally{fs.writeFileSync(path.join(out,'console.log'),logs.join('\n'));await browser.close();if(server)await new Promise(r=>server.close(r));}
})().catch(e=>{console.error(e);process.exitCode=1});
