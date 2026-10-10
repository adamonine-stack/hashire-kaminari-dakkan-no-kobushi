"""Configure the requested ten controls without changing fighter identity or specials."""
from pathlib import Path
from PIL import Image
import json,re

ROOT=Path(__file__).resolve().parents[1]
INV=ROOT/'audit_evidence/basic_moves_20261010/inventory'
actors=json.loads((INV/'inventory.json').read_text(encoding='utf-8'))
SLUGS=['akky','gou','seiya','crusher','shadow','masato','rei','cross','rio','teki','leon','dark_seiya']
KEYS=['neutral_punch','forward_punch','down_punch','back_punch','up_punch','neutral_kick','forward_kick','down_kick','back_kick','up_kick']
PACE=[1.0,1.15,.82,1.25,.80,1.12,1.08,.96,.94,1.07,.88,.9]
STEPS=[42,34,48,30,52,32,46,38,46,42,50,48]
TITLES=['雷','剛','閃','鉄塊','影','静','昇龍','無影','疾駆','封','黒翼','冥']
SUFFIXES=['ジャブ','踏み込み拳','低突き','かち上げ','飛び拳','前蹴り','速蹴り','足払い','押し蹴り','飛び蹴り']
TIMES=[(.06,.07,.15),(.08,.07,.18),(.09,.07,.17),(.12,.08,.22),(.13,.09,.18),(.15,.10,.31),(.11,.08,.30),(.16,.10,.35),(.16,.10,.34),(.16,.11,.33)]
MULT=[.75,.9,.8,.85,.85,1.1,1.0,1.05,1.0,1.15]

def remove_property(s,key):
    return re.sub(r'^'+key+r' = \{.*?^\}\s*\n?', '',s,flags=re.M|re.S) if re.search(r'^'+key+r' = \{\n',s,re.M) else re.sub(r'^'+key+r' = .*\n?','',s,flags=re.M)

