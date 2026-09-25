// Validate every authored cell against the saved packing manifest.
const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '../godot/assets/characters/enemy01/animations/crusher_v1');
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'packing_manifest.json'), 'utf8'));
const cell = manifest.cell;
const failures = [];

async function run() {
  const { data, info } = await sharp(path.join(root, 'motion_atlas.png'))
    .ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  if (info.width !== manifest.columns * cell.width ||
      info.height !== Math.ceil(manifest.frames.length / manifest.columns) * cell.height)
    failures.push(`Atlas dimensions ${info.width}x${info.height} mismatch manifest`);
  const rows = [];
  for (const frame of manifest.frames) {
    const { index, source, baseline } = frame;
    const ox = index % manifest.columns * cell.width;
    const oy = Math.floor(index / manifest.columns) * cell.height;
    let left = cell.width, right = -1, top = cell.height, bottom = -1;
    for (let y = 0; y < cell.height; y++) {
      for (let x = 0; x < cell.width; x++) {
        const a = data[((oy + y) * info.width + ox + x) * info.channels + 3];
        if (a < 128) continue;
        left = Math.min(x, left); right = Math.max(x, right);
        top = Math.min(y, top); bottom = Math.max(y, bottom);
      }
    }
    const name = path.basename(source, '.png');
    if (right < 0) failures.push(`${name}: empty cell ${index}`);
    if (left < 2 || right > cell.width - 3 || top < 2 || bottom > cell.height - 3)
      failures.push(`${name}: content clipped or overlaps a cell boundary (${left},${top})–(${right},${bottom})`);
    if (Math.abs(bottom - baseline) > 2)
      failures.push(`${name}: foot/body baseline ${bottom} differs from ${baseline}`);
    rows.push({ index, name, left, top, right, bottom, height: bottom - top + 1 });
  }
  for (const [name, ids] of Object.entries({
    walk: [1, 2, 3, 4], dash: [7, 8], strong_punch: [5, 6],
  })) {
    const heights = ids.map(i => rows[i].height);
    const spread = Math.max(...heights) - Math.min(...heights);
    if (spread > (name === 'dash' ? 12 : 8)) failures.push(`${name}: height spread ${spread}px`);
  }
  console.table(rows);
  if (failures.length) {
    console.error(`CRUSHER_ATLAS_FAILED (${failures.length}):\n${failures.join('\n')}`);
    process.exitCode = 1;
  } else console.log(`CRUSHER_ATLAS_OK frames=${rows.length} baseline=${manifest.frames[0].baseline}`);
}
run().catch(e => { console.error(e); process.exitCode = 1; });
