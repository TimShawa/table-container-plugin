@tool
extends Resource
class_name StructureBase


var signature: Dictionary = {}
	#&"field_a": {
		#type = TYPE_INT, default = 0
	#}
#}
var default_values: Dictionary = {}


#INFO: Syntax ```if 1:``` or ```if "-CODE-BLOCK-":```: just implementation of blocks, basically for code folding.


func _get_property_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = [{
		name = "Default Values",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_GROUP
	}]
	if signature.is_empty():
		list.append({
			name = "Empty",
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_EDITOR
		})
	else:
		for field in default_values:
			var entry = {
				name = field + " ",
				type = signature[field].type
			}
			if &"usage" in signature[field]:
				entry.usage = signature[field].usage
			if &"hint" in signature[field]:
				entry.hint = signature[field].hint
				if &"hint_string" in signature[field]:
					entry.hint_string = signature[field].hint_string
			list.push_back(entry)
		list.push_back({name="",type=TYPE_NIL,usage=PROPERTY_USAGE_GROUP})
		list.push_back({
			name = &"instantiate",
			type = TYPE_BOOL
		})
	return list




func _get(prop: StringName):
	if prop.ends_with(" "):
		prop = prop.trim_suffix(" ")
		if prop in default_values:
			return default_values[prop]
	if prop == &"instantiate":
		return true




func _set(prop: StringName, value: Variant) -> bool:
	if prop.ends_with(" "):
		prop = prop.trim_suffix(" ")
		if prop in default_values:
			default_values[prop] = value
			return true
	if prop == &"instantiate": pass
	return false




func _init(map: Dictionary = {}) -> void:
	if "-BUILD-STRUCTURE-":
		if map.is_empty():
			push_warning("Structure base is empty. Add some fields with StructureBase.create_field() or it might cause errors.")
		else:
			signature.clear()
			for field in map:
				
				if "-HANDLE-EXCEPTIONS-":
					if !is_valid_field_name(field):
						push_warning("StructureBase: Trying to create field with invalid name ({f}). Ignored.".format([field]))
						continue
					if field in signature:
						push_warning("StructureBase: Field [{f}] is already inside. Ignored.".format([field]))
						continue
					if &"type" not in map[field]:
						push_warning("StructureBase: Field [{f}] has unset type. Ignored.".format([field]))
						continue
				
				signature[field].type = map[field].type
				if map[field].has(&"default"):
					signature[field].usage = map[field].usage
				if map[field].has(&"usage"):
					signature[field].usage = map[field].usage
				if map[field].has(&"hint_string"):
					signature[field].usage = map[field].hint
				if map[field].has(&"hint_string"):
					signature[field].usage = map[field].hint_string
	
	connect(&"changed", refresh_defaults)
	connect(&"changed", func(s=self): s.emit_signal(&"property_list_changed"))
	emit_changed()




func create_field( name: StringName = &"new_variable", type := TYPE_INT, default = 0, usage := PROPERTY_USAGE_DEFAULT, hint := PROPERTY_HINT_NONE, hint_string := "" ) -> StringName:
	if "-HANDLE-EXCEPTIONS-":
		if name.is_empty():
			push_warning("StructureBase: Trying to create field with empty name. Skipped.")
			return &""
		if type < 0 or type >= TYPE_MAX:
			push_warning("StructureBase: Trying to create field with invalid Variant type. Skipped.")
			return &""
		if type in [ TYPE_CALLABLE, TYPE_SIGNAL, TYPE_RID ]:
			type = TYPE_NIL
		if default != null and typeof(default) != type:
			push_warning("StructureBase: Trying to create field with invalid default value, so that value has been rejected.")
			default = type_default_value(type)
	name = unique_name(name)
	signature[name] = { type=type, usage=usage, hint=hint, hint_string=hint_string }
	if is_value_compatible(name, default):
		default_values[name] = default
	else:
		default_values[name] = type_default_value(type)
	emit_changed()
	return name




func unique_name(name: StringName) -> StringName:
	if name in signature:
		var num = [] as PackedStringArray
		name = name.reverse()
		for i in name.length():
			if name.unicode_at(i) in range("0".unicode_at(0), "9".unicode_at(0)):
				num.push_back(name.substr(i, 1))
		num = "".join(num).reverse()
		name = name.reverse()
		if num.is_valid_int():
			name = name.left(-num.length()) + String.num_int64(int(num) + 1)
		else:
			name = unique_name(name.trim_suffix("_") + "_2")
	return name




func erase_field(name: StringName) -> bool:
	if name in signature:
		signature.erase(name)
		emit_changed()
		return true
	return false




func move_field(idx: int, rel: int) -> void:
	signature = dict_move_to(signature, idx, idx + rel)
	emit_changed()




