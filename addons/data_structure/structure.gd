@tool
extends Resource
class_name Structure

## @experimental
## Data structure class. Contains static-name fields having fixed types.
## 
## 
## To create a new structure, just do it with [method Object.new]:
## [codeblock]
## var struct = Structure.new()
## [/codeblock]
## Use methods [method add_field] and [method delete_field] to add/delete fields with new structure:
## [codeblock]
## # Add field "some_field" of type int with 0 as default value
## struct.add_field("some_field", TYPE_INT, 0)
## 
## # Remove field "some_field" from structure
## struct.remove_field("some_field")
## [/codeblock]
## It's also possible to add fields at [Structure] construction:
## [codeblock]
## var struct = Structure.new({
##     "field_a": {
##         type = TYPE_STRING,
##         default = "first_field"
##     },
##     "field_b": {
##         type = TYPE_INT,
##         default = 0,
##         hint = PROPERTY_HINT_ENUM,
##         hint_string = "One,Two,Three",
##     }
## })
## [/codeblock]
## To modify an instance of configured structure, prevent changing it's signature with [method lock] method.
## You can [method unlock] it later.[br]
## [br]
## After locking, you can acces structure members via [code]struct.member[/code] syntax:
## [codeblock]
## var struct = Structure.new()
## struct.add_field("field", TYPE_INT, 4)
## 
## print( struct.field )    # prints default "field" value
## struct.field = 17        # causes error
## 
## struct.lock()
## 
## print( struct.field )    # output: 4
## 
## struct.field = 17
## print( struct.field )    # output: 17
## [/codeblock]
## Method [method instantiate] returns locked copy of structure with already locked signature - or an instance -
## without modifying original structure.[br][br]
## Methods [method compare], [method signcmp] used for compare two structures and
## [method datacmp] - for compare two instances.

## Locked state. If [code]true[/code], signature is locked for editing, unlocked otherwise. Actual data can be pulled only from locked structures.
var locked := false
## [Dictionary] of structure's properties including:[br]
## -   [param type] : [enum Variant.Type],[br]
## -   [param default] : [Variant] - default value,[br]
## -   [param usage] : [enum @GlobalScope.PropertyUsageFlags],[br]
## -   [param hint] : [enum @GlobalScope.PropertyHint],[br]
## -   [param hint_string] : [String].[br]
## Last tree params are optional.
## Keys of dictionary are names of structure's fields.[br]
## For more information see [method Object._get_property_list].
var signature := {}
## Actual data of structure. Struct must be locked before acces to its data (see [method lock])
var data := {}:
	get:
		if !locked:
			push_error('Structure must be locked before access to its data.')
			return {}
		return data
	set(value):
		if !locked:
			push_error('Structure must be locked before access to its data.')
			return
		data = value


func _init(struct = {}):
	signature = struct


## Returns duplicate of structure. If original struct is unlocled, locks created duplicate. See [member Structure.locked]
func instantiate() -> Structure:
	var struct = duplicate(true) as Structure
	if !struct.locked:
		struct.lock()
	return struct


## Locks [code]signature[/code] for editing. See [member Structure.locked].
func lock():
	locked = true
	for name in signature:
		if signature[name].type in (range(TYPE_ARRAY, TYPE_PACKED_COLOR_ARRAY + 1) + [TYPE_DICTIONARY]):
			data[name] = signature[name].default.duplicate()
		data[name] = signature[name].default
	emit_signal(&'property_list_changed')
	emit_changed()
	return self


## Unlocks [code]signature[/code]. See [member Structure.locked].
func unlock():
	data.clear()
	locked = false
	emit_signal(&'property_list_changed')
	emit_changed()
	return self


## Adds new field at the end of struct's signature. Requres unlocked state.
func add_field(name: StringName, type: Variant.Type, default: Variant, usage = null, hint = null, hint_string = null) -> Error:
	if locked:
		push_error('Structure is locked!')
		return ERR_LOCKED
	if name in signature:
		return ERR_ALREADY_EXISTS
	if name in [ &'signature' ]:
		return ERR_ALREADY_IN_USE
	var field = { type=type, default=default }
	if usage != null:
		field.usage = usage
	if hint != null:
		field.hint = hint
		if hint_string != null:
			field.hint_string = hint_string
	signature[name] = field
	emit_signal(&'property_list_changed')
	emit_changed()
	return OK


