const fs = require('fs'), path = require('path'), sharp = require('sharp');
const folder = path.resolve(__dirname, '../godot/assets/characters/player03/animations/dark_seiya_v1');
async function main() {
  fs.mkdirSync(folder, {recursive:true});
  const original = path.join(folder, 'ground_contact_source.png');
  const {data,info} = await sharp(original).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  console.log('source alpha', data[3], data[(info.width * info.height-1)*4+3]);
  // Generated contact pose has the same head proportions as the reference.
  // One fixed authored conversion for this source, never runtime fit-to-pose.
  const contact = await sharp(original).trim({threshold:32}).resize({width:164,kernel:'nearest'}).png().toBuffer();
  const meta = await sharp(contact).metadata();
  const base = path.resolve(folder, '../seiya_v1/motion_atlas.png');
  const layers = [];
  // Keep original authored pixels, canvas, foot line and head size unchanged.
  const indices = [84,85,86,87,86,85,2];
  for (let i=0;i<indices.length;i++) {
    const n=indices[i];
    const image=await sharp(base).extract({left:n%8*384,top:Math.floor(n/8)*288,width:384,height:288}).png().toBuffer();
    layers.push({input:image,left:i*384,top:0});
  }
  layers.push({input:contact,left:7*384+Math.round(192-meta.width/2),top:270-meta.height});
  await sharp({create:{width:8*384,height:288,channels:4,background:'#00000000'}}).composite(layers).png().toFile(path.join(folder,'special_atlas.png'));
  console.log('DARK_SEIYA_ATLAS_OK contact=',meta.width,meta.height);
  const heads={};
  for(const [file,columns,count] of [[base,8,104],[path.resolve(folder,'../cross_reactions/reactions.png'),6,6],[path.join(folder,'special_atlas.png'),8,8]]) {
    for(let n=0;n<count;n++) {
      const {data}=await sharp(file).extract({left:n%columns*384,top:Math.floor(n/columns)*288,width:384,height:288}).ensureAlpha().raw().toBuffer({resolveWithObject:true});
      const mask=new Uint8Array(384*288);let best=null;
      for(let p=0;p<mask.length;p++) {const r=data[p*4]/255,g=data[p*4+1]/255,b=data[p*4+2]/255;if(data[p*4+3]>204&&r>.58&&g>.36&&b<r*.51&&g<r*.91)mask[p]=1;}
      for(let p=0;p<mask.length;p++) {if(mask[p]!==1)continue; const q=[p];mask[p]=2;let x0=384,y0=288,x1=0,y1=0;
        for(let j=0;j<q.length;j++){const t=q[j],x=t%384,y=Math.floor(t/384);x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);
          for(const v of [x>0?t-1:-1,x<383?t+1:-1,t-384,t+384])if(v>=0&&v<mask.length&&mask[v]===1){mask[v]=2;q.push(v);}}
        if(q.length>40&&y1-y0<65&&x1-x0>12&&(!best||y0<best[1]))best=[x0,y0,x1,y1];
      }
      const rect=best?[best[0]-4,best[1]-4,best[2]-best[0]+9,best[3]-best[1]+15]:[150,70,50,50];
      heads[path.basename(path.dirname(file))+'/'+path.basename(file)+':'+(n%columns*384)+':'+(Math.floor(n/columns)*288)]=rect;
    }
  }
  fs.writeFileSync(path.join(folder,'head_landmarks.json'),JSON.stringify(heads));
}
main().catch(e=>{console.error(e);process.exit(1)});
