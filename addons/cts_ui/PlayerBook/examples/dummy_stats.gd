extends Node

var stats = {
	"Health": 100,
	"Mana": 50,
	"Strength": 10,
	"Dexterity": 12
}

func get_stat(stat_name: String):
	return stats.get(stat_name, 0)

func set_stat(stat_name: String, value):
	stats[stat_name] = value
