shader_type spatial;
// Capim e flores (Ciclo 4, ADR-027): planos cruzados com recorte pela
// transparência da textura e a ponta balançando ao vento. COLOR.g = camada
// no Texture2DArray / 255, COLOR.a = luz própria (a flor-lúmen brilha à noite).
render_mode cull_disabled, specular_disabled;

uniform sampler2DArray texturas : source_color, filter_nearest_mipmap, repeat_disable;
uniform float vento = 0.09;

varying flat float camada;
varying float brilho;

void vertex() {
	camada = floor(COLOR.g * 255.0 + 0.5);
	brilho = COLOR.a;
	NORMAL = vec3(0.0, 1.0, 0.0); // iluminada como o chão em volta
	float ponta = 1.0 - UV.y;
	vec3 mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float onda = sin(TIME * 2.1 + mundo.x * 0.9 + mundo.z * 0.7) + 0.4 * sin(TIME * 3.3 + mundo.z * 1.3);
	VERTEX.x += onda * vento * ponta;
	VERTEX.z += onda * vento * 0.5 * ponta;
}

void fragment() {
	vec4 t = texture(texturas, vec3(UV, camada));
	ALBEDO = t.rgb;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	EMISSION = t.rgb * brilho;
}
