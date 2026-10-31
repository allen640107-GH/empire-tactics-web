extends Node
# 帝國戰記 v14 — 全域資料與存檔（Autoload：G）
var W := {}        # 武器
var A := {}        # 防具
var I := {}        # 道具
var JW := {}       # 職業可用武器類型
var JA := {}       # 職業可用防具類型
var GROW := {}
var EGROW := {}
var BATTLES: Array = []
var TPL := {}
var PARTY0: Array = []
var PORTRAIT := {}

# 進度
var roster: Array = []     # 隊伍成員（字典）
var inv := {}              # 裝備庫存 {名稱: 數量}（不含身上裝備）
var items := {}            # 道具 {名稱: 數量}
var gold := 0
var progress := 0          # 下一場戰鬥索引（0..15），16 = 通關
var cur_battle := 0
var play_time := 0.0
var cleared := {}
var last_result := {}      # 上一場戰鬥結果（營地顯示用）
var test_mode := false
const EXP_PER_LV := 100
const MAX_LV := 50
const SAVE_PATH := "user://saves/auto.json"   # v21：固定存檔夾＋槽位

func _ready() -> void:
	migrate_settings()
	load_settings()
	get_tree().node_added.connect(_on_node_added)
	var eq: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/equip.json"))
	var sj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story.json"))
	W = eq.weapons; A = eq.armors; I = eq.items; JW = eq.job_weapons; JA = eq.job_armors; GROW = eq.growth
	BATTLES = sj.battles; TPL = sj.templates; PARTY0 = sj.party; PORTRAIT = sj.portrait; EGROW = sj.enemy_growth
	# JSON 數字為 float，轉為 int
	for d in [W, A]:
		for k in d:
			for f in d[k]:
				if typeof(d[k][f]) == TYPE_FLOAT: d[k][f] = int(d[k][f])
	for k in I:
		I[k].val = int(I[k].val); I[k].range = int(I[k].range); I[k].price = int(I[k].price)
	new_game()
	migrate_legacy()

func _process(d: float) -> void:
	play_time += d / maxf(Engine.time_scale, 0.01)

func ints(d: Dictionary) -> Dictionary:
	var o := {}
	for k in d: o[k] = int(d[k])
	return o

func make_member(p: Dictionary, lv := 1) -> Dictionary:
	var m := {"name": p.name, "job": p.job, "key": p.key, "title": p.title, "lv": 1, "exp": 0, "base": ints(p.base),
		"weapon": p.weapon, "armor": p.armor, "hero": p.get("hero", false), "tier": 0, "cls": ""}
	var rng := RandomNumberGenerator.new(); rng.seed = hash(p.name)
	for i in lv - 1: level_up(m, rng)
	return m

func new_game() -> void:
	roster.clear()
	for p in PARTY0: roster.append(make_member(p))
	inv = {"長劍": 1, "手斧": 1}
	items = {"回復藥": 4, "魔力水": 2, "解毒草": 2, "火焰瓶": 1}
	gold = 600; progress = 0; cur_battle = 0; play_time = 0.0; cleared = {}; last_result = {}; keyitems = []; events = {}

# ---------- 成長 ----------
func level_up(m: Dictionary, rng = null) -> Dictionary:
	var g: Dictionary = GROW.get(m.job, GROW["騎士"])
	var gains := {}
	for k in g:
		var v: float = g[k]
		var add := int(v)
		var fr := v - add
		var r: float = rng.randf() if rng != null else randf()
		if r < fr: add += 1
		if add > 0:
			m.base[k] = int(m.base.get(k, 0)) + add
			gains[k] = add
	m.lv += 1
	return gains

func add_exp(m: Dictionary, amount: int) -> Array:
	var ups := []
	if m.lv >= MAX_LV: return ups
	m.exp += amount
	while m.exp >= EXP_PER_LV and m.lv < MAX_LV:
		m.exp -= EXP_PER_LV
		ups.append(level_up(m))
	return ups

func member(n: String):
	for m in roster:
		if m.name == n: return m
	return null

# ---------- 裝備 ----------
func can_equip(job: String, kind: String, nm: String, hero := false) -> bool:
	if kind == "weapon":
		var w: Dictionary = W[nm]
		if w.get("enemy", false): return false
		if w.get("hero", false) and not hero: return false
		return w.type in JW.get(job, [])
	var a: Dictionary = A[nm]
	if a.get("enemy", false): return false
	return a.type in JA.get(job, [])

