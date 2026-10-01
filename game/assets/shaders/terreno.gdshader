shader_type spatial;
// Terreno (Ciclo 4, ADR-027). O ChunkMesher manda tudo na cor do vértice pra
// economizar arrays: r = oclusão de ambiente do canto, g = camada da textura
// no Texture2DArray / 255, b = direção da face / 255 (ordem do mesher: cima,
// baixo, norte, sul, leste, oeste) e a = luz própria do bloco. Cabe no
// renderizador Compatibility, o único da Web.
render_mode cull_back, specular_disabled;

uniform sampler2DArray texturas : source_color, filter_nearest_mipmap, repeat_enable;
uniform float camada_folhas = 6.0;
uniform float vento = 0.045;

const vec3 NORMAIS[6] = vec3[6](
	vec3(0.0, 1.0, 0.0), vec3(0.0, -1.0, 0.0), vec3(0.0, 0.0, -1.0),
	vec3(0.0, 0.0, 1.0), vec3(1.0, 0.0, 0.0), vec3(-1.0, 0.0, 0.0)
);

varying float oclusao;
varying flat float camada;
varying float brilho;

void vertex() {
	oclusao = COLOR.r;
	camada = floor(COLOR.g * 255.0 + 0.5);
	brilho = COLOR.a;
	NORMAL = NORMAIS[int(floor(COLOR.b * 255.0 + 0.5))];
	if (camada == camada_folhas) {
		vec3 mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float onda = sin(TIME * 1.7 + mundo.x * 0.6 + mundo.y * 0.3)
			+ 0.5 * sin(TIME * 2.6 + mundo.z * 0.8);
		VERTEX.x += onda * vento;
		VERTEX.z += onda * vento * 0.6;
	}
}

void fragment() {
	vec3 cor = texture(texturas, vec3(UV, camada)).rgb;
	ALBEDO = cor * oclusao;
	EMISSION = cor * brilho * 1.6;
}
