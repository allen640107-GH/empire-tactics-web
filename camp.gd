extends Control
# 營地／世界地圖：標題、出擊、商店、隊伍裝備、存檔、結局
var font: FontFile
var page: Control
var info: Label
var sfxp: AudioStreamPlayer
var bgm: AudioStreamPlayer
var vop: AudioStreamPlayer
var bgm_key := ""
func music(key: String) -> void:
	if key == bgm_key: return
	var path := "res://assets/v15/bgm/%s.ogg" % key
	if not ResourceLoader.exists(path):
		if not bgm.playing: bgm.play()
		return
	bgm_key = key
	var nw := AudioStreamPlayer.new(); add_child(nw)
	var st: AudioStreamOggVorbis = load(path); st.loop = true
	nw.stream = st; nw.volume_db = -40.0; nw.play()
	var old := bgm; bgm = nw
	var tw := create_tween().set_parallel()
	tw.tween_property(nw, "volume_db", -9.0, 1.4)
	if old.playing: tw.tween_property(old, "volume_db", -50.0, 1.4)
	tw.chain().tween_callback(old.queue_free)
var shot_dir := ""
const MAP_OFS := Vector2(40, 90)

func _ready() -> void:
	font = load("res://assets/fonts/NotoSerifTC.ttf")
	var th := Theme.new(); th.default_font = font; th.default_font_size = 20
	for t in ["Button", "OptionButton"]:
		th.set_stylebox("normal", t, sbt("btn.png", 12, 4)); th.set_stylebox("hover", t, sbt("btn_hover.png", 12, 4))
		th.set_stylebox("pressed", t, sbt("btn_press.png", 12, 4)); th.set_stylebox("disabled", t, sbt("btn_dis.png", 12, 4))
		th.set_color("font_color", t, Color(0.25, 0.15, 0.06)); th.set_color("font_hover_color", t, Color(0.45, 0.2, 0.02))
		th.set_color("font_disabled_color", t, Color(0.45, 0.4, 0.35))
	theme = th
	set_anchors_preset(Control.PRESET_FULL_RECT)
	sfxp = AudioStreamPlayer.new(); add_child(sfxp)
	bgm = AudioStreamPlayer.new(); add_child(bgm)
	var s: AudioStreamWAV = load("res://assets/sfx/bgm.wav"); s.loop_mode = AudioStreamWAV.LOOP_FORWARD; s.loop_end = s.data.size() / 4
	bgm.stream = s; bgm.volume_db = -16.0; bgm.pitch_scale = 0.85
	vop = AudioStreamPlayer.new(); add_child(vop)
	if G.get_meta("autotest_ending", false):
		G.remove_meta("autotest_ending"); play_ending(func(): print("ENDING DONE"); get_tree().quit()); return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--campshots="): shot_dir = a.substr(12)
		if a == "--promoshots": promo_shots = true
		if a == "--savetest": save_test(); return
		if a == "--endingtest": G.test_mode = true; play_ending(func(): print("ENDING DONE"); get_tree().quit()); return
		if a == "--savetest21": save_test21(); return
		if a.begins_with("--savetest23="): save_test23(a.substr(13)); return
		if a == "--saveshots": save_shots(); return
		if a.begins_with("--titledemo"): demo = a.substr(12) if a.length() > 12 else "title"
		if a == "--autotest" or a == "--touchtest" or a.begins_with("--battle="):
			get_tree().change_scene_to_file.call_deferred("res://main.tscn"); return
	if shot_dir != "": run_shots(); return
	if G.get_meta("in_campaign", false): show_camp()
	else: show_title()

func sbt(n: String, m: int, pad := 6) -> StyleBoxTexture:
	var s := StyleBoxTexture.new(); s.texture = load("res://assets/ui/" + n)
	s.texture_margin_left = m; s.texture_margin_right = m; s.texture_margin_top = m; s.texture_margin_bottom = m
	s.content_margin_left = m + pad; s.content_margin_right = m + pad; s.content_margin_top = m + pad - 4; s.content_margin_bottom = m + pad - 4
	return s

func click() -> void:
	sfxp.stream = load("res://assets/sfx/click.wav"); sfxp.play()

func lbl(t: String, size := 20, col := Color(0.28, 0.17, 0.08)) -> Label:
	var l := Label.new(); l.text = t; l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func btn(t: String, cb: Callable, w := 180) -> Button:
	var b := Button.new(); b.text = t; b.custom_minimum_size = Vector2(w, 44)
	b.pressed.connect(func(): click(); cb.call())
	# v17：懸停放大＋手指游標
	b.mouse_entered.connect(func(): hover_fx(b)); b.focus_entered.connect(func(): hover_fx(b))
	b.mouse_exited.connect(func(): if is_instance_valid(b): b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.1))
	return b

var hand: TextureRect
func hover_fx(b: Control) -> void:
	if b is Button and b.disabled: return
	b.pivot_offset = b.size * 0.5
	b.create_tween().tween_property(b, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if hand == null or not is_instance_valid(hand):
		hand = TextureRect.new(); hand.texture = load("res://assets/v15/cursor.png"); hand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hand.size = Vector2(40, 30); hand.mouse_filter = Control.MOUSE_FILTER_IGNORE; hand.z_index = 50; add_child(hand)
	hand.visible = true; hand.move_to_front()
	hand.position = Vector2(b.global_position.x - 38, b.global_position.y + b.size.y * 0.5 - 15)
	var ht := hand.create_tween(); ht.tween_property(hand, "position:x", hand.position.x - 6, 0.12); ht.tween_property(hand, "position:x", hand.position.x, 0.12)

func icon_of(nm: String) -> String:
	for d in [G.W, G.A, G.I]:
		if d.has(nm): return str(d[nm].get("icon", ""))
	return ""

func header(t: String) -> void:
	# v17：金邊標題列
	var bar := ColorRect.new(); bar.position = Vector2(0, 14); bar.size = Vector2(1600, 52); bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new(); g.set_color(0, Color(0.25, 0.06, 0.03, 0.0)); g.set_color(1, Color(0.25, 0.06, 0.03, 0.0)); g.add_point(0.15, Color(0.3, 0.08, 0.04, 0.85)); g.add_point(0.7, Color(0.2, 0.05, 0.03, 0.6))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.width = 256; gt.height = 4
	var tr := TextureRect.new(); tr.texture = gt; tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.position = bar.position; tr.size = bar.size; tr.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(tr)
	for y in [14, 65]:
		var ln := ColorRect.new(); ln.color = Color(0.85, 0.66, 0.3, 0.8); ln.position = Vector2(20, y); ln.size = Vector2(1100, 2); ln.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(ln)
	var l := lbl(t, 28, Color(1, 0.86, 0.55)); l.position = Vector2(40, 20)
	l.add_theme_color_override("font_outline_color", Color(0.15, 0.03, 0.01)); l.add_theme_constant_override("outline_size", 6); page.add_child(l)

func panel(pos: Vector2, size: Vector2) -> PanelContainer:
	var p := PanelContainer.new(); p.position = pos; p.size = size
	p.add_theme_stylebox_override("panel", sbt("panel.png", 16, 6))
	var sh := Panel.new(); var ss := StyleBoxFlat.new(); ss.bg_color = Color(0, 0, 0, 0.0); ss.shadow_color = Color(0, 0, 0, 0.5); ss.shadow_size = 14; ss.shadow_offset = Vector2(5, 7)
	sh.add_theme_stylebox_override("panel", ss); sh.position = pos + Vector2(8, 8); sh.size = size - Vector2(16, 16); sh.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(sh)
	page.add_child(p); return p

func new_page() -> void:
	if page: page.queue_free()
	page = Control.new(); page.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(page)
	var bg := ColorRect.new(); bg.color = Color(0.1, 0.08, 0.06); bg.set_anchors_preset(Control.PRESET_FULL_RECT); page.add_child(bg)
	# v17：暗化插畫背景＋暈影＋浮游光點＋淡入
	var art := TextureRect.new(); art.texture = load("res://assets/v15/title_bg.jpg"); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT); art.modulate = Color(0.32, 0.26, 0.22); art.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(art)
	var vg := ColorRect.new(); vg.set_anchors_preset(Control.PRESET_FULL_RECT); vg.mouse_filter = Control.MOUSE_FILTER_IGNORE; vg.material = FX.mat(FX.VIG); page.add_child(vg)
	page.add_child(particles(30, 6.0, Vector2(800, 900), Vector2(800, 20), Vector2(10, 30), Color(1, 0.75, 0.4, 0.5), Vector2(0.05, 0.14), Vector2(0, -4), 30.0))
	page.modulate.a = 0.0; page.create_tween().tween_property(page, "modulate:a", 1.0, 0.25)
	if hand != null and is_instance_valid(hand): hand.visible = false

# ---------- 標題（v15：帝國史詩風） ----------
const FX := preload("res://v15fx.gd")
var wk: FontFile
var t_nodes := {}
var t_time := 0.0
var t_busy := false
var demo := ""
var pro_on := false
var pro_click := false
var pro_skip := false

func wkf() -> FontFile:
	if wk == null:
		wk = load("res://assets/fonts/WenKaiTC.ttf"); wk.fallbacks = [font]
	return wk

func tl(t: String, size: int, col: Color, f: Font = null) -> Label:
	var l := lbl(t, size, col); l.add_theme_font_override("font", f if f else wkf()); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func glow_lbl(l: Label, c := Color(1.0, 0.7, 0.3, 0.25), r := 12) -> Label:
	l.add_theme_color_override("font_shadow_color", c); l.add_theme_constant_override("shadow_outline_size", r)
	l.add_theme_constant_override("shadow_offset_x", 0); l.add_theme_constant_override("shadow_offset_y", 0)
	return l

func fader(a0: float) -> ColorRect:
	var f := ColorRect.new(); f.color = Color(0, 0, 0, a0); f.set_anchors_preset(Control.PRESET_FULL_RECT); f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(f); return f

func particles(amount: int, life: float, pos: Vector2, ext: Vector2, vel: Vector2, col: Color, sc: Vector2, grav := Vector2.ZERO, spread := 25.0) -> CPUParticles2D:
	var p := CPUParticles2D.new(); p.amount = amount; p.lifetime = life; p.position = pos; p.preprocess = life
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE; p.emission_rect_extents = ext
	p.texture = load("res://assets/v15/mote.png"); p.direction = Vector2(0, -1); p.spread = spread
	p.initial_velocity_min = vel.x; p.initial_velocity_max = vel.y; p.gravity = grav
	p.scale_amount_min = sc.x; p.scale_amount_max = sc.y
	var g := Gradient.new(); g.set_color(0, Color(col, 0.0)); g.set_color(1, Color(col, 0.0)); g.add_point(0.2, col); g.add_point(0.75, Color(col, col.a * 0.6))
	p.color_ramp = g
	var m := CanvasItemMaterial.new(); m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD; p.material = m
	p.hue_variation_min = -0.03; p.hue_variation_max = 0.03
	return p

