return {
	STRICT_RUNTIME_TYPES = true; -- assert on parameter and property type mismatch
	SLEEP_OFFSET_SQ_LIMIT = (1/3840)^2; -- square of the offset sleep limit
	SLEEP_VELOCITY_SQ_LIMIT = 1e-2^2; -- square of the velocity sleep limit
	SLEEP_ROTATION_DIFF = math.rad(0.01); -- rad
	SLEEP_ROTATION_VELOCITY = math.rad(0.1); -- rad/s
	EPS = 1e-5; -- epsilon for stability checks around pathological frequency/damping values
}