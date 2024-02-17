@tool
extends EditorPlugin


func _enter_tree() -> void:
	var struct = Structure.new({
		&'some_field': {type = TYPE_INT, default = 0},
		&'one_more': {type = TYPE_STRING, default = ''}
	})
	var struct2 = Structure.new({
		&'some_field': {type = TYPE_INT, default = 0},
		&'one_more': {type = TYPE_STRING, default = ''}
	})
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