func show_title() -> void:
	music("title")
	new_page(); t_busy = false; t_nodes = {}; t_time = 0.0
	var bg := TextureRect.new(); bg.texture = load("res://assets/v15/title_bg.jpg"); bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE; bg.size = Vector2(1720, 968); bg.position = Vector2(-60, -34); bg.material = FX.mat(FX.BG)
	page.add_child(bg); t_nodes.bg = bg
	var clouds := Control.new(); clouds.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(clouds); t_nodes.clouds = clouds
	for i in 6:
		var c := TextureRect.new(); c.texture = load("res://assets/v12/cloud.png"); c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.size = Vector2(520, 200) * (0.7 + 0.12 * i); c.position = Vector2(-300 + i * 360, 20 + (i * 53) % 180)
		c.modulate = Color(1.0, 0.82, 0.6, 0.16 + 0.03 * (i % 3)); c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.set_meta("v", 6.0 + 4.0 * (i % 3)); clouds.add_child(c)
	var rays := ColorRect.new(); rays.set_anchors_preset(Control.PRESET_FULL_RECT); rays.material = FX.mat(FX.RAYS); rays.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(rays)
	page.add_child(particles(46, 9.0, Vector2(800, 470), Vector2(820, 460), Vector2(4, 14), Color(1.0, 0.86, 0.55, 0.55), Vector2(0.10, 0.32), Vector2(3, -2), 180.0))
	page.add_child(particles(70, 7.0, Vector2(800, 930), Vector2(860, 20), Vector2(30, 75), Color(1.0, 0.55, 0.2, 0.9), Vector2(0.05, 0.14), Vector2(6, -8)))
	var vig := ColorRect.new(); vig.set_anchors_preset(Control.PRESET_FULL_RECT); vig.material = FX.mat(FX.VIG); vig.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(vig)
	# 兩側金陽旗（懸掛於金色橫桿，飄動）
	var bn := Control.new(); bn.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(bn); t_nodes.banners = bn
	for x in [70.0, 1600.0 - 70.0 - 150.0]:
		var f := TextureRect.new(); f.texture = load("res://assets/v15/banner.png"); f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		f.size = Vector2(150, 527); f.position = Vector2(x, -6); f.material = FX.mat(FX.BANNER); f.mouse_filter = Control.MOUSE_FILTER_IGNORE; bn.add_child(f)
		var rod := ColorRect.new(); rod.color = Color(0.62, 0.45, 0.2); rod.position = Vector2(x - 14, -4); rod.size = Vector2(178, 9); bn.add_child(rod)
		for e in [x - 20, x + 158]:
			var k := ColorRect.new(); k.color = Color(0.9, 0.75, 0.4); k.position = Vector2(e, -8); k.size = Vector2(12, 16); bn.add_child(k)
	# 標誌
	var n_items := 5 + int(G.game_cleared())
	var tbh: float = 48.0 + 14.0 * G.font_k()
	var fr_h: float = 70.0 + (tbh + 6.0) * n_items
	var logo := Control.new(); logo.position = Vector2(0, 96 - maxf(0.0, fr_h - 400.0) * 0.45); logo.size = Vector2(1600, 320); logo.pivot_offset = Vector2(800, 120); logo.mouse_filter = Control.MOUSE_FILTER_IGNORE; logo.set_meta("no_fix", true); page.add_child(logo); t_nodes.logo = logo
	var fv := FontVariation.new(); fv.base_font = wkf(); fv.spacing_glyph = 22
	var halo := tl("帝國戰記", 150, Color(0, 0, 0, 0), fv); halo.size = Vector2(1600, 190); glow_lbl(halo, Color(1.0, 0.62, 0.22, 0.22), 30); logo.add_child(halo); t_nodes.halo = halo
	var sh := tl("帝國戰記", 150, Color(0.14, 0.06, 0.02, 0.95), fv); sh.size = Vector2(1600, 190); sh.position = Vector2(3, 4)
	sh.add_theme_constant_override("outline_size", 4); sh.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.02, 0.9)); logo.add_child(sh)
	var gl := tl("帝國戰記", 150, Color.WHITE, fv); gl.size = Vector2(1600, 190); gl.material = FX.mat(FX.GOLD); gl.add_theme_constant_override("outline_size", 3); gl.add_theme_color_override("font_outline_color", Color(0.22, 0.09, 0.02, 1.0)); logo.add_child(gl)
	var en := tl("E M P I R E   C H R O N I C L E", 24, Color(0.93, 0.8, 0.52), font); en.size = Vector2(1600, 30); en.position = Vector2(0, 196); glow_lbl(en, Color(0, 0, 0, 0.7), 8); logo.add_child(en)
	var dv := TextureRect.new(); dv.texture = load("res://assets/v15/divider.png"); dv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; dv.size = Vector2(760, 38); dv.position = Vector2(420, 226); logo.add_child(dv)
	var sub := tl("── 金陽旗的歸途 ──", 38 if G.is_handheld() else 34, Color(0.97, 0.9, 0.74)); sub.size = Vector2(1600, 44); sub.position = Vector2(0, 262); glow_lbl(sub, Color(0, 0, 0, 0.75), 10); logo.add_child(sub)
	# 選單
	var fr := NinePatchRect.new(); fr.texture = load("res://assets/v15/menu_frame.png"); fr.patch_margin_left = 44; fr.patch_margin_right = 44; fr.patch_margin_top = 44; fr.patch_margin_bottom = 44
	var fr_y: float = 850.0 - fr_h; fr.size = Vector2(480, fr_h); fr.position = Vector2(570, fr_y); fr.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(fr); t_nodes.menu = fr
	var v := VBoxContainer.new(); v.position = Vector2(40, 30); v.size = Vector2(400, fr_h - 60.0); v.alignment = BoxContainer.ALIGNMENT_CENTER; v.add_theme_constant_override("separation", 6); fr.add_child(v)
	var glow := StyleBoxTexture.new(); glow.texture = load("res://assets/v15/sel_glow.png")
	var items := [["新的旅程", func(): G.backup_auto(); G.new_game(); G.set_meta("in_campaign", true); show_prologue()],
		["繼續征途", func():
			if G.load_game(): G.cur_battle = mini(G.progress, G.BATTLES.size() - 1); G.set_meta("in_campaign", true); show_camp()],
		["存檔管理", func(): show_saves(false)],
		["字體大小：" + G.FONT_LEVEL_NAMES[G.font_level], func(): G.cycle_font_level(); show_title()]]
	var cleared := G.game_cleared()
	if cleared: items.append(["回放破關動畫", func(): play_ending(func(): show_title())])
	items.append(["離開", func(): get_tree().quit()])
	var btns := []
	for it in items:
		var b := Button.new(); b.text = it[0]; b.custom_minimum_size = Vector2(400, tbh); b.set_meta("keep_h", true)
		b.add_theme_font_override("font", wkf()); b.add_theme_font_size_override("font_size", 28)
		for st in ["normal", "disabled"]: b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		for st in ["hover", "focus", "pressed", "hover_pressed"]: b.add_theme_stylebox_override(st, glow)
		b.add_theme_color_override("font_color", Color(0.9, 0.82, 0.64)); b.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.78))
		b.add_theme_color_override("font_focus_color", Color(1.0, 0.95, 0.78)); b.add_theme_color_override("font_pressed_color", Color(1, 1, 0.9))
		b.add_theme_color_override("font_disabled_color", Color(0.48, 0.42, 0.34)); b.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02)); b.add_theme_constant_override("outline_size", 5)
		var cb: Callable = it[1]
		b.mouse_entered.connect(func(): if not b.disabled: b.grab_focus())
		b.focus_entered.connect(func(): t_nodes.sel = b; if t_time > 1.0: tick())
		b.pressed.connect(func(): title_pick(b, cb))
		v.add_child(b); btns.append(b)
	btns[1].disabled = not G.has_save()
	if btns[1].disabled: btns[1].focus_mode = Control.FOCUS_NONE
	t_nodes.btns = btns
	if cleared:
		var ck := tl("★ 通關 ★", 30, Color(1.0, 0.85, 0.35), wkf()); ck.size = Vector2(300, 44); ck.position = Vector2(1180, 330); ck.rotation = -0.12
		ck.add_theme_constant_override("outline_size", 8); ck.add_theme_color_override("font_outline_color", Color(0.35, 0.1, 0.02)); glow_lbl(ck, Color(1, 0.7, 0.2, 0.5), 14); logo.add_child(ck)
	if G.migrate_msg != "":
		var mm := tl(G.migrate_msg, 20, Color(0.7, 1.0, 0.7)); mm.size = Vector2(1600, 30); mm.position = Vector2(0, 20); glow_lbl(mm, Color(0, 0, 0, 0.8), 6); page.add_child(mm)
	var cur := TextureRect.new(); cur.texture = load("res://assets/v15/cursor.png"); cur.size = Vector2(48, 36); cur.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; cur.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(cur); t_nodes.cur = cur
	var hint := tl("↑↓ 或滑鼠選擇　　Enter／點擊 決定", 18, Color(0.85, 0.75, 0.55, 0.8)); hint.size = Vector2(1600, 26); hint.position = Vector2(0, 852); glow_lbl(hint, Color(0, 0, 0, 0.8), 6); page.add_child(hint); t_nodes.hint = hint
	var ver := lbl("v22　©金陽旗工作室", 15, Color(0.8, 0.7, 0.5, 0.6)); ver.position = Vector2(1400, 866); page.add_child(ver)
	# 進場：黑幕淡出、標誌浮現、選單滑入
	var f := fader(1.0)
	logo.modulate.a = 0.0; logo.scale = Vector2(1.06, 1.06); fr.modulate.a = 0.0; fr.position.y = fr_y + 40; cur.modulate.a = 0.0; hint.modulate.a = 0.0
	var tw := create_tween(); tw.tween_property(f, "color:a", 0.0, 1.8).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(logo, "modulate:a", 1.0, 2.0).set_delay(0.6)
	tw.parallel().tween_property(logo, "scale", Vector2.ONE, 2.6).set_delay(0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(fr, "modulate:a", 1.0, 1.0).set_delay(1.9)
	tw.parallel().tween_property(fr, "position:y", fr_y, 1.0).set_delay(1.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(cur, "modulate:a", 1.0, 0.6).set_delay(2.6)
	tw.parallel().tween_property(hint, "modulate:a", 1.0, 0.8).set_delay(2.8)
	tw.tween_callback(func(): if is_instance_valid(f): f.queue_free())
	btns[0].grab_focus.call_deferred()
	t_nodes.sel = btns[0]
	if demo != "": title_demo()

func tick() -> void:
	sfxp.stream = load("res://assets/sfx/step.wav"); sfxp.volume_db = -8.0; sfxp.play()

func title_pick(b: Button, cb: Callable) -> void:
	if t_busy: return
	t_busy = true; click()
	var tw := create_tween(); tw.tween_property(b, "modulate", Color(2.0, 1.7, 1.2), 0.12); tw.tween_property(b, "modulate", Color.WHITE, 0.3)
	var f := fader(0.0); var tw2 := create_tween(); tw2.tween_property(f, "color:a", 1.0, 1.1).set_delay(0.25)
	await tw2.finished
	cb.call()

func title_demo() -> void:
	await get_tree().create_timer(4.5).timeout
	if not is_instance_valid(t_nodes.get("btns", [null])[0]): return
	t_nodes.btns[-1].grab_focus(); await get_tree().create_timer(1.4).timeout
	t_nodes.btns[0].grab_focus(); await get_tree().create_timer(1.6).timeout
	t_nodes.btns[0].pressed.emit()

func _process(d: float) -> void:
	if t_nodes.has("bg") and is_instance_valid(t_nodes.bg):
		t_time += d
		var m := get_viewport().get_mouse_position() / Vector2(1600, 900) - Vector2(0.5, 0.5)
		if demo != "": m = Vector2(sin(t_time * 0.3), cos(t_time * 0.23)) * 0.3
		var drift := Vector2(sin(t_time * 0.07) * 18.0, sin(t_time * 0.05) * 8.0)
		t_nodes.bg.position = t_nodes.bg.position.lerp(Vector2(-60, -34) + drift - m * 30.0, minf(1.0, d * 3.0))
		t_nodes.banners.position = t_nodes.banners.position.lerp(-m * 14.0, minf(1.0, d * 3.0))
		for c in t_nodes.clouds.get_children():
			c.position.x += c.get_meta("v") * d
			if c.position.x > 1700: c.position.x = -700
		t_nodes.halo.modulate.a = 0.7 + 0.3 * sin(t_time * 1.3)
		var s = t_nodes.get("sel")
		if s and is_instance_valid(s):
			var tgt: Vector2 = s.global_position + Vector2(30 + sin(t_time * 6.0) * 6.0, 10)
			t_nodes.cur.position = t_nodes.cur.position.lerp(tgt, minf(1.0, d * 14.0)) if t_time > 0.3 else tgt

# ---------- 序章（v15：編年史式逐行浮現） ----------
const PRO := [
	["帝國曆三一七年　・　瓦爾坎帝國", "res://assets/v15/pro_1.jpg", Vector2(0.0, 0.0), Vector2(-90, -30),
		["瓦爾坎帝國高舉《統一法典》，", "十年之間，七邦盡入版圖。"]],
	["帝國曆三一四年　・　帝都廣場", "res://assets/v15/pro_2.jpg", Vector2(-80, -20), Vector2(0, -40),
		["三年前，洛薩里亞公國以叛逆之名見廢，", "末代公爵受刑於帝都廣場，", "金陽旗自此委於塵土。"]],
	["北境　・　霜松林", "res://assets/v15/pro_3.jpg", Vector2(-100, -40), Vector2(0, 0),
		["此後，帝國糧車晝夜不絕，輾過北境的泥濘；", "舊公國的子民，在重稅與徵兵之下噤聲無言。"]],
	["帝國曆三一七年　秋　・　灰石關外", "res://assets/v15/pro_4.jpg", Vector2(0, -50), Vector2(-80, 0),
		["直至今夜——", "灰石關外的山丘上，一面早已被禁的藍底金陽旗，", "再度迎風升起。"]],
]

func pro_wait(sec: float) -> bool:
	pro_click = false; var t := 0.0
	while t < sec and not pro_click and not pro_skip:
		await get_tree().process_frame; t += get_process_delta_time()
	var c := pro_click; pro_click = false; return c

func pro_anim(tw: Tween) -> void:
	pro_click = false
	while tw.is_valid() and tw.is_running() and not pro_skip:
		if pro_click: tw.custom_step(60.0); break
		await get_tree().process_frame
	pro_click = false

func _input(e: InputEvent) -> void:
	if not pro_on: return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if t_nodes.has("skip") and is_instance_valid(t_nodes.skip) and t_nodes.skip.get_global_rect().has_point(e.position): return
		pro_click = true; get_viewport().set_input_as_handled()
	elif e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_ESCAPE: pro_skip = true
		elif e.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]: pro_click = true
		get_viewport().set_input_as_handled()

func show_prologue() -> void:
	new_page(); t_nodes = {}; pro_on = true; pro_skip = false; pro_click = false
	var imgs := []
	for i in 2:
		var tr := TextureRect.new(); tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.size = Vector2(1760, 990); tr.modulate.a = 0.0; tr.material = FX.mat(FX.PAINT); tr.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(tr); imgs.append(tr)
	page.add_child(particles(40, 10.0, Vector2(800, 450), Vector2(820, 460), Vector2(3, 10), Color(1.0, 0.85, 0.6, 0.35), Vector2(0.06, 0.2), Vector2(4, -1), 180.0))
	var vig := ColorRect.new(); vig.set_anchors_preset(Control.PRESET_FULL_RECT); vig.material = FX.mat(FX.VIG); vig.material.set_shader_parameter("amt", 0.95)
	vig.material.set_shader_parameter("tint", Color(0.02, 0.012, 0.005)); vig.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(vig)
	var gb := TextureRect.new(); var gt := GradientTexture2D.new(); var gg := Gradient.new(); gg.set_color(0, Color(0, 0, 0, 0)); gg.set_color(1, Color(0.02, 0.01, 0.0, 0.88))
	gt.gradient = gg; gt.fill_from = Vector2(0, 0); gt.fill_to = Vector2(0, 1); gt.width = 4; gt.height = 256; gb.texture = gt
	gb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; gb.position = Vector2(0, 470); gb.size = Vector2(1600, 430); gb.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(gb)
	var head := Control.new(); head.size = Vector2(1600, 120); head.position = Vector2(0, 52); head.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(head)
	var hl := tl("", 34, Color(0.96, 0.84, 0.55)); hl.size = Vector2(1600, 48); glow_lbl(hl, Color(0, 0, 0, 0.85), 12); head.add_child(hl)
	var dv := TextureRect.new(); dv.texture = load("res://assets/v15/divider.png"); dv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; dv.size = Vector2(640, 32); dv.position = Vector2(480, 52); head.add_child(dv)
	var box := Control.new(); box.position = Vector2(0, 600); box.size = Vector2(1600, 260); box.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(box)
	var sk := Button.new(); sk.text = "略過序章 ▶▶"; sk.position = Vector2(1400, 30); sk.size = Vector2(170, 46); sk.add_theme_font_override("font", wkf())
	sk.pressed.connect(func(): pro_skip = true); sk.modulate.a = 0.75; page.add_child(sk); t_nodes.skip = sk
	var hint := tl("點擊／Enter：下一行　　Esc：略過", 16, Color(0.8, 0.72, 0.55, 0.6)); hint.size = Vector2(1600, 24); hint.position = Vector2(0, 868); page.add_child(hint)
	var f := fader(1.0); var tw0 := create_tween(); tw0.tween_property(f, "color:a", 0.0, 1.6); 
	head.modulate.a = 0.0
	var cur := 0
	for si in PRO.size():
		if pro_skip: break
		var sc: Array = PRO[si]; var img: TextureRect = imgs[cur]; var old: TextureRect = imgs[1 - cur]; cur = 1 - cur
		img.texture = load(sc[1]); var p0: Vector2 = sc[2]; var p1: Vector2 = sc[3]
		img.position = p0; img.scale = Vector2(1.0, 1.0); page.move_child(img, 2); 
		var lines: Array = sc[4]
		var dur := 6.0 + lines.size() * 4.2
		var kb := create_tween().set_parallel(); kb.tween_property(img, "position", p1, dur + 3.0).set_trans(Tween.TRANS_SINE)
		kb.tween_property(img, "scale", Vector2(1.05, 1.05), dur + 3.0).set_trans(Tween.TRANS_SINE)
		var cf := create_tween().set_parallel(); cf.tween_property(img, "modulate:a", 1.0, 2.2).set_trans(Tween.TRANS_SINE)
		cf.tween_property(old, "modulate:a", 0.0, 2.2).set_trans(Tween.TRANS_SINE)
		hl.text = sc[0]
		var ht := create_tween(); ht.tween_property(head, "modulate:a", 1.0, 1.6).set_delay(0.8)
		await pro_anim(ht)
		var y := 0.0
		for ln in lines:
			if pro_skip: break
			var l := tl(ln, 36, Color(0.97, 0.91, 0.74)); l.size = Vector2(1600, 50); glow_lbl(l, Color(1.0, 0.66, 0.28, 0.24), 14)
			l.add_theme_constant_override("outline_size", 6); l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.01, 0.75))
			l.position = Vector2(0, y + 22); l.modulate.a = 0.0; box.add_child(l)
			var lt := create_tween().set_parallel(); lt.tween_property(l, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
			lt.tween_property(l, "position:y", y, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			await pro_anim(lt)
			await pro_wait(1.1 + ln.length() * 0.06)
			y += 62.0
		await pro_wait(2.4)
		var out := create_tween().set_parallel(); out.tween_property(box, "modulate:a", 0.0, 1.2); out.tween_property(head, "modulate:a", 0.0, 1.2)
		await pro_anim(out)
		for c in box.get_children(): c.queue_free()
		box.modulate.a = 1.0
	# 章名
	if not pro_skip:
		var f2 := fader(0.0); var ft := create_tween(); ft.tween_property(f2, "color:a", 1.0, 1.6); await pro_anim(ft)
		var c1 := tl("序　章", 28, Color(0.85, 0.72, 0.48)); c1.size = Vector2(1600, 40); c1.position = Vector2(0, 360); page.add_child(c1)
		var c2 := tl("霜松林的金陽", 64, Color.WHITE); c2.size = Vector2(1600, 90); c2.position = Vector2(0, 410); c2.material = FX.mat(FX.GOLD); c2.material.set_shader_parameter("h", 80.0); page.add_child(c2)
		var c3 := TextureRect.new(); c3.texture = load("res://assets/v15/divider.png"); c3.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; c3.size = Vector2(560, 30); c3.position = Vector2(520, 505); page.add_child(c3)
		for c in [c1, c2, c3]: c.modulate.a = 0.0
		var ct := create_tween().set_parallel(); for c in [c1, c2, c3]: ct.tween_property(c, "modulate:a", 1.0, 1.8)
		await pro_anim(ct); await pro_wait(2.6)
		var co := create_tween().set_parallel(); for c in [c1, c2, c3]: co.tween_property(c, "modulate:a", 0.0, 1.4)
		await pro_anim(co)
	else:
		var f3 := fader(0.0); var t3 := create_tween(); t3.tween_property(f3, "color:a", 1.0, 0.8); await t3.finished
	pro_on = false; G.set_meta("prologue_done", true)
	show_camp()
	var fi := fader(1.0); var ti := create_tween(); ti.tween_property(fi, "color:a", 0.0, 1.0); ti.tween_callback(fi.queue_free)
	if demo != "": camp_demo()

func camp_demo() -> void:
	await get_tree().create_timer(3.0).timeout
	if demo == "battle": go_battle()
	elif demo == "title": get_tree().quit()

# ---------- 營地／世界地圖 ----------
func show_camp() -> void:
	new_page()
	music("camp")
	if G.progress >= G.BATTLES.size():
		if not G.ending_seen and not G.test_mode:
			play_ending(func(): G.ending_seen = true; G.mark_game_cleared(); G.save_game(); show_ending())
		else: show_ending()
		return
	G.cur_battle = mini(G.progress, G.BATTLES.size() - 1)
	var head := lbl("營地　──　%s　第 %d／%d 戰　　軍資金 %d G　　遊玩時間 %s" % [G.chapter_of(G.cur_battle), G.cur_battle + 1, G.BATTLES.size(), G.gold, G.fmt_time(G.play_time)], 24, Color(0.95, 0.85, 0.6))
	head.position = Vector2(40, 30); page.add_child(head)
	var tr := TextureRect.new(); tr.texture = load("res://assets/ui/parchment.png"); tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.position = MAP_OFS - Vector2(20, 20); tr.size = Vector2(1080, 560); page.add_child(tr)
	var mp := Control.new(); mp.position = Vector2.ZERO; mp.size = Vector2(1600, 900); mp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp.draw.connect(func(): draw_map(mp)); page.add_child(mp)
	var tw := mp.create_tween().set_loops(); tw.tween_method(func(_x): mp.queue_redraw(), 0.0, 1.0, 1.0)
	for i in G.BATTLES.size():
		if i > G.progress: continue
		var b: Dictionary = G.BATTLES[i]
		var l := lbl(b.name, 15, Color(0.3, 0.15, 0.05) if i < G.progress else Color(0.6, 0.08, 0.05))
		l.position = MAP_OFS + Vector2(b.node[0], b.node[1]) + Vector2(-30, 14); page.add_child(l)
	# 右側：章節資訊
	var bd: Dictionary = G.battle_def(G.cur_battle)
	var p := panel(Vector2(1140, 80), Vector2(420, 560))
	var csc := ScrollContainer.new(); csc.custom_minimum_size = Vector2(380, 510); csc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; p.add_child(csc)
	var v := VBoxContainer.new(); v.size_flags_horizontal = Control.SIZE_EXPAND_FILL; v.add_theme_constant_override("separation", 8); csc.add_child(v)
	v.child_entered_tree.connect(func(c): if c is Label: c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; c.custom_minimum_size.x = 360)
	v.add_child(lbl(G.chapter_of(G.cur_battle), 20, Color(0.45, 0.25, 0.08)))
	v.add_child(lbl("下一戰：%s" % bd.name, 26, Color(0.5, 0.12, 0.05)))
	v.add_child(lbl("地點：%s" % bd.loc, 18))
	v.add_child(lbl("建議等級：Lv%d" % G.expected_lv(G.cur_battle), 18))
	var en := []
	for e in bd.enemies: en.append("%s×%d" % [e.t, int(e.n)])
	var el := lbl("敵軍：" + "、".join(en), 17); el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; el.custom_minimum_size = Vector2(380, 0); v.add_child(el)
	if bd.get("boss") != null: v.add_child(lbl("◆ 頭目：%s（%s）" % [bd.boss.name, bd.boss.title], 18, Color(0.55, 0.1, 0.35)))
	if bd.get("recruit") != null: v.add_child(lbl("★ 可能有新的夥伴……", 17, Color(0.15, 0.35, 0.15)))
	var pn := []
	for m in G.roster:
		if G.can_promote(m) > 0: pn.append(m.name)
	if str(G.last_result.get("legend", "")) != "": v.add_child(lbl("◆ 特殊劇情達成：獲得傳說「%s」！" % G.last_result.legend, 17, Color(0.5, 0.3, 0.0)))
	if str(G.last_result.get("summon", "")) != "": v.add_child(lbl("◆ 獲得「%s」！米菈可召喚水之召喚獸・利維坦" % G.SUMMON_ITEM, 17, Color(0.1, 0.35, 0.6)))
	if pn.size() > 0: v.add_child(lbl("★ 可晉升：%s（隊伍・裝備）" % "、".join(pn), 17, Color(0.6, 0.4, 0.05)))
	v.add_child(lbl(" ", 6))
	var party := []
	for m in G.roster: party.append("%s Lv%d" % [m.name, int(m.lv)])
	var pl := lbl("隊伍（%d 人）：\n" % G.roster.size() + "　".join(party), 17); pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; pl.custom_minimum_size = Vector2(380, 0); v.add_child(pl)
	if not G.last_result.is_empty():
		var lr := lbl("上一戰：%s　獲得 %d G　升級 %d 次" % ["勝利" if G.last_result.get("win", true) else "敗北", int(G.last_result.get("gold", 0)), int(G.last_result.get("lvups", 0))], 16, Color(0.35, 0.25, 0.15)); v.add_child(lr)
	var bot := VBoxContainer.new(); bot.position = Vector2(40, 670); bot.size = Vector2(1520, 0); bot.add_theme_constant_override("separation", 6); page.add_child(bot)
	bot.resized.connect(func(): bot.position.y = minf(670.0, 890.0 - bot.size.y))
	var hb := HFlowContainer.new(); hb.custom_minimum_size = Vector2(1520, 0); hb.add_theme_constant_override("h_separation", 12); hb.add_theme_constant_override("v_separation", 8); bot.add_child(hb)
	hb.add_child(btn("⚔ 出擊", func(): go_battle(), 200))
	hb.add_child(btn("商店", func(): show_shop(), 150))
	hb.add_child(btn("隊伍・裝備", func(): show_party(), 180))
	hb.add_child(btn("召喚獸", func(): show_summons(), 130))
	hb.add_child(btn("存檔", func(): G.save_game(); show_saves(true), 130))
	var vb := btn("語音 %d%%" % int(round(G.voice_vol * 100)), func(): pass, 140)
	vb.pressed.connect(func():
		var lv := [1.0, 0.7, 0.4, 0.0]; var i := 0
		for k in lv.size():
			if absf(lv[k] - G.voice_vol) < 0.05: i = (k + 1) % lv.size()
		G.voice_vol = lv[i]; G.save_settings(); vb.text = "語音 %d%%" % int(round(G.voice_vol * 100))
		var pv := "res://assets/v15/vo/hero_cry0.ogg"
		if G.voice_vol > 0.0 and ResourceLoader.exists(pv): vop.stream = load(pv); vop.volume_db = linear_to_db(G.voice_vol); vop.play())
	hb.add_child(vb)
	hb.add_child(btn("字體 " + G.FONT_LEVEL_NAMES[G.font_level], func(): G.cycle_font_level(); show_camp(), 130))
	hb.add_child(btn("標題畫面", func(): show_title(), 150))
	info = lbl("", 18, Color(0.95, 0.85, 0.6)); bot.add_child(info)
	var chap := []
	for i in G.progress: chap.append(G.BATTLES[i].name)
	if G.progress > 0:
		var h := HBoxContainer.new(); bot.add_child(h)
		h.add_child(lbl("重玩已通過的章節：", 17, Color(0.85, 0.75, 0.55)))
		var ob := OptionButton.new(); ob.custom_minimum_size = Vector2(240, 40)
		for c in chap: ob.add_item(c)
		h.add_child(ob)
		h.add_child(btn("出擊（重玩）", func(): G.cur_battle = ob.selected; go_battle(), 170))

func draw_map(c: Control) -> void:
	var tt := Time.get_ticks_msec() / 1000.0
	# 地形：海岸、山脈、河流
	var sea := PackedVector2Array()
	for i in 24: sea.append(MAP_OFS + Vector2(620 + i * 18, 470 + sin(i * 0.9) * 14))
	sea.append(MAP_OFS + Vector2(1060, 540)); sea.append(MAP_OFS + Vector2(620, 540))
	c.draw_colored_polygon(sea, Color(0.35, 0.5, 0.6, 0.45))
	for m in [Vector2(380, 230), Vector2(420, 260), Vector2(790, 260), Vector2(825, 280), Vector2(700, 110), Vector2(740, 120), Vector2(230, 120)]:
		var p: Vector2 = MAP_OFS + m
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(-22, 14), p + Vector2(0, -20), p + Vector2(22, 14)]), Color(0.45, 0.35, 0.25, 0.7))
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(-7, -8), p + Vector2(0, -20), p + Vector2(7, -8)]), Color(0.95, 0.95, 0.9, 0.8))
	for f in [Vector2(260, 200), Vector2(290, 215), Vector2(320, 160), Vector2(500, 260), Vector2(470, 210)]:
		c.draw_circle(MAP_OFS + f, 9, Color(0.25, 0.4, 0.2, 0.6))
	for i in G.BATTLES.size() - 1:
		var a: Vector2 = MAP_OFS + Vector2(G.BATTLES[i].node[0], G.BATTLES[i].node[1])
		var b: Vector2 = MAP_OFS + Vector2(G.BATTLES[i + 1].node[0], G.BATTLES[i + 1].node[1])
		if i < G.progress: c.draw_line(a, b, Color(0.55, 0.15, 0.05), 3.0)
		else: c.draw_dashed_line(a, b, Color(0.35, 0.25, 0.15, 0.6), 2.0, 8.0)
	for i in G.BATTLES.size():
		var bd: Dictionary = G.BATTLES[i]
		var p: Vector2 = MAP_OFS + Vector2(bd.node[0], bd.node[1])
		var boss: bool = bd.get("boss") != null
		var r := 11.0 if boss else 8.0
		if i < G.progress:
			c.draw_circle(p, r, Color(0.85, 0.65, 0.2)); c.draw_arc(p, r, 0, TAU, 24, Color(0.3, 0.15, 0.05), 2.0)
		elif i == G.progress:
			var pr := r + 4 + sin(tt * 4.0) * 3.0
			c.draw_circle(p, pr + 6, Color(0.9, 0.2, 0.1, 0.25)); c.draw_circle(p, r, Color(0.8, 0.1, 0.05)); c.draw_arc(p, r, 0, TAU, 24, Color(1, 0.9, 0.6), 2.0)
		else:
			c.draw_circle(p, r, Color(0.5, 0.45, 0.4, 0.7))
		if boss:
			var k: Vector2 = p + Vector2(0, -r - 10)
			c.draw_colored_polygon(PackedVector2Array([k + Vector2(-8, 5), k + Vector2(-8, -4), k + Vector2(-4, 0), k + Vector2(0, -7), k + Vector2(4, 0), k + Vector2(8, -4), k + Vector2(8, 5)]), Color(0.6, 0.15, 0.55) if i >= G.progress else Color(0.6, 0.45, 0.2))

