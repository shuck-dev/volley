extends "res://addons/gut/hook_script.gd"

const CoverageScript = preload("res://addons/coverage/coverage.gd")

const COVERAGE_TARGET := 50.0
const FILE_TARGET := 25.0


func run():
	var coverage = CoverageScript.instance
	var coverage_file = (
		OS.get_environment("COVERAGE_FILE") if OS.has_environment("COVERAGE_FILE") else ""
	)
	if coverage_file:
		coverage.save_coverage_file(coverage_file)
	coverage.set_coverage_targets(COVERAGE_TARGET, FILE_TARGET)
	var verbosity = CoverageScript.Verbosity.FAILING_FILES
	var logger = gut.get_logger()
	coverage.finalize(verbosity)
	if coverage.coverage_passing():
		logger.passed(
			(
				"Coverage: %.1f%% total (target %.1f%%), %.1f%% file (target %.1f%%)"
				% [coverage.coverage_percent(), COVERAGE_TARGET, FILE_TARGET, FILE_TARGET]
			)
		)
	else:
		logger.failed(
			(
				"Coverage target of %.1f%% total (%.1f%% file) was not met"
				% [COVERAGE_TARGET, FILE_TARGET]
			)
		)
		set_exit_code(2)
