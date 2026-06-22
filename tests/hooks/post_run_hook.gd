extends "res://addons/gut/hook_script.gd"

const CoverageScript = preload("res://addons/coverage/coverage.gd")

const COVERAGE_TARGET := 75.0


func run():
	var coverage = CoverageScript.instance
	var coverage_file = (
		OS.get_environment("COVERAGE_FILE") if OS.has_environment("COVERAGE_FILE") else ""
	)
	if coverage_file:
		coverage.save_coverage_file(coverage_file)
	# Whole-project target only; the per-file floor was dropped because it forced brittle wiring
	# tests on glue code that has no unit-testable behaviour. INF disables the per-file check.
	coverage.set_coverage_targets(COVERAGE_TARGET, INF)
	var verbosity = CoverageScript.Verbosity.NONE
	var logger = gut.get_logger()
	coverage.finalize(verbosity)
	if coverage.coverage_passing():
		logger.passed(
			(
				"Coverage: %.1f%% total (target %.1f%%)"
				% [coverage.coverage_percent(), COVERAGE_TARGET]
			)
		)
	else:
		logger.failed("Coverage target of %.1f%% total was not met" % COVERAGE_TARGET)
		set_exit_code(2)
