extends Node2D

func _ready() -> void:
	GameManager.reset()
	WaveManager.reset()

	WaveManager.path_nodes = [
		$Paths/Path2D,
		$Paths/Path2D2,
		$Paths/Path2D3
	]
	WaveManager.enemy_parent = $Enemies
	WaveManager.towers_parent = $Towers

	$TowerPlacement.path_nodes = WaveManager.path_nodes
	$TowerPlacement.towers_parent = $Towers
