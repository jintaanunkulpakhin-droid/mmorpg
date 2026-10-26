class_name Fx
## Spell and level-up effects: magic circles, light pillars, sparkles,
## fire and floating damage numbers. They all clean themselves up.
##
## Every effect is made from simple shapes plus the shaders in res://shaders,
## so there are no texture files. Call them from anywhere, for example:
##   Fx.magic_circle(get_tree().current_scene, player.global_position, Color.CYAN)

const CIRCLE_SHADER := preload("res://shaders/magic_circle.gdshader")
const PILLAR_SHADER := preload("res://shaders/light_pillar.gdshader")

static var _dot_texture: Texture2D


## A round glowing circle on the floor that spins for "duration" seconds.
static func magic_circle(parent: Node, pos: Vector3, color: Color, radius := 1.3, duration := 1.0) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.global_position = pos + Vector3(0, 0.04, 0)

	var quad := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(radius * 2.0, radius * 2.0)
	quad.mesh = mesh
	var mat := ShaderMaterial.new()
	mat.shader = CIRCLE_SHADER
	mat.set_shader_parameter("color", color)
	mat.set_shader_parameter("fade", 0.0)
	quad.material_override = mat
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(quad)

	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 0.0
	light.omni_range = radius * 2.5
	light.position = Vector3(0, 0.6, 0)
	root.add_child(light)

	var tween := root.create_tween().set_parallel()
	tween.tween_method(func(t: float) -> void: mat.set_shader_parameter("spin", t), 0.0, duration * 2.5, duration)
	tween.tween_method(func(f: float) -> void:
		mat.set_shader_parameter("fade", f)
		light.light_energy = f * 2.0, 0.0, 1.0, 0.15)
	tween.tween_method(func(f: float) -> void:
		mat.set_shader_parameter("fade", f)
		light.light_energy = f * 2.0, 1.0, 0.0, 0.25).set_delay(duration - 0.25)
	tween.tween_property(root, "scale", Vector3.ONE, 0.2).from(Vector3(0.4, 1.0, 0.4))
	tween.chain().tween_callback(root.queue_free)
	# Little twinkles floating up off the circle.
	sparkles(parent, pos, color.lightened(0.5), int(12 + radius * 14), true, duration)
	return root


## A column of light shooting up from the floor.
static func light_pillar(parent: Node, pos: Vector3, color: Color, radius := 0.8, height := 5.0, duration := 1.2) -> void:
	var root := Node3D.new()
	parent.add_child(root)
	root.global_position = pos

	var tube := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.6
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.cap_top = false
	mesh.cap_bottom = false
	mesh.radial_segments = 24
	tube.mesh = mesh
	tube.position.y = height * 0.5
	var mat := ShaderMaterial.new()
	mat.shader = PILLAR_SHADER
	mat.set_shader_parameter("color", color)
	tube.material_override = mat
	tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(tube)

	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 3.0
	light.omni_range = 6.0
	light.position.y = 1.0
	root.add_child(light)

	var tween := root.create_tween().set_parallel()
	tween.tween_property(tube, "scale", Vector3.ONE, 0.18).from(Vector3(0.2, 0.2, 0.2))
	tween.tween_method(func(t: float) -> void: mat.set_shader_parameter("scroll", t), 0.0, duration * 3.0, duration)
	tween.tween_method(func(f: float) -> void:
		mat.set_shader_parameter("fade", f)
		light.light_energy = f * 3.0, 1.0, 0.0, duration * 0.5).set_delay(duration * 0.5)
	tween.chain().tween_callback(root.queue_free)


## A burst of glowing dots. "rise" makes them float up instead of spraying out.
static func sparkles(parent: Node, pos: Vector3, color: Color, amount := 40, rise := false, lifetime := 1.0) -> void:
	var p := CPUParticles3D.new()
	parent.add_child(p)
	p.global_position = pos
	p.one_shot = true
	p.explosiveness = 0.0 if rise else 0.9
	p.amount = amount
	p.lifetime = lifetime
	p.mesh = _dot_mesh(color)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.5 if rise else 0.25
	if rise:
		p.direction = Vector3.UP
		p.spread = 15.0
		p.gravity = Vector3(0, 1.5, 0)
		p.initial_velocity_min = 0.8
		p.initial_velocity_max = 2.5
	else:
		p.direction = Vector3.UP
		p.spread = 180.0
		p.gravity = Vector3(0, -2.0, 0)
		p.initial_velocity_min = 2.0
		p.initial_velocity_max = 4.5
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	p.emitting = true
	p.finished.connect(p.queue_free)


## Flames that lick upward for a moment (used by Benika's fire skill).
static func fire(parent: Node, pos: Vector3, duration := 0.8) -> void:
	var p := CPUParticles3D.new()
	parent.add_child(p)
	p.global_position = pos
	p.amount = 70
	p.lifetime = 0.7
	p.mesh = _dot_mesh(Color(1.0, 0.45, 0.15), 0.55)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.6
	p.direction = Vector3.UP
	p.spread = 12.0
	p.gravity = Vector3(0, 4.0, 0)
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.5
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.6))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	var colors := Gradient.new()
	colors.set_color(0, Color(1.0, 0.9, 0.5))
	colors.set_color(1, Color(0.8, 0.1, 0.05))
	p.color_ramp = colors
	p.emitting = true

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.5, 0.2)
	light.light_energy = 3.0
	light.omni_range = 5.0
	light.position.y = 1.0
	p.add_child(light)

	var tween := p.create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(func() -> void: p.emitting = false)
	tween.tween_property(light, "light_energy", 0.0, 0.6)
	tween.tween_callback(p.queue_free)


## A number that pops up above someone's head and floats away.
static func damage_number(parent: Node, pos: Vector3, text: String, color: Color, big := false) -> void:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.pixel_size = 0.0011 if big else 0.0008
	label.font_size = 40
	label.outline_size = 12
	label.modulate = color
	label.outline_modulate = Color(0.08, 0.04, 0.02)
	label.render_priority = 10
	label.outline_render_priority = 9
	parent.add_child(label)
	label.global_position = pos + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.2, 0.2))

	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "scale", Vector3.ONE, 0.15).from(Vector3.ONE * 1.8)
	tween.tween_property(label, "position:y", label.position.y + 1.0, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.6)
	tween.tween_property(label, "outline_modulate:a", 0.0, 0.3).set_delay(0.6)
	tween.chain().tween_callback(label.queue_free)


## One glowing dot used by all particle effects (a small soft-edged square
## that always faces the camera and adds light instead of covering things).
static func _dot_mesh(color: Color, size := 0.18) -> QuadMesh:
	if _dot_texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		var tex := GradientTexture2D.new()
		tex.gradient = gradient
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(0.5, 0.0)
		tex.width = 32
		tex.height = 32
		_dot_texture = tex
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = color
	mat.albedo_texture = _dot_texture
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	quad.material = mat
	return quad