## Remove specific field from signature. Requires unlocked state (see [method unlock]).
func delete_field(name) -> Error:
	if locked:
		push_error('Structure is locked!')
		return ERR_LOCKED
	if name not in signature:
		return ERR_DOES_NOT_EXIST
	signature.erase(name)
	emit_signal(&'property_list_changed')
	emit_changed()
	return OK


func _get(prop):
	if prop == &'signature ':
		var text = ''
		for i in signature.size():
			var name = signature.keys()[i]
			text += name + ' : ' + type_string(signature[name].type)
			if i != signature.size() - 1:
				text += '\n'
		return text
	if prop == &'lock ':
		return locked
	if prop == &'save ':
		return true
	if prop in signature:
		if locked:
			return data[prop]
		else:
			push_error('Structure must be locked before access to its data.')


func _set(prop, value) -> bool:
	var result = false
	if prop == &'lock ':
		if value:
			var can_lock = true
			if signature.is_empty():
				can_lock = false
				push_error('Structure cannot be empty!')
			for i in signature:
				if typeof(i) not in [ TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH ]:
					can_lock = false
					push_error('Invalid field name. Must be String, StringName or NodePath.')
					break
				if StringName(i) in [ &'signature' ]:
					can_lock = false
					push_error('Field name hides native one.')
					break
			if can_lock:
				lock()
				result = true
			else:
				result = false
		else:
			unlock()
	if prop == &'save ':
		emit_signal(&'property_list_changed')
		emit_changed()
	if prop in signature:
		if locked:
			data[prop] = value
			result = true
		else:
			push_error('Structure must be locked before using its members.')
	return result


func _get_property_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if !locked:
		list = [
			{
				&'name': &'signature',
				&'type': TYPE_DICTIONARY,
			},
		]
	else:
		var entries: Array[Dictionary] = []
		for name in data:
			var entry := { &'name': name, &'type': signature[name].type }
			if &'usage' in signature[name]:
				entry.usage = signature[name].usage
			if &'hint' in signature[name]:
				entry.hint = signature[name].hint
				if &'hint_string' in signature[name]:
					entry.hint_string = signature[name].hint_string
			entries.push_back(entry)
		list = entries + list
		list.push_back({ &'name': &'save ', &'type': TYPE_BOOL })
		list.push_back({
				&'name': &'signature ',
				&'type': TYPE_STRING,
				&'usage': PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY,
				&'hint': PROPERTY_HINT_MULTILINE_TEXT
			})
	list.push_front({ &'name': &'lock ', &'type': TYPE_BOOL })
	return list


## Compares two structures (actual data excluded).[br]
## [codeblock]
## func _ready():
##     var struct_a = Struct.new({
##         'a': {
##             type = TYPE_INT,
##             default = 0
##         }
##     })
##     var struct_b = Struct.new({
##         'a': {
##             type = TYPE_INT,
##             default = 0
##         }
##     })
##     var struct_c = Struct.new({
##         'a': {
##             type = TYPE_INT,
##             default = 1
##         }
##     })
##     print( struct_a.compare(struct_b) ) # Returns true
##     print( struct_a.compare(struct_c) ) # Returns false
## [/codeblock]
func compare(right: Structure):
	return signature == right.signature


## Compares actual structure values with the other one's. No need to [method lock] before use.
func datacmp(right: Structure):
	return instantiate().data == right.instantiate().data


## Compares [code]signature[/code]s of two structs depending only on field names and types.
func signcmp(right: Structure):
	return get(&'signature ') == right.get(&'signature ')


func set_default(field, value):
	if locked:
		push_error(error_string(ERR_LOCKED))
		return
	if field not in signature:
		push_error(error_string(ERR_DOES_NOT_EXIST))
		return
	signature[field].default = value
	emit_signal('property_list_changed')
	emit_changed()