for n,(actor,slug) in enumerate(zip(actors,SLUGS)):
    definition=ROOT/('godot/data/'+actor['path']+'.tres')
    s=definition.read_text(encoding='utf-8')
    # Replace the prior grounded-up experiment with the requested jumping control.
    removed=len(re.findall(r'^\[ext_resource .* id="original_up_[^"]+"\]\n',s,re.M))
    if removed:
        s=re.sub(r'^\[ext_resource .* id="original_up_[^"]+"\]\n','',s,flags=re.M)
        s=re.sub(r', ExtResource\("original_up_[^"]+"\)','',s)
        s=re.sub(r'load_steps=(\d+)',lambda m:f'load_steps={int(m[1])-removed}',s,count=1)
    s=remove_property(s,'original_motion_sequences')
    s=remove_property(s,'basic_move_paths')
    added=[]
    source_actor=actors[2] if slug=='dark_seiya' else actor
    source_prefix='seiya' if slug=='dark_seiya' else slug
    generated=slug not in ['akky','gou','seiya','dark_seiya']
    manifest=None
    if generated:
        atlas=f'res://assets/characters/basic_moves_v2/{slug}/motion_atlas.tres'
        added.append(atlas)
        if (ROOT/f'godot/assets/characters/basic_moves_v2/{slug}/supplement_atlas.tres').exists():
            added.append(f'res://assets/characters/basic_moves_v2/{slug}/supplement_atlas.tres')
        manifest=json.loads((ROOT/f'godot/assets/characters/basic_moves_v2/{slug}/packing_manifest.json').read_text(encoding='utf-8'))
    elif slug=='dark_seiya':
        for key in ['forward_punch','back_punch','forward_kick','back_kick','air_punch','air_kick']:
            png=source_actor['clips']['seiya_'+key]['source']
            added.append(png.rsplit('/',1)[0]+'/motion_atlas.tres')
    if added:
        match=re.search(r'^extra_motion_atlas_paths = Array\[String\]\(\[(.*)\]\)',s,re.M)
        if match:
            existing=json.loads('['+match[1]+']')
            s=re.sub(r'^extra_motion_atlas_paths = .*$', 'extra_motion_atlas_paths = Array[String]('+json.dumps(list(dict.fromkeys(existing+added)))+')',s,flags=re.M)
        else:s+='\nextra_motion_atlas_paths = Array[String]('+json.dumps(added)+')\n'
    paths={};recipes={};details=[]
    for i,key in enumerate(KEYS):
        direction,kind=key.split('_');is_air=direction=='up';is_low=direction=='down'
        if generated and key in manifest['contacts']:
            source='basic_source_'+key;count=4;contact=2
            offset=manifest['contacts'][key]
        else:
            source={'neutral_punch':'punch_1','neutral_kick':'kick_1','down_punch':'crouch_punch','down_kick':'crouch_kick_sweep','up_punch':'jump_punch','up_kick':'jump_kick'}.get(key,source_prefix+'_'+key)
            air_source=source_prefix+'_air_'+kind
            if is_air and air_source in source_actor['clips']:source=air_source
            clip=source_actor['clips'][source];count=clip['count'];contact=clip['contact_frame']
            # Use the measured fist/foot region relative to the fighter's stable floor.
            image=Image.open(INV/(source_actor['id']+'__'+source+'.png')).convert('RGBA')
            box=image.getchannel('A').getbbox();margin=clip['margin'];baseline=actor['idle_rect'][1]+actor['idle_rect'][3]
            world=actor['height']*(actor['height_cm']/175)*actor['scale_adjustment']/actor['body_px']
            x=box[2]-6
            y=box[1]+(box[3]-box[1])*(.3 if kind=='punch' else .4)
            if is_low:y=box[1]+(box[3]-box[1])*(.38 if kind=='punch' else .78)
            if direction=='back' and kind=='punch':
                # The raised fist is above the head; full silhouette center includes
                # the rear foot and can incorrectly place the attack behind the body.
                top=image.getchannel('A').crop((0,box[1],image.width,box[1]+max(8,round((box[3]-box[1])*.07)))).getbbox()
                x=(top[0]+top[2])/2;y=box[1]+8
            if is_air:y=box[1]+(box[3]-box[1])*(.48 if kind=='punch' else .52)
            offset=[round((x+margin[0]-actor['cell'][0]/2)*world*actor['width_scale'],2),round((y+margin[1]-baseline)*world,2)]
        # Limit preparation to two meaningful cells, retain the real contact cell.
        indices=list(range(contact))+[contact]+list(range(contact+1,count))
        if contact>2:indices=[0,contact-1]+indices[contact:];contact=2
        cells=[[source,index,1.0] for index in indices]+[['idle',0,1.0]]
        if is_low:cells[-1]=['crouch',0,1.0]
        if is_air:cells[-1]=['jump_air',0,1.0]
        recipes['basic_'+key]={'fps':12.0,'cells':cells}
        folder=ROOT/f'godot/data/basic_moves/{slug}';folder.mkdir(parents=True,exist_ok=True)
        path=f'res://data/basic_moves/{slug}/{key}.tres';paths[key]=path
        startup,active,recovery=TIMES[i];startup=round(startup*PACE[n],4);recovery=round(recovery*PACE[n],4)
        tags={'neutral_punch':['close'],'neutral_kick':['middle'],'forward_punch':['approach','punish'],'down_punch':['close','evade'],'back_punch':['anti_air'],'up_punch':['air'],'forward_kick':['middle','punish'],'down_kick':['low'],'back_kick':['evade'],'up_kick':['air']}[key]
        # Existing neutral jab chains remain available through their original IDs.
        next_ids=[]
        if key=='neutral_punch':
            first=re.search(r'path="res://data/attacks/([^\"]*punch_1\.tres)"',s)
            if first:
                old=(ROOT/'godot/data/attacks'/first[1]).read_text(encoding='utf-8')
                m=re.search(r'^next_attack_ids = (.*)$',old,re.M)
                if m:
                    next_ids=re.findall(r'"([^"]+)"',m[1])
        values={
            'attack_id':f'basic_{slug}_{key}','display_name':TITLES[n]+SUFFIXES[i],
            'attack_type':kind,'attack_category':'basic_air' if is_air else 'basic',
            'command_direction':'' if direction=='neutral' else direction,'command_priority':100,
            'ground_only':not is_air,'airborne_only':False,'jump_on_start':is_air,'crouch_on_start':is_low,
            'base_damage':MULT[i],'startup_time':startup,'active_time':active,'recovery_time':recovery,
            'hitbox_size':('Vector2(48, 80)' if key=='back_punch' else ('Vector2(46, 32)' if kind=='kick' else 'Vector2(34, 30)')),
            'hitbox_offset':f'Vector2({offset[0]}, {offset[1]})',
            'forward_move_distance':STEPS[n] if key=='forward_punch' else 0,
            'forward_move_duration':startup if key=='forward_punch' else 0,
            'knockback':'Vector2(90, 0)' if key=='back_kick' else ('Vector2(135, 0)' if kind=='kick' else 'Vector2(65, 0)'),
            'launch_velocity':'Vector2(35, -220)' if key=='back_punch' else 'Vector2(0, 0)',
            'hit_reaction':'launch_hit' if key=='back_punch' else ('damage_low' if is_low else 'damage_light'),
            'knockdown':key=='down_kick','hitstop_time':.04 if kind=='punch' else .06,
            'hitstun_time':.24 if kind=='punch' else .30,'is_guardable':True,
            'attack_height':'low' if is_low else ('overhead' if is_air else 'middle'),
            'guard_knockback':'Vector2(35, 0)','guard_hit_time':.13 if kind=='punch' else .17,
            'hurtbox_height_scale':.55 if is_low else 1.0,'hurtbox_start':0.0,
            'hurtbox_end':round(startup+active+recovery,4),
            'landing_recovery':.08 if key=='up_punch' else (.16 if key=='up_kick' else 0.0),
            'animation_name':'basic_'+key,'contact_start_frame':contact,'contact_end_frame':contact,
            'can_cancel_on_hit':bool(next_ids),'can_cancel_on_whiff':False,
            'combo_input_start':startup+active,'combo_input_end':startup+active+recovery,
            'ai_distance_min':0.0,'ai_distance_max':max(90,round(abs(offset[0])+45+(STEPS[n] if key=='forward_punch' else 0))),
            'next_attack_ids':next_ids,'ai_tags':tags
        }
        lines=['[gd_resource type="Resource" script_class="PlayerAttackData" load_steps=2 format=3]','[ext_resource type="Script" path="res://scripts/data/player_attack_data.gd" id="1"]','[resource]','script = ExtResource("1")']
        for prop,val in values.items():
            if prop in ['hitbox_size','hitbox_offset','knockback','launch_velocity','guard_knockback']:encoded=val
            elif prop=='hit_reaction':encoded='&'+json.dumps(val)
            elif isinstance(val,list):encoded='Array[String]('+json.dumps(val)+')'
            else:encoded=json.dumps(val,ensure_ascii=False)
            lines.append(prop+' = '+encoded)
        (folder/(key+'.tres')).write_text('\n'.join(lines)+'\n',encoding='utf-8')
        details.append({'key':key,'source':source,'contact':contact,'offset':offset,'startup':startup,'recovery':recovery})
    s+='\nbasic_move_paths = '+json.dumps(paths,ensure_ascii=False)+'\noriginal_motion_sequences = '+json.dumps(recipes,ensure_ascii=False)+'\n'
    definition.write_text(s,encoding='utf-8')
    (ROOT/f'godot/data/basic_moves/{slug}/manifest.json').write_text(json.dumps({'actor':actor['id'],'moves':details},ensure_ascii=False,indent=2),encoding='utf-8')
    if actor['path'].startswith('enemies/'):
        ai=re.search(r'path="(res://data/enemy_ai/[^\"]+)"',s)
        if ai:
            p=ROOT/'godot'/ai[1].removeprefix('res://');text=p.read_text(encoding='utf-8')
            if 'use_situation_moves =' in text:text=re.sub(r'use_situation_moves = .*','use_situation_moves = true',text)
            else:text+='\nuse_situation_moves = true\n'
            p.write_text(text,encoding='utf-8')
    print(slug,'10 moves configured')
