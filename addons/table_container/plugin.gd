@tool
extends EditorPlugin

var control: Container
var menu: VBoxContainer
var use_menu = false

func _enter_tree() -> void:
	menu = load('res://addons/table_container/components/side_menu.scn').instantiate()
	menu.get_node(^'BtnAdd').connect('pressed', func(): print('add'))


func _exit_tree() -> void:
	if is_instance_valid(menu):
		if menu.is_inside_tree():
			_edit(null)
			menu.queue_free()

func _handles(object):
	return use_menu or menu.is_inside_tree()


func _edit(object):
	if object is TableContainer:
		add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_RIGHT, menu)
	else:
		if menu.is_inside_tree():
			remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_RIGHT, menu)