func go_battle() -> void:
	G.set_meta("in_campaign", true)
	get_tree().change_scene_to_file("res://main.tscn")

# ---------- 商店 ----------
func desc(nm: String) -> String:
	if G.W.has(nm):
		var w: Dictionary = G.W[nm]
		return "%s［%s］攻%+d%s" % [nm, w.type, int(w.get("atk", 0)), tags(w)]
	if G.A.has(nm):
		var a: Dictionary = G.A[nm]
		return "%s［%s］防%+d%s" % [nm, a.type, int(a.get("def", 0)), tags(a)]
	return "%s：%s" % [nm, G.I[nm].get("desc", "")]

func tags(d: Dictionary) -> String:
	var t := []
	for k in ["hp", "mp", "atk", "mag", "spd", "move", "jump"]:
		if int(d.get(k, 0)) != 0 and not (k == "atk" and d.has("rmin")): t.append("%s%+d" % [{"hp":"HP","mp":"MP","atk":"攻","mag":"魔","spd":"速","move":"移","jump":"跳"}[k], int(d[k])])
	for k in ["drain", "poison", "crit", "pierce", "regen", "mpregen", "summon", "hit", "eva", "thorns", "heal", "nostun", "nopoison", "stun", "holy", "double", "endure"]:
		if int(d.get(k, 0)) != 0: t.append({"drain":"吸血","poison":"毒","crit":"會心","pierce":"穿透","regen":"再生","mpregen":"MP回復","summon":"召喚強化","hit":"命中","eva":"迴避","thorns":"反傷","heal":"治癒強化","nostun":"抗暈","nopoison":"抗毒","stun":"暈眩","holy":"對頭目","double":"連射","endure":"不屈"}[k])
	return (" " + "/".join(t)) if t.size() > 0 else ""

