shader_type sky;
// Céu do Vale Dourado (Ciclo 4, ADR-027): degradê topo/horizonte, sol com
// halo de dia, lua e estrelas à noite e nuvens fofas que andam com o vento.
// As cores vêm do DayNightCalculator a cada quadro (scenes/main.gd).

uniform vec3 cor_topo : source_color = vec3(0.23, 0.53, 1.0);
uniform vec3 cor_horizonte : source_color = vec3(0.75, 0.89, 1.0);
uniform vec3 cor_luz : source_color = vec3(1.0, 0.97, 0.92);
uniform float noite : hint_range(0.0, 1.0) = 0.0;
uniform float cobertura_nuvens : hint_range(0.0, 1.0) = 0.45;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * ruido(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 dir = EYEDIR;
	float altura = clamp(dir.y, -1.0, 1.0);
	float t = pow(clamp(altura, 0.0, 1.0), 0.55);
	vec3 cor = mix(cor_horizonte, cor_topo, t);
	// abaixo do horizonte: névoa na cor do horizonte, levemente mais escura
	cor = mix(cor, cor_horizonte * 0.85, smoothstep(0.0, -0.25, altura));

	vec3 dir_luz = LIGHT0_DIRECTION;
	float alinhamento = max(dot(dir, dir_luz), 0.0);
	// de dia: disco do sol e halo largo na cor da luz
	float dia = 1.0 - noite;
	cor += cor_luz * pow(alinhamento, 12.0) * 0.35 * dia;
	cor += cor_luz * pow(alinhamento, 160.0) * 0.9 * dia;
	cor = mix(cor, vec3(1.0, 0.98, 0.9) * 2.4, smoothstep(0.9993, 0.9997, alinhamento) * dia);
	// à noite: lua no lugar do sol e estrelas piscando
	float lua = smoothstep(0.99935, 0.9996, alinhamento) * noite;
	cor = mix(cor, vec3(0.92, 0.94, 1.0) * 1.6, lua);
	cor += vec3(0.55, 0.62, 0.9) * pow(alinhamento, 60.0) * 0.25 * noite;
	if (noite > 0.01 && altura > 0.0) {
		vec3 d = dir * 160.0;
		vec3 celula = floor(d);
		float h = fract(sin(dot(celula, vec3(12.9898, 78.233, 45.164))) * 43758.5453);
		if (h > 0.985) {
			float dist = length(fract(d) - 0.5);
			float brilho = smoothstep(0.22, 0.0, dist) * (0.6 + 0.4 * sin(TIME * 2.0 + h * 50.0));
			cor += vec3(1.0, 0.95, 0.85) * brilho * noite * smoothstep(0.0, 0.2, altura);
		}
	}

	// nuvens projetadas num plano alto, andando devagar
	if (altura > 0.0) {
		vec2 p = dir.xz / (altura + 0.18) * 1.6 + vec2(TIME * 0.012, TIME * 0.004);
		float n = fbm(p);
		float nuvem = smoothstep(1.0 - cobertura_nuvens, 1.0 - cobertura_nuvens + 0.25, n);
		nuvem *= smoothstep(0.0, 0.18, altura);
		vec3 cor_nuvem = mix(vec3(1.0), cor_luz, 0.35) * mix(1.0, 0.25, noite);
		cor_nuvem = mix(cor_nuvem, cor_horizonte, 0.25);
		float sombra = smoothstep(0.55, 0.95, fbm(p + vec2(0.08, 0.05)));
		cor_nuvem *= 1.0 - sombra * 0.18;
		cor = mix(cor, cor_nuvem, nuvem * 0.85);
	}
	COLOR = cor;
}
