extends Node

const AI_FOLDER_PATH = "user://ai_profiles/"
var file_to_edit: String = ""

func _ready():
	_ensure_ai_folder_exists()

func _ensure_ai_folder_exists():
	var user_dir = DirAccess.open("user://")
	
	# 1. Skapa mappen om den inte finns
	if not user_dir.dir_exists("ai_profiles"):
		user_dir.make_dir("ai_profiles")
		
	# 2. Öppna res:// och loopa igenom alla dina standard-AI:s
	var res_dir = DirAccess.open("res://ai_profiles/")
	if res_dir:
		res_dir.list_dir_begin()
		var file_name = res_dir.get_next()
		
		while file_name != "":
			if not res_dir.current_is_dir() and file_name.ends_with(".json"):
				var dest_path = AI_FOLDER_PATH + file_name
				var source_path = "res://ai_profiles/" + file_name
				
				# 3. Den magiska kollen: Finns just DEN HÄR filen i user://?
				if not FileAccess.file_exists(dest_path):
					# Nej? Då kopierar vi över den!
					var file_to_copy = FileAccess.open(source_path, FileAccess.READ)
					var content = file_to_copy.get_as_text()
					file_to_copy.close()
					
					var new_file = FileAccess.open(dest_path, FileAccess.WRITE)
					new_file.store_string(content)
					new_file.close()
					
			file_name = res_dir.get_next()
		res_dir.list_dir_end()

# En bonus-funktion! Alla andra scener kan anropa denna för att få en färdig lista på filer.
func get_all_ai_files() -> Array[String]:
	var ai_files: Array[String] = []
	var dir = DirAccess.open(AI_FOLDER_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				ai_files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return ai_files
