class_name LuzLook
extends RefCounted
## Variações de luz e cor (rodada visual de 20/11/2026), por cima da luz de cada ato (GroundLooks.apply_env).
## 0 = a luz de hoje, sem mexer em nada (padrão). --luz=N em game/main.gd.
##   1 dia limpo: pouca névoa, sol quente e céu frio, cores mais vivas.
##   2 fim de tarde quente: sol baixo e dourado, sombras longas, sombra azulada.
##   3 contraste forte: sol forte, sombra escura e definida, ambiente azul.
## Cada variação parte da luz do ato (cor, ângulo, névoa) e puxa para o alvo; por isso vale em todos os atos
## e a troca de ato (crossfade em main.gd) continua misturando de um ato para o outro.

static var VAR := 2   # padrão aprovado em 20/11/2026 na página de revisão (0 = como era antes)

const NAMES := ["Atual", "Dia limpo", "Fim de tarde quente", "Contraste forte"]

# Por variação: quanto o sol puxa para o quente (cor e alvo), o ambiente para o frio, a névoa que sobra,
# multiplicadores de energia, elevação do sol (graus, negativo = para baixo), saturação e contraste somados.
const P := {
	1: {"sun_to": Color(1.0, 0.93, 0.78), "sun_k": 0.45, "sun_e": 1.2, "amb_to": Color(0.55, 0.68, 0.95), "amb_k": 0.35, "amb_e": 0.95,
		"fog": 0.3, "vfog": 0.25, "fog_sky": 0.25, "elev": -52.0, "elev_k": 0.4, "sat": 0.1, "con": 0.07, "expo": 1.0,
		"blur": 0.5, "ssao": 2.0, "rim_e": 0.9, "fog_to": Color(0.78, 0.86, 1.0), "fog_k": 0.4},
	2: {"sun_to": Color(1.0, 0.72, 0.46), "sun_k": 0.42, "sun_e": 1.3, "amb_to": Color(0.42, 0.5, 0.82), "amb_k": 0.45, "amb_e": 0.8,
		"fog": 0.45, "vfog": 0.4, "fog_sky": 0.4, "elev": -23.0, "elev_k": 0.65, "sat": 0.05, "con": 0.1, "expo": 0.98,
		"blur": 0.35, "ssao": 2.4, "rim_e": 1.2, "fog_to": Color(0.95, 0.68, 0.5), "fog_k": 0.45},
	3: {"sun_to": Color(1.0, 0.88, 0.66), "sun_k": 0.4, "sun_e": 1.45, "amb_to": Color(0.25, 0.34, 0.85), "amb_k": 0.65, "amb_e": 0.45,
		"fog": 0.3, "vfog": 0.25, "fog_sky": 0.3, "elev": -36.0, "elev_k": 0.6, "sat": 0.04, "con": 0.2, "expo": 1.0,
		"blur": 0.15, "ssao": 3.0, "rim_e": 1.0, "fog_to": Color(0.45, 0.55, 0.8), "fog_k": 0.4},
}


static func apply(env: Environment, sun: DirectionalLight3D, rim: DirectionalLight3D = null) -> void:
	if VAR <= 0 or not P.has(VAR):
		return
	var q: Dictionary = P[VAR]
	sun.light_color = sun.light_color.lerp(q["sun_to"], q["sun_k"])
	sun.light_energy *= q["sun_e"]
	var r := sun.rotation_degrees
	r.x = lerpf(r.x, q["elev"], q["elev_k"])
	sun.rotation_degrees = r
	sun.shadow_blur = q["blur"]
	sun.light_angular_distance = 0.0
	env.ambient_light_color = env.ambient_light_color.lerp(q["amb_to"], q["amb_k"])
	env.ambient_light_energy *= q["amb_e"]
	env.fog_density *= q["fog"]
	env.fog_light_color = env.fog_light_color.lerp(q["fog_to"], q["fog_k"])
	env.fog_sky_affect = q["fog_sky"]
	env.volumetric_fog_density *= q["vfog"]
	env.adjustment_saturation += q["sat"]
	env.adjustment_contrast += q["con"]
	env.tonemap_exposure *= q["expo"]
	env.ssao_intensity = q["ssao"]
	if rim:
		rim.light_energy *= q["rim_e"]
