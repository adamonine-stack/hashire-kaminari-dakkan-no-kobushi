# DEV045 Character Assets

This folder stores the official character art adopted for DEV045.

Each character folder uses the same replaceable structure:

- `portrait.png`
- `battle.png`
- `icon.png`
- `sprite_sheet.png`
- `shadow.png`
- `skins/`
- `effects/`

Current folders:

- `player01` - 主人公1 / アッキー
- `player02` - 主人公2 / ごう
- `player03` - 主人公3 / せいや
- `enemy01` - クラッシャー
- `enemy02` - シャドウボクサー
- `enemy03` - マサト・タカハシ
- `enemy04` - レイ・カゲヤマ
- `enemy05` - シャドウボクサー（保存済みID互換のためデータIDは維持）
- `enemy06` - リオ・フリック・ガルシア
- `enemy07` - テキ・ファイター
- `enemy08` - レオン・クロウ

The current PNGs are derived from the confirmed design sheets shared for DEV045. When production-cut animation sprite sheets are supplied, replace the files in each folder without changing scene code. Fighter resources reference these files through `FighterDefinition`.

Stage 5 and Stage 6 use authored fixed-cell motion atlases under each character's `animations/` folder. Their clips share one source-cell size per fighter, and the visual controller applies one scale for the whole atlas so attack, movement, and recovery clips cannot shrink the sprite by changing frame bounds.
