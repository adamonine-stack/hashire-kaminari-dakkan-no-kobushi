# Seiya dedicated stepping punch

Branch codex/stage1-gou-seiya-20261007; start HEAD183fdaf5b5f9b59e55be313c15ec0f645038e659.

Changed seiya_forward_punch animation from punch_2 to dedicated seiya_forward_punch only. Damage1.05, startup0.13/active0.08/recovery0.22, forward38, hitbox60x34 at68,-125, hurtbox/cancel targets retained.

Imagegen used official seiya_slim_v3/formal_standing.png. Keep slim torso/shoulders/limbs, blond head/face, white long sleeves covering belly, beige trousers/belt/white sneakers. Dedicated chamber/stepping contact/retract/finish. Source comparison inspected before connection. Four unique action key poses mapped [1,1,2,3,4]12fps contact2; no additional intermediate art claimed. One195/477=0.4088050314 scale all source poses, no separate limb resize. Cell384x288 origin160 baseline270 head_scale_override1 prevents duplicate head shrink.

Native Intel Iris Xe seven-pose comparison inspected with official standing; fixed scale/source assertions passed. Both-facing headless and native authored combat failures=[]: dedicated source/head correction, actual advance/damage, confirmed forward kick cancel inside configured window and whiff cancel denied. Cancel test checks transition, not subsequent kick hit/full combo. Complete Seiya atlas122clips351frames failures=[]. Native contact screenshot inspected. Existing editor safe-save error and headless ObjectDB exit warning remain; no warning-free claim. No physical phone/manual touch/deployed Web verification or publication.

Added source/gray/same-scale/native evidence, packer, atlasPNG/TRES/manifest, native review/combat tests/report. Changed fighter supplemental path, attack animation only, atlas exact source expectation. Existing unrelated dirty/import files preserved/excluded. Remaining other directional/throw/receiver dedicated art and final Stage1 play/release unfinished.