func owned_list(m: Dictionary, kind: String) -> Array:
	# 可裝備的：身上的 + 庫存中可用的
	var cur: String = m[kind]
	var out := [cur]
	for k in inv:
		if inv[k] <= 0 or k == cur: continue
		if (kind == "weapon" and W.has(k)) or (kind == "armor" and A.has(k)):
			if can_equip(m.job, kind, k, m.get("hero", false)): out.append(k)
	var tb: Dictionary = W if kind == "weapon" else A
	out.sort_custom(func(a, b): return int(tb[a].tier) < int(tb[b].tier))
	return out

func swap_equip(m: Dictionary, kind: String, nm: String) -> void:
	if m[kind] == nm: return
	if inv.get(nm, 0) <= 0: return
	inv[nm] -= 1
	if inv[nm] <= 0: inv.erase(nm)
	inv[m[kind]] = inv.get(m[kind], 0) + 1
	m[kind] = nm

func add_inv(nm: String, n := 1) -> void:
	if I.has(nm): items[nm] = items.get(nm, 0) + n
	else: inv[nm] = inv.get(nm, 0) + n

func shop_tier() -> int:
	return clampi(int((progress + 2) * 0.6), 1, 9)

func shop_list() -> Array:
	var out := []
	var t := shop_tier()
	for k in W:
		if not W[k].get("enemy", false) and not W[k].get("hero", false) and not W[k].get("legend", false) and int(W[k].tier) <= t: out.append(k)
	for k in A:
		if not A[k].get("enemy", false) and not A[k].get("legend", false) and int(A[k].tier) <= t: out.append(k)
	return out

func item_shop() -> Array:
	var out := []
	for k in I:
		var need := 0
		match k:
			"鳳凰之羽", "萬能藥": need = 4
			"全效藥", "經驗之書", "高級魔力水": need = 7
			"聖水", "雷鳴符", "高級回復藥": need = 3
			"復甦草": need = 2
			"不死鳥之淚": need = 8
			"轉生之靈": need = 12
		if progress >= need: out.append(k)
	return out

func price(nm: String) -> int:
	if W.has(nm): return int(W[nm].price)
	if A.has(nm): return int(A[nm].price)
	return int(I[nm].price)

func buy(nm: String) -> bool:
	var p := price(nm)
	if gold < p: return false
	gold -= p; add_inv(nm); return true

func sell(nm: String) -> bool:
	if I.has(nm):
		if items.get(nm, 0) <= 0: return false
		items[nm] -= 1
		if items[nm] <= 0: items.erase(nm)
	else:
		if inv.get(nm, 0) <= 0: return false
		inv[nm] -= 1
		if inv[nm] <= 0: inv.erase(nm)
	gold += price(nm) / 2
	return true

func use_item(nm: String) -> void:
	items[nm] = items.get(nm, 0) - 1
	if items[nm] <= 0: items.erase(nm)

# ---------- 戰鬥設定 ----------
func expected_lv(n: int) -> int:
	return int(round(1.0 + 0.85 * n))

func enemy_tier(n: int) -> int:
	return clampi(int(n * 0.6), 0, 9)

func pick_gear(tbl: Dictionary, types: Array, tier: int, rng: RandomNumberGenerator) -> String:
	var best := ""; var bt := -1
	var t := clampi(tier + rng.randi_range(-1, 0), 0, 9)
	for k in tbl:
		var e: Dictionary = tbl[k]
		if e.get("enemy", false) or e.get("hero", false) or e.get("legend", false): continue
		if not (e.type in types): continue
		var et := int(e.tier)
		if et <= t and et > bt and (k != "十字弓"): bt = et; best = k
	if best == "":
		var lo := 99
		for k in tbl:
			var e: Dictionary = tbl[k]
			if e.get("enemy", false) or e.get("hero", false) or e.get("legend", false) or not (e.type in types): continue
			if int(e.tier) < lo: lo = int(e.tier); best = k
	return best

func enemy_member(tname: String, n: int, lvoff: int, rng: RandomNumberGenerator) -> Dictionary:
	var tp: Dictionary = TPL[tname]
	var lv := maxi(1, expected_lv(n) + lvoff)
	var m := {"name": tname, "job": tp.job, "key": tp.key, "title": tp.title, "lv": lv, "base": ints(tp.base)}
	var g: Dictionary = EGROW.get(tp.job, EGROW["騎士"])
	for k in g:
		m.base[k] = int(m.base.get(k, 0)) + int(round(float(g[k]) * (lv - 1)))
	var et := enemy_tier(n)
	m.weapon = pick_gear(W, [tp.wt], et, rng)
	m.armor = pick_gear(A, [tp.at], et, rng)
	if tp.job == "刺客": m.weapon = pick_gear(W, ["劍"], maxi(0, et - 1), rng)
	return m