func who_can(nm: String) -> String:
	var o := []
	for m in G.roster:
		var kind := "weapon" if G.W.has(nm) else "armor"
		if G.can_equip(m.job, kind, nm, m.get("hero", false)): o.append(m.name)
	return ("可裝備：" + "、".join(o)) if o.size() > 0 else "（目前無人可裝備）"

func show_shop(tab := 0) -> void:
	new_page()
	header("商店　──　軍資金 %d G" % G.gold)
	var tabs := HBoxContainer.new(); tabs.position = Vector2(40, 76); page.add_child(tabs)
	var names := ["武器", "防具", "道具", "出售"]
	for i in 4: tabs.add_child(btn(names[i], func(): show_shop(i), 130)); tabs.get_child(i).disabled = i == tab
	tabs.add_child(btn("返回營地", func(): show_camp(), 160))
	var p := panel(Vector2(40, 130), Vector2(1520, 720))
	var sc := ScrollContainer.new(); sc.custom_minimum_size = Vector2(1490, 690); p.add_child(sc)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 4); sc.add_child(v)
	var list := []
	match tab:
		0: for k in G.shop_list(): if G.W.has(k): list.append(k)
		1: for k in G.shop_list(): if G.A.has(k): list.append(k)
		2: list = G.item_shop()
		3:
			for k in G.inv: list.append(k)
			for k in G.items: list.append(k)
	if list.is_empty(): v.add_child(lbl("（沒有可交易的物品）", 20))
	var zi := 0
	for nm in list:
		var row := PanelContainer.new(); var rs := StyleBoxFlat.new(); rs.bg_color = Color(0.55, 0.38, 0.16, 0.13 if zi % 2 == 0 else 0.0); rs.set_corner_radius_all(4); rs.content_margin_left = 6
		row.add_theme_stylebox_override("panel", rs); v.add_child(row); zi += 1
		var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 12); row.add_child(h)
		var ip := icon_of(nm)
		var ic := TextureRect.new(); ic.custom_minimum_size = Vector2(36, 36); ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ip != "" and ResourceLoader.exists(ip): ic.texture = load(ip)
		h.add_child(ic)
		var have: int = G.items.get(nm, 0) if G.I.has(nm) else G.inv.get(nm, 0)
		var l := lbl(desc(nm), 18); l.custom_minimum_size = Vector2(580, 0); l.clip_text = true; h.add_child(l)
		var l2 := lbl("" if G.I.has(nm) else who_can(nm), 15, Color(0.3, 0.3, 0.45)); l2.custom_minimum_size = Vector2(380, 0); l2.clip_text = true; h.add_child(l2)
		h.add_child(lbl("持有 %d" % have, 16))
		if tab == 3:
			h.add_child(btn("出售 %d G" % (G.price(nm) / 2), func(): G.sell(nm); show_shop(3), 170))
		else:
			var b := btn("購買 %d G" % G.price(nm), func():
				G.buy(nm); show_shop(tab), 170)
			b.disabled = G.gold < G.price(nm); h.add_child(b)

