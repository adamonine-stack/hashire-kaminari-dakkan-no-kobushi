// Read alpha bounds and emit a measured atlas. Never resize or fit individual poses.
const fs = require('fs');
const path = require('path');
const {PNG} = require('C:/Users/takas/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/pngjs');
const folder = path.resolve(__dirname, '../godot/assets/characters/player01/animations/forward_leap_v1');
const png = PNG.sync.read(fs.readFileSync(path.join(folder, 'source.png')));
const seen = new Uint8Array(png.width*png.height);
const components=[];
for(let pixel=0;pixel<seen.length;pixel++) {
  if(seen[pixel] || png.data[pixel*4+3]<=32) continue;
  let x0=png.width,y0=png.height,x1=0,y1=0,count=0;
  const stack=[pixel];seen[pixel]=1;
  while(stack.length) {
    const n=stack.pop(),x=n%png.width,y=Math.floor(n/png.width);
    count++;x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);
    for(const next of [x>0?n-1:-1,x+1<png.width?n+1:-1,y>0?n-png.width:-1,y+1<png.height?n+png.width:-1]) {
      if(next>=0 && !seen[next] && png.data[next*4+3]>32) {seen[next]=1;stack.push(next);}
    }
  }
  if(count>2000) components.push({x:x0,y:y0,w:x1-x0+1,h:y1-y0+1,count});
}
if(components.length!==8) throw new Error('Expected eight isolated full-body poses: '+JSON.stringify(components));
const regions=components.sort((a,b)=>(Math.floor((a.y+a.h/2)/(png.height/2))-Math.floor((b.y+b.h/2)/(png.height/2))) || a.x-b.x);
for(const r of regions) if(r.x<=0 || r.y<=0 || r.x+r.w>=png.width || r.y+r.h>=png.height) throw new Error('Clipped source silhouette');
// One source-to-display scale based on neutral full body height; identical for all frames.
const scale = 160 / regions[0].h;
const offsets = regions.map(r=>({x:Math.round(160-r.w*scale/2),y:Math.round(208-r.h*scale)}));
for(let i=0;i<8;i++) if(offsets[i].x<0 || offsets[i].y<0 || offsets[i].x+Math.round(regions[i].w*scale)>320) throw new Error('Pose exceeds fixed display cell');
const text = `[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]
[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/characters/player01/animations/forward_leap_v1/source_texture.res" id="2"]
[resource]
script = ExtResource("1")
texture = ExtResource("2")
cell_size = Vector2i(320,224)
columns = 4
head_scale_override = 1.0
frame_regions = Array[Rect2i]([${regions.map(r=>`Rect2i(${r.x},${r.y},${r.w},${r.h})`).join(',')}])
frame_offsets = Array[Vector2i]([${offsets.map(o=>`Vector2i(${o.x},${o.y})`).join(',')}])
frame_source_scales = Array[float]([${regions.map(()=>scale).join(',')}])
frame_offsets_are_display_pixels = true
source_alpha_threshold = 0.03137255
isolate_source_component = true
clips = {
"akky_diagonal_jump": {"frames": [1,2,2], "fps": 13.636, "loop": false},
"akky_diagonal_punch": {"frames": [3,4,5,5], "fps": 16.667, "loop": false},
"akky_diagonal_land": {"frames": [6,6,7], "fps": 10.0, "loop": false}
}
`;
fs.writeFileSync(path.join(folder,'motion_atlas.tres'),text);
fs.writeFileSync(path.join(folder,'measurements.json'),JSON.stringify({width:png.width,height:png.height,regions,scale,offsets},null,2));
console.log(JSON.stringify({regions,uniformScale:scale}));