func boss_member(bd: Dictionary, n: int) -> Dictionary:
	var m := {"name": bd.name, "job": bd.job, "key": bd.key, "title": bd.title, "lv": int(bd.lv), "base": ints(bd.base),
		"weapon": bd.weapon, "armor": bd.armor, "boss": true, "skill": bd.skill, "scale": float(bd.get("scale", 1.15))}
	var g: Dictionary = EGROW.get(bd.job, EGROW["騎士"])
	# 頭目基礎值為 Lv1 參考 → 依等級成長（略打折）
	for k in g:
		m.base[k] = int(m.base.get(k, 0)) + int(round(float(g[k]) * 0.85 * (int(bd.lv) - 1)))
	m.base.hp = int(m.base.hp * 1.6)
	return m

const CHAPTERS := [[0, "序章「霜松林的金陽」"], [1, "第一章「灰石關」"], [2, "第二章「商都的天秤」"], [6, "第三章「法典的真相」"], [8, "第四章「金陽再臨」"], [11, "第五章「鐵壁與王座」"], [15, "終章「金陽之下」"]]
func chapter_of(n: int) -> String:
	var c := ""
	for e in CHAPTERS:
		if n >= int(e[0]): c = e[1]
	return c

func chapter_title(n: int) -> String:
	return "%s・第%d戰 %s" % [chapter_of(n), n + 1, BATTLES[clampi(n, 0, BATTLES.size() - 1)].name]

func battle_def(n: int) -> Dictionary:
	return BATTLES[clampi(n, 0, BATTLES.size() - 1)]

# 依進度建立「應有的」隊伍（自動測試或章節選擇用）
func setup_for_battle(n: int) -> void:
	new_game()
	progress = n; cur_battle = n
	var lv := expected_lv(n)
	roster.clear()
	for p in PARTY0: roster.append(make_member(p, lv))
	for i in n:
		var r = BATTLES[i].get("recruit")
		if r != null and member(r.name) == null: roster.append(make_member(r, maxi(1, lv - 1)))
	var t := shop_tier()
	var rng := RandomNumberGenerator.new(); rng.seed = 7 + n
	for m in roster:
		var types: Array = JW[m.job]
		if not m.hero:
			var w := pick_gear(W, [types[0]], t, rng)
			if w != "" and int(W[w].tier) > int(W[m.weapon].tier): m.weapon = w
		# v14：於職業可穿的所有防具類型中挑防禦最高者（同值優先職業專屬）
		var a := ""
		for k in A:
			var e: Dictionary = A[k]
			if e.get("enemy", false) or e.get("hero", false) or e.get("legend", false) or not (e.type in JA[m.job]) or int(e.tier) > t: continue
			if a == "" or int(e.def) > int(A[a].def) or (int(e.def) == int(A[a].def) and e.type == JA[m.job][0]): a = k
		if a != "" and int(A[a].tier) > int(A[m.armor].tier): m.armor = a
	items = {"回復藥": 4 + n / 3, "魔力水": 2 + n / 4, "解毒草": 2, "火焰瓶": 2, "高級回復藥": n / 3, "聖水": 1 if n >= 3 else 0, "鳳凰之羽": 1 if n >= 4 else 0, "雷鳴符": 1 if n >= 3 else 0, "復甦草": 2 if n >= 2 else 0, "不死鳥之淚": 1 if n >= 8 else 0, "轉生之靈": 1 if n >= 12 else 0}
	for k in items.keys():
		if items[k] <= 0: items.erase(k)
	gold = 800 + n * 400
	# v16：自動測試／章節選擇時依進度自動晉升
	keyitems = []
	if n >= 5: keyitems.append(SUMMON_ITEM)
	if n >= 9: keyitems.append(KEY_ITEM)
	if n >= 12 and "--withadam" in OS.get_cmdline_user_args(): keyitems.append(SUMMON3_ITEM); print("WITHADAM ", keyitems)   # 測試：亞達曼展示
	var bi := 0
	for m in roster:
		var br := "a" if (bi + n) % 2 == 0 else "b"; bi += 1
		while can_promote(m) > 0: promote(m, br)

