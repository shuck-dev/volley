class_name StatModifier
extends RefCounted

enum Operation { ADD, MULTIPLY }

var source_key: String
var stat_key: StringName
var operation: Operation
var value: float
