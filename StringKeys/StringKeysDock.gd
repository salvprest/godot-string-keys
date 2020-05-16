tool
extends Node

#TODO:
#Get csv file or make one
#Write keys to csv file
#Save and load settings/ presets
#if the user sets to print output
#Hide and make sure certian options are disabled when other are enabled
#Tooltips are accurate and make sure to list what is allowed (IE: No \ in prefix/suffix)
#Check that all comments should be there
#Maybes:
#	Only allow open tscns that aren't in ignored paths
#	Paths to only include rather than ignore as well
#	Figure out how it can check binary files such as .vs visual scripts or binary .scn and .res

#POTENTIAL ISSUES:
#Back slash \ and other special issues might be able to confuse what parts of a file are strings
#Certian situations may cause a problem when using an old .csv file as an input

#Test comment strings (Must remove addons from ignores path for this to work)
#	"$$This is a test key \"Quote\""
#   "Category$$Test key number 2 \\back\\ slashes \\"

var _working := false
var _files_to_search = []
var _allowed_formats = []
var _ignored_paths = []
var _keys = []

func _on_Button_pressed():
	if _working: #Cancel work
		_done_working()
	else: #Start working
		#Display:
		_working = true
		$VBox/ProgressBar.show()
		$VBox/Button.text = "Cancel..."
		#Work
		_find_files_to_search()
		_search_files_for_keys()
		_done_working()

func _done_working():
	_working = false
	$VBox/ProgressBar.hide()
	$VBox/ProgressBar.value = 0
	$VBox/Button.text = "Create Translation File"
	_files_to_search = []
	_allowed_formats = []
	_ignored_paths = []
	_keys = []

#Finding files:
func _find_files_to_search():
	if $VBox/Grid/CheckBox_OpenTscnsOnly.pressed:
		_files_to_search = EditorScript.new().get_editor_interface().get_open_scenes()
		_print_if_allowed("\nStringKeys files to search: " + str(_files_to_search))
	else:
		#allowed formats:
		var _formats_unformatted = $VBox/Grid/TextEdit_FileTypes.text.split(",", false)
		for f in _formats_unformatted:
			_allowed_formats.append("." + f.strip_edges()) #add . and strip of spaces/new lines
		#ignored paths:
		var _ign_paths_unformatted = $VBox/Grid/TextEdit_PathsToIgnore.text.split(",", false)
		for p in _ign_paths_unformatted:
			_ignored_paths.append("res://" + p.strip_edges()) #add res and strip spaces/new lines
		#search:
		_files_to_search = _get_files_in_directory_recursive("res://")
		#print:
		_print_if_allowed("\nStringKeys allowed formats: " + str(_allowed_formats))
		_print_if_allowed("StringKeys ignored paths: " + str(_ignored_paths))
		_print_if_allowed("\nStringKeys files to search: " + str(_files_to_search))

func _get_files_in_directory_recursive(path : String) -> Array:
	var dir = Directory.new()
	if dir.open(path) == OK:
		var file_paths = []
		dir.list_dir_begin(true, true) #Skip navigational and hidden, maybe shouldn't do hidden?
		var current_file = dir.get_next()
		while current_file != "":
			if dir.current_is_dir(): #look into a sub directory
				var full_dir_path = path + current_file
				if _is_path_allowed(full_dir_path):
					file_paths += _get_files_in_directory_recursive(full_dir_path + "/")
			else: #add a file
				if _is_file_allowed_format(current_file):
					file_paths.append(path + current_file)
			current_file = dir.get_next()
		return file_paths
	else:
		_print_if_allowed("ERROR: Couldn't open path: " + path)
		return []

func _is_file_allowed_format(file_name : String) -> bool:
	for i in _allowed_formats:
		if file_name.ends_with(i):
			return true
	return false

func _is_path_allowed(path : String) -> bool:
	return not _ignored_paths.has(path)

#Finding string keys in files:
func _search_files_for_keys():
	for f in _files_to_search:
		_append_array_to_array_unique(_keys, _find_keys_in_file(f))
	_keys.sort() #make alphabetical
	_print_if_allowed("\nStringKeys keys found: " + str(_keys))

func _find_keys_in_file(file_path : String) -> Array:
	var file = File.new()
	file.open(file_path, File.READ)
	var file_text : String = file.get_as_text()
	var found_keys = []
	var is_in_string := false
	var found_string : String
	var can_leave_string := true #used so that \ doesn't cause issues with whether a " is the end of a string, or part of it
	for c in file_text:
		if c == "\"" and can_leave_string: #character is an ", entering/leaving a string
			if is_in_string:
				if _is_string_a_key(found_string):
					found_keys.append(found_string)
				found_string = ""
				can_leave_string = true #now that it's exiting a string, allow it to leave next time
			is_in_string = not is_in_string 
		else: #is regular character, or couldn't leave due to a \
			if is_in_string: #then add this character
				found_string += c
				if c == "\\":
					can_leave_string = not can_leave_string #toggles in case of doubles
				else:
					can_leave_string = true #can always leave if last wasn't a \
	return found_keys

func _is_string_a_key(string : String) -> bool: #TODO: at least a suffix
	return string.find($VBox/Grid/LineEdit_Prefix.text) != -1
	
#Warnings:
func _on_CheckBox_ClearFile_toggled(button_pressed):
	$VBox/ClearFileWarning.visible = button_pressed

func _on_CheckBox_RemoveUnused_toggled(button_pressed):
	$VBox/RemoveUnusedWarning.visible = button_pressed

#Other:
func _print_if_allowed(thing): ##########################################################TODO Option
	print(thing)

func _append_array_to_array_unique(original: Array, addition: Array):
	for a in addition:
		if not original.has(a):
			original.append(a)