func after_battle(win: bool, res: Dictionary) -> void:
	last_result = res
	if win:
		var bd := battle_def(cur_battle)
		gold += int(res.get("gold", 0))
		for d in res.get("drops", []): add_inv(d)
		var r = bd.get("recruit")
		if r != null and member(r.name) == null:
			var avg := 0
			for m in roster: avg += m.lv
			avg = maxi(1, avg / maxi(1, roster.size()))
			roster.append(make_member(r, avg))
			if inv.get(r.weapon, 0) > 0:
				inv[r.weapon] -= 1
				if inv[r.weapon] <= 0: inv.erase(r.weapon)
		if cur_battle == 4 and not has_lev(): keyitems.append(SUMMON_ITEM); res["summon"] = SUMMON_ITEM
		if cur_battle == 8 and not (KEY_ITEM in keyitems): keyitems.append(KEY_ITEM); res["keyitem"] = KEY_ITEM
		var lg: String = str(res.get("legend", ""))   # v23：特殊劇情獎勵
		if lg != "":
			events[str(res.get("event", ""))] = true
			if lg == SUMMON3_ITEM:
				if not has_adam(): keyitems.append(SUMMON3_ITEM)
			elif inv.get(lg, 0) <= 0 and not legend_equipped(lg): add_inv(lg)
		cleared[str(cur_battle)] = true
		if cur_battle >= progress: progress = cur_battle + 1
		cur_battle = mini(progress, BATTLES.size() - 1)
	if not test_mode: save_game()

# ---------- 存檔 ----------
func save_dict() -> Dictionary:
	return {"v": SAVE_VER, "ts": int(Time.get_unix_time_from_system()), "keyitems": keyitems, "roster": roster, "inv": inv, "items": items, "gold": gold, "progress": progress, "play_time": play_time, "cleared": cleared, "ending_seen": ending_seen, "events": events}

func save_game(path := SAVE_PATH) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(save_dict()))
	f.close()
	if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	return DirAccess.rename_absolute(tmp, path) == OK

func has_save(path := "") -> bool:
	if path != "": return FileAccess.file_exists(path)
	return latest_slot() != ""

func load_game(path := "") -> bool:
	if path == "": path = latest_slot()
	if path == "" or not FileAccess.file_exists(path): return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(d) != TYPE_DICTIONARY: return false
	roster = []
	for m in d.roster:
		m.lv = int(m.lv); m.exp = int(m.exp); m.base = ints(m.base)
		m.tier = int(m.get("tier", 0)); m.cls = str(m.get("cls", ""))   # v16：舊存檔相容
		if m.tier > 0 and not (m.cls in ["a", "b"]): m.tier = 0; m.cls = ""
		roster.append(m)
	inv = ints(d.inv); items = ints(d.items); gold = int(d.gold); progress = int(d.progress)
	play_time = float(d.get("play_time", 0.0)); cleared = d.get("cleared", {}); ending_seen = bool(d.get("ending_seen", false))
	if progress >= BATTLES.size(): mark_game_cleared()
	keyitems = []
	for k in d.get("keyitems", []): keyitems.append(str(k))
	if progress >= 5 and not has_lev(): keyitems.append(SUMMON_ITEM)   # v17：舊存檔已過第5戰者補發契約
	if progress >= 9 and not (KEY_ITEM in keyitems): keyitems.append(KEY_ITEM)   # 舊存檔已過第9戰者補發
	events = d.get("events", {})   # v23：舊存檔無特殊劇情紀錄 → 視為未達成（可重玩章節補拿）
	if typeof(events) != TYPE_DICTIONARY: events = {}
	return true

func fmt_time(t: float) -> String:
	var s := int(t)
	return "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]

# ---- v15：語音設定 ----
var voice_vol := 0.8
const SETTINGS := "user://settings.cfg"
func load_settings() -> void:
	var c := ConfigFile.new()
	if c.load(SETTINGS) == OK: voice_vol = float(c.get_value("audio", "voice", 0.8))
	font_level = int(c.get_value("display", "font_level", 1 if is_handheld() else 0))
	if c.load(SETTINGS) != OK: font_level = 1 if is_handheld() else 0
func save_settings() -> void:
	var c := ConfigFile.new(); c.load(SETTINGS); c.set_value("audio", "voice", voice_vol); c.set_value("display", "font_level", font_level); c.save(SETTINGS)
