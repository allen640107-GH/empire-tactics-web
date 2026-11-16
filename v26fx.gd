extends RefCounted
# v26 畫面精緻化：戰場後製（銳利化／調色／暈影／打擊衝擊）＋標題鏡頭光暈與選單流光（全部自製 shader）
const POST := """shader_type canvas_item;
uniform sampler2D scr : hint_screen_texture, filter_linear;
uniform float sharpen = 0.3;
uniform float contrast = 1.0;
uniform float sat = 1.0;
uniform float vig = 0.15;
uniform vec3 gain = vec3(1.0);
uniform vec3 lift = vec3(0.0);
uniform float punch = 0.0;
uniform vec2 punch_c = vec2(0.5);
void fragment(){
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	vec3 c = texture(scr, uv).rgb;
	if (sharpen > 0.001) {
		vec3 n = texture(scr, uv + vec2(0.0, px.y)).rgb + texture(scr, uv - vec2(0.0, px.y)).rgb
			+ texture(scr, uv + vec2(px.x, 0.0)).rgb + texture(scr, uv - vec2(px.x, 0.0)).rgb;
		c += (c - n * 0.25) * sharpen;
	}
	if (punch > 0.002) {
		vec2 d = uv - punch_c;
		float k = punch * 0.035;
		vec3 a = texture(scr, uv - d * k).rgb;
		vec3 b = texture(scr, uv - d * k * 2.0).rgb;
		c = vec3(mix(c.r, a.r, 0.5), c.g * 0.5 + a.g * 0.3 + b.g * 0.2, mix(c.b, b.b, 0.6));
		c += punch * 0.16 * vec3(1.0, 0.88, 0.7) * smoothstep(0.9, 0.0, length(d * vec2(1.6, 1.0)));
	}
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	c = mix(vec3(l), c, sat);
	c = (c - 0.5) * contrast + 0.5;
	c = c * gain + lift * (1.0 - c);
	vec2 v = (uv - 0.5) * vec2(1.15, 1.0);
	c *= 1.0 - vig * smoothstep(0.38, 0.86, length(v));
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}"""
# 標題：太陽鏡頭光暈（星芒＋光環＋鬼影），加算混合
const FLARE := """shader_type canvas_item;
render_mode blend_add;
uniform vec2 sun = vec2(0.85, 0.47);
uniform float strength = 1.0;
void fragment(){
	vec2 asp = vec2(1.78, 1.0);
	vec2 d = (UV - sun) * asp;
	float r = length(d);
	float pulse = 0.85 + 0.15 * sin(TIME * 1.7);
	float star = exp(-abs(d.y) * 260.0) * exp(-abs(d.x) * 4.5) + exp(-abs(d.x) * 300.0) * exp(-abs(d.y) * 9.0) * 0.6;
	float core = exp(-r * 38.0) * 1.4;
	float ring = exp(-pow((r - 0.11) * 70.0, 2.0)) * 0.10;
	vec3 col = vec3(1.0, 0.82, 0.55) * (star * 0.55 * pulse + core) + vec3(1.0, 0.6, 0.3) * ring;
	vec2 axis = (vec2(0.5) - sun);
	for (int i = 1; i <= 3; i++) {
		float t = float(i) * 0.55;
		vec2 gp = sun + axis * (1.0 + t);
		float gr = length((UV - gp) * asp);
		float sz = 0.025 + 0.02 * float(i);
		float g = smoothstep(sz, sz * 0.75, gr) * 0.05;
		col += g * mix(vec3(1.0, 0.7, 0.35), vec3(0.45, 0.7, 1.0), float(i) / 3.0);
	}
	COLOR = vec4(col * strength, 1.0);
}"""
# 選單框：斜向金色流光掃過（依本地座標，九宮格也連續）
const SHEEN := """shader_type canvas_item;
uniform vec2 sz = vec2(480.0, 400.0);
uniform float period = 5.5;
varying vec2 lp;
void vertex(){ lp = VERTEX; }
void fragment(){
	vec4 c = texture(TEXTURE, UV) * COLOR;
	vec2 p = lp / sz;
	float t = mod(TIME, period) / period;
	float x = p.x + p.y * 0.45 - (t * 2.6 - 0.6);
	float s = exp(-x * x * 90.0);
	c.rgb += vec3(1.0, 0.86, 0.52) * s * 0.55 * c.a;
	COLOR = c;
}"""
static func mat(code: String) -> ShaderMaterial:
	var s := Shader.new(); s.code = code
	var m := ShaderMaterial.new(); m.shader = s; return m
