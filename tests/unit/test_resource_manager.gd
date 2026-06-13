extends GutTest

## Unit tests for ResourceManager - the resource economy singleton.

var rm: ResourceManager


func before_each() -> void:
	rm = ResourceManager.new()
	## Reset to ensure clean state
	rm.reset()


func after_each() -> void:
	rm.free()


# ── Initialization ───────────────────────────────────────────────────────

func test_initial_gold() -> void:
	assert_eq(rm.get_resource(ResourceTypes.Type.GOLD), 5000)


func test_initial_food() -> void:
	assert_eq(rm.get_resource(ResourceTypes.Type.FOOD), 1000)


func test_initial_materials() -> void:
	assert_eq(rm.get_resource(ResourceTypes.Type.MATERIALS), 500)


func test_initial_wood() -> void:
	assert_eq(rm.get_resource(ResourceTypes.Type.WOOD), 300)


func test_initial_iron() -> void:
	assert_eq(rm.get_resource(ResourceTypes.Type.IRON), 100)


func test_initial_horses() -> void:
	assert_eq(rm.get_resource(ResourceTypes.Type.HORSES), 50)


func test_all_resources_dictionary() -> void:
	var all := rm.get_all_resources()
	assert_eq(all.size(), 6)
	assert_true(all.has(ResourceTypes.Type.GOLD))
	assert_true(all.has(ResourceTypes.Type.FOOD))


# ── Basic Operations ─────────────────────────────────────────────────────

func test_add_resource() -> void:
	var result := rm.add_resource(ResourceTypes.Type.GOLD, 1000)
	assert_true(result)
	assert_eq(rm.get_resource(ResourceTypes.Type.GOLD), 6000)


func test_add_resource_negative_amount() -> void:
	var result := rm.add_resource(ResourceTypes.Type.GOLD, -100)
	assert_false(result)
	assert_eq(rm.get_resource(ResourceTypes.Type.GOLD), 5000)


func test_add_resource_respects_max() -> void:
	rm.set_max_resource(ResourceTypes.Type.GOLD, 6000)
	rm.add_resource(ResourceTypes.Type.GOLD, 5000)
	assert_eq(rm.get_resource(ResourceTypes.Type.GOLD), 6000)


func test_spend_resource_success() -> void:
	var result := rm.spend_resource(ResourceTypes.Type.GOLD, 1000)
	assert_true(result)
	assert_eq(rm.get_resource(ResourceTypes.Type.GOLD), 4000)


func test_spend_resource_insufficient() -> void:
	watch_signals(rm)
	var result := rm.spend_resource(ResourceTypes.Type.GOLD, 10000)
	assert_false(result)
	assert_eq(rm.get_resource(ResourceTypes.Type.GOLD), 5000)
	assert_signal_emitted(rm, "insufficient_resources")


func test_spend_resource_exact_amount() -> void:
	var result := rm.spend_resource(ResourceTypes.Type.GOLD, 5000)
	assert_true(result)
	assert_eq(rm.get_resource(ResourceTypes.Type.GOLD), 0)


func test_spend_resource_negative_amount() -> void:
	var result := rm.spend_resource(ResourceTypes.Type.GOLD, -100)
	assert_true(result)
	assert_eq(rm.get_resource(ResourceTypes.Type.GOLD), 5000)


# ── Multiple Resource Spending ───────────────────────────────────────────

func test_spend_resources_all_available() -> void:
	var costs := {
		ResourceTypes.Type.GOLD: 1000,
		ResourceTypes.Type.FOOD: 500,
	}
	var result := rm.spend_resources(costs)
	assert_true(result)
	assert_eq(rm.get_resource(ResourceTypes.Type.GOLD), 4000)
	assert_eq(rm.get_resource(ResourceTypes.Type.FOOD), 500)


func test_spend_resources_insufficient() -> void:
	var costs := {
		ResourceTypes.Type.GOLD: 1000,
		ResourceTypes.Type.FOOD: 5000,  ## Not enough food
	}
	var result := rm.spend_resources(costs)
	assert_false(result)
	## No resources should be spent
	assert_eq(rm.get_resource(ResourceTypes.Type.GOLD), 5000)
	assert_eq(rm.get_resource(ResourceTypes.Type.FOOD), 1000)


# ── Production Rates ─────────────────────────────────────────────────────

func test_process_turn_production() -> void:
	var produced := rm.process_turn_production()
	assert_true(produced.size() > 0)
	assert_true(produced.has(ResourceTypes.Type.GOLD))
	assert_eq(rm.get_resource(ResourceTypes.Type.GOLD), 5100)