# ---------- 隊伍・裝備 ----------
func stat_line(m: Dictionary) -> String:
	var w: Dictionary = G.W[m.weapon]; var a: Dictionary = G.A[m.armor]; var b: Dictionary = m.base
	return "HP %d　MP %d　攻 %d　防 %d　魔 %d　速 %d　移 %d" % [int(b.hp) + int(w.get("hp", 0)) + int(a.get("hp", 0)), int(b.mp) + int(w.get("mp", 0)) + int(a.get("mp", 0)),
		int(b.atk) + int(w.get("atk", 0)), int(b.def) + int(a.get("def", 0)) + int(w.get("def", 0)), int(b.mag) + int(w.get("mag", 0)) + int(a.get("mag", 0)),
		int(b.spd) + int(w.get("spd", 0)) + int(a.get("spd", 0)), int(b.move) + int(w.get("move", 0)) + int(a.get("move", 0))]

func show_party() -> void:
	new_page()
	header("隊伍・裝備　──　%d 人" % G.roster.size())
	var bk := btn("返回營地", func(): show_camp(), 160); bk.position = Vector2(1380, 24); page.add_child(bk)
	var n: int = G.roster.size()
	var k := G.font_k()
	# v21 可讀性：可捲動清單，每人兩行（資料／裝備），大字不截斷
	var sc := ScrollContainer.new(); sc.position = Vector2(40, 84); sc.size = Vector2(1520, 800); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; page.add_child(sc)
	var list := VBoxContainer.new(); list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; list.add_theme_constant_override("separation", 8); sc.add_child(list)
	for i in n:
		var m: Dictionary = G.roster[i]
		var p := PanelContainer.new(); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.96, 0.91, 0.8); sb.border_color = Color(0.55, 0.4, 0.22); sb.set_border_width_all(2); sb.set_corner_radius_all(8); sb.set_content_margin_all(10); p.add_theme_stylebox_override("panel", sb)
		list.add_child(p)
		var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 14); p.add_child(h)
		var path := "res://assets/v12/p_%s.png" % m.key
		if ResourceLoader.exists(path):
			var tr := TextureRect.new(); tr.texture = load(path); tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.custom_minimum_size = Vector2(96, 96) * minf(k, 1.3); tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER; h.add_child(tr)
		var v := VBoxContainer.new(); v.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(v)
		var top := HBoxContainer.new(); top.add_theme_constant_override("separation", 16); v.add_child(top)
		var nm := lbl("%s　%s・%s　Lv%d　EXP %d/%d" % [m.name, G.cls_name(m), m.title, int(m.lv), int(m.exp), G.EXP_PER_LV], 19, Color(0.45, 0.12, 0.05)); nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(nm)
		var pt := G.can_promote(m)
		if pt > 0:
			var mm := m
			var pb := btn("★ %s" % ("晉升" if pt == 1 else "二轉"), func(): show_promote(mm), 120); pb.custom_minimum_size = Vector2(120, 34); pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER; top.add_child(pb)
		elif G.promo_need(m) != "":
			top.add_child(lbl(G.promo_need(m), 15, Color(0.35, 0.28, 0.2)))
		var st := lbl(stat_line(m), 16); st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(st)
		var eq := HBoxContainer.new(); eq.add_theme_constant_override("separation", 12); v.add_child(eq)
		for kind in ["weapon", "armor"]:
			var vv := HBoxContainer.new(); vv.size_flags_horizontal = Control.SIZE_EXPAND_FILL; eq.add_child(vv)
			var kl := lbl("武器" if kind == "weapon" else "防具", 16, Color(0.3, 0.22, 0.15)); kl.size_flags_vertical = Control.SIZE_SHRINK_CENTER; vv.add_child(kl)
			var ob := OptionButton.new(); ob.custom_minimum_size = Vector2(0, 38); ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL; ob.add_theme_font_size_override("font_size", 16); ob.clip_text = false
			var opts: Array = G.owned_list(m, kind)
			for o in opts:
				var ip := icon_of(o)
				if ip != "" and ResourceLoader.exists(ip): ob.add_icon_item(load(ip), desc(o))
				else: ob.add_item(desc(o))
			ob.add_theme_constant_override("icon_max_width", int(28 * k))
			ob.selected = 0
			ob.item_selected.connect(func(idx): G.swap_equip(m, kind, opts[idx]); show_party())
			vv.add_child(ob)
			var pm := ob.get_popup(); pm.add_theme_font_size_override("font_size", int(18 * k))

# ---------- 結局 ----------
func show_ending() -> void:
	new_page()
	var tr := TextureRect.new(); tr.texture = load("res://assets/ui/parchment.png"); tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.position = Vector2(250, 60); tr.size = Vector2(1100, 780); page.add_child(tr)
	var esc := ScrollContainer.new(); esc.position = Vector2(320, 100); esc.size = Vector2(960, 640); esc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; page.add_child(esc)
	var v := VBoxContainer.new(); v.size_flags_horizontal = Control.SIZE_EXPAND_FILL; v.add_theme_constant_override("separation", 12); esc.add_child(v)
	var et := lbl("終章　金陽旗的歸途", 40, Color(0.5, 0.12, 0.05)); et.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(et)
	var txt := ["法典巨像崩解，天穹王座上的光熄滅了。",
		"馬克西姆斯皇帝放下了劍，帝國的「統一法典」在這一天結束。",
		"雷恩沒有登上王座。他把金陽旗插在帝都的城牆上，然後回到了北境。",
		"加爾德重建了灰石關，薇格的赤狼成了自由的商隊護衛，",
		"歐蕾莉亞把聖殿的大門重新為所有人敞開。",
		"七個邦國的旗幟，再一次在風中並列。",
		" ",
		"── 全 %d 章通關 ──　遊玩時間 %s　隊伍 %d 人" % [G.BATTLES.size(), G.fmt_time(G.play_time), G.roster.size()],
		"感謝遊玩！素材來源請見 CREDITS.md"]
	for t in txt:
		var l := lbl(t, 22); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.custom_minimum_size = Vector2(920, 0); v.add_child(l)
		l.modulate.a = 0.0; create_tween().tween_property(l, "modulate:a", 1.0, 1.2).set_delay(txt.find(t) * 0.8)
	var h := HBoxContainer.new(); h.position = Vector2(330, 752); h.add_theme_constant_override("separation", 12); page.add_child(h)
	h.add_child(btn("回到標題", func(): G.set_meta("in_campaign", false); show_title(), 200))
	h.add_child(btn("回放破關動畫", func(): play_ending(func(): show_ending()), 220))
	h.add_child(btn("重玩章節", func(): G.progress = G.BATTLES.size(); show_replay(), 200))

