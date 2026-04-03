class_name StatModifier
extends RefCounted

enum Operation { ADD, MULTIPLY }

const OPERATION_BY_NAME: Dictionary = {
	&"add": Operation.ADD,
	&"multiply": Operation.MULTIPLY,
}

var source_key: String
var stat_key: StringName
var operation: Operation
var value: float
