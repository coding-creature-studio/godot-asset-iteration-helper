# ==============================================================================
# Asset Iteration Helper addon for the Godot Engine 4.4+
#
# Version: 1.1.0
# Godot Engine Compatibility: 4.4.0+B
# Author: Coding Creature
# License: GPL 3.0 
# Code Repository: https://github.com/coding-creature-studio/godot-asset-iteration-helper
# Documentation: https://codingcreature.com/addons/asset-iteration-helper/
# Follow on X: @CodingCreature
# ==============================================================================
@tool
extends EditorScenePostImport

var save_meshes = true
var save_collision_shapes = true
var save_materials = true

var collision_suffix = "_collision"
var material_suffix = "_material"

func _post_import(scene):
	var mesh_instances = _find_all_mesh_instances(scene)
	var collision_shapes = _find_all_collision_shapes(scene)
	var import_path = get_source_file()
	if not import_path or import_path == "":
		import_path = scene.get_filename()
	if not import_path or import_path == "":
		import_path = "res://"
	var folder = ""
	if typeof(import_path) == TYPE_STRING and import_path.find("/") != -1:
		folder = import_path.substr(0, import_path.rfind("/"))
	else:
		folder = "res://"
	var file_base = "imported"
	if typeof(import_path) == TYPE_STRING:
		var file_name = import_path.substr(import_path.rfind("/") + 1)
		if file_name.find(".") != -1:
			file_base = file_name.substr(0, file_name.find("."))
		else:
			file_base = file_name
	
	# Save meshes as .tres
	if save_meshes:
		for mesh_instance in mesh_instances:
			if mesh_instance and mesh_instance.mesh:
				var mesh = mesh_instance.mesh
				if mesh is Resource and mesh.get_class() == "ArrayMesh" and mesh.get_surface_count() > 0:
					var mesh_name_str = str(mesh_instance.name)
					var save_path_str = str(folder) + "/" + file_base + "_" + mesh_name_str + ".tres"
					mesh.resource_name = mesh_name_str
					var err = ResourceSaver.save(mesh, save_path_str)
					if err == OK:
						var reloaded_mesh = ResourceLoader.load(save_path_str, "", ResourceLoader.CACHE_MODE_REPLACE)
						if reloaded_mesh:
							mesh_instance.mesh = reloaded_mesh

	# Save only user-created materials as .tres
	if save_materials:
		for mesh_instance in mesh_instances:
			if mesh_instance and mesh_instance.mesh:
				var mesh = mesh_instance.mesh
				if mesh is Resource and mesh.get_class() == "ArrayMesh" and mesh.get_surface_count() > 0:
					var surface_count = mesh.get_surface_count()
					for i in range(surface_count):
						var material = mesh.surface_get_material(i)
						var debug_msg = "Material on mesh '" + str(mesh_instance.name) + "', surface " + str(i) + ": "
						if material:
							debug_msg += "resource_name='" + str(material.resource_name) + "', type=" + str(material.get_class()) + ", resource_path='" + str(material.resource_path) + "'"
						else:
							debug_msg += "None"
						print(debug_msg)
						
						# Check for user-created material
						var mat_name = str(material.resource_name)
						if material and mat_name != "" and mat_name != "unnamed material" and not _is_auto_generated_name(mat_name):
							print("Saving material: " + str(material.resource_name))
							var material_name_str = str(material.resource_name)
							var mat_save_path = str(folder) + "/" + file_base + "_" + material_name_str + material_suffix + ".tres"
							material.resource_name = material_name_str
							var mat_err = ResourceSaver.save(material, mat_save_path)
							if mat_err == OK:
								var reloaded_material = ResourceLoader.load(mat_save_path, "", ResourceLoader.CACHE_MODE_REPLACE)
								if reloaded_material:
									mesh.surface_set_material(i, reloaded_material)
						else:
							print("Skipping material: " + str(material.resource_name if material else "None"))

	# Save collision shapes as .tres
	if save_collision_shapes:
		for shape_node in collision_shapes:
			if shape_node and shape_node.shape:
				var shape = shape_node.shape
				var shape_name_str = str(shape_node.name)
				var save_path_str = str(folder) + "/" + file_base + "_" + shape_name_str + collision_suffix + ".tres"
				shape.resource_name = shape_name_str + collision_suffix
				var err = ResourceSaver.save(shape, save_path_str)
				if err == OK:
					var reloaded_shape = ResourceLoader.load(save_path_str, "", ResourceLoader.CACHE_MODE_REPLACE)
					if reloaded_shape:
						shape_node.shape = reloaded_shape

	return scene

func _is_auto_generated_name(name: String) -> bool:
	# Check if name follows pattern: ObjectName_mat + number
	var parts = name.split("_mat")
	if parts.size() == 2:
		var suffix = parts[1]
		return suffix.is_valid_int()
	return false

func _find_all_mesh_instances(node):
	var result = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result += _find_all_mesh_instances(child)
	return result

func _find_all_collision_shapes(node):
	var result = []
	if node is CollisionShape3D:
		result.append(node)
	for child in node.get_children():
		result += _find_all_collision_shapes(child)
	return result