func show_replay() -> void:
	G.progress = G.BATTLES.size() - 1; G.cur_battle = G.progress
	show_camp()

# ---------- 截圖（測試用） ----------
func snap(n: String) -> void:
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shot_dir + "/" + n + ".png")
	print("CAMPSHOT ", n)

func run_shots() -> void:
	G.test_mode = true
	G.setup_for_battle(10); G.last_result = {"win": true, "gold": 900, "lvups": 3}
	G.inv = {"秘銀劍": 1, "長劍": 2, "鎖子甲": 1}
	show_title(); await get_tree().create_timer(3.4).timeout; await snap("c01_title")
	show_camp(); await snap("c02_worldmap")
	show_shop(0); await get_tree().create_timer(0.3).timeout
	var bs := page.find_children("*", "Button", true, false)
	if bs.size() > 6: hover_fx(bs[6])
	await snap("c03_shop_weapon")
	show_shop(2); await snap("c04_shop_item")
	show_party(); await snap("c05_party_equip")
	show_summons(); await get_tree().create_timer(0.6).timeout; await snap("c05b_summons")
	if promo_shots: await run_promo_shots(); return
	G.progress = G.BATTLES.size(); show_camp(); await get_tree().create_timer(8.0).timeout; await snap("c06_ending")
	print("CAMPSHOTS DONE"); get_tree().quit()

# ---------- v16：職業晉升 ----------
var promo_shots := false
func spr_frame(key: String, f: int) -> AtlasTexture:
	var tex: Texture2D = load("res://assets/v12/spr/%s.png" % key)
	var cell := float(tex.get_height()) / 2.0
	var at := AtlasTexture.new(); at.atlas = tex; at.region = Rect2(f * cell, 0, cell, cell)
	return at

func anim_rect(key: String, frames: Array, sz: float, fps := 6.0) -> TextureRect:
	var tr := TextureRect.new(); tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(sz, sz); tr.size = Vector2(sz, sz)
	var texs := []
	for f in frames: texs.append(spr_frame(key, f))
	tr.texture = texs[0]
	var tw := tr.create_tween().set_loops()
	tw.tween_method(func(x): tr.texture = texs[int(x) % texs.size()], 0.0, float(texs.size()) - 0.001, texs.size() / fps)
	return tr

func bonus_txt(b: Dictionary) -> String:
	var o := []
	var nm := {"hp": "HP", "mp": "MP", "atk": "攻", "def": "防", "mag": "魔", "spd": "速", "move": "移"}
	for k in b: o.append("%s+%d" % [nm.get(k, k), int(b[k])])
	return "　".join(o)

func skills_of(key: String, t: int) -> String:
	var src: Script = load("res://main.gd")
	var o := []
	for s in src.get_script_constant_map()["SPELLS"]:
		if s.get("cls", "") == key and int(s.t) == t: o.append("%s（MP%d）" % [s.n, int(s.mp)])
	return "、".join(o)

func show_promote(m: Dictionary) -> void:
	new_page()
	var t := G.can_promote(m)
	page.add_child(lbl("職業晉升　──　%s（%s　Lv%d）" % [m.name, G.cls_name(m), int(m.lv)], 28, Color(0.95, 0.85, 0.6))); page.get_child(-1).position = Vector2(40, 24)
	var bk := btn("返回", func(): show_party(), 160); bk.position = Vector2(1380, 24); page.add_child(bk)
	var brs := ["a", "b"] if t == 1 else [m.cls]
	var x0 := 160.0 if brs.size() == 2 else 520.0
	for i in brs.size():
		var br: String = brs[i]; var d: Array = G.PROMO[m.key][br]
		var p := panel(Vector2(x0 + i * 680, 100), Vector2(600, 720))
		var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 8); p.add_child(v)
		v.add_child(lbl(("%s" if t == 1 else "%s → " + d[1]) % d[0], 32, Color(0.5, 0.12, 0.05)))
		v.add_child(lbl(d[4], 17))
		var ar := anim_rect("%s_%s" % [m.key, br], [0, 1, 2, 3, 24, 25, 26, 27, 26, 25], 360.0); v.add_child(ar)
		v.add_child(lbl("能力加成：" + bonus_txt(d[1 + t]) + ("" if d[1 + t].has("mp") else "　MP+10"), 18, Color(0.2, 0.3, 0.1)))
		v.add_child(lbl("習得技能：" + skills_of("%s_%s" % [m.key, br], t), 18, Color(0.3, 0.15, 0.45)))
		if t == 1: v.add_child(lbl("二轉：%s（Lv%d＋%s）" % [d[1], G.PROMO_LV[1], G.KEY_ITEM], 15, Color(0.4, 0.35, 0.3)))
		var bb := btn("選擇此職業" if t == 1 else "進行二轉", func(): promo_ceremony(m, br), 260); v.add_child(bb)

func promo_ceremony(m: Dictionary, br: String) -> void:
	var old_name := G.cls_name(m)
	var bon := G.promote(m, br)
	if bon.is_empty(): show_party(); return
	if not G.test_mode: G.save_game()
	new_page()
	music("promote")
	sfxp.stream = load("res://assets/sfx/lvup_fanfare.wav"); sfxp.play()
	var bg := ColorRect.new(); bg.color = Color(0.03, 0.02, 0.06); bg.size = Vector2(1600, 900); page.add_child(bg)
	# 光柱
	var pil := TextureRect.new(); var gt := GradientTexture2D.new(); var gr := Gradient.new()
	gr.set_color(0, Color(1, 0.85, 0.4, 0.0)); gr.set_color(1, Color(1, 0.85, 0.4, 0.0)); gr.add_point(0.5, Color(1, 0.95, 0.7, 0.9))
	gt.gradient = gr; gt.width = 256; gt.height = 8; pil.texture = gt; pil.stretch_mode = TextureRect.STRETCH_SCALE
	pil.size = Vector2(10, 900); pil.position = Vector2(795, 0); page.add_child(pil)
	var tw := create_tween(); tw.tween_property(pil, "size:x", 420.0, 1.2).set_trans(Tween.TRANS_EXPO); tw.parallel().tween_property(pil, "position:x", 590.0, 1.2).set_trans(Tween.TRANS_EXPO)
	var cr := ColorRect.new(); cr.color = Color(1, 0.95, 0.75, 0.0); cr.size = Vector2(1600, 900); cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 魔法陣
	var ring := Control.new(); ring.position = Vector2(800, 700); page.add_child(ring)
	ring.draw.connect(func():
		for r in [150.0, 120.0, 90.0]: ring.draw_arc(Vector2.ZERO, r, 0, TAU, 64, Color(1, 0.8, 0.35, 0.7), 2.0)
		for i in 12:
			var a := i * TAU / 12.0; ring.draw_line(Vector2.from_angle(a) * 90.0, Vector2.from_angle(a + 0.5) * 150.0, Color(1, 0.85, 0.4, 0.6), 1.5))
	ring.scale = Vector2(1, 0.35)
	var rt := ring.create_tween().set_loops(); rt.tween_property(ring, "rotation", TAU, 8.0).from(0.0)
	# 光粒
	var pt := CPUParticles2D.new(); pt.position = Vector2(800, 760); pt.amount = 80; pt.lifetime = 3.0; pt.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	pt.emission_rect_extents = Vector2(200, 10); pt.direction = Vector2(0, -1); pt.spread = 10; pt.gravity = Vector2(0, -30); pt.initial_velocity_min = 60; pt.initial_velocity_max = 160
	pt.texture = load("res://assets/v15/mote.png"); pt.color = Color(1, 0.85, 0.45); pt.scale_amount_min = 0.3; pt.scale_amount_max = 0.8; page.add_child(pt)
	# 角色：舊→新
	var key := "%s_%s" % [m.key, br]
	var oldr := anim_rect(m.key, [0, 1, 2, 3], 460.0); oldr.position = Vector2(570, 330); page.add_child(oldr)
	var newr := anim_rect(key, [15, 16, 17, 18, 24, 25, 26, 27, 26, 25, 24, 0, 1, 2, 3, 2, 1], 460.0, 5.0); newr.position = Vector2(570, 330); newr.modulate.a = 0.0; page.add_child(newr)
	page.add_child(cr)
	var bn := TextureRect.new(); bn.texture = load("res://assets/v15/banner.png"); bn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bn.stretch_mode = TextureRect.STRETCH_SCALE; bn.size = Vector2(900, 120); bn.position = Vector2(350, 60); bn.modulate.a = 0.0; page.add_child(bn)
	var t1 := lbl("%s　晉升為「%s」！" % [m.name, G.cls_name(m)], 40, Color(0.98, 0.88, 0.55)); t1.position = Vector2(350, 85); t1.size = Vector2(900, 60)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; t1.modulate.a = 0.0; page.add_child(t1)
	var t2 := lbl("%s → %s\n%s\n習得：%s" % [old_name, G.cls_name(m), bonus_txt(bon), skills_of(key, int(m.tier))], 22, Color(0.95, 0.9, 0.75))
	var t2b := ColorRect.new(); t2b.color = Color(0.03, 0.02, 0.06, 0.75); t2b.position = Vector2(450, 190); t2b.size = Vector2(700, 118); t2b.modulate.a = 0.0; page.add_child(t2b); page.move_child(t2b, page.get_child_count() - 2)
	for L in [t1, t2]: L.add_theme_constant_override("outline_size", 6); L.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02))
	t2.position = Vector2(350, 196); t2.size = Vector2(900, 100); t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; t2.modulate.a = 0.0; page.add_child(t2)
	var s2 := create_tween()
	s2.tween_interval(1.4)
	s2.tween_property(cr, "color:a", 1.0, 0.25)
	s2.tween_callback(func(): oldr.visible = false; newr.modulate.a = 1.0)
	s2.tween_property(cr, "color:a", 0.0, 0.9)
	s2.tween_property(bn, "modulate:a", 1.0, 0.5); s2.parallel().tween_property(t1, "modulate:a", 1.0, 0.5)
	s2.tween_property(t2, "modulate:a", 1.0, 0.6); s2.parallel().tween_property(t2b, "modulate:a", 1.0, 0.6)
	var ok := btn("繼續", func(): show_party(), 200); ok.position = Vector2(700, 800); page.add_child(ok)

func run_promo_shots() -> void:
	G.setup_for_battle(10)
	for m in G.roster: m.tier = 0; m.cls = ""
	var m: Dictionary = G.roster[0]
	show_party(); await snap("p01_party_promotable")
	show_promote(m); await snap("p02_choose_branch")
	promo_ceremony(m, "a"); await get_tree().create_timer(0.3).timeout; await snap("p03_ceremony_start")
	await get_tree().create_timer(3.4).timeout; await snap("p04_ceremony_done")
	var g: Dictionary = G.roster[1]
	G.promote(g, "a"); show_promote(g); await snap("p05_second_tier_choice")
	promo_ceremony(g, "a"); await get_tree().create_timer(3.8).timeout; await snap("p06_second_tier_done")
	show_party(); await snap("p07_party_after")
	print("PROMOSHOTS DONE")
	get_tree().quit()