func test_process_turn_production_respects_max() -> void:
	rm.set_max_resource(ResourceTypes.Type.GOLD, 5100)
	var produced := rm.process_turn_production()
	assert_eq(rm.get_resource(ResourceTypes.Type.GOLD), 5100)
	assert_false(produced.has(ResourceTypes.Type.GOLD) and produced[ResourceTypes.Type.GOLD] > 0)


func test_set_production_rate() -> void:
	rm.set_production_rate(ResourceTypes.Type.GOLD, 500)
	rm.process_turn_production()
	assert_eq(rm.get_resource(ResourceTypes.Type.GOLD), 5500)


func test_get_production_rate() -> void:
	assert_eq(rm.get_production_rate(ResourceTypes.Type.GOLD), 100)
	assert_eq(rm.get_production_rate(ResourceTypes.Type.FOOD), 50)


# ── Query Methods ────────────────────────────────────────────────────────

func test_has_resource_true() -> void:
	assert_true(rm.has_resource(ResourceTypes.Type.GOLD, 5000))


func test_has_resource_false() -> void:
	assert_false(rm.has_resource(ResourceTypes.Type.GOLD, 5001))


func test_has_resources_all_true() -> void:
	var costs := {
		ResourceTypes.Type.GOLD: 1000,
		ResourceTypes.Type.FOOD: 500,
	}
	assert_true(rm.has_resources(costs))


func test_has_resources_one_false() -> void:
	var costs := {
		ResourceTypes.Type.GOLD: 1000,
		ResourceTypes.Type.FOOD: 2000,  ## Not enough
	}
	assert_false(rm.has_resources(costs))


func test_get_max_resource() -> void:
	assert_eq(rm.get_max_resource(ResourceTypes.Type.GOLD), 999999)


func test_set_max_resource() -> void:
	rm.set_max_resource(ResourceTypes.Type.GOLD, 10000)
	assert_eq(rm.get_max_resource(ResourceTypes.Type.GOLD), 10000)


func test_get_resource_percentage() -> void:
	## 5000 / 999999 ≈ 0.005
	var pct := rm.get_resource_percentage(ResourceTypes.Type.GOLD)
	assert_gt(pct, 0.0)
	assert_lt(pct, 0.01)


# ── Signal Emission ──────────────────────────────────────────────────────

func test_add_resource_emits_signal() -> void:
	watch_signals(rm)
	rm.add_resource(ResourceTypes.Type.GOLD, 100)
	assert_signal_emitted(rm, "resource_gained")
	assert_signal_emitted_with_parameters(rm, "resources_changed", [ResourceTypes.Type.GOLD, 5100])


func test_spend_resource_emits_changed_signal() -> void:
	watch_signals(rm)
	rm.spend_resource(ResourceTypes.Type.GOLD, 100)
	assert_signal_emitted(rm, "resources_changed")


# ── Reset ────────────────────────────────────────────────────────────────

func test_reset_restores_initial_values() -> void:
	## Modify resources
	rm.add_resource(ResourceTypes.Type.GOLD, 10000)
	rm.spend_resource(ResourceTypes.Type.FOOD, 500)
	
	## Reset
	rm.reset()
	
	## Check values
	assert_eq(rm.get_resource(ResourceTypes.Type.GOLD), 5000)
	assert_eq(rm.get_resource(ResourceTypes.Type.FOOD), 1000)


# ── Edge Cases ───────────────────────────────────────────────────────────

func test_set_resource_directly() -> void:
	rm.set_resource(ResourceTypes.Type.GOLD, 100)
	assert_eq(rm.get_resource(ResourceTypes.Type.GOLD), 100)


func test_set_resource_clamped_to_zero() -> void:
	rm.set_resource(ResourceTypes.Type.GOLD, -100)
	assert_eq(rm.get_resource(ResourceTypes.Type.GOLD), 0)


func test_set_resource_clamped_to_max() -> void:
	rm.set_max_resource(ResourceTypes.Type.GOLD, 500)
	rm.set_resource(ResourceTypes.Type.GOLD, 1000)
	assert_eq(rm.get_resource(ResourceTypes.Type.GOLD), 500)


func test_get_all_resources_text() -> void:
	var text := rm.get_all_resources_text()
	assert_string_contains(text, "5000")
	assert_string_contains(text, "1000")


func test_get_resource_text() -> void:
	var text := rm.get_resource_text(ResourceTypes.Type.GOLD)
	assert_string_contains(text, "🪙")
	assert_string_contains(text, "5000")