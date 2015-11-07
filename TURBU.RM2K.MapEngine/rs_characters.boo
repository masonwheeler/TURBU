namespace TURBU.RM2K.RPGScript

import turbu.constants
import turbu.RM2K.environment

def AddItem(id as int, Quantity as int):
	GEnvironment.value.Party.AddItem(id, Quantity)

def RemoveItem(id as int, Quantity as int):
	GEnvironment.value.Party.RemoveItem(id, Quantity)

def heroJoin(id as int):
	if (id not in range(1, GEnvironment.value.HeroCount + 1)) or (GEnvironment.value.PartySize == MAXPARTYSIZE):
		return
	for i in range(1, MAXPARTYSIZE + 1):
		if GEnvironment.value.Party[i] == GEnvironment.value.Heroes[id]:
			return
	i = GEnvironment.value.Party.OpenSlot
	if i != 0:
		GEnvironment.value.Party[i] = GEnvironment.value.Heroes[id]

def heroLeave(id as int):
	i as int
	if (id == 0) or (id > GEnvironment.value.HeroCount):
		return
	for I in range(1, (MAXPARTYSIZE + 1)):
		if GEnvironment.value.Party[i] == GEnvironment.value.Heroes[id]:
			GEnvironment.value.Party[i] = null

def addExp(id as int, number as int, notify as bool):
	GEnvironment.value.Party.LevelNotify = notify
	GEnvironment.value.Party.AddExp(id, number)

def RemoveExp(id as int, number as int):
	GEnvironment.value.Party.RemoveExp(id, number)

def AddLevels(id as int, number as int, showMessage as bool):
	GEnvironment.value.Party.LevelNotify = showMessage
	GEnvironment.value.Party.AddLevels(id, number)

def RemoveLevels(hero as int, Count as int):
	GEnvironment.value.Party.RemoveLevels(hero, Count)
