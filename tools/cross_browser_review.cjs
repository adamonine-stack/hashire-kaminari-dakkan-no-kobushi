const fs=require('fs'),path=require('path'),http=require('http');
const {chromium}=require('playwright');
async function main(){
 const base=path.resolve(__dirname,'..'),out=path.join(base,'audit_evidence/browser');fs.mkdirSync(out,{recursive:true});
 let server,url=process.argv[2];
 if(!url){
  const dir=path.join(base,'build/web');
  server=http.createServer((req,res)=>{
   const name=decodeURIComponent(req.url.split('?')[0]);const file=path.resolve(dir,'.'+(name==='/'?'/index.html':name));
   if(!file.startsWith(dir+path.sep)||!fs.existsSync(file)){res.writeHead(404);res.end();return;}
   const mime={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png','.pck':'application/octet-stream'};
   res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream'});fs.createReadStream(file).pipe(res);
  });await new Promise(r=>server.listen(8766,'127.0.0.1',r));url='http://127.0.0.1:8766/';
 }
 const executables=['C:/Program Files/Google/Chrome/Application/chrome.exe','C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'];
 const exe=executables.find(p=>fs.existsSync(p));
 const browser=await chromium.launch({executablePath:exe,headless:true,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
 const page=await browser.newPage({viewport:{width:1280,height:720}}),logs=[];
 page.on('console',m=>logs.push(m.text()));page.on('pageerror',e=>logs.push('PAGE_ERROR '+e.message));
 await page.goto(url,{waitUntil:'load',timeout:120000});await page.waitForTimeout(18000);
 await page.screenshot({path:path.join(out,process.argv[2]?'public-title.png':'local-title.png')});
 fs.writeFileSync(path.join(out,'console.log'),logs.join('\n'));
 console.log(JSON.stringify({url,title:await page.title(),canvas:await page.locator('canvas').count(),errors:logs.filter(x=>/error/i.test(x)).slice(-8)}));
 await browser.close();if(server)server.close();
}
main().catch(e=>{console.error(e);process.exit(1)});