func save_test() -> void:
	# 模擬 v15 舊存檔（v13 格式，無 tier/cls/keyitems）
	G.setup_for_battle(10)
	var d := G.save_dict(); d.v = 13; d.erase("keyitems")
	for m in d.roster: m.erase("tier"); m.erase("cls")
	var f := FileAccess.open("user://compat_test.json", FileAccess.WRITE); f.store_string(JSON.stringify(d)); f.close()
	var ok := G.load_game("user://compat_test.json")
	var o := []
	for m in G.roster: o.append("%s tier=%d cls=%s can=%d" % [m.name, m.tier, m.cls, G.can_promote(m)])
	print("SAVETEST load=", ok, " keyitems=", G.keyitems, " | ", "; ".join(o))
	G.promote(G.roster[0], "b"); G.promote(G.roster[0], "b"); G.save_game("user://compat_test.json"); G.load_game("user://compat_test.json")
	print("SAVETEST roundtrip ", G.roster[0].name, " ", G.cls_name(G.roster[0]), " tier=", G.roster[0].tier)
	get_tree().quit()

# ---------- v17：召喚獸圖鑑 ----------
func sheet_anim(path: String, grid: Vector2i, row: int, frames: int, sz: Vector2, fps := 7.0) -> TextureRect:
	var tex: Texture2D = load(path)
	var cw := float(tex.get_width()) / grid.x; var ch := float(tex.get_height()) / grid.y
	var texs := []
	for f in frames:
		var at := AtlasTexture.new(); at.atlas = tex; at.region = Rect2(f * cw, row * ch, cw, ch); texs.append(at)
	var tr := TextureRect.new(); tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = sz; tr.size = sz; tr.texture = texs[0]
	var tw := tr.create_tween().set_loops()
	tw.tween_method(func(x): tr.texture = texs[int(x) % texs.size()], 0.0, float(texs.size()) - 0.001, texs.size() / fps)
	return tr

func show_summons() -> void:
	new_page()
	var head := lbl("召喚獸　──　米菈締結的契約", 30, Color(0.95, 0.85, 0.6)); head.position = Vector2(40, 26); page.add_child(head)
	var has_mira := G.member("米菈") != null
	var defs := [
		{"n": "伊弗利特", "sub": "炎之魔神", "el": "火", "elc": Color(0.75, 0.2, 0.05), "img": "res://assets/v12/ifrit.png", "grid": Vector2i(6, 1), "row": 0, "fr": 2,
		 "sk": "地獄之焰", "cost": "MP24", "rng": "射程 4・半徑 2", "eff": "隕石雨＋大爆炸，對範圍內全部敵人造成高額火焰傷害。\n定位：攻擊・清場", "own": has_mira, "how": "米菈加入時即擁有"},
		{"n": "利維坦", "sub": "深海之王", "el": "水", "elc": Color(0.1, 0.35, 0.7), "img": "res://assets/v12/leviathan.png", "grid": Vector2i(8, 3), "row": 0, "fr": 8,
		 "sk": "大海嘯", "cost": "MP30", "rng": "射程 4・半徑 3", "eff": "巨浪橫掃：敵人受水屬性傷害（對火屬性 ×1.3）並 70% 緩速；\n我方回復 30% 最大 HP 並解除灼燒／中毒／冰封等異常。\n定位：支援・控制", "own": G.has_lev(), "how": "第5戰「港口夜戰」勝利後，於銀帆港海底取得「利維坦之契約」"},
		{"n": "亞達曼", "sub": "玄岳聖龜", "el": "地", "elc": Color(0.45, 0.3, 0.1), "img": "res://assets/v23/adamant.png", "grid": Vector2i(8, 3), "row": 0, "fr": 8,
		 "sk": "玄岳震", "cost": "MP28", "rng": "射程 4・半徑 2", "eff": "山岳落地：敵人受地屬性傷害並束縛；\n我方獲得岩盾（防禦提升）並回復 20% HP。\n定位：防禦・控制", "own": G.has_adam(), "how": "特殊劇情「沉睡的聖獸」（第12戰 熔岩礦坑）：米菈觸碰封印石並存活到勝利"}]
	for i in defs.size():
		var d: Dictionary = defs[i]
		var p := panel(Vector2(30 + i * 515, 90), Vector2(500, 660))
		var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 6); p.add_child(v)
		var h := HBoxContainer.new(); v.add_child(h)
		var nm := lbl(d.n if d.own else "？？？", 30, [Color(0.45, 0.1, 0.05), Color(0.05, 0.2, 0.45), Color(0.35, 0.22, 0.05)][i]); h.add_child(nm)
		h.add_child(lbl("　%s〔%s〕" % [d.sub, d.el], 18, d.elc))
		var art := sheet_anim(d.img, d.grid, d.row, d.fr, Vector2(470, 300), [6.0, 7.0, 6.5][i])
		if not d.own: art.modulate = Color(0, 0, 0, 0.75)
		v.add_child(art)
		if d.own:
			var sk := lbl("招式：「%s」　%s\n%s" % [d.sk, d.cost, d.rng], 18, Color(0.35, 0.12, 0.05)); sk.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY; sk.custom_minimum_size = Vector2(470, 0); v.add_child(sk)
			var e := lbl(d.eff, 17); e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; e.custom_minimum_size = Vector2(470, 0); v.add_child(e)
			var ok := lbl("✔ 已締結契約（%s）" % d.how, 15, Color(0.15, 0.4, 0.15)); ok.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY; ok.custom_minimum_size = Vector2(470, 0); v.add_child(ok)
		else:
			var e2 := lbl("尚未締結契約。\n取得方式：" + d.how, 18, Color(0.35, 0.3, 0.25)); e2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; e2.custom_minimum_size = Vector2(470, 0); v.add_child(e2)
	var hb := HBoxContainer.new(); hb.position = Vector2(40, 770); page.add_child(hb)
	hb.add_child(btn("返回營地", func(): show_camp(), 200))

# ================= v21：存檔管理（槽位／匯出／匯入） =================
var sv_box: TextEdit
var sv_msg: Label
func show_saves(in_game: bool) -> void:
	t_busy = false
	new_page()
	var head := lbl("存檔管理　──　換版本、換裝置都能接著玩", 30, Color(0.95, 0.85, 0.6)); head.position = Vector2(40, 22); page.add_child(head)
	var pn := panel(Vector2(30, 76), Vector2(1540, 420))
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 8); pn.add_child(v)
	for s in G.SLOTS:
		var inf: Dictionary = G.slot_info(s)
		if s == "backup" and inf.is_empty(): continue
		var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 10); v.add_child(h)
		var nl := lbl(G.SLOT_NAMES[s], 22, Color(0.45, 0.15, 0.05)); nl.custom_minimum_size = Vector2(190, 0); h.add_child(nl)
		var il := lbl(inf.get("text", "（空）"), 19); il.custom_minimum_size = Vector2(720, 0); h.add_child(il)
		var sp: String = G.slot_path(s)
		if not inf.is_empty():
			h.add_child(btn("讀取", func():
				if G.load_game(sp): G.cur_battle = mini(G.progress, G.BATTLES.size() - 1); G.set_meta("in_campaign", true); show_camp(), 100))
			h.add_child(btn("匯出存檔碼", func():
				var code: String = G.export_code(G.read_json(sp)); sv_box.text = code; copy_code(code), 170))
		if in_game and s.begins_with("slot"):
			h.add_child(btn("存到這裡", func(): G.save_game(sp); show_saves(true); sv_msg.text = "已存到 " + G.SLOT_NAMES[s], 150))
	if in_game:
		var hc := HBoxContainer.new(); v.add_child(hc)
		hc.add_child(btn("匯出目前進度", func(): var code: String = G.export_code(); sv_box.text = code; copy_code(code), 220))
	# 存檔碼區
	var p2 := panel(Vector2(30, 506), Vector2(1540, 370))
	var v2 := VBoxContainer.new(); v2.add_theme_constant_override("separation", 8); p2.add_child(v2)
	v2.add_child(lbl("存檔碼（在手機／網頁／電腦之間搬移進度：A 裝置「匯出」→ 複製 → B 裝置「貼上」→「匯入到存檔 N」）", 18, Color(0.35, 0.22, 0.1)))
	sv_box = TextEdit.new(); sv_box.custom_minimum_size = Vector2(1480, 120); sv_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	sv_box.placeholder_text = "在這裡貼上 ET1. 開頭的存檔碼"; sv_box.add_theme_font_size_override("font_size", 15); v2.add_child(sv_box)
	var h2 := HBoxContainer.new(); h2.add_theme_constant_override("separation", 10); v2.add_child(h2)
	h2.add_child(btn("複製", func(): copy_code(sv_box.text), 100))
	h2.add_child(btn("貼上", func(): paste_code(), 100))
	for s in ["slot1", "slot2", "slot3"]:
		h2.add_child(btn("匯入到" + G.SLOT_NAMES[s], func(): do_import(s, in_game), 200))
	h2.add_child(btn("存成檔案", func(): export_file(), 150))
	if not OS.has_feature("web") and not OS.has_feature("mobile"): h2.add_child(btn("從檔案匯入", func(): import_file(), 170))
	h2.add_child(btn("返回", func():
		if in_game: show_camp()
		else: show_title(), 110))
	sv_msg = lbl(G.migrate_msg, 18, Color(0.1, 0.4, 0.1)); v2.add_child(sv_msg)

func copy_code(code: String) -> void:
	if code.strip_edges() == "": sv_msg.text = "沒有存檔碼可複製"; return
	DisplayServer.clipboard_set(code)
	sv_msg.text = "已複製存檔碼（%d 字）到剪貼簿，可貼到記事本／LINE 自己傳給自己" % code.length()

func paste_code() -> void:
	var t := ""
	if OS.has_feature("web"):
		var r = JavaScriptBridge.eval("window.prompt('請長按貼上存檔碼（ET1. 開頭）', '') || ''", true)
		t = str(r) if r != null else ""
	else: t = DisplayServer.clipboard_get()
	if t.strip_edges() == "": sv_msg.text = "剪貼簿是空的"; return
	sv_box.text = t.strip_edges(); sv_msg.text = "已貼上，請選擇要匯入到哪個存檔"

func do_import(slot: String, in_game: bool) -> void:
	var err: String = G.import_code(sv_box.text, slot)
	if err != "": sv_msg.text = "匯入失敗：" + err; sv_msg.add_theme_color_override("font_color", Color(0.6, 0.1, 0.05)); return
	show_saves(in_game); sv_msg.text = "匯入成功 → %s（%s）。按「讀取」即可繼續遊玩" % [G.SLOT_NAMES[slot], G.slot_info(slot).get("text", "")]

