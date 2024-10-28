extends Node

var job_queue : Array[Job]
var villager_queue : Array[Villager]

func queue_job(job : Job):
	job_queue.append(job)
	assign_workers()

func queue_villager(villager : Villager):
	villager_queue.append(villager)
	assign_workers()

func assign_workers():
	while job_queue.size() > 0 || villager_queue.size() > 0:
		var villager = villager_queue.pop_front()
		var job = job_queue.pop_front()
		villager.set_job(job)
