# レイ専用必殺技・制作前Motion設計

第2ステージ enemy_04_rei_kageyama、rei_dragon_uppercut（竜巻昇龍拳）を引き継ぐ。旧Atlasのspecial_attack/rei_dragon_uppercutは通常punch_2と同じFrame16、recoveryはFrame17を共有していた。

新規: 独立した8原画。0沈み込む予備動作→1荷重移動→2腰で拳を巻き込む構え→3上昇打撃→4拳を高く伸ばしたImpact→5拳を戻し着地荷重→6身体を起こすRecovery→7専用Finish。まず0/2/4/7のKey Poseを1枚ずつ制作・デザイン比較し、その後1/3/5/6を制作。左右の腕と脚の役割、衣装、髪、顔、足基準を維持し、SpriteのRuntime拡縮は使用しない。

正式デザイン: 刈り上げの暗髪、筋肉質の長身、毛皮縁の黒いノースリーブベスト、黒い指抜き手袋、腰の金色チェーン、黒いゆったりしたパンツ、厚底の黒いブーツ。現行Godotの実idle Frameを参照画像として書き出す。

受け手: 主人公3人だけ。各人に顎/胸を跳ね上げられたhit、上へ押し上げられ後方へ流れるair、仰向けのdown、強いGuard衝撃、Guard維持の5原画。すべて個別制作し、技IDごとの反応に登録。他の技の受け手と通常技は保持。

戦闘: Damage14（主力Attack×1.5）、Guard可能、既存15%Chip、Hit時攻撃中断、MAXゲージとCooldown4.2s。Startup0.18s/保護0.10s、Active0.20s、Recovery0.55s、Whiff倍率1.25。開始保護が終わった残りStartupは攻撃で止められる。上方向Launchを速度上限と画面内保持で制御し、長時間無敵にはしない。AIは前工程のreversal/counter観察方式を使用。

Effect: 足元の短い螺旋、前腕から実HitBoxへ伸びる上昇弧。顔や服を覆うAuraを避ける。Soundは既存Start/Active/Hitポイントを使用。

検証予定: 正式Atlas参照・通常P/Kとの非共有、全原画×左右、固定Scaleと足基準、実Battleの三人×左右の命中/Guard/Whiff/被弾中Reversal/KO/壁寄り、開始保護の終了、AI観察、物理HitBox接触、Launch方向・着地・Effect同期。描画と手動実戦は区別して報告する。