const VOICE_MAP := {"rain": "hero", "erin": "erin", "grey": "grey", "mira": "mira", "vig": "vig", "gard": "gard", "aurelia": "aurelia", "mira_e": "enemy_f", "aurelia_e": "enemy_f", "maximus": "boss", "cyrus": "boss", "simon": "boss", "barto": "boss"}
func voice_of(key: String, team: int, boss: bool) -> String:
	if VOICE_MAP.has(key): return VOICE_MAP[key]
	if boss: return "boss"
	return "enemy_m" if team == 1 else "knight"
const SPELL_IDS := {"火球術": "f1", "烈焰陣": "f2", "獄炎爆": "f3", "冰矢術": "w1", "激流術": "w2", "冰封棺": "w3", "風刃術": "a1", "旋風術": "a2", "瘴氣風暴": "a3",
	"石礫術": "e1", "地裂術": "e2", "隕岩崩": "e3", "治癒之水": "h1", "淨化術": "h2", "遲緩術": "d1", "疾風術": "b1", "灼燒咒": "d2", "岩盾術": "b2", "束縛根": "d3",
	"復活術": "r1", "大復活術": "r2", "沉默術": "d4", "聖淨領域": "h3", "生命之泉": "h4", "天火流星": "f4", "大海嘯波": "w4", "雷霆審判": "a4", "天崩地裂": "e4", "時間加速": "b3"}
func spell_id(n: String) -> String: return SPELL_IDS.get(n, "x")

# ---- v16：職業晉升 ----
var keyitems: Array = []
const KEY_ITEM := "英雄之證"
const SUMMON_ITEM := "利維坦之契約"   # v17：第二召喚獸
func has_lev() -> bool: return SUMMON_ITEM in keyitems
# ---- v23：特殊劇情／第三召喚獸 ----
const SUMMON3_ITEM := "玄岳之契"
var events: Dictionary = {}
func has_adam() -> bool: return SUMMON3_ITEM in keyitems
func legend_equipped(nm: String) -> bool:
	for m in roster:
		if m.weapon == nm or m.armor == nm: return true
	return false
const PROMO_LV := [5, 10]
# key → 分支 a/b：[一轉名, 二轉名, 一轉加成, 二轉加成, 說明]
const PROMO := {
	"rain": {"a": ["聖騎士", "王道聖騎士", {"hp": 14, "def": 4, "mag": 2}, {"hp": 18, "def": 5, "mag": 3, "atk": 2}, "以聖光守護同伴的重裝騎士"],
		"b": ["劍聖", "黎明劍帝", {"atk": 5, "spd": 2, "hp": 6}, {"atk": 6, "spd": 2, "hp": 10, "move": 1}, "追求一劍極致的劍士"]},
	"erin": {"a": ["鷹眼狙擊", "天穹神射", {"atk": 5, "hp": 6}, {"atk": 6, "hp": 8, "spd": 1}, "超遠距精準射擊"],
		"b": ["遊俠", "秋風遊俠王", {"spd": 3, "move": 1, "hp": 8}, {"atk": 4, "spd": 2, "hp": 10}, "疾行林野的機動射手"]},
	"grey": {"a": ["破壞者", "毀滅戰神", {"atk": 6, "hp": 10}, {"atk": 7, "hp": 14}, "捨身狂攻的巨斧戰士"],
		"b": ["鐵壁", "不落要塞", {"def": 5, "hp": 16}, {"def": 6, "hp": 20, "atk": 2}, "以巨盾擋下一切的守衛"]},
	"mira": {"a": ["煉獄賢者", "焚天賢者", {"mag": 5, "mp": 10}, {"mag": 6, "mp": 14}, "專精火焰的大魔導"],
		"b": ["星辰召喚", "星界召喚主", {"mag": 3, "mp": 16, "hp": 6}, {"mag": 4, "mp": 18, "def": 2}, "與星辰訂約的召喚師"]},
	"vig": {"a": ["血狼", "血月狼王", {"atk": 5, "spd": 2}, {"atk": 6, "spd": 2, "hp": 10}, "嗜血的雙斧狂戰士"],
		"b": ["狼群首領", "赤狼大族長", {"hp": 12, "def": 3, "atk": 2}, {"hp": 14, "def": 4, "atk": 3}, "率領赤狼的戰團長"]},
	"gard": {"a": ["深淵騎士", "深淵領主", {"atk": 5, "mag": 3}, {"atk": 6, "mag": 4, "hp": 10}, "駕馭深淵之力的黑騎士"],
		"b": ["黃昏守護者", "月蝕聖盾", {"def": 5, "hp": 12}, {"def": 6, "hp": 16, "mag": 2}, "以月盾守護弱者的贖罪騎士"]},
	"aurelia": {"a": ["熾天聖女", "熾天大聖女", {"mag": 5, "mp": 12}, {"mag": 6, "mp": 14, "hp": 8}, "展開光翼的高階祭司"],
		"b": ["審判者", "神罰審判長", {"atk": 5, "def": 4, "hp": 10}, {"atk": 6, "def": 4, "hp": 12}, "手持金鎚執行神罰的聖戰士"]}}

