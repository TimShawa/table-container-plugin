@icon('res://addons/table_container/icon.png')
@tool
extends VBoxContainer
class_name TableContainer

const SCENE: PackedScene = preload('res://addons/table_container/table_container.scn')
const cells = {
	row = preload('res://addons/table_container/components/table_row.scn'),
	cell = preload('res://addons/table_container/components/table_cell.scn'),
	head = preload('res://addons/table_container/components/table_header.scn')
}
@export var table: Dictionary = {}
@export_group('Parameters')
@export var fields: Dictionary = {}
@export var hide_keys := false:
	set(value):
		hide_keys = value
		update()
@export var hide_headers := false:
	set(value):
		hide_headers = value
		update()


func _enter_tree() -> void:
	if !(get_child_count(1) - get_child_count()):
		var inst = SCENE.instantiate() as PanelContainer
		add_child(inst, 0, Node.INTERNAL_MODE_BACK)
	await get_tree().process_frame
	update()

func clear(clear_header = false):
	if clear_header:
		var children = $Panel/Scroll/VBox/Header.get_children(1).slice(1)
		for i in children:
			$Panel/Scroll/VBox/Header.remove_child(i)
		for i in children:
			i.queue_free()
	var children = $Panel/Scroll/VBox.get_children(1).slice(1)
	for i in children:
		$Panel/Scroll/VBox.remove_child(i)
	for i in children:
		i.queue_free()


func update():
	clear(true)
	$Panel/Scroll/VBox/Header.visible = !hide_headers
	$Panel/Scroll/VBox/Header/Key.visible = !hide_keys
	for column in fields:
		var field = cells.head.instantiate()
		field.get_child(0).text = column
		$Panel/Scroll/VBox/Header.add_child(field)
	for key in table:
		var row = cells.row.instantiate()
		$Panel/Scroll/VBox.add_child(row)
		if !hide_keys:
			var name = cells.cell.instantiate()
			name.text = var2str(key)
			row.get_child(0).add_child(name)
		for field in fields:
			var value
			if field in table[key]:
				print(is_values_compatible(fields[field], table[key][field]))
				value = table[key][field]
			else:
				value = fields[field]
			var cell = cells.cell.instantiate()
			cell.text = var2str(value)
			row.get_child(0).add_child(cell)


