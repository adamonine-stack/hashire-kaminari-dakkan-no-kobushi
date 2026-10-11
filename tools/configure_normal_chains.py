"""Install per-fighter normal chains and move the launcher to down+punch.

Generated art is packed separately; gameplay resources remain reviewable.
"""
from pathlib import Path
import json, re, subprocess

ROOT = Path(__file__).resolve().parents[1]
BASELINE_REF = 'bdc7ffd'  # Original basic-move resources before normal-chain migration.
ACTORS = json.loads((ROOT/'audit_evidence/basic_moves_20261010/inventory/inventory.json').read_text(encoding='utf-8'))
SLUGS = ['akky','gou','seiya','crusher','shadow','masato','rei','cross','rio','teki','leon','dark_seiya']
STYLES = ['balance','power','speed','power','speed','power','balance','balance','speed','balance','speed','speed']
SOURCES = {
    'akky': {'punch':[('punch_1',[0,1,2,3]),('punch_2',[0,1,2,3]),('crouch_punch',[0,1,2,3])], 'kick':[('kick_1',[0,1,2,3,4]),('kick_2',[0,1,2,3,4])]},
    'gou': {'punch':[('punch_1',[0,1,2,4,5]),('gou_forward_punch',[0,1,2,3,4])], 'kick':[('kick_1',[0,1,3,4,5]),('gou_forward_kick',[0,1,2,3,4])]},
    'seiya': {'punch':[('punch_1',[0,1,3,4,5]),('seiya_forward_punch',[0,1,2,3,4]),('crouch_punch',[0,1,2,4,5]),('punch_2',[0,1,3,4,5])], 'kick':[('kick_1',[0,1,3,4,5]),('seiya_forward_kick',[0,1,2,3,4]),('seiya_back_kick',[0,1,2,3,4])]},
    'crusher': {'punch':[('punch_1',[0,0,1,2]),('punch_2',[0,0,1,2,3])], 'kick':[('kick_1',[0,0,1,2]),('crusher_forward_kick',[0,1,2,3,4])]},
    'rei': {'punch':[('punch_1',[0,0,1,2]),('basic_source_forward_punch',[0,1,2,3]),('crouch_punch',[0,0,1,2])], 'kick':[('kick_1',[0,0,1,2]),('basic_source_forward_kick',[0,1,2,3])]},
    'teki': {'punch':[('punch_1',[0,0,1,2]),('basic_source_forward_punch',[0,1,2,3]),('crouch_punch',[0,0,1,2])], 'kick':[('kick_1',[0,0,1,2]),('basic_source_forward_kick',[0,1,2,3])]},
    'cross': {'punch':[('punch_1',[0,0,1,2]),('basic_source_forward_punch',[0,1,2,3]),('crouch_punch',[0,0,1,2])], 'kick':[('kick_1',[0,0,1,2]),('basic_source_forward_kick',[0,1,2,3])]},
    'shadow': {'punch':[('punch_1',[0,0,1,2]),('punch_2',[0,0,1,2]),('basic_source_forward_punch',[0,1,2,3]),('crouch_punch',[0,1,2,3])], 'kick':[('basic_source_neutral_kick',[0,1,2,3]),('basic_source_forward_kick',[0,1,2,3]),('basic_source_back_kick',[0,1,2,3])]}
}

def baseline(path):
    return subprocess.check_output(['git','show',BASELINE_REF+':'+path.relative_to(ROOT).as_posix()],cwd=ROOT).decode('utf-8')

def prop(text, key, value):
    line = key+' = '+value
    if re.search(r'^'+key+r' = .*$', text, re.M):
        return re.sub(r'^'+key+r' = .*$', lambda _: line, text, flags=re.M)
    return text+'\n'+line+'\n'

