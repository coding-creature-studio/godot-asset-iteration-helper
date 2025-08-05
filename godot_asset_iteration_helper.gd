@tool
extends EditorScenePostImport

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

    # Save collision shapes as .tres
    for shape_node in collision_shapes:
        if shape_node and shape_node.shape:
            var shape = shape_node.shape
            var shape_name_str = str(shape_node.name)
            var save_path_str = str(folder) + "/" + file_base + "_" + shape_name_str + "_collision.tres"
            shape.resource_name = shape_name_str + "_collision"
            var err = ResourceSaver.save(shape, save_path_str)
            if err == OK:
                var reloaded_shape = ResourceLoader.load(save_path_str, "", ResourceLoader.CACHE_MODE_REPLACE)
                if reloaded_shape:
                    shape_node.shape = reloaded_shape

    return scene

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