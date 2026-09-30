const sharp = require('sharp');
const path = require('path');

async function pack(character) {
  const root = path.resolve(__dirname, `../godot/assets/characters/${character}/animations/${character === 'enemy03' ? 'masato_v1' : 'leon_v1'}`);
  const input = path.join(root, 'sources/generated_atlas.png');
  const { data, info } = await sharp(input).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const layers = [];
  const cols = 6, rows = 6, cell = 320;
  for (let row = 0; row < rows; row++) for (let col = 0; col < cols; col++) {
    const left = Math.round(col * info.width / cols), right = Math.round((col + 1) * info.width / cols);
    const top = Math.round(row * info.height / rows), bottom = Math.round((row + 1) * info.height / rows);
    const width = right - left, height = bottom - top;
    const pixels = Buffer.alloc(width * height * 4);
    for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
      const source = ((top + y) * info.width + left + x) * 4, dest = (y * width + x) * 4;
      const r = data[source], g = data[source + 1], b = data[source + 2];
      const max = Math.max(r, g, b), min = Math.min(r, g, b), sat = max ? (max - min) / max : 0;
      const chromaFringe = character === 'enemy03' && sat > 0.42 && max > 90 && (
        (r > g * 1.4 && r > b * 1.3) || (g > r * 1.28 && g > b * 1.2) || (b > r * 1.22 && b > g * 1.15)
      );
      pixels[dest] = r; pixels[dest + 1] = g; pixels[dest + 2] = b; pixels[dest + 3] = chromaFringe ? 0 : data[source + 3];
    }
    const seen = new Uint8Array(width * height);
    for (let p = 0; p < width * height; p++) {
      if (seen[p] || pixels[p * 4 + 3] < 32) continue;
      const todo = [p], component = []; seen[p] = 1;
      let x0 = width, y0 = height, x1 = 0, y1 = 0;
      for (let i = 0; i < todo.length; i++) {
        const q = todo[i], x = q % width, y = Math.floor(q / width);
        component.push(q); x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y);
        for (const n of [x > 0 ? q - 1 : -1, x + 1 < width ? q + 1 : -1, y > 0 ? q - width : -1, y + 1 < height ? q + width : -1]) {
          if (n >= 0 && !seen[n] && pixels[n * 4 + 3] >= 32) { seen[n] = 1; todo.push(n); }
        }
      }
      if ((y1 - y0 + 1) <= 12 && (x1 - x0 + 1) >= Math.max(70, Math.floor(width * 0.34))) {
        for (const q of component) pixels[q * 4 + 3] = 0;
      }
    }
    const fitted = await sharp(pixels, { raw: { width, height, channels: 4 } })
      .resize(cell, cell, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 }, kernel: 'lanczos3' })
      .png().toBuffer();
    layers.push({ input: fitted, left: col * cell, top: row * cell });
  }
  await sharp({ create: { width: cell * cols, height: cell * rows, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite(layers).png().toFile(path.join(root, 'motion_atlas.png'));
  console.log(`${character.toUpperCase()}_ATLAS_PACKED frames=36 cell=${cell}x${cell} chroma_fringe_removed=${character === 'enemy03'}`);
}

async function main() {
  await Promise.all([pack('enemy03'), pack('enemy08')]);
  for (const [src, dest] of [
    ['stage_07_hideout_entrance_source.png', 'stage_07_hideout_entrance.webp'],
    ['stage_08_hideout_boss_room_source.png', 'stage_08_hideout_boss_room.webp'],
  ]) await sharp(path.resolve(__dirname, '../godot/assets/backgrounds', src)).resize(1504, 846, { fit: 'cover' }).webp({ quality: 90 }).toFile(path.resolve(__dirname, '../godot/assets/backgrounds', dest));
}
main().catch(error => { console.error(error); process.exitCode = 1; });
