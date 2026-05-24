extends Node

var gold: int = 400
var starting_gold: int = 400

signal gold_changed(new_amount: int)

func reset() -> void:
	gold = starting_gold
	gold_changed.emit(gold)

func can_afford(amount: int) -> bool:
	return gold >= amount

func spend_gold(amount: int) -> bool:
	if not can_afford(amount):
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func get_refund(total_invested: int) -> int:
	return int(total_invested * 0.5)
