@tool
extends EditorInspectorPlugin

var PROPERTY = preload('res://addons/structure_resource/insp_editor_structure/structure_editor.scn')
const STRUCTURE = preload('res://addons/structure_resource/data_structure.gd')




func _can_handle(object: Object) -> bool:
	return object is STRUCTURE




func _parse_category(object: Object, category: String) -> void:
	if category == 'data_structure.gd':
		var editor = PROPERTY.instantiate()
		add_custom_control(editor)
		editor.edited = object
		object.connect(&'changed', editor.update)
		object.emit_changed()