func cls_name(m: Dictionary) -> String:
	var t := int(m.get("tier", 0))
	if t <= 0 or not PROMO.has(m.key): return m.job
	return PROMO[m.key][m.cls][t - 1]

# 回傳可晉升至的階級（0 = 不可）
func can_promote(m: Dictionary) -> int:
	if not PROMO.has(m.key): return 0
	var t := int(m.get("tier", 0))
	if t == 0 and int(m.lv) >= PROMO_LV[0]: return 1
	if t == 1 and int(m.lv) >= PROMO_LV[1] and KEY_ITEM in keyitems: return 2
	return 0

func promo_need(m: Dictionary) -> String:
	var t := int(m.get("tier", 0))
	if not PROMO.has(m.key) or t >= 2: return ""
	if t == 0: return "Lv%d 可晉升" % PROMO_LV[0]
	var s := "Lv%d" % PROMO_LV[1]
	if not (KEY_ITEM in keyitems): s += "＋「%s」（第9戰後取得）" % KEY_ITEM
	return s + " 可二轉"

func promote(m: Dictionary, branch := "a") -> Dictionary:
	var t := can_promote(m)
	if t == 0: return {}
	if t == 2: branch = m.cls
	m.cls = branch; m.tier = t
	var bon: Dictionary = PROMO[m.key][branch][1 + t]
	bon = bon.duplicate()
	if not bon.has("mp"): bon["mp"] = 10   # 物理系晉升補 MP 以施放職業技能
	for k in bon: m.base[k] = int(m.base.get(k, 0)) + int(bon[k])
	return bon


# ================= v21：跨版本存檔 =================
const SAVE_VER := 23
const SAVE_DIR := "user://saves/"
const SLOTS := ["auto", "slot1", "slot2", "slot3", "backup"]
const SLOT_NAMES := {"auto": "自動存檔", "slot1": "存檔 1", "slot2": "存檔 2", "slot3": "存檔 3", "backup": "新遊戲前備份"}
var ending_seen := false
var migrate_msg := ""
func slot_path(s: String) -> String: return SAVE_DIR + s + ".json"

func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if typeof(d) == TYPE_DICTIONARY and d.has("roster") else {}

func slot_ts(path: String) -> int:
	var d := read_json(path)
	if d.is_empty(): return -1
	return int(d.get("ts", FileAccess.get_modified_time(path)))

func latest_slot() -> String:
	var best := ""; var bt := -1
	for s in SLOTS:
		var t := slot_ts(slot_path(s))
		if t > bt: bt = t; best = slot_path(s)
	return best

func slot_info(s: String) -> Dictionary:
	var d := read_json(slot_path(s))
	if d.is_empty(): return {}
	var p := int(d.get("progress", 0))
	return {"progress": p, "play_time": float(d.get("play_time", 0.0)), "ts": slot_ts(slot_path(s)), "n": (d.roster as Array).size(), "gold": int(d.get("gold", 0)), "v": int(d.get("v", 0)),
		"text": "%s｜%s｜遊玩 %s｜%d 人｜%d G" % ["已通關" if p >= BATTLES.size() else "第 %d 戰" % (mini(p, BATTLES.size() - 1) + 1), Time.get_datetime_string_from_unix_time(slot_ts(slot_path(s)) + tz_bias(), true), fmt_time(float(d.get("play_time", 0.0))), (d.roster as Array).size(), int(d.get("gold", 0))]}

func tz_bias() -> int: return int(Time.get_time_zone_from_system().get("bias", 0)) * 60

