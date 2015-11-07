namespace turbu.shops

import Pythia.Runtime
import turbu.defs

class TShopData(TObject):

	[Getter(ShopType)]
	private FShopType as TShopTypes

	[Getter(MessageStyle)]
	private FMessageStyle as int

	[Getter(Inventory)]
	private FInventory as (int)

	public def constructor(shopType as TShopTypes, messageStyle as int, inventory as (int)):
		FShopType = shopType
		FMessageStyle = messageStyle
		FInventory = inventory

