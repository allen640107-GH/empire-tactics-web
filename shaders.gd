extends RefCounted
# 帝國戰記 v2 着色器集合（全部自製）

const UNIT := """
shader_type spatial;
uniform sampler2D tex : source_color, hint_default_white, filter_linear_mipmap;
uniform vec4 base_col : source_color = vec4(1.0);
uniform float hc = 0.0;
uniform float hw = 0.0;
uniform float hs = 0.0;
uniform float smin = 0.3;
uniform vec3 tint = vec3(1.0);
uniform vec4 flash = vec4(0.0);
uniform vec4 rim_col = vec4(0.0);
vec3 rgb2hsv(vec3 c){vec4 K=vec4(0.,-1./3.,2./3.,-1.);vec4 p=mix(vec4(c.bg,K.wz),vec4(c.gb,K.xy),step(c.b,c.g));vec4 q=mix(vec4(p.xyw,c.r),vec4(c.r,p.yzx),step(p.x,c.r));float d=q.x-min(q.w,q.y);float e=1.0e-10;return vec3(abs(q.z+(q.w-q.y)/(6.*d+e)),d/(q.x+e),q.x);}
vec3 hsv2rgb(vec3 c){vec4 K=vec4(1.,2./3.,1./3.,3.);vec3 p=abs(fract(c.xxx+K.xyz)*6.-K.www);return c.z*mix(K.xxx,clamp(p-K.xxx,0.,1.),c.y);}
void fragment(){
	vec3 c = texture(tex, UV).rgb * base_col.rgb;
	vec3 h = rgb2hsv(c);
	float dh = abs(fract(h.x - hc + 0.5) - 0.5);
	float sel = (1.0 - smoothstep(hw, hw + 0.03, dh)) * smoothstep(smin, smin + 0.08, h.y);
	vec3 c0 = c;
	float skin = smoothstep(0.025, 0.04, h.x) * (1.0 - smoothstep(0.1, 0.12, h.x)) * smoothstep(0.38, 0.45, h.y) * (1.0 - smoothstep(0.75, 0.82, h.y)) * smoothstep(0.75, 0.82, h.z);
	sel *= 1.0 - skin;
	vec3 sk = c0 * vec3(0.97, 0.93, 0.9);
	h.x = fract(h.x + hs * sel);
	c = mix(mix(c, hsv2rgb(h), sel) * tint, sk, skin);
	ALBEDO = c;
	float metal = (1.0 - smoothstep(0.18, 0.26, h.y)) * smoothstep(0.48, 0.52, h.x) * (1.0 - smoothstep(0.6, 0.64, h.x)) * (1.0 - skin);
	float brush = sin(UV.y * 900.0 + sin(UV.x * 300.0) * 2.0) * 0.5 + 0.5;
	ALBEDO = c * mix(1.0, 0.92 + 0.1 * brush, metal);
	METALLIC = metal * 0.7;
	ROUGHNESS = mix(mix(0.66, 0.8, skin), 0.3 + 0.12 * brush, metal);
	SPECULAR = mix(0.5, 0.25, skin);
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = flash.rgb * flash.a + rim_col.rgb * rim_col.a * fr;
}
"""

const LAVA := """
shader_type spatial;
uniform sampler2D noise_tex : repeat_enable;
uniform float dissolve = 0.0;
uniform float glow = 1.0;
varying vec3 lp;
varying vec3 wn;
void vertex(){ lp = VERTEX; wn = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz; }
void fragment(){
	// v8：暗色玄武岩鱗片＋細熔岩脈（手繪感）
	float n1 = texture(noise_tex, lp.xy * 2.2 + vec2(0.0, TIME * 0.05)).r;
	float n2 = texture(noise_tex, lp.zy * 2.2 - vec2(TIME * 0.03, TIME * 0.04)).r;
	float n = n1 * 0.6 + n2 * 0.4;
	vec2 q = vec2(lp.x * 26.0 + lp.z * 14.0, lp.y * 30.0);
	q.x += step(0.5, fract(q.y * 0.5)) * 0.5;
	vec2 g = fract(q) - 0.5;
	float scale = smoothstep(0.5, 0.2, length(g * vec2(1.0, 1.4)));
	float crack = 1.0 - smoothstep(0.0, 0.014, abs(n - 0.5)) ;
	float hot = smoothstep(0.7, 0.95, n);
	if (n2 < dissolve) { discard; }
	float up = clamp(normalize(wn).y * 0.5 + 0.5, 0.0, 1.0);
	vec3 rock = mix(vec3(0.05, 0.04, 0.04), vec3(0.17, 0.12, 0.1), scale) * mix(0.8, 1.15, up);
	ALBEDO = mix(rock, vec3(0.3, 0.07, 0.02), hot * 0.5);
	ROUGHNESS = mix(0.85, 0.45, scale);
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 fire = vec3(1.0, 0.42, 0.06);
	EMISSION = (fire * (crack * 2.6 + hot * 0.35 + (1.0 - scale) * 0.08) + vec3(1.0, 0.45, 0.1) * fr * 0.7) * glow;
	if (n2 < dissolve + 0.06) { EMISSION += vec3(1.0, 0.7, 0.2) * 6.0; }
}
"""

