const fs=require('fs'),path=require('path'),sharp=require('sharp');
const root=path.resolve(__dirname,'../godot');
// Reuse the alpha connected-component splitter used for the authored atlas.
const {components}=require('./build_cross_motion_atlas.cjs');
async function main(){
 const input=path.join(root,'assets/characters/cross_reactions/source.png');
 const {info,data,poses:all}=await components(input);
 // The last two poses touch in two rows. Do not crop connected characters:
 // retain the four clean reactions and each ally's original landing pose.
 const poses=all.filter(p=>p.left<990 && p.width<400);
 if(poses.length!==12)throw Error(`Expected 12 isolated clean reaction poses, got ${poses.length}`);
 poses.sort((a,b)=>(a.top+a.height/2)-(b.top+b.height/2));
 const actors=[['player01','ally_balance',320,224,0.55],['player02','ally_power',384,288,0.65],['player03','ally_speed',384,288,0.62]];
 for(let row=0;row<3;row++){
  const [actor,def,w,h,scale]=actors[row],parts=poses.slice(row*4,row*4+4).sort((a,b)=>a.left-b.left),layers=[];
  for(let i=0;i<4;i++){
   const p=parts[i],buf=Buffer.alloc(p.width*p.height*4);
   for(const q of p.indices){const to=((Math.floor(q/info.width)-p.top)*p.width+q%info.width-p.left)*4;data.copy(buf,to,q*4,q*4+4);}
   const width=Math.round(p.width*scale),height=Math.round(p.height*scale),left=Math.round((w-width)/2),top=h-18-height;
   if(left<0||top<0)throw Error('Reaction cell overflow');
   layers.push({input:await sharp(buf,{raw:{width:p.width,height:p.height,channels:4}}).resize(width,height,{kernel:'nearest'}).png().toBuffer(),left:i*w+left,top});
  }
  const main=['akky_v3','gou_v1','seiya_v1'][row];
  const mainDir=path.join(root,`assets/characters/${actor}/animations/${main}`);
  const mainTres=fs.readFileSync(path.join(mainDir,'motion_atlas.tres'),'utf8');
  const down=Number(mainTres.match(/"down": \{"frames": \[(\d+)/)[1]),cols=Number(mainTres.match(/columns = (\d+)/)[1]);
  layers.push({input:await sharp(path.join(mainDir,'motion_atlas.png')).extract({left:down%cols*w,top:Math.floor(down/cols)*h,width:w,height:h}).png().toBuffer(),left:4*w,top:0});
  const dir=`assets/characters/${actor}/animations/cross_reactions`;
  fs.mkdirSync(path.join(root,dir),{recursive:true});
  await sharp({create:{width:w*6,height:h,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(layers).png().toFile(path.join(root,dir,'reactions.png'));
  const clips={cross_react_pull:[0],cross_react_shoulder:[1,2],cross_react_reap:[2],cross_react_joint:[3],cross_react_pull_down:[0,2,4],cross_react_shoulder_down:[1,2,4],cross_react_reap_down:[2,4],cross_react_joint_down:[3,4]};
  fs.writeFileSync(path.join(root,dir,'reactions.tres'),`[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n[ext_resource type="Texture2D" path="res://${dir}/reactions.png" id="2"]\n[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\ncell_size = Vector2i(${w}, ${h})\ncolumns = 6\nclips = {\n${Object.entries(clips).map(([name,frames])=>`"${name}": {"frames": [${frames}], "fps": 9.0, "loop": false}`).join(',\n')}\n}\n`);
  const file=path.join(root,`data/fighters/${def}.tres`);
  let s=fs.readFileSync(file,'utf8');
  if(!s.includes('cross_reactions'))s=s.replace(/load_steps=(\d+)/,(_,n)=>'load_steps='+(+n+1)).replace('[resource]',`[ext_resource type="Resource" path="res://${dir}/reactions.tres" id="cross_reactions"]\n\n[resource]\nsupplemental_motion_atlas = ExtResource("cross_reactions")`);
  s=s.replace(/supplemental_motion_atlas = ExtResource\("cross_reactions"\)\r?\n/g,'').replace('script = ExtResource("1_definition")','script = ExtResource("1_definition")\nsupplemental_motion_atlas = ExtResource("cross_reactions")');
  fs.writeFileSync(file,s);
 }
 console.log('CROSS_REACTIONS_OK actors=3 new_poses=12 original_landings=3');
}
main().catch(e=>{console.error(e);process.exitCode=1});