SOURCES['rio']={'punch':[('punch_1',[0,0,1,2]),('punch_2',[0,0,1,2]),('basic_source_forward_punch',[0,1,2,3]),('crouch_punch',[0,0,1,2])], 'kick':[('kick_1',[0,0,1,2]),('kick_2',[0,0,1,2]),('basic_source_forward_kick',[0,1,2,3])]}
SOURCES['masato']={'punch':[('punch_1',[0,0,1,2]),('punch_2',[0,0,1,2])], 'kick':[('kick_1',[0,0,1,2]),('basic_source_forward_kick',[0,1,2,3])]}
SOURCES['leon']={'punch':[('punch_1',[0,0,1,2]),('punch_2',[0,0,1,2]),('crouch_punch',[0,0,1,2]),('basic_source_forward_punch',[0,1,2,3])], 'kick':[('kick_1',[0,0,1,2]),('basic_source_forward_kick',[0,1,2,3]),('basic_source_back_kick',[0,1,2,3])]}
SOURCES['dark_seiya']=SOURCES['seiya']
for index in [0,1,2,3,6,9,7,4,8,5,10,11]:
    actor,slug,style=ACTORS[index],SLUGS[index],STYLES[index]
    folder = ROOT/f'godot/data/basic_moves/{slug}'
    definition = ROOT/('godot/data/'+actor['path']+'.tres')
    text = baseline(definition)
    paths = json.loads(re.search(r'^basic_move_paths = (.*)$', text, re.M)[1])
    punches, kicks = {'balance':(3,2),'speed':(4,3),'power':(2,2)}[style]
    limit = max(punches,3)  # Keep P,P,K mixed routes on power fighters too.
    recipes=json.loads(re.search(r'^original_motion_sequences = (.*)$',text,re.M)[1])
    for kind, count in [('punch',punches),('kick',kicks)]:
        for rank in range(1,limit+1):
            source = baseline(folder/f'neutral_{kind}.tres')
            move_id = f'chain_{slug}_{kind}_{rank}'
            next_ids = []
            for target, target_count in [('punch',punches),('kick',kicks)]:
                if rank < limit and (target != kind or rank < count):
                    next_ids.append(f'chain_{slug}_{target}_{rank+1}')
            values = {
                'attack_id':json.dumps(move_id), 'attack_category':'"normal_chain"',
                'command_direction':'""',
                'animation_name':json.dumps(f'normal_{kind}_{min(rank,count)}'),
                'next_attack_ids':'Array[String]('+json.dumps(next_ids)+')',
                'combo_route_hit_limit':str(limit), 'command_priority':'100',
                'startup_time':str((.065 if kind=='punch' else .095)*(1.10 if style=='power' else .9 if style=='speed' else 1)),
                'active_time':'0.07', 'recovery_time':'0.24',
                'combo_input_start':'0.0', 'combo_input_end':'0.40',
                'forward_move_distance':'10.0', 'forward_move_duration':'0.12',
                'knockback':'Vector2(18, 0)', 'launch_velocity':'Vector2(0, 0)',
                'knockdown':'false', 'can_cancel_on_hit':'true',
                'can_cancel_on_whiff':'false', 'contact_start_frame':'2', 'contact_end_frame':'2',
            }
            clip,indices=SOURCES[slug][kind][min(rank,count)-1]
            geometry_key='down_punch' if clip=='crouch_punch' else 'forward_'+kind if 'forward_' in clip else 'back_'+kind if 'back_' in clip else 'neutral_'+kind
            if slug=='shadow' and clip=='crouch_punch': geometry_key='neutral_punch'
            geometry=baseline(folder/(geometry_key+'.tres'))
            for key in ['hitbox_offset','hitbox_size']:
                values[key]=re.search(r'^'+key+r' = (.*)$',geometry,re.M)[1]
            if index in [6,9,7,4,8,5,10,11]:
                # Keep authored outer reach, but include the extending forearm /
                # lower leg so a close confirmed target is not skipped by a
                # longer followup whose fist/foot passes beyond its hurtbox.
                ox,oy=map(float,re.search(r'Vector2\(([^,]+),\s*([^\)]+)\)',values['hitbox_offset']).groups())
                sx,sy=map(float,re.search(r'Vector2\(([^,]+),\s*([^\)]+)\)',values['hitbox_size']).groups())
                outer=ox+sx/2
                inner=min(22.0,ox-sx/2)
                values['hitbox_offset']=f'Vector2({(inner+outer)/2}, {oy})'
                values['hitbox_size']=f'Vector2({outer-inner}, {sy})'
            recipes[f'normal_{kind}_{min(rank,count)}']={'fps':12.0,'cells':[[clip,index,1.0] for index in indices]+[['idle',0,1.0]]}
            if clip=='crouch_punch' and slug!='shadow':
                values.update(crouch_on_start='true',hurtbox_height_scale='0.55',hurtbox_start='0.0',hurtbox_end='0.45',attack_height='"low"',hit_reaction='&"damage_low"')
            for key,value in values.items(): source=prop(source,key,value)
            (folder/f'normal_{kind}_{rank}.tres').write_text(source,encoding='utf-8')
        paths[f'neutral_{kind}']=f'res://data/basic_moves/{slug}/normal_{kind}_1.tres'
        # Path-backed followups must also be registered before combat starts.
        for rank in range(2,limit+1):
            paths[f'chain_{kind}_{rank}']=f'res://data/basic_moves/{slug}/normal_{kind}_{rank}.tres'
    down = folder/'down_punch.tres'
    back = folder/'back_punch.tres'
    launcher = baseline(back)
    launcher=prop(launcher,'attack_id',json.dumps(f'basic_{slug}_down_punch'))
    launcher=prop(launcher,'command_direction','"down"')
    launcher=prop(launcher,'display_name','"打ち上げ"')
    launcher=prop(launcher,'animation_name','"basic_down_launcher"')
    launcher=prop(launcher,'hitbox_offset','Vector2(70, -90)')
    launcher=prop(launcher,'hitbox_size','Vector2(65, 110)')
    down.write_text(launcher,encoding='utf-8')
    overhead=prop(launcher,'attack_id',json.dumps(f'basic_{slug}_back_punch'))
    for key,value in {'command_direction':'"back"','display_name':'"打ち下ろし"',
                      'animation_name':'"normal_overhead"','launch_velocity':'Vector2(0, 0)',
                      'hit_reaction':'&"damage_low"','attack_height':'"overhead"',
                      'hitbox_size':'Vector2(55, 65)','hitbox_offset':'Vector2(90, -65)',
                      'ai_tags':'Array[String](["close", "overhead"])'}.items(): overhead=prop(overhead,key,value)
    back.write_text(overhead,encoding='utf-8')
    # Copy the former launcher recipe under its new control name.
    recipes['basic_down_launcher']=recipes['basic_back_punch']
    recipes['normal_overhead']={'fps':12.0,'cells':[['idle',0,1.0],['overhead_windup',0,1.0],['overhead_contact',0,1.0],['overhead_contact',0,1.0],['idle',0,1.0]]}
    extra=re.search(r'^extra_motion_atlas_paths = Array\[String\]\((.*)\)$',text,re.M)
    extras=json.loads(extra[1]) if extra else []
    extras.append(f'res://assets/characters/overhead_v1/{slug}/motion_atlas.tres')
    if slug=='akky':
        extras.append('res://assets/characters/overhead_v1/akky_cross/motion_atlas.tres')
        recipes['normal_punch_2']={'fps':12.0,'cells':[['punch_1',0,1.0],['punch_1',1,1.0],['cross_contact',0,1.0],['punch_1',3,1.0],['idle',0,1.0]]}
    if slug in ['rio','masato','leon','dark_seiya']:
        clip,indices=SOURCES[slug]['punch'][1]
        # Return to the official guarded stance; an unrelated old punch's
        # windup can use the opposite arm and must not precede this contact.
        recipes['normal_punch_2']={'fps':12.0,'cells':[['idle',0,1.0],['idle',0,1.0],['authored_normal_contact',0,1.0],['idle',0,1.0],['idle',0,1.0]]}
    text=prop(text,'extra_motion_atlas_paths','Array[String]('+json.dumps(extras)+')')
    text=prop(text,'original_motion_sequences',json.dumps(recipes))
    text=prop(text,'basic_move_paths',json.dumps(paths))
    definition.write_text(text,encoding='utf-8')
    print(slug,style,punches,kicks)
