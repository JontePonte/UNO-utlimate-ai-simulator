@tool
extends EditorScript

func _run():
	var fs = EditorInterface.get_resource_filesystem()
	var root = fs.get_filesystem()
	_resave_recursive(root)
	print("Done resaving!")

func _resave_recursive(dir):
	# Loop files
	for i in range(dir.get_file_count()):
		var file_name = dir.get_file(i)
		var path = dir.get_path() + "/" + file_name

		if file_name.ends_with(".tscn") or file_name.ends_with(".tres") or file_name.ends_with(".scn"):
			var res = load(path)
			if res:
				var err = ResourceSaver.save(res, path)
				if err != OK:
					push_error("Failed to save: " + path)

	# Loop subdirectories
	for i in range(dir.get_subdir_count()):
		var subdir = dir.get_subdir(i)
		_resave_recursive(subdir)
