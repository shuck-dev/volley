class_name StatModifier
extends RefCounted

enum Operation { ADD, MULTIPLY }

# Where did it come from?
var source_key: String
# What stat is being modified?
var stat_key: StringName
# How is the stat being modified?
var operation: Operation
# With what value is the stat modified?
var value: float
