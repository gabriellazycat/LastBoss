class_name LuzLook
extends RefCounted
## Luz de fim de tarde quente (20/11/2026) por cima da luz de cada ato (GroundLooks.apply_env): sol baixo e dourado,
## sombras longas, sombra azulada. Parte da luz do ato (cor, ângulo, névoa) e puxa para o alvo; por isso vale em todos
## os atos e a troca de ato (crossfade em main.gd) continua misturando de um ato para o outro.

# Quanto o sol puxa para o quente (cor e alvo), o ambiente para o frio, a névoa que sobra, multiplicadores de energia,
# elevação do sol (graus, negativo = para baixo), saturação e contraste somados.
const Q := {"sun_to": Color(1.0, 0.72, 0.46), "sun_k": 0.42, "sun_e": 1.3, "amb_to": Color(0.42, 0.5, 0.82), "amb_k": 0.45, "amb_e": 0.8,
		"fog": 0.45, "vfog": 0.4, "fog_sky": 0.4, "elev": -23.0, "elev_k": 0.65, "sat": 0.05, "con": 0.1, "expo": 0.98,
		"blur": 0.35, "ssao": 2.4, "rim_e": 1.2, "fog_to": Color(0.95, 0.68, 0.5), "fog_k": 0.45}


static func apply(env: Environment, sun: DirectionalLight3D, rim: DirectionalLight3D = null) -> void:
	var q: Dictionary = Q
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
