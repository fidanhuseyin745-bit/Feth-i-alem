extends GutTest

## Unit tests for GameState – the pure game-logic class.

var gs: GameState


func before_each() -> void:
	gs = GameState.new()


# ── Initialization ───────────────────────────────────────────────────────

func test_initial_turn_is_one() -> void:
	assert_eq(gs.turn, 1, "Game should start at turn 1")


func test_initial_gold() -> void:
	assert_eq(gs.gold, 5000, "Starting gold should be 5000")


func test_initial_selected_region_empty() -> void:
	assert_eq(gs.selected_region, "", "No region should be selected at start")


func test_regions_loaded() -> void:
	assert_eq(gs.regions.size(), 8, "There should be 8 regions")


func test_factions_loaded() -> void:
	assert_eq(gs.factions.size(), 6, "There should be 6 factions")


func test_istanbul_starts_byzantine() -> void:
	assert_eq(gs.regions["istanbul"]["owner"], "byzantine")


func test_edirne_starts_ottoman() -> void:
	assert_eq(gs.regions["edirne"]["owner"], "ottoman")


# ── Queries ──────────────────────────────────────────────────────────────

func test_ottoman_total_troops() -> void:
	# edirne 5000 + bursa 2000 + selanik 1500 = 8500
	assert_eq(gs.get_ottoman_total_troops(), 8500)


func test_ottoman_income() -> void:
	# edirne 300 + bursa 200 + selanik 180 = 680
	assert_eq(gs.get_ottoman_income(), 680)


func test_faction_total_troops_byzantine() -> void:
	# istanbul 3000
	assert_eq(gs.get_faction_total_troops("byzantine"), 3000)


func test_faction_total_troops_unknown_faction() -> void:
	assert_eq(gs.get_faction_total_troops("nonexistent"), 0)


func test_get_regions_owned_by_ottoman() -> void:
	var owned := gs.get_regions_owned_by("ottoman")
	assert_eq(owned.size(), 3)
	assert_has(owned, "edirne")
	assert_has(owned, "bursa")
	assert_has(owned, "selanik")


func test_get_regions_owned_by_unknown() -> void:
	assert_eq(gs.get_regions_owned_by("nonexistent").size(), 0)


func test_faction_display_name_known() -> void:
	assert_eq(gs.get_faction_display_name("ottoman"), "Osmanli")
	assert_eq(gs.get_faction_display_name("byzantine"), "Bizans")


func test_faction_display_name_unknown() -> void:
	assert_eq(gs.get_faction_display_name("xyz"), "xyz")


func test_region_info_text_format() -> void:
	var text := gs.get_region_info_text("istanbul")
	assert_string_contains(text, "Bizans")
	assert_string_contains(text, "3000")
	assert_string_contains(text, "500")


func test_region_info_text_nonexistent() -> void:
	assert_eq(gs.get_region_info_text("nonexistent"), "")


func test_gold_label_text() -> void:
	assert_string_contains(gs.gold_label_text(), "5000")


func test_turn_label_text() -> void:
	assert_eq(gs.turn_label_text(), "Tur: 1")


# ── Win probability ─────────────────────────────────────────────────────

func test_win_probability_positive() -> void:
	# attacker 8500, defender 3000 → 8500 / (8500 + 3000 + 1) ≈ 0.739
	var prob := gs.compute_win_probability("istanbul")
	assert_almost_eq(prob, 8500.0 / 11501.0, 0.001)


func test_win_probability_strong_defender() -> void:
	# akkoyunlu has 4000 troops
	var prob := gs.compute_win_probability("akkoyunlu")
	assert_gt(prob, 0.0)
	assert_lt(prob, 1.0)


func test_win_probability_nonexistent_region() -> void:
	assert_eq(gs.compute_win_probability("nonexistent"), 0.0)


# ── End turn ─────────────────────────────────────────────────────────────

func test_end_turn_increments_turn() -> void:
	gs.end_turn()
	assert_eq(gs.turn, 2)


func test_end_turn_adds_income() -> void:
	var income := gs.get_ottoman_income()
	gs.end_turn()
	assert_eq(gs.gold, 5000 + income)


func test_end_turn_multiple() -> void:
	gs.end_turn()
	gs.end_turn()
	gs.end_turn()
	assert_eq(gs.turn, 4)
	assert_eq(gs.gold, 5000 + 680 * 3)


func test_end_turn_emits_signal() -> void:
	watch_signals(gs)
	gs.end_turn()
	assert_signal_emitted(gs, "turn_ended")


# ── Attack ───────────────────────────────────────────────────────────────

func test_attack_success_with_zero_roll() -> void:
	# roll 0.0 is always below win prob → guaranteed win
	var result := gs.try_attack("istanbul", 0.0)
	assert_true(result, "Attack with roll=0 should always succeed")
	assert_eq(gs.regions["istanbul"]["owner"], "ottoman")


func test_attack_success_grants_gold() -> void:
	var gold_before := gs.gold
	gs.try_attack("istanbul", 0.0)
	assert_eq(gs.gold, gold_before + 200)


func test_attack_failure_with_high_roll() -> void:
	var result := gs.try_attack("istanbul", 0.999)
	assert_false(result, "Attack with roll=0.999 should fail")
	assert_eq(gs.regions["istanbul"]["owner"], "byzantine")


func test_attack_own_region_fails() -> void:
	var result := gs.try_attack("edirne", 0.0)
	assert_false(result, "Cannot attack own region")


