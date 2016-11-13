namespace TURBU.RM2K.RPGScript

import System.Linq.Enumerable
import turbu.constants
import turbu.RM2K.environment

def AddItem(id as int, Quantity as int):
	GEnvironment.value.Party.AddItem(id, Quantity)

def RemoveItem(id as int, Quantity as int):
	GEnvironment.value.Party.RemoveItem(id, Quantity)

def HeroJoin(id as int):
	if (id not in range(1, GEnvironment.value.HeroCount + 1)) or (GEnvironment.value.PartySize == MAXPARTYSIZE):
		return
	if GEnvironment.value.Party.Contains(GEnvironment.value.Heroes[id]):
		return
	i = GEnvironment.value.Party.OpenSlot
	if i != 0:
		GEnvironment.value.Party[i] = GEnvironment.value.Heroes[id]

def HeroLeave(id as int):
	if (id == 0) or (id > GEnvironment.value.HeroCount):
		return
	var i = GEnvironment.value.Party.IndexOf(GEnvironment.value.Heroes[id])
	if i != -1:
		GEnvironment.value.Party[i] = null

def AddExp(id as int, number as int, notify as bool):
	GEnvironment.value.Party.LevelNotify = notify
	GEnvironment.value.Heroes[id].Exp += number

def RemoveExp(id as int, number as int):
	GEnvironment.value.Heroes[id].Exp -= number

def AddLevels(id as int, number as int, showMessage as bool):
	GEnvironment.value.Party.LevelNotify = showMessage
	GEnvironment.value.Heroes[id].Level += number

def RemoveLevels(id as int, number as int):
	GEnvironment.value.Heroes[id].Level -= number