# 舊版存檔搜尋：舊 user:// 檔名 + 舊版 Godot 預設資料夾（v14~v20 專案名稱）。只讀取、不刪除。
func legacy_candidates() -> Array:
	var c := ["user://save_v14.json", "user://save.json"]
	var names := ["帝國戰記 SRPG", "帝國戰記 SRPG v13"]
	for n in range(14, 21): names.append("帝國戰記 SRPG v%d" % n)
	for base in [OS.get_data_dir() + "/Godot/app_userdata/", OS.get_data_dir() + "/godot/app_userdata/"]:
		for n in names:
			for fn in ["save_v14.json", "save.json"]: c.append(base + n + "/" + fn)
	return c

func migrate_legacy(force := false) -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if has_save() and not force: return
	var best := ""; var bt := -1
	for p in legacy_candidates():
		if FileAccess.file_exists(p) and not read_json(p).is_empty():
			var t := int(FileAccess.get_modified_time(p))
			print("MIGRATE found ", p, " mtime=", t)
			if t > bt: bt = t; best = p
	if best == "": return
	if load_game(best):
		save_game(slot_path("auto")); save_game(slot_path("slot1"))
		migrate_msg = "已自動匯入舊版存檔（第 %d 戰，%s）" % [mini(progress, BATTLES.size() - 1) + 1, fmt_time(play_time)]
		print("MIGRATE OK from ", best, " progress=", progress, " v=", SAVE_VER)
	new_game(); gold = 600; progress = 0; play_time = 0.0; cleared = {}; ending_seen = false

# 存檔碼：ET1.<base64(gzip(JSON))>.<md5 前 8 碼>
func export_code(d := {}) -> String:
	if d.is_empty(): d = save_dict()
	var raw := JSON.stringify(d).to_utf8_buffer()
	var b := Marshalls.raw_to_base64(raw.compress(FileAccess.COMPRESSION_GZIP))
	return "ET1." + b + "." + b.md5_text().substr(0, 8)

func import_code(code: String, slot: String) -> String:
	var s := code.strip_edges().replace("\n", "").replace("\r", "").replace(" ", "")
	var parts := s.split(".")
	if parts.size() != 3 or parts[0] != "ET1": return "格式不正確（應以 ET1. 開頭）"
	if parts[1].md5_text().substr(0, 8) != parts[2]: return "存檔碼不完整或有錯字（檢查碼不符）"
	var raw := Marshalls.base64_to_raw(parts[1]).decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	var d = JSON.parse_string(raw.get_string_from_utf8())
	if typeof(d) != TYPE_DICTIONARY or not d.has("roster"): return "存檔內容無法讀取"
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var tmp := SAVE_DIR + "_import.json"
	var f := FileAccess.open(tmp, FileAccess.WRITE); f.store_string(JSON.stringify(d)); f.close()
	if not load_game(tmp): return "存檔內容無法讀取"
	DirAccess.remove_absolute(tmp)
	save_game(slot_path(slot))
	return ""

# 通關記錄（與槽位無關，存在 settings.cfg）
func mark_game_cleared() -> void:
	var c := ConfigFile.new(); c.load(SETTINGS); c.set_value("game", "cleared", true); c.save(SETTINGS)
func game_cleared() -> bool:
	var c := ConfigFile.new()
	if c.load(SETTINGS) == OK and bool(c.get_value("game", "cleared", false)): return true
	for s in SLOTS:
		if int(slot_info(s).get("progress", 0)) >= BATTLES.size(): return true
	return false

func backup_auto() -> void:
	if FileAccess.file_exists(slot_path("auto")):
		DirAccess.copy_absolute(slot_path("auto"), slot_path("backup"))


# ================= v21：可讀性（字體大小 標準／大／特大） =================
var font_level := 0
const FONT_LEVEL_NAMES := ["標準", "大", "特大"]
func is_handheld() -> bool:
	if OS.has_feature("mobile"): return true
	if OS.has_feature("web") and DisplayServer.is_touchscreen_available(): return true
	return OS.get_cmdline_user_args().has("--handheld")
func font_k() -> float:
	var base := [1.15, 1.35, 1.6] if is_handheld() else [1.0, 1.2, 1.4]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fontlevel="): font_level = clampi(int(a.substr(12)), 0, 2)
	return base[clampi(font_level, 0, 2)]
func cycle_font_level() -> String:
	font_level = (font_level + 1) % 3; save_settings(); return FONT_LEVEL_NAMES[font_level]