func test_attack_empty_region_id() -> void:
	assert_false(gs.try_attack("", 0.0))


func test_attack_nonexistent_region() -> void:
	assert_false(gs.try_attack("nonexistent", 0.0))


func test_attack_istanbul_special_message() -> void:
	watch_signals(gs)
	gs.try_attack("istanbul", 0.0)
	assert_signal_emitted(gs, "region_conquered")


func test_attack_does_not_change_gold_on_failure() -> void:
	var gold_before := gs.gold
	gs.try_attack("istanbul", 0.999)
	assert_eq(gs.gold, gold_before)


# ── Diplomacy ────────────────────────────────────────────────────────────

func test_diplomacy_success() -> void:
	var result := gs.try_diplomacy("istanbul")
	assert_true(result)
	assert_eq(gs.gold, 4500)


func test_diplomacy_insufficient_gold() -> void:
	gs.gold = 100
	var result := gs.try_diplomacy("istanbul")
	assert_false(result)
	assert_eq(gs.gold, 100, "Gold should not change on failure")


func test_diplomacy_exactly_500_gold() -> void:
	gs.gold = 500
	assert_true(gs.try_diplomacy("istanbul"))
	assert_eq(gs.gold, 0)


func test_diplomacy_empty_region() -> void:
	assert_false(gs.try_diplomacy(""))


func test_diplomacy_nonexistent_region() -> void:
	assert_false(gs.try_diplomacy("nonexistent"))


# ── Build ────────────────────────────────────────────────────────────────

func test_build_success() -> void:
	var troops_before: int = gs.regions["edirne"]["troops"]
	var income_before: int = gs.regions["edirne"]["income"]
	var result := gs.try_build("edirne")
	assert_true(result)
	assert_eq(gs.gold, 4700)
	assert_eq(gs.regions["edirne"]["troops"], troops_before + 500)
	assert_eq(gs.regions["edirne"]["income"], income_before + 50)


func test_build_insufficient_gold() -> void:
	gs.gold = 100
	var result := gs.try_build("edirne")
	assert_false(result)
	assert_eq(gs.gold, 100)


func test_build_exactly_300_gold() -> void:
	gs.gold = 300
	assert_true(gs.try_build("edirne"))
	assert_eq(gs.gold, 0)


func test_build_non_ottoman_region() -> void:
	var result := gs.try_build("istanbul")
	assert_false(result, "Cannot build in non-Ottoman region")
	assert_eq(gs.gold, 5000)


func test_build_empty_region() -> void:
	assert_false(gs.try_build(""))


func test_build_nonexistent_region() -> void:
	assert_false(gs.try_build("nonexistent"))


func test_build_multiple_times() -> void:
	gs.try_build("edirne")
	gs.try_build("edirne")
	# 5000 - 300 - 300 = 4400
	assert_eq(gs.gold, 4400)
	assert_eq(gs.regions["edirne"]["troops"], 5000 + 1000)
	assert_eq(gs.regions["edirne"]["income"], 300 + 100)


# ── Income after conquest ────────────────────────────────────────────────

func test_income_increases_after_conquest() -> void:
	var income_before := gs.get_ottoman_income()
	gs.try_attack("istanbul", 0.0)
	var income_after := gs.get_ottoman_income()
	assert_gt(income_after, income_before, "Conquering Istanbul should increase income")
	assert_eq(income_after, income_before + 500)


func test_troops_increase_after_conquest() -> void:
	var troops_before := gs.get_ottoman_total_troops()
	gs.try_attack("istanbul", 0.0)
	var troops_after := gs.get_ottoman_total_troops()
	assert_gt(troops_after, troops_before)


# ── Combined scenarios ───────────────────────────────────────────────────

func test_build_then_end_turn() -> void:
	gs.try_build("edirne")  # -300 gold, +50 income
	gs.end_turn()           # +730 income (680 + 50)
	assert_eq(gs.gold, 5000 - 300 + 730)
	assert_eq(gs.turn, 2)


func test_attack_then_end_turn() -> void:
	gs.try_attack("istanbul", 0.0)  # +200 gold, istanbul now ottoman
	gs.end_turn()                    # income now includes istanbul's 500
	# gold: 5000 + 200 + (680 + 500)
	assert_eq(gs.gold, 5000 + 200 + 1180)


func test_diplomacy_then_build() -> void:
	gs.try_diplomacy("istanbul")  # -500
	gs.try_build("edirne")        # -300
	assert_eq(gs.gold, 5000 - 500 - 300)


# ── Enemy turn simulation ───────────────────────────────────────────────

func test_enemy_turn_no_attack_high_chance() -> void:
	# rng_attack_chance = 0.99 → no faction attacks (need < 0.15)
	var owners_before := {}
	for rid in gs.regions:
		owners_before[rid] = gs.regions[rid]["owner"]
	gs.simulate_enemy_turn(0.99, 0.0, 0.0)
	for rid in gs.regions:
		assert_eq(gs.regions[rid]["owner"], owners_before[rid],
			"No region should change owner when attack chance is high")


func test_enemy_turn_attack_but_miss_target() -> void:
	# rng_attack_chance = 0.0 (attack), rng_target_chance = 0.99 (miss target)
	var owners_before := {}
	for rid in gs.regions:
		owners_before[rid] = gs.regions[rid]["owner"]
	gs.simulate_enemy_turn(0.0, 0.99, 0.0)
	for rid in gs.regions:
		assert_eq(gs.regions[rid]["owner"], owners_before[rid])
