extends Node2D
class_name Workable

var available_work_slots = 3

func add_worker():
	available_work_slots -= 1
