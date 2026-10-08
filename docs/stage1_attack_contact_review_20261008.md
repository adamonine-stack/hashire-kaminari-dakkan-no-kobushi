# 第1ステージ 攻撃全フレーム・接触姿勢の確認

開始/終了 branch: codex/stage1-gou-seiya-20261007
開始 HEAD: 215fbf4184ac71856ceeb65cabd223729f6ff033

## 修正
### AKKY Down P
既存の専用launcherは4Frameとも低い構え/戻しで、上方向の打撃姿勢がなかった。既存launcherの構え2Frameと、正式デザインで既に使う方向Punch atlasの上方向打撃・戻し2Frameを、320×224pxの完全なセルのまま1:1で再構成した。新規AI画像生成・頭身変更・腕脚の変形・Frameごとの拡縮はない。新しいlauncher_contact_v2を対象クリップへ接続し、旧Resourceは残した。
接触Frame2は上方向の拳となる。HitBoxを(45,-190)へ移し、準備中の低姿勢HurtBoxは0.18秒で終了するよう設定。発生0.20/Active0.09/Recovery0.34、ダメージ、打ち上げ速度(55,-420)、Cancel Routeは維持。

### 豪・聖夜の通常攻撃Contact
技データにはContact2または未設定が残り、実行側のキャラクター別補正がContact3へ変更していた。レビュー画像だけを見れば実際と異なる曲がった腕を接触姿勢として扱ってしまう。豪3技/聖夜4技にContact3を明示し、共通処理は明示されたMove Dataをlegacy fallbackより優先するよう修正した。実ゲームの従来のContact3と回復Frame4以降を維持し、通常技の戦闘値は変更していない。全キャラクターの技ID固定表を置換する大規模Refactorはしていない。

## 検証
- stage1_attack_frame_review: 4人の技Resourceが実際に参照するクリップと必殺技の構え・攻撃・終了を抽出。左右両向き544Frameをheadless/ネイティブ描画で確認し failures=[]。Sprite倍率、基準位置、反転、Texture/Atlas範囲、Contact Frame範囲を全Frameで検査。
- 全Frame画像と、立ち姿付きFrame stripを作成。Contact指定のない技は代表Frameと表示し、Contactと誤認しない。全素材の画素を等倍で配置。
- stage1_contact_pose_check: 豪・聖夜の通常攻撃のデータ/実行一致と、複製したDataのContact2がlegacy補正より優先されることを確認。AKKY launcherは左右両向きで実Area2D接触により地上のCrusherへDamageと上向きの力を与える。攻撃側は実physics、被攻撃側は接触位置を固定したfixtureであり、手操作のLauncher Comboではない。headless/nativeとも failures=[]。
- AKKY atlas: 142clips/376frames、豪150/401、聖夜156/423、すべてpass。
- directional_attacks_check、stage1_remaining_heroes_check、stage1_regressionすべて failures=[]。
- 右向きContact/代表姿勢の4人分の一覧と、AKKY打ち上げ/豪・聖夜通常P/Crusher Forward Kの全Frame stripを目視比較。左右は機械検査と全Frame描画。544Frameすべてを個別に目視承認したとは報告しない。

## 残るデザイン課題
CrusherのForward K、Back K、Down P、Dive Kなど一部地上技には、正式立ち姿や新しいAir攻撃より肌の描き込み密度が少ない素材が残る。体格・服装だけでなく肌・顔の密度も統一する必要がある。今回のContact修正で解決したとは扱わない。次の制作では正式立ち姿と同じデザインを用い、1技ずつKey Pose比較→中間Frame→Atlas→実描画の順で修正する。

## 未確認/保存範囲
新規Sprite描き直し、全Motionの全Frame目視、スマホ実機、手操作の1対1試合、公開Webは今回未実施。既存の終了時ObjectDB警告は残り、方向攻撃17件/残り主人公テスト16件を記録。544枚の生Frameと各stripはローカル保存し、Commitにはinventory、両向き4人分の一覧、AKKY launcher strip、native launcher2枚を含める。既存User変更は保持。