const PILLAR := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform sampler2D noise_tex : repeat_enable;
uniform vec4 col : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform float power = 1.0;
void fragment(){
	float n = texture(noise_tex, vec2(UV.x * 3.0, UV.y * 1.5 + TIME * 1.6)).r;
	float n2 = texture(noise_tex, vec2(UV.x * 5.0 + 0.3, UV.y * 2.5 + TIME * 2.3)).r;
	float v = (1.0 - UV.y) ;
	float a = smoothstep(0.25, 0.9, n * n2 * 2.0) * pow(UV.y, 0.6) * power;
	ALBEDO = col.rgb * (1.5 + n * 2.0);
	ALPHA = clamp(a, 0.0, 1.0);
}
"""

const DECAL := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform sampler2D tex : source_color;
uniform vec4 col : source_color = vec4(1.0, 0.6, 0.2, 1.0);
uniform float alpha = 1.0;
void fragment(){
	vec4 t = texture(tex, UV);
	ALBEDO = col.rgb * 3.0;
	ALPHA = t.a * alpha * col.a;
}
"""

const WATER := """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D nrm : hint_normal, repeat_enable;
void fragment(){
	vec2 uv = UV * vec2(3.0, 24.0);
	vec3 a = texture(nrm, uv + vec2(0.02, -0.25) * TIME).rgb;
	vec3 b = texture(nrm, uv * 1.37 + vec2(-0.03, -0.18) * TIME).rgb;
	NORMAL_MAP = normalize(a + b - 1.0) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.6;
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	ALBEDO = mix(vec3(0.02, 0.09, 0.11), vec3(0.25, 0.38, 0.42), fr);
	ROUGHNESS = 0.04;
	METALLIC = 0.0;
	SPECULAR = 0.9;
	float edge = smoothstep(0.0, 0.12, UV.x) * smoothstep(0.0, 0.12, 1.0 - UV.x);
	ALPHA = 0.55 + 0.35 * edge;
}
"""

const GRASS := """
shader_type spatial;
render_mode cull_disabled;
uniform vec3 base : source_color = vec3(0.10, 0.17, 0.05);
uniform vec3 tip : source_color = vec3(0.45, 0.55, 0.20);
void vertex(){
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float k = UV.y * UV.y;
	VERTEX.x += sin(TIME * 1.8 + w.x * 0.7 + w.z * 0.3) * 0.08 * k;
	VERTEX.z += cos(TIME * 1.3 + w.z * 0.6) * 0.05 * k;
}
void fragment(){
	ALBEDO = mix(base, tip, UV.y) * COLOR.rgb;
	ROUGHNESS = 0.9;
	BACKLIGHT = vec3(0.2, 0.3, 0.1);
}
"""

const FLAG := """
shader_type spatial;
render_mode cull_disabled;
uniform vec3 cloth : source_color = vec3(0.5, 0.04, 0.05);
uniform vec3 gold : source_color = vec3(0.85, 0.65, 0.2);
void vertex(){
	float k = UV.x;
	VERTEX.z += sin(TIME * 3.0 + UV.x * 6.0 + UV.y * 2.0) * 0.12 * k;
}
void fragment(){
	vec2 c = UV - vec2(0.5, 0.42);
	float border = step(UV.x, 0.06) + step(0.94, UV.x) + step(UV.y, 0.05);
	float emblem = step(length(c * vec2(1.0, 1.3)), 0.2) - step(length(c * vec2(1.0, 1.3)), 0.15);
	float cross = step(abs(c.x), 0.03) * step(abs(c.y), 0.16) + step(abs(c.y), 0.03) * step(abs(c.x), 0.12);
	float tail = step(0.85, UV.y) * step(abs(UV.x - 0.5), (UV.y - 0.85) * 3.3);
	if (tail > 0.5) { discard; }
	ALBEDO = mix(cloth, gold, clamp(border + emblem + cross, 0.0, 1.0));
	ROUGHNESS = 0.85;
	BACKLIGHT = cloth * 0.6;
}
"""

