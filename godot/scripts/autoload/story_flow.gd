extends Node

const SAVE_PATH := "user://story_progress.cfg"
const HEROES := ["player_01_akky", "player_02_gou", "player_03_seiya"]
const NAMES := {"player_01_akky": "アッキー", "player_02_gou": "ごう", "player_03_seiya": "せいや"}
const TARGETS := {"player_01_akky": "恋人", "player_02_gou": "弟", "player_03_seiya": "妹"}

var survivors: Array[String] = []
var opening_lines: Array = []
var ending_lines: Array = []
var all_survivors_clear := false

func _ready() -> void:
	_load_progress()

func start_new_game() -> void:
	survivors.assign(HEROES)
	opening_lines = [
		{"speaker":"アッキー", "text":"来てくれたか。二人とも、話がある。"},
		{"speaker":"ごう", "text":"……俺もだ。"},
		{"speaker":"アッキー", "text":"どうした？"},
		{"speaker":"ごう", "text":"弟がさらわれた。"},
		{"speaker":"アッキー", "text":"何だって……？"},
		{"speaker":"せいや", "text":"待て。俺も同じだ。"},
		{"speaker":"ごう", "text":"同じ？"},
		{"speaker":"せいや", "text":"妹がさらわれた。突然、連絡が取れなくなった。"},
		{"speaker":"アッキー", "text":"……俺の恋人もだ。"},
		{"speaker":"せいや", "text":"三人同時か……。偶然じゃないな。"},
		{"speaker":"アッキー", "text":"ああ。調べて分かったことが一つある。"},
		{"speaker":"アッキー", "text":"ブラックスパロウだ。", "mark":true},
		{"speaker":"ごう", "text":"ブラックスパロウ……。"},
		{"speaker":"せいや", "text":"やっぱり奴らか。"},
		{"speaker":"ごう", "text":"だったら、すぐアジトへ乗り込もうぜ。"},
		{"speaker":"せいや", "text":"待て。肝心のアジトがどこにあるのか分からない。"},
		{"speaker":"ごう", "text":"じゃあ、どうする？"},
		{"speaker":"アッキー", "text":"まず街だ。"},
		{"speaker":"アッキー", "text":"ブラックスパロウの奴を見つけて、アジトの情報を探る。"},
		{"speaker":"せいや", "text":"そこから奴らを追うってことか。"},
		{"speaker":"アッキー", "text":"ああ。"},
		{"speaker":"ごう", "text":"決まりだな。"},
		{"speaker":"アッキー", "text":"ブラックスパロウを壊す。"},
		{"speaker":"アッキー", "text":"そして――全員、必ず連れ戻す。"},
		{"speaker":"ごう", "text":"ああ！"},
		{"speaker":"せいや", "text":"行こう。"},
	]

func prepare_ending(living_ids: Array) -> void:
	opening_lines.clear()
	survivors.clear()
	for hero in HEROES:
		if living_ids.has(hero): survivors.append(hero)
	all_survivors_clear = survivors.size() == HEROES.size()
	_save_progress()
	ending_lines.clear()
	var rescued: Array[String] = []
	var missing: Array[String] = []
	for hero in HEROES:
		var item := "%sの%s" % [NAMES[hero], TARGETS[hero]]
		if survivors.has(hero): rescued.append(item)
		else: missing.append(item)
	if all_survivors_clear:
		ending_lines.append({"speaker":"アッキー", "text":"みんな、無事だったか！"})
		ending_lines.append({"speaker":"ごう", "text":"ああ。全員そろってる。"})
		ending_lines.append({"speaker":"", "text":"救出した：%s。" % "、".join(rescued)})
		ending_lines.append({"speaker":"せいや", "text":"三人とも、大切な人を連れ戻せたな。"})
		ending_lines.append({"speaker":"", "text":"三人はそれぞれの大切な人と再会した。奪還は、まだ終わっていない。"})
		ending_lines.append({"speaker":"", "text":"TO BE CONTINUED…"})
	else:
		ending_lines.append({"speaker":NAMES[survivors[0]], "text":"無事だったか！"})
		ending_lines.append({"speaker":rescued[0], "text":"うん……。"})
		ending_lines.append({"speaker":"", "text":"救出できた：%s。" % "、".join(rescued)})
		ending_lines.append({"speaker":"", "text":"救出された人々と、生存メンバーは再会した。"})
		ending_lines.append({"speaker":NAMES[survivors[0]], "text":"待て……。%sは？" % "と、".join(missing)})
		ending_lines.append({"speaker":rescued[0], "text":"%sも、さっきまでここにいた。でも……男が来た。" % "と、".join(missing)})
		ending_lines.append({"speaker":rescued[0], "text":"ブラックスパロウの人たちとは違った。邪悪なオーラを纏った男だった……。"})
		ending_lines.append({"speaker":"", "text":"その男が、%sを連れていった。" % "と、".join(missing), "silhouette":true})
		ending_lines.append({"speaker":NAMES[survivors[0]], "text":"ブラックスパロウの仲間なのか？"})
		ending_lines.append({"speaker":rescued[0], "text":"分からない……。でも、ブラックスパロウの奴らもあの男には近づこうとしなかった。"})
		ending_lines.append({"speaker":"", "text":"生存メンバーは沈黙した。"})
		ending_lines.append({"speaker":"", "text":"一体誰が……？", "silhouette":true})
		ending_lines.append({"speaker":"", "text":"奪還は、まだ終わっていない。"})
		ending_lines.append({"speaker":"", "text":"TO BE CONTINUED…"})

func complete_ending() -> void:
	_save_progress()

func _save_progress() -> void:
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(SAVE_PATH): cfg.load(SAVE_PATH)
	cfg.set_value("story", "normal_ending_unlocked", true)
	cfg.set_value("story", "all_survivors_clear", all_survivors_clear)
	cfg.save(SAVE_PATH)

func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		all_survivors_clear = bool(cfg.get_value("story", "all_survivors_clear", false))
