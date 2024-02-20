@tool
extends Resource
class_name struct




var _base: StructureBase
var _data: Dictionary = {}
var _configured: bool = false





func _get_property_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = [{
		name = &'_base',
		usage = (PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY) if _configured else PROPERTY_USAGE_DEFAULT,
	}]
	if _configured:
		for field in _data:
			var entry = {
				name = field,
				type = _base.signature[field].type,
				usage = _base.signature[field].usage,
				hint = _base.signature[field].hint,
				hint_string = _base.signature[field].hint
			}
	return list




func _property_can_revert(property: StringName) -> bool:
	if _base:
		if property in _base.signature:
			return true
	return false




func _property_get_revert(property: StringName) -> Variant:
	return _base.signature[property].default




func _get(property: StringName) -> Variant:
	if _base:
		if property in _data:
			return _data[property]
	return null




func _set(property: StringName, value: Variant) -> bool:
	if _base:
		if property in _data:
			_data[property] = value
			return true
	return false




func _init(base: StructureBase = StructureBase.new()):
	self._base = base
	_data.clear()
	for field in _base.signature:
		_data[field] = _base.get(field + &" ")




func _modify(map: Dictionary) -> void:
	if _configured:
		for field in _base.signature:
			if field in map:
				if _base.is_value_compatible(field, map[field]):
					_data[field] = map[field]
					continue
			_data[field] = _base.signature[field].default
