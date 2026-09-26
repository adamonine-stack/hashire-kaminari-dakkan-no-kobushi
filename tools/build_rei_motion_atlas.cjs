// Deterministic game-asset packing; preserve generated pixels, alpha and scale.
const sharp = require('sharp');
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '../godot/assets/characters/enemy04/animations/rei_v1');
async function run() {
  const {data, info} = await sharp(path.join(root, 'sources/generated_atlas.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const w = info.width, h = info.height, seen = new Uint8Array(w*h), components = [];
  for (let p=0;p<w*h;p++) {
    if(seen[p] || data[p*4+3]<32) continue;
    const todo=[p]; seen[p]=1; let minX=w,minY=h,maxX=0,maxY=0;
    for(let n=0;n<todo.length;n++) {
      const q=todo[n], x=q%w,y=Math.floor(q/w);
      minX=Math.min(minX,x); minY=Math.min(minY,y); maxX=Math.max(maxX,x); maxY=Math.max(maxY,y);
      for(const v of [x>0?q-1:-1,x<w-1?q+1:-1,y>0?q-w:-1,y<h-1?q+w:-1]) {
        if(v>=0 && !seen[v] && data[v*4+3]>=32) { seen[v]=1;todo.push(v); }
      }
    }
    if(todo.length>100) components.push({n:todo.length,left:minX,top:minY,width:maxX-minX+1,height:maxY-minY+1});
  }
  if (components.length !== 36) throw new Error(`Expected 36 isolated poses; got ${components.length}`);
  // Order the six authored rows by their feet, then by column. No pose resizing.
  const rows = [235, 455, 678, 890, 1075, 1254];
  const ordered = rows.flatMap((end,row) => components.filter(c => c.top+c.height <= end && c.top+c.height > (row ? rows[row-1] : 0)).sort((a,b)=>a.left-b.left));
  const layers=[], manifest=[];
  for(let i=0;i<ordered.length;i++) {
    const c=ordered[i], col=i%6;
    const left=c.left-col*209+55;
    const lift=i===9?34:i===10?18:(i===30||i===31)?24:0;
    const top=270-c.height-lift;
    if(left<0 || left+c.width>320 || top<0) throw new Error(`Overflow at ${i}`);
    layers.push({input:await sharp(path.join(root,'sources/generated_atlas.png')).extract({left:c.left,top:c.top,width:c.width,height:c.height}).png().toBuffer(),left:col*320+left,top:Math.floor(i/6)*300+top});
    manifest.push({index:i,source_rect:c,offset:{x:left,y:top},scale:1,baseline:270-lift});
  }
  await sharp({create:{width:1920,height:1800,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(layers).png().toFile(path.join(root,'motion_atlas.png'));
  fs.writeFileSync(path.join(root,'packing_manifest.json'),JSON.stringify({cell:[320,300],columns:6,frames:manifest},null,2)+'\n');
  console.log('REI_ATLAS_OK 36 poses, 1920x1800, unchanged pixel scale and alpha');
}
run().catch(e=>{console.error(e);process.exitCode=1;});