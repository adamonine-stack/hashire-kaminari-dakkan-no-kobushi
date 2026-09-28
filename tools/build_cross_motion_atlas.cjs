// Packs original generated animation art without repainting or per-pose scaling.
const fs = require('fs'), path = require('path'), sharp = require('sharp');
const root = path.resolve(__dirname, '../godot/assets/characters/enemy05/animations/cross_v1');
async function components(file) {
  const {data, info} = await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const {width:w,height:h} = info, seen = new Uint8Array(w*h), out=[];
  for(let p=0;p<w*h;p++) {
    if(seen[p] || data[p*4+3]<32) continue;
    const todo=[p];seen[p]=1;let x0=w,y0=h,x1=0,y1=0;
    for(let n=0;n<todo.length;n++) {
      const q=todo[n],x=q%w,y=Math.floor(q/w);
      x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);
      for(const v of [x>0?q-1:-1,x<w-1?q+1:-1,y>0?q-w:-1,y<h-1?q+w:-1])
        if(v>=0&&!seen[v]&&data[v*4+3]>=32){seen[v]=1;todo.push(v);}
    }
    if(todo.length>500)out.push({left:x0,top:y0,width:x1-x0+1,height:y1-y0+1,pixels:todo.length,indices:todo});
  }
  return {info,data,poses:out};
}
async function main(){
  const sources=[['base',6,6],['extras',5,4]];
  const layers=[], manifest=[];
  for(const [name,cols,rows] of sources){
    const file=path.join(root,'sources',name+'.png');
    if(!fs.existsSync(file))throw Error(`Missing production source: ${file}`);
    const {info,data,poses}=await components(file);
    console.log(name,info.width,info.height,`poses=${poses.length}`);
    if(poses.length!==cols*rows)throw Error(`${name}: expected ${cols*rows} isolated poses, got ${poses.length}`);
    // Authored rows are ordered by body center, then each row left to right.
    poses.sort((a,b)=>(a.top+a.height/2)-(b.top+b.height/2));
    const ordered=[];
    for(let row=0;row<rows;row++)ordered.push(...poses.slice(row*cols,(row+1)*cols).sort((a,b)=>a.left-b.left));
    for(let j=0;j<ordered.length;j++){
      const p=ordered[j],index=manifest.length;
      // Preserve source horizontal body placement relative to its authored column.
      // One scale for the entire supplementary sheet (its native density differs).
      const scale=name==='extras'?0.72:0.94;
      const width=Math.round(p.width*scale),height=Math.round(p.height*scale);
      const left=Math.round((384-width)/2);
      const top=270-height;
      if(left<0||left+width>384||top<0)throw Error(`Overflow ${name}/${j}`);
      const rect={left:p.left,top:p.top,width:p.width,height:p.height};
      // Rectangles can overlap another pose's extended fist. Pack only this
      // connected sprite, not unrelated pixels inside its bounding rectangle.
      const isolated=Buffer.alloc(p.width*p.height*4);
      for(const q of p.indices){const to=((Math.floor(q/info.width)-p.top)*p.width+q%info.width-p.left)*4;data.copy(isolated,to,q*4,q*4+4);}
      layers.push({input:await sharp(isolated,{raw:{width:p.width,height:p.height,channels:4}}).resize(width,height,{kernel:'nearest'}).png().toBuffer(),left:(index%8)*384+left,top:Math.floor(index/8)*288+top});
      manifest.push({index,source:name,source_index:j,rect,offset:{x:left,y:top},scale,baseline:270});
    }
  }
  await sharp({create:{width:3072,height:Math.ceil(manifest.length/8)*288,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(layers).png().toFile(path.join(root,'motion_atlas.png'));
  fs.writeFileSync(path.join(root,'packing_manifest.json'),JSON.stringify({cell:[384,288],columns:8,frames:manifest},null,2)+'\n');
  console.log(`CROSS_PACK_OK poses=${manifest.length}`);
}
module.exports = {components};
if (require.main === module) main().catch(e=>{console.error(e);process.exitCode=1;});
