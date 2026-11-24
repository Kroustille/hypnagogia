extends GutTest
## DangerProfile.boss_extra_pattern (story 6.3): only Total abandon asks for the pop quiz, and the profile can come back down.


func test_the_extra_pattern_is_off_under_total_abandon_and_on_at_it() -> void:
	var danger: DangerProfile = DangerProfile.new()
	for tier: int in Lucidity.Tier.size():
		danger.apply_tier(tier, Tuning.LUCIDITY)
		assert_eq(danger.boss_extra_pattern, tier >= Tuning.LUCIDITY.boss_extra_pattern_from_tier, "tier %d" % tier)
	danger.apply_tier(Lucidity.Tier.ABANDON, Tuning.LUCIDITY)
	assert_false(danger.boss_extra_pattern, "Abandon is not Total abandon")
