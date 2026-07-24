class_name StatModifier
extends RefCounted

enum Operation { ADD, PERCENTAGE }

const OPERATION_BY_NAME: Dictionary = {
	&"add": Operation.ADD,
	&"percentage": Operation.PERCENTAGE,
}

var source_key: String
var stat_key: StringName
var operation: Operation
var value: float
var range_stat_key: StringName
var temporary := false
var instanced := false
