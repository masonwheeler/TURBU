namespace turbu.RM2K.items

import Pythia.Runtime

[Metaclass(TRpgItem)]
class TRpgItemClass(TClass):

	abstract def Create(Item as int, Quantity as int) as turbu.RM2K.items.TRpgItem:
		pass

[Metaclass(TRpgInventory)]
class TRpgInventoryClass(TClass):

	virtual def Create() as turbu.RM2K.items.TRpgInventory:
		return turbu.RM2K.items.TRpgInventory()