func migrate_settings() -> void:
	if FileAccess.file_exists(SETTINGS): return
	var best := ""; var bt := -1
	for base in [OS.get_data_dir() + "/Godot/app_userdata/", OS.get_data_dir() + "/godot/app_userdata/"]:
		for n in range(14, 21):
			var p: String = base + "帝國戰記 SRPG v%d/settings.cfg" % n
			if FileAccess.file_exists(p) and FileAccess.get_modified_time(p) > bt: bt = FileAccess.get_modified_time(p); best = p
	if best != "": DirAccess.copy_absolute(best, SETTINGS)

var _bold_cache := {}
func _on_node_added(n: Node) -> void:
	if n is Label or n is Button or n is RichTextLabel or n is LineEdit or n is TextEdit:
		_fix_text.call_deferred(n)

func _fix_text(n: Control) -> void:
	if not is_instance_valid(n) or n.has_meta("fs_done"): return
	n.set_meta("fs_done", true)
	var k := font_k()
	var an: Node = n
	while an != null:
		if an.has_meta("no_fix"): return
		if an.has_meta("max_k"): k = minf(k, float(an.get_meta("max_k"))); break
		an = an.get_parent()
	var key := "normal_font_size" if n is RichTextLabel else "font_size"
	var fs0: int = n.get_theme_font_size(key)
	if n is Label and n.autowrap_mode == TextServer.AUTOWRAP_OFF and not (n.get_parent() is Container):
		var tw0 := 0.0
		for line in n.text.split("\n"): tw0 = maxf(tw0, n.get_theme_font("font").get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs0).x)
		if n.size.x > tw0 + 4.0: n.set_meta("w0", n.size.x)
	var fs := int(round(fs0 * k))
	# 小字下限（手機）：至少 18
	if is_handheld(): fs = maxi(fs, int(18 * k))
	n.add_theme_font_size_override(key, fs)
	n.set_meta("fs_base", fs)
	# 加粗
	var fk := "normal_font" if n is RichTextLabel else "font"
	var f: Font = n.get_theme_font(fk)
	if f != null and k > 1.0:
		var emb := 0.35 if k < 1.3 else 0.6
		var ck := str(f.get_instance_id()) + ":" + str(emb)
		if not _bold_cache.has(ck):
			var fv := FontVariation.new(); fv.base_font = f; fv.variation_embolden = emb; _bold_cache[ck] = fv
		n.add_theme_font_override(fk, _bold_cache[ck])
	# 對比：淺色字加深描邊＋陰影，深色字再加深
	if n is Label or n is Button:
		var col: Color = n.get_theme_color("font_color")
		if col.get_luminance() > 0.45:
			n.add_theme_constant_override("outline_size", maxi(n.get_theme_constant("outline_size"), int(round(4 * k))))
			var oc: Color = n.get_theme_color("font_outline_color"); oc.a = maxf(oc.a, 0.9)
			if oc.get_luminance() > 0.3: oc = Color(0.05, 0.03, 0.02, 0.95)
			n.add_theme_color_override("font_outline_color", oc)
			if n is Label:
				n.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
				n.add_theme_constant_override("shadow_offset_x", int(2 * k)); n.add_theme_constant_override("shadow_offset_y", int(2 * k))
		elif k > 1.0:
			n.add_theme_color_override("font_color", col.darkened(0.35))
	if n is Button and not n.has_meta("keep_h"):
		var cms: Vector2 = n.custom_minimum_size
		var mh := 56.0 if is_handheld() else 0.0
		if cms != Vector2.ZERO or mh > 0.0: n.custom_minimum_size = Vector2(cms.x * (1.0 + (k - 1.0) * 0.3), maxf(cms.y * (1.0 + (k - 1.0) * 0.6), mh))
	_fit_text.call_deferred(n)

# 放大後若超出原本固定寬度（非容器配置）→ 縮回到剛好放得下，避免截斷
func _fit_text(n: Control) -> void:
	if not is_instance_valid(n) or not (n is Label): return
	var l := n as Label
	if l.autowrap_mode != TextServer.AUTOWRAP_OFF or l.get_parent() is Container: return
	if not l.has_meta("w0") or l.text == "": return
	var fs: int = l.get_meta("fs_base", 20)
	var f := l.get_theme_font("font")
	var w := 0.0
	for line in l.text.split("\n"): w = maxf(w, f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var avail: float = l.get_meta("w0")
	if w > avail and w > 0.0:
		l.add_theme_font_size_override("font_size", maxi(10, int(fs * avail / w)))
