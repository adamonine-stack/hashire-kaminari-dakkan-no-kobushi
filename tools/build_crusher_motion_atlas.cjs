// Packs individually inspected source poses without per-pose scaling.
// The production FighterMotionAtlas references these fixed-scale cells.
const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '../godot/assets/characters/enemy01/animations/crusher_v1');
const order = [
  'idle_master', 'walk_near_leg_back', 'walk_transition_a',
  'walk_near_leg_front', 'walk_transition_b', 'punch_startup_candidate',
  'punch_contact_revised', 'dash_near_leg_back', 'dash_near_leg_front',
  'jump_takeoff', 'jump_ascent', 'jump_descent', 'jump_landing',
  'punch_jab', 'kick_contact', 'guard', 'crouch', 'damage',
  'knockdown', 'ko', 'getup', 'crouch_punch', 'crouch_sweep',
  'throw_grab', 'throw_lift',
];
const cell = { width: 400, height: 280 };
const columns = 4;
const scale = 0.2; // fixed physical pixel scale, including the wide KO source
const baseline = 260;

async function measure(pathname) {
  const { data, info } = await sharp(pathname).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  let bottom = -1;
  for (let y = 0; y < info.height; y++) {
    for (let x = 0; x < info.width; x++) {
      if (data[(y * info.width + x) * info.channels + 3] >= 128) bottom = y;
    }
  }
  if (bottom < 0) throw new Error(`Empty sprite: ${pathname}`);
  return { width: info.width, height: info.height, bottom };
}

async function run() {
  const layers = [];
  const manifest = [];
  for (let i = 0; i < order.length; i++) {
    const name = order[i];
    const pathname = path.join(root, 'sources', `${name}.png`);
    const { width, height, bottom } = await measure(pathname);
    // Discard only transparent source padding below the visible body.
    const trimmedHeight = Math.min(height, bottom + 20);
    const scaledWidth = Math.round(width * scale);
    const scaledHeight = Math.round(trimmedHeight * scale);
    if (scaledWidth > cell.width || scaledHeight > cell.height) throw new Error(`Cell overflow: ${name}`);
    const x = Math.round((cell.width - scaledWidth) / 2);
    const y = baseline - Math.round(bottom * scale);
    if (y < 0 || y + scaledHeight > cell.height) throw new Error(`Vertical overflow: ${name}`);
    layers.push({
      input: await sharp(pathname).extract({ left: 0, top: 0, width, height: trimmedHeight })
        .resize(scaledWidth, scaledHeight, { kernel: 'nearest' }).png().toBuffer(),
      left: i % columns * cell.width + x,
      top: Math.floor(i / columns) * cell.height + y,
    });
    manifest.push({ index: i, source: `sources/${name}.png`, x, y, scale, baseline });
  }
  const height = Math.ceil(order.length / columns) * cell.height;
  await sharp({ create: { width: columns * cell.width, height, channels: 4,
    background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite(layers).png().toFile(path.join(root, 'motion_atlas.png'));
  fs.writeFileSync(path.join(root, 'packing_manifest.json'),
    JSON.stringify({ cell, columns, scale, frames: manifest }, null, 2) + '\n');
  console.log(`crusher atlas: ${order.length} cells, ${columns * cell.width}x${height}`);
}
run().catch(error => { console.error(error); process.exitCode = 1; });
