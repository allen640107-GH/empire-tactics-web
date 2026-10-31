extends RefCounted
# v15 標題／序章用 shader
const BG := """shader_type canvas_item;
float h(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float n(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(h(i),h(i+vec2(1,0)),f.x),mix(h(i+vec2(0,1)),h(i+vec2(1,1)),f.x),f.y);}
uniform float warm = 1.0;
void fragment(){
	vec2 uv=UV;
	float sky=smoothstep(0.55,0.25,uv.y);
	uv.x += sky*(n(uv*vec2(3.,6.)+vec2(TIME*0.05,0.))-0.5)*0.006;
	// 瀑布流動（左下）
	float wf=smoothstep(0.035,0.0,abs(uv.x-0.225))*smoothstep(0.62,0.7,uv.y);
	uv.y += wf*(n(vec2(uv.x*80.,uv.y*20.-TIME*3.))-0.5)*0.01;
	vec4 c=texture(TEXTURE,uv);
	c.rgb += wf*0.10*n(vec2(uv.x*120.,uv.y*30.-TIME*4.));
	c.rgb = mix(c.rgb, c.rgb*vec3(1.08,0.98,0.82), warm);
	COLOR=c;
}"""
const RAYS := """shader_type canvas_item;
render_mode blend_add;
uniform vec2 sun = vec2(0.85,0.47);
uniform float strength = 0.22;
void fragment(){
	vec2 d=UV-sun; d.x*=1.78;
	float a=atan(d.y,d.x); float r=length(d);
	float rays=0.5+0.5*sin(a*13.+TIME*0.25)*sin(a*7.-TIME*0.17+1.3);
	rays=pow(rays,3.);
	float fall=exp(-r*1.6);
	float glow=exp(-r*7.)*1.2;
	vec3 col=vec3(1.0,0.72,0.38)*(rays*fall*strength+glow*0.35);
	COLOR=vec4(col,1.0);
}"""
const VIG := """shader_type canvas_item;
uniform float amt = 0.75;
uniform vec4 tint : source_color = vec4(0.12,0.06,0.02,1.0);
void fragment(){
	vec2 d=UV-0.5; d.x*=1.3;
	float v=smoothstep(0.32,0.85,length(d));
	float bot=smoothstep(0.55,1.0,UV.y)*0.35;
	COLOR=vec4(tint.rgb, clamp(v*amt+bot,0.,0.95));
}"""
const GOLD := """shader_type canvas_item;
varying vec2 lp;
uniform float h = 160.0;
void vertex(){lp=VERTEX;}
void fragment(){
	float a=COLOR.a;
	float y=clamp((lp.y-20.)/h,0.,1.);
	vec3 g=mix(vec3(1.0,0.93,0.66),vec3(0.80,0.52,0.18),smoothstep(0.15,0.75,y));
	g=mix(g,vec3(0.55,0.32,0.10),smoothstep(0.75,1.0,y));
	float band=lp.x*0.6+lp.y*0.8-mod(TIME*260.,2600.)+300.;
	float sh=exp(-band*band/1800.);
	g+=vec3(1.0,0.95,0.8)*sh*0.75;
	COLOR=vec4(g,a);
}"""
const BANNER := """shader_type canvas_item;
void fragment(){
	vec2 uv=UV;
	float w=sin(uv.y*7.-TIME*2.2)*0.5+sin(uv.y*13.-TIME*3.1+uv.x*2.)*0.25;
	uv.x += w*0.035*uv.y;
	uv.y += w*0.006;
	vec4 c=texture(TEXTURE,uv);
	float shade=0.82+0.25*cos(uv.y*7.-TIME*2.2);
	c.rgb*=shade*vec3(1.05,0.95,0.85);
	COLOR=c;
}"""
const PAINT := """shader_type canvas_item;
uniform float sep = 0.25;
float h(vec2 p){return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453);}
void fragment(){
	vec4 c=texture(TEXTURE,UV);
	float l=dot(c.rgb,vec3(0.3,0.59,0.11));
	c.rgb=mix(c.rgb,vec3(l)*vec3(1.1,0.95,0.75),sep);
	c.rgb+= (h(UV*vec2(1600.,900.)+fract(TIME))-0.5)*0.035;
	COLOR=c;
}"""
static func mat(code: String) -> ShaderMaterial:
	var s := Shader.new(); s.code = code
	var m := ShaderMaterial.new(); m.shader = s; return m
