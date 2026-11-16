extends Node3D
# 帝國戰記 SRPG v2 — KayKit CC0 骨架角色、戰鬥特效、帝國城塞場景、帝國風介面

const SH = preload("res://shaders.gd")
const V15FX = preload("res://v15fx.gd")
var W := 12
var H := 10
const STEP := 0.5
var MAP: Array = []
const DIRS := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
const UNIT_SCALE := 0.8
var ROCK_CELLS: Array = []
var LAVA_CELLS: Array = []
var road_cells := {}
var bidx := 0
var bdef := {}
var TH := {}
var spawn_p: Array = []
var spawn_e: Array = []
var spawn_boss := Vector2i(-1, -1)
var fall_cell := Vector2i(-1, -1)
var res := {"exp": {}, "drops": [], "gold": 0, "lvups": 0}
var turns_p := 0
var turns_e := 0
var dlg_lines := 0
var boss_phase := 0
var do_shots := false
var levelup_shot_done := false
var item_shot_done := false
var ally_item_test := false
var boss_shot_done := false
var item_tested := {}
var sel_item := ""
var pending_phase = null
const THEMES := {
	"dawn": {"top": Color(0.2, 0.29, 0.45), "hor": Color(0.78, 0.52, 0.32), "amb": 0.42, "fog": Color(0.62, 0.46, 0.34), "sun": Color(1.0, 0.7, 0.42), "sun_e": 2.3, "rot": Vector3(-30, -55, 0), "tint": Vector3(1.0, 1.12, 1.0), "snow": 0.0, "moss": Vector3(0.30, 0.36, 0.13), "leaf": Vector3(0.2, 0.28, 0.07), "mtn": Color(0.42, 0.44, 0.55), "grass": true, "flowers": 0.45, "fx": "leaf", "torch": 1.4, "exp": 1.0},
	"day": {"top": Color(0.24, 0.42, 0.72), "hor": Color(0.72, 0.8, 0.86), "amb": 0.55, "fog": Color(0.66, 0.74, 0.82), "sun": Color(1.0, 0.93, 0.8), "sun_e": 2.1, "rot": Vector3(-52, -40, 0), "tint": Vector3(1.0, 1.15, 0.95), "snow": 0.0, "moss": Vector3(0.30, 0.38, 0.13), "leaf": Vector3(0.18, 0.3, 0.07), "mtn": Color(0.5, 0.58, 0.7), "grass": true, "flowers": 0.5, "fx": "leaf", "torch": 0.6, "exp": 1.0},
	"dusk": {"top": Color(0.25, 0.18, 0.36), "hor": Color(0.95, 0.45, 0.22), "amb": 0.36, "fog": Color(0.7, 0.38, 0.25), "sun": Color(1.0, 0.55, 0.28), "sun_e": 2.4, "rot": Vector3(-16, -70, 0), "tint": Vector3(1.05, 1.0, 0.85), "snow": 0.0, "moss": Vector3(0.32, 0.32, 0.12), "leaf": Vector3(0.28, 0.24, 0.07), "mtn": Color(0.38, 0.3, 0.42), "grass": true, "flowers": 0.3, "fx": "leaf", "torch": 1.6, "exp": 1.0},
	"night": {"top": Color(0.03, 0.05, 0.14), "hor": Color(0.15, 0.2, 0.36), "amb": 0.3, "fog": Color(0.12, 0.16, 0.3), "sun": Color(0.55, 0.65, 1.0), "sun_e": 1.0, "rot": Vector3(-40, 30, 0), "tint": Vector3(0.85, 0.95, 1.1), "snow": 0.0, "moss": Vector3(0.2, 0.28, 0.16), "leaf": Vector3(0.12, 0.2, 0.1), "mtn": Color(0.12, 0.15, 0.26), "grass": true, "flowers": 0.15, "fx": "firefly", "torch": 2.4, "exp": 1.15},
	"snow": {"top": Color(0.42, 0.5, 0.64), "hor": Color(0.7, 0.76, 0.86), "amb": 0.6, "fog": Color(0.66, 0.72, 0.84), "sun": Color(0.9, 0.93, 1.0), "sun_e": 1.25, "rot": Vector3(-35, -30, 0), "tint": Vector3(0.86, 0.88, 0.92), "snow": 0.85, "moss": Vector3(0.85, 0.88, 0.95), "leaf": Vector3(0.75, 0.8, 0.85), "mtn": Color(0.75, 0.8, 0.9), "grass": false, "flowers": 0.0, "fx": "snow", "torch": 1.4, "exp": 0.8},
	"lava": {"top": Color(0.12, 0.05, 0.05), "hor": Color(0.6, 0.18, 0.06), "amb": 0.35, "fog": Color(0.45, 0.14, 0.06), "sun": Color(1.0, 0.45, 0.2), "sun_e": 1.8, "rot": Vector3(-28, 60, 0), "tint": Vector3(0.75, 0.62, 0.5), "snow": 0.0, "moss": Vector3(0.12, 0.08, 0.06), "leaf": Vector3(0.1, 0.08, 0.05), "mtn": Color(0.18, 0.08, 0.07), "grass": false, "flowers": 0.0, "fx": "ember", "torch": 2.0, "exp": 1.05},
	"temple": {"top": Color(0.3, 0.38, 0.55), "hor": Color(0.9, 0.8, 0.62), "amb": 0.55, "fog": Color(0.85, 0.76, 0.6), "sun": Color(1.0, 0.88, 0.65), "sun_e": 2.0, "rot": Vector3(-45, -20, 0), "tint": Vector3(1.05, 1.08, 0.92), "snow": 0.0, "moss": Vector3(0.36, 0.38, 0.2), "leaf": Vector3(0.25, 0.3, 0.1), "mtn": Color(0.55, 0.55, 0.62), "grass": true, "flowers": 0.25, "fx": "dust", "torch": 1.2, "exp": 1.0},
	"ruins": {"top": Color(0.28, 0.3, 0.36), "hor": Color(0.6, 0.55, 0.5), "amb": 0.45, "fog": Color(0.5, 0.48, 0.46), "sun": Color(0.9, 0.85, 0.78), "sun_e": 1.7, "rot": Vector3(-38, -60, 0), "tint": Vector3(0.92, 1.0, 0.88), "snow": 0.0, "moss": Vector3(0.26, 0.32, 0.14), "leaf": Vector3(0.2, 0.24, 0.08), "mtn": Color(0.36, 0.38, 0.44), "grass": true, "flowers": 0.15, "fx": "dust", "torch": 1.6, "exp": 1.0},
	"throne": {"top": Color(0.1, 0.04, 0.12), "hor": Color(0.45, 0.15, 0.25), "amb": 0.38, "fog": Color(0.3, 0.1, 0.18), "sun": Color(0.95, 0.6, 0.8), "sun_e": 1.7, "rot": Vector3(-42, 40, 0), "tint": Vector3(0.8, 0.78, 0.9), "snow": 0.0, "moss": Vector3(0.2, 0.12, 0.2), "leaf": Vector3(0.2, 0.1, 0.15), "mtn": Color(0.2, 0.1, 0.2), "grass": false, "flowers": 0.0, "fx": "ember", "torch": 2.2, "exp": 1.05},
	"forest": {"base": "dawn", "top": Color(0.22, 0.34, 0.42), "hor": Color(0.7, 0.72, 0.52), "fog": Color(0.42, 0.52, 0.38), "sun": Color(1.0, 0.86, 0.6), "rot": Vector3(-38, -50, 0), "tint": Vector3(1.0, 1.0, 1.0), "leaf": Vector3(0.1, 0.24, 0.08), "mtn": Color(0.3, 0.42, 0.4), "gt": "t_forest", "tree": "pine", "tree_mul": 3.2, "flowers": 0.3, "rockc": Color(0.75, 0.85, 0.75)},
	"grass": {"base": "day", "gt": "t_grass", "tree": "round", "tree_mul": 0.8, "flowers": 0.85, "tint": Vector3(1.0, 1.05, 0.92), "mtn": Color(0.46, 0.56, 0.72)},
	"plains": {"base": "day", "hor": Color(0.86, 0.82, 0.7), "fog": Color(0.8, 0.76, 0.62), "sun": Color(1.0, 0.88, 0.66), "gt": "t_plains", "tint": Vector3(1.0, 1.0, 1.0), "tree": "round", "tree_mul": 0.6, "flowers": 0.6, "mtn": Color(0.52, 0.56, 0.66)},
	"castle": {"base": "day", "gt": "t_cobble", "tint": Vector3(0.62, 0.62, 0.66), "grass": false, "flowers": 0.05, "tree": "round", "tree_mul": 0.4, "props": "castle", "mtn": Color(0.44, 0.5, 0.62), "fx": "dust", "rockc": Color(0.68, 0.68, 0.72), "exp": 0.92},
	"fortress": {"base": "dusk", "gt": "t_cobble", "tint": Vector3(0.7, 0.66, 0.62), "grass": false, "flowers": 0.0, "tree": "dead", "tree_mul": 0.6, "props": "castle", "rockc": Color(0.7, 0.66, 0.66)},
	"nightcastle": {"base": "night", "gt": "t_cobble", "tint": Vector3(0.8, 0.85, 0.95), "grass": false, "flowers": 0.0, "tree": "none", "props": "castle"},
	"desert": {"base": "day", "top": Color(0.3, 0.48, 0.74), "hor": Color(0.9, 0.74, 0.52), "amb": 0.42, "fog": Color(0.8, 0.62, 0.42), "sun": Color(1.0, 0.9, 0.7), "sun_e": 1.8, "exp": 0.88, "rot": Vector3(-58, -30, 0), "tint": Vector3(0.66, 0.6, 0.55), "moss": Vector3(0.62, 0.48, 0.3), "leaf": Vector3(0.2, 0.34, 0.12), "mtn": Color(0.78, 0.56, 0.36), "grass": false, "flowers": 0.0, "fx": "dust", "gt": "t_sand", "ct": "t_sandstone", "tree": "cactus", "tree_mul": 1.6, "props": "desert", "side": Vector3(0.85, 0.82, 0.8), "rockc": Color(0.85, 0.82, 0.8)},
}
const SKILLS := {
	"暗黑劍": {"kind": "strike", "mult": 1.6, "drain": 50, "col": Color(0.6, 0.2, 1.0)},
	"狂狼咆哮": {"kind": "roar", "col": Color(1.0, 0.3, 0.1)},
	"毒刃亂舞": {"kind": "strike", "mult": 0.85, "hits": 2, "poison": 60, "col": Color(0.4, 1.0, 0.3)},
	"隕星": {"kind": "aoe", "range": 4, "rad": 1, "mult": 1.1, "col": Color(1.0, 0.5, 0.1)},
	"聖域": {"kind": "sanct", "col": Color(1.0, 0.95, 0.6)},
	"震地擊": {"kind": "quake", "rad": 2, "mult": 0.9, "stun": 50, "col": Color(0.9, 0.7, 0.4)},
	"貫穿": {"kind": "strike", "mult": 1.5, "pierce": 100, "col": Color(0.5, 0.8, 1.0)},
	"法典審判": {"kind": "aoe", "range": 5, "rad": 2, "mult": 1.2, "col": Color(1.0, 0.85, 0.3)},
	"崩山拳": {"kind": "quake", "rad": 2, "mult": 1.0, "stun": 30, "col": Color(0.8, 0.5, 0.3)},
}
const SUMMON_COST := 24
const SUMMON_RANGE := 4
const SUMMON_AOE := 2
# v17：第二召喚獸 利維坦（水・支援／控制）
const LEV_COST := 30
const LEV_RANGE := 4
const LEV_AOE := 3
var summon_kind := "ifrit"
var lev_shot_done := false

var heights := {}
var units: Array = []
var cur = null
var state := "prep"
var moved := false
var acted := false
var hl_nodes: Array = []
var hl_cells := {}
var aoe_nodes: Array = []
var reach := {}
var mats := {}
var ui_font: FontVariation
var narr_font: FontVariation
var font_bold: FontVariation
var cam_pivot: Node3D
var cam: Camera3D
var env: Environment
var sun: DirectionalLight3D
var sun_base := 2.0
var fx_lights: Array = []
var r_method := "forward_plus"
var yaw := 45.0
var target_yaw := 45.0
var cam_dist := 23.0
var target_dist := 23.0
var pitch := 40.0
var target_pitch := 40.0
var shake := 0.0
var cursor_ring: MeshInstance3D
var noise_tex: Texture2D
var unit_shader: Shader
var torches: Array = []
var clouds: Array = []
var birds: Array = []
var tile_grass: Array = []
var outer_top := {}
var water_cells: Array = []
var water_mats: Array = []
var spr_shader: Shader
const SPR_SH := '''shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
uniform sampler2D tex : source_color, filter_nearest;
uniform int frame = 0;
uniform int row = 0;
uniform float flip = 0.0;
uniform vec4 flash = vec4(0.0);
uniform vec3 tint = vec3(1.0, 0.93, 0.85);
uniform float dissolve = 0.0;
uniform vec2 grid = vec2(24.0, 2.0);
uniform float glowmul = 1.7;
uniform sampler2D wm : hint_default_black, filter_nearest;
uniform vec4 wcol = vec4(1.0, 1.0, 1.0, 0.0);
uniform float wpulse = 0.0;
uniform vec4 stc = vec4(0.0);
uniform vec3 amb = vec3(1.0);
uniform vec3 rim_col = vec3(1.0, 0.8, 0.55);
uniform vec2 rim_dir = vec2(0.0, -1.0);
uniform float rim_str = 0.0;
uniform vec3 plit = vec3(0.0);
uniform float plit_dir = 0.0;
uniform vec4 sel_col = vec4(0.0);
float h21(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void vertex() {
	vec3 sc = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	vec3 r = normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz));
	vec3 f = normalize(cross(r, vec3(0.0, 1.0, 0.0)));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(r * sc.x, 0.0), vec4(0.0, sc.y, 0.0, 0.0), vec4(-f * sc.z, 0.0), MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}
void fragment() {
	vec2 uv = UV;
	if (flip > 0.5) uv.x = 1.0 - uv.x;
	vec2 cuv = (vec2(float(frame), float(row)) + uv) / grid;
	vec4 c = texture(tex, cuv);
	bool sel_o = false; float sel_k = 0.0;
	if (c.a < 0.5) {
		// v20：行動角色像素邊緣外描光（只畫在自己的看板四邊形內）
		if (sel_col.a <= 0.001) discard;
		vec2 cpx = grid / vec2(textureSize(tex, 0));
		for (int i = 0; i < 12; i++) {
			float an = float(i) * 0.5236; vec2 dv = vec2(cos(an), sin(an));
			for (int s = 1; s <= 3; s++) {
				vec2 l = uv + dv * cpx * float(s) * 1.3;
				if (l.x < 0.0 || l.x > 1.0 || l.y < 0.0 || l.y > 1.0) continue;
				if (texture(tex, (vec2(float(frame), float(row)) + l) / grid).a >= 0.5) sel_k = max(sel_k, 1.0 - float(s - 1) * 0.3);
			}
		}
		if (sel_k <= 0.0) discard;
		sel_o = true;
	}
	vec2 tsz = vec2(textureSize(tex, 0));
	if (dissolve > 0.0 && h21(floor(cuv * tsz / 2.0)) < dissolve) discard;
	vec3 col = c.rgb * tint;
	if (c.a < 0.995) col *= glowmul;
	float wmk = texture(wm, cuv).r * wcol.a;
	if (wmk > 0.0) {
		float lum = dot(c.rgb, vec3(0.3, 0.55, 0.15));
		vec3 wc = mix(col, wcol.rgb * (0.45 + lum * 1.25), 0.85);
		wc += wcol.rgb * wpulse * (0.35 + 0.25 * sin(TIME * 4.0 + cuv.y * 40.0));
		col = mix(col, wc, wmk);
	}
	if (stc.a > 0.0) { float shm = 0.7 + 0.3 * sin(TIME * 5.0 + cuv.y * 90.0); float lm = dot(c.rgb, vec3(0.3, 0.55, 0.15)); col = mix(col, stc.rgb * (0.45 + lm * 1.1), stc.a * shm); }
	// v19：環境色溫 + 依光向的像素邊緣光 + 火把/法術局部照明（逐像素取樣，不模糊像素風）
	col *= amb;
	vec2 px = 1.0 / tsz; float fx = flip > 0.5 ? -1.0 : 1.0;
	float lum2 = dot(c.rgb, vec3(0.3, 0.55, 0.15));
	if (rim_str > 0.001) {
		vec2 d = rim_dir * vec2(fx, 1.0);
		float e1 = 1.0 - step(0.5, texture(tex, cuv + d * px).a);
		float e2 = 1.0 - step(0.5, texture(tex, cuv + d * px * 2.0).a);
		float edge = clamp(e1 + e2 * 0.45, 0.0, 1.0);
		col += rim_col * rim_str * edge * (0.55 + 0.6 * lum2);
	}
	if (dot(plit, vec3(1.0)) > 0.002) {
		vec2 pd = vec2(plit_dir * fx, -0.3);
		float pe = 1.0 - step(0.5, texture(tex, cuv + pd * px * 2.0).a);
		col += plit * (0.35 + 0.65 * lum2) * (0.6 + 0.9 * pe);
	}
	col = mix(col, flash.rgb, clamp(flash.a, 0.0, 1.0) * 0.8);
	if (sel_o) { float br = 0.5 + 0.5 * sin(TIME * 3.0); col = sel_col.rgb * (0.9 + 1.5 * br) * sel_k * sel_col.a; }
	ALBEDO = col;
}
'''
const TER_SH := '''shader_type spatial;
render_mode cull_disabled;
uniform sampler2D tg : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tc : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D nz : filter_linear_mipmap, repeat_enable;
uniform float sc = 0.5;
uniform vec3 top_tint = vec3(1.0);
uniform vec3 side_tint = vec3(1.0);
uniform float snow = 0.0;
uniform vec3 moss_col = vec3(0.30, 0.36, 0.13);
varying vec3 wp; varying vec3 wn; varying float dtop;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); dtop = UV2.x; }
void fragment() {
	float n1 = texture(nz, wp.xz * 0.09).r;
	float n2 = texture(nz, wp.xz * 0.31 + vec2(0.37)).r;
	if (wn.y > 0.5) {
		vec3 tp = texture(tg, wp.xz * sc).rgb * top_tint;
		tp *= 0.86 + 0.28 * n1;
		tp = mix(tp, tp * vec3(1.08, 1.0, 0.72), smoothstep(0.55, 0.75, n2) * 0.5);
		tp = mix(tp, vec3(0.88, 0.91, 0.97) * (0.9 + 0.14 * n1), snow * smoothstep(0.2, 0.45, n2 * 0.7 + 0.3));
		ALBEDO = tp;
	} else {
		vec3 aw = abs(wn);
		float hx = aw.x > aw.z ? wp.z : wp.x;
		vec2 suv = vec2(hx, wp.y) * sc;
		float ns = texture(nz, vec2(hx * 0.21, wp.y * 0.35)).r;
		vec3 sd = texture(tc, suv + vec2(0.0, ns * 0.18)).rgb * side_tint;
		float strata = fract(wp.y * 1.45 + ns * 0.9);
		sd *= 0.8 + 0.28 * smoothstep(0.08, 0.32, strata) - 0.1 * smoothstep(0.85, 1.0, strata);
		sd = mix(sd, sd * vec3(1.1, 0.98, 0.86), smoothstep(0.4, 0.7, texture(nz, vec2(hx, wp.y) * 0.13).r) * 0.45);
		float moss = 1.0 - smoothstep(0.02, 0.16 + ns * 0.34, dtop);
		sd = mix(sd, moss_col * (0.8 + 0.4 * ns), moss * 0.9);
		sd *= 1.0 - 0.2 * smoothstep(0.0, 0.07, dtop) * (1.0 - smoothstep(0.07, 0.3, dtop));
		sd *= mix(1.0, 0.72, smoothstep(0.6, 3.2, dtop));
		ALBEDO = sd;
	}
	ROUGHNESS = 0.95; SPECULAR = 0.15;
}
'''
const SPR_KEY := {"雷恩":"rain","艾琳":"erin","葛雷":"grey","米菈":"mira","黑騎士加爾德":"gard","帝國騎士":"eknight","帝國狂戰士":"ebers","帝國弩手":"earch","帝國重弩手":"earch2"}
const SPR_W := {"黎明王劍":"hero","長劍":"sword","巨劍":"great","戰斧":"axe","巨斧":"gaxe","輕弩":"xbow","十字弓":"hxbow","魔杖":"wand","秘銀杖":"staff"}
const SANIM := {"idle":[[0,1,2,3],0.32,true],"walk":[[4,5,6,7,8,9],0.1,true],"atk":[[10,11,12,13,14],0.1,false],"cast":[[15,16,17,18],0.18,true],"hurt":[[19,20],0.16,false],"death":[[19,21,22,23],0.22,false],"win":[[24,25,26,27],0.2,true]}

var base_ts := 1.0
var sfx_streams := {}
var sfx_players: Array = []
var bgm: AudioStreamPlayer
# UI
var ui_root: Control
var order_box: VBoxContainer
var card := {}
var tcard := {}
var log_label: Label
var turn_label: Label
var menu_panel: PanelContainer
var menu_box: VBoxContainer
var equip_panel: PanelContainer
var equip_vbox: VBoxContainer
var banner: Label
var banner_bg: TextureRect
var flash: ColorRect
var over_panel: PanelContainer
var title_panel: PanelContainer
var log_lines: Array = []
var hover_cell := Vector2i(-1, -1)
var card_unit = null
# autotest
var autotest := false
var autolose := false
var shots_dir := "D:/SRPG/tmp/shots"
var summon_shot_done := false
var attack_shot_done := false
var equip_tested := false
var menu_shot := false
var menu_shot_done := false
var t_elapsed := 0.0

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	call_deferred("build_touch_ui")
	for a in args:
		if a == "--autotest": autotest = true
		if a == "--touchtest": autotest = true; touch_test = true
		if a == "--autolose": autotest = true; autolose = true
		if a.begins_with("--shots="): shots_dir = a.substr(8); do_shots = true
		if a.begins_with("--wx="): wx_force = a.substr(5)
		if a == "--menushot": menu_shot = true
		if a == "--evtest": evtest = true
		if a == "--allyitem": ally_item_test = true; autotest = true
		if a == "--wxonly": wx_only = true
		if a == "--lightshot": light_shot = true
		if a == "--settleshot": settle_shot = true
		if a == "--promoview": promo_view = true
		if a.begins_with("--battle="): bidx = clampi(int(a.substr(9)) - 1, 0, 15)
	if OS.has_environment("SRPG_TRACE"): printerr("STAGE font")
	var ff: FontFile = load("res://assets/fonts/NotoSerifTC.ttf")
	ui_font = FontVariation.new(); ui_font.base_font = ff
	narr_font = FontVariation.new(); var wk: FontFile = load("res://assets/fonts/WenKaiTC.ttf"); wk.fallbacks = [ff]; narr_font.base_font = wk; narr_font.spacing_glyph = 2
	ui_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}
	font_bold = FontVariation.new(); font_bold.base_font = ff
	font_bold.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 900}
	# 同步產生雜訊貼圖（NoiseTexture2D 會在背景執行緒生成，啟動時偶發 heap corruption 閃退）
	var fn := FastNoiseLite.new(); fn.frequency = 0.02
	var nimg := fn.get_seamless_image(256, 256); nimg.generate_mipmaps()
	noise_tex = ImageTexture.create_from_image(nimg)
	unit_shader = Shader.new(); unit_shader.code = SH.UNIT
	spr_shader = Shader.new(); spr_shader.code = SPR_SH
	if autotest:
		G.test_mode = true
		G.setup_for_battle(bidx)
	else: bidx = G.cur_battle
	bdef = G.battle_def(bidx)
	var th0: Dictionary = THEMES.get(bdef.theme, THEMES.dawn)
	TH = (THEMES[th0.base] as Dictionary).merged(th0, true) if th0.has("base") else th0.duplicate()
	gen_map()
	if OS.has_environment("SRPG_TRACE"): printerr("STAGE build_audio()")
	build_audio()
	if OS.has_environment("SRPG_TRACE"): printerr("STAGE build_env()")
	build_env()
	if OS.has_environment("SRPG_TRACE"): printerr("STAGE build_map()")
	build_map()
	if OS.has_environment("SRPG_TRACE"): printerr("STAGE build_scenery()")
	build_scenery()
	if OS.has_environment("SRPG_TRACE"): printerr("STAGE build_units()")
	build_units()
	party_n = alive_team(0).size(); build_settlement(); ev_setup(); form_apply(); flag_setup()
	for u0 in players(): legend_aura(u0)
	target_dist = 23.0 * maxf(1.0, map_k() * 0.92); cam_dist = target_dist
	if OS.has_environment("SRPG_TRACE"): printerr("STAGE build_ui()")
	build_ui()
	wx_init()
	# v22：手機 3D 以 85% 解析度算圖、UI 仍原生清晰，提升幀率降低觸控延遲
	if OS.has_feature("mobile"): get_viewport().scaling_3d_scale = 0.85
	if OS.has_environment("SRPG_TRACE"): printerr("STAGE update_cam()")
	update_cam()
	if OS.has_environment("SRPG_TRACE"): printerr("STAGE done")
	if autotest:
		base_ts = 1.6
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--ts="): base_ts = float(a.substr(5))
		Engine.time_scale = base_ts
		run_autotest()
	else:
		var bf := brief_def()
		if bf.is_empty():
			if bdef.narr.size() > 0 and not (bidx == 0 and G.get_meta("prologue_done", false)): await play_story(bdef.narr, true)
			await play_story(bdef.pre)
		else:
			await show_briefing(bf)
			await play_story(bf.field, false, {}, brief_vo(bf))
		await ev_intro()
		await boss_entrance()
		open_equip(players(), true)

# ---------------- 音效 ----------------
func build_audio() -> void:
	for n in ["slash","hit","crit","bow","magic","explode","summon","click","step","death","victory","defeat","levelup","heal","lev_roar","lev_wave"]:
		sfx_streams[n] = load("res://assets/sfx/%s.wav" % n)
	for i in 10:
		var p := AudioStreamPlayer.new(); p.volume_db = -6.0; add_child(p); sfx_players.append(p)
	bgm = AudioStreamPlayer.new(); add_child(bgm)
	var s: AudioStreamWAV = load("res://assets/sfx/bgm.wav")
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD; s.loop_begin = 0; s.loop_end = int(s.get_length() * s.mix_rate) - 1
	bgm.stream = s; bgm.volume_db = -14.0
	if bdef.get("boss") != null: bgm.pitch_scale = 0.92
	if ResourceLoader.exists("res://assets/v15/bgm/prebattle.ogg"): call_deferred("bgm_play", "prebattle", 0.8)
	else: bgm.play()

func sfx(n: String, pitch_var := 0.08, vol := -6.0) -> void:
	for p in sfx_players:
		if not p.playing:
			p.stream = sfx_streams[n]; p.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var); p.volume_db = vol; p.play(); return

# ---------------- 材質工具 ----------------
func flat(c: Color, metal := 0.0, rough := 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c; m.metallic = metal; m.roughness = rough
	return m

func glow(c: Color, alpha := 1.0, energy := 3.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.emission_enabled = true; m.emission = c; m.emission_energy_multiplier = energy
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func shmat(code: String) -> ShaderMaterial:
	var s := Shader.new(); s.code = code
	var m := ShaderMaterial.new(); m.shader = s
	return m

func mi(parent: Node, mesh: Mesh, pos: Vector3, mat: Material, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var m := MeshInstance3D.new(); m.mesh = mesh; m.position = pos; m.material_override = mat
	m.rotation = rot; m.scale = scl; parent.add_child(m); return m

func box(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new(); b.size = s; return b
func cyl(tr: float, br: float, h: float, seg := 16) -> CylinderMesh:
	var c := CylinderMesh.new(); c.top_radius = tr; c.bottom_radius = br; c.height = h; c.radial_segments = seg; return c
func sph(r: float, seg := 16) -> SphereMesh:
	var s := SphereMesh.new(); s.radius = r; s.height = r * 2; s.radial_segments = seg; s.rings = max(4, seg / 2); return s
func quad(w: float, h: float) -> QuadMesh:
	var q := QuadMesh.new(); q.size = Vector2(w, h); return q

# ---------------- 環境 ----------------
func build_env() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	var sky := Sky.new()
	var pm := ProceduralSkyMaterial.new()
	pm.sky_top_color = TH.top; pm.sky_horizon_color = TH.hor; pm.sky_curve = 0.12
	pm.ground_horizon_color = TH.hor.darkened(0.06); pm.ground_bottom_color = TH.top; pm.ground_curve = 0.25
	pm.sun_angle_max = 18.0; pm.sun_curve = 0.08; pm.energy_multiplier = 1.0
	sky.sky_material = pm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = TH.amb
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = TH.exp
	env.tonemap_white = 6.0
	env.ambient_light_sky_contribution = 0.8
	env.ambient_light_color = TH.top.lerp(TH.hor, 0.35)
	env.ssao_enabled = true
	env.ssao_intensity = 1.9
	env.ssao_radius = 1.35
	env.ssao_power = 1.6
	env.ssao_detail = 0.7
	env.ssao_light_affect = 0.12
	env.glow_enabled = true
	env.glow_intensity = 0.75
	env.glow_strength = 0.95
	env.glow_bloom = 0.09
	env.glow_hdr_threshold = 0.95
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.set_glow_level(0, 0.0); env.set_glow_level(2, 0.8); env.set_glow_level(4, 0.6)
	env.fog_enabled = true
	env.fog_light_color = TH.fog
	env.fog_density = 0.006
	env.fog_aerial_perspective = 0.6
	env.fog_sky_affect = 0.25
	env.fog_height = -0.6
	env.fog_height_density = 0.05
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.86
	env.adjustment_contrast = 1.12
	# v19：FFT 風調色——暗部偏冷紫褐、中間調暖赭、亮部奶油金
	var cg := Gradient.new(); cg.set_color(0, Color(0.03, 0.02, 0.035)); cg.set_color(1, Color(1.0, 0.95, 0.82)); cg.add_point(0.25, Color(0.24, 0.2, 0.19)); cg.add_point(0.5, Color(0.55, 0.48, 0.38)); cg.add_point(0.78, Color(0.82, 0.74, 0.6))
	var cgt := GradientTexture1D.new(); cgt.gradient = cg; cgt.width = 256; env.adjustment_color_correction = cgt
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = TH.rot
	sun.light_color = TH.sun
	sun.light_energy = TH.sun_e
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 55.0
	sun.shadow_blur = 1.7
	sun.shadow_opacity = 0.9
	sun.light_angular_distance = 0.6
	sun.directional_shadow_blend_splits = true
	sun_base = TH.sun_e
	add_child(sun)
	light_fallbacks()
	build_post()
	cam_pivot = Node3D.new(); add_child(cam_pivot)
	cam = Camera3D.new(); cam.fov = 28.0; cam.far = 400.0; cam_pivot.add_child(cam)
	cam.current = true
	var ca := CameraAttributesPractical.new(); ca.dof_blur_far_enabled = true; ca.dof_blur_far_distance = 48.0; ca.dof_blur_far_transition = 30.0; ca.dof_blur_amount = 0.05
	cam.attributes = ca

func cell_pos(c: Vector2i) -> Vector3:
	return Vector3(c.x - W / 2.0 + 0.5, heights.get(c, 0) * STEP, c.y - H / 2.0 + 0.5)

func inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < W and c.y < H

func gen_map() -> void:
	var mp: Dictionary = bdef.map
	W = int(mp.get("w", 12)); H = int(mp.get("h", 10))
	var sd := int(mp.seed)
	var rng := RandomNumberGenerator.new(); rng.seed = sd
	var fn := FastNoiseLite.new(); fn.seed = sd; fn.frequency = 0.14; fn.fractal_octaves = 2
	var amp: float = float(mp.amp)
	var hh := {}
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			var v: float = (fn.get_noise_2d(x * 1.0, y * 1.0) + 0.6) * 0.8 * (amp + 0.8)
			if mp.get("plateau", false): v += clampf((x + y - 11) * 0.3, 0.0, 1.5)
			if x + y <= 4: v = minf(v, 1.0)
			hh[c] = clampi(int(round(v)), 0, 4)
	water_cells = []; LAVA_CELLS = []; fall_cell = Vector2i(-1, -1)
	if mp.get("river", false):
		var x := rng.randi_range(W / 3, W - 5)
		for y in H:
			water_cells.append(Vector2i(x, y))
			if y < H - 1 and y > 1 and rng.randf() < 0.35:
				var nx := clampi(x + (1 if rng.randf() < 0.5 else -1), W / 3 - 1, W - 4)
				water_cells.append(Vector2i(nx, y)); x = nx
		fall_cell = Vector2i(x, H - 1)
	var wr := int(mp.get("water_rows", 0))
	for y in range(H - wr, H):
		for x in range(0, W * 5 / 12):
			if not Vector2i(x, y) in water_cells: water_cells.append(Vector2i(x, y))
	if wr > 0 and fall_cell.x < 0: fall_cell = Vector2i(2, H - 1)
	for c in water_cells: hh[c] = 0
	if mp.get("lava", false):
		LAVA_CELLS = water_cells.duplicate(); water_cells = []; fall_cell = Vector2i(-1, -1)
		var keep: Array = []
		for c in LAVA_CELLS:
			if c.y % 4 == 2 or c.y == H - 1: keep.append(c)
		for c in keep: LAVA_CELLS.erase(c)
	var changed := true
	while changed:
		changed = false
		for c in hh:
			for d in DIRS:
				var n: Vector2i = c + d
				if hh.has(n) and hh[c] - hh[n] > 2:
					hh[c] -= 1; changed = true
	heights = hh
	road_cells = {}
	var ry := rng.randi_range(2, 5)
	for x in W:
		var c := Vector2i(x, ry)
		if not c in water_cells and not c in LAVA_CELLS: road_cells[c] = true
		if rng.randf() < 0.3 and x < W - 1:
			ry = clampi(ry + (1 if rng.randf() < 0.5 else -1), 1, H - 2)
			var c2 := Vector2i(x, ry)
			if not c2 in water_cells and not c2 in LAVA_CELLS: road_cells[c2] = true
	ROCK_CELLS = []
	var tries := 0
	while ROCK_CELLS.size() < int(mp.rocks) and tries < 300:
		tries += 1
		var c := Vector2i(rng.randi_range(1, W - 2), rng.randi_range(1, H - 2))
		if c.x + c.y <= 4 or (W - 1 - c.x) + (H - 1 - c.y) <= 3: continue
		if c in ROCK_CELLS or c in water_cells or c in LAVA_CELLS or road_cells.has(c): continue
		ROCK_CELLS.append(c)
		if not connected(): ROCK_CELLS.erase(c)
	var free: Array = []
	for c in hh:
		if not c in ROCK_CELLS and not c in LAVA_CELLS: free.append(c)
	free.sort_custom(func(a, b): return (a.x + a.y) * 100 + a.x < (b.x + b.y) * 100 + b.x)
	spawn_p = free.slice(0, 8)
	var ef: Array = free.filter(func(c): return not c in spawn_p)
	ef.sort_custom(func(a, b): return (W - 1 - a.x + H - 1 - a.y) * 100 - hh[a] * 30 < (W - 1 - b.x + H - 1 - b.y) * 100 - hh[b] * 30)
	spawn_boss = Vector2i(-1, -1)
	if bdef.get("boss") != null:
		var bb: Vector2i = ef[0]
		for i in mini(8, ef.size()):
			if hh[ef[i]] > hh[bb]: bb = ef[i]
		spawn_boss = bb; ef.erase(bb)
	spawn_e = ef.slice(0, 16)
	MAP = []
	for y in H:
		var row := ""
		for x in W: row += str(hh[Vector2i(x, y)])
		MAP.append(row)
	print("MAP ", bidx + 1, " ", bdef.name, " ", MAP, " rocks=", ROCK_CELLS.size(), " water=", water_cells.size(), " lava=", LAVA_CELLS.size(), " conn=", connected())

func connected() -> bool:
	var blocked := {}
	for c in ROCK_CELLS: blocked[c] = true
	for c in LAVA_CELLS: blocked[c] = true
	var total := W * H - blocked.size()
	var st0 := Vector2i(0, 0)
	if blocked.has(st0): return false
	var seen := {st0: true}; var q := [st0]
	while q.size() > 0:
		var c: Vector2i = q.pop_front()
		for d in DIRS:
			var n: Vector2i = c + d
			if n.x < 0 or n.y < 0 or n.x >= W or n.y >= H or seen.has(n) or blocked.has(n): continue
			if absi(heights[n] - heights[c]) > 2: continue
			seen[n] = true; q.append(n)
	return seen.size() == total


func build_map() -> void:
	var tm := ShaderMaterial.new(); var tsh := Shader.new(); tsh.code = TER_SH; tm.shader = tsh
	tm.set_shader_parameter("tg", load("res://assets/v12/%s.png" % TH.get("gt", "t_grass"))); tm.set_shader_parameter("tc", load("res://assets/v12/%s.png" % TH.get("ct", "t_cliff")))
	tm.set_shader_parameter("sc", 0.5); tm.set_shader_parameter("top_tint", TH.tint); tm.set_shader_parameter("side_tint", TH.get("side", Vector3(1.05, 1.02, 1.08)))
	tm.set_shader_parameter("snow", TH.snow); tm.set_shader_parameter("moss_col", TH.moss)
	var rm := tm.duplicate(); rm.set_shader_parameter("tg", load("res://assets/v12/t_path.png")); rm.set_shader_parameter("top_tint", Vector3(1.0, 0.95, 0.85) * TH.tint / Vector3(1.0, 1.12, 1.0)); rm.set_shader_parameter("snow", TH.snow * 0.5)
	var km := tm.duplicate(); km.set_shader_parameter("tg", load("res://assets/v12/t_cliff.png")); km.set_shader_parameter("top_tint", Vector3(1.05, 1.0, 0.92))
	mats.ter = tm; mats.road = rm; mats.rocktop = km
	var trng := RandomNumberGenerator.new(); trng.seed = 4
	tm.set_shader_parameter("nz", noise_tex)
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			var top: float = heights[c] * STEP
			var p := cell_pos(c)
			var depth := top + 1.6
			var sb := StaticBody3D.new()
			var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = Vector3(1, depth, 1)
			cs.shape = bs; sb.add_child(cs); sb.position = Vector3(p.x, top - depth / 2.0, p.z)
			sb.set_meta("cell", c)
			add_child(sb)
	build_terrain(tm, rm, km)
	cursor_ring = MeshInstance3D.new()
	var tor := TorusMesh.new(); tor.inner_radius = 0.4; tor.outer_radius = 0.47
	cursor_ring.mesh = tor; cursor_ring.material_override = glow(Color(1.0, 0.8, 0.3), 0.9, 2.5)
	add_child(cursor_ring); cursor_ring.visible = false

func grass_mesh() -> ArrayMesh:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new(); rng.seed = 5
	for i in 7:
		var a := rng.randf() * TAU; var r := rng.randf() * 0.12
		var b := Vector3(cos(a) * r, 0, sin(a) * r)
		var side := Vector3(-sin(a), 0, cos(a)) * 0.035
		var hgt := rng.randf_range(0.3, 0.55)
		var tipv := b + Vector3(cos(a) * 0.12, hgt, sin(a) * 0.12)
		st.set_color(Color(1, 1, 1)); st.set_uv(Vector2(0, 0)); st.add_vertex(b - side)
		st.set_uv(Vector2(1, 0)); st.add_vertex(b + side)
		st.set_uv(Vector2(0.5, 1)); st.add_vertex(tipv)
	st.generate_normals()
	return st.commit()

func in_keepout(p: Vector3) -> bool:
	if absf(p.x) < 6.6 and absf(p.z) < 5.6: return true          # 戰場
	if p.z < -9.0 and p.z > -14.5 and p.x > -9.0 and p.x < 15.0: return true  # 城牆
	if p.z < -14.5 and p.x > -9.0 and p.x < 15.0: return true    # 城內
	if absf(p.x + 11.0) < 2.4: return true                       # 河
	if p.x > -1.2 and p.x < 1.2 and p.z < -5.0: return true      # 城門道路
	return false

func lowpoly(mesh: Mesh, rng: RandomNumberGenerator, jit: float) -> ArrayMesh:
	var stt := SurfaceTool.new(); stt.create_from(mesh, 0)
	var arr := stt.commit_to_arrays(); var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var jm := {}
	for i in vs.size():
		var k := Vector3i(roundi(vs[i].x * 1000), roundi(vs[i].y * 1000), roundi(vs[i].z * 1000))
		if not jm.has(k): jm[k] = Vector3(rng.randf_range(-jit, jit), rng.randf_range(-jit, jit), rng.randf_range(-jit, jit))
		vs[i] += jm[k]
	arr[Mesh.ARRAY_VERTEX] = vs; arr[Mesh.ARRAY_NORMAL] = null; arr[Mesh.ARRAY_TANGENT] = null
	var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var s2 := SurfaceTool.new(); s2.create_from(am, 0); s2.deindex(); s2.generate_normals(false)
	return s2.commit()

func build_scenery() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 9
	var rockm := StandardMaterial3D.new(); rockm.albedo_texture = load("res://assets/v12/%s.png" % TH.get("ct", "t_cliff")); rockm.uv1_triplanar = true; rockm.uv1_scale = Vector3.ONE * 0.6
	rockm.albedo_color = TH.get("rockc", Color(0.9, 0.92, 1.0)); rockm.roughness = 0.95
	# 島底倒錐（漂浮）
	var cone := lowpoly(cyl(8.2, 0.6, 9.0, 9), rng, 0.6)
	mi(self, cone, Vector3(0, -2.6 - 4.5, 0), rockm, Vector3(0, 0.3, 0), Vector3(1.0, 1.0, 0.85))
	var cone2 := lowpoly(cyl(4.2, 0.3, 6.0, 7), rng, 0.4)
	mi(self, cone2, Vector3(2.5, -9.0, 1.5), rockm, Vector3(0, 1.0, 0))
	# 岩塊
	var spots := [Vector2(-6.6, -3.0), Vector2(6.7, 2.4), Vector2(-4.0, 5.7), Vector2(4.6, -5.6), Vector2(6.8, -4.6), Vector2(-6.7, 4.2), Vector2(1.8, 5.7), Vector2(-2.6, -5.7)]
	for sp in spots:
		var base: float = ground_y(Vector2(sp.x, sp.y)) - 0.25
		var r := rng.randf_range(0.35, 0.7)
		var rk := lowpoly(sph(r, 6), rng, r * 0.25)
		mi(self, rk, Vector3(sp.x, base + r * 0.5, sp.y), rockm, Vector3(rng.randf(), rng.randf() * TAU, 0), Vector3(1.0, rng.randf_range(0.7, 1.3), 1.0))
	# 稜角岩（FFT 參考圖密度）
	var crag := func(pos: Vector3, r: float, hgt: float):
		var sides := rng.randi_range(4, 6)
		var top_r := r * rng.randf_range(0.0, 0.45)
		var m := lowpoly(cyl(top_r, r, hgt, sides), rng, r * 0.22)
		mi(self, m, pos + Vector3(0, hgt * 0.5 - 0.08, 0), rockm, Vector3(rng.randf_range(-0.15, 0.15), rng.randf() * TAU, rng.randf_range(-0.15, 0.15)))
	for y in range(-2, H + 2):
		for x in range(-2, W + 2):
			if x >= 0 and y >= 0 and x < W and y < H: continue
			if rng.randf() > 0.72: continue
			if not outer_top.has(Vector2i(x, y)): continue
			var top: float = outer_top[Vector2i(x, y)] - 0.04
			for n in rng.randi_range(1, 2):
				var r := rng.randf_range(0.3, 0.62)
				crag.call(Vector3(x - W / 2.0 + 0.5 + rng.randf_range(-0.3, 0.3), top, y - H / 2.0 + 0.5 + rng.randf_range(-0.3, 0.3)), r, r * rng.randf_range(1.2, 2.4))
	# 格角小岩與石片（不擋格心）
	for y in range(0, H + 1):
		for x in range(0, W + 1):
			if rng.randf() > 0.3: continue
			var hs: Array = []
			for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
				var cc: Vector2i = Vector2i(x, y) + d
				if inside(cc): hs.append(heights[cc])
			if hs.is_empty(): continue
			var mn: int = hs.min()
			var r := rng.randf_range(0.1, 0.2)
			crag.call(Vector3(x - W / 2.0, mn * STEP - 0.02, y - H / 2.0), r, r * rng.randf_range(1.0, 2.2))
	# 場內獨立大岩石（不可行走）
	for rc in ROCK_CELLS:
		var rp := cell_pos(rc)
		crag.call(rp + Vector3(0.05, -0.05, -0.05), 0.48, 1.5)
		crag.call(rp + Vector3(-0.28, -0.05, 0.22), 0.3, 0.8)
		crag.call(rp + Vector3(0.3, -0.05, 0.25), 0.22, 0.55)
	if TH.grass: build_grass(rng)
	build_details(rng)
	# 低多邊形樹
	var trunk := StandardMaterial3D.new(); trunk.albedo_color = Color(0.36, 0.24, 0.16); trunk.roughness = 1.0
	var leaf := shmat(WIND_SH); leaf.set_shader_parameter("col", TH.leaf)
	var leaf2 := shmat(WIND_SH); leaf2.set_shader_parameter("col", TH.leaf * 1.3)
	var tree_spots: Array = []
	var ok: Array = outer_top.keys()
	ok.sort()
	var tstyle: String = TH.get("tree", "pine")
	var tcount := 0 if tstyle == "none" else int(round(float(bdef.map.trees) * float(TH.get("tree_mul", 1.0))))
	for i in tcount:
		var oc: Vector2i = ok[rng.randi() % ok.size()]
		tree_spots.append(Vector2(oc.x - W / 2.0 + 0.5 + rng.randf_range(-0.2, 0.2), oc.y - H / 2.0 + 0.5 + rng.randf_range(-0.2, 0.2)))
	for tp in tree_spots:
		var base: float = ground_y(Vector2(tp.x, tp.y)) - 0.15
		var s := rng.randf_range(0.8, 1.2)
		build_tree(tstyle, Vector3(tp.x, base, tp.y), s, rng, trunk, leaf, leaf2)
	build_props(rng, rockm)
	# 旗竿（帝國旗）
	var pole := StandardMaterial3D.new(); pole.albedo_color = Color(0.3, 0.22, 0.16)
	var fl := shmat(SH.FLAG); fl.set_shader_parameter("cloth", Color(0.36, 0.08, 0.32) if bdef.theme == "throne" else Color(0.5, 0.1, 0.07))
	var fq := quad(0.8, 0.55); fq.subdivide_width = 10; fq.subdivide_depth = 4
	var flag_pos: Array = []
	for fc0 in [[Vector2i(W - 1, H - 1), Vector3(0.38, 0, 0.38)], [Vector2i(W - 1, 0), Vector3(0.4, 0, -0.42)], [Vector2i(0, H - 1), Vector3(-0.42, 0, 0.4)]]:
		if fc0[0] in LAVA_CELLS or fc0[0] in water_cells: continue
		flag_pos.append(cell_pos(fc0[0]) + fc0[1])
	for bp0 in flag_pos:
		var bp: Vector3 = bp0
		mi(self, cyl(0.03, 0.04, 2.4, 6), bp + Vector3(0, 1.2, 0), pole)
		mi(self, fq, bp + Vector3(0.41, 2.0, 0), fl)
		# 火把
		mi(self, cyl(0.035, 0.03, 0.9, 6), bp + Vector3(0.18, 0.45, 0.18), pole)
		var fp := fire_particles(bp + Vector3(0.18, 0.95, 0.18), 24, 0.05, 0.7)
		var tl := OmniLight3D.new(); tl.light_color = Color(1, 0.6, 0.25); tl.light_energy = 1.4; tl.omni_range = 3.6; tl.omni_attenuation = 1.4; tl.position = bp + Vector3(0.18, 1.05, 0.18); add_child(tl); torches.append(tl)
	build_sky_life()
	build_weather()
	# 浮游塵埃
	var dust := GPUParticles3D.new(); dust.amount = 110; dust.lifetime = 9.0; dust.preprocess = 9.0
	var dm := ParticleProcessMaterial.new(); dm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX; dm.emission_box_extents = Vector3(9, 2.5, 8)
	dm.gravity = Vector3(0.05, 0.02, 0.03); dm.initial_velocity_min = 0.05; dm.initial_velocity_max = 0.2; dm.spread = 180
	dm.scale_min = 0.5; dm.scale_max = 1.0
	dust.process_material = dm
	var dq := quad(0.05, 0.05); var dmat := particle_mat("glow.png", Color(1, 0.85, 0.6, 0.75)); dq.material = dmat
	dust.draw_pass_1 = dq; dust.position = Vector3(0, 2.5, 0); add_child(dust)

func particle_mat(t: String, c: Color, add := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = load("res://assets/ui/" + t); m.albedo_color = c
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if add: m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.no_depth_test = false
	return m

func fire_particles(pos: Vector3, amount: int, radius: float, size: float) -> GPUParticles3D:
	var p := GPUParticles3D.new(); p.amount = amount; p.lifetime = 0.7
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE; pm.emission_sphere_radius = radius
	pm.gravity = Vector3(0, 1.6, 0); pm.initial_velocity_min = 0.1; pm.initial_velocity_max = 0.5; pm.direction = Vector3(0, 1, 0); pm.spread = 25
	pm.scale_min = 0.6; pm.scale_max = 1.0
	var sc := Curve.new(); sc.add_point(Vector2(0, 1)); sc.add_point(Vector2(1, 0.1)); var ct := CurveTexture.new(); ct.curve = sc; pm.scale_curve = ct
	var g := Gradient.new(); g.set_color(0, Color(1, 0.8, 0.35, 1)); g.set_color(1, Color(0.8, 0.15, 0.02, 0))
	var gt := GradientTexture1D.new(); gt.gradient = g; pm.color_ramp = gt
	p.process_material = pm
	var q := quad(size * 0.4, size * 0.4); q.material = particle_mat("glow.png", Color.WHITE); p.draw_pass_1 = q
	p.position = pos; add_child(p)
	return p

# ---------------- 角色模型（Quaternius Universal Base Characters＋Universal Animation Library，CC0） ----------------
# 沿用舊動畫名稱（KayKit 命名）→ UAL 動畫，原有 play() 呼叫全部不用改
const HUMAN_SCALE := 0.8
# v8 精緻Q版：頭部放大倍率與身體壓縮
const CHIBI_F := 2.0
const CHIBI_SQ := 0.82
const CHIBI_SXZ := 1.08
var ual_lib: AnimationLibrary
var human_cache := {}
var outfit_cache := {}
var human_shader: Shader
var hair_shader: Shader

# 服裝：依靜止姿勢位置把身體網格頂點分區，寫入材質編號（COLOR.r）與滾邊（COLOR.g），並依材質厚度沿法線外擴
# 部位材質：0 皮膚 1 上衣 2 褲 3 皮革 4 板甲 5 鎖甲 6 長袍
# 以骨骼為原點、但座標軸對齊身體（T-pose）的掛點，方便以公尺直接擺放裝備
# Q 版頭部中心（世界座標）
# 武器在手骨座標：握把在掌心，刃朝 +Z（拇指方向）
# 主角專屬外觀：金髮（UBC 髮型＋分層暖金色調）、金冠、深藍金邊太陽紋披風＋毛領、金肩甲、黎明王劍光刃
# 兩點之間放一段圓錐／圓柱（Y 軸對齊 a→b）
# 每位角色的特色配件（皮帶扣、腰包、箭筒、法器吊飾、肩甲雕花、披巾、頭飾…）
func hero_aura(node: Node3D) -> void:
	var p := GPUParticles3D.new(); p.amount = 28; p.lifetime = 1.8
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING; pm.emission_ring_radius = 0.38; pm.emission_ring_inner_radius = 0.2; pm.emission_ring_height = 0.05; pm.emission_ring_axis = Vector3.UP
	pm.gravity = Vector3(0, 0.6, 0); pm.initial_velocity_min = 0.1; pm.initial_velocity_max = 0.3; pm.direction = Vector3.UP
	pm.scale_min = 0.5; pm.scale_max = 1.0
	var g := Gradient.new(); g.set_color(0, Color(1, 0.95, 0.7, 1)); g.set_color(1, Color(1, 0.7, 0.2, 0)); var gt := GradientTexture1D.new(); gt.gradient = g; pm.color_ramp = gt
	p.process_material = pm
	var q := quad(0.07, 0.07); q.material = particle_mat("spark.png", Color(1, 0.85, 0.45)); p.draw_pass_1 = q
	p.position.y = 0.1; node.add_child(p)

func play(u, a: String, blend := 0.15, speed := 1.0) -> void:
	if not u.has("sanim"): return
	var n := "idle"
	if a in ["Running_A", "Walking_A"]: n = "walk"
	elif a.contains("Attack") or a.contains("Shoot"): n = "atk"
	elif a in ["Spellcasting", "Cheer", "Spellcast_Raise"]: n = "cast"
	elif a.begins_with("Hit") or a == "Block" or a.begins_with("Dodge"): n = "hurt"
	elif a.begins_with("Death"): n = "death"
	u.sanim = {"n": n, "t": 0.0, "sp": speed}

func tick_sprite(u, d: float, cf: Vector3, cr: Vector3) -> void:
	var an: Dictionary = u.sanim
	an.t += d * float(an.get("sp", 1.0))
	var nn: String = an.n
	if nn == "win" and int(u.get("ncols", 24)) < 28: nn = "cast"
	var def: Array = SANIM[nn]
	var fr: Array = def[0]; var i := int(an.t / float(def[1]))
	i = i % fr.size() if def[2] else mini(i, fr.size() - 1)
	var ry: float = u.node.rotation.y
	if u.get("big", false):
		var off := Vector3(0.5, 0, 0.5).rotated(Vector3.UP, -ry)
		u.body.position.x = off.x; u.body.position.z = off.z
	var f := Vector3(sin(ry), 0, cos(ry))
	var front := f.dot(-cf) > -0.05
	u.smat.set_shader_parameter("frame", fr[i])
	u.smat.set_shader_parameter("row", 0 if front else 1)
	u.smat.set_shader_parameter("flip", 1.0 if (f.dot(cr) < 0.0) == front else 0.0)

# ---------------- 單位 ----------------
func st(u, k: String) -> int:
	var w: Dictionary = G.W[u.weapon]; var a: Dictionary = G.A[u.armor]
	var v := int(u.base.get(k, 0)) + int(w.get(k, 0)) + int(a.get(k, 0)) + int(u.buff.get(k, 0))
	if k == "atk" and float(w.get("grow", 0.0)) > 0.0: v += int(float(w.grow) * float(u.lv))
	if k == "spd" and u.status.has("slow"): v = int(v * 0.6)
	if k == "spd" and u.status.has("haste"): v = int(v * 1.35) + 1
	if k == "def" and u.status.has("shield"): v += 6 + int(v * 0.25)
	if k == "move": v += int(wx().mv)
	if k == "spd" or k == "move" or k == "jump": v = max(v, 1)
	return v

func eff(u, k: String) -> int:
	return int(G.W[u.weapon].get(k, 0)) + int(G.A[u.armor].get(k, 0))

func immune(u, k: String) -> bool:
	if eff(u, "no" + k) > 0:
		popup(u.node.position + Vector3(0, 0.7, 0), "抗毒" if k == "poison" else "抗暈", Color(0.8, 0.9, 1)); return true
	return false

func set_status(u, k: String, v: int) -> bool:
	if immune(u, k): return false
	u.status[k] = v; return true

func players() -> Array: return units.filter(func(u): return u.team == 0)
func alive_team(t: int) -> Array: return units.filter(func(u): return u.team == t and u.alive)
func foes(u) -> Array: return alive_team(1 - u.team)

func unit_at(c: Vector2i):
	for u in units:
		if u.alive and u.cell == c: return u
	for u in units:
		if u.alive and u.get("big", false):
			var dd: Vector2i = c - u.cell
			if dd.x >= 0 and dd.y >= 0 and dd.x <= 1 and dd.y <= 1: return u
	return null

# v16：法典巨像佔 2×2 格
func big_fits(u, c: Vector2i) -> bool:
	for dd in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		var n: Vector2i = c + dd
		if not inside(n) or n in ROCK_CELLS or n in LAVA_CELLS: return false
		var o = unit_at(n)
		if o != null and o != u: return false
	return true

func add_unit(n: String, job: String, team: int, base: Dictionary, w: String, a: String, c: Vector2i, model: String, look: Dictionary, scl := 1.0, title := "", extra := {}):
	var u := {"name": n, "job": job, "team": team, "base": base, "weapon": w, "armor": a, "cell": c, "alive": true, "ct": 0,
		"model": model, "key": model, "look": look, "title": title, "lv": 1, "member": null, "buff": {}, "buff_t": 0, "status": {}, "turns": 0, "boss": false, "hero": false,
		"sk_mult": 1.0, "sk_drain": 0, "sk_poison": 0, "sk_pierce": 0, "phase": 0}
	u.merge(extra, true)
	if model == "colossus": u.big = true
	var node := Node3D.new(); add_child(node)
	u.node = node
	var sb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var cap := CapsuleShape3D.new(); cap.radius = 0.3; cap.height = 1.3
	cs.shape = cap; cs.position.y = 0.65; sb.add_child(cs); sb.set_meta("unit_idx", units.size()); node.add_child(sb)
	var body := Node3D.new(); node.add_child(body)
	var hq := 1.5 * scl
	var sm := ShaderMaterial.new(); sm.shader = spr_shader
	var qm := QuadMesh.new(); qm.size = Vector2(hq * 1.3, hq * 1.3); qm.center_offset = Vector3(0, hq * 1.3 * (0.5 - 3.0 / 128.0), 0)
	u.qm = qm; u.scl = scl
	var q := MeshInstance3D.new(); q.mesh = qm; q.material_override = sm; q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; body.add_child(q)
	var shd := MeshInstance3D.new(); var spm := PlaneMesh.new(); spm.size = Vector2(0.8, 0.6) * scl; shd.mesh = spm; shd.position.y = 0.02
	var shm := StandardMaterial3D.new(); shm.albedo_texture = load("res://assets/ui/shadow_blob.png"); shm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; shm.albedo_color = Color(0.1, 0.05, 0.12, 0.85); shd.material_override = shm
	shd.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; node.add_child(shd)
	u.body = body; u.mats = [sm]; u.smat = sm; u.sanim = {"n": "idle", "t": 0.0}
	u.portrait = load("res://assets/v12/p_%s.png" % model)
	if u.hero:
		hero_aura(node)
	# 腳下陣營光環
	var ring := MeshInstance3D.new(); var tor := TorusMesh.new(); tor.inner_radius = 0.3; tor.outer_radius = 0.36; tor.rings = 24
	ring.mesh = tor; ring.position.y = 0.04; ring.scale = Vector3(1, 0.15, 1)
	ring.material_override = glow(Color(0.85, 0.25, 1.0) if u.boss else Color(1.0, 0.8, 0.3) if u.get("hero", false) else (Color(0.3, 0.6, 1.0) if team == 0 else Color(1.0, 0.25, 0.15)), 0.45, 1.6)
	node.add_child(ring); u.ring = ring
	var lab := Label3D.new(); lab.font = font_bold; lab.font_size = 34; lab.pixel_size = 0.0031 * G.font_k(); lab.outline_size = int(12 * G.font_k()); lab.outline_modulate = Color(0, 0, 0, 1)
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED; lab.position.y = 2.05 * scl; lab.no_depth_test = true
	lab.modulate = Color(0.8, 0.9, 1) if team == 0 else Color(1, 0.75, 0.68)
	lab.outline_modulate = Color(0.05, 0.03, 0.02)
	node.add_child(lab); u.label = lab
	# 頭上 HP 條
	var hb := Node3D.new(); hb.position.y = 1.9 * scl; node.add_child(hb)
	var bg := Sprite3D.new(); bg.texture = load("res://assets/ui/bar_bg.png"); bg.pixel_size = 0.009; bg.billboard = BaseMaterial3D.BILLBOARD_ENABLED; bg.no_depth_test = true; bg.render_priority = 1
	bg.centered = false; bg.offset = Vector2(-32, -8); bg.scale = Vector3(1, 0.55, 1)
	hb.add_child(bg)
	var fg := Sprite3D.new(); fg.texture = load("res://assets/ui/bar_hp.png" if team == 0 else "res://assets/ui/bar_enemy.png"); fg.pixel_size = 0.009
	fg.billboard = BaseMaterial3D.BILLBOARD_ENABLED; fg.no_depth_test = true; fg.render_priority = 2
	fg.centered = false; fg.offset = Vector2(-31, -7); fg.region_enabled = true; fg.region_rect = Rect2(0, 0, 62, 14); fg.scale = Vector3(1, 0.55, 1)
	hb.add_child(fg)
	u.hpbar = fg; u.hpbar_root = hb
	units.append(u)
	u.hp = st(u, "hp"); u.mp = st(u, "mp")
	node.position = cell_pos(c)
	node.rotation.y = 0.0 if team == 0 else PI
	refresh_look(u)
	update_label(u)
	u.rage = 0; rage_bar_make(u); update_rage(u)   # v20：怒氣每場重置
	return u

const WVAR := {"rain": {"大劍": "_gs"}, "grey": {"巨斧": "_ga"}}
func weapon_color(wn: String) -> Color:
	if wn == "" or not G.W.has(wn): return Color(1, 1, 1, 0)
	var w: Dictionary = G.W[wn]; var t := int(w.get("tier", 0))
	var a := clampf(0.25 + t * 0.07, 0.0, 0.9)
	for e in [[["炎", "紅蓮", "火", "伊弗利特", "赤", "熔"], Color(1.0, 0.42, 0.15)], [["冰", "霜", "雪"], Color(0.45, 0.8, 1.0)], [["聖", "王者", "黎明", "金", "光", "天"], Color(1.0, 0.84, 0.35)],
			[["黑", "魔", "暗", "黃昏", "冥", "血", "噬", "屠"], Color(0.7, 0.25, 0.85)], [["世界樹", "森", "綠", "風", "翠"], Color(0.4, 1.0, 0.5)], [["秘銀", "銀", "星", "月"], Color(0.75, 0.9, 1.0)]]:
		for kw in e[0]:
			if wn.contains(kw): return Color(e[1].r, e[1].g, e[1].b, a + 0.15)
	if t <= 1: return Color(1, 1, 1, 0)
	return Color(0.85, 0.88, 0.95, a * 0.6)

func refresh_look(u) -> void:
	var k: String = u.key
	var wn: String = str(u.get("weapon", ""))
	var suf := ""
	if WVAR.has(k) and G.W.has(wn): suf = WVAR[k].get(G.W[wn].type, "")
	if ucls(u) != "": k = ucls(u); suf = ""   # v16：晉升職業貼圖
	var tex: Texture2D = load("res://assets/v12/spr/%s%s.png" % [k, suf])
	u.smat.set_shader_parameter("tex", tex)
	# v16：依貼圖格大小（頭目 192/256px）調整看板尺寸與欄數
	var cell := float(tex.get_height()) / 2.0
	var cols := int(round(float(tex.get_width()) / cell)); u.ncols = cols
	u.smat.set_shader_parameter("grid", Vector2(cols, 2))
	if cell > 129.0 and u.has("qm"):
		var cf := cell / 128.0
		if not u.boss: cf = 1.0 + (cf - 1.0) * 0.5
		var hq: float = 1.5 * float(u.get("scl", 1.0)) * cf
		u.qm.size = Vector2(hq * 1.3, hq * 1.3); u.qm.center_offset = Vector3(0, hq * 1.3 * (0.5 - 4.0 / cell), 0)
		var top := hq * 1.3 * 0.95
		u.label.position.y = top + 0.15; u.hpbar_root.position.y = top
	var mp := "res://assets/v12/spr/%s%s_wm.png" % [k, suf]
	if ResourceLoader.exists(mp) and not OS.get_environment("V14OFF").contains("wm"):
		u.smat.set_shader_parameter("wm", load(mp))
		var wc := weapon_color(wn); u.smat.set_shader_parameter("wcol", wc)
		var pulse := 0.0
		if G.W.has(wn) and (int(G.W[wn].get("tier", 0)) >= 6 or wn == "黎明王劍"): pulse = 0.6
		u.smat.set_shader_parameter("wpulse", pulse)
	else:
		u.smat.set_shader_parameter("wcol", Color(1, 1, 1, 0)); u.smat.set_shader_parameter("wpulse", 0.0)
	if utier(u) >= 2 and not u.has("aura"): promo_aura(u)
	if u.alive: play(u, idle_anim(u), 0.2)

func update_label(u) -> void:
	var tag := ""
	if u.status.has("poison"): tag += "〔毒〕"
	if u.status.has("stun"): tag += "〔暈〕"
	refresh_status_icons(u)
	u.label.text = ("♛ " if u.get("hero", false) else "") + "%s Lv%d%s" % [u.name, u.lv, tag]
	var r: float = clampf(float(u.hp) / float(st(u, "hp")), 0.0, 1.0)
	u.hpbar.region_rect = Rect2(1, 1, 62.0 * r, 14)

func set_flash(u, c: Color) -> void:
	for m in u.mats: m.set_shader_parameter("flash", c)

func hit_flash(u, c: Color) -> void:
	var tw := create_tween()
	tw.tween_method(func(a): set_flash(u, Color(c.r, c.g, c.b, a)), 1.6, 0.0, 0.35)

func build_units() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = int(bdef.map.seed) * 3 + 1
	var i := 0
	for m in G.roster:
		if i >= spawn_p.size(): break
		add_unit(m.name, m.job, 0, m.base, m.weapon, m.armor, spawn_p[i], m.key, {}, 1.06 if m.get("hero", false) else 1.0, m.title, {"member": m, "lv": int(m.lv), "hero": m.get("hero", false)})
		i += 1
	var ei := 0
	for e in bdef.enemies:
		for k in int(e.n):
			if ei >= spawn_e.size(): break
			var em := G.enemy_member(e.t, bidx, int(e.lv), rng)
			add_unit(e.t, em.job, 1, em.base, em.weapon, em.armor, spawn_e[ei], em.key, {}, 1.0, em.title, {"lv": int(em.lv)})
			ei += 1
	if bdef.get("boss") != null:
		var bm := G.boss_member(bdef.boss, bidx)
		add_unit(bm.name, bm.job, 1, bm.base, bm.weapon, bm.armor, spawn_boss, bm.key, {}, bm.scale, bm.title, {"lv": int(bm.lv), "boss": true, "skill": bm.skill, "bdef": bdef.boss})
	for u in units:
		var to: Vector3 = Vector3.ZERO - u.node.position
		u.node.rotation.y = atan2(to.x, to.z)
	if autotest and not autolose and not OS.get_environment("V14OFF").contains("assist"):
		# 自動測試勝利模式：AI 操作玩家方，給予小幅加成以穩定驗證勝利流程（不影響正式遊戲）
		for u in players(): u.base = u.base.duplicate(); u.base.hp = int(u.base.hp * 1.25); u.hp = st(u, "hp"); u.base.atk = int(u.base.atk * 1.15); u.base.mag = int(u.base.mag * 1.15)
	if autolose:
		for u in alive_team(1): u.base = u.base.duplicate(); u.base.atk += 80; u.base.mag += 80
		for u in players(): u.base = u.base.duplicate(); u.hp = 12; u.base.atk = 1; u.base.mag = 1
	for u in units: update_label(u)

# ---------------- 介面 ----------------
func uitex(n: String) -> Texture2D:
	return load("res://assets/ui/" + n)

func sbt(n: String, m: int, pad := 6) -> StyleBoxTexture:
	var s := StyleBoxTexture.new(); s.texture = uitex(n)
	s.texture_margin_left = m; s.texture_margin_right = m; s.texture_margin_top = m; s.texture_margin_bottom = m
	s.content_margin_left = m + pad; s.content_margin_right = m + pad; s.content_margin_top = m + pad - 4; s.content_margin_bottom = m + pad - 4
	return s

func panel(pos: Vector2, size: Vector2, kind := "panel.png") -> PanelContainer:
	var p := PanelContainer.new(); p.position = pos; p.size = size
	p.add_theme_stylebox_override("panel", sbt(kind, 16, 4))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.draw.connect(func():
		var sz := p.size
		for cp in [Vector2(7, 7), Vector2(sz.x - 7, 7), Vector2(7, sz.y - 7), Vector2(sz.x - 7, sz.y - 7)]:
			var d := PackedVector2Array([cp + Vector2(0, -6), cp + Vector2(6, 0), cp + Vector2(0, 6), cp + Vector2(-6, 0)])
			p.draw_colored_polygon(d, Color(0.95, 0.75, 0.32))
			p.draw_polyline(d + PackedVector2Array([d[0]]), Color(0.35, 0.18, 0.05), 1.5)
		p.draw_line(Vector2(18, 3), Vector2(sz.x - 18, 3), Color(1, 0.85, 0.5, 0.5), 1.0)
		p.draw_line(Vector2(18, sz.y - 3), Vector2(sz.x - 18, sz.y - 3), Color(0.2, 0.1, 0.03, 0.6), 1.0))
	ui_root.add_child(p); return p

func ink(c: Color) -> Color:
	if c.get_luminance() < 0.55: return c
	if c.r > 0.9 and c.b < 0.6 and c.g > 0.7: return Color(0.48, 0.2, 0.06)
	if c.b > c.r + 0.1: return Color(0.12, 0.22, 0.5)
	if c.r > c.g + 0.25: return Color(0.58, 0.1, 0.08)
	return Color(0.26, 0.17, 0.1)

func lbl(t: String, size := 20, col := Color(0.95, 0.9, 0.8), bold := false, raw := false) -> Label:
	var l := Label.new(); l.text = t; l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", col if raw else ink(col))
	if bold: l.add_theme_font_override("font", font_bold)
	if raw: l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func build_ui() -> void:
	var cl := CanvasLayer.new(); add_child(cl)
	ui_root = Control.new(); ui_root.set_anchors_preset(Control.PRESET_FULL_RECT); ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var th := Theme.new(); th.default_font = ui_font; th.default_font_size = 20
	for t in ["Button", "OptionButton"]:
		th.set_stylebox("normal", t, sbt("btn.png", 12, 4)); th.set_stylebox("hover", t, sbt("btn_hover.png", 12, 4))
		th.set_stylebox("pressed", t, sbt("btn_press.png", 12, 4)); th.set_stylebox("disabled", t, sbt("btn_dis.png", 12, 4))
		th.set_stylebox("focus", t, StyleBoxEmpty.new())
		th.set_color("font_color", t, Color(0.28, 0.17, 0.08)); th.set_color("font_hover_color", t, Color(0.55, 0.22, 0.05))
		th.set_color("font_pressed_color", t, Color(0.4, 0.15, 0.05)); th.set_color("font_disabled_color", t, Color(0.45, 0.42, 0.38))
		th.set_color("font_outline_color", t, Color(0.15, 0.03, 0.02)); th.set_constant("outline_size", t, 0)
	th.set_stylebox("panel", "PopupMenu", sbt("panel.png", 16, 2))
	th.set_stylebox("hover", "PopupMenu", sbt("btn_hover.png", 12, 0))
	th.set_color("font_color", "PopupMenu", Color(0.28, 0.17, 0.08)); th.set_color("font_hover_color", "PopupMenu", Color(0.55, 0.22, 0.05))
	th.set_color("font_outline_color", "Label", Color(0.05, 0.03, 0.02)); th.set_constant("outline_size", "Label", 0)
	ui_root.theme = th
	var vig := ColorRect.new(); vig.set_anchors_preset(Control.PRESET_FULL_RECT); vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vs := Shader.new(); vs.code = "shader_type canvas_item;\nvoid fragment(){ vec2 d = UV - 0.5; float v = smoothstep(0.42, 0.85, length(d * vec2(1.25, 1.0))); COLOR = vec4(0.06, 0.03, 0.02, v * 0.55); }"
	var vm := ShaderMaterial.new(); vm.shader = vs; vig.material = vm; cl.add_child(vig)
	cl.add_child(ui_root)
	# 標題牌
	var tp := panel(Vector2(540, 10), Vector2(520, 70)); title_panel = tp
	var tv := VBoxContainer.new(); tv.add_theme_constant_override("separation", -2); tp.add_child(tv)
	var t1 := lbl(G.chapter_title(bidx), 22, Color(1, 0.84, 0.45), true); t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tv.add_child(t1)
	turn_label = lbl("出陣準備", 18, Color(0.95, 0.9, 0.8)); turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tv.add_child(turn_label)
	# 行動順序
	var op := panel(Vector2(14, 14), Vector2(250, 420))
	var ov := VBoxContainer.new(); ov.add_theme_constant_override("separation", 4); op.add_child(ov)
	ov.add_child(lbl("行動順序", 22, Color(1, 0.84, 0.45), true))
	order_box = VBoxContainer.new(); order_box.add_theme_constant_override("separation", 3); ov.add_child(order_box)
	# 我方/當前角色卡
	card = make_card(Vector2(14, 676), Vector2(560, 210), 170)
	tcard = make_card(Vector2(1166, 706), Vector2(420, 180), 130)
	tcard.panel.visible = false
	# v22：純資訊面板不攔截點擊——手指點在面板下的格子也能選到（以前會被面板吃掉，感覺「點了沒反應」）
	order_panel = op
	for pn in [op, card.panel, tcard.panel]: _pass_mouse(pn)
	# 指令選單
	menu_panel = panel(Vector2(1330, 300), Vector2(256, 100))
	var mv := VBoxContainer.new(); mv.add_theme_constant_override("separation", 6); menu_panel.add_child(mv)
	mv.add_child(lbl("指令", 22, Color(1, 0.84, 0.45), true))
	menu_box = VBoxContainer.new(); menu_box.add_theme_constant_override("separation", 6); mv.add_child(menu_box)
	menu_panel.visible = false
	# 戰鬥紀錄
	var lk := G.font_k()
	log_label = lbl("", 18, Color(0.97, 0.93, 0.85), false, true); log_label.position = Vector2(588, 890 - 112 * lk); log_label.size = Vector2(570, 112 * lk)
	log_label.add_theme_constant_override("outline_size", 7); log_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; log_label.clip_text = false; log_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	ui_root.add_child(log_label)
	var help := lbl("左鍵 選擇／確定　右鍵・Esc 取消\nQ/E 旋轉　滾輪 縮放　WASD 平移　R 俯角", 17, Color(1.0, 0.97, 0.9), false, true)
	help.position = Vector2(1186, 12); help.size = Vector2(400, 56); help.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	help.add_theme_constant_override("outline_size", 8)
	ui_root.add_child(help); help_lbl = help
	banner_bg = TextureRect.new(); banner_bg.texture = uitex("trail.png"); banner_bg.position = Vector2(0, 130); banner_bg.size = Vector2(1600, 150)
	banner_bg.stretch_mode = TextureRect.STRETCH_SCALE; banner_bg.modulate = Color(0.15, 0.02, 0.0, 0.0); banner_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; banner_bg.flip_h = false
	ui_root.add_child(banner_bg)
	banner = Label.new(); banner.position = Vector2(0, 120); banner.size = Vector2(1600, 170)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_font_override("font", font_bold); banner.add_theme_font_size_override("font_size", 60)
	banner.add_theme_color_override("font_color", Color(1, 0.86, 0.5)); banner.add_theme_color_override("font_outline_color", Color(0.25, 0.04, 0)); banner.add_theme_constant_override("outline_size", 16)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE; banner.visible = false; ui_root.add_child(banner)
	flash = ColorRect.new(); flash.set_anchors_preset(Control.PRESET_FULL_RECT); flash.color = Color(1, 0.9, 0.7, 0); flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(flash)
	equip_panel = panel(Vector2(200, 110), Vector2(1200, 600)); equip_panel.visible = false; equip_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	equip_vbox = VBoxContainer.new(); equip_vbox.add_theme_constant_override("separation", 10); equip_vbox.set_meta("max_k", 1.25); equip_panel.add_child(equip_vbox)
	build_dialog()

# 角色卡：頭像 + 名字 + 動畫 HP/MP 條 + 能力值
var order_panel: Control
func _pass_mouse(n: Node) -> void:
	if n is Control and not (n is BaseButton) and not (n is ScrollContainer): (n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for ch in n.get_children(): _pass_mouse(ch)

func make_card(pos: Vector2, size: Vector2, ps: int) -> Dictionary:
	var p := panel(pos, size)
	var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 12); p.add_child(hb)
	var frame := PanelContainer.new(); frame.add_theme_stylebox_override("panel", sbt("parchment.png", 12, -6)); hb.add_child(frame)
	frame.custom_minimum_size = Vector2(ps, ps); frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pt := TextureRect.new(); pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; pt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pt.custom_minimum_size = Vector2(ps - 12, ps - 12); frame.add_child(pt)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 2); v.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hb.add_child(v)
	var nm := lbl("", 26 if ps > 150 else 22, Color(1, 0.86, 0.5), true); v.add_child(nm)
	var jb := lbl("", 16, Color(0.85, 0.8, 0.7)); v.add_child(jb)
	var hp := make_bar(v, "bar_hp.png", "HP")
	var mp := make_bar(v, "bar_mp.png", "MP")
	var sl := lbl("", 16 if ps > 150 else 15, Color(0.92, 0.88, 0.8)); sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(sl)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; jb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var tw_min := size.x - ps - 44.0
	for wl in [nm, jb, sl]: wl.custom_minimum_size.x = tw_min
	# v21 可讀性：字放大後卡片往上長，貼齊畫面底部／右側，不跑出畫面
	var bottom := pos.y + size.y; var right_al := pos.x > 800.0; var right := pos.x + size.x
	p.resized.connect(func():
		p.position.y = minf(pos.y, bottom - p.size.y)
		if right_al: p.position.x = minf(pos.x, right - p.size.x))
	return {"panel": p, "portrait": pt, "name": nm, "job": jb, "hp": hp, "mp": mp, "stats": sl, "unit": null}

func make_bar(parent: Control, fill: String, tag: String) -> Dictionary:
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 6); parent.add_child(row)
	var tl := lbl(tag, 15, Color(1, 0.84, 0.45), true); tl.custom_minimum_size = Vector2(30, 0); row.add_child(tl)
	var holder := Control.new(); holder.custom_minimum_size = Vector2(0, 18); holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(holder)
	var bars := []
	for t in ["bar_bg.png", "bar_ghost.png", fill]:
		var b := TextureProgressBar.new(); b.nine_patch_stretch = true; b.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.stretch_margin_left = 2; b.stretch_margin_right = 2; b.stretch_margin_top = 2; b.stretch_margin_bottom = 2
		if t == "bar_bg.png": b.texture_under = uitex(t)
		else: b.texture_progress = uitex(t)
		b.max_value = 1000; b.value = 1000; b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(b); bars.append(b)
	var vl := lbl("", 15); vl.custom_minimum_size = Vector2(84, 0); vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; row.add_child(vl)
	return {"ghost": bars[1], "fill": bars[2], "val": vl}

func set_bar(b: Dictionary, v: int, mx: int, animate: bool) -> void:
	var tv := 1000.0 * float(v) / float(max(mx, 1))
	b.val.text = "%d/%d" % [v, mx]
	if animate:
		var tw := create_tween(); tw.tween_property(b.fill, "value", tv, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var tg := create_tween(); tg.tween_interval(0.45); tg.tween_property(b.ghost, "value", tv, 0.6)
	else:
		b.fill.value = tv; b.ghost.value = tv

func fill_card(c: Dictionary, u, extra := "") -> void:
	_fill_card0(c, u, extra); _pass_mouse(c.panel)

func _fill_card0(c: Dictionary, u, extra := "") -> void:
	if u == null: return
	var same: bool = c.unit == u
	c.unit = u
	c.portrait.texture = u.portrait
	c.portrait.modulate = Color(1, 1, 1) if u.alive else Color(0.45, 0.4, 0.4)
	c.name.text = u.name
	c.name.add_theme_color_override("font_color", Color(0.12, 0.22, 0.5) if u.team == 0 else Color(0.58, 0.1, 0.08))
	c.job.text = "%s・%s%s" % [u.job, u.title, "" if u.alive else "（戰鬥不能）"]
	set_bar(c.hp, u.hp, st(u, "hp"), same)
	set_bar(c.mp, u.mp, st(u, "mp"), same)
	var w = G.W[u.weapon]
	var s := "Lv%d　攻%d 防%d 魔%d 速%d 移%d 跳%d\n%s（射程%d-%d）・%s" % [u.lv, st(u, "atk"), st(u, "def"), st(u, "mag"), st(u, "spd"), st(u, "move"), st(u, "jump"), u.weapon, w.rmin, w.rmax, u.armor]
	if u.status.has("poison"): s += "　〔中毒〕"
	if u.status.has("stun"): s += "　〔暈眩〕"
	if extra != "": s = extra
	c.stats.text = s
	fill_rage_card(c, u)

# 頭像：每名角色以獨立 SubViewport 渲染實際 3D 模型
func log_msg(s: String) -> void:
	print("[LOG] ", s)
	log_lines.append(s)
	while log_lines.size() > (4 if G.font_k() < 1.3 else 3): log_lines.pop_front()
	if log_label != null: log_label.text = "\n".join(log_lines)

func predict(n: int) -> Array:
	var ct := {}
	for i in units.size():
		if units[i].alive: ct[i] = units[i].ct
	if ct.is_empty(): return []
	var out := []
	var guard := 0
	while out.size() < n and guard < 5000:
		guard += 1
		var best := -1
		for i in ct:
			if ct[i] >= 100 and (best < 0 or ct[i] > ct[best]): best = i
		if best >= 0:
			out.append(units[best]); ct[best] -= 100
		else:
			for i in ct: ct[i] += st(units[i], "spd")
	return out

func update_order() -> void:
	_update_order0()
	if order_panel != null: _pass_mouse(order_panel)

func _update_order0() -> void:
	for ch in order_box.get_children(): ch.queue_free()
	var lst := []
	if cur != null: lst.append(cur)
	lst.append_array(predict(6))
	for i in lst.size():
		var u = lst[i]
		var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 8)
		var fr := PanelContainer.new(); fr.add_theme_stylebox_override("panel", sbt("parchment.png" if i == 0 else "panel.png", 8, -4)); fr.custom_minimum_size = Vector2(46, 46)
		var tr := TextureRect.new(); tr.texture = u.portrait; tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.custom_minimum_size = Vector2(40, 40)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; fr.add_child(tr); row.add_child(fr)
		var nl := lbl(("▶ " if i == 0 else "") + u.name, 19 if i == 0 else 17, Color(0.7, 0.85, 1.0) if u.team == 0 else Color(1, 0.62, 0.52), i == 0)
		nl.size_flags_vertical = Control.SIZE_SHRINK_CENTER; nl.clip_text = true; nl.custom_minimum_size = Vector2(170, 0)
		row.add_child(nl)
		order_box.add_child(row)

func show_menu() -> void:
	for ch in menu_box.get_children(): ch.queue_free()
	menu_panel.visible = true
	var items := [["移動", "cmd_move", moved], ["攻擊", "cmd_attack", acted]]
	if moved and not acted and not undo_data.is_empty() and undo_data.u == cur: items.insert(1, ["移動復原", "cmd_undo", false])
	var sil := silenced(cur)
	if can_talk(cur) != null: items.insert(1, ["說服・%s" % ev.npc, "cmd_talk", acted])
	if cur.job == "召喚師":
		items.append(["召喚・伊弗利特 MP%d" % summon_cost(cur), "cmd_summon", acted or sil or cur.mp < summon_cost(cur)])
		if cur.team == 0 and G.has_lev():
			items.append(["召喚・利維坦 MP%d" % lev_cost(cur), "cmd_summon_lev", acted or sil or cur.mp < lev_cost(cur)])
		if cur.team == 0 and G.has_adam():
			items.append(["召喚・亞達曼 MP%d" % adam_cost(cur), "cmd_summon_adam", acted or sil or cur.mp < adam_cost(cur)])
	if caster(cur) or ucls(cur) != "":
		items.append([("魔法" if caster(cur) else "技能") + ("（沉默）" if sil else ""), "cmd_magic", acted or sil or spells_of(cur).is_empty()])
	if cur.job == "僧侶":
		items.append(["治癒術 MP%d" % HEAL_COST, "cmd_heal", acted or sil or cur.mp < HEAL_COST])
	if has_rage(cur) and int(cur.get("rage", 0)) >= RAGE_MAX:
		items.append(["★必殺・%s" % SPECIALS[cur.key].n, "cmd_special", acted or sil])
	var icnt := 0
	for k in G.items: icnt += int(G.items[k])
	items.append(["道具（%d）" % icnt, "cmd_item", acted or icnt <= 0])
	items.append(["裝備變更", "cmd_equip", acted])
	items.append(["待機", "cmd_wait", false])
	for it in items:
		var b := Button.new(); b.text = it[0]; b.disabled = it[2]; b.custom_minimum_size = Vector2(226, 46)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if it[1] == "cmd_special":
			b.add_theme_color_override("font_color", Color(1, 0.62, 0.2)); b.add_theme_color_override("font_hover_color", Color(1, 0.85, 0.4))
		var ic := cmd_icon(it[1])
		if ic != "" and ResourceLoader.exists(ic): b.icon = load(ic); b.expand_icon = false; b.add_theme_constant_override("icon_max_width", 30)
		b.pressed.connect(func(): sfx("click", 0.05, -10.0))
		b.pressed.connect(Callable(self, it[1]))
		hand_hook(b)
		menu_box.add_child(b)
	menu_panel.reset_size()
	# v17：選單滑入
	var mx := 1330.0
	if touch_mode and touch_bar != null: menu_panel.reset_size(); mx = minf(mx, touch_bar.get_global_rect().position.x - menu_panel.size.x - 12.0)
	menu_panel.position.x = mx + 40; menu_panel.modulate.a = 0.0
	var mt := menu_panel.create_tween().set_parallel(); mt.tween_property(menu_panel, "position:x", mx, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT); mt.tween_property(menu_panel, "modulate:a", 1.0, 0.15)
	fill_card(card, cur)

# ---- v17：FFT 風格手指游標與指令圖示 ----
var hand: TextureRect
func cmd_icon(cmd: String) -> String:
	return {"cmd_move": "res://assets/icons/a19.png", "cmd_attack": "res://assets/icons/w0.png", "cmd_summon": "res://assets/v15/fx/el_fire.png",
		"cmd_summon_lev": "res://assets/v15/fx/el_water.png", "cmd_magic": "res://assets/icons/w40.png", "cmd_heal": "res://assets/icons/i2.png",
		"cmd_item": "res://assets/icons/i0.png", "cmd_equip": "res://assets/icons/a9.png", "cmd_wait": ""}.get(cmd, "")
func hand_hook(b: Control) -> void:
	var f := func():
		if hand == null:
			hand = TextureRect.new(); hand.texture = load("res://assets/v15/cursor.png"); hand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			hand.size = Vector2(42, 32); hand.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui_root.add_child(hand)
			var ht := hand.create_tween().set_loops(); ht.tween_property(hand, "pivot_offset:x", 0.0, 0.01)
			ht.tween_method(func(x): if is_instance_valid(hand) and hand.has_meta("bx"): hand.position.x = hand.get_meta("bx") + sin(x) * 5.0, 0.0, TAU, 0.6)
		if not b.is_inside_tree() or (b is Button and b.disabled): return
		hand.visible = true; hand.move_to_front()
		hand.set_meta("bx", b.global_position.x - 40.0); hand.position = Vector2(b.global_position.x - 40.0, b.global_position.y + b.size.y * 0.5 - 16.0)
		if not autotest: sfx("click", 0.1, -22.0)
		var bt := b.create_tween(); b.pivot_offset = b.size * 0.5; bt.tween_property(b, "scale", Vector2(1.04, 1.04), 0.08); bt.tween_property(b, "scale", Vector2.ONE, 0.12)
	b.mouse_entered.connect(f); b.focus_entered.connect(f)

func hide_menu() -> void:
	menu_panel.visible = false
	if hand != null: hand.visible = false

# ---------------- 裝備選單 ----------------
func allowed_weapons(u) -> Array:
	if u.member == null: return [u.weapon]
	return G.owned_list(u.member, "weapon")

func allowed_armors(u) -> Array:
	if u.member == null: return [u.armor]
	return G.owned_list(u.member, "armor")

func equip(u, kind: String, item: String) -> void:
	var ohp = u.hp; var omp = u.mp
	if u.member != null:
		G.swap_equip(u.member, kind, item)
		u[kind] = u.member[kind]
	else:
		u[kind] = item
	legend_aura(u)
	u.hp = min(ohp, st(u, "hp")); u.mp = min(omp, st(u, "mp"))
	refresh_look(u); update_label(u)
	log_msg("%s 裝備了 %s" % [u.name, item])
	call_deferred("open_equip", equip_list, equip_prep)

var equip_prep := false
var equip_list: Array = []
func open_equip(list: Array, prep: bool) -> void:
	equip_prep = prep; equip_list = list
	hide_menu()
	state = "equip"
	for ch in equip_vbox.get_children(): ch.queue_free()
	var t := lbl("出陣準備 — 編成與裝備" if prep else "裝備變更（不消耗行動）", 28, Color(1, 0.84, 0.45), true)
	equip_vbox.add_child(t)
	equip_vbox.add_child(lbl("持有：武器／防具 %d 件　道具 %d 個　金幣 %d G" % [inv_count(), item_count(), G.gold], 16, Color(0.85, 0.8, 0.7)))
	var ps := 86 if list.size() <= 5 else 50
	for u in list:
		var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 14)
		var fr := PanelContainer.new(); fr.add_theme_stylebox_override("panel", sbt("parchment.png", 10, -5)); fr.custom_minimum_size = Vector2(ps + 10, ps + 10)
		var tr := TextureRect.new(); tr.texture = u.portrait; tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.custom_minimum_size = Vector2(ps, ps); fr.add_child(tr)
		row.add_child(fr)
		var nv := VBoxContainer.new(); nv.custom_minimum_size = Vector2(170, 0)
		nv.add_child(lbl("%s Lv%d" % [u.name, u.lv], 22 if ps > 60 else 18, Color(0.7, 0.85, 1.0), true)); nv.add_child(lbl("%s・%s" % [u.job, u.title], 15, Color(0.85, 0.8, 0.7)))
		nv.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(nv)
		var ow := OptionButton.new(); ow.custom_minimum_size = Vector2(320, 46); ow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var ws := allowed_weapons(u)
		for i in ws.size():
			var w = G.W[ws[i]]
			ow.add_item("%s 攻+%d（%d-%d）%s" % [ws[i], int(w.get("atk", 0)), w.rmin, w.rmax, gear_tag(w)], i)
			if ws[i] == u.weapon: ow.select(i)
		var oa := OptionButton.new(); oa.custom_minimum_size = Vector2(250, 46); oa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var ar := allowed_armors(u)
		for i in ar.size():
			var ad: Dictionary = G.A[ar[i]]
			oa.add_item("%s 防+%d%s" % [ar[i], int(ad.get("def", 0)), gear_tag(ad)], i)
			if ar[i] == u.armor: oa.select(i)
		var sl := lbl(stat_short(u), 16)
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ow.item_selected.connect(func(i): equip(u, "weapon", ws[i]); sl.text = stat_short(u); sfx("click"))
		oa.item_selected.connect(func(i): equip(u, "armor", ar[i]); sl.text = stat_short(u); sfx("click"))
		row.add_child(ow); row.add_child(oa); row.add_child(sl)
		equip_vbox.add_child(row)
	var b := Button.new(); b.text = "出陣！" if prep else "關閉"; b.custom_minimum_size = Vector2(240, 52)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(close_equip)
	equip_vbox.add_child(b)
	equip_panel.visible = true
	equip_panel.reset_size()
	await get_tree().process_frame
	equip_panel.reset_size()
	equip_panel.position = Vector2((1600 - equip_panel.size.x) / 2.0, max(10.0, (900 - equip_panel.size.y) / 2.0 - 20))

func stat_short(u) -> String:
	return "HP %d　MP %d　攻 %d　防 %d　魔 %d\n速 %d　移 %d　跳 %d" % [st(u, "hp"), st(u, "mp"), st(u, "atk"), st(u, "def"), st(u, "mag"), st(u, "spd"), st(u, "move"), st(u, "jump")]

func inv_count() -> int:
	var n := 0
	for k in G.inv: n += int(G.inv[k])
	return n

func item_count() -> int:
	var n := 0
	for k in G.items: n += int(G.items[k])
	return n

func gear_tag(d: Dictionary) -> String:
	var t := []
	for k in ["hp", "mp", "atk", "mag", "spd", "move", "jump"]:
		if int(d.get(k, 0)) != 0 and not (k == "atk" and d.has("rmin")): t.append("%s%+d" % [{"hp":"HP","mp":"MP","atk":"攻","mag":"魔","spd":"速","move":"移","jump":"跳"}[k], int(d[k])])
	for k in ["drain", "poison", "crit", "pierce", "regen", "mpregen", "summon", "hit", "eva", "thorns", "heal", "nostun", "nopoison", "stun"]:
		if int(d.get(k, 0)) != 0: t.append({"drain":"吸血","poison":"毒","crit":"會心","pierce":"穿透","regen":"再生","mpregen":"MP回復","summon":"召喚強化","hit":"命中","eva":"迴避","thorns":"反傷","heal":"治癒強化","nostun":"抗暈","nopoison":"抗毒","stun":"暈眩"}[k])
	return (" " + "/".join(t)) if t.size() > 0 else ""

func close_equip() -> void:
	equip_panel.visible = false
	sfx("click")
	if equip_prep:
		equip_prep = false
		log_msg("戰鬥開始！擊敗所有帝國軍。")
		next_turn()
	else:
		state = "menu"; show_menu()

# ---------------- 鏡頭與輸入 ----------------
func update_cam() -> void:
	cam_pivot.rotation_degrees.y = yaw
	var pr := deg_to_rad(pitch)
	cam.position = Vector3(0, sin(pr) * cam_dist, cos(pr) * cam_dist)
	if shake > 0: cam.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * shake * 0.25
	cam.look_at(cam_pivot.global_position)

func _process(d: float) -> void:
	var rd := d / maxf(Engine.time_scale, 0.01)
	t_elapsed += rd
	_hold_check()
	if touch_mode and touch_bar != null and menu_panel.visible:
		var lim := touch_bar.get_global_rect().position.x - menu_panel.size.x - 12.0
		if menu_panel.position.x > lim: menu_panel.position.x = lim
	if autotest and t_elapsed > 900.0:
		print("AUTOTEST FAIL: timeout"); get_tree().quit(2)
	yaw = lerp(yaw, target_yaw, min(1.0, rd * 5.0))
	cam_dist = lerp(cam_dist, target_dist, min(1.0, rd * 5.0))
	pitch = lerp(pitch, target_pitch, min(1.0, rd * 5.0))
	shake = max(0.0, shake - rd * 2.0)
	var mv := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): mv.z -= 1
	if Input.is_key_pressed(KEY_S): mv.z += 1
	if Input.is_key_pressed(KEY_A): mv.x -= 1
	if Input.is_key_pressed(KEY_D): mv.x += 1
	if mv != Vector3.ZERO and state != "anim":
		cam_pivot.position += mv.rotated(Vector3.UP, deg_to_rad(yaw)).normalized() * rd * 8.0
		cam_pivot.position.x = clamp(cam_pivot.position.x, -cam_lim(), cam_lim()); cam_pivot.position.z = clamp(cam_pivot.position.z, -cam_lim(), cam_lim())
	update_cam()
	var cb := cam.global_transform.basis
	for uu in units: tick_sprite(uu, d, -cb.z, cb.x)
	for i in clouds.size():
		var c: Node3D = clouds[i]
		var cr := Vector2(c.position.x, c.position.z)
		cr = cr.rotated(rd * 0.012 * (1.0 + 0.3 * (i % 3)))
		c.position.x = cr.x; c.position.z = cr.y
	for b in birds:
		var bn: Node3D = b.n
		var a: float = t_elapsed * b.sp + b.ph
		bn.position = Vector3(cos(a) * b.r, b.y + sin(a * 2.3) * 0.4, sin(a) * b.r * 0.7)
		b.m.set_shader_parameter("frame", int(t_elapsed * 6.0 + b.ph * 3.0) % 2)
	if sun != null:
		sun.light_energy = sun_base + sin(t_elapsed * 0.31) * 0.1 * sun_base / maxf(0.1, TH.sun_e) + sin(t_elapsed * 1.7) * 0.03
		sprite_lighting(rd)
	rage_tick(rd)
	for t in torches: t.light_energy = TH.torch + sin(t_elapsed * 13.0 + t.position.x) * 0.15 + randf() * 0.2
	if cur != null and cur.alive and state != "over":
		cursor_ring.visible = true
		cursor_ring.position = cur.node.position + Vector3(0, 0.05, 0)
		cursor_ring.rotation.y += rd * 1.5
		var s := 1.0 + sin(t_elapsed * 4.0) * 0.05
		cursor_ring.scale = Vector3(s, 0.3, s)

func _unhandled_input(e: InputEvent) -> void:
	if state == "equip": return
	if e is InputEventScreenTouch or e is InputEventScreenDrag:
		touch_input(e); return
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_Q: target_yaw -= 90
			KEY_E: target_yaw += 90
			KEY_R: target_pitch = 62.0 if target_pitch < 50 else 40.0
			KEY_ESCAPE: cancel()
	elif e is InputEventMouseButton and e.pressed:
		match e.button_index:
			MOUSE_BUTTON_WHEEL_UP: target_dist = max(10.0, target_dist - 1.0 * maxf(1.0, map_k()))
			MOUSE_BUTTON_WHEEL_DOWN: target_dist = min(zmax(), target_dist + 1.0 * maxf(1.0, map_k()))
			MOUSE_BUTTON_RIGHT: cancel()
			MOUSE_BUTTON_LEFT:
				if touch_mode:
					if not (touch_seen and e.device == InputEvent.DEVICE_ID_EMULATION): t_press = e.position   # 觸控：放開時才判定點擊（拖曳不誤觸）
					return
				var c := pick(e.position)
				if c.x >= 0: on_cell_clicked(c)
	elif e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT and touch_mode:
		if touch_seen and e.device == InputEvent.DEVICE_ID_EMULATION: return   # v24：有真實觸控事件時，點擊由 touch_tap 處理
		if t_press.x > -9000 and e.position.distance_to(t_press) < slop() and not t_dragged and not lp_done:
			var c := fuzzy_pick(t_press)   # v22：以按下位置判定（手指離開時的滑移不改變目標）
			if c.x >= 0:
				on_hover(c); on_cell_clicked(c)
		t_press = Vector2(-9999, -9999); t_dragged = false; lp_done = false
	elif e is InputEventMouseMotion and touch_mode:
		pass
	elif e is InputEventMouseMotion:
		var c := pick(e.position)
		if c.x >= 0 and c != hover_cell: on_hover(c)

# ---------------- v18m：觸控（Android／網頁） ----------------
var touch_mode := false
var t_press := Vector2(-9999, -9999)
var t_dragged := false
var touches := {}
var pinch_d := 0.0
var touch_bar: Control
var help_lbl: Label

func touch_input(e: InputEvent) -> void:
	if not touch_mode: set_touch_mode(true)
	if e is InputEventScreenTouch:
		touch_seen = true
		if e.pressed:
			# v24：iOS Safari 的觸控 id 是很大的數字且可能前後不一致（網頁端已在 index.js 重新編號；此處再做保險）
			if touches.is_empty():
				t_dragged = false; t_press = e.position; t_multi = false; lp_done = false; t_hold = Time.get_ticks_msec()
			touches[e.index] = e.position; touch_ts[e.index] = Time.get_ticks_msec()
		else:
			var single := touches.size() <= 1 and not t_multi
			if touches.has(e.index): touches.erase(e.index)
			elif touches.size() == 1: touches.clear()   # v24：放開的 id 對不上時視為唯一那根手指
			touch_ts.erase(e.index)
			if touches.is_empty(): touch_ts.clear()
			# v24：點擊直接由觸控放開判定（不依賴瀏覽器的滑鼠模擬）
			if single and touches.is_empty(): touch_tap(e.position)
		if touches.size() == 2:
			# v22：雙指＝縮放／旋轉，鎖定直到全部手指離開（避免放開一指時鏡頭跳動）
			var p: Array = touches.values(); pinch_d = (p[0] as Vector2).distance_to(p[1]); t_dragged = true; t_multi = true
			twist_a = ((p[1] as Vector2) - (p[0] as Vector2)).angle(); twist_acc = 0.0
		if touches.is_empty(): pinch_d = 0.0; t_hold = 0
	elif e is InputEventScreenDrag:
		if not touches.has(e.index) and touches.size() == 1 and not t_multi: touches.clear()   # v24：id 不一致時沿用同一根手指
		touches[e.index] = e.position; touch_ts[e.index] = Time.get_ticks_msec()
		if touches.size() >= 2:
			var p: Array = touches.values(); var dd := (p[0] as Vector2).distance_to(p[1])
			if pinch_d > 0.0: target_dist = clamp(target_dist * pinch_d / maxf(dd, 1.0), 10.0, zmax())
			pinch_d = dd; t_dragged = true
			var ang := ((p[1] as Vector2) - (p[0] as Vector2)).angle()
			twist_acc += wrapf(ang - twist_a, -PI, PI); twist_a = ang
			if absf(twist_acc) > 0.5:
				target_yaw += 90.0 if twist_acc > 0 else -90.0; twist_acc = 0.0; buzz(15)
		elif t_multi: return
		elif state != "anim" and not cam_lock:
			if t_press.x > -9000 and e.position.distance_to(t_press) < slop() and not t_dragged: return
			t_dragged = true
			var k := cam_dist / 900.0 * 1.6
			var mv := Vector3(-e.relative.x, 0, -e.relative.y) * k
			cam_pivot.position += mv.rotated(Vector3.UP, deg_to_rad(yaw))
			cam_pivot.position.x = clamp(cam_pivot.position.x, -cam_lim(), cam_lim()); cam_pivot.position.z = clamp(cam_pivot.position.z, -cam_lim(), cam_lim())

# ---- v22：手感改善工具 ----
var t_multi := false
var touch_seen := false
var touch_ts := {}

func gui_blocks(pos: Vector2, n: Node = null) -> bool:
	if n == null: n = get_tree().root
	for ch in n.get_children():
		if ch is Node3D: continue
		if ch is CanvasItem and not ch.visible: continue
		if ch is Control and ch.mouse_filter == Control.MOUSE_FILTER_STOP and ch.get_global_rect().has_point(pos): return true
		if gui_blocks(pos, ch): return true
	return false

func touch_tap(pos: Vector2) -> void:
	if gui_blocks(t_press):
		t_press = Vector2(-9999, -9999); t_dragged = false; lp_done = false; return
	if t_press.x > -9000 and pos.distance_to(t_press) < slop() and not t_dragged and not lp_done:
		var c := fuzzy_pick(t_press)
		if c.x >= 0:
			on_hover(c); on_cell_clicked(c)
	t_press = Vector2(-9999, -9999); t_dragged = false; lp_done = false
var t_hold := 0
var lp_done := false
var twist_a := 0.0
var twist_acc := 0.0
var pend_cell := Vector2i(-1, -1)
var path_nodes := []
var touch_hint_shown := false
var lp_ms := 500
var confirm_btn: Button
var speed_btn: Button
var undo_data := {}
const CONFIRM_STATES := ["move", "attack", "magic", "summon", "heal", "item", "special"]

func slop() -> float:
	# 約 3.5 公釐的實體距離換算成遊戲座標（不同 DPI 手機手感一致），至少 24
	var dpi := float(DisplayServer.screen_get_dpi())
	if dpi <= 0: dpi = 160.0
	var px := dpi / 25.4 * 3.5
	var ws := Vector2(DisplayServer.window_get_size()); var vs := get_viewport().get_visible_rect().size
	var sc := minf(ws.x / maxf(vs.x, 1.0), ws.y / maxf(vs.y, 1.0))
	return clampf(px / maxf(sc, 0.01), 24.0, 60.0)

func buzz(ms: int) -> void:
	if touch_mode and OS.has_feature("mobile"): Input.vibrate_handheld(ms)

func valid_target(c: Vector2i) -> bool:
	if c.x < 0 or not hl_cells.has(c): return false
	if state == "attack":
		var t = unit_at(c); return t != null and t.team != cur.team
	return true

func fuzzy_pick(p: Vector2) -> Vector2i:
	# 放大點擊判定：手指偏一點也能選到最近的有效格（優先有單位的格）
	var c := pick(p)
	if not (state in CONFIRM_STATES) or valid_target(c): return c
	var best := Vector2i(-1, -1)
	for r in [22.0, 40.0]:
		for i in 8:
			var q := pick(p + Vector2.RIGHT.rotated(i * PI / 4.0) * r)
			if valid_target(q):
				if unit_at(q) != null: return q
				if best.x < 0: best = q
		if best.x >= 0: return best
	return c

func clear_pending() -> void:
	pend_cell = Vector2i(-1, -1)
	for n in path_nodes: if is_instance_valid(n): n.queue_free()
	path_nodes.clear()
	if confirm_btn != null: confirm_btn.disabled = true

func set_pending(c: Vector2i) -> void:
	clear_pending(); pend_cell = c
	on_hover(c)
	if state == "move" and reach.has("parent"):
		var x := c
		while x != cur.cell and reach.parent.has(x):
			path_nodes.append(hl_quad(x, Color(1.0, 0.85, 0.25, 0.75) if x == c else Color(1.0, 0.95, 0.6, 0.55))); x = reach.parent[x]
	if confirm_btn != null: confirm_btn.disabled = false
	sfx("click", 0.05, -14.0); buzz(12)
	if not touch_hint_shown: touch_hint_shown = true; log_msg("再點一次同一格或按「確定」執行")

func confirm_pending() -> void:
	if pend_cell.x < 0: return
	var c := pend_cell
	await on_cell_clicked(c, true)

func _hold_check() -> void:
	if not touch_mode or lp_done or t_hold == 0 or t_dragged or touches.size() != 1: return
	if Time.get_ticks_msec() - t_hold < lp_ms: return
	var c := pick(t_press); var u = unit_at(c)
	if u == null: return   # v24：長按空地不算長按（避免低幀率時點擊被吃掉）
	lp_done = true
	tcard.panel.visible = true; fill_card(tcard, u, "（長按查看）"); buzz(30); sfx("click", 0.05, -12.0)

func toggle_speed() -> void:
	base_ts = 2.0 if base_ts < 1.5 else 1.0
	Engine.time_scale = base_ts
	if speed_btn != null: speed_btn.text = "倍速×%d" % int(base_ts)
	var cf := ConfigFile.new(); cf.load("user://touch.cfg"); cf.set_value("touch", "speed", base_ts); cf.save("user://touch.cfg")

func cmd_undo() -> void:
	if undo_data.is_empty() or undo_data.u != cur or acted: return
	cur.cell = undo_data.cell; cur.node.position = undo_data.pos; cur.node.rotation = undo_data.rot
	moved = false; undo_data = {}
	sfx("click", 0.05, -10.0); buzz(15); log_msg("已復原移動")
	show_menu()

func set_touch_mode(on: bool) -> void:
	touch_mode = on
	if touch_bar != null: touch_bar.visible = on
	if help_lbl != null:
		help_lbl.text = "點一下 預覽　再點一次／確定鈕 執行　長按 看資料\n單指拖曳 平移　雙指 縮放・扭轉旋轉" if on else "左鍵 選擇／確定　右鍵・Esc 取消\nQ/E 旋轉　滾輪 縮放　WASD 平移　R 俯角"
		help_lbl.add_theme_font_size_override("font_size", 18 if on else 17)
		if on: help_lbl.position.x = 1110; help_lbl.size.x = 470; help_lbl.add_theme_font_size_override("font_size", 15); help_lbl.set_meta("max_k", 1.0)

func build_touch_ui() -> void:
	var cl := CanvasLayer.new(); cl.layer = 6; add_child(cl)
	# v22：右側拇指區直排大按鈕；確定鈕在最上方醒目、取消緊鄰；避開右上天候與右下資訊卡
	touch_bar = VBoxContainer.new(); touch_bar.add_theme_constant_override("separation", 8); touch_bar.set_meta("no_fix", true)
	touch_bar.anchor_left = 1.0; touch_bar.anchor_right = 1.0; touch_bar.anchor_top = 0.0; touch_bar.anchor_bottom = 0.0
	touch_bar.offset_left = -114; touch_bar.offset_right = -10; touch_bar.offset_top = 132; touch_bar.offset_bottom = 600
	if ui_root != null and ui_root.theme != null: touch_bar.theme = ui_root.theme
	cl.add_child(touch_bar)
	var defs := [["確定", func(): confirm_pending()], ["取消", func(): clear_pending(); cancel()], ["左轉", func(): target_yaw -= 90], ["右轉", func(): target_yaw += 90],
		["俯仰", func(): target_pitch = 62.0 if target_pitch < 50 else 40.0], ["倍速×1", func(): toggle_speed()]]
	for d in defs:
		var b := Button.new(); b.text = d[0]; b.custom_minimum_size = Vector2(104, 70)
		b.add_theme_font_size_override("font_size", 24); b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func(): buzz(10))
		b.pressed.connect(d[1]); touch_bar.add_child(b)
		if d[0] == "確定":
			confirm_btn = b; b.disabled = true
			b.add_theme_color_override("font_color", Color(1, 0.86, 0.35)); b.add_theme_font_size_override("font_size", 28)
		elif d[0].begins_with("倍速"): speed_btn = b
	var cf := ConfigFile.new()
	if not autotest and cf.load("user://touch.cfg") == OK and float(cf.get_value("touch", "speed", 1.0)) > 1.5: toggle_speed()
	set_touch_mode(("--touch" in OS.get_cmdline_user_args()) or (DisplayServer.is_touchscreen_available() and (OS.has_feature("mobile") or OS.has_feature("web"))))

func pick(p: Vector2) -> Vector2i:
	var from := cam.project_ray_origin(p)
	var q := PhysicsRayQueryParameters3D.create(from, from + cam.project_ray_normal(p) * 300.0)
	var r := get_world_3d().direct_space_state.intersect_ray(q)
	if r.is_empty(): return Vector2i(-1, -1)
	var col = r.collider
	if col.has_meta("cell"): return col.get_meta("cell")
	if col.has_meta("unit_idx"): return units[col.get_meta("unit_idx")].cell
	return Vector2i(-1, -1)

func on_hover(c: Vector2i) -> void:
	hover_cell = c
	var u = unit_at(c)
	if state == "item" and hl_cells.has(c):
		clear_aoe()
		var rr := item_rad(sel_item)
		for a in heights:
			if mdist(a, c) <= rr: aoe_nodes.append(hl_quad(a, Color(0.5, 1.0, 0.9, 0.5)))
		tcard.panel.visible = true
		fill_card(tcard, u if u != null else cur, "▶ %s：%s" % [sel_item, G.I[sel_item].desc])
		return
	if state == "magic" and hl_cells.has(c):
		magic_hover(c, u); return
	if state == "special" and hl_cells.has(c):
		special_hover(c); return
	if state == "summon" and hl_cells.has(c):
		clear_aoe()
		var n := 0
		var na := 0
		var lv := summon_kind == "leviathan"
		for a in aoe_cells(c):
			aoe_nodes.append(hl_quad(a, Color(0.35, 0.8, 1.0, 0.55) if lv else Color(1, 0.85, 0.2, 0.55)))
			var t = unit_at(a)
			if t != null and t.team != cur.team: n += 1
			elif t != null: na += 1
		tcard.panel.visible = true
		if lv: fill_card(tcard, u if u != null else cur, "▶ 利維坦・大海嘯\n敵人 %d 名（水傷＋緩速）　我方 %d 名（回復＋淨化）" % [n, na])
		else: fill_card(tcard, u if u != null else cur, "▶ 伊弗利特・地獄之焰\n命中 100%%　範圍內敵人 %d 名" % n)
		return
	if u == null or u == cur:
		tcard.panel.visible = false
		return
	tcard.panel.visible = true
	if state == "attack" and hl_cells.has(c) and u.team != cur.team:
		var p := calc(cur, u, cur.cell)
		fill_card(tcard, u, "▶ 命中 %d%%　預估傷害 %d\n　 爆擊率 %d%%（高低差 %+d）" % [p.hit, p.dmg, p.crit, heights[cur.cell] - heights[u.cell]])
	else:
		fill_card(tcard, u)

func cancel() -> void:
	if state in ["move", "attack", "summon", "heal", "item", "itemmenu", "magic", "magicmenu", "special"]:
		clear_hl(); tcard.panel.visible = false; state = "menu"; show_menu()

# ---------------- 格子計算 ----------------
func mdist(a: Vector2i, b: Vector2i) -> int: return abs(a.x - b.x) + abs(a.y - b.y)

func reachable(u) -> Dictionary:
	var start: Vector2i = u.cell
	var dist := {start: 0}; var parent := {start: start}; var q := [start]
	var mv := 0 if u.status.has("root") else st(u, "move"); var jp := st(u, "jump")
	while q.size() > 0:
		var c: Vector2i = q.pop_front()
		if dist[c] >= mv: continue
		for dd in DIRS:
			var n: Vector2i = c + dd
			if not inside(n) or dist.has(n) or n in ROCK_CELLS or n in LAVA_CELLS: continue
			if abs(heights[n] - heights[c]) > jp: continue
			var o = unit_at(n)
			if o != null and o.team != u.team: continue
			dist[n] = dist[c] + 1; parent[n] = c; q.append(n)
	var ends := []
	for c in dist:
		var o = unit_at(c)
		if (o == null or o == u) and (not u.get("big", false) or big_fits(u, c)): ends.append(c)
	return {"parent": parent, "ends": ends}

func ranged(u) -> bool:
	return G.W[u.weapon].type in ["弩", "杖"]

func in_range(u, from: Vector2i, to: Vector2i) -> bool:
	var w = G.W[u.weapon]
	var d := mdist(from, to)
	var dh: int = heights[from] - heights[to]
	var rmax: int = w.rmax
	if w.type == "弩" and dh >= 2: rmax += 1
	if rmax > 1: rmax = maxi(maxi(w.rmin, 1), rmax + int(wx().rng))
	if d < w.rmin or d > rmax: return false
	if not ranged(u) and abs(dh) > 2: return false
	return true

func attack_cells(u, from: Vector2i) -> Array:
	var out := []
	for c in heights:
		if in_range(u, from, c): out.append(c)
	return out

func aoe_cells(c: Vector2i) -> Array:
	var out := []
	for k in heights:
		if mdist(k, c) <= (LEV_AOE if summon_kind == "leviathan" else (2 if summon_kind == "adam" else SUMMON_AOE)): out.append(k)
	return out

func calc(a, d, from: Vector2i) -> Dictionary:
	var dh: int = heights[from] - heights[d.cell]
	var wxh: int = int(wx().hit) + (int(wx().rhit) if ranged(a) else 0)
	var hit := clampi(80 + (st(a, "spd") - st(d, "spd")) * 2 + dh * 4 + eff(a, "hit") - eff(d, "eva") + wxh, 20, 99)
	var dfm: float = 1.0 - clampf(eff(a, "pierce") / 100.0, 0.0, 0.8)
	var dmg: int
	if G.W[a.weapon].type == "杖":
		dmg = maxi(1, int((st(a, "mag") * 1.2 - st(d, "def") * 0.3 * dfm) * (1.0 + 0.05 * dh)))
	else:
		dmg = maxi(1, int((st(a, "atk") - st(d, "def") * 0.6 * dfm) * (1.0 + 0.08 * dh)))
	dmg = maxi(1, int(dmg * wx_el(uel(a))))
	var crit := clampi(8 + (st(a, "spd") - st(d, "spd")) + maxi(0, dh) * 3 + eff(a, "crit"), 3, 45)
	return {"hit": hit, "dmg": dmg, "crit": crit}

func summon_dmg(a, d) -> int:
	return maxi(1, int((st(a, "mag") * 1.6 + 10 - st(d, "def") * 0.4) * (1.0 + eff(a, "summon") / 100.0)))

const HEAL_COST := 10

func turn_upkeep(u) -> bool:
	await wx_turn()
	if u.team == 0: turns_p += 1
	else: turns_e += 1
	var rg := eff(u, "regen")
	if rg > 0 and u.hp < st(u, "hp"):
		u.hp = mini(st(u, "hp"), u.hp + rg); popup(u.node.position, "+%d" % rg, Color(0.5, 1, 0.5))
	var mr := eff(u, "mpregen")
	if mr > 0 and u.mp < st(u, "mp"):
		u.mp = mini(st(u, "mp"), u.mp + mr); popup(u.node.position + Vector3(0, 0.35, 0), "MP+%d" % mr, Color(0.5, 0.75, 1))
	if u.status.has("poison"):
		var pd := maxi(3, int(st(u, "hp") * 0.08))
		u.hp = maxi(0, u.hp - pd); popup(u.node.position, "毒 %d" % pd, Color(0.6, 1, 0.4)); hit_flash(u, Color(0.4, 1, 0.3))
		u.status.poison -= 1
		if u.status.poison <= 0: u.status.erase("poison")
		log_msg("%s 受到毒傷 %d" % [u.name, pd])
		if u.hp <= 0:
			kill(u); update_label(u); await wait(0.8)
			if await check_end(): return true
			cur.ct -= 100; next_turn(); return true
	if status_upkeep(u) and u.hp <= 0:
		kill(u); update_label(u); await wait(0.8)
		if await check_end(): return true
		cur.ct -= 100; next_turn(); return true
	if u.buff_t > 0:
		u.buff_t -= 1
		if u.buff_t <= 0 and u.get("buff_temp", false): u.buff = {}; u.buff_temp = false
	update_label(u)
	if u.status.has("stun") or u.status.has("freeze"):
		var fz: bool = u.status.has("freeze")
		u.status.erase("stun"); u.status.erase("freeze"); update_label(u)
		popup(u.node.position, "冰封中" if fz else "暈眩中", Color(0.6, 0.9, 1) if fz else Color(1, 1, 0.4)); log_msg("%s %s，無法行動" % [u.name, "被冰封" if fz else "暈眩"])
		await wait(0.7)
		moved = false; acted = false; end_turn(); return true
	return false

func heal_amt(u) -> int:
	return int(st(u, "mag") * 1.5) + 18 + eff(u, "heal")

func cmd_heal() -> void:
	var cells := []
	for t in alive_team(cur.team):
		if mdist(t.cell, cur.cell) <= 3: cells.append(t.cell)
	show_hl(cells, Color(0.3, 1.0, 0.5, 0.45)); state = "heal"; hide_menu()
	log_msg("選擇治癒對象（綠色格）")

func do_heal(u, t) -> void:
	u.mp -= HEAL_COST
	face(u, t.node.position); play(u, "Spellcasting", 0.1); sfx("heal", 0.05, -4.0)
	var mc := magic_circle(t.node.position + Vector3(0, 0.05, 0), 0.8, Color(0.4, 1.0, 0.6))
	var rp := make_rise(t.node.position, Color(0.4, 1.0, 0.5), 0.5, 50)
	await wait(0.6)
	var amt := mini(heal_amt(u), st(t, "hp") - t.hp)
	t.hp += amt; track_heal(u, amt)
	popup(t.node.position, "+%d" % amt, Color(0.4, 1.0, 0.5), true)
	log_msg("%s 為 %s 治癒 %d HP" % [u.name, t.name, amt])
	update_label(t); fill_card(card, u)
	await wait(0.7)
	mc.queue_free(); rp.emitting = false; get_tree().create_timer(1.5).timeout.connect(rp.queue_free)
	play(u, idle_anim(u), 0.2)
	if u.team == 0: grant_exp(u, 12)

func cmd_item() -> void:
	hide_menu()
	for ch in menu_box.get_children(): ch.queue_free()
	menu_panel.visible = true
	var keys: Array = G.items.keys(); keys.sort()
	for k in keys:
		var d: Dictionary = G.I[k]
		var b := Button.new(); b.text = "%s ×%d" % [k, G.items[k]]; b.tooltip_text = d.desc
		b.icon = load(d.icon); b.expand_icon = true; b.custom_minimum_size = Vector2(300, 42)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func(): sfx("click", 0.05, -10.0); pick_item(k))
		menu_box.add_child(b)
	var bb := Button.new(); bb.text = "返回"; bb.custom_minimum_size = Vector2(300, 42)
	bb.pressed.connect(func(): show_menu())
	menu_box.add_child(bb)
	menu_panel.reset_size()
	state = "itemmenu"

func item_rad(k: String) -> int:
	return 2 if G.I[k].eff == "holy" else 0

func item_target_ok(k: String, c: Vector2i) -> bool:
	var d: Dictionary = G.I[k]
	if mdist(c, cur.cell) > int(d.range): return false
	var t = unit_at(c)
	match d.target:
		"ally": return t != null and t.team == cur.team and (d.eff != "revive_all" or not downed_allies(cur.team).is_empty())
		"enemy": return t != null and t.team != cur.team
		"dead": return dead_at(c) != null and t == null
		"area": return true
	return false

func dead_at(c: Vector2i):
	for u in units:
		if not u.alive and u.team == cur.team and u.cell == c and int(u.get("down_t", 0)) > 0 and not u.get("gone", false): return u
	return null

func pick_item(k: String) -> void:
	sel_item = k
	var cells := []
	for c in heights:
		if item_target_ok(k, c): cells.append(c)
	hide_menu()
	# v25：對隊友（含自己）使用時以綠色標示可選目標
	var ally: bool = G.I[k].target in ["ally", "dead"]
	show_hl(cells, Color(0.3, 1.0, 0.4, 0.6) if ally else Color(0.4, 0.9, 1.0, 0.45)); state = "item"
	if ally:
		for c in cells:
			var lb := Label3D.new(); lb.text = "▼ 使用"; lb.font_size = 56; lb.outline_size = 14
			lb.modulate = Color(0.35, 1.0, 0.45); lb.outline_modulate = Color(0, 0.2, 0.05)
			lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED; lb.no_depth_test = true; lb.render_priority = 10
			lb.position = cell_pos(c) + Vector3(0, 2.3, 0); add_child(lb); hl_nodes.append(lb)
			var tw := lb.create_tween().set_loops(); tw.tween_property(lb, "position:y", lb.position.y + 0.25, 0.4); tw.tween_property(lb, "position:y", lb.position.y, 0.4)
	log_msg(("使用 %s：%s（點選綠色格子：自己或相鄰隊友）" if ally else "使用 %s：%s（選擇目標）") % [k, G.I[k].desc])

func do_item(u, k: String, c: Vector2i) -> void:
	var d: Dictionary = G.I[k]
	G.use_item(k)
	var t = unit_at(c)
	if d.eff == "revive": t = dead_at(c)
	if t != null: face(u, t.node.position)
	play(u, "Attack" if d.target == "enemy" else "Spellcasting", 0.1)
	log_msg("%s 使用了 %s" % [u.name, k])
	var pos: Vector3 = cell_pos(c)
	var col := Color(0.4, 0.9, 1.0)
	if d.target == "enemy":
		col = Color(1, 0.5, 0.2) if d.eff == "bomb" else Color(1, 1, 0.4)
		var n := Node3D.new(); add_child(n); n.position = u.node.position + Vector3(0, 1, 0)
		mi(n, sph(0.12, 8), Vector3.ZERO, glow(col, 1.0, 5.0))
		var tw := create_tween(); tw.tween_property(n, "position", pos + Vector3(0, 0.5, 0), 0.4)
		await tw.finished; n.queue_free()
		sfx("explode", 0.1, -6.0)
		burst(pos + Vector3(0, 0.4, 0), col, 40, 5.0, "spark.png", 0.25, 0.7)
		shake = max(shake, 0.3)
		var dm: int = int(d.val)
		t.hp = maxi(0, t.hp - dm); track_dmg(u, t, dm); hit_flash(t, col); play(t, "Hit_A", 0.05)
		popup(t.node.position, str(dm), col, true)
		if d.eff == "stunbomb" and t.hp > 0 and set_status(t, "stun", 1): popup(t.node.position + Vector3(0, 0.5, 0), "暈眩", Color(1, 1, 0.4))
		update_label(t)
		if t.hp <= 0: kill(t)
	else:
		sfx("heal", 0.05, -4.0)
		var mc := magic_circle(pos + Vector3(0, 0.05, 0), 0.7 + item_rad(k) * 0.8, col)
		var rp := make_rise(pos, col, 0.5 + item_rad(k) * 0.6, 60)
		await wait(0.5)
		var tg: Array = []
		if d.eff == "holy":
			for o in alive_team(u.team):
				if mdist(o.cell, c) <= 2: tg.append(o)
		elif d.eff == "revive_all": tg = downed_allies(u.team)
		elif t != null: tg = [t]
		for o in tg:
			match d.eff:
				"heal", "holy":
					var a := mini(int(d.val), st(o, "hp") - o.hp); o.hp += a; popup(o.node.position, "+%d" % a, Color(0.4, 1, 0.5), true)
				"mp":
					var a := mini(int(d.val), st(o, "mp") - o.mp); o.mp += a; popup(o.node.position, "MP+%d" % a, Color(0.5, 0.7, 1), true)
				"cure":
					o.status.erase("poison"); o.status.erase("burn"); popup(o.node.position, "解毒・滅火", Color(0.6, 1, 0.6)); update_label(o)
				"cureall":
					o.status = {}; var a := mini(int(d.val), st(o, "hp") - o.hp); o.hp += a; popup(o.node.position, "+%d" % a, Color(0.4, 1, 0.5), true)
				"buff_atk", "buff_def", "buff_spd":
					var sk: String = d.eff.substr(5)
					o.buff[sk] = int(o.buff.get(sk, 0)) + int(d.val)
					popup(o.node.position, "%s+%d" % [{"atk":"攻","def":"防","spd":"速"}[sk], int(d.val)], Color(1, 0.8, 0.3), true)
				"revive", "revive_all":
					if unit_at(o.cell) == null: revive_unit(o, int(d.val), k)
				"exp":
					if o.member != null: grant_exp(o, int(d.val))
			update_label(o)
		if do_shots and not item_shot_done:
			item_shot_done = true; await wait(0.2); await shot("09_item_use")
		await wait(0.6)
		mc.queue_free(); rp.emitting = false; get_tree().create_timer(1.5).timeout.connect(rp.queue_free)
	fill_card(card, u)
	await wait(0.4)
	play(u, idle_anim(u), 0.2)

func make_rise_tmp(pos: Vector3, col: Color, radius: float, t: float) -> void:
	var p := make_rise(pos, col, radius, 70)
	get_tree().create_timer(t).timeout.connect(func(): p.emitting = false)
	get_tree().create_timer(t + 1.6).timeout.connect(p.queue_free)

func grant_exp(u, amt: int) -> void:
	if u.team != 0 or u.member == null or not u.alive: return
	var m: Dictionary = u.member
	res.exp[u.name] = int(res.exp.get(u.name, 0)) + amt
	var old := {}
	for k in ["hp", "mp", "atk", "def", "mag", "spd"]: old[k] = st(u, k)
	var ohp := st(u, "hp"); var omp := st(u, "mp"); var olv: int = u.lv
	var ups: Array = G.add_exp(m, amt)
	if ups.is_empty(): return
	u.leveled = true
	u.lv = m.lv
	u.hp += st(u, "hp") - ohp; u.mp += st(u, "mp") - omp
	res.lvups += ups.size()
	var sb := spell_names_lv(u, olv)
	await level_up_fx(u, old, olv)
	update_label(u)
	await learned_popup(u, sb)

func level_up_fx(u, old: Dictionary, olv: int) -> void:
	var p: Vector3 = u.node.position
	var bv := bgm.volume_db; var tb := create_tween(); tb.tween_property(bgm, "volume_db", -32.0, 0.25)
	if not sfx_streams.has("lvup_fanfare"): sfx_streams["lvup_fanfare"] = load("res://assets/sfx/lvup_fanfare.wav")
	sfx("lvup_fanfare", 0.0, -1.0); sfx("levelup", 0.0, -8.0)
	log_msg("%s 升到了 Lv%d！" % [u.name, u.lv])
	# 光柱：白色核心 + 金色外柱 + 上升光環
	var nodes := []
	for spec in [[0.18, 0.24, Color(1, 1, 0.92), 0.9, 6.0], [0.55, 0.75, Color(1, 0.8, 0.3), 0.35, 3.5], [1.0, 1.25, Color(1, 0.7, 0.2), 0.12, 2.0]]:
		var pil := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = spec[0]; cm.bottom_radius = spec[1]; cm.height = 12.0; cm.cap_top = false; cm.cap_bottom = false; cm.radial_segments = 24
		var gm := glow(spec[2], spec[3], spec[4]); gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD; gm.cull_mode = BaseMaterial3D.CULL_DISABLED
		pil.mesh = cm; pil.material_override = gm; pil.position = p + Vector3(0, 6.0, 0); pil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(pil); pil.scale = Vector3(0.05, 0.1, 0.05); nodes.append(pil)
		var tw := create_tween(); tw.tween_property(pil, "scale", Vector3(1, 1, 1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in 3:
		var rg := MeshInstance3D.new(); var tm := TorusMesh.new(); tm.inner_radius = 0.75; tm.outer_radius = 0.9; rg.mesh = tm
		var rm := glow(Color(1, 0.9, 0.45), 0.8, 4.0); rm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD; rg.material_override = rm
		rg.position = p + Vector3(0, 0.1, 0); add_child(rg); nodes.append(rg); rg.scale = Vector3(0.3, 1, 0.3)
		var tr := create_tween().set_parallel(); tr.tween_property(rg, "position:y", p.y + 3.5 + i, 1.6).set_delay(i * 0.22).set_ease(Tween.EASE_OUT); tr.tween_property(rg, "scale", Vector3(1.6, 1, 1.6), 1.6).set_delay(i * 0.22)
	var lt := OmniLight3D.new(); lt.light_color = Color(1, 0.85, 0.45); lt.light_energy = 9; lt.omni_range = 7; lt.position = p + Vector3(0, 1.4, 0); add_child(lt); nodes.append(lt)
	make_rise_tmp(p, Color(1, 0.85, 0.3), 0.6, 1.8)
	burst(p + Vector3(0, 1.0, 0), Color(1, 0.9, 0.4), 80, 5.0, "spark.png", 0.22, 1.0)
	burst(p + Vector3(0, 0.3, 0), Color(1, 1, 0.8), 40, 2.5, "spark.png", 0.15, 1.4)
	hit_flash(u, Color(1, 0.95, 0.5))
	play(u, "Cheer", 0.2)
	# 畫面閃光
	if flash != null:
		flash.color = Color(1, 0.95, 0.7, 0.55); flash.visible = true
		var tf := create_tween(); tf.tween_property(flash, "color:a", 0.0, 0.5)
	# 大字 LEVEL UP!
	var big := Label.new(); big.text = "LEVEL UP!"; big.add_theme_font_override("font", font_bold); big.add_theme_font_size_override("font_size", 128)
	big.add_theme_color_override("font_color", Color(1, 0.86, 0.25)); big.add_theme_color_override("font_outline_color", Color(0.35, 0.1, 0.0)); big.add_theme_constant_override("outline_size", 22)
	big.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6)); big.add_theme_constant_override("shadow_offset_x", 6); big.add_theme_constant_override("shadow_offset_y", 8)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; big.size = Vector2(1000, 170); big.position = Vector2(300, 150); big.pivot_offset = Vector2(500, 85); big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(big); big.scale = Vector2(2.4, 2.4); big.modulate.a = 0.0
	var tbig := create_tween().set_parallel(); tbig.tween_property(big, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT); tbig.tween_property(big, "modulate:a", 1.0, 0.2)
	var sub := lbl("%s　Lv %d → Lv %d" % [u.name, olv, u.lv], 40, Color(1, 0.97, 0.85), true, true)
	sub.add_theme_constant_override("outline_size", 10); sub.add_theme_color_override("font_outline_color", Color(0.25, 0.1, 0.0))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; sub.size = Vector2(1000, 60); sub.position = Vector2(300, 318); ui_root.add_child(sub)
	# 屬性提升面板
	var pn := panel(Vector2(1180, 330), Vector2(360, 330))
	var pv := VBoxContainer.new(); pv.add_theme_constant_override("separation", 4); pn.add_child(pv)
	pv.set_meta("max_k", 1.3)
	var hd := lbl("能力提升", 28, Color(0.55, 0.25, 0.04), true); hd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; pv.add_child(hd)
	var names := {"hp":"HP","mp":"MP","atk":"攻擊","def":"防禦","mag":"魔力","spd":"速度"}
	for k in ["hp", "mp", "atk", "def", "mag", "spd"]:
		var nv := st(u, k); var dv: int = nv - int(old[k])
		var row := HBoxContainer.new(); pv.add_child(row)
		var a1 := lbl(names[k], 24, Color(0.3, 0.18, 0.08), true); a1.custom_minimum_size = Vector2(80, 0); row.add_child(a1)
		var a2 := lbl("%d → %d" % [int(old[k]), nv], 24, Color(0.25, 0.15, 0.08)); a2.custom_minimum_size = Vector2(150, 0); row.add_child(a2)
		var a3 := lbl(("+%d" % dv) if dv > 0 else "—", 26, Color(0.1, 0.5, 0.12) if dv > 0 else Color(0.45, 0.4, 0.35), true); row.add_child(a3)
	pn.modulate.a = 0.0; pn.position.x = 1600
	var tp := create_tween().set_parallel(); tp.tween_property(pn, "position:x", 1180.0, 0.35).set_delay(0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT); tp.tween_property(pn, "modulate:a", 1.0, 0.3).set_delay(0.25)
	if do_shots and not levelup_shot_done:
		levelup_shot_done = true
		var op := cam_pivot.position; var od := target_dist
		cam_pivot.position = p + Vector3(0, 1.6, 0); target_dist = 13.0; cam_dist = 13.0
		await wait(0.75); await shot("10_levelup")
		cam_pivot.position = op; target_dist = od
	await wait(2.0)
	var t3 := create_tween().set_parallel()
	for n in [big, sub, pn]: t3.tween_property(n, "modulate:a", 0.0, 0.4)
	for n in nodes:
		if n is MeshInstance3D: t3.tween_property(n, "scale", Vector3(0.01, 1, 0.01), 0.4)
	t3.tween_property(bgm, "volume_db", bv, 0.8)
	await t3.finished
	big.queue_free(); sub.queue_free(); pn.queue_free()
	for n in nodes: n.queue_free()
	play(u, idle_anim(u), 0.2)


func summon_cost(u) -> int:
	return maxi(12, SUMMON_COST - eff(u, "summon") / 5)

func skill_banner(txt: String, col: Color) -> void:
	banner.text = txt; banner.add_theme_color_override("font_color", col)
	banner.visible = true; banner_bg.visible = true
	banner.modulate.a = 0.0; banner_bg.modulate.a = 0.0
	var tw := create_tween().set_parallel(); tw.tween_property(banner, "modulate:a", 1.0, 0.25); tw.tween_property(banner_bg, "modulate:a", 1.0, 0.25)

func skill_banner_end() -> void:
	var tw := create_tween().set_parallel(); tw.tween_property(banner, "modulate:a", 0.0, 0.3); tw.tween_property(banner_bg, "modulate:a", 0.0, 0.3)
	await tw.finished
	banner.visible = false; banner_bg.visible = false

func skill_hit(a, t, mult: float, pierce: int, col: Color) -> int:
	var p := calc(a, t, a.cell)
	var dm := int(p.dmg * mult * 0.8 * randf_range(0.92, 1.08))
	if pierce > 0: dm = int(dm * (1.0 + 0.004 * pierce * st(t, "def") / 10.0))
	dm = maxi(1, dm)
	t.hp = maxi(0, t.hp - dm); track_dmg(a, t, dm)
	hit_flash(t, col); play(t, "Hit_B", 0.05)
	magic_impact(t.node.position + Vector3(0, 0.6, 0), col)
	if do_shots and not fx_shots.has("magic"):
		fx_shots["magic"] = true
		await get_tree().create_timer(0.1, true, false, true).timeout
		await shot("03e_magic_fx")
	popup(t.node.position, str(dm), col, true)
	update_label(t)
	if t.hp <= 0: kill(t)
	return dm

# 頭目技能：回傳 true 表示已行動
func boss_skill(u) -> bool:
	var sk: Dictionary = SKILLS.get(u.get("skill", ""), {})
	if sk.is_empty(): return false
	var fs: Array = foes(u)
	if fs.is_empty(): return false
	var col: Color = sk.col
	var target = null; var center: Vector2i = u.cell
	match sk.kind:
		"strike":
			var r := reachable(u); var best = null
			for c in r.ends:
				for t in fs:
					if mdist(c, t.cell) == 1 and abs(heights[c] - heights[t.cell]) <= 2:
						if best == null or t.hp < best.t.hp: best = {"c": c, "t": t}
			if best == null: return false
			if best.c != u.cell: await move_unit(u, best.c, r.parent); moved = true
			target = best.t
		"aoe":
			var bn := 0
			for c in heights:
				if mdist(c, u.cell) > int(sk.range): continue
				var n := 0
				for t in fs:
					if mdist(t.cell, c) <= int(sk.rad): n += 1
				if n > bn: bn = n; center = c
			if bn == 0: return false
		"quake":
			var n := 0
			for t in fs:
				if mdist(t.cell, u.cell) <= int(sk.rad): n += 1
			if n == 0:
				var r := reachable(u)
				var bc = null; var bnn := 0
				for c in r.ends:
					var k := 0
					for t in fs:
						if mdist(t.cell, c) <= int(sk.rad): k += 1
					if k > bnn: bnn = k; bc = c
				if bc == null: return false
				await move_unit(u, bc, r.parent); moved = true
			center = u.cell
		"roar", "sanct":
			pass
	var skname: String = u.skill
	skill_banner("%s・%s" % [u.name, skname], col)
	sfx("magic", 0.0, -2.0)
	play(u, "Spellcasting", 0.1)
	var mc := magic_circle(u.node.position + Vector3(0, 0.06, 0), 1.4, col)
	make_rise_tmp(u.node.position, col, 0.9, 1.0)
	var lt := OmniLight3D.new(); lt.light_color = col; lt.light_energy = 3; lt.omni_range = 6; lt.position = u.node.position + Vector3(0, 1.5, 0); add_child(lt)
	await wait(0.9)
	log_msg("%s 發動了「%s」！" % [u.name, skname])
	match sk.kind:
		"strike":
			face(u, target.node.position)
			for h in int(sk.get("hits", 1)):
				if not target.alive: break
				play(u, "1H_Melee_Attack_Chop", 0.05, 1.2); await wait(0.3)
				sfx("crit", 0.05, -3.0); shake = 0.6
				burst(target.node.position + Vector3(0, 0.7, 0), col, 50, 6.0, "spark.png", 0.22, 0.7)
				var dm := await skill_hit(u, target, float(sk.mult), int(sk.get("pierce", 0)), col)
				if int(sk.get("drain", 0)) > 0:
					var hv := dm * int(sk.drain) / 100; u.hp = mini(st(u, "hp"), u.hp + hv); popup(u.node.position, "+%d" % hv, Color(0.6, 0.3, 1.0)); update_label(u)
				if int(sk.get("poison", 0)) > 0 and target.alive and set_status(target, "poison", 3): update_label(target)
				await wait(0.35)
		"aoe":
			var cp := cell_pos(center)
			var mc2 := magic_circle(cp + Vector3(0, 0.06, 0), 1.0 + float(sk.rad), col)
			for i in 5:
				meteor(cp + Vector3(randf_range(-3, 3), 10, randf_range(-3, 3)), cp + Vector3(randf_range(-0.8, 0.8), 0.2, randf_range(-0.8, 0.8)), i * 0.12)
			await wait(1.0)
			for t in fs:
				if t.alive and mdist(t.cell, center) <= int(sk.rad): await skill_hit(u, t, float(sk.mult), 0, col)
			await wait(0.4); mc2.queue_free()
		"quake":
			sfx("explode", 0.0, -2.0); shake = 1.0
			burst(u.node.position + Vector3(0, 0.2, 0), Color(0.6, 0.5, 0.4, 0.8), 60, 6.0, "smoke.png", 0.6, 1.0, 0.0, 90.0, Vector3.UP)
			for t in fs:
				if t.alive and mdist(t.cell, u.cell) <= int(sk.rad):
					await skill_hit(u, t, float(sk.mult), 0, col)
					if t.alive and randi() % 100 < int(sk.stun) and set_status(t, "stun", 1): update_label(t); popup(t.node.position + Vector3(0, 0.5, 0), "暈眩", Color(1, 1, 0.4))
			await wait(0.5)
		"roar":
			sfx("crit", 0.0, -2.0); shake = 0.5
			for o in alive_team(u.team):
				if mdist(o.cell, u.cell) <= 4:
					o.buff["atk"] = int(o.buff.get("atk", 0)) + 6; o.buff_t = 3; o.buff_temp = true
					popup(o.node.position, "攻+6", Color(1, 0.4, 0.2), true); make_rise_tmp(o.node.position, col, 0.4, 0.6)
		"sanct":
			sfx("heal", 0.0, -2.0)
			for o in alive_team(u.team):
				if mdist(o.cell, u.cell) <= 4:
					var a := mini(st(o, "hp") - o.hp, int(st(o, "hp") * 0.3)); o.hp += a
					popup(o.node.position, "+%d" % a, Color(0.5, 1, 0.5), true); update_label(o); make_rise_tmp(o.node.position, col, 0.4, 0.6)
	if do_shots and not boss_shot_done:
		boss_shot_done = true; await wait(0.1); await shot("11_boss_skill")
	await wait(0.6)
	mc.queue_free(); lt.queue_free()
	await skill_banner_end()
	play(u, idle_anim(u), 0.2)
	acted = true
	return true

func spawn_phase2(u) -> void:
	var p2: Dictionary = u.bdef.phase2
	var bm := G.boss_member(p2, bidx)
	await wait(1.6)
	skill_banner("%s 現出真身——%s！" % [u.name, bm.name], Color(1, 0.8, 0.3))
	sfx("summon", 0.0, 0.0); shake = 1.2
	var c: Vector2i = u.cell
	if not big_fits(u, c):
		var best := 999
		for k in heights:
			if big_fits(u, k) and mdist(k, u.cell) < best: best = mdist(k, u.cell); c = k
	var nu = add_unit(bm.name, bm.job, 1, bm.base, bm.weapon, bm.armor, c, bm.key, {}, bm.scale, bm.title, {"lv": int(bm.lv), "boss": true, "skill": bm.skill, "bdef": p2, "phase": 2})
	nu.ct = 60
	var tc := cell_pos(c)
	nu.node.scale = Vector3.ONE * 0.05
	make_rise_tmp(tc, Color(1, 0.7, 0.3), 1.2, 1.4)
	burst(tc + Vector3(0, 1, 0), Color(1, 0.8, 0.4), 80, 7.0, "spark.png", 0.25, 1.0)
	var tw := create_tween(); tw.tween_property(nu.node, "scale", Vector3.ONE, 0.9).set_trans(Tween.TRANS_BACK)
	await play_story([[bm.name, p2.get("line", "愚蠢的反抗者……法典之力，將你們碾為塵土！")]])
	await skill_banner_end()
	if do_shots: await shot("12_boss_phase2")

func after_damage(d) -> void:
	# 頭目血量低於一半時進入第二階段（強化）
	if d.alive and d.boss and d.phase == 0 and d.hp * 2 < st(d, "hp"):
		d.phase = 1
		d.buff["atk"] = int(d.buff.get("atk", 0)) + 5; d.buff["def"] = int(d.buff.get("def", 0)) + 3
		popup(d.node.position + Vector3(0, 0.6, 0), "憤怒！", Color(1, 0.3, 0.2), true)
		log_msg("%s 陷入狂怒，攻防上升！" % d.name)
		make_rise_tmp(d.node.position, Color(1, 0.25, 0.15), 0.6, 1.2)

# ---------------- 高亮 ----------------
func hl_quad(c: Vector2i, col: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(0.92, 0.92); m.mesh = pm
	var mat := StandardMaterial3D.new(); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.albedo_color = col
	mat.emission_enabled = true; mat.emission = Color(col.r, col.g, col.b); mat.emission_energy_multiplier = 0.6
	m.material_override = mat; m.position = cell_pos(c) + Vector3(0, 0.035, 0)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	var tw := m.create_tween().set_loops(); tw.tween_property(mat, "albedo_color:a", col.a * 0.55, 0.6); tw.tween_property(mat, "albedo_color:a", col.a, 0.6)
	return m

func show_hl(cells: Array, col: Color) -> void:
	clear_hl()
	for c in cells:
		hl_nodes.append(hl_quad(c, col)); hl_cells[c] = true

func clear_aoe() -> void:
	for n in aoe_nodes: n.queue_free()
	aoe_nodes.clear()

func clear_hl() -> void:
	for n in hl_nodes: n.queue_free()
	hl_nodes.clear(); hl_cells.clear(); clear_aoe(); clear_pending()

# ---------------- 回合流程 ----------------
func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout

func next_turn() -> void:
	if await check_end(): return
	var guard := 0
	while guard < 5000:
		guard += 1
		var best = null
		for u in units:
			if u.alive and u.ct >= 100 and (best == null or u.ct > best.ct or (u.ct == best.ct and st(u, "spd") > st(best, "spd"))): best = u
		if best != null:
			start_turn(best); return
		for u in units:
			if u.alive: u.ct += st(u, "spd")

var cam_lock := false
var focus_tw: Tween
func focus(p: Vector3) -> void:
	if cam_lock: return
	var tw := create_tween(); focus_tw = tw; tw.tween_property(cam_pivot, "position", Vector3(p.x * 0.6, 0, p.z * 0.6), 0.5).set_trans(Tween.TRANS_SINE)

var bgm_started := false
func start_turn(u) -> void:
	cur = u; moved = false; acted = false; undo_data = {}
	act_set(u)
	if not bgm_started:
		bgm_started = true; bgm_play(battle_track(), 1.2)
	focus(u.node.position)
	update_order(); fill_card(card, u); tcard.panel.visible = false
	turn_label.text = ("我方回合 — %s" if u.team == 0 else "帝國軍回合 — %s") % u.name
	log_msg("── %s 的回合 ──" % u.name)
	u.turns += 1
	if u.team == 0: p_turns += 1
	if u.team == 0 and p_turns > round_no * maxi(1, party_n):
		round_no += 1
		for o in units.duplicate():
			if o.team == 0 and not o.alive and int(o.get("down_t", 0)) > 0 and not o.get("gone", false) and round_no > int(o.get("down_r", 0)): down_tick(o)
		await new_round()
		if state == "over": return
	if await turn_upkeep(u): return
	if u.team == 1:
		state = "anim"; hide_menu()
		await enemy_ai(u)
	elif autotest and not touch_test:
		state = "anim"; hide_menu()
		await auto_player(u)
	else:
		state = "menu"; show_menu()

func end_turn() -> void:
	clear_hl(); hide_menu()
	cur.ct -= 100 if (moved and acted) else 80
	state = "anim"
	await wait(0.35)
	next_turn()

func cmd_move() -> void:
	reach = reachable(cur)
	show_hl(reach.ends, Color(0.25, 0.55, 1.0, 0.45)); state = "move"; hide_menu()
	log_msg("選擇移動目的地（藍色格）")

func cmd_attack() -> void:
	show_hl(attack_cells(cur, cur.cell), Color(1.0, 0.25, 0.2, 0.45)); state = "attack"; hide_menu()
	log_msg("選擇攻擊目標（紅色格）")

func cmd_summon() -> void:
	summon_kind = "ifrit"
	var cells := []
	for c in heights:
		if mdist(c, cur.cell) <= SUMMON_RANGE: cells.append(c)
	show_hl(cells, Color(1.0, 0.55, 0.1, 0.32)); state = "summon"; hide_menu()
	log_msg("選擇召喚目標地點（橘色範圍，黃色為爆炸範圍）")

func cmd_summon_lev() -> void:
	summon_kind = "leviathan"
	var cells := []
	for c in heights:
		if mdist(c, cur.cell) <= LEV_RANGE: cells.append(c)
	show_hl(cells, Color(0.2, 0.6, 1.0, 0.32)); state = "summon"; hide_menu()
	log_msg("選擇大海嘯中心（藍色範圍）：敵人受水傷＋緩速，我方回復 30% HP 並淨化")

func cmd_equip() -> void:
	open_equip([cur], false)

func cmd_wait() -> void:
	end_turn()

func on_cell_clicked(c: Vector2i, confirmed := false) -> void:
	# v22：觸控兩段式確認——第一下預覽（路徑／傷害），第二下或「確定」才執行
	if touch_mode and not confirmed and state in CONFIRM_STATES and valid_target(c) and c != pend_cell:
		set_pending(c); return
	clear_pending()
	if touch_mode and state in CONFIRM_STATES and valid_target(c): buzz(25)
	match state:
		"move":
			if hl_cells.has(c):
				undo_data = {"u": cur, "cell": cur.cell, "pos": cur.node.position, "rot": cur.node.rotation}
				clear_hl(); state = "anim"
				await move_unit(cur, c, reach.parent)
				moved = true
				await ev_after_move(cur); await flag_check(cur)
				if state == "over" or ev_state.get("busy", false): return
				await after_action()
		"attack":
			var t = unit_at(c)
			if hl_cells.has(c) and t != null and t.team != cur.team:
				clear_hl(); state = "anim"
				await do_attack(cur, t)
				acted = true; await after_action()
		"summon":
			if hl_cells.has(c):
				clear_hl(); state = "anim"
				if summon_kind == "leviathan": await do_leviathan(cur, c)
				elif summon_kind == "adam": await do_adamant(cur, c)
				else: await do_summon(cur, c)
				summon_kind = "ifrit"
				acted = true; await after_action()
		"magic":
			if magic_valid(cur, sel_spell, c):
				clear_hl(); clear_aoe(); tcard.panel.visible = false; state = "anim"
				await do_magic(cur, sel_spell, c)
				acted = true; await after_action()
		"special":
			if special_valid(cur, c):
				clear_hl(); clear_aoe(); tcard.panel.visible = false; state = "anim"
				await do_special(cur, c)
				acted = true; await after_action()
		"heal":
			var t = unit_at(c)
			if hl_cells.has(c) and t != null:
				clear_hl(); state = "anim"
				await do_heal(cur, t)
				acted = true; await after_action()
		"item":
			if hl_cells.has(c):
				clear_hl(); state = "anim"
				await do_item(cur, sel_item, c)
				acted = true; await after_action()

func after_action() -> void:
	if await check_end(): return
	if moved and acted: end_turn()
	else:
		state = "menu"
		if not autotest or touch_test: show_menu()
		else: fill_card(card, cur)

func check_end() -> bool:
	if state == "over": return true
	if pending_phase != null:
		var pu = pending_phase; pending_phase = null
		await spawn_phase2(pu)
	var win := alive_team(1).is_empty()
	var lose := alive_team(0).is_empty()
	if not (win or lose): return false
	state = "over"; clear_hl(); hide_menu(); cursor_ring.visible = false; tcard.panel.visible = false
	if win and ResourceLoader.exists("res://assets/v15/bgm/victory.ogg"): bgm_play("victory", 0.4)
	else: bgm.stop(); sfx("victory" if win else "defeat", 0.0, -3.0)
	for u in alive_team(0 if win else 1):
		play(u, "Cheer", 0.3)
		if win: victory_hop(u)
	if win and do_shots:
		await wait(0.35); await shot("victory_a"); await wait(0.25); await shot("victory_b")
	await wait(1.2)
	var rec = bdef.get("recruit")
	if win:
		res.gold += 100 + bidx * 40
		await ev_on_win()
		G.after_battle(true, res)
		await play_story(bdef.post, false, {1: "07_post_dialog"} if do_shots else {})
	else:
		await play_story(bdef.get("lose", POST_LOSE))
	over_panel = panel(Vector2(430, 150), Vector2(740, 560))
	over_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 10); over_panel.add_child(v)
	var l := lbl("勝　利" if win else "敗　北", 60, Color(1, 0.84, 0.4) if win else Color(1, 0.4, 0.35), true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.add_theme_constant_override("outline_size", 12); v.add_child(l)
	var l2 := lbl("第%d戰「%s」%s" % [bidx + 1, bdef.name, "完成" if win else "失敗……可重新挑戰"], 22, Color(0.95, 0.9, 0.8))
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(l2)
	var lines := []
	if win:
		lines.append("獲得金幣：%d G（持有 %d G）" % [res.gold, G.gold])
		if res.drops.size() > 0: lines.append("戰利品：" + "、".join(res.drops))
		var ex := []
		for k in res.exp: ex.append("%s +%d" % [k, res.exp[k]])
		if ex.size() > 0: lines.append("經驗值：" + "　".join(ex))
		if res.lvups > 0: lines.append("升級次數：%d" % res.lvups)
		if rec != null: lines.append("★ %s 加入了隊伍！" % rec.name)
		if res.get("legend", "") != "": lines.append("◆ 特殊劇情達成：獲得「%s」！" % res.legend)
		elif ev_state.get("failed", false) or (not ev.is_empty() and not ev_state.get("done_before", false)): lines.append("◇ 特殊劇情「%s」未達成（可於營地「重玩章節」再挑戰）" % ev.name)
		if flag_taken: lines.append("◆ 佔領敵軍據點：軍資金加成")
		lines.append("回合數：我方 %d／敵方 %d" % [turns_p, turns_e])
	else:
		lines.append("提示：回營地購買更好的裝備與道具，或重新挑戰。")
	for s0 in lines:
		var ll := lbl(s0, 19, Color(0.85, 0.9, 1.0)); ll.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY; ll.custom_minimum_size = Vector2(680, 0)
		ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(ll)
	var hb := HBoxContainer.new(); hb.alignment = BoxContainer.ALIGNMENT_CENTER; hb.add_theme_constant_override("separation", 20); v.add_child(hb)
	if not win:
		var b := Button.new(); b.text = "重新挑戰"; b.custom_minimum_size = Vector2(220, 52)
		b.pressed.connect(func(): get_tree().reload_current_scene())
		hb.add_child(b)
	var b2 := Button.new(); b2.text = "返回營地"; b2.custom_minimum_size = Vector2(220, 52)
	b2.pressed.connect(func(): Engine.time_scale = 1.0; get_tree().change_scene_to_file("res://camp.tscn"))
	hb.add_child(b2)
	over_panel.modulate.a = 0.0
	if win:
		over_panel.visible = false
		await show_results(rec)
		if do_shots: await wait(0.4); await shot("08_results")
	else:
		var tw := create_tween(); tw.tween_property(over_panel, "modulate:a", 1.0, 0.6)
	turn_label.text = "戰鬥結束"
	log_msg("戰鬥結束：" + ("勝利" if win else "敗北"))
	print("RESULT: ", "WIN" if win else "LOSE", " battle=", bidx + 1)
	var lvs := []
	for m in G.roster: lvs.append("%s:Lv%d" % [m.name, m.lv])
	print("STATS battle=%d turns_p=%d turns_e=%d gold=%d drops=%s lvups=%d dlg=%d party=%s" % [bidx + 1, turns_p, turns_e, res.gold, str(res.drops), res.lvups, dlg_lines, " ".join(lvs)])
	if autotest: finish_autotest(win)
	return true

# ---------------- 動作演出與特效 ----------------
func face(u, to: Vector3) -> void:
	var d: Vector3 = to - u.node.position
	if Vector2(d.x, d.z).length() > 0.01: u.node.rotation.y = atan2(d.x, d.z)

func move_unit(u, target: Vector2i, parent: Dictionary) -> void:
	var path := []
	var c := target
	while c != u.cell:
		path.push_front(c); c = parent[c]
	if path.is_empty(): return
	play(u, "Running_A", 0.15)
	for stp in path:
		var a: Vector3 = u.node.position; var b := cell_pos(stp)
		face(u, b)
		var hop: float = 0.05 + abs(b.y - a.y) * 0.7
		var tw := create_tween()
		tw.tween_method(func(t): u.node.position = a.lerp(b, t) + Vector3(0, sin(t * PI) * hop, 0), 0.0, 1.0, 0.24)
		sfx("step", 0.15, -14.0)
		await tw.finished
	u.cell = target
	play(u, idle_anim(u), 0.2)

func popup(pos: Vector3, txt: String, col: Color, big := false) -> void:
	var pk := G.font_k()
	var l := Label3D.new(); l.font = font_bold; l.text = txt; l.font_size = 96 if big else 68; l.pixel_size = 0.005 * pk; l.outline_size = int(22 * pk)
	l.modulate = col.lightened(0.15); l.outline_modulate = Color(0.0, 0.0, 0.0); l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.no_depth_test = true
	l.render_priority = 5; l.outline_render_priority = 4
	l.position = pos + Vector3(randf_range(-0.15, 0.15), 1.25, 0); l.scale = Vector3.ONE * 0.3; add_child(l)
	var tw := create_tween()
	if big and txt.is_valid_int():
		# v17：大數字先放大再回彈（FFT 式跳字），並加亮色描邊
		l.outline_size = int(28 * pk); l.outline_modulate = Color(0.02, 0.0, 0.0, 1.0)
		tw.tween_property(l, "scale", Vector3.ONE * 1.7, 0.09).set_ease(Tween.EASE_OUT)
		tw.tween_property(l, "scale", Vector3.ONE * 1.2, 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(l, "position:y", l.position.y + 0.25, 0.16)
	else:
		tw.tween_property(l, "scale", Vector3.ONE * (1.25 if big else 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y + 0.7, 0.9).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.5)
	tw.tween_callback(l.queue_free)

func burst(pos: Vector3, col: Color, amount: int, speed: float, tex_name := "spark.png", size := 0.18, life := 0.6, grav := -6.0, spread := 180.0, dir := Vector3.UP) -> GPUParticles3D:
	if amount >= 30: fx_light(pos + Vector3(0, 0.6, 0), col, clampf(amount / 30.0, 1.0, 3.0) * 1.6, maxf(0.45, life))
	var p := GPUParticles3D.new(); p.amount = amount; p.lifetime = life; p.one_shot = true; p.explosiveness = 0.95
	var pm := ParticleProcessMaterial.new()
	pm.direction = dir; pm.spread = spread; pm.initial_velocity_min = speed * 0.4; pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, grav, 0); pm.damping_min = 1.0; pm.damping_max = 3.0
	pm.scale_min = 0.5; pm.scale_max = 1.2
	var sc := Curve.new(); sc.add_point(Vector2(0, 1)); sc.add_point(Vector2(1, 0)); var ct := CurveTexture.new(); ct.curve = sc; pm.scale_curve = ct
	var g := Gradient.new(); g.set_color(0, Color(1, 1, 0.9, 1)); g.add_point(0.25, col); g.set_color(g.get_point_count() - 1, Color(col.r, col.g, col.b, 0))
	var gt := GradientTexture1D.new(); gt.gradient = g; pm.color_ramp = gt
	p.process_material = pm
	var q := quad(size, size); q.material = particle_mat(tex_name, Color.WHITE, tex_name != "smoke.png"); p.draw_pass_1 = q
	p.position = pos; add_child(p); p.emitting = true
	get_tree().create_timer(life + 1.5, true, false, true).timeout.connect(p.queue_free)
	return p

func slash_trail(a, d, col: Color, wide: bool) -> void:
	var m := MeshInstance3D.new(); m.mesh = quad(1.6 if wide else 1.2, 0.8)
	var sm := shmat(SH.TRAIL); sm.set_shader_parameter("tex", uitex("trail.png")); sm.set_shader_parameter("col", col)
	m.material_override = sm
	var mid: Vector3 = a.node.position.lerp(d.node.position, 0.55) + Vector3(0, 0.75, 0)
	add_child(m); m.global_position = mid
	m.look_at(cam.global_position, Vector3.UP)
	m.rotate_object_local(Vector3.FORWARD, randf_range(-0.9, -0.4) if randf() < 0.5 else randf_range(0.4, 0.9))
	var tw := create_tween()
	tw.tween_method(func(v): sm.set_shader_parameter("sweep", v), 0.0, 1.0, 0.12)
	tw.tween_method(func(v): sm.set_shader_parameter("alpha", v), 1.0, 0.0, 0.25)
	tw.tween_callback(m.queue_free)

func projectile(a, d, magic: bool) -> void:
	var from: Vector3 = a.node.position + Vector3(0, 0.62, 0) + (d.node.position - a.node.position).normalized() * 0.3
	var to: Vector3 = d.node.position + Vector3(0, 0.6, 0)
	var n := Node3D.new(); add_child(n); n.position = from
	var trail: GPUParticles3D
	if magic:
		mi(n, sph(0.12, 12), Vector3.ZERO, glow(Color(0.75, 0.4, 1.0), 1.0, 6.0))
		mi(n, sph(0.22, 12), Vector3.ZERO, glow(Color(0.5, 0.2, 1.0), 0.35, 3.0))
		var l := OmniLight3D.new(); l.light_color = Color(0.7, 0.4, 1.0); l.light_energy = 2.0; l.omni_range = 3.0; n.add_child(l)
		trail = fire_particles(Vector3.ZERO, 40, 0.08, 0.5)
		(trail.process_material as ParticleProcessMaterial).gravity = Vector3.ZERO
		var g := Gradient.new(); g.set_color(0, Color(0.9, 0.7, 1, 1)); g.set_color(1, Color(0.4, 0.1, 1, 0)); var gt := GradientTexture1D.new(); gt.gradient = g
		(trail.process_material as ParticleProcessMaterial).color_ramp = gt
		trail.local_coords = false
		remove_child(trail); n.add_child(trail)
	else:
		var shaft := mi(n, cyl(0.012, 0.012, 0.5, 6), Vector3.ZERO, flat(Color(0.35, 0.24, 0.14)), Vector3(PI / 2, 0, 0))
		mi(n, cyl(0.0, 0.035, 0.1, 6), Vector3(0, 0, -0.3), flat(Color(0.75, 0.75, 0.8), 0.9, 0.3), Vector3(-PI / 2, 0, 0))
		mi(n, box(Vector3(0.07, 0.002, 0.09)), Vector3(0, 0, 0.2), flat(Color(0.8, 0.15, 0.1)))
		mi(n, cyl(0.03, 0.03, 0.45, 6), Vector3(0, 0, 0.05), glow(Color(1, 0.9, 0.6), 0.25, 2.0), Vector3(PI / 2, 0, 0))
	var arc := 0.25 if magic else 0.5 + from.distance_to(to) * 0.05
	var dur := 0.45 if magic else 0.32
	var prev := [from]
	var tw := create_tween()
	tw.tween_method(func(t):
		var p := from.lerp(to, t) + Vector3(0, sin(t * PI) * arc, 0)
		if p.distance_to(prev[0]) > 0.001: n.look_at_from_position(p, p + (p - prev[0]), Vector3.UP)
		prev[0] = p, 0.0, 1.0, dur)
	await tw.finished
	if trail != null: trail.emitting = false
	n.visible = false
	get_tree().create_timer(1.0).timeout.connect(n.queue_free)

func do_attack(a, d) -> void:
	face(a, d.node.position); face(d, a.node.position)
	var p := calc(a, d, a.cell)
	var w = G.W[a.weapon]
	var start: Vector3 = a.node.position
	fill_card(tcard, d); tcard.panel.visible = true
	var anim := attack_anim(a)
	play(a, anim, 0.08, 1.15)
	if randi() % 100 < 70: voice(a, "cry", "")
	var is_hit: bool = randi() % 100 < p.hit
	var is_crit: bool = is_hit and randi() % 100 < p.crit
	if do_shots and not attack_shot_done and is_hit and a.team == 0 and w.type != "杖": is_crit = true
	if w.type == "弩":
		await wait(0.3); sfx("bow")
		await projectile(a, d, false)
	elif w.type == "杖":
		await wait(0.35); sfx("magic")
		var mc := magic_circle(a.node.position + Vector3(0, 0.05, 0), 0.9, Color(0.6, 0.3, 1.0))
		await projectile(a, d, true)
		mc.queue_free()
	else:
		var dir: Vector3 = (d.node.position - start) * 0.32
		var tw := create_tween(); tw.tween_property(a.node, "position", start + dir, 0.18).set_delay(0.1)
		await wait(0.33)
		sfx("slash")
		var two: bool = w.get("two", false)
		slash_trail(a, d, Color(1.0, 0.55, 0.25) if is_crit else (Color(1.0, 0.85, 0.6) if a.team == 0 else Color(1, 0.35, 0.25)), two)
		var tb := create_tween(); tb.tween_property(a.node, "position", start, 0.25).set_delay(0.25)
	var hp_pos: Vector3 = d.node.position + Vector3(0, 0.6, 0)
	if is_hit:
		var dmg := int(p.dmg * randf_range(0.9, 1.1))
		if is_crit:
			dmg = int(dmg * 1.5)
			Engine.time_scale = base_ts * 0.25
			sfx("crit", 0.0, -3.0)
			flash.color = Color(1, 0.95, 0.85, 0.22); create_tween().tween_property(flash, "color:a", 0.0, 0.35)
			shake = 0.7
			popup(d.node.position + Vector3(0, 0.75 + 0.3 * G.font_k(), 0), "CRITICAL!", Color(1, 0.85, 0.2), true)
			burst(hp_pos, Color(1, 0.7, 0.2), 60, 7.0, "spark.png", 0.22, 0.7)
			burst(hp_pos, Color(1, 0.95, 0.7), 1, 0.0, "glow.png", 2.2, 0.35, 0.0)
			impact_fx(hp_pos, Color(1, 0.7, 0.25), true)
		else:
			sfx("hit")
			shake = 0.25
			burst(hp_pos, Color(1, 0.6, 0.25) if w.type != "杖" else Color(0.7, 0.4, 1), 26, 4.5)
			burst(hp_pos, Color(1, 0.8, 0.5) if w.type != "杖" else Color(0.7, 0.5, 1), 1, 0.0, "glow.png", 1.1, 0.25, 0.0)
			if w.type == "杖": magic_impact(hp_pos, Color(0.7, 0.45, 1.0))
			else: impact_fx(hp_pos, Color(1, 0.65, 0.3))
			if do_shots and not fx_shots.has("hit"):
				fx_shots["hit"] = true
				await get_tree().create_timer(0.07, true, false, true).timeout
				await shot("03d_hit_fx")
		if d.boss and eff(a, "holy") > 0: dmg = int(dmg * (1.0 + eff(a, "holy") / 100.0))
		d.hp = max(0, d.hp - dmg); track_dmg(a, d, dmg)
		var dr := eff(a, "drain")
		if dr > 0:
			var hv := maxi(1, dmg * dr / 100); a.hp = mini(st(a, "hp"), a.hp + hv); popup(a.node.position, "+%d" % hv, Color(0.5, 1, 0.5)); update_label(a)
		var th := eff(d, "thorns")
		if th > 0 and w.type != "弩" and w.type != "杖" and a.alive:
			var rd := maxi(1, dmg * th / 100); a.hp = maxi(1, a.hp - rd); popup(a.node.position + Vector3(0, 0.3, 0), "反傷 %d" % rd, Color(0.85, 0.85, 1.0)); hit_flash(a, Color(0.8, 0.8, 1)); update_label(a)
		if d.hp > 0 and eff(a, "poison") > 0 and randi() % 100 < eff(a, "poison") and set_status(d, "poison", 3): popup(d.node.position + Vector3(0, 0.5, 0), "中毒", Color(0.5, 1, 0.3))
		if d.hp > 0: voice(d, "hurt", "")
		if d.hp > 0 and a.team == 1 and a.lv >= 10 and randi() % 100 < (12 if a.boss else 8): apply_status(d, {"fire": "burn", "water": "slow", "earth": "root", "wind": "poison"}[uel(a)], 100)
		if d.hp > 0 and eff(a, "stun") > 0 and randi() % 100 < eff(a, "stun") and set_status(d, "stun", 1): popup(d.node.position + Vector3(0, 0.5, 0), "暈眩", Color(1, 1, 0.4))
		hit_flash(d, Color(1, 0.3, 0.2) if not is_crit else Color(1, 0.8, 0.3))
		play(d, "Hit_B" if is_crit else "Hit_A", 0.05)
		var b: Node3D = d.body
		var tw2 := create_tween(); tw2.tween_property(b, "position:x", 0.06, 0.04); tw2.tween_property(b, "position:x", -0.06, 0.04); tw2.tween_property(b, "position:x", 0.0, 0.04)
		popup(d.node.position, str(dmg), Color(1, 0.95, 0.85) if not is_crit else Color(1, 0.55, 0.15), is_crit)
		log_msg("%s 以%s攻擊 %s，%s造成 %d 傷害" % [a.name, a.weapon, d.name, "爆擊！" if is_crit else "", dmg])
		update_label(d); fill_card(tcard, d)
		if card.unit == d: fill_card(card, d)
		if is_crit:
			await get_tree().create_timer(0.12, true, false, true).timeout
			if do_shots and not attack_shot_done:
				attack_shot_done = true
				await shot("03a_attack")
			Engine.time_scale = base_ts
		if d.hp > 0 and eff(a, "double") > 0 and randi() % 100 < eff(a, "double"):
			await wait(0.3)
			var d2 := maxi(1, int(p.dmg * 0.6)); d.hp = maxi(0, d.hp - d2); track_dmg(a, d, d2)
			burst(hp_pos, Color(0.6, 0.85, 1.0), 40, 6.0, "spark.png", 0.2, 0.6); sfx("bow", 0.1, -4.0)
			popup(d.node.position + Vector3(0, 0.4, 0), "流星連射 %d" % d2, Color(0.6, 0.9, 1.0), true); update_label(d)
			log_msg("流星連射！追加 %d 傷害" % d2)
		if d.hp > 0 and eff(a, "holy") > 0 and randi() % 100 < 30: legend_strike(a, d)
		if d.hp <= 0: kill(d)
		else:
			after_damage(d)
			get_tree().create_timer(0.7).timeout.connect(func(): if d.alive: play(d, idle_anim(d), 0.3))
	else:
		play(d, "Block" if d.model in ["Knight", "Barbarian"] else "Dodge_Left", 0.05)
		popup(d.node.position, "MISS", Color(0.75, 0.85, 1.0))
		log_msg("%s 的攻擊被 %s 閃過了（命中率 %d%%）" % [a.name, d.name, p.hit])
		get_tree().create_timer(0.7).timeout.connect(func(): if d.alive: play(d, idle_anim(d), 0.3))
	await wait(0.75)
	play(a, idle_anim(a), 0.25)
	tcard.panel.visible = false
	if a.team == 0 and a.alive:
		var xp := (8 if is_hit else 3) + maxi(0, d.lv - a.lv) * 3
		if not d.alive: xp += 60 if d.boss else 22
		await grant_exp(a, xp)

func kill(u) -> void:
	if evtest and u.alive and ev_active() and (u.get("npc", false) or (u.team == 0 and u.name == str(ev.get("who", "")))):
		u.hp = 1; update_label(u); print("EVTEST guard ", u.name); return
	if evtest and u.alive and u.team == 1 and ev_active() and ev.kind == "seal" and not ev_state.get("triggered", false) and alive_team(1).size() <= 1:
		u.hp = 1; update_label(u); print("EVTEST guard last enemy ", u.name); return
	if u.alive and eff(u, "endure") > 0 and not u.get("endured", false):
		u.endured = true; u.hp = 1; update_label(u)
		popup(u.node.position + Vector3(0, 0.8, 0), "不屈！", Color(1, 0.85, 0.3), true)
		light_pillar(u.node.position, Color(1, 0.8, 0.35), 0.7)
		log_msg("%s 的龍王鎧發出光芒，以 1 HP 撐住了致命一擊！" % u.name)
		return
	u.alive = false
	if u.get("npc_lbl") != null and is_instance_valid(u.npc_lbl): u.npc_lbl.queue_free()
	ev_on_kill(u)
	if u.team == 0: down_start(u)
	if bstat.has(u.get("last_by", "")): bstat[u.last_by].kills += 1
	if u.has("sicons"): u.sicons.visible = false
	var retreat: bool = u.boss and u.get("bdef", {}).get("retreat", false)
	log_msg(("%s 負傷撤退了！" if retreat else "%s 倒下了！") % u.name)
	sfx("death")
	u.label.visible = false; u.hpbar_root.visible = false
	u.status = {}
	if u.team == 1:
		res.gold += 20 + u.lv * 6 + (120 if u.boss else 0)
		if u.boss and u.get("bdef", {}).get("drop", "") != "": res.drops.append(u.bdef.drop)
		elif bdef.get("drops", []).size() > 0 and randf() < 0.3: res.drops.append(bdef.drops[randi() % bdef.drops.size()])
		if u.boss and u.get("bdef", {}).has("phase2"): pending_phase = u
	if retreat:
		var tw0 := create_tween(); tw0.tween_property(u.node, "position:y", u.node.position.y + 0.6, 0.6); tw0.tween_property(u.node, "scale", Vector3(0.01, 0.01, 0.01), 0.5)
		tw0.tween_callback(func(): u.node.visible = false; u.node.scale = Vector3.ONE)
		burst(u.node.position + Vector3(0, 0.6, 0), Color(0.6, 0.6, 0.7, 0.7), 30, 2.5, "smoke.png", 0.7, 1.2, 0.5)
		popup(u.node.position + Vector3(0, 0.5, 0), "撤退", Color(0.8, 0.8, 1.0), true)
		return
	play(u, "Death_A", 0.1)
	var rt := create_tween(); rt.tween_property(u.ring.material_override, "albedo_color:a", 0.0, 0.8)
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_method(func(v): set_flash(u, Color(0.15, 0.1, 0.1, v)), 0.0, 0.6, 0.6)
	tw.tween_property(u.node, "position:y", u.node.position.y - 0.45, 0.8)
	tw.tween_callback(func(): u.node.visible = false)
	burst(u.node.position + Vector3(0, 0.3, 0), Color(0.5, 0.45, 0.4, 0.6), 18, 1.2, "smoke.png", 0.6, 1.4, 0.4)

func magic_circle(pos: Vector3, r: float, col: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(r * 2, r * 2); m.mesh = pm
	var sm := shmat(SH.DECAL); sm.set_shader_parameter("tex", uitex("magic_circle.png")); sm.set_shader_parameter("col", col)
	m.material_override = sm; m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m); m.position = pos; m.scale = Vector3.ONE * 0.05
	var tw := m.create_tween(); tw.tween_property(m, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var rt := m.create_tween().set_loops(); rt.tween_property(m, "rotation:y", TAU, 6.0).as_relative()
	return m

# ---------------- 召喚：伊弗利特 ----------------
class FakeAP:
	var speed_scale := 1.0
	var cb: Callable
	func play(n: String) -> void: cb.call(n)

func make_ifrit() -> Dictionary:
	var root := Node3D.new()
	var sm := ShaderMaterial.new(); sm.shader = spr_shader
	sm.set_shader_parameter("tex", load("res://assets/v12/ifrit.png")); sm.set_shader_parameter("grid", Vector2(6, 1)); sm.set_shader_parameter("frame", 0); sm.set_shader_parameter("row", 0)
	sm.set_shader_parameter("tint", Vector3(1.15, 1.05, 1.0))
	var qm := QuadMesh.new(); qm.size = Vector2(2.4 * 1.12 * 160.0 / 200.0, 2.4 * 1.12); qm.center_offset = Vector3(0, 2.4 * 1.12 * 0.5, 0)
	var spr := Node3D.new(); root.add_child(spr)
	var q := MeshInstance3D.new(); q.mesh = qm; q.material_override = sm; q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; spr.add_child(q)
	var aura := fire_particles(Vector3.ZERO, 60, 0.5, 0.5); remove_child(aura); root.add_child(aura); aura.position = Vector3(0, 1.4, 0)
	var lt := OmniLight3D.new(); lt.light_color = Color(1, 0.45, 0.15); lt.light_energy = 5.0; lt.omni_range = 3.5; lt.position = Vector3(0, 1.4, 0.4); root.add_child(lt)
	var ap := FakeAP.new()
	ap.cb = func(n: String):
		var tw := spr.create_tween()
		var ft := spr.create_tween()
		var F := func(i: int): sm.set_shader_parameter("frame", i)
		match n:
			"Spellcast_Raise":
				ft.tween_callback(F.bind(2)); ft.tween_interval(0.9)
				for k in 4:
					ft.tween_callback(F.bind(3)); ft.tween_interval(0.22); ft.tween_callback(F.bind(4)); ft.tween_interval(0.22)
			"2H_Melee_Attack_Chop":
				ft.tween_callback(F.bind(4)); ft.tween_interval(0.25); ft.tween_callback(F.bind(5)); ft.tween_interval(0.7); ft.tween_callback(F.bind(0))
			_:
				ft.set_loops(6); ft.tween_callback(F.bind(0)); ft.tween_interval(0.35); ft.tween_callback(F.bind(1)); ft.tween_interval(0.35)
		match n:
			"Spellcast_Raise":
				tw.set_loops(3); tw.tween_property(spr, "scale", Vector3(1.04, 0.97, 1.0), 0.35); tw.tween_property(spr, "scale", Vector3.ONE, 0.35)
			"2H_Melee_Attack_Chop":
				tw.tween_property(spr, "scale", Vector3(0.95, 1.08, 1.0), 0.25); tw.tween_property(spr, "scale", Vector3(1.1, 0.92, 1.0), 0.12); tw.tween_property(spr, "scale", Vector3.ONE, 0.3)
			_:
				tw.tween_property(spr, "scale", Vector3(1.05, 1.05, 1.0), 0.4)
	return {"root": root, "ap": ap, "lava": sm, "light": lt}

func meteor(from: Vector3, to: Vector3, delay: float) -> void:
	await wait(delay)
	var n := Node3D.new(); add_child(n); n.position = from
	mi(n, sph(0.35, 10), Vector3.ZERO, glow(Color(1, 0.7, 0.3), 1.0, 8.0))
	var tr := fire_particles(Vector3.ZERO, 50, 0.3, 1.6); remove_child(tr); n.add_child(tr); tr.local_coords = false
	(tr.process_material as ParticleProcessMaterial).gravity = Vector3(0, 2, 0)
	var tw := create_tween(); tw.tween_property(n, "position", to, 0.45).set_ease(Tween.EASE_IN)
	await tw.finished
	sfx("explode", 0.15, -8.0)
	burst(to + Vector3(0, 0.2, 0), Color(1, 0.5, 0.1), 40, 6.0, "spark.png", 0.25, 0.8)
	burst(to + Vector3(0, 0.3, 0), Color(0.3, 0.25, 0.22, 0.7), 10, 1.5, "smoke.png", 1.2, 1.6, 0.6)
	shake = max(shake, 0.4)
	tr.emitting = false; n.get_child(0).visible = false
	get_tree().create_timer(1.2).timeout.connect(n.queue_free)

func do_summon(u, c: Vector2i) -> void:
	hide_menu()
	u.mp -= summon_cost(u)
	fill_card(card, u)
	face(u, cell_pos(c))
	log_msg("%s 詠唱召喚咒文……" % u.name)
	voice(u, "line", "sum_ifr")
	var fx: Array = []
	var cpos: Vector3 = u.node.position
	play(u, "Spellcasting", 0.15)
	sfx("magic", 0.0, -4.0)
	var mc1 := magic_circle(cpos + Vector3(0, 0.06, 0), 1.3, Color(1, 0.5, 0.15)); fx.append(mc1)
	fx.append(make_rise(cpos, Color(1, 0.6, 0.2), 0.9))
	var lt0 := OmniLight3D.new(); lt0.light_color = Color(1, 0.55, 0.2); lt0.light_energy = 3; lt0.omni_range = 5; lt0.position = cpos + Vector3(0, 1, 0); add_child(lt0); fx.append(lt0)
	# 天色轉暗
	var old_sun := sun.light_energy; var old_amb := env.ambient_light_energy; var old_fog := env.fog_light_color
	var et := create_tween().set_parallel()
	et.tween_property(sun, "light_energy", 0.25, 1.2); et.tween_property(env, "ambient_light_energy", 0.25, 1.2)
	et.tween_property(env, "fog_light_color", Color(0.45, 0.15, 0.08), 1.2); et.tween_property(env, "background_energy_multiplier", 0.35, 1.2)
	await wait(1.0)
	# 鏡頭飛向目標
	var tp := cell_pos(c)
	var old_pos := cam_pivot.position; var old_yaw := target_yaw; var old_dist := target_dist; var old_pitch := target_pitch
	target_yaw = round(old_yaw / 360.0) * 360.0 + 25.0; target_dist = 20.0; target_pitch = 16.0
	# 橫幅移到畫面最上緣、單行小字，避免遮住伊弗利特頭部
	title_panel.visible = false
	banner.text = "召喚獸　伊弗利特　— 地獄之焰 —"; banner.visible = true; banner.modulate.a = 0
	banner.position = Vector2(0, 6); banner.size = Vector2(1600, 84); banner.add_theme_font_size_override("font_size", 40)
	banner_bg.position = Vector2(0, 10); banner_bg.size = Vector2(1600, 76)
	var bt := create_tween().set_parallel(); bt.tween_property(banner, "modulate:a", 1.0, 0.5); bt.tween_property(banner_bg, "modulate:a", 0.75, 0.5)
	sfx("summon", 0.0, -2.0)
	var mc2 := magic_circle(tp + Vector3(0, 0.08, 0), 3.4, Color(1, 0.35, 0.05)); fx.append(mc2)
	var mc3 := magic_circle(tp + Vector3(0, 3.5, 0), 2.4, Color(1, 0.6, 0.2)); fx.append(mc3)
	var pillar := MeshInstance3D.new(); pillar.mesh = cyl(1.4, 1.9, 16.0, 24); (pillar.mesh as CylinderMesh).cap_top = false; (pillar.mesh as CylinderMesh).cap_bottom = false
	var pm := shmat(SH.PILLAR); pm.set_shader_parameter("noise_tex", noise_tex); pm.set_shader_parameter("power", 0.0); pillar.material_override = pm
	pillar.position = tp + Vector3(0, 8, 0); add_child(pillar); fx.append(pillar)
	var pt := create_tween(); pt.tween_method(func(v): pm.set_shader_parameter("power", v), 0.0, 1.3, 0.7)
	fx.append(make_rise(tp, Color(1, 0.5, 0.1), 2.6, 220))
	# 伊弗利特從地底升起
	var off := Vector3(0, 0, 1).rotated(Vector3.UP, deg_to_rad(target_yaw))
	var ifd := make_ifrit()
	var ifr: Node3D = ifd.root
	add_child(ifr); fx.append(ifr)
	ifr.scale = Vector3.ONE * 3.0
	var side := off.cross(Vector3.UP).normalized()
	var ib := tp - off * 3.0 + side * 4.6
	ifr.position = ib + Vector3(0, -5.5, 0); ifr.rotation.y = atan2(tp.x - ib.x, tp.z - ib.z)
	cam_pivot.position = Vector3(tp.x * 0.35 + ib.x * 0.65, tp.y + 3.0, tp.z * 0.35 + ib.z * 0.65)
	ifd.ap.play("Spellcast_Raise"); ifd.ap.speed_scale = 0.8
	var it := create_tween(); it.tween_property(ifr, "position:y", ib.y - 0.2, 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	shake = 0.8
	await wait(1.2)
	var pt2 := create_tween(); pt2.tween_method(func(v): pm.set_shader_parameter("power", v), 1.3, 0.35, 0.6)
	await wait(0.5)
	if autotest and not summon_shot_done:
		await shot("03_summon")
		var sv := [cam_pivot.position, target_yaw, target_dist, target_pitch]
		cam_pivot.position = ifr.global_position + Vector3(0, 3.4, 0)
		target_dist = 12.0; target_pitch = 8.0
		yaw = target_yaw; cam_dist = target_dist; pitch = target_pitch
		await wait(0.5)
		await shot("03c_ifrit_close")
		cam_pivot.position = sv[0]; target_yaw = sv[1]; target_dist = sv[2]; target_pitch = sv[3]
		yaw = target_yaw; cam_dist = target_dist; pitch = target_pitch
	# 隕石雨 + 主火球
	voice(u, "line", "sk_ifr")
	ifd.ap.play("2H_Melee_Attack_Chop"); ifd.ap.speed_scale = 0.9
	for i in 6:
		var tgt := tp + Vector3(randf_range(-2.2, 2.2), 0, randf_range(-2.2, 2.2))
		meteor(tgt + Vector3(randf_range(-4, 4), 14, randf_range(-4, 4)), tgt, 0.12 * i)
	await wait(0.55)
	var ball := Node3D.new(); add_child(ball); fx.append(ball)
	ball.position = ifr.global_position + Vector3(0, 4.5, 0)
	mi(ball, sph(0.7, 16), Vector3.ZERO, glow(Color(1, 0.75, 0.35), 1.0, 8.0))
	var bfp := fire_particles(Vector3.ZERO, 80, 0.6, 2.5); remove_child(bfp); ball.add_child(bfp); bfp.local_coords = false
	var bl := create_tween(); bl.tween_property(ball, "position", tp + Vector3(0, 0.3, 0), 0.4).set_ease(Tween.EASE_IN)
	pm.set_shader_parameter("power", 0.12)
	await bl.finished
	ball.visible = false
	# 大爆炸：衝擊波、火球、煙
	sfx("explode", 0.0, 0.0)
	var boom := mi(self, sph(1.0, 24), tp, glow(Color(1, 0.55, 0.15), 0.9, 6.0), Vector3.ZERO, Vector3(0.2, 0.2, 0.2)); fx.append(boom)
	var bt2 := create_tween(); bt2.tween_property(boom, "scale", Vector3(2.4, 1.6, 2.4), 0.35).set_ease(Tween.EASE_OUT)
	bt2.parallel().tween_property(boom.material_override, "albedo_color:a", 0.0, 0.9)
	var wave := MeshInstance3D.new(); var tor := TorusMesh.new(); tor.inner_radius = 0.85; tor.outer_radius = 1.0; tor.rings = 48; wave.mesh = tor
	wave.material_override = glow(Color(1, 0.7, 0.3), 0.9, 5.0); wave.position = tp + Vector3(0, 0.2, 0); wave.scale = Vector3(0.3, 0.2, 0.3); add_child(wave); fx.append(wave)
	var wt := create_tween(); wt.tween_property(wave, "scale", Vector3(6, 0.4, 6), 0.6).set_ease(Tween.EASE_OUT)
	wt.parallel().tween_property(wave.material_override, "albedo_color:a", 0.0, 0.6)
	burst(tp + Vector3(0, 0.4, 0), Color(1, 0.55, 0.15), 160, 11.0, "spark.png", 0.3, 1.1, -5.0)
	burst(tp + Vector3(0, 0.6, 0), Color(0.28, 0.22, 0.2, 0.6), 22, 3.5, "smoke.png", 2.4, 2.6, 0.8)
	ifd.light.light_energy = 5
	pm.set_shader_parameter("power", 0.0)
	flash.color = Color(1, 0.8, 0.55, 0.25)
	var ft := create_tween(); ft.tween_property(flash, "color:a", 0.0, 0.4)
	shake = 1.4
	var hits := 0
	for a in aoe_cells(c):
		var t = unit_at(a)
		if t != null and t.team != u.team:
			var dmg := int(summon_dmg(u, t) * randf_range(0.92, 1.08))
			t.hp = max(0, t.hp - dmg); hits += 1; track_dmg(u, t, dmg)
			popup(t.node.position, str(dmg), Color(1, 0.6, 0.2), true)
			hit_flash(t, Color(1, 0.5, 0.1)); play(t, "Hit_B", 0.05)
			update_label(t)
			log_msg("地獄之焰 對 %s 造成 %d 傷害" % [t.name, dmg])
			if t.hp <= 0: kill(t)
			else:
				after_damage(t)
				var tt = t
				get_tree().create_timer(0.8).timeout.connect(func(): if tt.alive: play(tt, idle_anim(tt), 0.3))
	if hits == 0: log_msg("地獄之焰 沒有擊中任何敵人")
	await wait(0.75)
	if autotest and not summon_shot_done:
		summon_shot_done = true
		await shot("03b_summon_blast")
	await wait(1.1)
	# 消散
	ifd.ap.play("Cheer")
	get_tree().create_timer(0.45).timeout.connect(func():
		if is_instance_valid(ifr):
			for m in ifr.find_children("*", "MeshInstance3D", true, false):
				if (m as MeshInstance3D).material_override != ifd.lava: m.visible = false)
	var ot := create_tween().set_parallel()
	ot.tween_method(func(v): ifd.lava.set_shader_parameter("dissolve", v), 0.0, 1.05, 1.0)
	ot.tween_property(banner, "modulate:a", 0.0, 0.7); ot.tween_property(banner_bg, "modulate:a", 0.0, 0.7)
	ot.tween_method(func(v): pm.set_shader_parameter("power", v), 0.35, 0.0, 0.7)
	ot.tween_property(sun, "light_energy", old_sun, 1.2); ot.tween_property(env, "ambient_light_energy", old_amb, 1.2)
	ot.tween_property(env, "fog_light_color", old_fog, 1.2); ot.tween_property(env, "background_energy_multiplier", 1.0, 1.2)
	ot.tween_property(ifd.light, "light_energy", 0.0, 1.0)
	await ot.finished
	banner.visible = false; title_panel.visible = true
	banner.position = Vector2(0, 120); banner.size = Vector2(1600, 170); banner.add_theme_font_size_override("font_size", 60)
	banner_bg.position = Vector2(0, 130); banner_bg.size = Vector2(1600, 150)
	for f in fx:
		if is_instance_valid(f): f.queue_free()
	play(u, idle_anim(u), 0.3)
	var rt2 := create_tween(); rt2.tween_property(cam_pivot, "position", old_pos, 0.8)
	target_yaw = old_yaw; target_dist = old_dist; target_pitch = old_pitch
	await wait(0.8)
	if u.team == 0: await grant_exp(u, 15 + hits * 10)

func make_rise(pos: Vector3, col: Color, radius: float, amount := 90) -> GPUParticles3D:
	var p := GPUParticles3D.new(); p.amount = amount; p.lifetime = 1.4
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING; pm.emission_ring_radius = radius; pm.emission_ring_inner_radius = radius * 0.3; pm.emission_ring_height = 0.1
	pm.emission_ring_axis = Vector3.UP
	pm.gravity = Vector3(0, 3.0, 0); pm.initial_velocity_min = 0.3; pm.initial_velocity_max = 1.2; pm.direction = Vector3.UP; pm.spread = 15
	pm.tangential_accel_min = 1.0; pm.tangential_accel_max = 2.5
	var g := Gradient.new(); g.set_color(0, Color(1, 0.95, 0.7, 1)); g.set_color(1, Color(col.r, col.g, col.b, 0)); var gt := GradientTexture1D.new(); gt.gradient = g; pm.color_ramp = gt
	p.process_material = pm
	var q := quad(0.12, 0.12); q.material = particle_mat("spark.png", Color.WHITE); p.draw_pass_1 = q
	p.position = pos + Vector3(0, 0.1, 0); add_child(p)
	return p

# ---------------- AI ----------------
func ai_decide(u) -> Dictionary:
	var r := reachable(u)
	var best := {}; var best_score := -1e9
	for c in r.ends:
		for t in foes(u):
			if in_range(u, c, t.cell):
				var p := calc(u, t, c)
				var sc: float = p.hit * p.dmg / 100.0 + (60.0 if p.dmg >= t.hp else 0.0) + heights[c] * 0.5 - mdist(c, u.cell) * 0.1
				if ranged(u): sc += mdist(c, t.cell) * 0.6
				if sc > best_score: best_score = sc; best = {"move": c, "target": t, "parent": r.parent}
	if not best.is_empty(): return best
	if u.team == 1:
		var hm = hold_move(u)
		if hm != null: return hm
	var bc: Vector2i = u.cell; var bd := 1e9
	for c in r.ends:
		var md := 1e9
		for t in foes(u): md = min(md, mdist(c, t.cell))
		var sc: float = md - heights[c] * 0.1
		if sc < bd: bd = sc; bc = c
	return {"move": bc, "target": null, "parent": r.parent}

func heal_plan(u):
	if u.job != "僧侶" or u.mp < HEAL_COST: return null
	var best = null; var bm := 0.0
	for t in alive_team(u.team):
		var miss: float = 1.0 - float(t.hp) / float(st(t, "hp"))
		if miss > 0.35 and miss > bm and mdist(t.cell, u.cell) <= 3: bm = miss; best = t
	return best

func enemy_ai(u) -> void:
	if u.get("hidden", false) or u.get("npc_wait", false):
		await wait(0.1); end_turn(); return
	await wait(0.5)
	if u.boss and u.turns % 2 == 0:
		if await boss_skill(u):
			if await check_end(): return
			end_turn(); return
	var hp_t = heal_plan(u)
	if hp_t != null:
		await do_heal(u, hp_t); acted = true
		end_turn(); return
	if (caster(u) or ucls(u) != "") and randi() % 100 < (35 if u.boss else 40):
		var mp = magic_plan(u)
		if mp != null:
			if mp.move != u.cell: await move_unit(u, mp.move, mp.parent); moved = true
			await do_magic(u, mp.spell, mp.cell); acted = true
			if await check_end(): return
			end_turn(); return
	var dcs := ai_decide(u)
	if dcs.move != u.cell:
		await move_unit(u, dcs.move, dcs.parent); moved = true
	if dcs.target != null and dcs.target.alive:
		await do_attack(u, dcs.target); acted = true
	if await check_end(): return
	end_turn()

func summon_plan(u):
	if u.mp < summon_cost(u): return null
	var r := reachable(u)
	var best = null; var bn := 0
	for c in r.ends:
		for t in heights:
			if mdist(c, t) > SUMMON_RANGE: continue
			var n := 0
			for a in aoe_cells(t):
				var o = unit_at(a)
				if o != null and o.alive and o != u and o.team != u.team: n += 1
			if n > bn: bn = n; best = {"move": c, "cell": t, "parent": r.parent}
	return best

# 自動測試：玩家單位透過與滑鼠相同的指令流程操作
func auto_use_item(u, k: String, c: Vector2i) -> bool:
	if G.items.get(k, 0) <= 0: return false
	cmd_item(); await wait(0.25)
	pick_item(k); on_hover(c); await wait(0.3)
	if not hl_cells.has(c): cancel(); return false
	await on_cell_clicked(c)
	return true

# 自動測試：玩家單位透過與滑鼠相同的指令流程操作
func auto_player(u) -> void:
	await wait(0.4)
	if ally_item_test and u.team == 0:
		ally_item_test = false
		G.items["回復藥"] = 3
		var tgt = null
		for o in alive_team(0):
			if o != u and mdist(o.cell, u.cell) == 1: tgt = o
		if tgt == null:
			for o in alive_team(0):
				if o != u:
					for c in heights:
						if mdist(c, o.cell) == 1 and unit_at(c) == null and abs(c.x - u.cell.x) + abs(c.y - u.cell.y) <= 6:
							units.erase(u); u.cell = c; u.node.position = cell_pos(c); units.append(u); tgt = o; break
				if tgt != null: break
		tgt.hp = maxi(1, tgt.hp - 40); update_label(tgt)
		var h0: int = tgt.hp
		cmd_item(); await wait(0.5); await shot_to(shots_dir + "/v25_item_menu.png")
		pick_item("回復藥"); on_hover(tgt.cell); await wait(0.8)
		print("ALLYITEM cells=%s target_ok=%s self_ok=%s" % [str(hl_cells.size()), str(hl_cells.has(tgt.cell)), str(hl_cells.has(u.cell))])
		await shot_to(shots_dir + "/v25_item_target_ally.png")
		await on_cell_clicked(tgt.cell); await wait(1.0)
		await shot_to(shots_dir + "/v25_item_used_on_ally.png")
		print("ALLYITEM %s used on %s hp %d->%d" % [u.name, tgt.name, h0, tgt.hp])
		print("ALLYITEM DONE"); get_tree().quit(); return
	if do_shots and not menu_shot_done and u.team == 0:
		menu_shot_done = true
		state = "menu"; show_menu(); await wait(0.8)
		for b in menu_box.get_children():
			if b is Button and not b.disabled and b.text.begins_with("攻擊"): b.grab_focus(); b.emit_signal("mouse_entered")
		await wait(0.5); await shot("02b_action_menu")
		if menu_shot: get_tree().quit(); return
		hide_menu(); state = "anim"
	if cur == u and state == "anim": state = "menu"
	if evtest:
		print("EVAUTO ", u.name, " cell=", u.cell, " goal=", ev_cell, " active=", ev_active(), " round=", round_no)
		if not acted and await ev_auto(u): return
		if cur != u or state == "over": return
	if "--withadam" in OS.get_cmdline_user_args() and not acted and not fx_shots.has("adam_done") and u.job == "召喚師" and G.has_adam() and u.mp >= adam_cost(u):
		var ac0 = adam_plan(u)
		if ac0 != null:
			fx_shots["adam_done"] = true; print("ADAM SHOWCASE ", u.name, " at ", ac0)
			cmd_summon_adam(); on_hover(ac0); await wait(0.4)
			await on_cell_clicked(ac0)
			if state == "over": return
			if state == "menu": cmd_wait()
			return
	if not equip_tested and u.member != null and allowed_weapons(u).size() > 1:
		equip_tested = true
		cmd_equip(); await wait(0.6)
		var before := stat_short(u)
		var ws := allowed_weapons(u)
		equip(u, "weapon", ws[ws.size() - 1])
		print("EQUIP TEST in battle: ", u.weapon, " ", before.replace("\n", " | "), " => ", stat_short(u).replace("\n", " | "))
		await wait(0.2); close_equip(); await wait(0.3); hide_menu()
	if not acted and has_rage(u) and int(u.get("rage", 0)) >= RAGE_MAX and not (u.hp * 100 < st(u, "hp") * 25):
		var spn = special_plan(u)
		if spn != null:
			if spn.move != u.cell:
				cmd_move(); await wait(0.3); await on_cell_clicked(spn.move)
				if state == "over": return
			cmd_special(); special_hover(spn.cell); await wait(0.4)
			await on_cell_clicked(spn.cell)
			if state == "over": return
			if state == "menu": cmd_wait()
			return
	# 道具
	if not acted:
		if u.status.has("poison") and (await auto_use_item(u, "解毒草", u.cell) or await auto_use_item(u, "萬能藥", u.cell)): pass
		elif u.hp * 100 < st(u, "hp") * 40:
			for k in ["高級回復藥", "回復藥", "全效藥"]:
				if await auto_use_item(u, k, u.cell): break
		if state == "over": return
	if cur != u or state == "over": return
	if not acted and downed_allies(0).size() >= 2 and G.items.get("轉生之靈", 0) > 0:
		await auto_use_item(u, "轉生之靈", u.cell)
	for rk in ["鳳凰之羽", "復甦草", "不死鳥之淚"]:
		if acted or G.items.get(rk, 0) <= 0: continue
		for o in downed_allies(0):
			if mdist(o.cell, u.cell) <= 1 and unit_at(o.cell) == null:
				await auto_use_item(u, rk, o.cell); break
	if not acted:
		for k in ["雷鳴符", "火焰瓶"]:
			if G.items.get(k, 0) <= 0 or item_tested.has(k): continue
			for t in foes(u):
				if mdist(t.cell, u.cell) <= int(G.I[k].range):
					item_tested[k] = true
					await auto_use_item(u, k, t.cell); break
			if acted: break
		if state == "over": return
	if cur != u or state == "over": return
	if not acted and u.job == "僧侶":
		var ht = heal_plan(u)
		if ht != null:
			cmd_heal(); on_hover(ht.cell); await wait(0.3); await on_cell_clicked(ht.cell)
			if state == "over": return
			if state == "menu": cmd_wait()
			return
	if not acted and not silenced(u) and u.job == "召喚師" and G.has_adam() and (randi() % 100 < 45 or not fx_shots.has("adam_done")):
		var ac = adam_plan(u)
		if ac != null:
			fx_shots["adam_done"] = true
			cmd_summon_adam(); on_hover(ac); await wait(0.4)
			await on_cell_clicked(ac)
			if state == "over": return
			if state == "menu": cmd_wait()
			return
	if not acted and u.job == "召喚師" and u.team == 0 and G.has_lev():
		var lp = lev_plan(u)
		if lp != null and (lp.score >= 3.0 or (autotest and not lev_shot_done and lp.score >= 1.0)):
			if lp.move != u.cell:
				cmd_move(); await on_cell_clicked(lp.move)
				if state == "over": return
			cmd_summon_lev(); on_hover(lp.cell); await wait(0.5)
			await on_cell_clicked(lp.cell)
			if state == "over": return
			if state == "menu": cmd_wait()
			return
	if not acted and (caster(u) or ucls(u) != "") and (u.job != "召喚師" or summon_plan(u) == null or randi() % 100 < 50):
		var mg = magic_plan(u, not moved)
		if mg != null:
			if mg.move != u.cell:
				cmd_move(); await on_cell_clicked(mg.move)
				if state == "over": return
			cmd_magic(); await wait(0.3); pick_spell(mg.spell); on_hover(mg.cell); await wait(0.5)
			await on_cell_clicked(mg.cell)
			if state == "over": return
			if state == "menu": cmd_wait()
			return
	if not acted and u.job == "召喚師":
		var sp = summon_plan(u)
		if sp != null:
			if sp.move != u.cell:
				cmd_move(); await on_cell_clicked(sp.move)
				if state == "over": return
			cmd_summon(); on_hover(sp.cell); await wait(0.5)
			await on_cell_clicked(sp.cell)
			if state == "over": return
			if state == "menu": cmd_wait()
			return
	if cur != u or state == "over": return
	var d := ai_decide(u)
	if OS.has_environment("SRPG_TRACE"): print("AUTO ", u.name, " move=", d.move, " from=", u.cell, " state=", state)
	if not moved and d.move != u.cell:
		cmd_move(); await wait(0.3); await on_cell_clicked(d.move)
		if state == "over": return
	if not acted and d.target != null and d.target.alive and in_range(u, u.cell, d.target.cell):
		cmd_attack(); on_hover(d.target.cell); await wait(0.4); await on_cell_clicked(d.target.cell)
		if state == "over": return
	if cur == u and (state == "move" or state == "attack"):
		print("AUTO FALLBACK state=", state, " unit=", u.name); clear_hl(); state = "menu"
	if state == "menu": cmd_wait()

func shot(n: String) -> void:
	if not do_shots: return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(shots_dir)
	var img := get_viewport().get_texture().get_image()
	var nm := "b%02d_%s" % [bidx + 1, n]
	var err := img.save_png(shots_dir + "/" + nm + ".png")
	print("SHOT ", nm, " err=", err)

# ---------------- 主線劇情 ----------------
const PROLOGUE := [
	["旁白", "帝國曆三一七年。"],
	["旁白", "瓦爾坎帝國以「統一法典」之名，十年間吞併了七個邦國。"],
	["旁白", "三年前，洛薩里亞公國被冠上叛亂之罪而廢除，公爵於帝都廣場受刑。"],
	["旁白", "此後，帝國的運糧車隊源源不絕地駛過北境，舊公國的子民在重稅與徵兵之下沉默。"],
	["旁白", "今夜，一面早已被禁的藍底金陽旗，在帝國北方補給樞紐「灰石關」外的山丘上升起——"],
]
const PRE_BATTLE := [
	["葛雷", "斥候回報，關內守軍不到兩百。帶隊的是……第三軍團長，加爾德。"],
	["雷恩", "……加爾德。教我握劍的人，也是三年前替帝國打開公國城門的人。"],
	["米菈", "殿下，自由都市同盟的商人說了，要等我們拿下灰石關，才肯送來糧食與弩箭。這一仗輸不起。"],
	["艾琳", "城牆上的弩手交給我。你們只要記得一件事——別讓他們點起烽火。"],
	["黑騎士加爾德", "洛薩里亞的金陽旗……原來公爵家還有人活著。雷恩，回去吧。帝國不是一面旗就能撼動的。"],
	["雷恩", "我不是來撼動帝國的，加爾德。我是來把被奪走的東西，一件一件拿回來。"],
	["黑騎士加爾德", "那就拔劍。讓我看看，你還記得多少我教你的東西。"],
	["雷恩", "全軍聽令——奪下灰石關！"],
]
const POST_WIN := [
	["旁白", "加爾德身負重傷，在親衛拚死掩護下自後門撤離。灰石關城頭的帝國鷲旗，緩緩降下。"],
	["葛雷", "倉庫裡堆滿了從北境村莊徵來的穀物，夠三個村子過冬。殿下，分給百姓，還是留作軍糧？"],
	["雷恩", "分一半給百姓。我們若和帝國一樣搶，就沒有資格舉起這面旗。"],
	["米菈", "殿下，在加爾德的營帳裡找到這封密函……封蠟是宰相馬克西姆斯的印。"],
	["雷恩", "「北境叛軍可任其坐大。待其攻陷灰石關，即以『同盟資助叛逆』為名，向自由都市宣戰。」……我們被利用了。"],
	["艾琳", "宰相要的是同盟的港口和金庫。我們只是他點燃戰火的那根火柴。"],
	["雷恩", "那就讓這根火柴，燒到他料想不到的地方。整軍——趕在帝國大軍之前，前往自由都市。"],
	["旁白", "第一章「灰石關」完。"],
]
const POST_LOSE := [
	["黑騎士加爾德", "這就是你的覺悟嗎，雷恩……太輕了。"],
	["旁白", "金陽旗再次倒在北境的泥土裡。——但只要還有人記得，它就會再升起。"],
]

var dlg := {}
var dlg_active := false
var dlg_adv := false
var dlg_skip := false

func build_dialog() -> void:
	var veil := ColorRect.new(); veil.set_anchors_preset(Control.PRESET_FULL_RECT); veil.color = Color(0.02, 0.015, 0.01, 0.0)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE; veil.visible = false; ui_root.add_child(veil)
	# v15：旁白改為逐行淡入（無打字機效果）
	var nl := VBoxContainer.new(); nl.position = Vector2(260, 150); nl.size = Vector2(1080, 560); nl.alignment = BoxContainer.ALIGNMENT_CENTER
	nl.add_theme_constant_override("separation", 26); nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.add_child(nl)
	var root := Control.new(); root.position = Vector2(170, 640); root.size = Vector2(1260, 250); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.visible = false; ui_root.add_child(root)
	var tail := Polygon2D.new(); tail.polygon = PackedVector2Array([Vector2(330, 6), Vector2(390, 6), Vector2(345, -34)]); tail.color = Color(0.92, 0.85, 0.7); root.add_child(tail)
	var tail2 := Line2D.new(); tail2.points = PackedVector2Array([Vector2(330, 4), Vector2(345, -34), Vector2(390, 4)]); tail2.width = 3; tail2.default_color = Color(0.47, 0.31, 0.16); root.add_child(tail2)
	var p := PanelContainer.new(); p.position = Vector2(0, 40); p.size = Vector2(1260, 200); p.add_theme_stylebox_override("panel", sbt("panel.png", 16, 10)); p.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(p)
	root.move_child(p, 0)
	var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 20); p.add_child(hb)
	var v := VBoxContainer.new(); v.size_flags_horizontal = Control.SIZE_EXPAND_FILL; v.add_theme_constant_override("separation", 8); hb.add_child(v)
	var tx := lbl("", 27, Color(0.2, 0.13, 0.08)); tx.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY; tx.custom_minimum_size = Vector2(980, 120); tx.size_flags_vertical = Control.SIZE_EXPAND_FILL; v.add_child(tx)
	var hint := lbl("▼ 點擊／Enter 繼續　　Esc 跳過劇情", 15, Color(0.45, 0.35, 0.25)); hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; v.add_child(hint)
	var frame := PanelContainer.new(); frame.add_theme_stylebox_override("panel", sbt("parchment.png", 12, -6)); frame.custom_minimum_size = Vector2(176, 176); hb.add_child(frame)
	var pt := TextureRect.new(); pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; pt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; pt.custom_minimum_size = Vector2(164, 164); frame.add_child(pt)
	var plate := PanelContainer.new(); var ps := StyleBoxFlat.new(); ps.bg_color = Color(0.32, 0.08, 0.05, 0.94); ps.border_color = Color(0.9, 0.72, 0.35)
	ps.set_border_width_all(3); ps.set_corner_radius_all(6); ps.shadow_color = Color(0, 0, 0, 0.45); ps.shadow_size = 6; ps.shadow_offset = Vector2(2, 3)
	plate.add_theme_stylebox_override("panel", ps); plate.position = Vector2(10, -8); plate.custom_minimum_size = Vector2(230, 50); plate.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(plate)
	var gold := StyleBoxFlat.new(); gold.draw_center = false; gold.border_color = Color(0.85, 0.66, 0.3); gold.set_border_width_all(4); gold.set_corner_radius_all(4)
	gold.shadow_color = Color(0, 0, 0, 0.35); gold.shadow_size = 4
	var gf := Panel.new(); gf.add_theme_stylebox_override("panel", gold); gf.mouse_filter = Control.MOUSE_FILTER_IGNORE; gf.set_anchors_preset(Control.PRESET_FULL_RECT); frame.add_child(gf)
	var arrow := lbl("▼", 22, Color(0.75, 0.35, 0.08)); arrow.position = Vector2(1214, 196); root.add_child(arrow)
	var at := arrow.create_tween().set_loops(); at.tween_property(arrow, "position:y", 204.0, 0.4).set_trans(Tween.TRANS_SINE); at.tween_property(arrow, "position:y", 196.0, 0.4).set_trans(Tween.TRANS_SINE)
	var nm := lbl("", 32, Color(1, 1, 1), true, true); nm.position = Vector2(30, -10); nm.add_theme_constant_override("outline_size", 10); nm.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.04)); root.add_child(nm)
	var sk := Button.new(); sk.text = "跳過劇情 ▶▶"; sk.position = Vector2(1404, 586); sk.size = Vector2(170, 46); sk.visible = false
	sk.pressed.connect(func(): dlg_skip = true)
	ui_root.add_child(sk)
	dlg = {"veil": veil, "narr": nl, "panel": root, "portrait": pt, "frame": frame, "name": nm, "text": tx, "skip": sk, "plate": plate}

func find_unit(n: String):
	for u in units:
		if u.name == n: return u
	return null

func _input(e: InputEvent) -> void:
	if not dlg_active: return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if dlg.skip.get_global_rect().has_point(e.position): return
		dlg_adv = true; get_viewport().set_input_as_handled()
	elif e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_ESCAPE: dlg_skip = true
		elif e.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]: dlg_adv = true
		get_viewport().set_input_as_handled()

func wait_adv(lbl_node: Label) -> void:
	dlg_adv = false
	var tw := create_tween(); tw.tween_property(lbl_node, "visible_ratio", 1.0, clampf(lbl_node.text.length() * 0.028, 0.3, 2.2))
	var t0 := Time.get_ticks_msec()
	while not dlg_skip:
		await get_tree().process_frame
		if dlg_adv:
			dlg_adv = false
			if lbl_node.visible_ratio < 1.0: tw.kill(); lbl_node.visible_ratio = 1.0
			else: break
		if autotest and lbl_node.visible_ratio >= 1.0 and Time.get_ticks_msec() - t0 > (2200 if do_shots else 500): break
	if tw.is_valid(): tw.kill()
	lbl_node.visible_ratio = 1.0

func play_story(lines: Array, narration := false, shots := {}, vo := {}) -> void:
	var prev_state := state
	state = "story"; dlg_active = true; dlg_skip = false
	dlg.skip.visible = true
	var old_pos := cam_pivot.position; var old_yaw := target_yaw; var old_dist := target_dist; var old_pitch := target_pitch
	if narration:
		dlg.veil.visible = true; for c in dlg.narr.get_children(): c.queue_free()
		var vt := create_tween(); vt.tween_property(dlg.veil, "color:a", 0.88, 0.6)
	for i in lines.size():
		if dlg_skip: break
		var who: String = lines[i][0]; var txt: String = lines[i][1]
		if narration:
			var ln := Label.new(); ln.text = txt; ln.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY; ln.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ln.custom_minimum_size = Vector2(1080, 0); ln.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ln.add_theme_font_override("font", narr_font); ln.add_theme_font_size_override("font_size", 34); ln.add_theme_color_override("font_color", Color(0.97, 0.9, 0.72))
			ln.add_theme_color_override("font_shadow_color", Color(1.0, 0.7, 0.3, 0.22)); ln.add_theme_constant_override("shadow_outline_size", 12)
			ln.add_theme_constant_override("shadow_offset_x", 0); ln.add_theme_constant_override("shadow_offset_y", 0)
			ln.modulate.a = 0.0; dlg.narr.add_child(ln)
			var tw := create_tween(); tw.tween_property(ln, "modulate:a", 1.0, 1.6).set_trans(Tween.TRANS_SINE)
			dlg_adv = false
			while tw.is_running() and not dlg_skip:
				await get_tree().process_frame
				if dlg_adv: dlg_adv = false; tw.custom_step(10.0)
			if not autotest: await get_tree().create_timer(0.6).timeout
			dlg_lines += 1
			if autotest and shots.has(i): await shot(shots[i])
			dlg_adv = false
			var t0 := Time.get_ticks_msec()
			while not dlg_skip and not dlg_adv:
				await get_tree().process_frame
				if autotest and Time.get_ticks_msec() - t0 > (1500 if do_shots else 400): break
			continue
		var u = find_unit(who)
		dlg_lines += 1
		dlg.panel.visible = true; card.panel.visible = false; tcard.panel.visible = false
		dlg.name.text = who
		dlg.plate.custom_minimum_size.x = 60.0 + who.length() * 34.0; dlg.plate.size.x = dlg.plate.custom_minimum_size.x
		if u != null:
			dlg.frame.visible = true; dlg.portrait.texture = u.portrait
			dlg.name.add_theme_color_override("font_color", Color(1, 0.9, 0.55) if u.get("hero", false) else (Color(0.85, 0.92, 1.0) if u.team == 0 else Color(1, 0.8, 0.75)))
			if u.alive:
				var p: Vector3 = u.node.position
				var ct := create_tween(); ct.tween_property(cam_pivot, "position", Vector3(p.x, p.y + 0.6, p.z), 0.6).set_trans(Tween.TRANS_SINE)
				target_yaw = rad_to_deg(u.node.rotation.y) + 25.0; target_dist = 10.0; target_pitch = 24.0
		elif G.PORTRAIT.has(who):
			dlg.frame.visible = true; dlg.portrait.texture = load("res://assets/v12/p_%s.png" % G.PORTRAIT[who])
			dlg.name.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
		else:
			dlg.frame.visible = false
			dlg.name.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
			dlg.name.text = "—— 旁白 ——"
		dlg.text.text = txt; dlg.text.visible_ratio = 0.0
		if vo.has(i) and not dlg_skip: play_line_vo(vo[i])
		if autotest and shots.has(i):
			dlg.text.visible_ratio = 1.0
			await wait(0.9)
			await shot(shots[i])
		await wait_adv(dlg.text)
	dlg.panel.visible = false; dlg.skip.visible = false; card.panel.visible = card.unit != null
	if narration:
		var vt2 := create_tween(); vt2.tween_property(dlg.veil, "color:a", 0.0, 0.6)
		await vt2.finished
		for c in dlg.narr.get_children(): c.queue_free()
		dlg.veil.visible = false
	dlg_active = false
	state = prev_state
	cam_pivot.position = old_pos; target_yaw = old_yaw; target_dist = old_dist; target_pitch = old_pitch

func hero_closeup() -> void:
	var u = find_unit("雷恩")
	var old_pos := cam_pivot.position; var old_yaw := target_yaw; var old_dist := target_dist; var old_pitch := target_pitch
	var p: Vector3 = u.node.position
	ui_root.visible = false
	cam_pivot.position = Vector3(p.x, p.y + 0.9, p.z)
	target_yaw = rad_to_deg(u.node.rotation.y) + 30.0; target_dist = 4.6; target_pitch = 12.0
	yaw = target_yaw; cam_dist = target_dist; pitch = target_pitch
	await wait(1.2)
	await shot("06_hero_closeup")
	var hp: Vector3 = u.node.position + Vector3(0, 1.3, 0)
	cam_pivot.position = hp
	target_yaw = rad_to_deg(u.node.rotation.y) + 8.0; target_dist = 2.4; target_pitch = 8.0
	yaw = target_yaw; cam_dist = target_dist; pitch = target_pitch
	await wait(0.8)
	await shot("06c_hero_face")
	var cen := Vector3.ZERO; var pu = players()
	for q in pu: cen += q.node.position
	cen /= pu.size()
	cam_pivot.position = cen + Vector3(0, 0.75, 0)
	target_yaw = 6.0; target_dist = 8.0; target_pitch = 14.0
	yaw = target_yaw; cam_dist = target_dist; pitch = target_pitch
	await wait(0.8)
	await shot("08_party")
	target_yaw = rad_to_deg(u.node.rotation.y) + 165.0; yaw = target_yaw; target_dist = 4.6; cam_dist = 4.6; target_pitch = 14.0; pitch = 14.0
	await wait(0.8)
	await shot("06b_hero_back")
	ui_root.visible = true
	cam_pivot.position = old_pos; target_yaw = old_yaw; target_dist = old_dist; target_pitch = old_pitch
	yaw = old_yaw; cam_dist = old_dist; pitch = old_pitch

func run_autotest() -> void:
	print("AUTOTEST START battle=", bidx + 1, " lose=", autolose, " name=", bdef.name)
	if not autolose:
		var bf := brief_def()
		if bf.is_empty():
			if bdef.narr.size() > 0: await play_story(bdef.narr, true, {0: "00_prologue"})
			await play_story(bdef.pre, false, {1: "05_dialog"})
		else:
			await show_briefing(bf, "00_briefing")
			await play_story(bf.field, false, {1: "05_dialog", int(bf.get("vo", 99)): "05b_boss_line"}, brief_vo(bf))
			print("BRIEFING OK battle=", bidx + 1, " field_lines=", bf.field.size())
		await ev_intro()
		await boss_entrance()
		if do_shots and bidx == 0: await hero_closeup()
	if promo_view:
		var pl := players(); var c := Vector3.ZERO
		for u in pl: c += u.node.position
		c /= maxf(1.0, pl.size())
		cam_pivot.position = c + Vector3(0, 0.8, 0); target_dist = 9.0; cam_dist = 9.0; update_cam()
		await wait(2.0); await shot("30_promo_party"); get_tree().quit(); return
	if settle_shot:
		# 聚落特寫（敵方側右下角）＋全圖俯瞰，並量測 FPS
		cam_pivot.position = cell_pos(Vector2i(W - 2, H - 2)) + Vector3(0, 0.6, 0); target_yaw = 30.0; yaw = 30.0; target_dist = 10.0; cam_dist = 10.0; target_pitch = 30.0; pitch = 30.0; update_cam()
		await wait(2.5); await shot("23_settle_b%02d_%s" % [bidx + 1, SETTLE.get(bidx, "outpost")])
		cam_pivot.position = cell_pos(Vector2i(W / 2, H / 2)); target_dist = 30.0; cam_dist = 30.0; target_pitch = 55.0; pitch = 55.0; update_cam()
		await wait(1.5); await shot("23_map_b%02d_%dx%d" % [bidx + 1, W, H])
		var ss := 0.0
		for k in 6:
			await wait(0.5); ss += Engine.get_frames_per_second()
		print("SETTLE battle=%d size=%dx%d fps=%.1f" % [bidx + 1, W, H, ss / 6.0])
		get_tree().quit(); return
	if light_shot:
		var lp := players(); var lc := Vector3.ZERO
		for q in lp: lc += q.node.position
		lc /= maxf(1.0, lp.size())
		cam_pivot.position = lc + Vector3(0, 0.6, 0); target_yaw = 35.0; yaw = 35.0; target_dist = 13.0; cam_dist = 13.0; target_pitch = 34.0; pitch = 34.0; update_cam()
		await wait(2.5); await shot("40_light_" + (wx_kind if wx_force != "" else str(bdef.theme)))
		var fsum := 0.0; var fmin := 9999.0
		for k in 10:
			await wait(0.5); var fp := Engine.get_frames_per_second(); fsum += fp; fmin = minf(fmin, fp)
		print("FPS theme=%s avg=%.1f min=%.1f renderer=%s" % [(wx_kind if wx_force != "" else str(bdef.theme)), fsum / 10.0, fmin, r_method])
		get_tree().quit(); return
	if wx_only:
		cam_dist = 18.0; update_cam()
		await wait(1.5); await shot("20_weather_" + wx_kind); get_tree().quit(); return
	if touch_test: await run_touchtest(); return
	open_equip(players(), true)
	await wait(0.8)
	var u = units[0]
	var before := stat_short(u)
	var best := ""
	for k in G.shop_list():
		if G.W.has(k) and G.can_equip(u.member.job, "weapon", k, u.hero) and (best == "" or int(G.W[k].atk) > int(G.W[best].atk)): best = k
	if best != "" and best != u.weapon:
		G.add_inv(best)
		equip(u, "weapon", best)
	print("EQUIP TEST prep: ", u.weapon, " ", before.replace("\n", " | "), " => ", stat_short(u).replace("\n", " | "))
	await wait(0.6)
	if not autolose: await shot("02_equip_menu")
	close_equip()
	await wait(0.2)
	if not autolose and do_shots:
		await wait(1.4)
		await shot("01_battlefield")
		if bidx == 0: await weapon_look_shots()
		if bidx == 0: await fx_showcase_shots()
		if fall_cell.x >= 0 and bidx in [1, 4, 9]: await waterfall_shot()

var fx_shots := {}

func fx_showcase_shots() -> void:
	# 特效展示：物理爆擊衝擊＋魔法光柱命中（慢動作擷取）
	var e = null
	e = find_unit("葛雷")
	if e == null: return
	var old_pos := cam_pivot.position; var oy := target_yaw; var od := target_dist; var op := target_pitch
	ui_root.visible = false
	cam_lock = true
	if focus_tw != null and focus_tw.is_valid(): focus_tw.kill()
	for o in units: o.node.visible = (o == e)
	var p: Vector3 = e.node.position
	print("FX SHOWCASE on ", e.name, " ", p)
	for i in 2:
		cam_pivot.position = p + Vector3(0, 0.7, 0); target_yaw = 45.0; target_dist = 5.0; target_pitch = 16.0
		yaw = target_yaw; cam_dist = target_dist; pitch = target_pitch
		await wait(0.4)
		cam_pivot.position = p + Vector3(0, 0.7, 0); yaw = target_yaw; cam_dist = target_dist; pitch = target_pitch
		if i == 0:
			impact_fx(p + Vector3(0, 0.6, 0), Color(1, 0.7, 0.25), true)
			burst(p + Vector3(0, 0.6, 0), Color(1, 0.7, 0.2), 60, 7.0, "spark.png", 0.22, 0.7)
		else:
			magic_impact(p + Vector3(0, 0.6, 0), Color(0.55, 0.45, 1.0))
		Engine.time_scale = 0.06
		for f in 3: await get_tree().process_frame
		await shot("03d_hit_fx" if i == 0 else "03e_magic_fx")
		Engine.time_scale = base_ts
		await wait(1.2)
	for o in units: o.node.visible = o.alive
	cam_lock = false
	ui_root.visible = true
	cam_pivot.position = old_pos; target_yaw = oy; target_dist = od; target_pitch = op
	yaw = oy; cam_dist = od; pitch = op

func weapon_look_shots() -> void:
	# 換裝外觀驗證：雷恩 劍→大劍、葛雷 斧→巨斧、加德 大劍→劍
	var old_pos := cam_pivot.position; var oy := target_yaw; var od := target_dist; var op := target_pitch
	ui_root.visible = false
	cam_lock = true
	if focus_tw != null and focus_tw.is_valid(): focus_tw.kill()
	await wait(1.5)
	for spec in [["雷恩", "大劍"], ["葛雷", "巨斧"]]:
		var u = find_unit(spec[0])
		if u == null: continue
		var keep: String = u.weapon
		var pick := ""
		for k in G.W.keys():
			if G.W[k].type == spec[1] and G.can_equip(u.member.job, "weapon", k, u.hero) and (pick == "" or int(G.W[k].get("tier", 0)) > int(G.W[pick].get("tier", 0))): pick = k
		if pick == "": continue
		var p: Vector3 = u.node.position
		for o in units: o.node.visible = (o == u)
		cam_pivot.position = p + Vector3(0, 0.75, 0); target_yaw = 45.0; target_dist = 4.2; target_pitch = 14.0
		yaw = target_yaw; cam_dist = target_dist; pitch = target_pitch
		await wait(0.7)
		await shot("02c_weapon_%s_before" % u.key)
		G.add_inv(pick); u.weapon = pick
		if u.member != null: u.member.weapon = pick
		refresh_look(u)
		await wait(0.7)
		cam_pivot.position = p + Vector3(0, 0.75, 0); target_yaw = 45.0; target_dist = 4.2; target_pitch = 14.0
		yaw = 45.0; cam_dist = 4.2; pitch = 14.0
		for f in 2: await get_tree().process_frame
		print("WL cam ", cam_pivot.position, " ", yaw, " ", cam_dist, " ", pitch, " unit ", u.node.position)
		print("WEAPON LOOK ", u.name, " ", keep, " -> ", pick)
		await shot("02d_weapon_%s_after" % u.key)
		u.weapon = keep
		if u.member != null: u.member.weapon = keep
		refresh_look(u)
	for o in units: o.node.visible = o.alive
	ui_root.visible = true
	cam_lock = false
	cam_pivot.position = old_pos; target_yaw = oy; target_dist = od; target_pitch = op
	yaw = oy; cam_dist = od; pitch = op

func waterfall_shot() -> void:
	var old_pos := cam_pivot.position; var oy := target_yaw; var od := target_dist; var op := target_pitch
	ui_root.visible = false
	var wb := cell_pos(fall_cell)
	for o in units: o.node.visible = false
	cam_pivot.position = Vector3(wb.x, wb.y - 2.2, H / 2.0 + 1.0); target_yaw = 12.0; target_dist = 10.0; target_pitch = 10.0
	yaw = target_yaw; cam_dist = target_dist; pitch = target_pitch
	await wait(1.0)
	await shot("01b_waterfall")
	for o in units: o.node.visible = o.alive
	ui_root.visible = true
	cam_lock = false
	cam_pivot.position = old_pos; target_yaw = oy; target_dist = od; target_pitch = op
	yaw = oy; cam_dist = od; pitch = op

func finish_autotest(win := false) -> void:
	await wait(2.5)
	await shot("04_result_lose" if autolose else "04_result_win")
	print("AUTOTEST DONE")
	if win and bidx == G.BATTLES.size() - 1:
		print("AUTOTEST -> ENDING"); Engine.time_scale = 1.0
		G.set_meta("autotest_ending", true); get_tree().change_scene_to_file("res://camp.tscn"); return
	get_tree().quit(0)


const WIND_SH := """shader_type spatial;
uniform vec3 col : source_color = vec3(0.4, 0.45, 0.18);
void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float k = clamp(VERTEX.y + 0.5, 0.0, 1.0);
	VERTEX.x += sin(TIME * 1.6 + wp.x * 0.8 + wp.z * 0.5) * 0.05 * k;
	VERTEX.z += sin(TIME * 1.3 + wp.z * 0.7) * 0.035 * k;
}
void fragment() { ALBEDO = col; ROUGHNESS = 1.0; }
"""
const GRASS_SH := """shader_type spatial;
render_mode cull_disabled;
uniform sampler2D tex : source_color, filter_nearest;
void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float k = 1.0 - UV.y;
	float w = sin(TIME * 2.2 + wp.x * 1.3 + wp.z * 0.9) * 0.6 + sin(TIME * 3.7 + wp.z * 2.0) * 0.25;
	VERTEX.x += w * 0.07 * k * k; VERTEX.z += w * 0.04 * k * k;
}
void fragment() {
	vec4 c = texture(tex, UV);
	if (c.a < 0.5) discard;
	ALBEDO = c.rgb * (0.95 + 0.45 * (1.0 - UV.y)); ROUGHNESS = 1.0;
}
"""
const BILL_SH := """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform sampler2D tex : source_color;
uniform vec2 grid = vec2(1.0, 1.0);
uniform int frame = 0;
uniform float alpha = 1.0;
void vertex() { float sx = length(MODEL_MATRIX[0].xyz); float sy = length(MODEL_MATRIX[1].xyz); MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sx, INV_VIEW_MATRIX[1] * sy, INV_VIEW_MATRIX[2], MODEL_MATRIX[3]); }
void fragment() {
	vec4 c = texture(tex, (vec2(float(frame), 0.0) + UV) / grid);
	ALBEDO = c.rgb; ALPHA = c.a * alpha;
}
"""

func build_grass(rng: RandomNumberGenerator) -> void:
	var gm := shmat(GRASS_SH); gm.set_shader_parameter("tex", load("res://assets/v12/grass_tuft.png"))
	var qm := QuadMesh.new(); qm.size = Vector2(0.32, 0.26); qm.center_offset = Vector3(0, 0.13, 0); qm.subdivide_depth = 2
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.mesh = qm
	var xs: Array = []
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if c in ROCK_CELLS or c in water_cells or c in LAVA_CELLS: continue
			for n in 5:
				var p := cell_pos(c) + Vector3(rng.randf_range(-0.46, 0.46), 0.0, rng.randf_range(-0.46, 0.46))
				if abs(p.x - cell_pos(c).x) < 0.18 and abs(p.z - cell_pos(c).z) < 0.18: continue
				for k in 2:
					var t := Transform3D(Basis(Vector3.UP, rng.randf() * PI + k * PI * 0.5).scaled(Vector3.ONE * rng.randf_range(0.7, 1.25)), p)
					xs.append(t)
	mm.instance_count = xs.size()
	for i in xs.size(): mm.set_instance_transform(i, xs[i])
	var mmi := MultiMeshInstance3D.new(); mmi.multimesh = mm; mmi.material_override = gm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(mmi)

func build_sky_life() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 21
	var ctex: Texture2D = load("res://assets/v12/cloud.png")
	for i in 9:
		var m := shmat(BILL_SH); m.set_shader_parameter("tex", ctex); m.set_shader_parameter("alpha", 0.75)
		var n := Node3D.new(); add_child(n)
		var q := MeshInstance3D.new(); q.mesh = quad(1, 0.5); q.material_override = m; q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; n.add_child(q)
		var s := rng.randf_range(7.0, 12.0); q.scale = Vector3(s, s, 1)
		var ang := rng.randf() * TAU
		var rr := rng.randf_range(17.0, 26.0)
		n.position = Vector3(cos(ang) * rr, rng.randf_range(-5.0, -2.0) if i % 2 == 0 else rng.randf_range(6.0, 10.0), sin(ang) * rr)
		clouds.append(n)
	var btex: Texture2D = load("res://assets/v12/bird.png")
	for i in 5:
		var m := shmat(BILL_SH); m.set_shader_parameter("tex", btex); m.set_shader_parameter("grid", Vector2(2, 1))
		var n := Node3D.new(); add_child(n)
		var q := MeshInstance3D.new(); q.mesh = quad(0.5, 0.25); q.material_override = m; q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; n.add_child(q)
		birds.append({"n": n, "m": m, "r": rng.randf_range(7.0, 11.0), "y": rng.randf_range(4.5, 6.5), "sp": rng.randf_range(0.18, 0.3) * (1 if i % 2 == 0 else -1), "ph": rng.randf() * TAU})
	# 落葉
	if TH.fx != "leaf": return
	var lp := GPUParticles3D.new(); lp.amount = 26; lp.lifetime = 7.0; lp.preprocess = 7.0
	var pm := ParticleProcessMaterial.new(); pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX; pm.emission_box_extents = Vector3(8, 0.5, 6)
	pm.gravity = Vector3(0.25, -0.35, 0.1); pm.initial_velocity_min = 0.1; pm.initial_velocity_max = 0.3; pm.spread = 180
	pm.angular_velocity_min = -180; pm.angular_velocity_max = 180; pm.angle_min = 0; pm.angle_max = 360
	pm.turbulence_enabled = true; pm.turbulence_noise_strength = 0.6; pm.turbulence_noise_scale = 3.0
	lp.process_material = pm
	var lq := quad(0.12, 0.12)
	var lm := StandardMaterial3D.new(); lm.albedo_texture = load("res://assets/v12/leaf.png"); lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	lm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES; lm.cull_mode = BaseMaterial3D.CULL_DISABLED; lq.material = lm
	lp.draw_pass_1 = lq; lp.position = Vector3(0, 4.0, 0); add_child(lp)

func build_weather() -> void:
	var fxk: String = TH.fx
	if fxk == "leaf" or fxk == "dust": return
	var p := GPUParticles3D.new(); var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	var q: QuadMesh
	match fxk:
		"snow":
			p.amount = 420; p.lifetime = 7.0; p.preprocess = 7.0
			pm.emission_box_extents = Vector3(13, 0.5, 11); pm.gravity = Vector3(0.25, -1.1, 0.1)
			pm.initial_velocity_min = 0.0; pm.initial_velocity_max = 0.2
			pm.turbulence_enabled = true; pm.turbulence_noise_strength = 0.4; pm.turbulence_noise_scale = 4.0
			pm.scale_min = 0.6; pm.scale_max = 1.2
			q = quad(0.07, 0.07); q.material = particle_mat("glow.png", Color(1, 1, 1, 0.9))
			p.position = Vector3(0, 7.5, 0)
		"ember":
			p.amount = 140; p.lifetime = 5.0; p.preprocess = 5.0
			pm.emission_box_extents = Vector3(10, 0.5, 8); pm.gravity = Vector3(0.1, 0.7, 0.05)
			pm.initial_velocity_min = 0.1; pm.initial_velocity_max = 0.4; pm.spread = 40; pm.direction = Vector3.UP
			pm.turbulence_enabled = true; pm.turbulence_noise_strength = 0.8; pm.turbulence_noise_scale = 3.0
			pm.scale_min = 0.4; pm.scale_max = 1.0
			var g := Gradient.new(); g.set_color(0, Color(1, 0.75, 0.3, 1)); g.set_color(1, Color(1, 0.2, 0.05, 0)); var gt := GradientTexture1D.new(); gt.gradient = g; pm.color_ramp = gt
			q = quad(0.08, 0.08); q.material = particle_mat("glow.png", Color.WHITE)
			p.position = Vector3(0, -0.5, 0)
		_:
			p.amount = 45; p.lifetime = 6.0; p.preprocess = 6.0
			pm.emission_box_extents = Vector3(7, 1.2, 6); pm.gravity = Vector3.ZERO
			pm.initial_velocity_min = 0.05; pm.initial_velocity_max = 0.25; pm.spread = 180
			pm.turbulence_enabled = true; pm.turbulence_noise_strength = 1.2; pm.turbulence_noise_scale = 2.0
			var g2 := Gradient.new(); g2.set_color(0, Color(0.8, 1, 0.4, 0)); g2.add_point(0.3, Color(0.85, 1, 0.45, 1)); g2.set_color(g2.get_point_count() - 1, Color(0.7, 1, 0.3, 0)); var gt2 := GradientTexture1D.new(); gt2.gradient = g2; pm.color_ramp = gt2
			q = quad(0.07, 0.07); q.material = particle_mat("glow.png", Color.WHITE)
			p.position = Vector3(0, 1.6, 0)
	p.process_material = pm; p.draw_pass_1 = q; add_child(p)

# ---------------- v12：合併地形網格（共用邊、無縫） ----------------
func tquad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, ty: float) -> void:
	for v in [a, b, c, a, c, d]:
		st.set_normal(n); st.set_uv(Vector2(v.x, v.z)); st.set_uv2(Vector2(maxf(ty - v.y, 0.0), 0.0)); st.add_vertex(v)

func build_terrain(tm: Material, rm: Material, km: Material) -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 33
	var GG := {}
	for y in range(-1, H + 1):
		for x in range(-1, W + 1):
			var c := Vector2i(x, y)
			if inside(c): GG[c] = heights[c] * STEP
			else:
				var cc := Vector2i(clampi(x, 0, W - 1), clampi(y, 0, H - 1))
				GG[c] = heights[cc] * STEP - snappedf(rng.randf_range(0.3, 0.8), 0.05)
				outer_top[c] = GG[c]
	var sts := {}
	for k in ["ter", "road", "rock"]:
		var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES); sts[k] = st
	var BOT := -2.7
	for c in GG:
		var t: float = GG[c]
		var x0: float = c.x - W / 2.0; var z0: float = c.y - H / 2.0
		var k := "ter"
		if inside(c):
			var h: int = heights[c]
			if road_cells.has(c): k = "road"
			elif h >= 3: k = "rock"
		elif rng.randf() < 0.4: k = "rock"
		var st: SurfaceTool = sts[k]
		tquad(st, Vector3(x0, t, z0), Vector3(x0 + 1, t, z0), Vector3(x0 + 1, t, z0 + 1), Vector3(x0, t, z0 + 1), Vector3.UP, t)
		for d in DIRS:
			var nb: Vector2i = c + d
			var nt: float = GG[nb] if GG.has(nb) else BOT
			if nt >= t - 0.001: continue
			var sw: SurfaceTool = sts["ter"]
			if d == Vector2i(1, 0): tquad(sw, Vector3(x0 + 1, t, z0), Vector3(x0 + 1, t, z0 + 1), Vector3(x0 + 1, nt, z0 + 1), Vector3(x0 + 1, nt, z0), Vector3.RIGHT, t)
			elif d == Vector2i(-1, 0): tquad(sw, Vector3(x0, t, z0 + 1), Vector3(x0, t, z0), Vector3(x0, nt, z0), Vector3(x0, nt, z0 + 1), Vector3.LEFT, t)
			elif d == Vector2i(0, 1): tquad(sw, Vector3(x0 + 1, t, z0 + 1), Vector3(x0, t, z0 + 1), Vector3(x0, nt, z0 + 1), Vector3(x0 + 1, nt, z0 + 1), Vector3.BACK, t)
			else: tquad(sw, Vector3(x0, t, z0), Vector3(x0 + 1, t, z0), Vector3(x0 + 1, nt, z0), Vector3(x0, nt, z0), Vector3.FORWARD, t)
	var mt := {"ter": tm, "road": rm, "rock": km}
	for k in sts:
		var m: ArrayMesh = sts[k].commit()
		mi(self, m, Vector3.ZERO, mt[k])
	# 島緣底部：倒垂鐘乳岩，接住外牆下緣
	var rockm: Material = km
	for c in GG:
		if inside(c): continue
		for n in 2:
			var r := rng.randf_range(0.35, 0.65); var hh := rng.randf_range(1.2, 3.2)
			var pos := Vector3(c.x - W / 2.0 + 0.5 + rng.randf_range(-0.3, 0.3), BOT + 0.25 - hh / 2.0, c.y - H / 2.0 + 0.5 + rng.randf_range(-0.3, 0.3))
			mi(self, lowpoly(cyl(r, 0.04, hh, 5), rng, r * 0.2), pos, rockm, Vector3(0, rng.randf() * TAU, 0))
	var slab := lowpoly(box(Vector3(W + 2.2, 0.8, H + 2.2)), rng, 0.15)
	mi(self, slab, Vector3(0, BOT - 0.15, 0), rockm)

const WATER_SH := """shader_type spatial;
render_mode cull_disabled, depth_draw_always;
uniform sampler2D nz : filter_linear_mipmap, repeat_enable;
uniform float fall = 0.0;
uniform float lava = 0.0;
void fragment() {
	vec2 uv = UV * vec2(1.0, 1.0);
	vec2 sp = fall > 0.5 ? vec2(0.0, -TIME * 0.9) : vec2(TIME * 0.03, TIME * 0.02);
	float a = texture(nz, uv * 0.6 + sp).r; float b = texture(nz, uv * 1.1 - sp * 0.7 + vec2(0.3)).r;
	vec3 n = normalize(vec3((a - 0.5) * 1.6, 1.0, (b - 0.5) * 1.6));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 deep = vec3(0.05, 0.16, 0.24); vec3 sky = vec3(0.45, 0.55, 0.62);
	vec3 c = mix(deep, sky, 0.06 + fr * 0.4);
	float foam = smoothstep(0.62, 0.72, a * 0.6 + b * 0.5) * (fall > 0.5 ? 0.8 : 0.18);
	ALBEDO = c + foam;
	ROUGHNESS = 0.18; METALLIC = 0.0; SPECULAR = 0.35;
	ALPHA = fall > 0.5 ? 0.78 : 0.82;
	if (lava > 0.5) {
		float l = a * 0.6 + b * 0.5;
		vec3 lc = mix(vec3(0.55, 0.06, 0.0), vec3(1.0, 0.62, 0.12), smoothstep(0.45, 0.8, l));
		ALBEDO = lc * 0.25; EMISSION = lc * 2.2; ROUGHNESS = 0.85; SPECULAR = 0.1; ALPHA = 1.0;
	}
}
"""
const FLOWER_SH := """shader_type spatial;
render_mode cull_disabled;
varying vec3 ic;
void vertex() { ic = COLOR.rgb; vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; float k = clamp(VERTEX.y * 4.0, 0.0, 1.0); VERTEX.x += sin(TIME * 2.0 + wp.x + wp.z) * 0.02 * k; }
void fragment() { ALBEDO = ic; ROUGHNESS = 1.0; }
"""
const TORN_SH := """shader_type spatial;
render_mode cull_disabled;
uniform vec3 cloth : source_color = vec3(0.45, 0.07, 0.06);
uniform sampler2D nz : filter_linear_mipmap, repeat_enable;
void vertex() { float k = UV.x; VERTEX.z += sin(TIME * 2.6 + UV.x * 7.0 + UV.y * 2.0) * 0.1 * k; VERTEX.y += sin(TIME * 1.9 + UV.x * 5.0) * 0.03 * k; }
void fragment() {
	float r = texture(nz, vec2(UV.y * 0.8, 0.13)).r;
	if (UV.x > 0.62 + r * 0.45) discard;
	float h = texture(nz, UV * vec2(1.3, 1.1) + vec2(0.5)).r;
	if (h > 0.71 && UV.x > 0.25) discard;
	float burn = smoothstep(0.5, 0.7, h) + smoothstep(0.5 + r * 0.45, 0.62 + r * 0.45, UV.x);
	ALBEDO = mix(cloth, vec3(0.08, 0.05, 0.04), clamp(burn, 0.0, 1.0) * 0.8) * (0.85 + 0.15 * step(0.5, fract(UV.y * 6.0)));
	ROUGHNESS = 0.9; BACKLIGHT = cloth * 0.5;
}
"""

func flower_mesh() -> ArrayMesh:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var g := Color(0.25, 0.4, 0.12)
	for v in [Vector3(-0.008, 0, 0), Vector3(0.008, 0, 0), Vector3(0, 0.16, 0)]:
		st.set_color(g); st.set_normal(Vector3.FORWARD); st.add_vertex(v)
	for i in 5:
		var a := i * TAU / 5.0
		var c := Vector3(0, 0.16, 0)
		var p1 := c + Vector3(cos(a - 0.45), 0.02, sin(a - 0.45)) * 0.045
		var p2 := c + Vector3(cos(a + 0.45), 0.02, sin(a + 0.45)) * 0.045
		for v in [c, p1, p2]:
			st.set_color(Color.WHITE); st.set_normal(Vector3.UP); st.add_vertex(v)
	return st.commit()

func on_top(c: Vector2i, off: Vector2) -> Vector3:
	var p := cell_pos(c); return Vector3(p.x + off.x, p.y, p.z + off.y)

func build_details(rng: RandomNumberGenerator) -> void:
	var nzt: Texture2D = noise_tex
	# 花（MultiMesh，多色）
	var fm := shmat(FLOWER_SH)
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_colors = true; mm.mesh = flower_mesh()
	var cols := [Color(0.95, 0.85, 0.35), Color(0.92, 0.92, 0.95), Color(0.75, 0.45, 0.85), Color(0.95, 0.5, 0.35)]
	var fx: Array = []; var fc: Array = []
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if c in ROCK_CELLS or c in water_cells or heights[c] >= 3: continue
			if road_cells.has(c) or c in LAVA_CELLS: continue
			if rng.randf() > float(TH.flowers): continue
			var cc: Color = cols[rng.randi() % cols.size()]
			for n in rng.randi_range(2, 5):
				var o := Vector2(rng.randf_range(-0.45, 0.45), rng.randf_range(-0.45, 0.45))
				if o.length() < 0.22: continue
				fx.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.8, 1.3)), on_top(c, o))); fc.append(cc)
	mm.instance_count = fx.size()
	for i in fx.size(): mm.set_instance_transform(i, fx[i]); mm.set_instance_color(i, fc[i])
	var mmi := MultiMeshInstance3D.new(); mmi.multimesh = mm; mmi.material_override = fm; mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(mmi)
	# 道路踏石（嵌入地面）
	var stone := StandardMaterial3D.new(); stone.albedo_texture = load("res://assets/v12/t_cliff.png"); stone.uv1_triplanar = true; stone.uv1_scale = Vector3.ONE * 1.4
	stone.albedo_color = Color(1.0, 0.96, 0.88); stone.roughness = 0.9
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if not road_cells.has(c): continue
			for n in 3:
				var o := Vector2(rng.randf_range(-0.38, 0.38), rng.randf_range(-0.38, 0.38))
				var r := rng.randf_range(0.1, 0.17)
				mi(self, lowpoly(cyl(r, r * 1.08, 0.06, 7), rng, 0.012), on_top(c, o) + Vector3(0, 0.0, 0), stone, Vector3(0, rng.randf() * TAU, 0), Vector3(1, 1, rng.randf_range(0.7, 1.0)))
	# 木柵欄（島北緣與西緣外圈岩棚上）
	var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.42, 0.29, 0.18); wood.roughness = 1.0
	var fence_cells := [Vector2i(-1, 2), Vector2i(-1, 3), Vector2i(-1, 4), Vector2i(2, -1), Vector2i(3, -1), Vector2i(4, -1), Vector2i(W, 4), Vector2i(W, 5), Vector2i(W, 6)]
	for fcl in fence_cells:
		var t: float = outer_top[fcl]
		var bx: float = fcl.x - W / 2.0 + 0.5; var bz: float = fcl.y - H / 2.0 + 0.5
		var along_z: bool = fcl.x < 0 or fcl.x >= W
		for i in 2:
			var o := -0.25 + i * 0.5
			var pp := Vector3(bx + (0.0 if along_z else o), t, bz + (o if along_z else 0.0))
			mi(self, cyl(0.035, 0.045, 0.62, 5), pp + Vector3(0, 0.27, 0), wood, Vector3(rng.randf_range(-0.08, 0.08), 0, rng.randf_range(-0.08, 0.08)))
		for rh in [0.2, 0.42]:
			var broken := rng.randf() < 0.25
			var ln := 0.55 if broken else 1.02
			mi(self, box(Vector3(0.04, 0.06, ln) if along_z else Vector3(ln, 0.06, 0.04)), Vector3(bx, t + rh, bz), wood, Vector3(0, 0, rng.randf_range(-0.05, 0.05) if not broken else 0.2))
	# 殘破軍旗（外圈岩棚）
	var pole := StandardMaterial3D.new(); pole.albedo_color = Color(0.3, 0.22, 0.16)
	for fp in [Vector2i(W, 2), Vector2i(-1, 7)]:
		var t: float = outer_top[fp]
		var bp := Vector3(fp.x - W / 2.0 + 0.5, t, fp.y - H / 2.0 + 0.5)
		mi(self, cyl(0.03, 0.04, 2.2, 6), bp + Vector3(0, 1.05, 0), pole, Vector3(0.12, 0, -0.1))
		var tq := quad(0.9, 0.7); tq.subdivide_width = 12; tq.subdivide_depth = 6
		var tf := shmat(TORN_SH); tf.set_shader_parameter("nz", nzt)
		mi(self, tq, bp + Vector3(0.47, 1.75, 0), tf, Vector3(0.12, 0, -0.1))
	# 遺跡：斷柱與殘牆（外圈岩棚）
	var ruin := StandardMaterial3D.new(); ruin.albedo_texture = load("res://assets/v12/t_cliff.png"); ruin.uv1_triplanar = true; ruin.uv1_scale = Vector3.ONE * 0.9; ruin.albedo_color = Color(1.05, 1.0, 0.9)
	for rp in [Vector2i(-1, -1), Vector2i(8, -1), Vector2i(W, H - 1), Vector2i(1, H)]:
		var t: float = outer_top[rp]
		var bp := Vector3(rp.x - W / 2.0 + 0.5, t, rp.y - H / 2.0 + 0.5)
		var hh := rng.randf_range(0.7, 1.5)
		mi(self, lowpoly(cyl(0.2, 0.23, hh, 8), rng, 0.03), bp + Vector3(0, hh / 2.0, 0), ruin)
		mi(self, box(Vector3(0.6, 0.16, 0.6)), bp + Vector3(0, 0.08, 0), ruin)
		mi(self, lowpoly(box(Vector3(0.7, 0.35, 0.22)), rng, 0.05), bp + Vector3(0.3, 0.17, 0.35), ruin, Vector3(0, 0.6, 0.0))
	for i in 3:
		var wc: Vector2i = [Vector2i(5, -1), Vector2i(W, 7), Vector2i(-1, 0)][i]
		var t: float = outer_top[wc]
		var bp := Vector3(wc.x - W / 2.0 + 0.5, t, wc.y - H / 2.0 + 0.5)
		for b in 4:
			var bh := 0.2 + rng.randf() * 0.25 * (3 - absf(b - 1.5))
			mi(self, box(Vector3(0.24, bh, 0.24)), bp + Vector3(-0.36 + b * 0.24, bh / 2.0, 0), ruin, Vector3(0, rng.randf_range(-0.05, 0.05), 0))
	# 青苔小石
	var moss := StandardMaterial3D.new(); moss.albedo_color = Color(0.32, 0.38, 0.15); moss.roughness = 1.0
	for i in 26:
		var c := Vector2i(rng.randi_range(0, W - 1), rng.randi_range(0, H - 1))
		if c in water_cells or c in LAVA_CELLS: continue
		var o := Vector2(rng.randf_range(-0.47, 0.47), rng.randf_range(-0.47, 0.47))
		if absf(o.x) < 0.3 and absf(o.y) < 0.3: continue
		var r := rng.randf_range(0.05, 0.1)
		mi(self, lowpoly(sph(r, 6), rng, r * 0.2), on_top(c, o) + Vector3(0, r * 0.2, 0), moss if rng.randf() < 0.5 else stone, Vector3.ZERO, Vector3(1, 0.6, 1))
	# 水窪＋流向島緣的瀑布
	var wm := shmat(WATER_SH); wm.set_shader_parameter("nz", nzt)
	wm.render_priority = 1
	for c in water_cells:
		var q := PlaneMesh.new(); q.size = Vector2(1.0, 1.0)
		mi(self, q, cell_pos(c) + Vector3(0, 0.025, 0), wm)
	if not LAVA_CELLS.is_empty():
		var lm := shmat(WATER_SH); lm.set_shader_parameter("nz", nzt); lm.set_shader_parameter("lava", 1.0)
		for c in LAVA_CELLS:
			var q := PlaneMesh.new(); q.size = Vector2(1.0, 1.0)
			mi(self, q, cell_pos(c) + Vector3(0, 0.03, 0), lm)
			if rng.randf() < 0.4:
				var lt := OmniLight3D.new(); lt.light_color = Color(1, 0.4, 0.1); lt.light_energy = 1.2; lt.omni_range = 2.2; lt.position = cell_pos(c) + Vector3(0, 0.5, 0); add_child(lt)
				fire_particles(cell_pos(c) + Vector3(0, 0.1, 0), 6, 0.4, 0.5)
	if fall_cell.x >= 0:
		var wf := shmat(WATER_SH); wf.set_shader_parameter("nz", nzt); wf.set_shader_parameter("fall", 1.0)
		var wb := cell_pos(fall_cell)
		var rt: float = outer_top[Vector2i(fall_cell.x, H)]
		var f1 := QuadMesh.new(); f1.size = Vector2(0.7, maxf(0.05, wb.y - rt))
		mi(self, f1, Vector3(wb.x, (wb.y + rt) / 2.0, H / 2.0 + 0.03), wf)
		var pq := PlaneMesh.new(); pq.size = Vector2(0.8, 1.0)
		mi(self, pq, Vector3(wb.x, rt + 0.025, H / 2.0 + 0.5), wm)
		var f2 := QuadMesh.new(); f2.size = Vector2(0.75, rt + 2.7 + 1.5)
		mi(self, f2, Vector3(wb.x, (rt - 4.2) / 2.0, H / 2.0 + 1.03), wf)
		var mist := fire_particles(Vector3(wb.x, -3.6, H / 2.0 + 1.2), 20, 0.3, 1.2)
		(mist.process_material as ParticleProcessMaterial).gravity = Vector3(0, -0.6, 0.2)
		var mg := Gradient.new(); mg.set_color(0, Color(0.9, 0.95, 1.0, 0.5)); mg.set_color(1, Color(0.9, 0.95, 1.0, 0.0))
		var mgt := GradientTexture1D.new(); mgt.gradient = mg; (mist.process_material as ParticleProcessMaterial).color_ramp = mgt
	water_mats.append(wm)
	build_mountains(rng)

func ground_y(p: Vector2) -> float:
	var c := Vector2i(floori(p.x + W / 2.0), floori(p.y + H / 2.0))
	if inside(c): return heights[c] * STEP
	if outer_top.has(c): return outer_top[c]
	return -0.6

func idle_anim(_u) -> String: return "Idle"
func attack_anim(_u) -> String: return "Attack"

# ---------------- v14 場景主題：樹種／道具／遠山 ----------------
func build_tree(style: String, p: Vector3, s: float, rng: RandomNumberGenerator, trunk: Material, leaf: Material, leaf2: Material) -> void:
	match style:
		"round":
			mi(self, lowpoly(cyl(0.08, 0.13, 1.0, 5), rng, 0.02), p + Vector3(0, 0.5 * s, 0), trunk, Vector3.ZERO, Vector3.ONE * s)
			mi(self, lowpoly(sph(0.55, 7), rng, 0.1), p + Vector3(0, 1.25 * s, 0), leaf, Vector3(0, rng.randf() * TAU, 0), Vector3(1.0, 0.85, 1.0) * s)
			mi(self, lowpoly(sph(0.36, 6), rng, 0.06), p + Vector3(0.25, 1.55 * s, 0.1), leaf2, Vector3.ZERO, Vector3.ONE * s)
		"cactus":
			var cm := StandardMaterial3D.new(); cm.albedo_color = Color(0.28, 0.48, 0.22); cm.roughness = 0.9
			var h := rng.randf_range(0.9, 1.5) * s
			mi(self, lowpoly(cyl(0.11, 0.13, h, 7), rng, 0.01), p + Vector3(0, h / 2.0, 0), cm)
			mi(self, sph(0.11, 7), p + Vector3(0, h, 0), cm)
			for side in [-1.0, 1.0]:
				if rng.randf() < 0.75:
					var ay := h * rng.randf_range(0.35, 0.6)
					mi(self, cyl(0.07, 0.07, 0.24, 6), p + Vector3(side * 0.16, ay, 0), cm, Vector3(0, 0, PI / 2))
					var ah := rng.randf_range(0.25, 0.45)
					mi(self, cyl(0.07, 0.07, ah, 6), p + Vector3(side * 0.27, ay + ah / 2.0, 0), cm)
					mi(self, sph(0.07, 6), p + Vector3(side * 0.27, ay + ah, 0), cm)
		"palm":
			var h2 := 1.8 * s
			mi(self, lowpoly(cyl(0.05, 0.1, h2, 6), rng, 0.02), p + Vector3(0.1, h2 / 2.0, 0), trunk, Vector3(0, 0, -0.1))
			for k in 6:
				var a := k * TAU / 6.0
				mi(self, box(Vector3(0.9, 0.03, 0.22)), p + Vector3(0.2 + cos(a) * 0.4, h2 - 0.05, sin(a) * 0.4), leaf, Vector3(0, -a, -0.35))
		"dead":
			mi(self, lowpoly(cyl(0.04, 0.11, 1.4, 5), rng, 0.03), p + Vector3(0, 0.7 * s, 0), trunk, Vector3.ZERO, Vector3.ONE * s)
			for k in 3:
				var a := rng.randf() * TAU
				mi(self, cyl(0.015, 0.04, 0.6, 4), p + Vector3(cos(a) * 0.18, (0.9 + k * 0.18) * s, sin(a) * 0.18), trunk, Vector3(cos(a) * 0.9, 0, -sin(a) * 0.9))
		_:
			mi(self, lowpoly(cyl(0.07, 0.12, 1.0, 5), rng, 0.02), p + Vector3(0, 0.5 * s, 0), trunk, Vector3.ZERO, Vector3.ONE * s)
			for k in 3:
				mi(self, lowpoly(cyl(0.0, 0.66 - k * 0.15, 0.85, 7), rng, 0.08), p + Vector3(0, (0.95 + k * 0.42) * s, 0), leaf if k != 1 else leaf2, Vector3(0, rng.randf() * TAU, 0), Vector3.ONE * s)

func build_props(rng: RandomNumberGenerator, rockm: Material) -> void:
	if OS.get_environment("V14OFF").contains("props"): return
	var kind: String = TH.get("props", "")
	if kind == "": return
	if kind == "castle":
		var st := StandardMaterial3D.new(); st.albedo_texture = load("res://assets/v12/t_cobble.png"); st.uv1_triplanar = true; st.uv1_scale = Vector3.ONE * 0.5
		st.albedo_color = Color(0.6, 0.58, 0.58); st.roughness = 0.95
		var roof := StandardMaterial3D.new(); roof.albedo_color = Color(0.32, 0.14, 0.12); roof.roughness = 0.8
		var ban := shmat(SH.FLAG); ban.set_shader_parameter("cloth", Color(0.16, 0.22, 0.5))
		# 遠側（-x、-z）城牆＋垛口
		for t in range(-1, max(W, H) + 1):
			for c in [Vector2i(-1, t), Vector2i(t, -1)]:
				if not outer_top.has(c): continue
				var base: float = outer_top[c]
				var cp := Vector3(c.x - W / 2.0 + 0.5, base, c.y - H / 2.0 + 0.5)
				mi(self, box(Vector3(1.0, 1.1, 1.0)), cp + Vector3(0, 0.5, 0), st)
				for k in 2:
					var off := Vector3(0.25 if c.x == -1 else -0.25 + k * 0.5, 1.2, -0.25 + k * 0.5 if c.x == -1 else 0.25)
					mi(self, box(Vector3(0.32, 0.25, 0.32)), cp + off, st)
		# 角塔
		for c in [Vector2i(-1, -1), Vector2i(-1, H), Vector2i(W, -1)]:
			if not outer_top.has(c): continue
			var b2: float = outer_top[c]
			var tp := Vector3(c.x - W / 2.0 + 0.5, b2, c.y - H / 2.0 + 0.5)
			mi(self, cyl(0.75, 0.85, 3.0, 10), tp + Vector3(0, 1.5, 0), st)
			for k in 8:
				var a := k * TAU / 8.0
				mi(self, box(Vector3(0.28, 0.3, 0.28)), tp + Vector3(cos(a) * 0.72, 3.12, sin(a) * 0.72), st, Vector3(0, -a, 0))
			mi(self, cyl(0.0, 0.95, 1.4, 10), tp + Vector3(0, 3.95, 0), roof)
			var fq := quad(0.6, 0.4); fq.subdivide_width = 8
			mi(self, cyl(0.02, 0.02, 0.9, 5), tp + Vector3(0, 5.0, 0), roof)
			mi(self, fq, tp + Vector3(0.31, 5.25, 0), ban)
	elif kind == "desert":
		var ss := StandardMaterial3D.new(); ss.albedo_texture = load("res://assets/v12/t_sandstone.png"); ss.uv1_triplanar = true; ss.uv1_scale = Vector3.ONE * 0.5; ss.roughness = 1.0
		var bone := StandardMaterial3D.new(); bone.albedo_color = Color(0.92, 0.88, 0.78)
		var cnt := 0
		var keys: Array = outer_top.keys(); keys.sort()
		for c in keys:
			if c.x != -1 and c.y != -1: continue
			if rng.randf() > 0.35: continue
			var b: float = outer_top[c]
			var pp := Vector3(c.x - W / 2.0 + 0.5, b, c.y - H / 2.0 + 0.5)
			if cnt % 3 == 2:
				# 斷柱
				var h := rng.randf_range(0.8, 2.2)
				mi(self, lowpoly(cyl(0.26, 0.3, h, 8), rng, 0.03), pp + Vector3(0, h / 2.0, 0), ss)
				mi(self, box(Vector3(0.7, 0.18, 0.7)), pp + Vector3(0, 0.09, 0), ss)
			else:
				# 風蝕岩柱（台地）
				var h2 := rng.randf_range(1.2, 2.8)
				mi(self, lowpoly(cyl(0.35, 0.5, h2, 6), rng, 0.08), pp + Vector3(0, h2 / 2.0, 0), ss, Vector3(0, rng.randf() * TAU, 0))
				mi(self, lowpoly(cyl(0.55, 0.38, 0.35, 6), rng, 0.06), pp + Vector3(0, h2 + 0.12, 0), ss)
			cnt += 1
		# 獸骨
		for k in 2:
			var c2: Vector2i = keys[rng.randi() % keys.size()]
			var b3: float = outer_top[c2]
			var bp := Vector3(c2.x - W / 2.0 + 0.5, b3 + 0.05, c2.y - H / 2.0 + 0.5)
			for r in 4:
				mi(self, cyl(0.025, 0.025, 0.5, 5), bp + Vector3(r * 0.13 - 0.2, 0.12, 0), bone, Vector3(0.4, 0, 0))

# 遠山：三層環狀山脊（頂點色漸層＋霧），島嶼浮在群山之上，預設鏡頭可見山脊輪廓
func build_mountains(rng: RandomNumberGenerator) -> void:
	if OS.has_environment("NOMTN") or OS.get_environment("V14OFF").contains("mtn"): return
	var mat := StandardMaterial3D.new(); mat.vertex_color_use_as_albedo = true; mat.roughness = 1.0; mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rings := [[46.0, -22.0, 9.0, 120], [72.0, -30.0, 13.0, 110], [108.0, -42.0, 20.0, 96]]
	for li in rings.size():
		var R: float = rings[li][0]; var top0: float = rings[li][1]; var amp: float = rings[li][2]; var n: int = rings[li][3]
		var base_y := top0 - amp * 2.6 - 20.0
		var c0: Color = TH.mtn.lerp(TH.fog, 0.18 + li * 0.22)
		var dark := c0 * 0.22; var lite := c0 * (0.5 + li * 0.08)
		var snowc := Color(0.72, 0.75, 0.8).lerp(c0, 0.15 + li * 0.15)
		var snow_line := top0 + amp * (0.55 if TH.snow > 0.0 else 0.8) if li > 0 or TH.snow > 0.0 else 9999.0
		var ph := rng.randf() * TAU
		var hs: Array = []
		for i in n + 1:
			var a := float(i % n) / float(n) * TAU
			var h := top0 + amp * (0.5 * sin(a * 3.0 + ph) + 0.3 * sin(a * 7.0 + ph * 2.0) + 0.2 * sin(a * 13.0 + 1.3))
			if i % 2 == 0: h += amp * rng.randf_range(0.2, 0.9)
			else: h -= amp * rng.randf_range(0.0, 0.4)
			hs.append(h)
		hs[n] = hs[0]
		var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var rows := []
		for i in n + 1:
			var a := float(i % n) / float(n) * TAU + PI / float(n) * 0.0
			var d := Vector3(cos(a), 0, sin(a))
			var h: float = hs[i]
			var span := h - base_y
			var jit := sin(a * 17.0 + li) * 1.2
			var pt := d * (R + jit) + Vector3(0, h, 0)
			var pm := d * (R - span * 0.32 + jit * 0.5) + Vector3(0, h - span * 0.38 + sin(a * 11.0) * 1.5, 0)
			var pb := d * (R - span * 0.75) + Vector3(0, base_y, 0)
			var pk := d * (R + 14.0) + Vector3(0, h - amp * 1.2, 0)
			rows.append([pb, pm, pt, pk, h])
		for i in n:
			var A: Array = rows[i]; var B: Array = rows[i + 1]
			for r in 3:
				var a0: Vector3 = A[r]; var a1: Vector3 = A[r + 1]; var b0: Vector3 = B[r]; var b1: Vector3 = B[r + 1]
				var ca := func(v: Vector3) -> Color:
					var t := clampf((v.y - base_y) / maxf(1.0, (top0 + amp) - base_y), 0.0, 1.0)
					var c := dark.lerp(lite, t)
					if v.y > snow_line: c = snowc
					return c
				for tri in [[a0, b0, a1], [a1, b0, b1]]:
					var cen: Vector3 = (tri[0] + tri[1] + tri[2]) / 3.0
					var cc: Color = ca.call(cen) * (0.92 + 0.16 * rng.randf())
					for v in tri:
						st.set_color(cc); st.add_vertex(v)
		st.generate_normals()
		var m := st.commit()
		var node := mi(self, m, Vector3.ZERO, mat)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

# ---------------- v14 精緻打擊／魔法特效 ----------------
func fx_billboard(tex: String, pos: Vector3, col: Color, size: float) -> MeshInstance3D:
	var m := MeshInstance3D.new(); m.mesh = quad(size, size)
	var mt := particle_mat(tex, col); mt.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; mt.vertex_color_use_as_albedo = false
	m.material_override = mt; m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m); m.position = pos
	return m

func streaks(pos: Vector3, col: Color, amount: int, speed: float, life := 0.35) -> void:
	var p := GPUParticles3D.new(); p.amount = amount; p.lifetime = life; p.one_shot = true; p.explosiveness = 1.0
	var pm := ParticleProcessMaterial.new(); pm.spread = 180; pm.initial_velocity_min = speed * 0.5; pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, -3, 0); pm.damping_min = 4.0; pm.damping_max = 8.0; pm.particle_flag_align_y = true
	var sc := Curve.new(); sc.add_point(Vector2(0, 1)); sc.add_point(Vector2(1, 0)); var ct := CurveTexture.new(); ct.curve = sc; pm.scale_curve = ct
	var g := Gradient.new(); g.set_color(0, Color(1, 1, 0.95, 1)); g.set_color(1, Color(col.r, col.g, col.b, 0)); var gt := GradientTexture1D.new(); gt.gradient = g; pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(0.035, 0.42)
	var mt := particle_mat("streak.png", Color.WHITE); mt.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED; mt.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = mt; p.draw_pass_1 = q; p.transform_align = GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD_Y_TO_VELOCITY
	p.position = pos; add_child(p); p.emitting = true
	get_tree().create_timer(life + 1.0, true, false, true).timeout.connect(p.queue_free)

func shock_ring(pos: Vector3, col: Color, r1: float, dur := 0.32) -> void:
	var m := fx_billboard("ring.png", pos, col, 1.0)
	m.scale = Vector3.ONE * 0.15
	var mt: StandardMaterial3D = m.material_override
	var tw := create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3.ONE * r1, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mt, "albedo_color:a", 0.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(m.queue_free)

func ground_ring(pos: Vector3, col: Color, r1: float, dur := 0.45) -> void:
	var m := MeshInstance3D.new(); var pq := PlaneMesh.new(); pq.size = Vector2(2, 2); m.mesh = pq
	var mt := particle_mat("ring.png", col); mt.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED; mt.vertex_color_use_as_albedo = false
	m.material_override = mt; m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m); m.position = pos + Vector3(0, 0.05, 0); m.scale = Vector3.ONE * 0.1
	var tw := create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3.ONE * r1, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(mt, "albedo_color:a", 0.0, dur)
	tw.chain().tween_callback(m.queue_free)

func flash_light(pos: Vector3, col: Color, e: float, dur := 0.25) -> void:
	var l := OmniLight3D.new(); l.light_color = col; l.light_energy = e; l.omni_range = 4.0; l.position = pos; add_child(l)
	var tw := create_tween(); tw.tween_property(l, "light_energy", 0.0, dur); tw.tween_callback(l.queue_free)

# 物理打擊：衝擊環＋流線火花＋星芒＋地面衝擊＋閃光
func toward_cam(pos: Vector3, d := 0.6) -> Vector3:
	var cam := get_viewport().get_camera_3d()
	if cam == null: return pos
	return pos + (cam.global_position - pos).normalized() * d

func impact_fx(pos0: Vector3, col: Color, heavy := false) -> void:
	var pos := toward_cam(pos0)
	shock_ring(pos, col, 1.6 if heavy else 1.0)
	streaks(pos, col, 34 if heavy else 18, 9.0 if heavy else 6.0)
	var s := fx_billboard("star.png", pos, Color(1, 0.97, 0.85, 1), 1.4 if heavy else 0.8)
	s.rotation.z = randf() * TAU
	var tw := create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector3.ONE * 1.6, 0.18); tw.tween_property(s.material_override, "albedo_color:a", 0.0, 0.2)
	tw.chain().tween_callback(s.queue_free)
	flash_light(pos, col, 6.0 if heavy else 3.0)
	screen_punch(pos, 1.0 if heavy else 0.5)
	if heavy:
		var gp := Vector3(pos0.x, pos0.y - 0.6, pos0.z)
		ground_ring(gp, col, 1.4)
		burst(gp + Vector3(0, 0.1, 0), Color(0.55, 0.48, 0.4, 0.7), 14, 2.5, "smoke.png", 0.5, 0.9, 0.3, 70.0)

# 魔法命中：地面符文環＋光柱＋螺旋星光
func magic_impact(pos: Vector3, col: Color) -> void:
	var gp := Vector3(pos.x, pos.y - 0.55, pos.z)
	var mc := magic_circle(gp + Vector3(0, 0.05, 0), 0.8, col)
	get_tree().create_timer(0.7, true, false, true).timeout.connect(mc.queue_free)
	ground_ring(gp, col, 1.2, 0.5)
	var beam := mi(self, cyl(0.28, 0.28, 3.0, 16), gp + Vector3(0, 1.5, 0), glow(col.lightened(0.3), 0.55, 4.0))
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(beam.material_override as StandardMaterial3D).blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	beam.scale = Vector3(0.2, 1, 0.2)
	var tw := create_tween()
	tw.tween_property(beam, "scale", Vector3(1.0, 1, 1.0), 0.12)
	tw.tween_property(beam, "scale", Vector3(0.05, 1.3, 0.05), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(beam.queue_free)
	var sp := burst(gp + Vector3(0, 0.2, 0), col.lightened(0.4), 30, 3.0, "star.png", 0.22, 0.9, -1.5, 25.0, Vector3.UP)
	(sp.process_material as ParticleProcessMaterial).orbit_velocity_min = 0.6; (sp.process_material as ParticleProcessMaterial).orbit_velocity_max = 1.0
	shock_ring(toward_cam(pos), col, 1.3, 0.4)
	streaks(toward_cam(pos), col.lightened(0.3), 16, 5.0)
	flash_light(pos, col, 5.0, 0.4)
	screen_punch(pos, 0.6)

# ================= v15：元素魔法・元素狀態・戰果統計・語音・BGM =================
const EL_NAME := {"fire": "火", "water": "水", "wind": "風", "earth": "地"}
const EL_COL := {"fire": Color(1.0, 0.45, 0.15), "water": Color(0.35, 0.7, 1.0), "wind": Color(0.45, 1.0, 0.6), "earth": Color(0.85, 0.65, 0.35)}
# 相剋：水→火→風→地→水（攻擊方剋制被攻擊方的屬性時 ×1.3，反之 ×0.8）
const EL_BEATS := {"water": "fire", "fire": "wind", "wind": "earth", "earth": "water"}
const JOB_EL := {"騎士": "earth", "狂戰士": "fire", "弩手": "wind", "召喚師": "fire", "暗黑騎士": "water", "僧侶": "water", "刺客": "wind", "巨像": "earth"}
# 狀態：key -> [名稱, 圖示, 顏色, 抵抗屬性]
const STAT_INFO := {"burn": ["灼燒", "st_burn", Color(1.0, 0.45, 0.1), "fire"], "slow": ["緩速", "st_slow", Color(0.4, 0.7, 1.0), "water"],
	"freeze": ["冰封", "st_freeze", Color(0.6, 0.9, 1.0), "water"], "root": ["束縛", "st_root", Color(0.55, 0.85, 0.3), "earth"],
	"poison": ["中毒", "st_poison", Color(0.6, 1.0, 0.3), "wind"], "haste": ["加速", "st_haste", Color(0.4, 1.0, 0.75), ""],
	"shield": ["岩盾", "st_shield", Color(1.0, 0.85, 0.45), ""], "stun": ["暈眩", "st_stun", Color(1.0, 1.0, 0.4), ""], "silence": ["沉默", "st_silence", Color(0.75, 0.6, 1.0), "wind"]}
# 法術：k=atk/heal/debuff/buff/cure ; aoe 為半徑 ; lv 為習得等級
const SPELLS := [
	{"n": "火球術", "el": "fire", "k": "atk", "pw": 1.0, "mp": 8, "rng": 4, "aoe": 0, "lv": 1, "st": "burn", "ch": 25},
	{"n": "烈焰陣", "el": "fire", "k": "atk", "pw": 1.15, "mp": 16, "rng": 4, "aoe": 1, "lv": 6, "st": "burn", "ch": 35},
	{"n": "獄炎爆", "el": "fire", "k": "atk", "pw": 1.6, "mp": 26, "rng": 5, "aoe": 1, "lv": 12, "st": "burn", "ch": 55},
	{"n": "冰矢術", "el": "water", "k": "atk", "pw": 1.0, "mp": 8, "rng": 4, "aoe": 0, "lv": 1, "st": "slow", "ch": 30},
	{"n": "激流術", "el": "water", "k": "atk", "pw": 1.15, "mp": 16, "rng": 4, "aoe": 1, "lv": 6, "st": "slow", "ch": 30},
	{"n": "冰封棺", "el": "water", "k": "atk", "pw": 1.5, "mp": 26, "rng": 5, "aoe": 0, "lv": 12, "st": "freeze", "ch": 45},
	{"n": "風刃術", "el": "wind", "k": "atk", "pw": 0.95, "mp": 7, "rng": 5, "aoe": 0, "lv": 1, "st": "", "ch": 0},
	{"n": "旋風術", "el": "wind", "k": "atk", "pw": 1.1, "mp": 15, "rng": 4, "aoe": 1, "lv": 6, "st": "", "ch": 0},
	{"n": "瘴氣風暴", "el": "wind", "k": "atk", "pw": 1.45, "mp": 26, "rng": 5, "aoe": 1, "lv": 12, "st": "poison", "ch": 55},
	{"n": "石礫術", "el": "earth", "k": "atk", "pw": 1.05, "mp": 8, "rng": 4, "aoe": 0, "lv": 1, "st": "", "ch": 0},
	{"n": "地裂術", "el": "earth", "k": "atk", "pw": 1.15, "mp": 16, "rng": 4, "aoe": 1, "lv": 6, "st": "root", "ch": 35},
	{"n": "隕岩崩", "el": "earth", "k": "atk", "pw": 1.6, "mp": 26, "rng": 5, "aoe": 1, "lv": 12, "st": "root", "ch": 45},
	{"n": "治癒之水", "el": "water", "k": "heal", "pw": 1.0, "mp": 8, "rng": 3, "aoe": 0, "lv": 1, "st": "", "ch": 0},
	{"n": "淨化術", "el": "water", "k": "cure", "pw": 0.0, "mp": 6, "rng": 3, "aoe": 0, "lv": 3, "st": "", "ch": 0},
	{"n": "遲緩術", "el": "water", "k": "debuff", "pw": 0.0, "mp": 8, "rng": 4, "aoe": 0, "lv": 2, "st": "slow", "ch": 85},
	{"n": "疾風術", "el": "wind", "k": "buff", "pw": 0.0, "mp": 10, "rng": 3, "aoe": 0, "lv": 4, "st": "haste", "ch": 100},
	{"n": "灼燒咒", "el": "fire", "k": "debuff", "pw": 0.0, "mp": 9, "rng": 4, "aoe": 0, "lv": 3, "st": "burn", "ch": 85},
	{"n": "岩盾術", "el": "earth", "k": "buff", "pw": 0.0, "mp": 10, "rng": 3, "aoe": 0, "lv": 3, "st": "shield", "ch": 100},
	{"n": "束縛根", "el": "earth", "k": "debuff", "pw": 0.0, "mp": 9, "rng": 4, "aoe": 0, "lv": 5, "st": "root", "ch": 80},
	# v16：晉升職業技能（cls=鍵_分支，t=所需階級，phys=以攻擊力計算）
	{"n": "聖光壁", "el": "earth", "k": "buff", "pw": 0.0, "mp": 8, "rng": 2, "aoe": 1, "lv": 1, "st": "shield", "ch": 100, "cls": "rain_a", "t": 1},
	{"n": "王道審光", "el": "fire", "k": "atk", "pw": 1.35, "mp": 14, "rng": 3, "aoe": 1, "lv": 1, "st": "burn", "ch": 30, "cls": "rain_a", "t": 2, "phys": true},
	{"n": "一閃", "el": "wind", "k": "atk", "pw": 1.4, "mp": 8, "rng": 1, "aoe": 0, "lv": 1, "st": "", "ch": 0, "cls": "rain_b", "t": 1, "phys": true},
	{"n": "黎明劍嵐", "el": "wind", "k": "atk", "pw": 1.3, "mp": 16, "rng": 2, "aoe": 1, "lv": 1, "st": "slow", "ch": 35, "cls": "rain_b", "t": 2, "phys": true},
	{"n": "穿心狙擊", "el": "wind", "k": "atk", "pw": 1.45, "mp": 9, "rng": 6, "aoe": 0, "lv": 1, "st": "", "ch": 0, "cls": "erin_a", "t": 1, "phys": true},
	{"n": "天穹流星", "el": "fire", "k": "atk", "pw": 1.3, "mp": 16, "rng": 6, "aoe": 1, "lv": 1, "st": "burn", "ch": 30, "cls": "erin_a", "t": 2, "phys": true},
	{"n": "纏藤箭", "el": "earth", "k": "atk", "pw": 1.0, "mp": 7, "rng": 5, "aoe": 0, "lv": 1, "st": "root", "ch": 60, "cls": "erin_b", "t": 1, "phys": true},
	{"n": "秋風箭雨", "el": "wind", "k": "atk", "pw": 1.15, "mp": 15, "rng": 5, "aoe": 1, "lv": 1, "st": "slow", "ch": 40, "cls": "erin_b", "t": 2, "phys": true},
	{"n": "粉碎重擊", "el": "earth", "k": "atk", "pw": 1.5, "mp": 8, "rng": 1, "aoe": 0, "lv": 1, "st": "stun", "ch": 30, "cls": "grey_a", "t": 1, "phys": true},
	{"n": "戰神旋斧", "el": "earth", "k": "atk", "pw": 1.3, "mp": 15, "rng": 1, "aoe": 1, "lv": 1, "st": "", "ch": 0, "cls": "grey_a", "t": 2, "phys": true},
	{"n": "鋼鐵意志", "el": "earth", "k": "buff", "pw": 0.0, "mp": 6, "rng": 0, "aoe": 1, "lv": 1, "st": "shield", "ch": 100, "cls": "grey_b", "t": 1},
	{"n": "要塞衝撞", "el": "earth", "k": "atk", "pw": 1.35, "mp": 12, "rng": 1, "aoe": 0, "lv": 1, "st": "stun", "ch": 50, "cls": "grey_b", "t": 2, "phys": true},
	{"n": "煉獄火柱", "el": "fire", "k": "atk", "pw": 1.35, "mp": 14, "rng": 5, "aoe": 0, "lv": 1, "st": "burn", "ch": 60, "cls": "mira_a", "t": 1},
	{"n": "焚天", "el": "fire", "k": "atk", "pw": 1.8, "mp": 30, "rng": 5, "aoe": 2, "lv": 1, "st": "burn", "ch": 50, "cls": "mira_a", "t": 2},
	{"n": "星辰祝福", "el": "wind", "k": "buff", "pw": 0.0, "mp": 12, "rng": 3, "aoe": 1, "lv": 1, "st": "haste", "ch": 100, "cls": "mira_b", "t": 1},
	{"n": "星界墜落", "el": "wind", "k": "atk", "pw": 1.55, "mp": 24, "rng": 6, "aoe": 1, "lv": 1, "st": "", "ch": 0, "cls": "mira_b", "t": 2},
	{"n": "血之狂嚎", "el": "fire", "k": "buff", "pw": 0.0, "mp": 6, "rng": 0, "aoe": 0, "lv": 1, "st": "haste", "ch": 100, "cls": "vig_a", "t": 1},
	{"n": "血月裂斬", "el": "fire", "k": "atk", "pw": 1.55, "mp": 12, "rng": 1, "aoe": 0, "lv": 1, "st": "burn", "ch": 50, "cls": "vig_a", "t": 2, "phys": true},
	{"n": "群狼號令", "el": "wind", "k": "buff", "pw": 0.0, "mp": 10, "rng": 2, "aoe": 1, "lv": 1, "st": "haste", "ch": 100, "cls": "vig_b", "t": 1},
	{"n": "赤狼突襲", "el": "wind", "k": "atk", "pw": 1.3, "mp": 12, "rng": 2, "aoe": 1, "lv": 1, "st": "", "ch": 0, "cls": "vig_b", "t": 2, "phys": true},
	{"n": "深淵斬", "el": "fire", "k": "atk", "pw": 1.45, "mp": 9, "rng": 1, "aoe": 0, "lv": 1, "st": "poison", "ch": 40, "cls": "gard_a", "t": 1, "phys": true},
	{"n": "冥獄崩落", "el": "earth", "k": "atk", "pw": 1.4, "mp": 18, "rng": 3, "aoe": 1, "lv": 1, "st": "slow", "ch": 40, "cls": "gard_a", "t": 2, "phys": true},
	{"n": "月盾", "el": "water", "k": "buff", "pw": 0.0, "mp": 8, "rng": 2, "aoe": 0, "lv": 1, "st": "shield", "ch": 100, "cls": "gard_b", "t": 1},
	{"n": "月蝕結界", "el": "water", "k": "buff", "pw": 0.0, "mp": 16, "rng": 0, "aoe": 2, "lv": 1, "st": "shield", "ch": 100, "cls": "gard_b", "t": 2},
	{"n": "熾天之光", "el": "water", "k": "heal", "pw": 1.4, "mp": 12, "rng": 3, "aoe": 1, "lv": 1, "st": "", "ch": 0, "cls": "aurelia_a", "t": 1},
	{"n": "聖光審判", "el": "fire", "k": "atk", "pw": 1.6, "mp": 22, "rng": 5, "aoe": 1, "lv": 1, "st": "", "ch": 0, "cls": "aurelia_a", "t": 2},
	{"n": "神罰之鎚", "el": "earth", "k": "atk", "pw": 1.45, "mp": 9, "rng": 1, "aoe": 0, "lv": 1, "st": "stun", "ch": 35, "cls": "aurelia_b", "t": 1, "phys": true},
	{"n": "天秤裁決", "el": "fire", "k": "atk", "pw": 1.4, "mp": 18, "rng": 2, "aoe": 1, "lv": 1, "st": "", "ch": 0, "cls": "aurelia_b", "t": 2, "phys": true}]
const STAT_DUR := {"stun": 1, "burn": 3, "slow": 2, "freeze": 1, "root": 2, "poison": 3, "haste": 3, "shield": 3, "silence": 2}
var sel_spell := {}
var bstat := {}
var vo_players: Array = []
var bgm2: AudioStreamPlayer
var stc_cache := {}

func caster(u) -> bool: return u.job in ["召喚師", "僧侶"]
func uel(u) -> String: return u.get("el", JOB_EL.get(u.job, "earth"))
func spells_of(u) -> Array:
	var out := []
	var uc := ucls(u)
	for s in SPELLS:
		if s.has("cls"):
			if s.cls == uc and utier(u) >= int(s.t): out.append(s)
			continue
		if not caster(u): continue
		if u.lv < int(s.lv): continue
		if u.job == "僧侶" and s.k == "atk" and not (s.el in ["water", "wind"]): continue
		if u.job == "召喚師" and s.k in ["heal", "cure"]: continue
		if u.team == 1 and not u.boss and int(s.lv) >= 12: continue
		out.append(s)
	for s in SPELLS23:
		if spell23_ok(u, s):
			var dup := false
			for o in out:
				if o.n == s.n: dup = true
			if not dup: out.append(s)
	return out
func el_mult(sel: String, t) -> float:
	if EL_BEATS.get(sel, "") == uel(t): return 1.3
	if EL_BEATS.get(uel(t), "") == sel: return 0.8
	return 1.0
func spell_dmg(a, t, s) -> int:
	var b := (st(a, "atk" if s.get("phys", false) else "mag") * 0.85 * float(s.pw) + 5.0 - st(t, "def") * 0.35) * el_mult(s.el, t) * wx_el(s.el)
	if int(s.aoe) > 0: b *= 0.85
	if t.boss: b *= 0.85
	if a.team == 1: b *= 0.7 if a.boss else 0.65
	if wx_res(s): b *= 1.35
	return maxi(1, int(b))
func spell_cells(u, s) -> Array:
	var out := []
	for c in heights:
		if mdist(c, u.cell) <= srng(s): out.append(c)
	return out
func spell_area(c: Vector2i, s) -> Array:
	var out := []
	for k in heights:
		if mdist(k, c) <= int(s.aoe): out.append(k)
	return out

# ---- 統計 ----
func bs(u) -> Dictionary:
	if not bstat.has(u.name): bstat[u.name] = {"dealt": 0, "taken": 0, "heal": 0, "kills": 0, "team": u.team}
	return bstat[u.name]
func track_dmg(a, t, dmg: int) -> void:
	if a != null: bs(a).dealt += dmg; t.last_by = a.name
	bs(t).taken += dmg
	# v20：怒氣——攻擊 +20，被攻擊 +22＋依損血比例（最多 +36）
	if a != null and dmg > 0: add_rage(a, 20)
	if dmg > 0: add_rage(t, 22 + mini(36, int(dmg * 70.0 / maxf(1.0, st(t, "hp")))))
func track_heal(a, amt: int) -> void:
	if a != null: bs(a).heal += amt

# ---- 狀態 ----
func status_resist(u, k: String) -> bool:
	var info = STAT_INFO.get(k)
	if info == null or info[3] == "": return false
	if uel(u) == info[3] and u.team == 1 and (u.boss or u.lv >= 8): return true
	if u.boss and k in ["freeze", "root"] and u.phase > 0: return true
	return false
func apply_status(u, k: String, chance: int) -> bool:
	if u.team == 0 and chance < 100: chance = int(chance * 0.6)
	if not u.alive or randi() % 100 >= chance: return false
	if (k == "poison" or k == "stun") and immune(u, k): return false
	if status_resist(u, k):
		popup(u.node.position + Vector3(0, 0.7, 0), "抵抗", Color(0.85, 0.9, 1)); return false
	u.status[k] = int(STAT_DUR.get(k, 2)) + (0 if k != "freeze" else 0)
	popup(u.node.position + Vector3(0, 0.55, 0), STAT_INFO[k][0], STAT_INFO[k][2], true)
	log_msg("%s 陷入「%s」狀態（%d 回合）" % [u.name, STAT_INFO[k][0], u.status[k]])
	update_label(u); return true
func status_upkeep(u) -> bool:
	# 回傳 true：此單位本回合無法行動（冰封）或已倒下
	if u.status.has("burn"):
		var bd := maxi(3, int(st(u, "hp") * 0.07))
		u.hp = maxi(0, u.hp - bd); bs(u).taken += bd
		if u.has("last_by") == false: u.last_by = ""
		popup(u.node.position, "灼 %d" % bd, Color(1, 0.5, 0.15)); hit_flash(u, Color(1, 0.45, 0.1))
		log_msg("%s 受到灼燒傷害 %d" % [u.name, bd])
	for k in ["burn", "slow", "root", "haste", "shield", "silence"]:
		if u.status.has(k):
			u.status[k] -= 1
			if u.status[k] <= 0: u.status.erase(k)
	update_label(u)
	if u.hp <= 0: return true
	return false
func status_tint(u) -> Color:
	for k in ["freeze", "burn", "poison", "root", "slow", "haste", "shield", "silence"]:
		if u.status.has(k): var c: Color = STAT_INFO[k][2]; return Color(c.r, c.g, c.b, 0.55 if k == "freeze" else 0.38)
	return Color(0, 0, 0, 0)
func refresh_status_icons(u) -> void:
	if not u.has("sicons"):
		var n := Node3D.new(); n.position.y = 2.42 * float(u.get("scl", 1.0)); u.node.add_child(n); u.sicons = n
	for ch in u.sicons.get_children(): ch.queue_free()
	var ks := []
	for k in u.status:
		if STAT_INFO.has(k): ks.append(k)
	for i in ks.size():
		var k: String = ks[i]
		var sp := Sprite3D.new(); sp.texture = load("res://assets/v15/fx/%s.png" % STAT_INFO[k][1]); sp.pixel_size = 0.0055
		sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED; sp.no_depth_test = true; sp.render_priority = 3
		sp.position = Vector3((i - (ks.size() - 1) * 0.5) * 0.4, 0, 0); u.sicons.add_child(sp)
		var l := Label3D.new(); l.font = font_bold; l.text = str(u.status[k]); l.font_size = 30; l.pixel_size = 0.004 * G.font_k(); l.outline_size = 9
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.no_depth_test = true; l.render_priority = 4; l.outline_render_priority = 3
		l.position = Vector3(0.12, -0.1, 0); sp.add_child(l)
	if u.has("smat"): u.smat.set_shader_parameter("stc", status_tint(u))

# ---- 序列幀特效 ----
func flipbook(pos: Vector3, nm: String, size: float, dur: float, col := Color(1, 1, 1), ground := false) -> void:
	var m := shmat(FLIP_SH); m.set_shader_parameter("tex", load("res://assets/v15/fx/fx_%s.png" % nm)); m.set_shader_parameter("col", col)
	var q := MeshInstance3D.new(); var qm := QuadMesh.new(); qm.size = Vector2(size, size); q.mesh = qm; q.material_override = m
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(q); q.position = pos
	if ground: m.set_shader_parameter("flatm", 1.0)
	var tw := create_tween(); tw.tween_method(func(v): m.set_shader_parameter("frame", mini(7, int(v))), 0.0, 7.99, dur)
	tw.tween_callback(q.queue_free)
const FLIP_SH := """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;
uniform sampler2D tex : source_color, filter_linear;
uniform int frame = 0;
uniform vec4 col : source_color = vec4(1.0);
uniform float flatm = 0.0;
void vertex() {
	if (flatm < 0.5) { float sx = length(MODEL_MATRIX[0].xyz); MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sx, INV_VIEW_MATRIX[1] * sx, INV_VIEW_MATRIX[2], MODEL_MATRIX[3]); }
	else { MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, -1.0, 0.0, 0.0), MODEL_MATRIX[3]); }
}
void fragment() {
	vec4 c = texture(tex, vec2((float(frame) + clamp(UV.x, 0.02, 0.98)) / 8.0, UV.y));
	ALBEDO = c.rgb * col.rgb * 1.4; ALPHA = c.a * col.a;
}
"""

# ---- 魔法指令 ----
func cmd_magic() -> void:
	for ch in menu_box.get_children(): ch.queue_free()
	state = "magicmenu"
	for s in spells_of(cur):
		var b := Button.new(); b.custom_minimum_size = Vector2(300, 40)
		b.text = "%s〔%s〕 MP%d" % [s.n, EL_NAME[s.el], s.mp]
		b.icon = load("res://assets/v15/fx/el_%s.png" % s.el); b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 28)
		b.disabled = cur.mp < int(s.mp)
		var ss = s
		b.pressed.connect(func(): sfx("click", 0.05, -10.0); pick_spell(ss))
		menu_box.add_child(b)
	var bk := Button.new(); bk.text = "返回"; bk.custom_minimum_size = Vector2(300, 40); bk.pressed.connect(func(): state = "menu"; show_menu()); menu_box.add_child(bk)
	menu_panel.reset_size()

func pick_spell(s) -> void:
	sel_spell = s
	var col: Color = EL_COL[s.el]
	show_hl(spell_cells(cur, s), Color(col.r, col.g, col.b, 0.4)); state = "magic"; hide_menu()
	log_msg("「%s」：選擇目標（射程 %d%s）" % [s.n, srng(s), "，範圍 %d" % s.aoe if int(s.aoe) > 0 else ""])

func magic_hover(c: Vector2i, u) -> void:
	clear_aoe()
	var s := sel_spell; var col: Color = EL_COL[s.el]
	var txt := "▶ %s〔%s〕 MP%d" % [s.n, EL_NAME[s.el], s.mp]
	for a in spell_area(c, s): aoe_nodes.append(hl_quad(a, Color(col.r, col.g, col.b, 0.6)))
	if u != null and s.k == "atk" and u.team != cur.team:
		var m := el_mult(s.el, u)
		txt += "\n預估傷害 %d%s" % [spell_dmg(cur, u, s), "　弱點！" if m > 1.0 else ("　抗性" if m < 1.0 else "")]
	elif s.st != "": txt += "\n附加：%s（%d%%）" % [STAT_INFO[s.st][0], s.ch]
	tcard.panel.visible = true
	fill_card(tcard, u if u != null else cur, txt)

func magic_valid(u, s, c: Vector2i) -> bool:
	if not hl_cells.has(c): return false
	if s.k == "atk":
		for a in spell_area(c, s):
			var t = unit_at(a)
			if t != null and t.team != u.team: return true
		return false
	if s.k == "revive": return not revive_targets(u, s, c).is_empty()
	var t = unit_at(c)
	if t == null: return false
	if s.k == "debuff": return t.team != u.team
	return t.team == u.team

func do_magic(u, s, c: Vector2i) -> void:
	u.mp -= int(s.mp)
	var col: Color = EL_COL[s.el]
	face(u, cell_pos(c)); play(u, "Spellcasting", 0.1)
	voice(u, "spell", s.n)
	sfx("magic", 0.05, -5.0)
	flipbook(u.node.position + Vector3(0, 0.06, 0), "cast", 2.2, 0.9, col, true)
	flipbook(u.node.position + Vector3(0, 1.0, 0), "cast", 1.4, 0.9, col)
	skill_banner(s.n, col)
	log_msg("%s 詠唱「%s」" % [u.name, s.n])
	await wait(0.75)
	var fxn: String = s.el if s.k in ["atk", "debuff"] else ("heal" if s.k in ["heal", "cure"] else s.el)
	var kills := 0
	if s.k == "atk" and (int(s.lv) >= 13 or s.has("wx")): await hi_fx(u, s, c)
	if s.k == "revive":
		var rv := revive_targets(u, s, c)
		magic_circle(cell_pos(c) + Vector3(0, 0.05, 0), 1.0 + int(s.aoe) * 0.9, Color(1, 0.9, 0.55))
		sfx("heal", 0.0, -3.0); await wait(0.3)
		for o in rv: revive_unit(o, int(s.pw), s.n)
		if do_shots and not fx_shots.has("revive"): fx_shots["revive"] = true; await wait(0.3); await shot("23_revive_spell")
	elif s.k == "atk":
		var hit_any := false
		for a in spell_area(c, s):
			var t = unit_at(a)
			if t == null or t.team == u.team or not t.alive: continue
			hit_any = true
			flipbook(t.node.position + Vector3(0, 0.8 if s.el != "earth" else 0.55, 0), fxn, 2.0 if s.el != "earth" else 1.8, 0.7, Color(1, 1, 1))
		if hit_any: sfx("explode" if s.el in ["fire", "earth"] else "hit", 0.1, -6.0); shake = max(shake, 0.35)
		await wait(0.3)
		for a in spell_area(c, s):
			var t = unit_at(a)
			if t == null or t.team == u.team or not t.alive: continue
			var dmg := int(spell_dmg(u, t, s) * randf_range(0.93, 1.07))
			t.hp = maxi(0, t.hp - dmg); track_dmg(u, t, dmg)
			hit_flash(t, col); play(t, "Hit_B", 0.05); voice(t, "hurt", "")
			var m := el_mult(s.el, t)
			popup(t.node.position, str(dmg) + ("！" if m > 1.0 else ""), col.lightened(0.3), m > 1.0)
			if m > 1.0: popup(t.node.position + Vector3(0, 0.45, 0), "弱點", Color(1, 0.9, 0.3))
			log_msg("「%s」對 %s 造成 %d 傷害%s" % [s.n, t.name, dmg, "（弱點）" if m > 1.0 else ""])
			update_label(t)
			if t.hp <= 0:
				kill(t); kills += 1
			else:
				after_damage(t)
				if s.st != "": apply_status(t, s.st, int(s.ch))
				var tt = t
				get_tree().create_timer(0.7).timeout.connect(func(): if tt.alive: play(tt, idle_anim(tt), 0.3))
	else:
		for t in support_targets(u, s, c):
			flipbook(t.node.position + Vector3(0, 0.8, 0), fxn, 2.0, 0.8, col if s.k != "heal" else Color(1, 1, 1))
			sfx("heal", 0.05, -5.0)
			await wait(0.35 if int(s.aoe) == 0 else 0.12)
			match s.k:
				"heal":
					var amt := mini(int(st(u, "mag") * 1.6) + 20, st(t, "hp") - t.hp)
					t.hp += amt; track_heal(u, amt); popup(t.node.position, "+%d" % amt, Color(0.4, 1.0, 0.5), true)
					log_msg("%s 為 %s 回復 %d HP" % [u.name, t.name, amt])
				"cure":
					for k in ["burn", "slow", "freeze", "root", "poison", "stun", "silence"]: t.status.erase(k)
					popup(t.node.position, "淨化", Color(0.7, 1, 0.9), true)
				"buff":
					t.status[s.st] = int(STAT_DUR[s.st]); popup(t.node.position, STAT_INFO[s.st][0], STAT_INFO[s.st][2], true)
				"debuff":
					voice(t, "hurt", "")
					if not apply_status(t, s.st, int(s.ch)): popup(t.node.position, "MISS", Color(0.75, 0.85, 1.0))
			update_label(t)
	fill_card(card, u)
	await wait(0.6)
	skill_banner_end()
	play(u, idle_anim(u), 0.2)
	if u.team == 0 and u.alive: await grant_exp(u, 10 + kills * 22)

# 自動/敵方 AI：選最佳法術
func magic_plan(u, allow_move := true):
	var r := reachable(u) if allow_move and not u.status.has("root") else {"ends": [u.cell], "parent": {u.cell: u.cell}}
	var best = null; var bsc := 0.0
	if silenced(u): return null
	for s in spells_of(u):
		if u.mp < int(s.mp) or s.k in ["cure"]: continue
		if s.k == "revive":
			for o in downed_allies(u.team):
				if unit_at(o.cell) != null: continue
				for mc in r.ends:
					if mdist(o.cell, mc) <= srng(s):
						var sc0 := 80.0 + revive_targets(u, s, o.cell).size() * 30.0
						if sc0 > bsc: bsc = sc0; best = {"move": mc, "cell": o.cell, "spell": s, "parent": r.parent}
						break
			continue
		for mc in r.ends:
			for c in heights:
				if mdist(c, mc) > srng(s): continue
				var sc := 0.0
				if s.k == "atk":
					for a in spell_area(c, s):
						var t = unit_at(a)
						if t != null and t.alive and t.team != u.team:
							var dm := spell_dmg(u, t, s); sc += minf(dm, t.hp) + (40.0 if dm >= t.hp else 0.0)
						elif t != null and t.team == u.team and t != u: sc -= 5
					sc -= float(s.mp) * 0.4
				elif s.k == "heal":
					var t = unit_at(c)
					if t != null and t.team == u.team and t.hp * 100 < st(t, "hp") * 55: sc = float(st(t, "hp") - t.hp) * 0.9
				elif s.k == "debuff":
					var t = unit_at(c)
					if t != null and t.team != u.team and not t.status.has(s.st) and not status_resist(t, s.st): sc = 14.0 + (10.0 if t.boss else 0.0)
				elif s.k == "buff":
					var t = unit_at(c)
					if t != null and t.team == u.team and not t.status.has(s.st) and t != u: sc = 11.0
				if sc > bsc: bsc = sc; best = {"move": mc, "cell": c, "spell": s, "parent": r.parent}
	return best

# ---- 語音 ----
func voice(u, kind: String, txt: String) -> void:
	if G.voice_vol <= 0.01: return
	var key: String = u.get("key", u.get("model", ""))
	var vk: String = G.voice_of(key, u.team, u.get("boss", false))
	var path := ""
	if kind == "spell": path = "res://assets/v15/vo/%s_sp_%s.ogg" % [vk, G.spell_id(txt)]
	elif kind == "hurt": path = "res://assets/v15/vo/%s_hurt%d.ogg" % [vk, randi() % 2]
	elif kind == "cry": path = "res://assets/v15/vo/%s_cry%d.ogg" % [vk, randi() % 3]
	elif kind == "line": path = "res://assets/v15/vo/%s_%s.ogg" % [vk, txt]
	if not ResourceLoader.exists(path): return
	if vo_players.is_empty():
		for i in 4:
			var p := AudioStreamPlayer.new(); add_child(p); vo_players.append(p)
	for p in vo_players:
		if not p.playing:
			p.stream = load(path); p.volume_db = linear_to_db(G.voice_vol) - 1.0; p.play(); return

# ---- 交響 BGM（交叉淡入） ----
func bgm_play(key: String, fade := 1.5) -> void:
	var path := "res://assets/v15/bgm/%s.ogg" % key
	if not ResourceLoader.exists(path): return
	if bgm2 == null: bgm2 = AudioStreamPlayer.new(); add_child(bgm2)
	var old := bgm; var nw := bgm2; bgm = nw; bgm2 = old
	var s: AudioStreamOggVorbis = load(path); s.loop = key != "victory"
	nw.stream = s; nw.volume_db = -40.0; nw.pitch_scale = 1.0; nw.play()
	var tw := create_tween().set_parallel()
	tw.tween_property(nw, "volume_db", -10.0, fade)
	if old.playing: tw.tween_property(old, "volume_db", -45.0, fade)
	tw.chain().tween_callback(func(): if bgm2 != bgm: bgm2.stop())

# ---- 勝利揮手：整體跳躍（不再使用被裁切的施法格） ----
func victory_hop(u) -> void:
	if int(u.get("ncols", 24)) >= 28: u.sanim = {"n": "win", "t": 0.0, "sp": 1.0}
	var b: Node3D = u.body
	var y0: float = b.position.y
	var tw := create_tween().set_loops(3)
	tw.tween_property(b, "position:y", y0 + 0.28, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(b, "position:y", y0, 0.22).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_interval(0.12)

# ---- 戰果結算畫面 ----
func show_results(rec) -> void:
	var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_STOP; ui_root.add_child(root)
	var dim := ColorRect.new(); dim.color = Color(0.03, 0.02, 0.01, 0.62); dim.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(dim)
	var pan := NinePatchRect.new(); pan.texture = load("res://assets/v15/menu_frame.png")
	pan.patch_margin_left = 44; pan.patch_margin_right = 44; pan.patch_margin_top = 44; pan.patch_margin_bottom = 44
	pan.position = Vector2(230, 70); pan.size = Vector2(1140, 760); pan.set_meta("max_k", 1.2); root.add_child(pan)
	var parch := ColorRect.new(); parch.color = Color(0.86, 0.78, 0.6, 0.96); parch.position = Vector2(30, 30); parch.size = pan.size - Vector2(60, 60); pan.add_child(parch)
	parch.material = V15FX.mat(V15FX.PAINT)
	var rays := ColorRect.new(); rays.position = Vector2(270, -60); rays.size = Vector2(600, 300); rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rm := V15FX.mat(V15FX.RAYS); rm.set_shader_parameter("sun", Vector2(0.5, 0.55)); rm.set_shader_parameter("strength", 0.35); rays.material = rm; pan.add_child(rays)
	var tl := Label.new(); tl.text = "戰　果"; tl.add_theme_font_override("font", narr_font); tl.add_theme_font_size_override("font_size", 56); tl.set_meta("max_k", 1.0)
	tl.add_theme_color_override("font_color", Color(0.45, 0.22, 0.05)); tl.add_theme_color_override("font_outline_color", Color(1, 0.9, 0.6)); tl.add_theme_constant_override("outline_size", 6)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tl.position = Vector2(0, 40); tl.size = Vector2(1140, 70); pan.add_child(tl)
	var sub := Label.new(); sub.text = "第%d戰「%s」　回合數：我方 %d／敵方 %d　金幣 +%d G" % [bidx + 1, bdef.name, turns_p, turns_e, res.gold]
	sub.add_theme_font_override("font", narr_font); sub.add_theme_font_size_override("font_size", 24); sub.add_theme_color_override("font_color", Color(0.3, 0.18, 0.06))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; sub.position = Vector2(0, 112); sub.size = Vector2(1140, 34); pan.add_child(sub)
	var dv := TextureRect.new(); dv.texture = load("res://assets/v15/divider.png"); dv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; dv.position = Vector2(170, 148); dv.size = Vector2(800, 40); pan.add_child(dv)
	# MVP：擊殺×40 + 輸出 + 治療×1.2
	var mvp := ""; var mbest := -1.0
	var rows := []
	for u in units:
		if u.team != 0 or u.member == null: continue
		var s := bs(u)
		var score: float = s.kills * 40.0 + s.dealt + s.heal * 1.2
		if score > mbest: mbest = score; mvp = u.name
		rows.append(u)
	var hdr := ["角色", "輸出", "承受", "治療", "擊殺", "經驗值"]
	var xs := [70, 330, 450, 570, 690, 790]
	for i in hdr.size():
		var h := lbl(hdr[i], 22, Color(0.4, 0.2, 0.05), true); h.position = Vector2(xs[i], 190); pan.add_child(h)
	var y := 230.0
	var lvd: Array = []
	for u in rows:
		var s := bs(u)
		var row := Control.new(); row.position = Vector2(0, y); row.modulate.a = 0.0; pan.add_child(row)
		if rows.find(u) % 2 == 1:
			var zb := ColorRect.new(); zb.color = Color(0.45, 0.3, 0.12, 0.10); zb.position = Vector2(50, -4); zb.size = Vector2(1040, 46); zb.mouse_filter = Control.MOUSE_FILTER_IGNORE; row.add_child(zb)
		if u.get("portrait") != null:
			var fc := TextureRect.new(); fc.texture = u.portrait; fc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; fc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			fc.position = Vector2(20, -2); fc.size = Vector2(42, 42); fc.mouse_filter = Control.MOUSE_FILTER_IGNORE; row.add_child(fc)
		if u.name == mvp:
			var hl := ColorRect.new(); hl.color = Color(1.0, 0.8, 0.3, 0.35); hl.position = Vector2(50, -4); hl.size = Vector2(1040, 46); row.add_child(hl)
			var mv := lbl("★MVP", 20, Color(0.75, 0.3, 0.02), true); mv.position = Vector2(1000, 6); row.add_child(mv)
		var vals := [u.name + "  Lv%d" % u.lv, str(s.dealt), str(s.taken), str(s.heal), str(s.kills)]
		for i in vals.size():
			var l := lbl(vals[i], 22, Color(0.18, 0.1, 0.03)); l.position = Vector2(xs[i], 4); row.add_child(l)
		var bar_bg := ColorRect.new(); bar_bg.color = Color(0.3, 0.2, 0.1, 0.5); bar_bg.position = Vector2(790, 12); bar_bg.size = Vector2(190, 16); row.add_child(bar_bg)
		var bar := ColorRect.new(); bar.color = Color(0.95, 0.7, 0.2); bar.position = Vector2(790, 12); bar.size = Vector2(0, 16); row.add_child(bar)
		var xl := lbl("+%d" % int(res.exp.get(u.name, 0)), 18, Color(0.3, 0.15, 0.03)); xl.position = Vector2(905, -14); row.add_child(xl)
		var e := 0.0
		if u.member != null: e = clampf(float(u.member.get("exp", 0)) / 100.0, 0.0, 1.0)
		lvd.append([row, bar, e, u.lv > int(u.get("lv0", u.lv))])
		y += 52.0
		if y > 640: break
	var info := []
	if res.drops.size() > 0: info.append("戰利品：" + "、".join(res.drops))
	if rec != null: info.append("★ %s 加入了隊伍！" % rec.name)
	var il := lbl("　".join(info), 20, Color(0.3, 0.16, 0.05)); il.position = Vector2(70, 650); il.size = Vector2(1000, 30); pan.add_child(il)
	var b2 := Button.new(); b2.text = "返回營地"; b2.custom_minimum_size = Vector2(240, 52); b2.position = Vector2(450, 680); pan.add_child(b2)
	hand_hook(b2)
	var sp := CPUParticles2D.new(); sp.amount = 40; sp.lifetime = 3.0; sp.position = Vector2(570, 380); sp.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sp.emission_rect_extents = Vector2(540, 340); sp.texture = load("res://assets/v15/mote.png"); sp.gravity = Vector2(0, -12); sp.initial_velocity_min = 2; sp.initial_velocity_max = 10
	sp.scale_amount_min = 0.06; sp.scale_amount_max = 0.18; sp.preprocess = 2.0
	var sg := Gradient.new(); sg.set_color(0, Color(1, 0.85, 0.4, 0)); sg.add_point(0.3, Color(1, 0.85, 0.45, 0.8)); sg.set_color(sg.get_point_count() - 1, Color(1, 0.8, 0.4, 0)); sp.color_ramp = sg
	var sgm := CanvasItemMaterial.new(); sgm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD; sp.material = sgm; pan.add_child(sp)
	b2.pressed.connect(func(): Engine.time_scale = 1.0; get_tree().change_scene_to_file("res://camp.tscn"))
	pan.modulate.a = 0.0; pan.scale = Vector2(0.96, 0.96); pan.pivot_offset = pan.size / 2
	var tw := create_tween(); tw.tween_property(pan, "modulate:a", 1.0, 0.5); tw.parallel().tween_property(pan, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	for d in lvd:
		var t2 := create_tween(); t2.tween_property(d[0], "modulate:a", 1.0, 0.25)
		t2.tween_property(d[1], "size:x", 190.0 * maxf(0.05, d[2]), 0.7).set_trans(Tween.TRANS_CUBIC)
		await t2.finished
		if d[3]:
			sfx("levelup", 0.0, -4.0)
			var lu := lbl("LEVEL UP!", 20, Color(0.9, 0.35, 0.05), true); lu.position = Vector2(990, -12); d[0].add_child(lu)
	over_panel = PanelContainer.new()

func battle_track() -> String:
	if bidx >= 15: return "final"
	if bdef.get("boss") != null and bdef.boss is Dictionary: return "boss"
	return ["battle_a", "battle_b", "battle_c"][int(bidx / 5) % 3]

# ---- v16：頭目專屬登場演出 ----
const BOSS_FX := {
	"maximus": [Color(1.0, 0.82, 0.3), "drop", "金陽皇帝 降臨"],
	"kai": [Color(0.55, 0.2, 0.75), "smoke", "毒影 現身"],
	"aurelia": [Color(1.0, 0.95, 0.75), "pillar", "聖光 降臨"],
	"cyrus": [Color(0.4, 0.65, 1.0), "rune", "星儀 展開"],
	"simon": [Color(1.0, 0.35, 0.2), "slam", "鐵壁 不動"],
	"gard": [Color(0.9, 0.15, 0.1), "slam", "黑劍 出鞘"],
	"barto": [Color(1.0, 0.5, 0.1), "stomp", "熔爐 怒吼"],
	"vig": [Color(0.85, 0.2, 0.15), "leap", "狼牙 撲殺"],
}
func boss_entrance() -> void:
	var b = null
	for u in units:
		if u.alive and u.boss: b = u
	if b == null or not BOSS_FX.has(b.key): return
	var fx: Array = BOSS_FX[b.key]; var col: Color = fx[0]; var kind: String = fx[1]
	var old_pos: Vector3 = cam_pivot.position; var od := target_dist
	cam_pivot.position = b.node.position + Vector3(0, 1.4, 0); target_dist = 12.0; cam_dist = 12.0
	var p: Vector3 = b.node.position
	var bd: Node3D = b.body; var y0 := bd.position.y
	bd.visible = false
	await wait(0.35)
	match kind:
		"drop", "leap":
			bd.position.y = y0 + (6.0 if kind == "drop" else 3.0); bd.visible = true
			var tw := create_tween(); tw.tween_property(bd, "position:y", y0, 0.45 if kind == "drop" else 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			await tw.finished
			shake = 1.0; sfx("explode", 0.0, -2.0)
			burst(p + Vector3(0, 0.2, 0), col, 90, 6.0, "spark.png", 0.22, 0.9)
			make_rise_tmp(p, col, 1.1, 1.2)
		"smoke":
			burst(p + Vector3(0, 0.6, 0), col, 120, 2.5, "spark.png", 0.4, 1.2, 0.5)
			sfx("magic", 0.0, -3.0); await wait(0.4); bd.visible = true
			b.node.scale = Vector3(0.6, 1.4, 0.6)
			var tw := create_tween(); tw.tween_property(b.node, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK); await tw.finished
		"pillar", "rune":
			make_rise_tmp(p, col, 0.9 if kind == "pillar" else 1.4, 1.6)
			sfx("heal" if kind == "pillar" else "magic", 0.0, -2.0)
			burst(p + Vector3(0, 2.5 if kind == "pillar" else 0.3, 0), col, 100, 3.0, "spark.png", 0.2, 1.4, 2.0 if kind == "pillar" else -1.0)
			await wait(0.5); bd.visible = true; b.node.scale = Vector3.ONE * 0.1
			var tw := create_tween(); tw.tween_property(b.node, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK); await tw.finished
		_:
			bd.visible = true; play(b, "Spellcasting")
			await wait(0.35)
			shake = 1.4 if kind == "stomp" else 0.9; sfx("explode", 0.0, 0.0)
			burst(p + Vector3(0, 0.1, 0), col, 110, 7.0, "spark.png", 0.25, 0.8, -8.0)
			make_rise_tmp(p, col, 1.3, 1.0)
	skill_banner("%s・%s" % [b.name, fx[2]], col)
	if b.key != "kai": victory_hop_once(b)
	await wait(0.6)
	if do_shots: await shot("10_boss_entrance")
	await wait(0.7)
	await skill_banner_end()
	play(b, idle_anim(b), 0.2)
	cam_pivot.position = old_pos; target_dist = od

func victory_hop_once(u) -> void:
	if int(u.get("ncols", 24)) >= 28: u.sanim = {"n": "win", "t": 0.0, "sp": 1.0}

# ---------------- v16：天候系統 ----------------
# 每關天候表（每 WX_PERIOD 回合推進一格，最後一格持續）
const WX_PERIOD := 3
const WX_PLAN := [["clear"], ["clear", "rain"], ["clear", "storm"], ["heat", "clear"], ["rain", "fog"], ["fog", "fog", "rain"],
	["sand", "heat"], ["clear", "storm"], ["rain", "storm"], ["clear", "rain", "storm"], ["fog", "clear"], ["heat"],
	["storm", "rain"], ["snow"], ["fog", "rain"], ["clear", "storm"]]
# n 名稱, el 屬性倍率, hit 命中修正, rhit 僅遠程命中修正, rng 遠程/法術射程修正, mv 移動修正
const WX := {
	"clear": {"n": "晴", "el": {}, "hit": 0, "rhit": 0, "rng": 0, "mv": 0, "d": "無特殊效果", "c": Color(1, 0.85, 0.4)},
	"rain": {"n": "雨", "el": {"water": 1.2, "fire": 0.8}, "hit": 0, "rhit": 0, "rng": 0, "mv": 0, "d": "水屬性+20%　火屬性−20%", "c": Color(0.5, 0.75, 1)},
	"storm": {"n": "暴風雨", "el": {"wind": 1.25, "water": 1.1, "fire": 0.85}, "hit": 0, "rhit": -10, "rng": 0, "mv": 0, "d": "風+25% 水+10% 火−15%　遠程命中−10", "c": Color(0.75, 0.8, 1)},
	"snow": {"n": "雪", "el": {"water": 1.1, "fire": 0.9}, "hit": 0, "rhit": 0, "rng": 0, "mv": -1, "d": "移動−1　水+10% 火−10%", "c": Color(0.9, 0.95, 1)},
	"fog": {"n": "濃霧", "el": {}, "hit": -15, "rhit": 0, "rng": -1, "mv": 0, "d": "命中−15　遠程・法術射程−1", "c": Color(0.85, 0.85, 0.85)},
	"sand": {"n": "沙塵暴", "el": {"earth": 1.25, "wind": 0.9}, "hit": -8, "rhit": 0, "rng": 0, "mv": 0, "d": "地屬性+25% 風−10%　命中−8", "c": Color(0.95, 0.75, 0.45)},
	"heat": {"n": "酷暑", "el": {"fire": 1.25, "water": 0.85}, "hit": 0, "rhit": 0, "rng": 0, "mv": 0, "d": "火屬性+25%　水屬性−15%", "c": Color(1, 0.5, 0.25)},
}
var wx_kind := "clear"
var wx_force := ""
var wx_only := false
var light_shot := false
var settle_shot := false
var wx_idx := 0
var wx_round := 0
var wx_tick := 0
var wx_root: Node3D
var wx_panel: PanelContainer
var wx_icon: TextureRect
var wx_name: Label
var wx_desc: Label
var wx_fc: Label
var wx_base := {}
var wx_flash: ColorRect
var wx_tint: ColorRect
var wx_tut_done := false
var wx_shot_done := {}

func wx_plan() -> Array:
	if wx_force != "": return [wx_force]
	var bw = bdef.get("weather", null)
	if bw is Array and bw.size() > 0: return bw
	return WX_PLAN[clampi(bidx, 0, WX_PLAN.size() - 1)]
func wx() -> Dictionary: return WX[wx_kind]
func wx_el(el: String) -> float: return float(wx().el.get(el, 1.0))
func srng(s) -> int:
	var r := int(s.rng)
	return maxi(1, r + int(wx().rng)) if r > 1 else r

func wx_init() -> void:
	wx_base = {"fd": env.fog_density, "fc": env.fog_light_color, "se": TH.sun_e, "sc": sun.light_color, "ae": env.ambient_light_energy}
	wx_root = Node3D.new(); add_child(wx_root)
	wx_flash = ColorRect.new(); wx_flash.set_anchors_preset(Control.PRESET_FULL_RECT); wx_flash.color = Color(0.9, 0.95, 1, 0); wx_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(wx_flash); ui_root.move_child(wx_flash, 0)
	wx_tint = ColorRect.new(); wx_tint.set_anchors_preset(Control.PRESET_FULL_RECT); wx_tint.color = Color(0, 0, 0, 0); wx_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(wx_tint); ui_root.move_child(wx_tint, 0)
	wx_panel = panel(Vector2(1196, 66), Vector2(390, 96))
	var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 8); wx_panel.add_child(hb)
	wx_icon = TextureRect.new(); wx_icon.custom_minimum_size = Vector2(64, 64); wx_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wx_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; wx_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER; hb.add_child(wx_icon)
	var vb := VBoxContainer.new(); vb.add_theme_constant_override("separation", -3); hb.add_child(vb)
	wx_name = lbl("", 20, Color(1, 0.84, 0.45), true); vb.add_child(wx_name)
	wx_desc = lbl("", 15); vb.add_child(wx_desc)
	wx_fc = lbl("", 15, Color(0.6, 0.8, 1)); vb.add_child(wx_fc)
	wx_idx = 0; wx_round = 0; wx_tick = 0
	wx_apply(wx_plan()[0], false)

func wx_tex(k: String) -> Texture2D:
	return load("res://assets/v16/wx/%s.png" % ("sand" if k == "sand" else k))

func wx_ui() -> void:
	if wx_panel == null: return
	var w := wx()
	wx_icon.texture = wx_tex(wx_kind)
	wx_name.text = "天候：%s" % w.n
	wx_desc.text = w.d
	var plan := wx_plan()
	if wx_idx + 1 < plan.size():
		var left := WX_PERIOD * (wx_idx + 1) - wx_round
		wx_fc.text = "預報：%d 回合後 → %s" % [maxi(1, left), WX[plan[wx_idx + 1]].n]
	else:
		wx_fc.text = "預報：%s 持續" % w.n

# 每次行動回合呼叫；以存活單位數視為一輪
func wx_turn() -> void:
	var alive := 0
	for u in units:
		if u.alive: alive += 1
	wx_tick += 1
	if wx_tick >= maxi(1, alive):
		wx_tick = 0; wx_round += 1
		var plan := wx_plan()
		var ni := mini(wx_round / WX_PERIOD, plan.size() - 1)
		if ni != wx_idx:
			wx_idx = ni
			if plan[ni] != wx_kind:
				wx_apply(plan[ni], true)
				var w := wx()
				log_msg("天候變化：%s（%s）" % [w.n, w.d])
				skill_banner("天候變化 — %s" % w.n, w.c)
				if not wx_tut_done:
					wx_tut_done = true
					log_msg("提示：天候會影響屬性威力、命中與移動，右上角天候牌顯示目前效果與預報。")
				await wait(0.9)
				if do_shots and not wx_shot_done.has(wx_kind):
					wx_shot_done[wx_kind] = true; await shot("20_weather_" + wx_kind)
				await skill_banner_end()
	wx_ui()

func wx_apply(k: String, anim: bool) -> void:
	wx_kind = k
	for c in wx_root.get_children(): c.queue_free()
	var fd: float = wx_base.fd; var fc: Color = wx_base.fc; var se: float = wx_base.se; var sc: Color = wx_base.sc; var ae: float = wx_base.ae
	match k:
		"rain":
			wx_rain(900, Vector3(0.6, -16, 0.2), Color(0.75, 0.82, 0.95, 0.8)); fd = maxf(fd, 0.012); fc = fc.lerp(Color(0.32, 0.37, 0.45), 0.65); se *= 0.6; ae *= 0.75; sc = sc.lerp(Color(0.7, 0.78, 0.9), 0.5)
		"storm":
			wx_rain(1300, Vector3(3.5, -20, 1.0), Color(0.7, 0.78, 0.95, 0.6)); fd = maxf(fd, 0.016); fc = fc.lerp(Color(0.17, 0.19, 0.26), 0.75); se *= 0.4; ae *= 0.6; sc = sc.lerp(Color(0.6, 0.66, 0.85), 0.6)
			wx_lightning()
		"snow":
			if TH.fx != "snow": wx_snow()
			fd = maxf(fd, 0.012); fc = fc.lerp(Color(0.85, 0.9, 1), 0.5); sc = sc.lerp(Color(0.85, 0.9, 1), 0.4)
		"fog":
			wx_drift(60, Color(0.85, 0.87, 0.9, 0.16), 2.6, Vector3(0.25, 0, 0.05), 0.6); fd = maxf(fd, 0.03); fc = fc.lerp(Color(0.75, 0.78, 0.8), 0.7); se *= 0.75
		"sand":
			wx_drift(500, Color(0.95, 0.72, 0.42, 0.55), 0.09, Vector3(6, 0, 1.2), 1.4); wx_drift(40, Color(0.9, 0.65, 0.35, 0.14), 2.4, Vector3(2.5, 0, 0.5), 1.0)
			fd = maxf(fd, 0.025); fc = fc.lerp(Color(0.8, 0.58, 0.32), 0.75); sc = sc.lerp(Color(1, 0.75, 0.45), 0.5)
		"heat":
			wx_heat(); fc = fc.lerp(Color(1, 0.6, 0.35), 0.35); se *= 1.15; sc = sc.lerp(Color(1, 0.7, 0.45), 0.45)
	var tc: Color = {"rain": Color(0.08, 0.13, 0.25, 0.28), "storm": Color(0.04, 0.06, 0.16, 0.45), "snow": Color(0.6, 0.7, 0.9, 0.06),
		"sand": Color(0.55, 0.32, 0.08, 0.12), "heat": Color(0.6, 0.2, 0.0, 0.06)}.get(k, Color(0, 0, 0, 0))
	if anim: create_tween().tween_property(wx_tint, "color", tc, 1.2)
	else: wx_tint.color = tc
	if anim:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(env, "fog_density", fd, 1.2); tw.tween_property(env, "fog_light_color", fc, 1.2)
		tw.tween_property(self, "sun_base", se, 1.2); tw.tween_property(sun, "light_color", sc, 1.2); tw.tween_property(env, "ambient_light_energy", ae, 1.2)
	else:
		env.fog_density = fd; env.fog_light_color = fc; sun_base = se; sun.light_energy = se; sun.light_color = sc; env.ambient_light_energy = ae
	wx_ui()

func wx_parts(amount: int, life: float) -> Array:
	var p := GPUParticles3D.new(); p.amount = amount; p.lifetime = life; p.preprocess = life
	p.visibility_aabb = AABB(Vector3(-20, -12, -20), Vector3(40, 30, 40))
	var pm := ParticleProcessMaterial.new(); pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	p.process_material = pm; wx_root.add_child(p)
	return [p, pm]

func wx_rain(n: int, vel: Vector3, col: Color) -> void:
	var a := wx_parts(n, 0.75); var p: GPUParticles3D = a[0]; var pm: ParticleProcessMaterial = a[1]
	pm.emission_box_extents = Vector3(14, 0.5, 12); pm.gravity = Vector3.ZERO
	pm.direction = vel.normalized(); pm.spread = 2; pm.initial_velocity_min = vel.length() * 0.9; pm.initial_velocity_max = vel.length() * 1.1
	var q := quad(0.035, 0.6); var m := particle_mat("glow.png", col); m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y; m.billboard_keep_scale = true
	q.material = m; p.draw_pass_1 = q; p.position = Vector3(-vel.x * 0.3, 9, -vel.z * 0.3)
	# 地面水花
	var b := wx_parts(n / 4, 0.35); var sp: GPUParticles3D = b[0]; var spm: ParticleProcessMaterial = b[1]
	spm.emission_box_extents = Vector3(11, 0.1, 9); spm.gravity = Vector3(0, -6, 0); spm.direction = Vector3.UP; spm.spread = 50
	spm.initial_velocity_min = 0.6; spm.initial_velocity_max = 1.3; spm.scale_min = 0.5; spm.scale_max = 1.0
	var q2 := quad(0.06, 0.06); q2.material = particle_mat("glow.png", Color(0.8, 0.88, 1, 0.5)); sp.draw_pass_1 = q2; sp.position = Vector3(0, 1.2, 0)

func wx_snow() -> void:
	var a := wx_parts(500, 7.0); var p: GPUParticles3D = a[0]; var pm: ParticleProcessMaterial = a[1]
	pm.emission_box_extents = Vector3(13, 0.5, 11); pm.gravity = Vector3(0.3, -1.1, 0.1)
	pm.turbulence_enabled = true; pm.turbulence_noise_strength = 0.5; pm.turbulence_noise_scale = 4.0; pm.scale_min = 0.6; pm.scale_max = 1.3
	var q := quad(0.08, 0.08); q.material = particle_mat("glow.png", Color(1, 1, 1, 0.9)); p.draw_pass_1 = q; p.position = Vector3(0, 7.5, 0)

func wx_drift(n: int, col: Color, sz: float, vel: Vector3, y: float) -> void:
	var a := wx_parts(n, 6.0); var p: GPUParticles3D = a[0]; var pm: ParticleProcessMaterial = a[1]
	pm.emission_box_extents = Vector3(13, y, 11); pm.gravity = Vector3.ZERO
	pm.direction = vel.normalized(); pm.spread = 12; pm.initial_velocity_min = vel.length() * 0.7; pm.initial_velocity_max = vel.length() * 1.2
	pm.turbulence_enabled = true; pm.turbulence_noise_strength = 0.6; pm.turbulence_noise_scale = 3.0
	var g := Gradient.new(); g.set_color(0, Color(1, 1, 1, 0)); g.add_point(0.25, Color(1, 1, 1, 1)); g.add_point(0.75, Color(1, 1, 1, 1)); g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	var gt := GradientTexture1D.new(); gt.gradient = g; pm.color_ramp = gt
	pm.scale_min = 0.6; pm.scale_max = 1.4
	var q := quad(sz, sz); q.material = particle_mat("glow.png", col, false); p.draw_pass_1 = q; p.position = Vector3(-vel.x * 1.5, y + 0.6, 0)

func wx_heat() -> void:
	var a := wx_parts(160, 4.0); var p: GPUParticles3D = a[0]; var pm: ParticleProcessMaterial = a[1]
	pm.emission_box_extents = Vector3(11, 0.3, 9); pm.gravity = Vector3(0, 0.5, 0); pm.direction = Vector3.UP; pm.spread = 25
	pm.initial_velocity_min = 0.2; pm.initial_velocity_max = 0.6; pm.turbulence_enabled = true; pm.turbulence_noise_strength = 1.0
	var g := Gradient.new(); g.set_color(0, Color(1, 0.8, 0.4, 0)); g.add_point(0.3, Color(1, 0.6, 0.25, 0.8)); g.set_color(g.get_point_count() - 1, Color(1, 0.3, 0.1, 0))
	var gt := GradientTexture1D.new(); gt.gradient = g; pm.color_ramp = gt
	var q := quad(0.1, 0.1); q.material = particle_mat("glow.png", Color.WHITE); p.draw_pass_1 = q; p.position = Vector3(0, 0.6, 0)

func wx_lightning() -> void:
	var t := Timer.new(); t.wait_time = 4.5; t.autostart = true; wx_root.add_child(t)
	t.timeout.connect(func():
		t.wait_time = randf_range(3.5, 8.0)
		if wx_kind != "storm": return
		var base: float = sun.light_energy
		var tw := create_tween()
		tw.tween_property(wx_flash, "color:a", 0.45, 0.05); tw.parallel().tween_property(sun, "light_energy", base * 3.0, 0.05)
		tw.tween_property(wx_flash, "color:a", 0.05, 0.08); tw.tween_property(wx_flash, "color:a", 0.3, 0.05)
		tw.tween_property(wx_flash, "color:a", 0.0, 0.35); tw.parallel().tween_property(sun, "light_energy", base, 0.35)
		sfx("explode", 0.2, -18.0))

# ---- v16：晉升 ----
func ucls(u) -> String:
	var m = u.get("member")
	if m == null or str(m.get("cls", "")) == "" or int(m.get("tier", 0)) <= 0: return ""
	return "%s_%s" % [m.key, m.cls]
func utier(u) -> int:
	var m = u.get("member")
	return 0 if m == null else int(m.get("tier", 0))
# 二轉：金色光環（腳下光圈＋上升光粒）
func promo_aura(u) -> void:
	var root := Node3D.new(); u.node.add_child(root); u.aura = root
	var ring := MeshInstance3D.new(); var qm := QuadMesh.new(); qm.size = Vector2(1.3, 1.3); qm.orientation = PlaneMesh.FACE_Y
	ring.mesh = qm; ring.position.y = 0.04
	var mt := StandardMaterial3D.new(); mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.blend_mode = BaseMaterial3D.BLEND_MODE_ADD; mt.albedo_texture = load("res://assets/v15/sel_glow.png"); mt.albedo_color = Color(1.0, 0.78, 0.3, 0.8)
	ring.material_override = mt; root.add_child(ring)
	var tw := ring.create_tween().set_loops(); tw.tween_property(mt, "albedo_color:a", 0.35, 1.0); tw.tween_property(mt, "albedo_color:a", 0.8, 1.0)
	var p := CPUParticles3D.new(); p.amount = 14; p.lifetime = 1.6; p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP; p.emission_ring_radius = 0.45; p.emission_ring_inner_radius = 0.3; p.emission_ring_height = 0.05
	p.direction = Vector3.UP; p.spread = 8.0; p.gravity = Vector3(0, 0.5, 0); p.initial_velocity_min = 0.4; p.initial_velocity_max = 0.8
	var pm := QuadMesh.new(); pm.size = Vector2(0.09, 0.09); p.mesh = pm
	var m2 := StandardMaterial3D.new(); m2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m2.blend_mode = BaseMaterial3D.BLEND_MODE_ADD; m2.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; m2.albedo_texture = load("res://assets/v15/mote.png")
	m2.albedo_color = Color(1.0, 0.85, 0.4); pm.material = m2
	p.scale_amount_min = 0.6; p.scale_amount_max = 1.2; root.add_child(p)
var promo_view := false

# ================= v17：第二召喚獸 利維坦（深海之王・水屬性・支援控制） =================
func lev_cost(u) -> int:
	return maxi(16, LEV_COST - eff(u, "summon") / 5)

func lev_dmg(a, d) -> int:
	var dm := (st(a, "mag") * 1.3 + 8 - st(d, "def") * 0.4) * (1.0 + eff(a, "summon") / 100.0)
	if uel(d) == "fire": dm *= 1.3
	return maxi(1, int(dm))

func lev_cells(c: Vector2i) -> Array:
	var out := []
	for k in heights:
		if mdist(k, c) <= LEV_AOE: out.append(k)
	return out

func lev_plan(u):
	if u.mp < lev_cost(u): return null
	var r := reachable(u)
	var best = null; var bs_ := 0.0
	for c in r.ends:
		for t in heights:
			if mdist(c, t) > LEV_RANGE: continue
			var sc := 0.0
			for a in lev_cells(t):
				var o = unit_at(a)
				if a == c: o = u
				if o == null or not o.alive: continue
				if o.team != u.team: sc += 1.0
				else:
					var miss: float = 1.0 - float(o.hp) / float(st(o, "hp"))
					if miss > 0.3: sc += 1.2
					for k in ["burn", "slow", "freeze", "root", "poison", "stun"]:
						if o.status.has(k): sc += 0.5; break
			if sc > bs_: bs_ = sc; best = {"move": c, "cell": t, "parent": r.parent, "score": sc}
	return best

func make_leviathan() -> Dictionary:
	var root := Node3D.new()
	var sm := ShaderMaterial.new(); sm.shader = spr_shader
	sm.set_shader_parameter("tex", load("res://assets/v12/leviathan.png")); sm.set_shader_parameter("grid", Vector2(8, 3))
	sm.set_shader_parameter("frame", 0); sm.set_shader_parameter("row", 1)
	sm.set_shader_parameter("tint", Vector3(0.92, 0.97, 1.02))
	var H := 3.3
	var qm := QuadMesh.new(); qm.size = Vector2(H * 0.75, H); qm.center_offset = Vector3(0, H * 0.5, 0)
	var spr := Node3D.new(); root.add_child(spr)
	var q := MeshInstance3D.new(); q.mesh = qm; q.material_override = sm; q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; spr.add_child(q)
	var lt := OmniLight3D.new(); lt.light_color = Color(0.3, 0.7, 1.0); lt.light_energy = 4.0; lt.omni_range = 4.0; lt.position = Vector3(0, 1.6, 0.5); root.add_child(lt)
	var ap := FakeAP.new()
	var cur_tw := [null]
	ap.cb = func(n: String):
		if cur_tw[0] != null and (cur_tw[0] as Tween).is_valid(): (cur_tw[0] as Tween).kill()
		var ft := spr.create_tween(); cur_tw[0] = ft
		var F := func(r: int, i: int): sm.set_shader_parameter("row", r); sm.set_shader_parameter("frame", i)
		match n:
			"rise":   # 第1列：破浪而出
				for i in 8: ft.tween_callback(F.bind(1, i)); ft.tween_interval(0.16)
			"attack": # 第2列：蓄勢→猛撲
				for i in 8: ft.tween_callback(F.bind(2, i)); ft.tween_interval(0.13 if i < 4 else 0.09)
				ft.tween_interval(0.5)
				for i in 8: ft.tween_callback(F.bind(0, i)); ft.tween_interval(0.14)
			_:        # 第0列：待機擺動
				ft.set_loops(8)
				for i in 8: ft.tween_callback(F.bind(0, i)); ft.tween_interval(0.14)
		var tw := spr.create_tween()
		if n == "attack":
			tw.tween_property(spr, "scale", Vector3(0.96, 1.05, 1.0), 0.5); tw.tween_property(spr, "scale", Vector3(1.08, 0.95, 1.0), 0.12); tw.tween_property(spr, "scale", Vector3.ONE, 0.4)
		else:
			tw.tween_property(spr, "scale", Vector3(1.02, 1.03, 1.0), 0.6); tw.tween_property(spr, "scale", Vector3.ONE, 0.6)
	return {"root": root, "ap": ap, "mat": sm, "light": lt}

func whirlpool(pos: Vector3, r: float) -> Node3D:
	var n := Node3D.new(); n.position = pos; add_child(n)
	for i in 3:
		var tor := TorusMesh.new(); tor.inner_radius = r * (0.35 + i * 0.25); tor.outer_radius = tor.inner_radius + 0.18; tor.rings = 48
		var m := mi(n, tor, Vector3(0, 0.05 + i * 0.04, 0), glow(Color(0.35, 0.75, 1.0), 0.55 - i * 0.12, 4.0), Vector3.ZERO, Vector3(1, 0.15, 1))
		var tw := m.create_tween().set_loops(); tw.tween_property(m, "rotation:y", TAU * (1 if i % 2 == 0 else -1), 1.6 + i * 0.5).from(0.0)
	var dk := mi(n, cyl(r, r, 0.02, 40), Vector3(0, 0.02, 0), glow(Color(0.02, 0.12, 0.3), 0.55, 1.0))
	return n

func do_leviathan(u, c: Vector2i) -> void:
	hide_menu()
	u.mp -= lev_cost(u)
	fill_card(card, u)
	face(u, cell_pos(c))
	log_msg("%s 詠唱深海的契約……" % u.name)
	voice(u, "line", "sum_lev")
	var fx: Array = []
	var cpos: Vector3 = u.node.position
	play(u, "Spellcasting", 0.15)
	sfx("magic", 0.0, -4.0)
	fx.append(magic_circle(cpos + Vector3(0, 0.06, 0), 1.3, Color(0.3, 0.7, 1.0)))
	fx.append(make_rise(cpos, Color(0.4, 0.8, 1.0), 0.9))
	# 天色轉為深海藍
	var old_sun := sun.light_energy; var old_amb := env.ambient_light_energy; var old_fog := env.fog_light_color
	var old_sc := sun.light_color
	var et := create_tween().set_parallel()
	et.tween_property(sun, "light_energy", 0.3, 1.2); et.tween_property(env, "ambient_light_energy", 0.35, 1.2)
	et.tween_property(sun, "light_color", Color(0.55, 0.75, 1.0), 1.2)
	et.tween_property(env, "fog_light_color", Color(0.08, 0.25, 0.45), 1.2); et.tween_property(env, "background_energy_multiplier", 0.4, 1.2)
	await wait(1.0)
	var tp := cell_pos(c)
	var old_pos := cam_pivot.position; var old_yaw := target_yaw; var old_dist := target_dist; var old_pitch := target_pitch
	target_yaw = round(old_yaw / 360.0) * 360.0 - 25.0; target_dist = 21.0; target_pitch = 17.0
	title_panel.visible = false
	banner.text = "召喚獸　利維坦　— 大海嘯 —"; banner.visible = true; banner.modulate.a = 0
	banner.add_theme_color_override("font_color", Color(0.78, 0.94, 1.0)); banner.add_theme_color_override("font_outline_color", Color(0.02, 0.1, 0.25))
	banner.position = Vector2(0, 6); banner.size = Vector2(1600, 84); banner.add_theme_font_size_override("font_size", 40)
	banner_bg.position = Vector2(0, 10); banner_bg.size = Vector2(1600, 76)
	var bt := create_tween().set_parallel(); bt.tween_property(banner, "modulate:a", 1.0, 0.5); bt.tween_property(banner_bg, "modulate:a", 0.75, 0.5)
	sfx("summon", 0.0, -3.0)
	# 漩渦與水柱
	var wp := whirlpool(tp + Vector3(0, 0.05, 0), 3.6); fx.append(wp)
	fx.append(magic_circle(tp + Vector3(0, 0.1, 0), 4.2, Color(0.2, 0.55, 1.0)))
	var pillar := MeshInstance3D.new(); pillar.mesh = cyl(1.6, 2.1, 16.0, 24); (pillar.mesh as CylinderMesh).cap_top = false; (pillar.mesh as CylinderMesh).cap_bottom = false
	var pm := shmat(SH.PILLAR); pm.set_shader_parameter("noise_tex", noise_tex); pm.set_shader_parameter("power", 0.0); pm.set_shader_parameter("col", Color(0.15, 0.5, 1.0, 1.0)); pillar.material_override = pm
	pillar.position = tp + Vector3(0, 8, 0); add_child(pillar); fx.append(pillar)
	var pt := create_tween(); pt.tween_method(func(v): pm.set_shader_parameter("power", v), 0.0, 1.2, 0.7)
	var spray := burst(tp + Vector3(0, 0.3, 0), Color(0.75, 0.92, 1.0), 120, 7.0, "spark.png", 0.22, 1.2, -9.0, 35.0)
	# 利維坦破浪而出
	var off := Vector3(0, 0, 1).rotated(Vector3.UP, deg_to_rad(target_yaw))
	var side := off.cross(Vector3.UP).normalized()
	var ld := make_leviathan(); var lev: Node3D = ld.root
	add_child(lev); fx.append(lev)
	lev.scale = Vector3.ONE * 3.0
	var lb := tp - off * 3.2 - side * 4.4
	lev.position = lb + Vector3(0, -2.5, 0); lev.rotation.y = atan2(tp.x - lb.x, tp.z - lb.z) * 0.0 + deg_to_rad(target_yaw)
	cam_pivot.position = Vector3(tp.x * 0.4 + lb.x * 0.6, tp.y + 3.0, tp.z * 0.4 + lb.z * 0.6)
	ld.ap.play("rise")
	var it := create_tween(); it.tween_property(lev, "position:y", lb.y - 0.2, 1.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	burst(lb + Vector3(0, 0.3, 0), Color(0.8, 0.95, 1.0), 140, 8.0, "spark.png", 0.25, 1.4, -10.0, 40.0)
	sfx("lev_roar", 0.0, -1.0)
	shake = 0.9
	await wait(1.4)
	ld.ap.play("idle")
	var pt2 := create_tween(); pt2.tween_method(func(v): pm.set_shader_parameter("power", v), 1.2, 0.3, 0.6)
	await wait(0.5)
	if autotest and not lev_shot_done:
		await shot("03f_leviathan")
		var sv := [cam_pivot.position, target_yaw, target_dist, target_pitch]
		cam_pivot.position = lev.global_position + Vector3(0, 4.6, 0)
		target_dist = 13.0; target_pitch = 8.0
		yaw = target_yaw; cam_dist = target_dist; pitch = target_pitch
		await wait(0.5)
		await shot("03g_leviathan_close")
		cam_pivot.position = sv[0]; target_yaw = sv[1]; target_dist = sv[2]; target_pitch = sv[3]
		yaw = target_yaw; cam_dist = target_dist; pitch = target_pitch
	# 大海嘯
	voice(u, "line", "sk_lev")
	ld.ap.play("attack")
	await wait(0.75)
	sfx("lev_wave", 0.0, -1.0)
	var wall := MeshInstance3D.new(); var wc := cyl(1.0, 1.15, 1.0, 48); wc.cap_top = false; wc.cap_bottom = false; wall.mesh = wc
	var wm := shmat(SH.PILLAR); wm.set_shader_parameter("noise_tex", noise_tex); wm.set_shader_parameter("col", Color(0.35, 0.75, 1.0, 1.0)); wm.set_shader_parameter("power", 1.6)
	wall.material_override = wm; wall.position = tp + Vector3(0, 0.6, 0); wall.scale = Vector3(0.3, 0.2, 0.3); add_child(wall); fx.append(wall)
	var wt := create_tween().set_parallel()
	wt.tween_property(wall, "scale", Vector3(LEV_AOE * 2.1, 2.6, LEV_AOE * 2.1), 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	wt.tween_property(wall, "position:y", tp.y + 1.3, 0.9)
	wt.chain().tween_method(func(v): wm.set_shader_parameter("power", v), 1.6, 0.0, 0.6)
	var ring := MeshInstance3D.new(); var tor := TorusMesh.new(); tor.inner_radius = 0.85; tor.outer_radius = 1.0; tor.rings = 48; ring.mesh = tor
	ring.material_override = glow(Color(0.7, 0.92, 1.0), 0.9, 5.0); ring.position = tp + Vector3(0, 0.25, 0); ring.scale = Vector3(0.3, 0.3, 0.3); add_child(ring); fx.append(ring)
	var rt := create_tween(); rt.tween_property(ring, "scale", Vector3(LEV_AOE * 2.3, 0.6, LEV_AOE * 2.3), 0.8).set_ease(Tween.EASE_OUT)
	rt.parallel().tween_property(ring.material_override, "albedo_color:a", 0.0, 0.9)
	for i in 10:
		var a := TAU * i / 10.0
		burst(tp + Vector3(cos(a) * 2.5, 0.4, sin(a) * 2.5), Color(0.75, 0.93, 1.0), 30, 6.5, "spark.png", 0.22, 1.0, -9.0, 30.0)
	var rain := burst(tp + Vector3(0, 9, 0), Color(0.6, 0.85, 1.0, 0.8), 260, 3.0, "spark.png", 0.1, 1.4, -14.0, 60.0, Vector3.DOWN)
	flash.color = Color(0.6, 0.85, 1.0, 0.28)
	var ft := create_tween(); ft.tween_property(flash, "color:a", 0.0, 0.5)
	shake = 1.3
	await wait(0.35)
	var hits := 0; var heals := 0
	for a in lev_cells(c):
		var t = unit_at(a)
		if t == null or not t.alive: continue
		if t.team != u.team:
			var dmg := int(lev_dmg(u, t) * randf_range(0.92, 1.08))
			t.hp = max(0, t.hp - dmg); hits += 1; track_dmg(u, t, dmg)
			popup(t.node.position, str(dmg), Color(0.45, 0.8, 1.0), true)
			hit_flash(t, Color(0.3, 0.6, 1.0)); play(t, "Hit_B", 0.05)
			update_label(t)
			log_msg("大海嘯 對 %s 造成 %d 傷害" % [t.name, dmg])
			if t.hp <= 0: kill(t)
			else:
				apply_status(t, "slow", 70)
				after_damage(t)
				var tt = t
				get_tree().create_timer(0.8).timeout.connect(func(): if tt.alive: play(tt, idle_anim(tt), 0.3))
		else:
			var amt := mini(int(st(t, "hp") * 0.3), st(t, "hp") - t.hp)
			var cl := 0
			for k in ["burn", "slow", "freeze", "root", "poison", "stun"]:
				if t.status.has(k): t.status.erase(k); cl += 1
			if amt <= 0 and cl == 0: continue
			t.hp += amt; track_heal(u, amt); heals += 1
			if amt > 0: popup(t.node.position, "+%d" % amt, Color(0.4, 1.0, 0.7), true)
			if cl > 0: popup(t.node.position + Vector3(0, 0.6, 0), "淨化", Color(0.7, 0.95, 1.0))
			var rp := make_rise(t.node.position, Color(0.4, 0.9, 1.0), 0.5, 50); fx.append(rp)
			update_label(t)
			log_msg("大海嘯 治癒 %s %d HP%s" % [t.name, amt, "（解除異常）" if cl > 0 else ""])
	if hits + heals == 0: log_msg("大海嘯 沒有波及任何人")
	fill_card(card, u)
	await wait(0.6)
	if autotest and not lev_shot_done:
		lev_shot_done = true
		await shot("03h_tidal_wave")
	await wait(1.0)
	# 沉回深海
	var ot := create_tween().set_parallel()
	ot.tween_property(lev, "position:y", lb.y - 6.0, 1.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	ot.tween_method(func(v): ld.mat.set_shader_parameter("dissolve", v), 0.0, 1.05, 1.2)
	ot.tween_property(banner, "modulate:a", 0.0, 0.7); ot.tween_property(banner_bg, "modulate:a", 0.0, 0.7)
	ot.tween_method(func(v): pm.set_shader_parameter("power", v), 0.3, 0.0, 0.7)
	ot.tween_property(sun, "light_energy", old_sun, 1.2); ot.tween_property(env, "ambient_light_energy", old_amb, 1.2)
	ot.tween_property(sun, "light_color", old_sc, 1.2)
	ot.tween_property(env, "fog_light_color", old_fog, 1.2); ot.tween_property(env, "background_energy_multiplier", 1.0, 1.2)
	ot.tween_property(ld.light, "light_energy", 0.0, 1.0)
	burst(lb + Vector3(0, 0.4, 0), Color(0.8, 0.95, 1.0), 80, 6.0, "spark.png", 0.22, 1.0, -9.0, 40.0)
	await ot.finished
	banner.visible = false; title_panel.visible = true
	banner.add_theme_color_override("font_color", Color(1, 0.86, 0.5)); banner.add_theme_color_override("font_outline_color", Color(0.25, 0.04, 0))
	banner.position = Vector2(0, 120); banner.size = Vector2(1600, 170); banner.add_theme_font_size_override("font_size", 60)
	banner_bg.position = Vector2(0, 130); banner_bg.size = Vector2(1600, 150)
	for f in fx:
		if is_instance_valid(f): f.queue_free()
	play(u, idle_anim(u), 0.3)
	var rt2 := create_tween(); rt2.tween_property(cam_pivot, "position", old_pos, 0.8)
	target_yaw = old_yaw; target_dist = old_dist; target_pitch = old_pitch
	await wait(0.8)
	if u.team == 0: await grant_exp(u, 15 + hits * 8 + heals * 6)


# ================= v19：每話戰前簡報 =================
var BRIEF: Array = []
var brief_vo_p: AudioStreamPlayer = null
func brief_def() -> Dictionary:
	if BRIEF.is_empty() and FileAccess.file_exists("res://data/briefing.json"):
		var j = JSON.parse_string(FileAccess.get_file_as_string("res://data/briefing.json"))
		if j is Array: BRIEF = j
	if bidx >= 0 and bidx < BRIEF.size(): return BRIEF[bidx]
	return {}

func brief_vo(bf: Dictionary) -> Dictionary:
	if bf.has("vo") and bf.has("vo_file"): return {int(bf.vo): str(bf.vo_file)}
	return {}

func play_line_vo(path: String) -> void:
	if G.voice_vol <= 0.01 or not ResourceLoader.exists(path): return
	if brief_vo_p == null: brief_vo_p = AudioStreamPlayer.new(); add_child(brief_vo_p)
	brief_vo_p.stream = load(path); brief_vo_p.volume_db = linear_to_db(G.voice_vol) + 1.0; brief_vo_p.play()

func show_briefing(bf: Dictionary, shot_name := "") -> void:
	var prev_state := state
	state = "story"; dlg_active = true; dlg_skip = false; dlg_adv = false
	bgm_play("prebattle", 1.2)
	var vs := get_viewport().get_visible_rect().size
	var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); root.size = vs; root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(root)
	var bg := TextureRect.new(); bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bp: String = str(bf.get("bg", "res://assets/v15/title_bg.jpg"))
	if not ResourceLoader.exists(bp): bp = "res://assets/v15/title_bg.jpg"
	bg.texture = load(bp); bg.size = vs * 1.08; bg.position = -vs * 0.04; bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(bg)
	var kb := create_tween(); kb.tween_property(bg, "position", Vector2(-vs.x * 0.07, -vs.y * 0.02), 30.0).set_trans(Tween.TRANS_SINE)
	var dim := ColorRect.new(); dim.set_anchors_preset(Control.PRESET_FULL_RECT); dim.size = vs; dim.color = Color(0.03, 0.02, 0.01, 0.42); dim.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(dim)
	# 羊皮紙卷軸 + 金框
	var pw := minf(1180.0, vs.x - 80.0); var ph := minf(760.0, vs.y - 60.0)
	var pp := PanelContainer.new(); pp.add_theme_stylebox_override("panel", sbt("parchment.png", 18, 0)); pp.position = Vector2((vs.x - pw) * 0.5, (vs.y - ph) * 0.5); pp.size = Vector2(pw, ph); pp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(pp)
	var gold := StyleBoxFlat.new(); gold.draw_center = false; gold.border_color = Color(0.82, 0.62, 0.26); gold.set_border_width_all(5); gold.set_corner_radius_all(6)
	gold.shadow_color = Color(0, 0, 0, 0.55); gold.shadow_size = 18
	var gf := Panel.new(); gf.add_theme_stylebox_override("panel", gold); gf.position = pp.position - Vector2(6, 6); gf.size = pp.size + Vector2(12, 12); gf.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(gf)
	var gold2 := StyleBoxFlat.new(); gold2.draw_center = false; gold2.border_color = Color(0.55, 0.36, 0.12, 0.8); gold2.set_border_width_all(2); gold2.set_corner_radius_all(4)
	var gi := Panel.new(); gi.add_theme_stylebox_override("panel", gold2); gi.position = pp.position + Vector2(14, 14); gi.size = pp.size - Vector2(28, 28); gi.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(gi)
	var mc := MarginContainer.new(); for k in ["left", "right"]: mc.add_theme_constant_override("margin_" + k, 70)
	mc.add_theme_constant_override("margin_top", 34); mc.add_theme_constant_override("margin_bottom", 26); mc.mouse_filter = Control.MOUSE_FILTER_IGNORE; pp.add_child(mc)
	var vb := VBoxContainer.new(); vb.add_theme_constant_override("separation", 10 if G.font_k() < 1.3 else 4); vb.mouse_filter = Control.MOUSE_FILTER_IGNORE; vb.set_meta("max_k", 1.28); mc.add_child(vb)
	if G.font_k() >= 1.3: mc.add_theme_constant_override("margin_left", 44); mc.add_theme_constant_override("margin_right", 44); mc.add_theme_constant_override("margin_top", 22); mc.add_theme_constant_override("margin_bottom", 14)
	var ink := Color(0.24, 0.14, 0.07); var red := Color(0.5, 0.1, 0.06)
	var items: Array = []
	var mk := func(t: String, sz: int, col: Color, center := false) -> Label:
		var l := Label.new(); l.text = t; l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY; l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_theme_font_override("font", narr_font); l.add_theme_font_size_override("font_size", sz); l.add_theme_color_override("font_color", col)
		if center: l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.modulate.a = 0.0; vb.add_child(l); items.append(l); return l
	mk.call("%s　·　%s" % [str(bf.ep), str(bf.get("chapter", ""))], 24, red, true)
	mk.call(str(bf.title), 54, Color(0.3, 0.12, 0.04), true).set_meta("max_k", 1.0)
	mk.call("── 戰場：%s ──" % str(bdef.get("loc", bf.title)), 22, Color(0.42, 0.3, 0.16), true)
	var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 6); vb.add_child(sp)
	for t in bf.story: mk.call(str(t), 25, ink)
	var sep := ColorRect.new(); sep.custom_minimum_size = Vector2(0, 2); sep.color = Color(0.6, 0.42, 0.18, 0.7); sep.modulate.a = 0.0; vb.add_child(sep); items.append(sep)
	mk.call("◆ 勝利條件　" + str(bf.win), 23, Color(0.12, 0.3, 0.12))
	mk.call("◆ 敗北條件　" + str(bf.lose), 23, Color(0.5, 0.1, 0.06))
	mk.call("◆ 天　　候　" + str(bf.weather), 21, ink)
	if str(bf.get("boss", "")) != "": mk.call("◆ 敵軍頭目　" + str(bf.boss), 21, ink)
	mk.call("◆ 戰場規模　%d×%d　%s" % [W, H, SETTLE_NAME.get(SETTLE.get(bidx, ""), "")], 21, ink)
	for bl in brief_ev_lines(): mk.call(bl, 21, Color(0.45, 0.2, 0.5))
	var hint := lbl("▼ 點擊／Enter 出陣　　跳過 ▶▶", 16, Color(0.45, 0.33, 0.2)); hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; hint.modulate.a = 0.0; vb.add_child(hint)
	dlg.skip.visible = true; ui_root.move_child(dlg.skip, ui_root.get_child_count() - 1)
	root.modulate.a = 0.0
	var ft := create_tween(); ft.tween_property(root, "modulate:a", 1.0, 0.7); await ft.finished
	dlg_adv = false
	for it in items:
		if dlg_skip: break
		var tw := create_tween(); tw.tween_property(it, "modulate:a", 1.0, 0.9 if it is Label and (it as Label).get_theme_font_size("font_size") >= 25 else 0.6).set_trans(Tween.TRANS_SINE)
		var t0 := Time.get_ticks_msec()
		while tw.is_running() and not dlg_skip:
			await get_tree().process_frame
			if dlg_adv: break
			if Time.get_ticks_msec() - t0 > 450: break
		if dlg_adv:
			dlg_adv = false
			for it2 in items: it2.modulate.a = 1.0
			break
	for it in items: it.modulate.a = 1.0
	hint.modulate.a = 1.0
	if autotest:
		await wait(0.6)
		if shot_name != "" and do_shots: await shot(shot_name)
	dlg_adv = false
	var t1 := Time.get_ticks_msec()
	while not dlg_skip and not dlg_adv:
		await get_tree().process_frame
		if autotest and Time.get_ticks_msec() - t1 > (1500 if do_shots else 300): break
	dlg_adv = false; dlg_skip = false
	var ot := create_tween(); ot.tween_property(root, "modulate:a", 0.0, 0.6); await ot.finished
	kb.kill(); root.queue_free()
	dlg.skip.visible = false; dlg_active = false; state = prev_state


# ================= v19：光影精緻化 =================
func light_fallbacks() -> void:
	r_method = str(ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method"))
	if OS.has_feature("web"): r_method = "gl_compatibility"
	elif OS.has_feature("mobile") and r_method == "forward_plus": r_method = "mobile"
	if r_method != "forward_plus":
		# Mobile / Compatibility：關閉不支援或昂貴的效果，避免壞畫面
		sun.light_angular_distance = 0.0
		env.ssao_enabled = false
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
		env.glow_intensity = 0.45
		env.fog_height_density = 0.0
		if r_method == "gl_compatibility": sun.shadow_blur = 1.0

# ---------- v26：戰場後製（銳利化／調色／暈影）＋命中衝擊 ----------
const FX26 := preload("res://v26fx.gd")
var post_mat: ShaderMaterial
var punch_amt := 0.0
var punch_t0 := -100000
var punch_live := false
func build_post() -> void:
	if OS.get_environment("V26POST") == "off" or "--nopost" in OS.get_cmdline_user_args(): return
	var pl := CanvasLayer.new(); pl.layer = -1; add_child(pl)
	var pr := ColorRect.new(); pr.set_anchors_preset(Control.PRESET_FULL_RECT); pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_mat = FX26.mat(FX26.POST); pr.material = post_mat; pl.add_child(pr)
	if r_method == "gl_compatibility":
		# 網頁版不支援 Environment 調色：在後製補回對比與飽和，暗部略冷、亮部略暖
		post_mat.set_shader_parameter("contrast", 1.1); post_mat.set_shader_parameter("sat", 1.14)
		post_mat.set_shader_parameter("gain", Vector3(1.03, 1.0, 0.95)); post_mat.set_shader_parameter("lift", Vector3(0.0, 0.004, 0.018))
		post_mat.set_shader_parameter("sharpen", 0.32); post_mat.set_shader_parameter("vig", 0.16)
	else:
		post_mat.set_shader_parameter("sat", 1.04); post_mat.set_shader_parameter("sharpen", 0.22); post_mat.set_shader_parameter("vig", 0.1)

func screen_punch(wpos: Vector3, amt: float) -> void:
	if post_mat == null or cam == null: return
	var vs := get_viewport().get_visible_rect().size
	var sp := cam.unproject_position(wpos) / vs if not cam.is_position_behind(wpos) else Vector2(0.5, 0.5)
	post_mat.set_shader_parameter("punch_c", sp.clamp(Vector2(0.1, 0.1), Vector2(0.9, 0.9)))
	punch_amt = maxf(amt, punch_now()); punch_t0 = Time.get_ticks_msec()

func punch_now() -> float:
	var t := (Time.get_ticks_msec() - punch_t0) / 260.0
	return 0.0 if t >= 1.0 else punch_amt * (1.0 - t) * (1.0 - t)

func post_update() -> void:
	if post_mat == null: return
	var v := punch_now()
	if v > 0.0 or punch_live: post_mat.set_shader_parameter("punch", v)
	punch_live = v > 0.0

func fx_light(pos: Vector3, col: Color, energy: float, dur: float) -> void:
	var cap := 4 if r_method == "forward_plus" else 2
	if fx_lights.size() >= cap: return
	var l := OmniLight3D.new(); l.light_color = col.lightened(0.15); l.light_energy = energy; l.omni_range = 4.2; l.omni_attenuation = 1.6
	l.shadow_enabled = false; l.position = pos; add_child(l); fx_lights.append(l)
	var tw := create_tween(); tw.tween_property(l, "light_energy", 0.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): fx_lights.erase(l); l.queue_free())

func sprite_lighting(_dt: float) -> void:
	post_update()
	if cam == null or sun == null: return
	var cb: Basis = cam.global_transform.basis
	var L: Vector3 = sun.global_transform.basis.z.normalized()
	var sx := L.dot(cb.x); var sy := L.dot(cb.y)
	var rdir := Vector2(sx, -sy)
	rdir = rdir.normalized() if rdir.length() > 0.08 else Vector2(0, -1)
	var back := maxf(0.0, -L.dot(cb.z))
	var ef := clampf(sun.light_energy / 2.2, 0.15, 1.2)
	var rstr := clampf((0.22 + 0.5 * back + 0.15 * absf(sx)) * ef, 0.0, 0.75)
	var sc: Color = sun.light_color
	var rc := Vector3(sc.r, sc.g * 0.92, sc.b * 0.8)
	var ac: Color = env.ambient_light_color
	var mixc := Vector3(sc.r * 0.55 + ac.r * 0.45, sc.g * 0.55 + ac.g * 0.45, sc.b * 0.55 + ac.b * 0.45)
	var lm := maxf(0.05, mixc.x * 0.3 + mixc.y * 0.55 + mixc.z * 0.15)
	var amb := (Vector3.ONE).lerp(mixc / lm, 0.3)
	var lights: Array = []
	for t in torches: lights.append(t)
	for f in fx_lights: lights.append(f)
	for u in units:
		if not u.alive or u.smat == null: continue
		var sm: ShaderMaterial = u.smat
		sm.set_shader_parameter("amb", amb); sm.set_shader_parameter("rim_dir", rdir); sm.set_shader_parameter("rim_str", rstr); sm.set_shader_parameter("rim_col", rc)
		var pl := Vector3.ZERO; var pdx := 0.0
		var up: Vector3 = u.node.position + Vector3(0, 0.7, 0)
		for l in lights:
			if not is_instance_valid(l): continue
			var d: Vector3 = l.global_position - up
			var dist := d.length(); var rng: float = l.omni_range * 1.15
			if dist >= rng: continue
			var w: float = pow(1.0 - dist / rng, 2.0) * float(l.light_energy) * 0.22
			var lc: Color = l.light_color
			pl += Vector3(lc.r, lc.g, lc.b) * w; pdx += d.dot(cb.x) * w
		pl = pl.clamp(Vector3.ZERO, Vector3(0.7, 0.7, 0.7))
		sm.set_shader_parameter("plit", pl); sm.set_shader_parameter("plit_dir", signf(pdx))

# ================= v20：行動角色標示＋怒氣必殺技 =================
const RAGE_MAX := 100
const RAGE_KEYS := ["rain", "erin", "grey", "mira", "vig", "gard", "aurelia"]
# k: 名稱, 台詞, 顏色, 射程(0=自身), 範圍半徑, 倍率, 種類
const SPECIALS := {
	"rain": {"n": "黎明王道斬", "line": "以王者之名——黎明王道斬！", "col": Color(1.0, 0.82, 0.3), "rng": 1, "aoe": 1, "mult": 3.0, "kind": "dawn",
		"desc": "單體＋周圍1格 3.0倍聖光斬，命中後回復周圍2格我方 25% HP"},
	"erin": {"n": "疾風三連星", "line": "風啊，貫穿吧——疾風三連星！", "col": Color(0.45, 1.0, 0.55), "rng": 6, "aoe": 0, "mult": 1.35, "kind": "triple",
		"desc": "射程6 單體三連射（各 1.35倍，必中），每箭可爆擊"},
	"grey": {"n": "大地粉碎", "line": "大地啊，碎裂吧——大地粉碎！", "col": Color(1.0, 0.55, 0.2), "rng": 0, "aoe": 2, "mult": 2.2, "kind": "quake",
		"desc": "以自身為中心半徑2 範圍 2.2倍震擊，60% 暈眩"},
	"mira": {"n": "紅蓮鳳凰陣", "line": "浴火重生吧——紅蓮鳳凰陣！", "col": Color(1.0, 0.3, 0.15), "rng": 5, "aoe": 2, "mult": 2.4, "kind": "phoenix",
		"desc": "射程5 半徑2 範圍 2.4倍火焰魔法，附加灼燒"},
	"vig": {"n": "赤狼血月旋", "line": "血月之下，撕碎一切——赤狼血月旋！", "col": Color(1.0, 0.15, 0.2), "rng": 0, "aoe": 1, "mult": 2.6, "kind": "spin",
		"desc": "周圍1格全體 2.6倍旋斬，吸收 50% 傷害"},
	"gard": {"n": "冥獄斷罪劍", "line": "罪孽，由我來斷——冥獄斷罪劍！", "col": Color(0.7, 0.3, 1.0), "rng": 2, "aoe": 0, "mult": 4.2, "kind": "doom",
		"desc": "射程2 單體 4.2倍、無視防禦，自身獲得鐵壁"},
	"aurelia": {"n": "聖光審判", "line": "天上的光啊，降下審判——聖光審判！", "col": Color(1.0, 0.95, 0.7), "rng": 4, "aoe": 2, "mult": 2.0, "kind": "judge",
		"desc": "射程4 半徑2：敵人 2.0倍聖傷，我方回復 40% HP 並淨化"},
}
var act_fx: Node3D
var act_parts: GPUParticles3D
var act_pm: ParticleProcessMaterial
var act_arrow: Label3D
var act_unit = null
var special_casting := false
var ci_skip := false
var special_tested := {}
var rage_card_bar := {}

func has_rage(u) -> bool:
	return u.team == 0 and str(u.get("key", "")) in RAGE_KEYS and u.get("member") != null

func add_rage(u, v: int) -> void:
	if not has_rage(u) or not u.alive or special_casting: return
	var before := int(u.get("rage", 0))
	if before >= RAGE_MAX: return
	u.rage = mini(RAGE_MAX, before + v)
	update_rage(u)
	if u.rage >= RAGE_MAX:
		sfx("levelup", 0.0, -4.0); popup(u.node.position + Vector3(0, 0.8, 0), "怒氣 MAX！", Color(1, 0.55, 0.15), true)
		burst(u.node.position + Vector3(0, 0.8, 0), Color(1, 0.5, 0.15), 40, 4.0, "spark.png", 0.2, 0.7)
		log_msg("%s 的怒氣已滿！可使用必殺技「%s」" % [u.name, SPECIALS[u.key].n])

func rage_bar_make(u) -> void:
	if not has_rage(u) or u.has("ragebar"): return
	var bg := Sprite3D.new(); bg.texture = load("res://assets/ui/bar_bg.png"); bg.pixel_size = 0.009; bg.billboard = BaseMaterial3D.BILLBOARD_ENABLED; bg.no_depth_test = true; bg.render_priority = 1
	bg.centered = false; bg.offset = Vector2(-32, -8); bg.scale = Vector3(1, 0.38, 1); bg.position.y = -0.11
	u.hpbar_root.add_child(bg)
	var fg := Sprite3D.new(); fg.texture = load("res://assets/ui/bar_hp.png"); fg.pixel_size = 0.009; fg.modulate = Color(1.6, 0.6, 0.15)
	fg.billboard = BaseMaterial3D.BILLBOARD_ENABLED; fg.no_depth_test = true; fg.render_priority = 2
	fg.centered = false; fg.offset = Vector2(-31, -7); fg.region_enabled = true; fg.region_rect = Rect2(1, 1, 0, 14); fg.scale = Vector3(1, 0.38, 1); fg.position.y = -0.11
	u.hpbar_root.add_child(fg)
	u.ragebar = fg; u.ragebg = bg

func update_rage(u) -> void:
	if not u.has("ragebar"): return
	var r := clampf(float(u.get("rage", 0)) / RAGE_MAX, 0.0, 1.0)
	u.ragebar.region_rect = Rect2(1, 1, 62.0 * r, 14)
	if card.get("unit") == u: fill_rage_card(card, u)

func make_rage_row(c: Dictionary) -> void:
	var v: VBoxContainer = c.hp.fill.get_parent().get_parent().get_parent()
	var rb := make_bar(v, "bar_hp.png", "怒")
	rb.fill.tint_progress = Color(1.7, 0.65, 0.15)
	v.move_child(rb.fill.get_parent().get_parent(), c.mp.fill.get_parent().get_parent().get_index() + 1)
	c.rage = rb

func fill_rage_card(c: Dictionary, u) -> void:
	if not c.has("rage"): make_rage_row(c)
	var row: Control = c.rage.fill.get_parent().get_parent()
	row.visible = u != null and has_rage(u)
	if row.visible:
		set_bar(c.rage, int(u.get("rage", 0)), RAGE_MAX, true)
		var full: bool = int(u.get("rage", 0)) >= RAGE_MAX
		c.rage.val.text = "MAX!" if full else "%d/%d" % [int(u.rage), RAGE_MAX]
		c.rage.val.add_theme_color_override("font_color", Color(1, 0.6, 0.2) if full else Color(0.95, 0.9, 0.8))

func rage_tick(rd: float) -> void:
	for u in units:
		if u.has("ragebar") and u.alive:
			if int(u.get("rage", 0)) >= RAGE_MAX:
				var k := 0.5 + 0.5 * sin(t_elapsed * 7.0)
				u.ragebar.modulate = Color(1.6 + k, 0.6 + k * 0.8, 0.15 + k * 0.5)
			else: u.ragebar.modulate = Color(1.6, 0.6, 0.15)
	# 行動角色：輪廓呼吸、箭頭上下
	if act_unit != null and is_instance_valid(act_fx):
		if not act_unit.alive or state == "over": act_set(null); return
		act_fx.global_position = act_unit.node.position
		var top: float = act_unit.hpbar_root.position.y
		act_arrow.position.y = top + 0.55 + sin(t_elapsed * 5.0) * 0.08

func act_set(u) -> void:
	if act_unit != null and act_unit.has("smat"): act_unit.smat.set_shader_parameter("sel_col", Color(0, 0, 0, 0))
	act_unit = u
	if act_fx == null:
		act_fx = Node3D.new(); add_child(act_fx)
		act_parts = GPUParticles3D.new(); act_parts.amount = 36; act_parts.lifetime = 1.6
		act_pm = ParticleProcessMaterial.new()
		act_pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING; act_pm.emission_ring_radius = 0.5; act_pm.emission_ring_inner_radius = 0.32; act_pm.emission_ring_height = 0.6; act_pm.emission_ring_axis = Vector3.UP
		act_pm.gravity = Vector3(0, 0.9, 0); act_pm.initial_velocity_min = 0.15; act_pm.initial_velocity_max = 0.45; act_pm.direction = Vector3.UP; act_pm.spread = 12.0
		act_pm.scale_min = 0.6; act_pm.scale_max = 1.2
		act_parts.process_material = act_pm
		var q := quad(0.08, 0.08); q.material = particle_mat("spark.png", Color(1, 1, 1)); act_parts.draw_pass_1 = q
		act_parts.position.y = 0.45; act_fx.add_child(act_parts)
		act_arrow = Label3D.new(); act_arrow.font = font_bold; act_arrow.text = "▼"; act_arrow.font_size = 64; act_arrow.pixel_size = 0.005; act_arrow.outline_size = 14
		act_arrow.billboard = BaseMaterial3D.BILLBOARD_ENABLED; act_arrow.no_depth_test = true; act_arrow.render_priority = 6; act_arrow.outline_render_priority = 5
		act_fx.add_child(act_arrow)
	if u == null:
		act_fx.visible = false; act_parts.emitting = false; return
	var ally: bool = u.team == 0
	var col := Color(1.0, 0.85, 0.35) if ally else Color(1.0, 0.18, 0.12)
	u.smat.set_shader_parameter("sel_col", Color(col.r, col.g, col.b, 1.0) if ally else Color(1.0, 0.22, 0.15, 1.0))
	var g := Gradient.new(); g.set_color(0, Color(1, 1, 0.9, 1) if ally else Color(1, 0.6, 0.5, 1)); g.set_color(1, Color(col.r, col.g, col.b, 0))
	var gt := GradientTexture1D.new(); gt.gradient = g; act_pm.color_ramp = gt
	act_pm.color = col
	var sc: float = float(u.get("scl", 1.0)) * (1.6 if u.get("big", false) else 1.0)
	act_pm.emission_ring_radius = 0.5 * sc; act_pm.emission_ring_inner_radius = 0.32 * sc
	act_arrow.modulate = Color(1.0, 0.9, 0.45) if ally else Color(1.0, 0.3, 0.22); act_arrow.outline_modulate = Color(0.25, 0.12, 0.0) if ally else Color(0.25, 0.0, 0.0)
	act_fx.visible = true; act_parts.emitting = true; act_parts.restart()
	act_fx.global_position = u.node.position

# ---- 選單 / 目標 ----
func special_cells(u) -> Array:
	var sp: Dictionary = SPECIALS[u.key]
	var out := []
	for c in heights:
		if mdist(c, u.cell) <= int(sp.rng): out.append(c)
	return out

func special_area(u, c: Vector2i) -> Array:
	var sp: Dictionary = SPECIALS[u.key]
	var ctr: Vector2i = u.cell if int(sp.rng) == 0 else c
	var out := []
	for k in heights:
		if mdist(k, ctr) <= int(sp.aoe): out.append(k)
	return out

func special_targets(u, c: Vector2i) -> Array:
	var out := []
	for a in special_area(u, c):
		var t = unit_at(a)
		if t != null and t.alive and t.team != u.team: out.append(t)
	return out

func cmd_special() -> void:
	var sp: Dictionary = SPECIALS[cur.key]
	hide_menu()
	if int(sp.rng) == 0:
		show_hl(special_area(cur, cur.cell), Color(sp.col.r, sp.col.g, sp.col.b, 0.45))
	else:
		show_hl(special_cells(cur), Color(sp.col.r, sp.col.g, sp.col.b, 0.35))
	state = "special"
	log_msg("必殺技「%s」：%s（選擇目標）" % [sp.n, sp.desc])

func special_valid(u, c: Vector2i) -> bool:
	var sp: Dictionary = SPECIALS[u.key]
	if int(sp.rng) == 0: return hl_cells.has(c) and not special_targets(u, c).is_empty()
	return hl_cells.has(c) and not special_targets(u, c).is_empty()

func special_hover(c: Vector2i) -> void:
	clear_aoe()
	var sp: Dictionary = SPECIALS[cur.key]
	for a in special_area(cur, c): aoe_nodes.append(hl_quad(a, Color(sp.col.r, sp.col.g, sp.col.b, 0.55)))
	tcard.panel.visible = true
	fill_card(tcard, unit_at(c) if unit_at(c) != null else cur, "▶ 必殺・%s\n%s　目標 %d 名" % [sp.n, sp.desc, special_targets(cur, c).size()])

func special_plan(u):
	if int(u.get("rage", 0)) < RAGE_MAX or not SPECIALS.has(u.key): return null
	var sp: Dictionary = SPECIALS[u.key]
	var r := reachable(u) if not moved and not u.status.has("root") else {"ends": [u.cell], "parent": {u.cell: u.cell}}
	var best = null; var bsc := 0.0
	for mc in r.ends:
		var oc: Vector2i = u.cell
		u.cell = mc
		var cs: Array = [mc] if int(sp.rng) == 0 else special_cells(u)
		for c in cs:
			var sc := 0.0
			for t in special_targets(u, c):
				if t.cell == mc: continue
				sc += 30.0 + (25.0 if t.boss else 0.0) + (15.0 if t.hp < st(t, "hp") / 2 else 0.0)
			if sc > bsc: bsc = sc; best = {"move": mc, "cell": c}
		u.cell = oc
	return best

# ---- 施放 ----
func do_special(u, c: Vector2i) -> void:
	var sp: Dictionary = SPECIALS[u.key]
	var col: Color = sp.col
	special_casting = true
	u.rage = 0; update_rage(u)
	var tg := special_targets(u, c)
	if not tg.is_empty(): face(u, tg[0].node.position)
	await cutin(u)
	skill_banner("必殺・" + sp.n, col)
	log_msg("%s 施放必殺技「%s」！" % [u.name, sp.n])
	print("SPECIAL OK name=", sp.n, " unit=", u.key, " targets=", tg.size(), " battle=", bidx + 1)
	var pos0: Vector3 = u.node.position
	var kills := 0
	match sp.kind:
		"dawn":
			play(u, "Spellcasting", 0.05); flipbook(pos0 + Vector3(0, 1.0, 0), "cast", 2.2, 0.7, col); sfx("magic", 0.0, -4.0)
			var tw := create_tween(); tw.tween_property(u.body, "position:y", 1.1, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			await wait(0.45)
			for i in 3: burst(u.node.position + Vector3(0, 2.0, 0), col, 30, 3.0, "spark.png", 0.22, 0.5, 0.0)
			var tp: Vector3 = tg[0].node.position if not tg.is_empty() else pos0
			play(u, "Attack", 0.02, 1.4)
			var tw2 := create_tween().set_parallel(); tw2.tween_property(u.body, "position:y", 0.0, 0.18).set_ease(Tween.EASE_IN)
			tw2.tween_property(u.node, "position", pos0 + (tp - pos0) * 0.45, 0.18)
			await wait(0.2)
			sfx("crit", 0.0, -2.0); shake = 0.9; flash.color = Color(1, 0.92, 0.6, 0.45); create_tween().tween_property(flash, "color:a", 0.0, 0.5)
			for t in tg:
				flipbook(t.node.position + Vector3(0, 1.2, 0), "heal", 3.0, 0.8, col)
				light_pillar(t.node.position, col, 0.9)
		"triple":
			for i in 3:
				play(u, "Attack", 0.02, 1.6); sfx("bow", 0.1, -3.0)
				if not tg.is_empty() and tg[0].alive: await projectile(u, tg[0], false)
				if not tg.is_empty(): burst(tg[0].node.position + Vector3(0, 0.7, 0), col, 30, 6.0, "spark.png", 0.2, 0.5)
				await wait(0.08)
			if not tg.is_empty(): flipbook(tg[0].node.position + Vector3(0, 0.8, 0), "wind", 2.6, 0.7, Color(1, 1, 1))
		"quake":
			play(u, "Spellcasting", 0.05)
			var tw := create_tween(); tw.tween_property(u.body, "position:y", 1.6, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tw.tween_property(u.body, "position:y", 0.0, 0.14).set_ease(Tween.EASE_IN)
			await wait(0.38); play(u, "Attack", 0.02, 1.8); await wait(0.12)
			sfx("explode", 0.0, -2.0); shake = 1.2
			for r in 3: spec_ring(pos0, col, 0.6 + r * 1.0, 0.5 + r * 0.12)
			for a in special_area(u, c): flipbook(cell_pos(a) + Vector3(0, 0.55, 0), "earth", 1.5, 0.6)
		"phoenix":
			play(u, "Spellcasting", 0.05); sfx("summon", 0.0, -4.0)
			var mc := magic_circle(cell_pos(c) + Vector3(0, 0.06, 0), 2.6, col)
			var mc2 := magic_circle(pos0 + Vector3(0, 0.05, 0), 1.0, col)
			await wait(0.6)
			burst(pos0 + Vector3(0, 1.5, 0), col, 70, 3.0, "spark.png", 0.3, 0.9, 0.0)
			var fly := Node3D.new(); add_child(fly); fly.position = pos0 + Vector3(0, 2.5, 0)
			var tw := create_tween(); tw.tween_property(fly, "position", cell_pos(c) + Vector3(0, 0.8, 0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			for k in 6: get_tree().create_timer(k * 0.07).timeout.connect(func(): if is_instance_valid(fly): flipbook(fly.position, "fire", 1.6, 0.4))
			await wait(0.47); fly.queue_free()
			sfx("explode", 0.0, -1.0); shake = 1.0
			for a in special_area(u, c): flipbook(cell_pos(a) + Vector3(0, 0.8, 0), "fire", 2.0, 0.7)
			light_pillar(cell_pos(c), col, 1.0)
			mc.queue_free(); mc2.queue_free()
		"spin":
			play(u, "Attack", 0.02, 2.0)
			var tw := create_tween(); tw.tween_method(func(v): u.node.rotation.y = v, u.node.rotation.y, u.node.rotation.y + TAU * 3.0, 0.7)
			for k in 4: get_tree().create_timer(k * 0.17).timeout.connect(func(): sfx("slash", 0.15, -3.0); spec_ring(u.node.position + Vector3(0, 0.6, 0), col, 1.6, 0.25))
			await wait(0.72)
			shake = 0.8
			for t in tg: burst(t.node.position + Vector3(0, 0.7, 0), col, 40, 5.0, "spark.png", 0.22, 0.6)
		"doom":
			play(u, "Spellcasting", 0.05); sfx("magic", 0.0, -3.0)
			burst(pos0 + Vector3(0, 0.6, 0), col, 60, 1.5, "spark.png", 0.25, 0.9, 1.5)
			flash.color = Color(0.1, 0.0, 0.15, 0.5); create_tween().tween_property(flash, "color:a", 0.0, 0.9)
			await wait(0.5)
			var tp: Vector3 = tg[0].node.position if not tg.is_empty() else pos0
			play(u, "Attack", 0.02, 1.2)
			var tw := create_tween(); tw.tween_property(u.node, "position", pos0 + (tp - pos0) * 0.6, 0.12)
			await wait(0.18)
			sfx("crit", 0.0, -1.0); shake = 1.1
			for t in tg:
				light_pillar(t.node.position, col, 1.2)
				slash_trail(u, t, col, true)
		"judge":
			play(u, "Spellcasting", 0.05); sfx("heal", 0.0, -3.0)
			var mc := magic_circle(cell_pos(c) + Vector3(0, 0.06, 0), 2.6, col)
			await wait(0.55)
			sfx("explode", 0.0, -4.0); shake = 0.7
			for a in special_area(u, c):
				light_pillar(cell_pos(a), col, 0.8)
			flash.color = Color(1, 1, 0.9, 0.5); create_tween().tween_property(flash, "color:a", 0.0, 0.6)
			mc.queue_free()
	await wait(0.15)
	# ---- 傷害 ----
	for t in tg:
		if not t.alive: continue
		var hits := 3 if sp.kind == "triple" else 1
		for h in hits:
			if not t.alive: break
			var pierce := 100 if sp.kind == "doom" else 0
			var dm := special_dmg(u, t, sp)
			if sp.kind == "triple" and randi() % 100 < calc(u, t, u.cell).crit: dm = int(dm * 1.5); popup(t.node.position + Vector3(0, 0.75 + 0.3 * G.font_k(), 0), "CRITICAL!", Color(1, 0.85, 0.2))
			t.hp = maxi(0, t.hp - dm); track_dmg(u, t, dm)
			hit_flash(t, col); play(t, "Hit_B", 0.05); voice(t, "hurt", "")
			popup(t.node.position + Vector3(0, h * 0.25, 0), str(dm), col.lightened(0.25), true)
			log_msg("「%s」對 %s 造成 %d 傷害" % [sp.n, t.name, dm])
			if sp.kind == "spin":
				var hv := maxi(1, dm / 2); u.hp = mini(st(u, "hp"), u.hp + hv); popup(u.node.position, "+%d" % hv, Color(0.5, 1, 0.5))
			update_label(t)
			if t.hp <= 0: kill(t); kills += 1
			if hits > 1: await wait(0.12)
		if t.alive:
			after_damage(t)
			if sp.kind == "quake" and randi() % 100 < 60 and set_status(t, "stun", 1): popup(t.node.position + Vector3(0, 0.5, 0), "暈眩", Color(1, 1, 0.4))
			if sp.kind == "phoenix": apply_status(t, "burn", 100)
			var tt = t
			get_tree().create_timer(0.7).timeout.connect(func(): if tt.alive: play(tt, idle_anim(tt), 0.3))
	if sp.kind == "dawn" or sp.kind == "judge":
		var ctr: Vector2i = u.cell if sp.kind == "dawn" else c
		var rr := 2
		for o in alive_team(u.team):
			if mdist(o.cell, ctr) > rr: continue
			var amt := mini(int(st(o, "hp") * (0.25 if sp.kind == "dawn" else 0.4)), st(o, "hp") - o.hp)
			if sp.kind == "judge":
				for k in ["burn", "slow", "freeze", "root", "poison", "stun"]: o.status.erase(k)
			if amt > 0:
				o.hp += amt; track_heal(u, amt); popup(o.node.position, "+%d" % amt, Color(0.4, 1.0, 0.5), true)
			update_label(o)
	if sp.kind == "doom":
		u.status["shield"] = int(STAT_DUR.get("shield", 2)); popup(u.node.position, STAT_INFO["shield"][0], STAT_INFO["shield"][2], true); update_label(u)
	# 歸位
	var bt := create_tween(); bt.tween_property(u.node, "position", cell_pos(u.cell), 0.25)
	u.body.position.y = 0.0
	if sp.kind == "spin": u.node.rotation.y = fmod(u.node.rotation.y, TAU)
	await wait(0.7)
	skill_banner_end()
	play(u, idle_anim(u), 0.2)
	fill_card(card, u)
	special_casting = false
	if do_shots and not special_tested.has("shot"):
		special_tested["shot"] = true
	if u.team == 0 and u.alive: await grant_exp(u, 16 + kills * 22)

func special_dmg(u, t, sp: Dictionary) -> int:
	var p := calc(u, t, u.cell)
	var base: float = float(p.dmg)
	if sp.kind == "phoenix" or sp.kind == "judge":
		base = maxf(base, st(u, "mag") * 1.3 - st(t, "def") * 0.3)
	if sp.kind == "doom":
		base = float(st(u, "atk")) * 1.0
	var dm := int(base * float(sp.mult) * randf_range(0.94, 1.06))
	if t.boss: dm = int(dm * 0.8)
	return maxi(1, dm)

func light_pillar(pos: Vector3, col: Color, dur: float) -> void:
	var m := MeshInstance3D.new(); var cy := CylinderMesh.new(); cy.top_radius = 0.42; cy.bottom_radius = 0.5; cy.height = 6.0; cy.cap_top = false; cy.cap_bottom = false
	m.mesh = cy; m.material_override = glow(col, 0.55, 4.0); m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position = pos + Vector3(0, 3.0, 0); m.scale = Vector3(0.1, 1, 0.1); add_child(m)
	var tw := create_tween(); tw.tween_property(m, "scale", Vector3(1.2, 1, 1.2), 0.12).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "scale", Vector3(0.02, 1, 0.02), dur).set_ease(Tween.EASE_IN)
	tw.tween_callback(m.queue_free)
	var l := OmniLight3D.new(); l.light_color = col; l.light_energy = 4.0; l.omni_range = 5.0; l.position = pos + Vector3(0, 1.2, 0); add_child(l); fx_lights.append(l)
	var lt := create_tween(); lt.tween_property(l, "light_energy", 0.0, dur + 0.2); lt.tween_callback(func(): fx_lights.erase(l); l.queue_free())

func spec_ring(pos: Vector3, col: Color, r: float, dur: float) -> void:
	var m := MeshInstance3D.new(); var tor := TorusMesh.new(); tor.inner_radius = 0.85; tor.outer_radius = 1.0; tor.rings = 32
	m.mesh = tor; m.material_override = glow(col, 0.75, 4.0); m.scale = Vector3(0.1, 0.1, 0.1); m.position = pos + Vector3(0, 0.1, 0)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(m)
	var tw := create_tween().set_parallel(); tw.tween_property(m, "scale", Vector3(r, 0.3, r), dur).set_ease(Tween.EASE_OUT)
	tw.tween_property(m.material_override, "albedo_color:a", 0.0, dur)
	tw.chain().tween_callback(m.queue_free)

# ---- 2D 必殺 cut-in ----
const SPEED_SH := """shader_type canvas_item;
uniform vec4 col : source_color = vec4(1.0);
float h(float x) { return fract(sin(x * 91.7) * 43758.5); }
void fragment() {
	float row = floor(UV.y * 70.0);
	float sp = 2.5 + h(row) * 4.0;
	float x = fract(UV.x * 0.6 - TIME * sp * 0.35 + h(row + 3.0));
	float len = 0.25 + h(row + 7.0) * 0.45;
	float a = smoothstep(0.0, 0.02, x) * (1.0 - smoothstep(len * 0.5, len, x)) * step(0.55, h(row + 11.0));
	COLOR = vec4(col.rgb, a * col.a);
}
"""
func cutin(u) -> void:
	var sp: Dictionary = SPECIALS[u.key]
	var col: Color = sp.col
	ci_skip = false
	var vp := get_viewport().get_visible_rect().size
	var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_STOP
	var cl := CanvasLayer.new(); cl.layer = 20; add_child(cl); cl.add_child(root)
	root.gui_input.connect(func(e): if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed: ci_skip = true)
	var dark := ColorRect.new(); dark.color = Color(0, 0, 0, 0); dark.set_anchors_preset(Control.PRESET_FULL_RECT); dark.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(dark)
	# 斜帶
	var band := Control.new(); band.clip_contents = true; band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bh := vp.y * 0.56
	band.size = Vector2(vp.x * 1.5, bh); band.pivot_offset = band.size * 0.5
	band.position = Vector2(-vp.x * 0.25, vp.y * 0.5 - bh * 0.5); band.rotation = deg_to_rad(-7.0)
	root.add_child(band)
	var bbg := ColorRect.new(); bbg.color = Color(col.r * 0.22, col.g * 0.16, col.b * 0.12, 0.96); bbg.set_anchors_preset(Control.PRESET_FULL_RECT); bbg.mouse_filter = Control.MOUSE_FILTER_IGNORE; band.add_child(bbg)
	var spd := ColorRect.new(); spd.set_anchors_preset(Control.PRESET_FULL_RECT); spd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new(); var sh := Shader.new(); sh.code = SPEED_SH; sm.shader = sh; sm.set_shader_parameter("col", Color(col.r, col.g, col.b, 0.75)); spd.material = sm; band.add_child(spd)
	for e in [0.0, 1.0]:
		var edge := ColorRect.new(); edge.color = Color(col.r, col.g, col.b, 1.0); edge.size = Vector2(band.size.x, 6); edge.position = Vector2(0, e * (bh - 6)); edge.mouse_filter = Control.MOUSE_FILTER_IGNORE; band.add_child(edge)
	var art := TextureRect.new(); art.texture = load("res://assets/v20/ci_%s.jpg" % u.key); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var aw := bh * 1.15; art.size = Vector2(aw, aw * 4.0 / 3.0)
	var ax := vp.x * 0.25 + vp.x * 0.12; art.position = Vector2(-aw - 50.0, -art.size.y * 0.16)
	band.add_child(art)
	var shine := ColorRect.new(); shine.color = Color(1, 1, 1, 0.0); shine.set_anchors_preset(Control.PRESET_FULL_RECT); shine.mouse_filter = Control.MOUSE_FILTER_IGNORE; band.add_child(shine)
	var nm := lbl(sp.n, 92, Color(1, 0.97, 0.88), true); nm.add_theme_color_override("font_outline_color", Color(col.r * 0.5, col.g * 0.25, col.b * 0.15)); nm.add_theme_constant_override("outline_size", 22)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nm.position = Vector2(vp.x + 40, vp.y * 0.5 - 10); nm.rotation = deg_to_rad(-7.0); root.add_child(nm)
	var ln := lbl("「" + sp.line + "」", 30, Color(1, 0.9, 0.7), true); ln.add_theme_constant_override("outline_size", 10); ln.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	ln.mouse_filter = Control.MOUSE_FILTER_IGNORE; ln.position = Vector2(vp.x * 0.42, vp.y * 0.5 + 100); ln.rotation = deg_to_rad(-7.0); ln.modulate.a = 0.0; root.add_child(ln)
	var who := lbl(u.name, 40, Color(col.r, col.g, col.b), true); who.add_theme_constant_override("outline_size", 12); who.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	who.mouse_filter = Control.MOUSE_FILTER_IGNORE; who.position = Vector2(vp.x * 0.44, vp.y * 0.5 - 110); who.rotation = deg_to_rad(-7.0); who.modulate.a = 0.0; root.add_child(who)
	var skp := lbl("點擊畫面略過 ▶▶", 20, Color(1, 1, 1, 0.7)); skp.position = Vector2(vp.x - 230, vp.y - 50); skp.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(skp)
	sfx("crit", 0.0, -6.0); sfx("summon", 0.0, -8.0)
	var t0 := create_tween().set_parallel()
	t0.tween_property(dark, "color:a", 0.72, 0.2)
	band.scale = Vector2(1, 0.02); t0.tween_property(band, "scale", Vector2(1, 1), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t0.tween_property(art, "position:x", ax, 0.32).set_delay(0.08).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t0.tween_property(nm, "position:x", vp.x * 0.42, 0.28).set_delay(0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t0.tween_property(who, "modulate:a", 1.0, 0.2).set_delay(0.3)
	t0.tween_property(ln, "modulate:a", 1.0, 0.25).set_delay(0.45)
	t0.tween_property(shine, "color:a", 0.55, 0.06).set_delay(0.4)
	t0.tween_property(shine, "color:a", 0.0, 0.3).set_delay(0.46)
	t0.tween_property(art, "position:x", ax + 60.0, 2.0).set_delay(0.4)
	get_tree().create_timer(0.3).timeout.connect(func(): voice_line(u.key))
	# 自動測試：首次完整播放（截圖），之後 0.8 秒自動略過以驗證略過路徑
	var full := 2.6
	var auto_skip := -1.0
	if autotest:
		if special_tested.has("cutin_full"): auto_skip = 0.8
		special_tested["cutin_full"] = true
	var t := 0.0
	var shot_done := false
	while t < full:
		await get_tree().process_frame
		t += get_process_delta_time() / maxf(Engine.time_scale, 0.01)
		if do_shots and not shot_done and t > 1.0:
			shot_done = true; await shot("05_cutin_%s" % u.key)
		if auto_skip > 0.0 and t > auto_skip: ci_skip = true
		if ci_skip:
			print("CUTIN SKIPPED unit=", u.key, " at=", snappedf(t, 0.01)); break
	var t1 := create_tween().set_parallel()
	t1.tween_property(root, "modulate:a", 0.0, 0.18)
	await t1.finished
	cl.queue_free()

func voice_line(key: String) -> void:
	if G.voice_vol <= 0.01: return
	var path := "res://assets/v20/vo/sp_%s.ogg" % key
	if not ResourceLoader.exists(path): return
	var p := AudioStreamPlayer.new(); add_child(p); p.stream = load(path); p.volume_db = linear_to_db(G.voice_vol) + 1.0; p.play()
	p.finished.connect(p.queue_free)


# ---------------- v22：觸控自動測試（模擬手指事件） ----------------
var touch_test := false
var tt_fail := 0
func tt_ok(name: String, ok: bool) -> void:
	print("TOUCHTEST ", "OK   " if ok else "FAIL ", name)
	if not ok: tt_fail += 1
func tt_win(vp: Vector2) -> Vector2:
	return get_viewport().get_screen_transform() * vp
func tt_touch(i: int, down: bool, vp: Vector2) -> void:
	var e := InputEventScreenTouch.new(); e.index = i; e.pressed = down; e.position = tt_win(vp); Input.parse_input_event(e)
	await get_tree().process_frame; await get_tree().process_frame
func tt_drag(i: int, vp: Vector2, rel: Vector2) -> void:
	var e := InputEventScreenDrag.new(); e.index = i; e.position = tt_win(vp); e.relative = rel * get_viewport().get_screen_transform().get_scale(); Input.parse_input_event(e)
	await get_tree().process_frame
func tt_tap(vp: Vector2) -> void:
	await tt_touch(0, true, vp); await wait(0.08); await tt_touch(0, false, vp); await wait(0.15)
func tt_cell(c: Vector2i) -> Vector2:
	return cam.unproject_position(cell_pos(c) + Vector3(0, 0.05, 0))
func tt_wait_menu() -> void:
	var t1 := t_elapsed
	while state != "menu" and t_elapsed - t1 < 10: await wait(0.1)

func run_touchtest() -> void:
	set_touch_mode(true); base_ts = 1.0; Engine.time_scale = 1.0
	open_equip(players(), true); await wait(0.5); close_equip()
	print("TOUCHTEST start win=", DisplayServer.window_get_size(), " slop=", slop())
	var t0 := t_elapsed
	while not (state == "menu" and cur != null and cur.team == 0):
		await wait(0.2)
		if int(t_elapsed * 5) % 25 == 0: print("TT wait state=", state, " cur=", (cur.name if cur != null else "-"), " t=", t_elapsed)
		if t_elapsed - t0 > 120: tt_ok("reach player menu", false); get_tree().quit(1); return
	await wait(1.0)
	cam_lock = true
	await shot("t01_menu_touchbar")
	await wait(0.4)
	print("TT rects menu=", menu_panel.get_global_rect(), " bar=", touch_bar.get_global_rect())
	tt_ok("menu shifted left of touch bar", menu_panel.get_global_rect().end.x <= touch_bar.get_global_rect().position.x + 1)
	var start: Vector2i = cur.cell
	cmd_move(); await wait(0.6)
	var ends: Array = reach.ends.filter(func(c): var q := cam.unproject_position(cell_pos(c)); return mdist(c, start) >= 2 and q.x > 300 and q.x < 1250 and q.y > 120 and q.y < 800)
	tt_ok("has move targets", ends.size() >= 2)
	if ends.size() < 2: get_tree().quit(1); return
	var tgt: Vector2i = ends[0]; var alt: Vector2i = ends[ends.size() - 1]
	await tt_tap(tt_cell(tgt))
	tt_ok("1st tap = preview only (no move)", cur.cell == start and pend_cell == tgt and path_nodes.size() >= 2 and not confirm_btn.disabled)
	await shot("t02_path_preview")
	await tt_tap(tt_cell(alt))
	tt_ok("tap other cell re-targets preview", cur.cell == start and pend_cell == alt)
	await tt_tap(tt_cell(alt) + Vector2(6, 4))
	await tt_wait_menu()
	tt_ok("2nd tap executes move", cur.cell == alt and moved)
	await wait(0.5)
	var has_undo := false
	for b in menu_box.get_children(): if b is Button and b.text == "移動復原": has_undo = true
	tt_ok("menu offers 移動復原", has_undo)
	await shot("t03_after_move_undo_menu")
	cmd_undo(); await wait(0.4)
	tt_ok("undo returns to start", cur.cell == start and not moved)
	cmd_move(); await wait(0.4)
	await tt_tap(tt_cell(tgt)); confirm_btn.emit_signal("pressed")
	await tt_wait_menu()
	tt_ok("確定 button executes", cur.cell == tgt)
	cmd_undo(); await wait(0.3)
	var en = null
	for u in units:
		var q := cam.unproject_position(u.node.position)
		if u != cur and u.hp > 0 and q.x > 100 and q.x < 1250 and q.y > 100 and q.y < 800: en = u; break
	tt_ok("found a unit to long-press", en != null)
	if en != null:
		cmd_move(); await wait(0.3)
		var p := cam.unproject_position(en.node.position + Vector3(0, 0.6, 0))
		await tt_touch(0, true, p); await wait(0.7)
		tt_ok("long-press shows info card", tcard.panel.visible and lp_done)
		await shot("t04_longpress_info")
		await tt_touch(0, false, p); await wait(0.2)
		tt_ok("long-press release does not act", cur.cell == start and state == "move" and pend_cell.x < 0)
		cancel(); await wait(0.2)
	cam_lock = false
	cmd_move(); await wait(0.3)
	var cp := cam_pivot.position
	var a := tt_cell(tgt)
	lp_ms = 60000   # 軟體算圖幀率很低，避免測試時誤觸發長按
	await tt_touch(0, true, a); await tt_drag(0, a + Vector2(8, 5), Vector2(8, 5)); await tt_touch(0, false, a + Vector2(8, 5)); await wait(0.15)
	print("TT jitter pend=", pend_cell, " tgt=", tgt, " drag=", t_dragged, " lp=", lp_done, " state=", state, " pick=", pick(a))
	tt_ok("jitter < slop still a tap", pend_cell == tgt)
	clear_pending()
	await tt_touch(0, true, a)
	for k in 12: await tt_drag(0, a + Vector2(10 * (k + 1), 0), Vector2(10, 0))
	await tt_touch(0, false, a + Vector2(120, 0)); await wait(0.2)
	tt_ok("drag pans camera, no tap", cam_pivot.position.distance_to(cp) > 0.3 and pend_cell.x < 0 and cur.cell == start)
	var c0 := Vector2(700, 450); var d0 := target_dist; var y0 := target_yaw
	await tt_touch(0, true, c0 + Vector2(-100, 0)); await tt_touch(1, true, c0 + Vector2(100, 0))
	for k in 10: await tt_drag(1, c0 + Vector2(100 + 8 * (k + 1), 0), Vector2(8, 0))
	tt_ok("pinch zooms", target_dist < d0 - 0.5)
	for k in 8: await tt_drag(1, c0 + Vector2(-100, 0) + Vector2(280, 0).rotated((k + 1) * 0.1), Vector2.ZERO)
	tt_ok("twist rotates 90°", absf(target_yaw - y0) == 90.0)
	await tt_touch(1, false, c0); cp = cam_pivot.position
	for k in 5: await tt_drag(0, c0 + Vector2(-100 - 20 * k, 0), Vector2(-20, 0))
	await tt_touch(0, false, c0)
	tt_ok("no camera jump after lifting one finger", cam_pivot.position.distance_to(cp) < 0.01)
	cancel(); await wait(1.0)
	await shot("t05_after_gestures")
	var ts := base_ts
	speed_btn.emit_signal("pressed")
	tt_ok("speed toggle x2", base_ts == 2.0 and Engine.time_scale == 2.0 and speed_btn.text.contains("×2"))
	speed_btn.emit_signal("pressed")
	tt_ok("speed toggle back", base_ts == 1.0)
	print("TOUCHTEST DONE fails=", tt_fail)
	get_tree().quit(1 if tt_fail > 0 else 0)


# =====================================================================
# v23：倒地倒數／復活／新法術／特殊劇情／傳說裝備／第三召喚獸／地圖規模與聚落
# =====================================================================
const DOWN_TURNS := 3
var round_no := 0
var ev := {}            # 本戰特殊劇情定義
var ev_state := {}      # done / failed / triggered
var ev_nodes: Array = []
var ev_cell := Vector2i(-1, -1)
var learned_shown := {}
var form := {}
var flag_cell := Vector2i(-1, -1)
var flag_taken := false
var flag_nodes := {}
var reinf_done := false

# ---------- 地圖規模（各戰不同） ----------
func map_k() -> float: return maxf(W / 12.0, H / 10.0)
func zmax() -> float: return 40.0 * maxf(1.0, map_k())
func cam_lim() -> float: return maxf(9.0, maxf(W, H) / 2.0 + 1.5)

# ---------- 倒地倒數 ----------
func down_start(u) -> void:
	if u.team != 0 or u.get("gone", false): return
	u.down_t = DOWN_TURNS; u.ct = 0
	var n := Node3D.new(); n.position = cell_pos(u.cell) + Vector3(0, 0.04, 0); add_child(n)
	var ring := mi(n, cyl(0.42, 0.42, 0.02, 32), Vector3.ZERO, glow(Color(1.0, 0.75, 0.3), 0.55, 3.0))
	var rt := ring.create_tween().set_loops(); rt.tween_property(ring, "scale", Vector3(1.12, 1, 1.12), 0.7); rt.tween_property(ring, "scale", Vector3.ONE, 0.7)
	var fl := fire_particles(Vector3.ZERO, 10, 0.15, 0.6); fl.reparent(n, false); fl.position = Vector3(0, 0.25, 0)
	(fl.process_material as ParticleProcessMaterial).color_ramp = null; (fl.process_material as ParticleProcessMaterial).color = Color(1.0, 0.85, 0.5, 0.9)
	var l := Label3D.new(); l.font = font_bold; l.font_size = 46; l.pixel_size = 0.0045 * G.font_k(); l.outline_size = 12
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.no_depth_test = true; l.render_priority = 4; l.position = Vector3(0, 0.95, 0)
	l.modulate = Color(1, 0.9, 0.55); l.outline_modulate = Color(0.25, 0.08, 0.02); n.add_child(l)
	u.down_node = n; u.down_lbl = l
	down_refresh(u)
	log_msg("%s 倒地！%d 回合內可用復活道具或復活術救回" % [u.name, DOWN_TURNS])

func down_refresh(u) -> void:
	if u.get("down_lbl") != null: u.down_lbl.text = "倒地 %d" % int(u.down_t)

func down_tick(u) -> void:
	u.down_t = int(u.down_t) - 1
	if int(u.down_t) > 0:
		down_refresh(u)
		if u.down_lbl != null: popup(u.down_node.position + Vector3(0, 0.6, 0), "剩 %d 回合" % int(u.down_t), Color(1, 0.75, 0.4))
		return
	u.gone = true
	log_msg("%s 力竭撤離戰場（本戰無法再復活，戰後歸隊）" % u.name)
	if u.get("down_node") != null:
		popup(u.down_node.position + Vector3(0, 0.6, 0), "撤離", Color(0.75, 0.75, 0.9), true)
		burst(u.down_node.position + Vector3(0, 0.4, 0), Color(0.8, 0.8, 1.0, 0.7), 24, 2.0, "glow.png", 0.25, 1.2, 0.5)
		var nd: Node3D = u.down_node; u.down_node = null; u.down_lbl = null
		var tw := create_tween(); tw.tween_property(nd, "scale", Vector3(0.01, 0.01, 0.01), 0.6); tw.tween_callback(nd.queue_free)

func down_clear(u) -> void:
	u.down_t = 0
	if u.get("down_node") != null: (u.down_node as Node3D).queue_free(); u.down_node = null; u.down_lbl = null

func revive_unit(o, pct: int, src := "") -> void:
	down_clear(o)
	o.alive = true; o.hp = maxi(1, st(o, "hp") * pct / 100); o.status = {}
	o.node.visible = true; o.node.scale = Vector3.ONE; o.node.position = cell_pos(o.cell); set_flash(o, Color(0, 0, 0, 0))
	o.label.visible = true; o.hpbar_root.visible = true; o.ring.material_override.albedo_color.a = 0.45
	if o.has("sicons"): o.sicons.visible = true
	o.ct = 50
	play(o, idle_anim(o), 0.2); popup(o.node.position, "復活！", Color(1, 0.9, 0.5), true)
	light_pillar(o.node.position, Color(1, 0.9, 0.55), 1.2)
	burst(o.node.position + Vector3(0, 0.3, 0), Color(1, 0.85, 0.5), 50, 3.0, "spark.png", 0.2, 1.2, -1.0, 40.0, Vector3.UP)
	log_msg("%s 復活了！（HP %d%%%s）" % [o.name, pct, "・" + src if src != "" else ""])
	update_label(o)

func downed_allies(team: int) -> Array:
	return units.filter(func(o): return o.team == team and not o.alive and int(o.get("down_t", 0)) > 0 and not o.get("gone", false))

# ---------- 新法術（含天候共鳴） ----------
const SPELLS23 := [
	{"n": "沉默術", "el": "wind", "k": "debuff", "pw": 0.0, "mp": 10, "rng": 4, "aoe": 0, "lv": 7, "st": "silence", "ch": 75},
	{"n": "時間加速", "el": "wind", "k": "buff", "pw": 0.0, "mp": 14, "rng": 3, "aoe": 1, "lv": 9, "st": "haste", "ch": 100, "job": "召喚師"},
	{"n": "聖淨領域", "el": "water", "k": "cure", "pw": 0.0, "mp": 12, "rng": 3, "aoe": 1, "lv": 9, "st": "", "ch": 0, "job": "僧侶"},
	{"n": "生命之泉", "el": "water", "k": "heal", "pw": 0.9, "mp": 22, "rng": 3, "aoe": 2, "lv": 12, "st": "", "ch": 0, "job": "僧侶"},
	{"n": "復活術", "el": "water", "k": "revive", "pw": 50.0, "mp": 18, "rng": 3, "aoe": 0, "lv": 11, "st": "", "ch": 0, "job": "僧侶", "t1": true},
	{"n": "大復活術", "el": "water", "k": "revive", "pw": 100.0, "mp": 34, "rng": 4, "aoe": 1, "lv": 1, "st": "", "ch": 0, "cls": "aurelia_a", "t": 2},
	{"n": "復活術", "el": "water", "k": "revive", "pw": 50.0, "mp": 18, "rng": 3, "aoe": 0, "lv": 1, "st": "", "ch": 0, "cls": "rain_a", "t": 2},
	{"n": "天火流星", "el": "fire", "k": "atk", "pw": 1.75, "mp": 32, "rng": 5, "aoe": 1, "lv": 13, "st": "burn", "ch": 60, "wx": "heat", "job": "召喚師"},
	{"n": "大海嘯波", "el": "water", "k": "atk", "pw": 1.6, "mp": 30, "rng": 5, "aoe": 1, "lv": 13, "st": "slow", "ch": 60, "wx": "rain"},
	{"n": "雷霆審判", "el": "wind", "k": "atk", "pw": 1.65, "mp": 30, "rng": 5, "aoe": 1, "lv": 14, "st": "stun", "ch": 30, "wx": "storm"},
	{"n": "天崩地裂", "el": "earth", "k": "atk", "pw": 1.75, "mp": 32, "rng": 5, "aoe": 1, "lv": 14, "st": "root", "ch": 55, "wx": "sand", "job": "召喚師"}]
const WX_RES := {"heat": ["fire", "酷暑"], "rain": ["water", "雨"], "storm": ["wind", "暴風雨"], "sand": ["earth", "沙塵暴"], "snow": ["water", "雪"]}

func spell23_ok(u, s) -> bool:
	if s.has("cls"): return s.cls == ucls(u) and utier(u) >= int(s.t)
	if not caster(u): return false
	if s.has("job") and u.job != s.job: return false
	if u.team == 1 and (s.k == "revive" or (not u.boss and int(s.lv) >= 12)): return false
	if u.job == "僧侶" and s.k == "atk" and not (s.el in ["water", "wind"]): return false
	if u.lv >= int(s.lv): return true
	return s.get("t1", false) and utier(u) >= 1
func wx_res(s) -> bool:
	var w: String = s.get("wx", "")
	if w == "": return false
	return wx_kind == w or (w == "rain" and wx_kind == "snow")
func silenced(u) -> bool: return u.status.has("silence")

func revive_targets(u, s, c: Vector2i) -> Array:
	var out := []
	for o in downed_allies(u.team):
		if mdist(o.cell, c) <= int(s.aoe) and unit_at(o.cell) == null: out.append(o)
	return out

# ---------- 「習得新法術」提示 ----------
func spell_names(u) -> Array:
	var o := []
	for s in spells_of(u): if not (s.n in o): o.append(s.n)
	return o
func learned_popup(u, before: Array) -> void:
	var nw := []
	for n in spell_names(u):
		if not (n in before): nw.append(n)
	if nw.is_empty(): return
	sfx("magic", 0.0, -4.0)
	for n in nw: log_msg("%s 習得了新法術「%s」！" % [u.name, n])
	var p := panel(Vector2(560, 300), Vector2(480, 0)); p.z_index = 50; p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 6); p.add_child(v)
	var t := lbl("✦ 習得新法術！", 30, Color(1, 0.85, 0.4), true); t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(t)
	var l2 := lbl("%s（Lv%d）\n「%s」" % [u.name, u.lv, "」「".join(nw)], 22, Color(0.95, 0.92, 0.85), true)
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l2.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY; l2.custom_minimum_size = Vector2(440, 0); v.add_child(l2)
	p.reset_size(); p.position = Vector2(800 - p.size.x / 2.0, 300)
	p.modulate.a = 0.0
	var tw := create_tween(); tw.tween_property(p, "modulate:a", 1.0, 0.25)
	burst(u.node.position + Vector3(0, 1.0, 0), Color(0.7, 0.85, 1.0), 40, 3.0, "spark.png", 0.2, 1.0, -1.0)
	if do_shots and not fx_shots.has("learn"): fx_shots["learn"] = true; await wait(0.35); await shot("23_spell_learned")
	await wait(1.6)
	var t2 := create_tween(); t2.tween_property(p, "modulate:a", 0.0, 0.35); await t2.finished
	p.queue_free()

# ---------- 高階魔法演出 ----------
func hi_fx(u, s, c: Vector2i) -> void:
	var pos := cell_pos(c)
	var col: Color = EL_COL[s.el]
	var res_on := wx_res(s)
	if res_on:
		popup(pos + Vector3(0, 1.6, 0), "天候共鳴！", Color(1, 0.95, 0.6), true)
		log_msg("「%s」與%s共鳴，威力 ×1.35" % [s.n, WX_RES[s.wx][1]])
	magic_circle(pos + Vector3(0, 0.05, 0), 1.2 + int(s.aoe) * 0.8, col)
	match s.el:
		"fire":
			for i in 5: meteor(pos + Vector3(randf_range(-3, 3), 9, randf_range(-3, 3)), pos + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)), i * 0.12)
		"water":
			light_pillar(pos, Color(0.4, 0.75, 1.0), 1.0)
			burst(pos + Vector3(0, 0.3, 0), Color(0.5, 0.8, 1.0), 120, 6.0, "spark.png", 0.22, 1.0, -8.0, 60.0, Vector3.UP)
		"wind":
			for i in 3:
				light_pillar(pos + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)), Color(0.85, 0.9, 1.0), 0.35)
				flash.color = Color(0.9, 0.95, 1.0, 0.35); create_tween().tween_property(flash, "color:a", 0.0, 0.2)
				sfx("thunder" if sfx_ok("thunder") else "explode", 0.1, -6.0); await wait(0.12)
		"earth":
			shake = max(shake, 0.9)
			for i in 10:
				var rp := pos + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
				burst(rp, Color(0.6, 0.45, 0.3), 14, 5.0, "spark.png", 0.3, 0.8, -12.0, 30.0, Vector3.UP)
	await wait(0.45)
func sfx_ok(n: String) -> bool: return ResourceLoader.exists("res://assets/sfx/%s.wav" % n)

# ---------- 傳說裝備 ----------
func legend_col(u):
	for nm in [u.weapon, u.armor]:
		var d: Dictionary = G.W.get(nm, G.A.get(nm, {}))
		if d.get("legend", false): var g: Array = d.get("glow", [1, 0.85, 0.4]); return Color(g[0], g[1], g[2])
	return null
func legend_aura(u) -> void:
	if u.get("lg_aura") != null: (u.lg_aura as Node).queue_free(); u.lg_aura = null
	var c = legend_col(u)
	if c == null: return
	var p := GPUParticles3D.new(); p.amount = 16; p.lifetime = 1.4
	var pm := ParticleProcessMaterial.new(); pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_radius = 0.38; pm.emission_ring_inner_radius = 0.3; pm.emission_ring_height = 0.05; pm.emission_ring_axis = Vector3.UP
	pm.gravity = Vector3(0, 0.9, 0); pm.initial_velocity_min = 0.05; pm.initial_velocity_max = 0.2; pm.scale_min = 0.5; pm.scale_max = 1.0
	var g := Gradient.new(); g.set_color(0, Color(c.r, c.g, c.b, 0.9)); g.set_color(1, Color(c.r, c.g, c.b, 0.0))
	var gt := GradientTexture1D.new(); gt.gradient = g; pm.color_ramp = gt; p.process_material = pm
	var q := quad(0.12, 0.12); q.material = particle_mat("glow.png", Color.WHITE); p.draw_pass_1 = q
	p.position = Vector3(0, 0.1, 0); u.node.add_child(p); u.lg_aura = p

func legend_strike(a, d) -> void:
	# 古王聖劍：攻擊命中後聖光追擊（光柱）
	if int(G.W[a.weapon].get("holy", 0)) <= 0 or not d.alive: return
	light_pillar(d.node.position, Color(1, 0.9, 0.5), 0.6)
	var dmg := maxi(1, int(st(a, "mag") * 0.6 + 6))
	d.hp = maxi(0, d.hp - dmg); track_dmg(a, d, dmg)
	popup(d.node.position + Vector3(0, 0.35, 0), "聖光 %d" % dmg, Color(1, 0.95, 0.6))
	update_label(d)
	if d.hp <= 0: kill(d)

# ---------- 特殊劇情 ----------
const EVENTS := {
	6: {"id": "e_altar", "kind": "reach", "who": "雷恩", "turns": 6, "reward": "古王聖劍", "mark": "altar",
		"name": "古王祭壇", "clue": "遺跡中央似乎有座發光的古王祭壇……傳說唯有王族血脈能喚醒它（6 回合內）。",
		"miss": "古代遺跡的「古王祭壇」仍在沉睡——據說王族之劍尚未被取走。",
		"pre": [["米菈", "雷恩，那座祭壇的紋章……和你劍柄上的金陽紋一模一樣！"], ["雷恩", "王族血脈……？趁帝國軍封鎖之前，我去看看！"]],
		"win": [["旁白", "雷恩觸碰祭壇的瞬間，沉睡千年的光芒甦醒了。"], ["雷恩", "這把劍……在呼喚我。"], ["米菈", "是傳說中的「古王聖劍」！初代國王與聖光立約的劍！"]]},
	9: {"id": "e_defect", "kind": "talk", "who": "加爾德", "npc": "洛克", "reward": "不落龍王鎧", "mark": "npc",
		"name": "舊部的請託", "clue": "敵陣中有一名加爾德的舊部「洛克」。若由加爾德前去說服，或許不必刀刃相向。",
		"miss": "加爾德的舊部「洛克」戰死於大平原……他守護的龍王鎧下落不明。",
		"pre": [["洛克", "……加爾德隊長？你真的投靠了叛軍？"], ["加爾德", "（那是洛克……我在金陽門時的副官。）"]],
		"win": [["加爾德", "洛克，法典束縛的是靈魂，不是良心。放下劍吧。"], ["洛克", "……隊長，三年來我每晚都在後悔。這副「不落龍王鎧」，請替我交給該穿的人。"], ["旁白", "洛克退出了戰場。"]]},
	11: {"id": "e_seal", "kind": "seal", "who": "米菈", "reward": "玄岳之契", "mark": "seal",
		"name": "沉睡的聖獸", "clue": "礦坑深處傳出大地的鼓動……召喚師若能觸及封印石，並在戰鬥結束前保住性命，就能聽見它的聲音。",
		"miss": "熔岩礦坑深處的「封印石」仍在鼓動——那裡有一頭未締約的聖獸。",
		"pre": [["米菈", "腳下在震動……這不是熔岩，是心跳！"], ["米菈", "礦坑深處有封印石。只要我能碰到它……"]],
		"win": [["米菈", "大地之子，玄岳聖龜・亞達曼……我聽見你了。"], ["旁白", "封印石碎裂，一頭背負山岳的巨龜在熔岩之下睜開了眼。"], ["米菈", "契約成立——「玄岳之契」！"]]},
	12: {"id": "e_rescue", "kind": "rescue", "turns": 7, "reward": "天弓流星", "mark": "cage", "npc": "蘿絲",
		"name": "囚籠中的弓匠", "clue": "要塞的囚籠裡關著傳說的弓匠「蘿絲」。帝國打算在第 7 回合把她押往帝都。",
		"miss": "鐵壁要塞的弓匠「蘿絲」被押往帝都——她打造的天弓再也無人知曉。",
		"pre": [["蘿絲", "外面的人！我是弓匠蘿絲……他們要在天黑前把我押走！"], ["艾琳", "有人被關在囚籠裡！得在他們押走她之前趕到！"]],
		"win": [["蘿絲", "謝謝你們……這是我一生最好的作品「天弓流星」，就交給那位女弓手吧。"], ["艾琳", "好輕……拉弦的瞬間，好像能聽見流星的聲音。"]]}}

func ev_setup() -> void:
	ev = EVENTS.get(bidx, {})
	ev_state = {}
	if ev.is_empty(): return
	if G.events.get(ev.id, false): ev_state.done_before = true
	if ev.kind == "talk":
		for u in alive_team(1):
			if not u.boss and u.job == "騎士":
				u.name = ev.npc; u.npc = true; u.title = "加爾德的舊部"; update_label(u); ev_npc_mark(u); break
		return
	# 祭壇／封印石／囚籠：放在偏敵方的空格
	var best := Vector2i(-1, -1); var bs0 := -1e9
	for c in heights:
		if c in ROCK_CELLS or c in LAVA_CELLS or c in water_cells or unit_at(c) != null: continue
		var fx := float(c.x) / W + float(c.y) / H
		var sc: float = -absf(fx - (1.05 if ev.kind == "reach" else 1.35)) * 10.0 + heights[c] * 0.2
		if sc > bs0: bs0 = sc; best = c
	ev_cell = best
	ev_mark(best, ev.mark)

func ev_mark(c: Vector2i, kind: String) -> void:
	var n := Node3D.new(); n.position = cell_pos(c); add_child(n); ev_nodes.append(n)
	var stone := StandardMaterial3D.new(); stone.albedo_color = Color(0.62, 0.58, 0.5); stone.roughness = 0.9
	var col: Color = {"altar": Color(1, 0.85, 0.4), "seal": Color(0.75, 0.55, 0.25), "cage": Color(0.6, 0.8, 1.0)}[kind]
	match kind:
		"altar":
			mi(n, box(Vector3(0.8, 0.18, 0.8)), Vector3(0, 0.09, 0), stone)
			mi(n, box(Vector3(0.5, 0.35, 0.5)), Vector3(0, 0.35, 0), stone)
			mi(n, sph(0.12, 12), Vector3(0, 0.68, 0), glow(col, 1.0, 5.0))
		"seal":
			mi(n, cyl(0.06, 0.3, 0.95, 6), Vector3(0, 0.48, 0), stone)
			mi(n, cyl(0.31, 0.31, 0.06, 6), Vector3(0, 0.55, 0), glow(Color(0.3, 1.0, 0.5), 0.8, 4.0))
		"cage":
			var iron := StandardMaterial3D.new(); iron.albedo_color = Color(0.25, 0.25, 0.28); iron.metallic = 0.8; iron.roughness = 0.4
			mi(n, box(Vector3(0.8, 0.06, 0.8)), Vector3(0, 0.03, 0), iron); mi(n, box(Vector3(0.8, 0.06, 0.8)), Vector3(0, 1.0, 0), iron)
			for i in 8:
				var a := i * TAU / 8.0
				mi(n, cyl(0.02, 0.02, 1.0, 5), Vector3(cos(a) * 0.36, 0.5, sin(a) * 0.36), iron)
			var cap := Label3D.new(); cap.text = "囚"; cap.font = font_bold; cap.font_size = 40; cap.pixel_size = 0.004 * G.font_k(); cap.billboard = BaseMaterial3D.BILLBOARD_ENABLED; cap.position = Vector3(0, 0.55, 0); cap.modulate = Color(1, 0.9, 0.7); cap.outline_size = 10; n.add_child(cap)
	var lt := OmniLight3D.new(); lt.light_color = col; lt.light_energy = 2.5; lt.omni_range = 2.5; lt.position = Vector3(0, 0.9, 0); n.add_child(lt)
	var rp := make_rise(Vector3.ZERO, col, 0.4, 24); rp.reparent(n, false); rp.position = Vector3(0, 0.1, 0)
	var ring := mi(n, cyl(0.48, 0.48, 0.015, 32), Vector3(0, 0.03, 0), glow(col, 0.45, 3.0))
	var tw := ring.create_tween().set_loops(); tw.tween_property(ring, "scale", Vector3(1.15, 1, 1.15), 0.8); tw.tween_property(ring, "scale", Vector3.ONE, 0.8)

func ev_npc_mark(u) -> void:
	var l := Label3D.new(); l.text = "！"; l.font = font_bold; l.font_size = 64; l.pixel_size = 0.005 * G.font_k(); l.outline_size = 12
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.no_depth_test = true; l.modulate = Color(1, 0.85, 0.3); l.position = Vector3(0, 2.9, 0); u.node.add_child(l)
	var tw := l.create_tween().set_loops(); tw.tween_property(l, "position:y", 3.1, 0.5); tw.tween_property(l, "position:y", 2.9, 0.5)
	u.npc_lbl = l

func ev_active() -> bool: return not ev.is_empty() and not ev_state.get("done", false) and not ev_state.get("failed", false)

func ev_fail(why: String) -> void:
	if not ev_active(): return
	ev_state.failed = true
	print("EVENT FAIL ", ev.id, " ", why)
	log_msg("特殊劇情「%s」未達成：%s" % [ev.name, why])
	popup(cell_pos(ev_cell) + Vector3(0, 1.4, 0) if ev_cell.x >= 0 else cur.node.position + Vector3(0, 1.5, 0), "劇情錯失", Color(0.8, 0.8, 0.9), true)
	for n in ev_nodes:
		var tw := create_tween(); tw.tween_property(n, "scale", Vector3(0.01, 0.01, 0.01), 0.8)

func ev_success() -> void:
	ev_state.done = true
	print("EVENT SUCCESS ", ev.id, " reward=", ev.reward)
	res.legend = ev.reward; res.event = ev.id
	await play_story(ev.win, false, {0: "23_event_%s" % ev.id} if do_shots else {})
	sfx("lvup_fanfare" if sfx_streams.has("lvup_fanfare") else "levelup", 0.0, -3.0)
	await legend_get_fx(ev.reward)

func legend_get_fx(nm: String) -> void:
	var icon := "res://assets/v23/legend_sword.png"
	var kind := "傳說武器"
	if G.W.has(nm): icon = G.W[nm].icon
	elif G.A.has(nm): icon = G.A[nm].icon; kind = "傳說防具"
	else: kind = "召喚契約"
	var p := panel(Vector2(500, 230), Vector2(600, 0)); p.z_index = 60
	var v := VBoxContainer.new(); v.alignment = BoxContainer.ALIGNMENT_CENTER; v.add_theme_constant_override("separation", 8); p.add_child(v)
	var t := lbl("★ 特殊劇情達成 ★", 32, Color(1, 0.85, 0.35), true); t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(t)
	var tr := TextureRect.new(); tr.texture = load(icon if G.W.has(nm) or G.A.has(nm) else "res://assets/v15/fx/el_earth.png"); tr.custom_minimum_size = Vector2(128, 128)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; v.add_child(tr)
	var l2 := lbl("獲得%s「%s」！" % [kind, nm], 26, Color(0.98, 0.95, 0.85), true); l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(l2)
	var ds := str(G.W.get(nm, G.A.get(nm, {})).get("desc", "米菈可召喚大地之召喚獸・玄岳聖龜 亞達曼"))
	var l3 := lbl(ds, 19, Color(0.85, 0.9, 1.0)); l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l3.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY; l3.custom_minimum_size = Vector2(560, 0); v.add_child(l3)
	p.reset_size(); p.position = Vector2(800 - p.size.x / 2.0, 450 - p.size.y / 2.0)
	p.scale = Vector2(0.6, 0.6); p.pivot_offset = p.size / 2.0; p.modulate.a = 0.0
	var tw := create_tween().set_parallel(); tw.tween_property(p, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK); tw.tween_property(p, "modulate:a", 1.0, 0.3)
	flash.color = Color(1, 0.95, 0.8, 0.35); create_tween().tween_property(flash, "color:a", 0.0, 0.6)
	await wait(0.6)
	if do_shots: await shot("23_legend_%s" % nm)
	await wait(2.2 if not autotest else 0.5)
	var t2 := create_tween(); t2.tween_property(p, "modulate:a", 0.0, 0.3); await t2.finished; p.queue_free()

func ev_after_move(u) -> void:
	if not ev_active() or u.team != 0: return
	match ev.kind:
		"reach":
			if u.cell == ev_cell and u.name == ev.who:
				if round_no <= int(ev.turns): await ev_trigger_story(); await ev_success()
		"seal":
			if u.cell == ev_cell and u.name == ev.who and not ev_state.get("triggered", false):
				ev_state.triggered = true
				await play_story([["米菈", "封印石……回應我吧！"], ["旁白", "封印石亮起了光。只要米菈撐到戰鬥結束，契約便能完成。"]], false, {0: "23_event_seal_touch"} if do_shots else {})
				popup(u.node.position + Vector3(0, 1.4, 0), "契約進行中", Color(0.5, 1, 0.6), true)
		"rescue":
			if mdist(u.cell, ev_cell) <= 1 and round_no <= int(ev.turns):
				await ev_trigger_story(); await ev_success()

func ev_trigger_story() -> void:
	for n in ev_nodes:
		burst(n.position + Vector3(0, 0.6, 0), Color(1, 0.9, 0.5), 80, 5.0, "spark.png", 0.25, 1.0, -2.0)
		light_pillar(n.position, Color(1, 0.9, 0.55), 1.4)
	await wait(0.6)

func ev_round() -> void:
	if not ev_active(): return
	if ev.kind in ["reach", "rescue"] and round_no > int(ev.turns):
		ev_fail("超過 %d 回合" % int(ev.turns))
	if ev.kind == "rescue" and round_no == int(ev.turns):
		log_msg("【注意】弓匠蘿絲將於本回合結束後被押走！")

func ev_on_kill(u) -> void:
	if not ev_active(): return
	if ev.kind == "talk" and u.get("npc", false): ev_fail("洛克戰死")
	if ev.kind == "seal" and u.team == 0 and u.name == ev.who and ev_state.get("triggered", false): ev_fail("米菈倒下，封印再次閉合")
	if ev.kind == "seal" and u.team == 0 and u.name == ev.who and not ev_state.get("triggered", false): pass

func ev_on_win() -> void:
	if ev_active() and ev.kind == "seal" and ev_state.get("triggered", false):
		var m = find_unit(ev.who)
		if m != null and m.alive: await ev_success()

func can_talk(u):
	if not ev_active() or ev.kind != "talk" or u.name != ev.who: return null
	for o in alive_team(1):
		if o.get("npc", false) and mdist(o.cell, u.cell) == 1: return o
	return null

func cmd_talk() -> void:
	var o = can_talk(cur)
	if o == null: return
	hide_menu(); state = "anim"
	face(cur, o.node.position); face(o, cur.node.position)
	await ev_trigger_story()
	await ev_success()
	# 洛克離開戰場（不計擊殺、不掉落）
	o.alive = false; o.label.visible = false; o.hpbar_root.visible = false
	if o.get("npc_lbl") != null: o.npc_lbl.queue_free()
	var tw := create_tween(); tw.tween_property(o.node, "scale", Vector3(0.01, 0.01, 0.01), 0.7); tw.tween_callback(func(): o.node.visible = false)
	burst(o.node.position + Vector3(0, 0.6, 0), Color(1, 0.9, 0.6), 40, 2.5, "glow.png", 0.25, 1.2, 0.6)
	acted = true
	after_action()

# ---------- 第三召喚獸：玄岳聖龜・亞達曼（地屬性） ----------
func adam_cost(u) -> int: return 28
func make_adamant() -> Dictionary:
	var root := Node3D.new()
	var sm := ShaderMaterial.new(); sm.shader = spr_shader
	sm.set_shader_parameter("tex", load("res://assets/v23/adamant.png")); sm.set_shader_parameter("grid", Vector2(8, 3))
	sm.set_shader_parameter("frame", 0); sm.set_shader_parameter("row", 1)
	sm.set_shader_parameter("tint", Vector3(1.0, 1.0, 0.98))
	var Hh := 3.0
	var qm := QuadMesh.new(); qm.size = Vector2(Hh * 4.0 / 3.0, Hh); qm.center_offset = Vector3(0, Hh * 0.5, 0)
	var spr := Node3D.new(); root.add_child(spr)
	var q := MeshInstance3D.new(); q.mesh = qm; q.material_override = sm; q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; spr.add_child(q)
	var lt := OmniLight3D.new(); lt.light_color = Color(1.0, 0.8, 0.4); lt.light_energy = 4.0; lt.omni_range = 4.5; lt.position = Vector3(0, 1.6, 0.6); root.add_child(lt)
	var ap := FakeAP.new()
	var cur_tw := [null]
	ap.cb = func(n: String):
		if cur_tw[0] != null and (cur_tw[0] as Tween).is_valid(): (cur_tw[0] as Tween).kill()
		var ft := spr.create_tween(); cur_tw[0] = ft
		var F := func(r: int, i: int): sm.set_shader_parameter("row", r); sm.set_shader_parameter("frame", i)
		match n:
			"rise":
				for i in 8: ft.tween_callback(F.bind(1, i)); ft.tween_interval(0.17)
			"attack":
				for i in 8: ft.tween_callback(F.bind(2, i)); ft.tween_interval(0.16 if i < 4 else 0.1)
				ft.tween_interval(0.4)
				for i in 8: ft.tween_callback(F.bind(0, i)); ft.tween_interval(0.15)
			_:
				ft.set_loops(8)
				for i in 8: ft.tween_callback(F.bind(0, i)); ft.tween_interval(0.15)
	return {"root": root, "ap": ap, "mat": sm, "light": lt}

func cmd_summon_adam() -> void:
	summon_kind = "adam"
	var cells := []
	for c in heights:
		if mdist(c, cur.cell) <= SUMMON_RANGE: cells.append(c)
	show_hl(cells, Color(0.9, 0.7, 0.35, 0.4)); state = "summon"; hide_menu()
	log_msg("選擇亞達曼的降臨位置（半徑 2：敵受地屬性傷害＋束縛，我方獲得岩盾＋回復 20%）")

func adam_cells(c: Vector2i) -> Array:
	var out := []
	for k in heights:
		if mdist(k, c) <= 2: out.append(k)
	return out

func do_adamant(u, c: Vector2i) -> void:
	hide_menu(); clear_hl()
	u.mp -= adam_cost(u)
	state = "anim"
	face(u, cell_pos(c)); play(u, "Spellcasting", 0.1)
	voice(u, "line", "summon_adam")
	skill_banner("召喚・玄岳聖龜 亞達曼", Color(0.95, 0.75, 0.35))
	var tp := cell_pos(c)
	var old_pos := cam_pivot.position; var oy := target_yaw; var od := target_dist; var op := target_pitch
	cam_pivot.position = tp + Vector3(0, 1.2, 0); target_yaw = round(oy / 360.0) * 360.0 + 20.0; target_dist = 15.0; target_pitch = 18.0
	var env: Environment = get_viewport().world_3d.environment if get_viewport().world_3d != null else null
	flash.color = Color(0.35, 0.22, 0.08, 0.0); create_tween().tween_property(flash, "color:a", 0.35, 0.6)
	# 大地裂開：魔法陣＋落石＋震動
	var mc := magic_circle(tp + Vector3(0, 0.06, 0), 2.6, Color(1.0, 0.75, 0.3))
	shake = 1.0; sfx("explode", 0.05, -4.0)
	for i in 14:
		var rp := tp + Vector3(randf_range(-2.2, 2.2), 0.05, randf_range(-2.2, 2.2))
		burst(rp, Color(0.55, 0.42, 0.3), 12, 5.0, "spark.png", 0.3, 0.9, -12.0, 35.0, Vector3.UP)
	burst(tp + Vector3(0, 0.3, 0), Color(0.5, 0.4, 0.3, 0.7), 60, 4.0, "smoke.png", 1.2, 1.6, 0.4)
	await wait(0.7)
	var ad := make_adamant(); add_child(ad.root)
	ad.root.position = tp + Vector3(0, 0.0, -0.6)
	var cam3 := get_viewport().get_camera_3d()
	if cam3 != null:
		var to: Vector3 = cam3.global_position - ad.root.position; ad.root.rotation.y = atan2(to.x, to.z)
	ad.ap.cb.call("rise")
	if do_shots: await wait(0.7); await shot("23_adam_a_rise")
	await wait(1.2)
	ad.ap.cb.call("idle")
	shake = 0.6
	# 護盾展開：金色半球結界
	var dome := mi(self, sph(1.0, 32), tp + Vector3(0, 0.0, 0), glow(Color(1.0, 0.8, 0.35), 0.22, 2.5), Vector3.ZERO, Vector3(0.1, 0.05, 0.1))
	(dome.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	var dt := create_tween(); dt.tween_property(dome, "scale", Vector3(2.6, 1.6, 2.6), 0.7).set_trans(Tween.TRANS_BACK)
	await wait(0.5)
	ad.ap.cb.call("attack")
	await wait(0.75)
	shake = 1.2; sfx("explode", 0.0, -2.0)
	flash.color = Color(1, 0.85, 0.5, 0.45); create_tween().tween_property(flash, "color:a", 0.0, 0.5)
	for k in adam_cells(c):
		var kp := cell_pos(k)
		burst(kp + Vector3(0, 0.1, 0), Color(0.75, 0.55, 0.3), 10, 4.5, "spark.png", 0.28, 0.8, -12.0, 25.0, Vector3.UP)
	if do_shots: await wait(0.1); await shot("23_adam_b_slam")
	var kills := 0
	for k in adam_cells(c):
		var t = unit_at(k)
		if t == null or not t.alive: continue
		if t.team != u.team:
			var b := (st(u, "mag") * 1.45 + 14.0 - st(t, "def") * 0.3) * el_mult("earth", t) * wx_el("earth") * (0.85 if t.boss else 1.0)
			var dmg := maxi(1, int(b * randf_range(0.93, 1.07)))
			t.hp = maxi(0, t.hp - dmg); track_dmg(u, t, dmg); hit_flash(t, Color(0.9, 0.65, 0.3)); play(t, "Hit_B", 0.05)
			popup(t.node.position, str(dmg), Color(1, 0.8, 0.45), true)
			update_label(t)
			if t.hp <= 0: kill(t); kills += 1
			else: apply_status(t, "root", 70)
		else:
			var hv := mini(int(st(t, "hp") * 0.2), st(t, "hp") - t.hp); t.hp += hv; track_heal(u, hv)
			t.status["shield"] = int(STAT_DUR["shield"])
			popup(t.node.position, "+%d 岩盾" % hv, Color(1, 0.9, 0.5), true); update_label(t)
	await wait(0.9)
	if do_shots: await shot("23_adam_c_shield")
	var dt2 := create_tween(); dt2.tween_property(dome, "scale", Vector3(0.1, 0.05, 0.1), 0.5); dt2.tween_callback(dome.queue_free)
	var st2 := create_tween(); st2.tween_property(ad.root, "position:y", ad.root.position.y - 3.2, 1.0).set_trans(Tween.TRANS_SINE)
	st2.parallel().tween_property(ad.light, "light_energy", 0.0, 1.0)
	await st2.finished; ad.root.queue_free(); mc.queue_free()
	create_tween().tween_property(flash, "color:a", 0.0, 0.4)
	skill_banner_end()
	cam_pivot.position = old_pos; target_yaw = oy; target_dist = od; target_pitch = op
	play(u, idle_anim(u), 0.2)
	acted = true
	if u.team == 0 and u.alive: await grant_exp(u, 12 + kills * 22)

func adam_plan(u):
	if not G.has_adam() or u.job != "召喚師" or u.team != 0 or u.mp < adam_cost(u): return null
	var best = null; var bsc := 1
	for cc in heights:
		if mdist(cc, u.cell) > SUMMON_RANGE: continue
		var n := 0
		for k in adam_cells(cc):
			var t = unit_at(k)
			if t != null and t.alive and t.team != u.team: n += 2
			elif t != null and t.alive and t.team == u.team and t.hp * 100 < st(t, "hp") * 70: n += 1
		if n > bsc: bsc = n; best = cc
	return best

# ---------- 地圖規模與敵軍聚落 ----------
const SETTLE := {0: "outpost", 1: "fort", 2: "bandit", 3: "bandit", 4: "harbor", 5: "village", 6: "ruins", 7: "cult", 8: "fortress",
	9: "warcamp", 10: "cult", 11: "mine", 12: "fortress", 13: "ice", 14: "fortress", 15: "throne"}
const SETTLE_NAME := {"outpost": "帝國哨站", "fort": "關隘堡壘", "bandit": "山賊營寨", "harbor": "港口倉庫", "village": "舊城街區", "ruins": "古代廢墟",
	"cult": "法典神殿", "fortress": "帝國要塞", "warcamp": "帝國野戰營", "mine": "礦坑據點", "ice": "冰原城牆", "throne": "天穹王座"}
# 佈陣：high=遠程兵佔高處 / ambush=伏兵 / reinf=增援波次(回合,數量) / patrol=巡邏與守備
const FORMS := {0: {"patrol": 2}, 1: {"high": true}, 2: {"ambush": 2}, 3: {"patrol": 2, "high": true}, 4: {"patrol": 2}, 5: {"ambush": 2},
	6: {"patrol": 2}, 7: {"high": true}, 8: {"high": true, "reinf": [4, 2]}, 9: {"reinf": [3, 3]}, 10: {"high": true}, 11: {"ambush": 2},
	12: {"high": true, "reinf": [4, 2]}, 13: {"high": true, "ambush": 2}, 14: {"reinf": [3, 2]}, 15: {"high": true}}

func smat(c: Color, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = rough; return m

const FLAG_SH := """shader_type spatial;
render_mode cull_disabled;
uniform vec3 col = vec3(0.7, 0.1, 0.1);
uniform vec3 col2 = vec3(0.95, 0.8, 0.3);
void vertex() {
	float k = (UV.x);
	VERTEX.z += sin(TIME * 4.0 + UV.x * 7.0) * 0.08 * k;
	VERTEX.y += sin(TIME * 3.0 + UV.x * 5.0) * 0.02 * k;
}
void fragment() {
	float band = step(0.42, UV.y) * step(UV.y, 0.58);
	ALBEDO = mix(col, col2, band);
	ROUGHNESS = 0.8;
}"""

func flag_at(p: Vector3, col: Color, col2 := Color(0.95, 0.8, 0.3), h := 2.0) -> ShaderMaterial:
	mi(self, cyl(0.03, 0.04, h, 6), p + Vector3(0, h / 2.0, 0), smat(Color(0.3, 0.22, 0.16)))
	var q := quad(0.8, 0.5); q.subdivide_width = 10; q.subdivide_depth = 4
	var m := shmat(FLAG_SH); m.set_shader_parameter("col", Vector3(col.r, col.g, col.b)); m.set_shader_parameter("col2", Vector3(col2.r, col2.g, col2.b))
	mi(self, q, p + Vector3(0.42, h - 0.3, 0), m)
	return m

func torch_at(p: Vector3, col := Color(1.0, 0.6, 0.25), tall := 0.9) -> void:
	mi(self, cyl(0.03, 0.04, tall, 6), p + Vector3(0, tall / 2.0, 0), smat(Color(0.25, 0.18, 0.12)))
	mi(self, cyl(0.07, 0.04, 0.1, 8), p + Vector3(0, tall, 0), smat(Color(0.2, 0.2, 0.22)))
	var f := fire_particles(p + Vector3(0, tall + 0.08, 0), 14, 0.05, 0.6)
	if col != Color(1.0, 0.6, 0.25):
		var g := Gradient.new(); g.set_color(0, Color(col.r, col.g, col.b, 1)); g.set_color(1, Color(col.r * 0.5, col.g * 0.5, col.b * 0.5, 0))
		var gt := GradientTexture1D.new(); gt.gradient = g; (f.process_material as ParticleProcessMaterial).color_ramp = gt
	var lt := OmniLight3D.new(); lt.light_color = col; lt.light_energy = 1.2; lt.omni_range = 2.4; lt.position = p + Vector3(0, tall + 0.2, 0); add_child(lt)
	if torches.size() < 24: torches.append(lt)

func smoke_at(p: Vector3, amount := 10) -> void:
	var s := GPUParticles3D.new(); s.amount = amount; s.lifetime = 3.0
	var pm := ParticleProcessMaterial.new(); pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE; pm.emission_sphere_radius = 0.1
	pm.gravity = Vector3(0.15, 0.4, 0); pm.initial_velocity_min = 0.2; pm.initial_velocity_max = 0.4; pm.direction = Vector3.UP; pm.spread = 12
	var sc := Curve.new(); sc.add_point(Vector2(0, 0.4)); sc.add_point(Vector2(1, 1.6)); var ct := CurveTexture.new(); ct.curve = sc; pm.scale_curve = ct
	var g := Gradient.new(); g.set_color(0, Color(0.45, 0.42, 0.4, 0.55)); g.set_color(1, Color(0.6, 0.6, 0.6, 0.0)); var gt := GradientTexture1D.new(); gt.gradient = g; pm.color_ramp = gt
	s.process_material = pm
	var q := quad(0.7, 0.7); q.material = particle_mat("smoke.png", Color.WHITE, false); s.draw_pass_1 = q
	s.position = p; add_child(s)

func campfire_at(p: Vector3) -> void:
	for i in 6:
		var a := i * TAU / 6.0
		mi(self, sph(0.06, 6), p + Vector3(cos(a) * 0.2, 0.04, sin(a) * 0.2), smat(Color(0.4, 0.38, 0.36)))
	mi(self, cyl(0.03, 0.03, 0.35, 5), p + Vector3(0, 0.06, 0), smat(Color(0.3, 0.2, 0.12)), Vector3(0, 0, PI / 2))
	mi(self, cyl(0.03, 0.03, 0.35, 5), p + Vector3(0, 0.06, 0), smat(Color(0.3, 0.2, 0.12)), Vector3(PI / 2, 0, 0))
	fire_particles(p + Vector3(0, 0.12, 0), 22, 0.1, 1.0)
	smoke_at(p + Vector3(0, 0.6, 0), 8)
	var lt := OmniLight3D.new(); lt.light_color = Color(1, 0.55, 0.2); lt.light_energy = 2.0; lt.omni_range = 3.0; lt.position = p + Vector3(0, 0.4, 0); add_child(lt)
	if torches.size() < 24: torches.append(lt)

func tent_at(p: Vector3, col: Color, rot: float) -> void:
	var t := PrismMesh.new(); t.size = Vector3(0.9, 0.65, 0.8)
	mi(self, t, p + Vector3(0, 0.325, 0), smat(col), Vector3(0, rot, 0))
	mi(self, box(Vector3(0.2, 0.36, 0.02)), p + Vector3(0, 0.18, 0) + Vector3(sin(rot), 0, cos(rot)) * 0.41, smat(Color(0.12, 0.08, 0.06)), Vector3(0, rot, 0))

func wall_seg(p: Vector3, along_z: bool, len := 1.0, h := 0.9, m: Material = null) -> void:
	if m == null: m = smat(Color(0.55, 0.53, 0.5))
	mi(self, box(Vector3(0.3, h, len) if along_z else Vector3(len, h, 0.3)), p + Vector3(0, h / 2.0, 0), m)
	for i in 3:
		var o := -len / 2.0 + len / 6.0 + i * len / 3.0
		mi(self, box(Vector3(0.32, 0.18, 0.16)), p + Vector3(0 if along_z else o, h + 0.09, o if along_z else 0), m)

func tower_at(p: Vector3, m: Material, h := 2.2) -> void:
	mi(self, cyl(0.38, 0.45, h, 10), p + Vector3(0, h / 2.0, 0), m)
	for i in 8:
		var a := i * TAU / 8.0
		mi(self, box(Vector3(0.14, 0.2, 0.14)), p + Vector3(cos(a) * 0.38, h + 0.1, sin(a) * 0.38), m)

func cannon_at(p: Vector3, yaw: float) -> void:
	var iron := smat(Color(0.18, 0.18, 0.2), 0.4); iron.metallic = 0.7
	mi(self, box(Vector3(0.45, 0.16, 0.3)), p + Vector3(0, 0.08, 0), smat(Color(0.35, 0.25, 0.16)), Vector3(0, yaw, 0))
	mi(self, cyl(0.07, 0.1, 0.7, 10), p + Vector3(0, 0.25, 0) + Vector3(sin(yaw), 0, cos(yaw)) * 0.15, iron, Vector3(PI / 2 - 0.2, yaw, 0))

func outer_y(c: Vector2i) -> float:
	if outer_top.has(c): return outer_top[c]
	var cc := Vector2i(clampi(c.x, 0, W - 1), clampi(c.y, 0, H - 1))
	return heights.get(cc, 0) * STEP

func opos(c: Vector2i) -> Vector3: return Vector3(c.x - W / 2.0 + 0.5, outer_y(c), c.y - H / 2.0 + 0.5)

func build_settlement() -> void:
	var th: String = SETTLE.get(bidx, "outpost")
	var rng := RandomNumberGenerator.new(); rng.seed = int(bdef.map.seed) * 7 + 3
	var stone := smat(Color(0.56, 0.54, 0.5)); var dark := smat(Color(0.3, 0.29, 0.32)); var white := smat(Color(0.88, 0.86, 0.8))
	var ice := smat(Color(0.75, 0.88, 0.95), 0.3)
	var red := Color(0.62, 0.08, 0.08); var gold := Color(0.95, 0.78, 0.3)
	# 敵方側外圈：右側 x=W 與下側 y=H
	var right := []; var bottom := []
	for y in range(H / 3, H + 1): right.append(Vector2i(W, y))
	for x in range(W / 3, W): bottom.append(Vector2i(x, H))
	match th:
		"outpost", "fort":
			for c in right.slice(0, right.size(), 2): wall_seg(opos(c), true, 1.0, 0.6 if th == "outpost" else 0.9, smat(Color(0.42, 0.3, 0.2)) if th == "outpost" else stone)
			tower_at(opos(right[right.size() / 2]), smat(Color(0.4, 0.28, 0.18)) if th == "outpost" else stone, 1.8)
			flag_at(opos(bottom[bottom.size() - 2]), red, gold)
			for c in bottom.slice(0, bottom.size(), 3): torch_at(opos(c))
		"bandit":
			for i in mini(4, bottom.size()): tent_at(opos(bottom[i * bottom.size() / 4]), Color(0.55, 0.42, 0.28).lerp(Color(0.4, 0.3, 0.25), rng.randf()), rng.randf_range(-0.6, 0.6))
			campfire_at(opos(right[right.size() / 2]))
			campfire_at(opos(bottom[bottom.size() - 1]))
			for c in right.slice(0, right.size(), 2):
				for k in 3: mi(self, cyl(0.04, 0.05, 0.8, 5), opos(c) + Vector3(0, 0.4, -0.3 + k * 0.3), smat(Color(0.4, 0.28, 0.16)), Vector3(rng.randf_range(-0.15, 0.15), 0, 0))
			flag_at(opos(right[1]), Color(0.15, 0.15, 0.15), Color(0.8, 0.15, 0.1), 1.6)
		"harbor", "village":
			for i in mini(4, bottom.size()):
				var p := opos(bottom[i * bottom.size() / 4])
				mi(self, box(Vector3(0.8, 0.7, 0.7)), p + Vector3(0, 0.35, 0), smat(Color(0.75, 0.68, 0.55)))
				var roof := PrismMesh.new(); roof.size = Vector3(0.9, 0.4, 0.8); mi(self, roof, p + Vector3(0, 0.9, 0), smat(Color(0.55, 0.22, 0.15)))
				smoke_at(p + Vector3(0.25, 1.1, 0), 5)
			for c in right.slice(0, right.size(), 2): torch_at(opos(c), Color(1.0, 0.75, 0.35), 1.0)
			for i in 4: mi(self, box(Vector3(0.3, 0.3, 0.3)), opos(right[i % right.size()]) + Vector3(0.25, 0.15 + (i / 2) * 0.3, 0.2), smat(Color(0.5, 0.36, 0.2)))
		"ruins":
			for c in right.slice(0, right.size(), 2):
				var hh := rng.randf_range(0.5, 1.6); mi(self, lowpoly(cyl(0.2, 0.24, hh, 8), rng, 0.04), opos(c) + Vector3(0, hh / 2.0, 0), stone)
			for c in bottom.slice(0, bottom.size(), 3): torch_at(opos(c), Color(0.4, 0.8, 1.0), 0.7)
			flag_at(opos(bottom[bottom.size() - 1]), red, gold)
		"cult", "throne":
			var m := white if th == "cult" else smat(Color(0.25, 0.2, 0.3))
			for c in right.slice(0, right.size(), 2):
				mi(self, cyl(0.16, 0.2, 1.8, 10), opos(c) + Vector3(0, 0.9, 0), m)
				mi(self, box(Vector3(0.5, 0.15, 0.5)), opos(c) + Vector3(0, 1.85, 0), m)
			for c in bottom.slice(0, bottom.size(), 2): torch_at(opos(c), Color(0.75, 0.4, 1.0) if th == "cult" else Color(1, 0.75, 0.3), 1.1)
			flag_at(opos(right[0]), Color(0.9, 0.88, 0.8) if th == "cult" else red, Color(0.6, 0.45, 0.9) if th == "cult" else gold, 2.4)
		"fortress", "ice", "warcamp", "mine":
			var m2 := ice if th == "ice" else (dark if th == "mine" else stone)
			if th == "warcamp":
				for i in mini(5, bottom.size()): tent_at(opos(bottom[i * bottom.size() / 5]), Color(0.7, 0.15, 0.12) if i % 2 == 0 else Color(0.85, 0.8, 0.7), 0.0)
				campfire_at(opos(right[right.size() / 2]))
				for c in right.slice(0, right.size(), 3): flag_at(opos(c), red, gold, 2.2)
			elif th == "mine":
				for c in right.slice(0, right.size(), 2): mi(self, box(Vector3(0.12, 1.0, 0.12)), opos(c) + Vector3(0, 0.5, 0), smat(Color(0.4, 0.28, 0.16)))
				for c in bottom.slice(0, bottom.size(), 2): torch_at(opos(c), Color(1, 0.5, 0.2), 0.8)
				smoke_at(opos(right[right.size() - 1]) + Vector3(0, 0.5, 0), 12)
			else:
				for c in right: wall_seg(opos(c), true, 1.0, 1.1, m2)
				tower_at(opos(right[0]), m2, 2.4); tower_at(opos(right[right.size() - 1]), m2, 2.4)
				for c in bottom.slice(0, bottom.size(), 3): cannon_at(opos(c), PI)
				for c in right.slice(1, right.size(), 3): flag_at(opos(c) + Vector3(0, 1.1, 0), red, gold, 1.6)
				for c in bottom.slice(1, bottom.size(), 3): torch_at(opos(c), Color(1.0, 0.6, 0.25), 1.0)
				if th == "ice":
					for c in bottom.slice(0, bottom.size(), 2): mi(self, cyl(0.0, 0.15, 0.7, 5), opos(c) + Vector3(0.3, 0.35, 0.25), ice)
	log_msg("戰場：%s（%d×%d）" % [SETTLE_NAME.get(th, th), W, H])

# 據點佔領：敵方軍旗格
func flag_setup() -> void:
	var best := Vector2i(-1, -1); var bsc := -1e9
	for c in heights:
		if c in ROCK_CELLS or c in LAVA_CELLS or c in water_cells or c == ev_cell: continue
		var sc: float = float(c.x) / W + float(c.y) / H + heights[c] * 0.05
		if unit_at(c) != null and unit_at(c).boss: continue
		if sc > bsc: bsc = sc; best = c
	if best.x < 0: return
	flag_cell = best
	var p := cell_pos(best)
	var m := flag_at(p + Vector3(0.3, 0, 0.3), Color(0.62, 0.08, 0.08), Color(0.95, 0.78, 0.3), 1.6)
	flag_nodes.mat = m
	var ring := mi(self, cyl(0.46, 0.46, 0.015, 32), p + Vector3(0, 0.03, 0), glow(Color(1, 0.3, 0.2), 0.35, 2.0))
	flag_nodes.ring = ring

func flag_check(u) -> void:
	if flag_taken or u.team != 0 or u.cell != flag_cell: return
	flag_taken = true
	var m: ShaderMaterial = flag_nodes.mat
	m.set_shader_parameter("col", Vector3(0.95, 0.8, 0.25)); m.set_shader_parameter("col2", Vector3(0.95, 0.95, 0.9))
	(flag_nodes.ring.material_override as StandardMaterial3D).albedo_color = Color(1, 0.85, 0.35, 0.45)
	popup(u.node.position + Vector3(0, 1.3, 0), "據點佔領！", Color(1, 0.85, 0.3), true)
	burst(u.node.position + Vector3(0, 1.0, 0), Color(1, 0.85, 0.4), 60, 4.0, "spark.png", 0.22, 1.0, -3.0)
	for e in alive_team(1):
		e.buff["atk"] = int(e.buff.get("atk", 0)) - 3; e.buff["def"] = int(e.buff.get("def", 0)) - 2
		popup(e.node.position + Vector3(0, 0.6, 0), "士氣低落", Color(0.7, 0.75, 0.9))
	res.gold += 150 + bidx * 20
	log_msg("%s 佔領了敵軍據點！敵軍士氣低落（攻−3 防−2），軍資金 +%d" % [u.name, 150 + bidx * 20])
	if do_shots and not fx_shots.has("flag"): fx_shots["flag"] = true; await wait(0.3); await shot("23_flag_capture")

# 佈陣
func form_apply() -> void:
	form = FORMS.get(bidx, {})
	var en := alive_team(1).filter(func(e): return not e.boss)
	if form.get("high", false):
		# 遠程兵與最高的敵方格交換位置
		var rs := en.filter(func(e): return ranged(e))
		var cells: Array = en.map(func(e): return e.cell)
		cells.sort_custom(func(a, b): return heights[a] > heights[b])
		var i := 0
		for e in rs:
			if i >= cells.size(): break
			var o = null
			for x in en:
				if x.cell == cells[i]: o = x
			if o != null and o != e:
				var tmp: Vector2i = e.cell; e.cell = o.cell; o.cell = tmp
				o.node.position = cell_pos(o.cell)
			e.node.position = cell_pos(e.cell); e.hold = 2
			i += 1
	var nam: int = int(form.get("ambush", 0))
	if nam > 0:
		# 伏兵：移到地圖中段並隱身，玩家接近 3 格或第 3 回合現身
		var mids := []
		for c in heights:
			if c in ROCK_CELLS or c in LAVA_CELLS or c in water_cells or unit_at(c) != null: continue
			var fx := float(c.x) / W + float(c.y) / H
			if fx > 0.75 and fx < 1.15: mids.append(c)
		var rng := RandomNumberGenerator.new(); rng.seed = bidx * 13 + 5
		var cand := en.filter(func(e): return not ranged(e))
		for k in mini(nam, cand.size()):
			if mids.is_empty(): break
			var c: Vector2i = mids.pop_at(rng.randi() % mids.size())
			var e = cand[cand.size() - 1 - k]
			e.cell = c; e.node.position = cell_pos(c); e.hidden = true; e.node.visible = false; e.label.visible = false; e.hpbar_root.visible = false
	var npat: int = int(form.get("patrol", 0))
	if npat > 0:
		var k := 0
		for e in en:
			if k >= npat or e.get("hidden", false) or ranged(e): continue
			e.patrol = [e.cell, e.cell + Vector2i(-2, 0) if inside(e.cell + Vector2i(-2, 0)) else e.cell + Vector2i(0, -2)]; e.hold = 1; k += 1

func ambush_check() -> void:
	for e in alive_team(1):
		if not e.get("hidden", false): continue
		var near := round_no >= 3
		for p in alive_team(0):
			if mdist(p.cell, e.cell) <= 3: near = true
		if near:
			e.hidden = false; e.node.visible = true; e.label.visible = true; e.hpbar_root.visible = true
			popup(e.node.position + Vector3(0, 1.2, 0), "伏兵！", Color(1, 0.4, 0.3), true)
			burst(e.node.position + Vector3(0, 0.4, 0), Color(0.5, 0.45, 0.4, 0.7), 30, 2.5, "smoke.png", 0.6, 1.0, 0.3)
			log_msg("伏兵 %s 現身了！" % e.name)
			if do_shots and not fx_shots.has("ambush"): fx_shots["ambush"] = true; await wait(0.3); await shot("23_ambush")

func reinf_check() -> void:
	var rf = form.get("reinf")
	if rf == null or reinf_done or round_no < int(rf[0]): return
	reinf_done = true
	var free := []
	for c in heights:
		if c in ROCK_CELLS or c in LAVA_CELLS or c in water_cells or unit_at(c) != null: continue
		free.append(c)
	free.sort_custom(func(a, b): return a.x + a.y > b.x + b.y)
	var rng := RandomNumberGenerator.new(); rng.seed = bidx * 31 + 7
	var n := 0
	skill_banner("敵軍增援！", Color(1, 0.45, 0.35))
	for i in int(rf[1]):
		if i >= free.size(): break
		var e: Dictionary = bdef.enemies[i % bdef.enemies.size()]
		var em := G.enemy_member(e.t, bidx, int(e.lv), rng)
		var u = add_unit(e.t, em.job, 1, em.base, em.weapon, em.armor, free[i], em.key, {}, 1.0, em.title, {"lv": int(em.lv)})
		if u != null:
			u.ct = 30; update_label(u)
			var to: Vector3 = Vector3.ZERO - u.node.position; u.node.rotation.y = atan2(to.x, to.z)
			burst(u.node.position + Vector3(0, 0.3, 0), Color(0.6, 0.5, 0.4, 0.7), 30, 3.0, "smoke.png", 0.6, 1.0, 0.3)
			n += 1
	log_msg("敵軍增援 %d 名抵達戰場！" % n)
	if do_shots and not fx_shots.has("reinf"): fx_shots["reinf"] = true; await wait(0.5); await shot("23_reinforce")
	await wait(0.6)
	skill_banner_end()

func new_round() -> void:
	ev_round()
	await ambush_check()
	await reinf_check()

# 守備／巡邏：玩家未接近時不主動出擊
func hold_move(u):
	var h := int(u.get("hold", 0))
	if h <= 0: return null
	var md := 99
	for p in alive_team(0): md = mini(md, mdist(p.cell, u.cell))
	if md <= int(st(u, "move")) + 3 or round_no >= 6: u.hold = 0; return null
	if h == 1 and u.has("patrol"):
		var tgt: Vector2i = u.patrol[1] if u.cell == u.patrol[0] else u.patrol[0]
		var r := reachable(u)
		if tgt in r.ends: return {"move": tgt, "target": null, "parent": r.parent}
	return {"move": u.cell, "target": null, "parent": {u.cell: u.cell}}


# ---------- v23 補充 ----------
var evtest := false
var p_turns := 0
var party_n := 0
func ev_intro() -> void:
	if ev.is_empty() or ev_state.get("done_before", false): return
	await play_story(ev.pre, false, {0: "23_event_pre_%s" % ev.id} if do_shots else {})
	log_msg("【特殊劇情】" + ev.name + "：" + ev.clue)

func support_targets(u, s, c: Vector2i) -> Array:
	if int(s.get("aoe", 0)) <= 0:
		var t = unit_at(c)
		return [] if t == null else [t]
	var out := []
	var foe: bool = s.k == "debuff"
	for k in spell_area(c, s):
		var t = unit_at(k)
		if t != null and t.alive and ((t.team != u.team) if foe else (t.team == u.team)): out.append(t)
	return out

func spell_names_lv(u, olv: int) -> Array:
	var nl: int = u.lv
	u.lv = olv
	var o := spell_names(u)
	u.lv = nl
	return o

func brief_ev_lines() -> Array:
	var o := []
	var e: Dictionary = EVENTS.get(bidx, {})
	if not e.is_empty() and not G.events.get(e.id, false): o.append("◆ 傳聞　" + str(e.clue))
	for k in EVENTS:
		if int(k) < bidx and not G.events.get(EVENTS[k].id, false) and int(k) >= bidx - 3:
			o.append("◇ 遺落　" + str(EVENTS[k].miss)); break
	return o

# 測試用：地形 BFS 距離（忽略單位），避免被牆或高低差卡住
func ev_goal_dist(goal: Vector2i, jp: int) -> Dictionary:
	var dist := {goal: 0}; var q := [goal]
	while q.size() > 0:
		var c: Vector2i = q.pop_front()
		for dd in DIRS:
			var n: Vector2i = c + dd
			if not inside(n) or dist.has(n) or n in ROCK_CELLS or n in LAVA_CELLS: continue
			if abs(heights[n] - heights[c]) > jp: continue
			var ob = unit_at(n)
			if ob != null and ob.team != 0 and n != goal: continue
			dist[n] = dist[c] + 1; q.append(n)
	return dist

# 自動測試：--evtest 讓負責的角色前往觸發點
func ev_auto(u) -> bool:
	if not evtest or not ev_active() or u.team != 0: return false
	var goal := Vector2i(-1, -1)
	if ev.kind == "seal" and not ev_state.get("triggered", false) and u.name != ev.who and round_no <= 3:
		# 測試用：封印石觸發前其餘隊員原地待命，避免戰鬥在米菈抵達前結束
		if cur == u and state == "menu": cmd_wait()
		return true
	match ev.kind:
		"talk":
			if u.name != ev.who: return false
			if can_talk(u) != null:
				state = "menu"; await cmd_talk()
				if cur == u and state == "menu": cmd_wait()
				return true
			for o in alive_team(1):
				if o.get("npc", false): goal = o.cell
		"reach", "seal":
			if u.name != ev.who or ev_state.get("triggered", false): return false
			goal = ev_cell
		"rescue":
			goal = ev_cell
	if goal.x < 0 or moved: return false
	var r := reachable(u)
	var gd := ev_goal_dist(goal, st(u, "jump"))
	var bc: Vector2i = u.cell; var bd: int = gd.get(u.cell, 999)
	for e in r.ends:
		if unit_at(e) != null and e != u.cell: continue
		var d: int = gd.get(e, 999)
		if d < bd or (d == bd and e == goal): bd = d; bc = e
	if bc == u.cell: return false
	cmd_move(); await wait(0.25); await on_cell_clicked(bc)
	if state == "over": return true
	if ev.kind == "talk" and can_talk(u) != null and not acted:
		await cmd_talk()
		if cur == u and state == "menu": cmd_wait()
		return true
	if cur == u and state == "menu": cmd_wait()
	return true

func shot_to(p: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(p)
