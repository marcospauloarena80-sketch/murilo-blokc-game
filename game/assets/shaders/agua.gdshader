shader_type spatial;
// Água dos lagos (Ciclo 4, ADR-027): ondulação procedural (sem textura),
// transparência que aumenta olhando de lado (fresnel), reflexo do sol e espuma
// clara nas cristas. Sem leitura de tela, pra caber no Compatibility da Web.
render_mode blend_mix, cull_back, depth_draw_opaque;

uniform vec3 cor_rasa : source_color = vec3(0.28, 0.78, 0.86);
uniform vec3 cor_funda : source_color = vec3(0.07, 0.36, 0.66);
uniform vec3 cor_ceu : source_color = vec3(0.75, 0.89, 1.0);

varying vec3 mundo;

float ondas(vec2 p) {
	return sin(p.x * 1.3 + TIME * 1.4) * 0.5
		+ sin(p.y * 1.7 - TIME * 1.1) * 0.35
		+ sin((p.x + p.y) * 2.3 + TIME * 2.0) * 0.15;
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += ondas(mundo.xz) * 0.025;
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	float e = 0.08;
	float dx = ondas(mundo.xz + vec2(e, 0.0)) - ondas(mundo.xz - vec2(e, 0.0));
	float dz = ondas(mundo.xz + vec2(0.0, e)) - ondas(mundo.xz - vec2(0.0, e));
	vec3 normal_mundo = normalize(vec3(-dx * 0.6, 1.0, -dz * 0.6));
	NORMAL = normalize((VIEW_MATRIX * vec4(normal_mundo, 0.0)).xyz);
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	float crista = smoothstep(0.72, 0.95, ondas(mundo.xz * 1.7) * 0.5 + 0.5);
	vec3 cor = mix(cor_funda, cor_rasa, 0.45 + 0.35 * crista);
	cor = mix(cor, cor_ceu, fresnel * 0.6);
	ALBEDO = cor + vec3(0.9) * crista * 0.12;
	ALPHA = mix(0.62, 0.93, fresnel);
	ROUGHNESS = 0.06;
	SPECULAR = 0.7;
	METALLIC = 0.0;
}
