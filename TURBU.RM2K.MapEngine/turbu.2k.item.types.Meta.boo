namespace turbu.RM2K.Item.types

import Pythia.Runtime
import turbu.RM2K.items

[Metaclass(TJunkItem)]
class TJunkItemClass(TRpgItemClass):

	override def Create(Item as int, Quantity as int):
		return turbu.RM2K.Item.types.TJunkItem(Item, Quantity)

[Metaclass(TEquipment)]
class TEquipmentClass(TRpgItemClass):

	override def Create(Item as int, Quantity as int):
		return turbu.RM2K.Item.types.TEquipment(Item, Quantity)

[Metaclass(TAppliedItem)]
abstract class TAppliedItemClass(TRpgItemClass):
	pass

[Metaclass(TRecoveryItem)]
class TRecoveryItemClass(TAppliedItemClass):

	override def Create(Item as int, Quantity as int):
		return turbu.RM2K.Item.types.TRecoveryItem(Item, Quantity)

[Metaclass(TBookItem)]
class TBookItemClass(TAppliedItemClass):

	override def Create(Item as int, Quantity as int):
		return turbu.RM2K.Item.types.TBookItem(Item, Quantity)

[Metaclass(TStatItem)]
class TStatItemClass(TAppliedItemClass):

	override def Create(Item as int, Quantity as int):
		return turbu.RM2K.Item.types.TStatItem(Item, Quantity)

[Metaclass(TSkillItem)]
class TSkillItemClass(TAppliedItemClass):

	override def Create(Item as int, Quantity as int):
		return turbu.RM2K.Item.types.TSkillItem(Item, Quantity)

[Metaclass(TSwitchItem)]
class TSwitchItemClass(TRpgItemClass):

	override def Create(Item as int, Quantity as int):
		return turbu.RM2K.Item.types.TSwitchItem(Item, Quantity)