func export_dir() -> String:
	var d := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	return (d if d != "" else OS.get_user_data_dir()) + "/EmpireTactics"

func export_file() -> void:
	var code := sv_box.text.strip_edges()
	if code == "": code = G.export_code(G.read_json(G.latest_slot())) if G.has_save() else ""
	if code == "": sv_msg.text = "沒有可匯出的存檔"; return
	var fn := "EmpireTactics_save_%s.txt" % Time.get_datetime_string_from_system().replace(":", "").replace("-", "").replace("T", "_")
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(code.to_utf8_buffer(), fn, "text/plain"); sv_msg.text = "已下載 " + fn; return
	DirAccess.make_dir_recursive_absolute(export_dir())
	var f := FileAccess.open(export_dir() + "/" + fn, FileAccess.WRITE)
	if f == null: DisplayServer.clipboard_set(code); sv_msg.text = "無法寫入檔案，已改為複製到剪貼簿"; return
	f.store_string(code); f.close(); sv_msg.text = "已存成 " + export_dir() + "/" + fn

func import_file() -> void:
	var dir := DirAccess.open(export_dir())
	if dir == null: sv_msg.text = "找不到 " + export_dir(); return
	var best := ""
	for fn in dir.get_files():
		if fn.begins_with("EmpireTactics_save") and fn.ends_with(".txt") and fn > best: best = fn
	if best == "": sv_msg.text = "資料夾裡沒有 EmpireTactics_save*.txt"; return
	sv_box.text = FileAccess.get_file_as_string(export_dir() + "/" + best).strip_edges()
	sv_msg.text = "已讀入 %s，請選擇要匯入到哪個存檔" % best

# ================= v21：破關動畫 =================
func play_ending(done: Callable) -> void:
	t_busy = false
	new_page()
	print("ENDING START")
	for c in get_children():
		if c is AudioStreamPlayer and c.playing and c != sfxp: c.stop()
	bgm_key = ""
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/v21/ending_data.json"))
	var vlen := float(data.video_len); var clen := float(data.credits_len); var elen := float(data.end_len)
	var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); page.add_child(root)
	var bk := ColorRect.new(); bk.color = Color.BLACK; bk.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(bk)
	var vp := VideoStreamPlayer.new(); vp.expand = true; vp.size = Vector2(1600, 900); vp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st = load("res://assets/v21/ending.ogv") if ResourceLoader.exists("res://assets/v21/ending.ogv") else null
	var use_video: bool = st != null and not OS.get_cmdline_user_args().has("--stills")
	var stills := Control.new(); stills.size = Vector2(1600, 900); stills.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(stills)
	if use_video: vp.stream = st; root.add_child(vp); vp.play()
	var mp := AudioStreamPlayer.new(); add_child(mp); mp.stream = load("res://assets/v21/ending_bgm.ogg"); mp.volume_db = -6.0; mp.play()
	var t0 := Time.get_ticks_msec()
	# 字幕：逐行淡入淡出
	for sb in data.subs:
		var who: String = sb[2]; var txt: String = sb[3]
		var l := Label.new(); l.text = txt if who == "旁白" else "%s　%s" % [who, txt]
		l.add_theme_font_override("font", font); l.add_theme_font_size_override("font_size", 34)
		l.add_theme_color_override("font_color", Color(1, 1, 1) if who == "旁白" else Color(1.0, 0.93, 0.8))
		l.add_theme_constant_override("outline_size", 10); l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.size = Vector2(1600, 50); l.position = Vector2(0, 800); l.modulate.a = 0.0; root.add_child(l)
		var tw := l.create_tween(); tw.tween_interval(float(sb[0])); tw.tween_property(l, "modulate:a", 1.0, 0.6)
		tw.tween_interval(float(sb[1]) - float(sb[0]) - 1.2); tw.tween_property(l, "modulate:a", 0.0, 0.6)
	# 片尾名單
	var cr := VBoxContainer.new(); cr.position = Vector2(0, 900); cr.size = Vector2(1600, 0); cr.add_theme_constant_override("separation", 10); root.add_child(cr)
	for c in data.credits:
		var l := Label.new(); l.text = c; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.custom_minimum_size = Vector2(1600, 40)
		l.add_theme_font_override("font", wkf()); l.add_theme_font_size_override("font_size", 40 if c == data.credits[0] else 32)
		l.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55) if c.begins_with("—") or c == data.credits[0] else Color(0.95, 0.95, 0.95)); cr.add_child(l)
	var ctw := cr.create_tween(); ctw.tween_interval(vlen); ctw.tween_property(cr, "position:y", -55.0 * data.credits.size() - 40.0, clen)
	var te := tl("THE END\n完", 96, Color(1.0, 0.82, 0.4), wkf()); te.size = Vector2(1600, 300); te.position = Vector2(0, 300); te.modulate.a = 0.0
	te.add_theme_constant_override("outline_size", 12); te.add_theme_color_override("font_outline_color", Color(0.25, 0.08, 0.0)); root.add_child(te)
	var etw := te.create_tween(); etw.tween_interval(vlen + clen); etw.tween_property(te, "modulate:a", 1.0, 1.2)
	var skip := btn("跳過 ▶▶", func(): set_meta("end_skip", true), 140); skip.position = Vector2(1430, 20); skip.modulate.a = 0.6; root.add_child(skip)
	set_meta("end_skip", false)
	var checked := false; var shot_at := [5.0, 15.0, 30.0, 50.0, 70.0, 84.0]
	var total := vlen + clen + elen
	while true:
		await get_tree().process_frame
		if not is_instance_valid(root): return
		var el := (Time.get_ticks_msec() - t0) / 1000.0
		if not checked and el > 1.5:
			checked = true
			var ok := use_video and vp.is_playing() and vp.stream_position > 0.2
			print("ENDING VIDEO playing=", ok, " pos=", vp.stream_position if use_video else -1.0)
			if not ok: start_stills(stills, vlen, vp)
		if shot_dir != "" and shot_at.size() > 0 and el >= shot_at[0]:
			shot_at.pop_front(); await snap("ending_%02d" % int(el))
		if el > vlen and use_video and vp.visible: vp.create_tween().tween_property(vp, "modulate:a", 0.0, 0.6); vp.visible = el < vlen + 0.7
		if el >= total or get_meta("end_skip"): break
	var ft := root.create_tween(); ft.tween_property(root, "modulate:a", 0.0, 0.8); ft.parallel().tween_property(mp, "volume_db", -40.0, 0.8)
	await ft.finished
	mp.queue_free()
	print("ENDING FINISHED t=", (Time.get_ticks_msec() - t0) / 1000.0)
	done.call()

# 影片無法播放時（部分瀏覽器／裝置）：改用靜態畫面交叉淡入＋緩慢推鏡
func start_stills(holder: Control, vlen: float, vp: VideoStreamPlayer) -> void:
	if is_instance_valid(vp): vp.stop(); vp.visible = false
	var files := []
	for i in 12: files.append("res://assets/v21/stills/s%02d.jpg" % i)
	var per := vlen / files.size()
	var tw := holder.create_tween()
	for i in files.size():
		var tr := TextureRect.new(); tr.texture = load(files[i]); tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.size = Vector2(1600, 900); tr.pivot_offset = Vector2(800, 450); tr.modulate.a = 0.0; holder.add_child(tr)
		tw.tween_property(tr, "modulate:a", 1.0, 0.8)
		tw.parallel().tween_property(tr, "scale", Vector2(1.08, 1.08), per).from(Vector2.ONE)
	tw.tween_property(holder, "modulate:a", 0.0, 0.8)
	print("ENDING STILLS fallback")

func save_test21() -> void:
	# 1) 槽位＋原子寫入 2) 存檔碼往返 3) 錯誤碼偵測 4) 舊版 v17 格式轉 v21
	G.test_mode = true
	G.setup_for_battle(12); G.gold = 4321; G.play_time = 3723.0
	print("SAVE21 user_dir=", OS.get_user_data_dir())
	var ok1: bool = G.save_game(G.slot_path("slot2"))
	var code: String = G.export_code()
	print("SAVE21 slot2=", ok1, " code_len=", code.length(), " head=", code.substr(0, 12))
	G.new_game()
	var err: String = G.import_code(code, "slot3")
	print("SAVE21 import err='", err, "' gold=", G.gold, " progress=", G.progress, " roster=", G.roster.size(), " info=", G.slot_info("slot3").get("text", ""))
	var bad := code.substr(0, 40) + "X" + code.substr(41)
	print("SAVE21 corrupt -> '", G.import_code(bad, "slot3"), "'  garbage -> '", G.import_code("hello", "slot3"), "'")
	var d := G.save_dict(); d.v = 17; d.erase("ts"); d.erase("ending_seen")
	var f := FileAccess.open("user://legacy17.json", FileAccess.WRITE); f.store_string(JSON.stringify(d)); f.close()
	print("SAVE21 legacy load=", G.load_game("user://legacy17.json"), " -> resave v=", G.save_dict().v)
	print("SAVE21 latest=", G.latest_slot(), " cleared=", G.game_cleared())
	get_tree().quit()

func save_test23(src: String) -> void:
	# v22 存檔（唯讀來源）→ 載入 → 營地畫面 → 另存 v23 測試檔；不覆寫任何玩家槽位
	var raw: Dictionary = G.read_json(src)
	print("SAVE23 src=", src, " v=", raw.get("v"), " progress=", raw.get("progress"), " gold=", raw.get("gold"), " roster=", raw.get("roster", []).size())
	var ok: bool = G.load_game(src)
	print("SAVE23 load=", ok, " progress=", G.progress, " gold=", G.gold, " roster=", G.roster.size(), " items=", G.items.size(), " events=", G.events, " has_adam=", G.has_adam(), " has_lev=", G.has_lev())
	G.cur_battle = mini(G.progress, G.BATTLES.size() - 1); G.set_meta("in_campaign", true)
	show_camp(); await get_tree().create_timer(3.0).timeout
	shot_dir = "/workspace/srpg/v23/shots"
	await snap("23_v22save_camp")
	var d := G.save_dict()
	var f := FileAccess.open("user://v23_from_v22_test.json", FileAccess.WRITE); f.store_string(JSON.stringify(d)); f.close()
	print("SAVE23 resave v=", d.v, " next_battle=", G.cur_battle + 1, " ", G.BATTLES[G.cur_battle].get("name", ""))
	print("SAVE23 OK")
	get_tree().quit()

func save_shots() -> void:
	shot_dir = OS.get_user_data_dir()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shotdir="): shot_dir = a.substr(10)
	show_title(); await get_tree().create_timer(4.0).timeout; await snap("s1_title")
	show_saves(false); await snap("s2_saves")
	sv_box.text = G.export_code(G.read_json(G.latest_slot())) if G.has_save() else ""; sv_msg.text = "（示範）已匯出存檔碼"; await snap("s3_export")
	get_tree().quit()
