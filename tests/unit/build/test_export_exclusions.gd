extends GutTest

const EXPORT_PRESETS_PATH := "res://export_presets.cfg"


func test_no_shipped_scene_references_an_export_excluded_resource() -> void:
	var excluded_patterns := _read_exclude_patterns()
	assert_gt(
		excluded_patterns.size(), 0, "expected exclude_filter to be parsed from export_presets.cfg"
	)

	var violations: Array[String] = []
	for scene_path in _find_files("res://scenes", "tscn"):
		if _matches_any(scene_path.trim_prefix("res://"), excluded_patterns):
			continue
		for referenced_path in _referenced_resource_paths(scene_path):
			if _matches_any(referenced_path, excluded_patterns):
				violations.append(
					"%s references excluded resource %s" % [scene_path, referenced_path]
				)

	assert_eq(
		violations,
		[] as Array[String],
		"shipped scenes must not depend on export-excluded resources"
	)


func test_all_presets_share_the_same_exclude_filter() -> void:
	var filters := _read_all_exclude_filters()
	assert_gt(filters.size(), 1, "expected export_presets.cfg to declare multiple presets")

	for filter in filters:
		assert_eq(filter, filters[0], "every export preset must share the same exclude_filter")


func _read_exclude_patterns() -> Array[String]:
	var filters := _read_all_exclude_filters()
	if filters.is_empty():
		return []

	var patterns: Array[String] = []
	for raw_pattern in filters[0].split(","):
		var pattern := raw_pattern.strip_edges()
		if pattern != "":
			patterns.append(pattern)
	return patterns


func _read_all_exclude_filters() -> Array[String]:
	var text := FileAccess.get_file_as_string(EXPORT_PRESETS_PATH)
	var regex := RegEx.new()
	regex.compile('exclude_filter="([^"]*)"')

	var filters: Array[String] = []
	for regex_match in regex.search_all(text):
		filters.append(regex_match.get_string(1))
	return filters


func _matches_any(path: String, patterns: Array[String]) -> bool:
	for pattern in patterns:
		if pattern.ends_with("*"):
			if path.begins_with(pattern.trim_suffix("*")):
				return true
		elif path == pattern:
			return true
	return false


func _find_files(dir_path: String, extension: String) -> Array[String]:
	var results: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return results

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry in [".", ".."]:
			entry = dir.get_next()
			continue
		var full_path := dir_path.path_join(entry)
		if dir.current_is_dir():
			results.append_array(_find_files(full_path, extension))
		elif entry.get_extension() == extension:
			results.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	return results


func _referenced_resource_paths(scene_path: String) -> Array[String]:
	var text := FileAccess.get_file_as_string(scene_path)
	var regex := RegEx.new()
	regex.compile('path="res://([^"]+)"')

	var paths: Array[String] = []
	for regex_match in regex.search_all(text):
		paths.append(regex_match.get_string(1))
	return paths
