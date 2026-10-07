# 聖夜の急降下キック（2026-10-07）

開始/終了branch: codex/stage1-gou-seiya-20261007
開始HEAD: 532bcc84ea0540d05241b4d04e667ae93d5b5508

## 追加
seiya_dive_kick: ↓＋空中K。優先度120で通常AirK（20）より先に選択。既存150ms入力履歴を使用。
Startup .14 / Active .16 / Recovery .32秒（実動作は既存キャラ倍率とHitStopを反映）。通常KのDamage倍率.9（現在Campaignでは11）。HitBox48×46、前42/上24px。Knockback130/-40、HitStun.24、HitStop.045、空中Overhead/Guard可。下降速度540、前進85（左右反転）、着地硬直.34秒。キャンセル許可なし・無敵/Armorなし。
従来の急降下/着地処理を利用し共有戦闘コードは変更しない。Saveへの新規必須項目なし。地上では発動不可。

## モーション
承認済み細身立ち姿を参考にbuilt-in imagegenで、準備→急降下→着地→復帰の4キーと倍率校正用立ち姿を作成。プロンプトは細い肩/胴/四肢、基準の小さめ頭、金髪/白い長袖/腹部を覆うシャツ/ベージュパンツ/白靴、脚を伸ばさない、透明背景を指定。
全キー共通195px校正、倍率0.362453531598513。空中セル上端75px、地上足元270px。Sprite倍率・骨格の局所加工なし。素材側の頭を二重縮小しないhead_scale_override1。
攻撃3フレーム（接触姿勢を保持）、着地3フレーム。4枚のキーを構成したもので、独立した6枚の中間絵ではない。保存先art_sources/seiya_dive_kick_v11とgodot/assets/characters/player03/animations/slim_dive_kick_v11。

## 検査
SEIYA_DIVE_KICK_CHECK failures=[]（headless/Intel Iris Xe実描画）: 左右のHit/Guard/Whiff、命中11Damage・Guard0Damage、地上拒否、Activeの降下・反転、着地攻撃解除とHitBox消去、Landing中P/K/Throw/Guard/Special/移動/Jump禁止、無敵なし、.34秒硬直後復帰を確認。
攻撃時間切れ後も着地硬直を保持する検査、テスト用攻撃パケットによる着地硬直の被弾/中断も確認。
方向Release後120ms入力とMobileUIハンドラーで方向を7tick保持→Kの優先選択を両向きで確認。手動スマホ実機検査ではない。
SEIYA_MOTION_ATLAS_OK clips=127 frames=372 failures=[]、SEIYA_DIVE_KICK_REVIEW poses=7。立ち姿と全モーション実描画を目視確認。
CRUSHER_AIR_RECEIVED_CHECK seiya failures=[]：既存左右3Hit空中コンボ/着地回帰。

## 修正・境界
確認コードの旧right入力名をmove_rightへ修正。紹介演出待ちで実描画テストが停止するawaitを既存テストの非同期開始方式に合わせて修正。Captureは着地描画更新後に行う。
既存インポートSafe save権限エラー・headless終了時ObjectDBリーク（18/19件）は未解決。剛の急降下、その他Guard/Throw/受けのモーション統一、全Stage回帰、手動実機、公開は未完了。
開始/終了status: phase_seiya_dive_start_status.txt / phase_seiya_dive_end_status.txt。既存dirtyは混ぜず保持。

ユーザーから急降下キックの脚が長すぎるとの指摘を受け、初稿は不採用。imagegen編集で蹴り脚の股関節からつま先までを約18%短くすることを目標に、膝と足首を近づける修正を行った。18%は編集指示であり実測保証ではない。全身の縮小は行わず、正式立ち姿との実描画比較を再確認した。修正版でheadlessの左右Hit/Guard/Whiffと着地硬直検査を再実行して通過。初稿はkey_poses_before_leg_revision.pngに比較用として保持し、ゲームは修正版のみ参照する。

脚修正版でもIntel Iris Xe実描画のSEIYA_DIVE_KICK_CHECK failures=[]を確認。着地Captureの空表示は描画更新を待つことで解消し、native_landing.pngを目視確認済み。