func var2str(value):
	if typeof(value) == TYPE_NIL:
		return '<null>'
	if typeof(value) == TYPE_OBJECT:
		if value == null:
			return '<empty>'
		if !is_instance_valid(value):
			return '<invalid>'
		if value is PackedDataContainer or value is PackedDataContainerRef:
			return 'Packed data (size ' + String.num_int64(value.size()) + ')'
		return value.to_string()
	if typeof(value) in [ TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH ]:
		return String(value)
	if typeof(value) == TYPE_DICTIONARY:
		return 'Dictionary (size' + String.num_int64(value.size()) + ')'
	if typeof(value) == TYPE_INT:
		return String.num_int64(value)
	if typeof(value) == TYPE_FLOAT:
		return String.num(value, 4)
	if typeof(value) == TYPE_BOOL:
		return 'true' if value else 'false'
	if typeof(value) == TYPE_VECTOR2:
		return '(' + String.num(value.x, 4) + ', ' + String.num(value.y, 4) + ')'
	if typeof(value) == TYPE_VECTOR2I:
		return '(' + String.num_int64(value.x, 4) + ', ' + String.num_int64(value.x) + ')'
	if typeof(value) == TYPE_VECTOR3:
		return '(' + String.num(value.x, 4) + ', ' + String.num(value.y, 4) + ', ' + String.num(value.z, 4) + ')'
	if typeof(value) == TYPE_VECTOR3I:
		return '(' + String.num_int64(value.x, 4) + ', ' + String.num_int64(value.y) + ', ' + String.num_int64(value.z) + ')'
	if typeof(value) == TYPE_VECTOR4:
		return '(' + String.num(value.x, 4) + ', ' + String.num(value.y, 4) + ', ' + String.num(value.z, 4) + ', ' + String.num(value.w, 4) + ')'
	if typeof(value) == TYPE_VECTOR4I:
		return '(' + String.num_int64(value.x, 4) + ', ' + String.num_int64(value.x) + ', ' + String.num_int64(value.z) + ', ' + String.num_int64(value.w) + ')'
	if typeof(value) == TYPE_RECT2:
		return '[P: ' + var2str(value.position) + ', S: ' + var2str(value.size)
	if typeof(value) == TYPE_RECT2I:
		return '[P: ' + var2str(value.position as Vector2i) + ', S: ' + var2str(value.size as Vector2i) + ']'
	if typeof(value) == TYPE_AABB:
		return '[P: ' + var2str(value.position as Vector3) + ', S: ' + var2str(value.size as Vector3) + ']'
	if typeof(value) == TYPE_PLANE:
		return '[N: ' + var2str(value.normal) + ', D: ' + String.num(value.d, 4) + ']'
	if typeof(value) == TYPE_QUATERNION:
		value = value.normalized()
		return '(' + String.num(value.x, 4) + ', ' + String.num(value.y, 4) + ', ' + String.num(value.z, 4) + ', ' + String.num(value.w, 4) + ')'
	if typeof(value) == TYPE_BASIS:
		value = value.orthonormalized()
		return '[X: ' + var2str(value.x) + ', Y: ' + var2str(value.y) + ', Z: ' + var2str(value.z) + ']'
	if typeof(value) == TYPE_TRANSFORM2D:
		return '[X: ' + var2str(value.x) + ', Y: ' + var2str(value.y) + ', O: ' + var2str(value.origin) + ']'
	if typeof(value) == TYPE_TRANSFORM3D:
		return '[X: ' + var2str(value.basis.x) + ', Y: ' + var2str(value.basis.y) + ', Z: ' + var2str(value.basis.z) + ', O: ' + var2str(value.origin) + ']'
	if typeof(value) == TYPE_PROJECTION:
		return '[X: ' + var2str(value.x) + ', Y: ' + var2str(value.y) + ', Z: ' + var2str(value.z) + ', W: ' + var2str(value.w) + ']'
	if typeof(value) == TYPE_COLOR:
		var text = '#' + value.to_html()
		if text.ends_with('ff'):
			text = text.left(-2)
		return text.to_upper()
	if typeof(value) == TYPE_ARRAY:
		return 'Array (size ' + String.num_int64(value.size()) + ')'
	if typeof(value) == TYPE_PACKED_BYTE_ARRAY:
		return 'Array of bytes (size ' + String.num_int64(value.size()) + ')'
	if typeof(value) == TYPE_PACKED_COLOR_ARRAY:
		return 'Array of colors (size ' + String.num_int64(value.size()) + ')'
	if typeof(value) == TYPE_PACKED_FLOAT32_ARRAY:
		return 'Array of half-precise floats (size ' + String.num_int64(value.size()) + ')'
	if typeof(value) == TYPE_PACKED_FLOAT64_ARRAY:
		return 'Array of floats (size ' + String.num_int64(value.size()) + ')'
	if typeof(value) == TYPE_PACKED_INT32_ARRAY:
		return 'Array of half-precise integers (size ' + String.num_int64(value.size()) + ')'
	if typeof(value) == TYPE_PACKED_INT64_ARRAY:
		return 'Array of integers (size ' + String.num_int64(value.size()) + ')'
	if typeof(value) == TYPE_PACKED_STRING_ARRAY:
		return 'Array of strings (size ' + String.num_int64(value.size()) + ')'
	if typeof(value) == TYPE_PACKED_VECTOR2_ARRAY:
		return 'Array of 2D-vectors (size ' + String.num_int64(value.size()) + ')'
	if typeof(value) == TYPE_PACKED_VECTOR3_ARRAY:
		return 'Array of 3D-vectors (size ' + String.num_int64(value.size()) + ')'

func _get_property_list() -> Array[Dictionary]:
	return [
		{ 'name': '', 'type': TYPE_STRING, 'usage': PROPERTY_USAGE_GROUP},
		{ 'name': 'refresh', 'type': TYPE_BOOL }
	]

func _set(prop, val):
	if prop == 'refresh':
		update()
	return false


func is_values_compatible(field, value):
	if typeof(field) == TYPE_BOOL:
		return true
	if typeof(field) in [ TYPE_INT, TYPE_FLOAT ]:
		return typeof(value) in [ TYPE_INT, TYPE_FLOAT, TYPE_BOOL ]
	if typeof(field) in [ TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH ]:
		if typeof(value) in [ TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH ]:
			return true
	if typeof(field) == TYPE_ARRAY:
		if typeof(value) in range(TYPE_ARRAY, TYPE_PACKED_COLOR_ARRAY + 1):
			return true
	if typeof(field) == TYPE_OBJECT:
		if typeof(value) == TYPE_OBJECT:
			if field == null or value == null:
				return true
			if ClassDB.class_exists(field.get_class()) and ClassDB.class_exists(value.get_class()):
				return ClassDB.is_parent_class(value.get_class(), field.get_class())
	return false
