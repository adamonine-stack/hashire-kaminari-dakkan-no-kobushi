const fs=require('fs'),path=require('path');
const root=path.resolve(__dirname,'../godot');
function edit(file,fn){const p=path.join(root,file);fs.writeFileSync(p,fn(fs.readFileSync(p,'utf8')));}
function write(file,text){fs.writeFileSync(path.join(root,file),text);}
for(const file of ['scripts/battle/battle_manager.gd','scripts/battle/round_manager.gd']) edit(file,s=>s.replace('enemy_02_speed.tres','SWAP.tres').replace('enemy_04_throw.tres','enemy_02_speed.tres').replace('SWAP.tres','enemy_04_throw.tres'));
edit('data/enemies/enemy_02_speed.tres',s=>s.replace('enemy_order = 2','enemy_order = 4'));
edit('scenes/Battle.tscn',s=>s.replace('active_enemy_count_limit = 1','active_enemy_count_limit = 2'));
edit('scripts/battle/stage1_battle_manager.gd',s=>s.replace('## Stage 1 completion slice.','## Published campaign slice (one or two stages).').replace('\t_show_message("STAGE 1 CLEAR")','\tvar title := "STAGE %d CLEAR" % enemy_team.size()\n\t_show_message(title)').replace('_show_end_panel("STAGE 1 CLEAR", "Crusher defeated.\\nORDER: %s\\nDEFEATED: %d  SURVIVED: %d" % [','_show_end_panel(title, "All opponents defeated.\\nORDER: %s\\nDEFEATED: %d  SURVIVED: %d" % [').replace('print("STAGE 1 CLEAR")','print(title)'));
// Keep Stage 1 isolation tests explicit while the shipped scene continues to Rei.
for(const file of ['tests/stage1_regression.gd','tests/dev053_stage1_smoke.gd']) edit(file,s=>s.replace('\troot.add_child(battle)','\tbattle.get_node("BattleManager").active_enemy_count_limit = 1\n\troot.add_child(battle)').replace('\tget_root().add_child(battle)','\tbattle.get_node("BattleManager").active_enemy_count_limit = 1\n\tget_root().add_child(battle)'));
const clips={};
function clip(names,frames,fps=10,loop=false){for(const name of names.split(' '))clips[name]={frames,fps,loop};}
clip('idle idle_ready',[0,1,0,1],4,true);clip('idle_prebattle',[35,0],3,false);
clip('walk walk_forward',[2,3,4,5],9,true);clip('walk_backward',[5,4,3,2],8,true);clip('dash',[6,7],12,true);
clip('jump jump_start',[8,9],10);clip('jump_air jump_up',[9],8);clip('jump_fall fall',[10],8);clip('jump_land land landing',[11,0],10);
clip('punch punch_1 light_attack',[12,13,14],12);clip('punch_2',[15,16,17],12);
clip('kick kick_1 kick_2 combo_finisher heavy_attack',[18,19,20],10);
clip('guard',[21],6,true);clip('crouch crouch_idle crouch_guard',[22],6,true);
clip('crouch_punch',[22,34,22],10);clip('crouch_kick crouch_kick_sweep crouch_sweep_kick',[22,23,22],10);
clip('damage damage_high damage_low damage_light guard_hit',[24,0],9);clip('damage_heavy knockback',[24,25],9);
clip('knockdown',[24,25,26],8);clip('down',[26],4);clip('ko defeat',[25,26],5);
clip('stand_up getup get_up',[26,27,22,0],8);clip('throw',[28,29],9);clip('throw_start',[28],8);clip('throw_hold',[28],8,true);clip('throw_release',[29],9);clip('grabbed',[24],6);clip('thrown',[25,26],8);
clip('jump_punch jump_punch_down',[9,30,10],10);clip('jump_kick',[9,31,10],10);
clip('special_startup',[32],6);clip('special special_attack rei_dragon_uppercut',[16],8);clip('special_recovery',[17],8);
const entries=Object.entries(clips).map(([k,v])=>`"${k}": {"frames": [${v.frames}], "fps": ${v.fps}.0, "loop": ${v.loop}}`).join(',\n');
write('assets/characters/enemy04/animations/rei_v1/motion_atlas.tres',`[gd_resource type="Resource" script_class="FighterMotionAtlas" load_steps=3 format=3]\n\n[ext_resource type="Script" path="res://scripts/data/fighter_motion_atlas.gd" id="1"]\n[ext_resource type="Texture2D" path="res://assets/characters/enemy04/animations/rei_v1/motion_atlas.png" id="2"]\n\n[resource]\nscript = ExtResource("1")\ntexture = ExtResource("2")\ncell_size = Vector2i(320, 300)\ncolumns = 6\nclips = {\n${entries}\n}\n`);
write('assets/characters/enemy04/animations/rei_v1/sources/.gdignore','\n');
const attacks=[
 {id:'rei_straight',name:'直突き',type:'punch',anim:'punch_1',startup:.18,active:.12,recovery:.24,damage:1,x:92,y:-145,w:64,h:44,next:['rei_uppercut','rei_roundhouse'],move:12,kx:180,ky:-40},
 {id:'rei_uppercut',name:'昇龍アッパー',type:'punch',anim:'punch_2',startup:.23,active:.15,recovery:.34,damage:1.3,x:65,y:-153,w:66,h:92,next:['rei_roundhouse'],move:22,kx:175,ky:-230},
 {id:'rei_roundhouse',name:'回し蹴り',type:'kick',anim:'kick_1',startup:.27,active:.15,recovery:.38,damage:1.1,x:105,y:-135,w:85,h:48,next:[],move:12,kx:270,ky:-80},
 {id:'rei_air_kick',name:'飛び蹴り',type:'kick',anim:'jump_kick',startup:.16,active:.18,recovery:.24,damage:1.05,x:98,y:-91,w:78,h:48,next:[],move:0,kx:220,ky:-75},
 {id:'rei_air_punch',name:'飛び込み突き',type:'punch',anim:'jump_punch_down',startup:.15,active:.15,recovery:.22,damage:1,x:84,y:-72,w:62,h:60,next:[],move:0,kx:170,ky:-40},
 {id:'rei_sweep',name:'下段回し蹴り',type:'kick',anim:'crouch_kick_sweep',startup:.24,active:.14,recovery:.34,damage:1,x:90,y:-30,w:95,h:38,next:[],move:0,kx:220,ky:-100}
];
for(const a of attacks) write(`data/attacks/${a.id}.tres`,`[gd_resource type="Resource" script_class="PlayerAttackData" load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://scripts/data/player_attack_data.gd" id="1"]\n\n[resource]\nscript = ExtResource("1")\nattack_id = "${a.id}"\ndisplay_name = "${a.name}"\nattack_type = "${a.type}"\nattack_category = "${a.id.includes('air')?'air':'normal'}"\nbase_damage = ${a.damage}\nstartup_time = ${a.startup}\nactive_time = ${a.active}\nrecovery_time = ${a.recovery}\ncombo_input_start = 0.08\ncombo_input_end = 0.36\nhitbox_size = Vector2(${a.w}, ${a.h})\nhitbox_offset = Vector2(${a.x}, ${a.y})\nforward_move_distance = ${a.move}.0\nforward_move_duration = 0.14\nknockback = Vector2(${a.kx}, ${a.ky})\nhitstop_time = 0.07\nhitstun_time = 0.26\nnext_attack_ids = Array[String]([${a.next.map(n=>`"${n}"`).join(', ')}])\nanimation_name = "${a.anim}"\n`);
let special=fs.readFileSync(path.join(root,'data/attacks/player1_special_thunder_drive.tres'),'utf8').replaceAll('player1_special_thunder_drive','rei_dragon_uppercut').replace('Thunder Drive','竜巻昇龍拳').replace('damage_multiplier = 2.8','damage_multiplier = 2.4').replace('startup_time = 0.25','startup_time = 0.42').replace('Vector2(120, 90)','Vector2(86, 130)').replace('Vector2(75, -55)','Vector2(65, -145)').replace('move_distance = 90.0','move_distance = 42.0').replace('Vector2(360, -96)','Vector2(240, -240)').replace('special_thunder_drive','rei_dragon_uppercut').replace('player1_special_warning','rei_charge').replace('player1_thunder_drive','rei_uppercut');
write('data/attacks/rei_dragon_uppercut.tres',special);
edit('data/enemies/enemy_04_throw.tres',s=>{
  let refs='[ext_resource type="Resource" path="res://assets/characters/enemy04/animations/rei_v1/motion_atlas.tres" id="9_motion"]\n';
  for(const a of [...attacks,{id:'rei_dragon_uppercut'}])refs+=`[ext_resource type="Resource" path="res://data/attacks/${a.id}.tres" id="${a.id}"]\n`;
  return s.replace('load_steps=9','load_steps=17').replace('[resource]',refs+'\n[resource]').replace('enemy_order = 4','enemy_order = 2').replace('sprite_sheet = ExtResource("7_sheet")','sprite_sheet = ExtResource("7_sheet")\nmotion_atlas = ExtResource("9_motion")\nsprite_sheet_format = &"authored_atlas"\nsprite_body_height_px = 209.0\ncharacter_height_cm = 192.0\nbattle_sprite_height = 174.78516\nvisual_scale_adjustment = 1.05\nattack_sequence = Array[Resource]([ExtResource("rei_straight"), ExtResource("rei_uppercut"), ExtResource("rei_roundhouse")])\nmax_attack_chain_count = 3\nair_kick_attack = ExtResource("rei_air_kick")\nair_punch_down_attack = ExtResource("rei_air_punch")\ncrouch_kick_sweep_attack = ExtResource("rei_sweep")\nspecial_attack_sequence = Array[Resource]([ExtResource("rei_dragon_uppercut")])\nspecial_ai_use_chance = 0.45').replace('遠めの打撃と飛び込みで主導権を取る。間合い管理が重要。','長い突きから昇龍アッパー、回し蹴りへ。紫の溜めが見えたら距離を取り、技後の隙を狙え。');
});
edit('data/enemy_ai/enemy_04_throw_ai.tres',s=>s.replace('punch_weight = 0.28','punch_weight = 0.48').replace('throw_weight = 0.32','throw_weight = 0.08').replace('preferred_distance_min = 55.0','preferred_distance_min = 82.0').replace('preferred_distance_max = 69.0','preferred_distance_max = 110.0').replace('preferred_distance = 64.0','preferred_distance = 96.0').replace('attack_distance = 66.0','attack_distance = 115.0').replace('retreat_distance = 34.0','retreat_distance = 56.0').replace('second_hit_probability = 0.36','second_hit_probability = 0.60').replace('third_hit_probability = 0.16','third_hit_probability = 0.38').replace('combo_rate = 0.36','combo_rate = 0.58'));
edit('scripts/player/player_combo_movement.gd',s=>s.replace('\tif not contact_frames.has(current_attack_id) or is_crouching:','\tif definition != null and String(definition.get("fighter_id")) == "enemy_04_rei_kageyama":\n\t\tfor id in ["rei_straight", "rei_uppercut", "rei_roundhouse", "rei_air_kick", "rei_air_punch", "rei_sweep"]:\n\t\t\tcontact_frames[id] = Vector2i(1, 1)\n\tif not contact_frames.has(current_attack_id) or (is_crouching and current_attack_id != "rei_sweep"):'));
// A reused enemy node must not carry Rei's authored combo into the next fighter.
edit('scripts/player/player_fighter_definition_movement.gd',s=>s.replace('if has_method("apply_attack_sequence") and not fighter_definition.attack_sequence.is_empty():','if has_method("apply_attack_sequence"):').replace('else fighter_definition.attack_sequence.size()','else maxi(1, fighter_definition.attack_sequence.size())'));
console.log('Rei Stage 2 resources configured');