const TRAIL := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform sampler2D tex : source_color;
uniform vec4 col : source_color = vec4(1.0);
uniform float alpha = 1.0;
uniform float sweep = 1.0;
void fragment(){
	vec4 t = texture(tex, UV);
	float m = step(UV.x, sweep);
	ALBEDO = col.rgb * 2.5;
	ALPHA = t.a * alpha * m;
}
"""

const HAIR := """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 c1 : source_color = vec4(0.55, 0.36, 0.1, 1.0);
uniform vec4 c2 : source_color = vec4(0.95, 0.76, 0.36, 1.0);
uniform vec4 hi : source_color = vec4(1.0, 0.95, 0.75, 1.0);
varying vec3 lp;
void vertex(){ lp = VERTEX; }
float hsh(float n){ return fract(sin(n) * 43758.5453); }
void fragment(){
	float ang = atan(lp.x, lp.z);
	float k = ang * 14.0 + lp.y * 3.0;
	float id = floor(k);
	float f = fract(k);
	float strand = smoothstep(0.0, 0.25, f) * (1.0 - smoothstep(0.75, 1.0, f));
	float tone = hsh(id) * 0.6 + 0.4 * strand;
	vec3 col = mix(c1.rgb, c2.rgb, tone);
	float fine = sin(ang * 90.0 + lp.y * 8.0) * 0.5 + 0.5;
	col *= 0.88 + 0.16 * fine;
	ALBEDO = col;
	ROUGHNESS = 0.42;
	SPECULAR = 0.65;
	ANISOTROPY = 0.75;
	ANISOTROPY_FLOW = vec2(0.0, 1.0);
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	EMISSION = hi.rgb * fr * 0.12;
}
"""

const CAPE := """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 cloth : source_color = vec4(0.018, 0.03, 0.13, 1.0);
uniform vec4 lining : source_color = vec4(0.05, 0.075, 0.2, 1.0);
uniform vec4 gold : source_color = vec4(0.95, 0.72, 0.28, 1.0);
uniform float emblem = 1.0;
void vertex(){
	float t = UV.y;
	VERTEX.z += sin(TIME * 1.7 + UV.x * 5.0) * 0.035 * t * t - 0.02 * t * sin(TIME * 0.9);
	VERTEX.x += sin(TIME * 1.3 + UV.y * 4.0) * 0.012 * t;
}
void fragment(){
	vec2 uv = UV;
	float weave = (sin(uv.x * 420.0) * sin(uv.y * 420.0)) * 0.5 + 0.5;
	vec3 base = FRONT_FACING ? lining.rgb : cloth.rgb;
	base *= 0.9 + 0.12 * weave;
	float edge = max(step(uv.x, 0.035) + step(0.965, uv.x), step(0.955, uv.y));
	float d = length((uv - vec2(0.5, 0.36)) * vec2(1.25, 1.0));
	float sunc = 1.0 - smoothstep(0.1, 0.11, d);
	float ray = step(0.11, d) * (1.0 - smoothstep(0.17, 0.18, d)) * step(0.55, sin(atan(uv.y - 0.36, uv.x - 0.5) * 12.0));
	float emb = FRONT_FACING ? 0.0 : clamp(sunc + ray, 0.0, 1.0) * emblem;
	float g = clamp(edge + emb, 0.0, 1.0);
	ALBEDO = mix(base, gold.rgb, g);
	METALLIC = g * 0.8;
	ROUGHNESS = mix(0.85, 0.35, g);
	SPECULAR = 0.3;
}
"""

# v5：寫實比例人物（Quaternius UBC）的皮膚＋服裝著色器。COLOR.r = 部位材質編號、COLOR.g = 邊緣滾邊
const HUMAN := """
shader_type spatial;
uniform sampler2D skin_tex : source_color, filter_linear_mipmap;
uniform sampler2D face_mask : filter_linear_mipmap;
uniform vec3 skin_tint = vec3(1.0);
uniform vec4 iris_col : source_color = vec4(0.45, 0.3, 0.18, 1.0);
uniform vec4 brow_col : source_color = vec4(0.3, 0.2, 0.1, 1.0);
uniform vec4 c_cloth : source_color = vec4(0.2, 0.3, 0.6, 1.0);
uniform vec4 c_pants : source_color = vec4(0.25, 0.2, 0.16, 1.0);
uniform vec4 c_leather : source_color = vec4(0.3, 0.18, 0.1, 1.0);
uniform vec4 c_metal : source_color = vec4(0.7, 0.72, 0.76, 1.0);
uniform vec4 c_robe : source_color = vec4(0.4, 0.1, 0.12, 1.0);
uniform vec4 c_trim : source_color = vec4(0.85, 0.65, 0.25, 1.0);
uniform vec4 flash = vec4(0.0);
uniform vec4 rim_col = vec4(0.0);
varying float vid;
varying float vedge;
varying vec3 wn;
float h21(vec2 p){ p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float vn(vec2 p){ vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
void vertex(){ vid = COLOR.r * 10.0; vedge = COLOR.g; wn = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz; }
void fragment(){
	int id = int(vid + 0.5);
	vec2 uv = UV;
	vec4 st = texture(skin_tex, uv);
	vec3 fm = texture(face_mask, uv).rgb;
	vec3 sk = st.rgb * mix(vec3(1.0), skin_tint * vec3(0.95, 0.8, 0.7), st.a);
	sk = mix(sk, st.rgb * iris_col.rgb * 1.9, fm.r);
	sk = mix(sk, brow_col.rgb * st.rgb * 1.5, fm.g);
	vec3 col = sk; float rough = 0.75; float metal = 0.0; float spec = 0.22; float nm = 0.0;
	float eyes = max(fm.r, 1.0 - st.a);
	float n1 = vn(uv * 90.0); float n2 = vn(uv * 600.0);
	float edge = smoothstep(0.25, 0.9, vedge);
	if (id == 1 || id == 2 || id == 6) {
		vec3 base = id == 1 ? c_cloth.rgb : (id == 2 ? c_pants.rgb : c_robe.rgb);
		float wx = sin(uv.x * 2600.0) * 0.5 + 0.5; float wy = sin(uv.y * 2600.0) * 0.5 + 0.5;
		float weave = mix(wx, wy, step(0.5, fract(uv.x * 413.0 + uv.y * 413.0)));
		col = base * (0.82 + 0.18 * weave) * (0.88 + 0.24 * n1);
		col = mix(col, c_trim.rgb * (0.85 + 0.3 * n2), edge * (id == 2 ? 0.0 : 1.0));
		rough = mix(0.9, 0.45, edge * float(id != 2)); metal = edge * float(id != 2) * 0.6; spec = 0.25; nm = 0.0;
	} else if (id == 3) {
		col = c_leather.rgb * (0.7 + 0.45 * n1) * (0.9 + 0.15 * n2);
		float stitch = step(0.82, fract(uv.y * 300.0)) * edge;
		col = mix(col, c_leather.rgb * 1.8, stitch * 0.6);
		rough = 0.55 - 0.15 * n1; spec = 0.45; nm = 0.0;
	} else if (id == 4) {
		float brush = vn(vec2(uv.x * 40.0, uv.y * 1500.0));
		col = c_metal.rgb * (0.85 + 0.2 * brush) * (0.92 + 0.12 * n1);
		col = mix(col, c_trim.rgb, edge);
		// 手繪金色雕花（卷草紋）
		vec2 q = uv * vec2(260.0, 260.0);
		float scroll = sin(q.x + 2.2 * sin(q.y * 0.9)) * sin(q.y + 2.2 * sin(q.x * 0.9));
		float eng = smoothstep(0.72, 0.9, abs(scroll)) * smoothstep(0.5, 0.62, vn(uv * 14.0));
		col = mix(col, c_trim.rgb * 1.05, eng * 0.85);
		col *= 1.0 - 0.25 * smoothstep(0.55, 0.72, abs(scroll)) * (1.0 - smoothstep(0.72, 0.8, abs(scroll))) * smoothstep(0.5, 0.62, vn(uv * 14.0));
		metal = 0.92; rough = 0.22 + 0.15 * brush + 0.1 * n2; spec = 0.6; nm = 0.0;
	} else if (id == 5) {
		vec2 g = fract(uv * 520.0 + vec2(0.0, step(0.5, fract(uv.x * 260.0)) * 0.5));
		float d = length(g - 0.5);
		float ring = smoothstep(0.12, 0.2, d) * (1.0 - smoothstep(0.38, 0.48, d));
		col = c_metal.rgb * mix(0.18, 1.0, ring) * (0.85 + 0.25 * n1);
		col = mix(col, c_leather.rgb, edge);
		metal = mix(0.2, 0.9, ring); rough = mix(0.8, 0.35, ring); spec = 0.5; nm = 0.0;
	}
	// 程序凹凸：布紋、皮革紋、錘痕/拉絲、鎖環（surface-gradient bump，GPU 便宜）
	float fw = clamp(1.0 - length(fwidth(uv)) * 900.0, 0.0, 1.0);
	float hgt = 0.0; float bstr = 0.0;
	if (id == 1 || id == 2 || id == 6) { hgt = (sin(uv.x * 2600.0) * sin(uv.y * 2600.0)) * 0.5 * fw + n1 * 0.6; bstr = 0.6; }
	else if (id == 3) { hgt = n2 * 0.7 * fw + n1 * 0.5 + vn(uv * 220.0) * 0.4; bstr = 0.9; }
	else if (id == 4) { hgt = vn(uv * 35.0) * 0.8 + vn(vec2(uv.x * 40.0, uv.y * 1500.0)) * 0.15 * fw - edge * 0.5; bstr = 0.5; }
	else if (id == 5) { vec2 g2 = fract(uv * 520.0 + vec2(0.0, step(0.5, fract(uv.x * 260.0)) * 0.5)); float d2 = length(g2 - 0.5); hgt = (smoothstep(0.12, 0.25, d2) * (1.0 - smoothstep(0.35, 0.48, d2))) * fw + n1 * 0.3; bstr = 1.1; }
	if (bstr > 0.0) {
		vec3 dpx = dFdx(VERTEX); vec3 dpy = dFdy(VERTEX);
		float dhx = dFdx(hgt) * bstr * 0.02; float dhy = dFdy(hgt) * bstr * 0.02;
		vec3 r1 = cross(dpy, NORMAL); vec3 r2 = cross(NORMAL, dpx);
		float det = dot(dpx, r1);
		vec3 gr = sign(det) * (dhx * r1 + dhy * r2);
		NORMAL = normalize(abs(det) * NORMAL - gr);
	}
	// 手繪感：上亮下暗的漸層＋暖色暗部
	float up = clamp(normalize(wn).y * 0.5 + 0.5, 0.0, 1.0);
	col *= mix(0.86, 1.08, up);
	if (id == 0) { col += vec3(0.05, 0.02, 0.0) * (1.0 - up); EMISSION = col * 0.03 * (1.0 - eyes); }
	ALBEDO = col;
	METALLIC = metal; ROUGHNESS = rough; SPECULAR = spec;
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION += flash.rgb * flash.a + rim_col.rgb * rim_col.a * fr + (id == 0 ? col * eyes * 0.12 : vec3(0.0));
}
"""

# v5：UBC 髮型貼圖（灰階髮絲）染色＋各向異性高光
const HAIR2 := """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 c1 : source_color = vec4(0.5, 0.33, 0.1, 1.0);
uniform vec4 c2 : source_color = vec4(1.0, 0.82, 0.45, 1.0);
uniform vec3 hc = vec3(0.0, 1.6, 0.0);
uniform vec4 flash = vec4(0.0);
varying vec3 lp;
varying vec3 wn;
void vertex(){ lp = VERTEX - hc; wn = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz; }
float hs(float n){ return fract(sin(n * 12.9898) * 43758.5453); }
void fragment(){
	// v8：程序化手繪動漫髮（分層髮束＋天使環高光）
	float ang = atan(lp.x, lp.z);
	float k = ang * 11.0;
	float id = floor(k); float f = fract(k);
	float strand = smoothstep(0.0, 0.3, f) * (1.0 - smoothstep(0.7, 1.0, f));
	float t = clamp(lp.y * 5.0 + 0.55, 0.0, 1.0);
	vec3 c = mix(c1.rgb, c2.rgb, clamp(t * 0.75 + 0.25 * strand + 0.15 * (hs(id) - 0.5), 0.0, 1.0));
	float ring = exp(-pow((lp.y - 0.06 - 0.015 * sin(ang * 3.0)) / 0.018, 2.0)) * (0.55 + 0.45 * strand);
	c = mix(c, mix(c2.rgb, vec3(1.0, 0.97, 0.88), 0.4), ring * 0.6);
	c *= 0.92;
	c *= 0.8 + 0.2 * strand;
	float up = clamp(normalize(wn).y * 0.5 + 0.5, 0.0, 1.0);
	c *= mix(0.85, 1.08, up);
	ALBEDO = c;
	ROUGHNESS = 0.6; SPECULAR = 0.3;
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	EMISSION = c2.rgb * fr * 0.1 + flash.rgb * flash.a;
}
"""
