extends RayCast3D

var last_hit_object: GeometryInstance3D = null

func _physics_process(_delta: float) -> void:
	if is_colliding():
		var hit = get_collider()
		
		# Check if we hit a mesh or an object containing a mesh (like a wall or tree)
		if hit is StaticBody3D or hit is Node3D:
			# Look for the visual mesh inside the object
			var mesh_node = hit.find_child("*MeshInstance3D*", true, false)
			if mesh_node and mesh_node is MeshInstance3D:
				# If it's a new object, reset the old one and fade this one
				if last_hit_object and last_hit_object != mesh_node:
					_reset_opacity(last_hit_object)
				
				last_hit_object = mesh_node
				_fade_out(mesh_node)
	else:
		# If the raycast hits nothing, restore the last faded object back to solid
		if last_hit_object:
			_reset_opacity(last_hit_object)
			last_hit_object = null

func _fade_out(mesh: MeshInstance3D):
	# Ensure the material allows transparency (StandardMaterial3D configuration)
	var mat = mesh.get_active_material(0)
	if mat is StandardMaterial3D:
		mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		# Smoothly blend to semi-transparent (0.2 opacity)
		mat.albedo_color.a = lerp(mat.albedo_color.a, 0.2, 0.1)

func _reset_opacity(mesh: MeshInstance3D):
	var mat = mesh.get_active_material(0)
	if mat is StandardMaterial3D:
		mat.albedo_color.a = lerp(mat.albedo_color.a, 1.0, 0.1)
		# Turn off transparency completely once it's fully solid to save performance
		if mat.albedo_color.a > 0.99:
			mat.transparency = StandardMaterial3D.TRANSPARENCY_DISABLED
