@tool
extends Node


@export
var base: StructureBase = StructureBase.new()

@export
var instance: struct


func _enter_tree() -> void:
	base.create_field(&'field_2')
	print(base.unique_name(&'field_2'))
	#print(base.signature)
	#instance = struct.new(base)
	#print(instance.__data__)