static func dict_move_to(dict: Dictionary, from: int, to: int) -> Dictionary:
	var temp = dict.duplicate(1)
	
	if temp.is_empty(): return temp
	to = clampi(to, 0, temp.size())
	if from == to: return temp
	if from < 0 or from > temp.size(): return temp
	
	var keys = temp.keys().duplicate(1)
	var key = keys[from]
	keys.remove_at(from)
	keys.insert(to, key)
	
	var values = temp.values().duplicate(1)
	var value = values[from]
	values.remove_at(from)
	values.insert(to, value)
	
	temp.clear()
	for i in keys.size():
		temp[keys[i]] = values[i]
	return temp




func refresh_defaults() -> void:
	var temp = default_values.duplicate(1)
	default_values.clear()
	for field in signature:
		if field in temp:
			if is_value_compatible(field, temp[field]):
				default_values[field] = temp[field]
				continue
		default_values[field] = type_default_value(signature[field].type)
	emit_signal(&"property_list_changed")




static func is_valid_field_name(name: StringName) -> bool:
	if name.is_empty():
		return false
	if name == &"field_name":
		return false
	if name.unicode_at(0) in range("0".unicode_at(0), "9".unicode_at(0) + 1) \
		or name.begins_with("_"):
			return false
	for i in name.length():
		if name.unicode_at(i) not in (
			range("A".unicode_at(0), "Z".unicode_at(0) + 1) + \
			range("a".unicode_at(0), "z".unicode_at(0) + 1) + \
			[ "_".unicode_at(0) ]):
				return false
	return true




func rename_field(old: StringName, new: StringName) -> void:
	if old in signature.keys():
		var temp = {}
		for i in signature.size():
			if signature.keys()[i] == old:
				temp[new] = signature[old]
			else:
				temp[ signature.keys()[i] ] = signature.values()[i]
		signature = temp
		
		temp = {}
		for i in signature.size():
			temp[ signature.keys()[i] ] = default_values.values()[i]
		default_values = temp
		
		emit_changed()




static func type_default_value(type: Variant.Type):
	var value
	match type:
		TYPE_NIL: value = null
		TYPE_BOOL: value = false
		TYPE_INT: value = 0
		TYPE_FLOAT: value = 0.0
		TYPE_STRING: value = ""
		TYPE_VECTOR2: value = Vector2()
		TYPE_VECTOR2I: value = Vector2i()
		TYPE_RECT2: value = Rect2()
		TYPE_RECT2I: value = Rect2i()
		TYPE_VECTOR3: value = Vector3()
		TYPE_VECTOR3I: value = Vector3i()
		TYPE_TRANSFORM2D: value = Transform2D()
		TYPE_VECTOR4: value = Vector4()
		TYPE_VECTOR4I: value = Vector4i()
		TYPE_PLANE: value = Plane()
		TYPE_QUATERNION: value = Quaternion()
		TYPE_AABB: value = AABB()
		TYPE_BASIS: value = Basis()
		TYPE_TRANSFORM3D: value = Transform3D()
		TYPE_PROJECTION: value = Projection()
		TYPE_COLOR: value = Color.WHITE
		TYPE_STRING_NAME: value = &""
		TYPE_NODE_PATH: value = ^""
		TYPE_OBJECT: value = null
		TYPE_DICTIONARY: value = {}
		_:
			if type in range(TYPE_ARRAY, TYPE_PACKED_COLOR_ARRAY):
				value = []
			else:
				value = null
	return value




func is_value_compatible(field: StringName, value):
	var type = signature[field].type
	var hint = PROPERTY_HINT_NONE
	var hint_string = ""
	if &"hint" in signature[field]:
		hint = signature[field].hint
		if &"hint_string" in signature[field]:
			hint_string = signature[field].hint_string
	
	if type == typeof(value): return true
	
	if type in [ TYPE_BOOL, TYPE_INT, TYPE_FLOAT ]:
		if typeof(value) in [ TYPE_BOOL, TYPE_INT, TYPE_FLOAT ]:
			return true
	
	if type in [ TYPE_VECTOR2, TYPE_VECTOR2I ]:
		if typeof(value) in [ TYPE_VECTOR2, TYPE_VECTOR2I ]:
			return true
	
	if type in [ TYPE_RECT2, TYPE_RECT2I ]:
		if typeof(value) in [ TYPE_VECTOR2, TYPE_VECTOR2I ]:
			return true
	
	if type in [ TYPE_VECTOR3, TYPE_VECTOR3I ]:
		if typeof(value) in [ TYPE_VECTOR2, TYPE_VECTOR2I ]:
			return true
	
	if type in [ TYPE_VECTOR4, TYPE_VECTOR4I ]:
		if typeof(value) in [ TYPE_VECTOR2, TYPE_VECTOR2I ]:
			return true
	
	if type in [ TYPE_VECTOR2, TYPE_VECTOR2I ]:
		if typeof(value) in [ TYPE_VECTOR2, TYPE_VECTOR2I ]:
			return true
	
	
	if type in [ TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH ]:
		if typeof(value) in [ TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH ]:
			return true
	
	return false




func change_field_type(field: StringName, type):
	if field in signature:
		signature[field].type = type
		emit_changed()
