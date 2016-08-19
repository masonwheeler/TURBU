namespace turbu.constants

import SG.defs
import Boo.Adt

let STAT_COUNT = 6
let COMMAND_COUNT = 7
let WEAPON_SLOTS = 2
let ARMOR_SLOTS = 3
let TOTAL_SLOTS = (WEAPON_SLOTS + ARMOR_SLOTS)
let PORTRAITS_PER_SHEET = 16
let SPRITES_PER_SHEET = 8
let LAYERS = 2 cast byte
let ANIM_RATE = 44 cast byte
let ANIM_RATE2 = 12 cast byte
let MAXPARTYSIZE = 4
let MAXEXP = 1000000
let MAXGOLD = 999999
let MAXLEVEL = 50
let MAX_SAVE_SLOTS = 15
let PORTRAIT_SIZE = TSgPoint(x: 48, y: 48)
let SPRITE_SIZE = TSgPoint(x: 24, y: 16)
let LOGICAL_SIZE = TSgPoint(x: 320, y: 240)
let PHYSICAL_SIZE = TSgPoint(x: 640, y: 480)
let TILE_SIZE = TSgPoint(x: 16, y: 16)
let vt_none = -1
let vt_integer = 0
let vt_boolean = 1
let vt_real = 2
let vt_string = 3
let vt_char = 4
let vt_object = 5
let vt_rpgHero = 6
let vt_rpgCharacter = 7
let vt_rpgParty = 8
let vt_rpgVehicle = 9
let vt_rpgMapobj = 10
let VT_ADDRESSES = [6]
let TYPENAMES = ('integer', 'boolean', 'real', 'string', 'char', 'TObject', 'TRpgHero', 'TRpgCharacter', 'TRpgParty', 'TRpgVehicle', 'TRpgMapObject')
//let WM_RENDER = (WM_USER + 1)
let V_ITEMS_OWNED = 'Items Owned'
let V_ITEMS_EQUIPPED = 'Items Equipped'
let V_MONEY_NAME = 'Money'
let V_NORMAL_STATUS = 'Normal Status'
let V_STAT_EXP = 'Stat-Exp'
let V_STAT_SHORT_LV = 'StatShort-Lv'
let V_STAT_SHORT_HP = 'StatShort-HP'
let V_STAT_SHORT_MP = 'StatShort-MP'
let V_MP_COST = 'MP Cost'
let V_STAT_HP = 'Stat-HP'
let V_STAT_MP = 'Stat-MP'
let V_STAT_ATTACK = 'Stat-Attack'
let V_STAT_DEFENSE = 'Stat-Defense'
let V_STAT_MIND = 'Stat-Mind'
let V_STAT_SPEED = 'Stat-Speed'
let V_STAT_LV = 'Stat-Lv'
let V_EQ_WEAPON = 'EQ-Weapon'
let V_EQ_SHIELD = 'EQ-Shield'
let V_EQ_ARMOR = 'EQ-Armor'
let V_EQ_HELMET = 'EQ-Helmet'
let V_EQ_ACCESSORY = 'EQ-Accessory'
let V_SAVE_WHERE = 'Save-Save Where'
let V_LOAD_WHERE = 'Save-Load Where'
let V_MENU_EQUIP = 'Menu-Equip'
let V_MENU_SAVE = 'Menu-Save'
let V_MENU_LOAD = 'Menu-Load Game'
let V_MENU_QUIT = 'Menu-Quit Game'
let V_MENU_NEW = 'Menu-New Game'
let V_SHOP_NUM_GREET = 'Shop{0}-Greet'
let V_SHOP_NUM_CONTINUE = 'Shop{0}-Continue'
let V_SHOP_NUM_BUY = 'Shop{0}-Buy'
let V_SHOP_NUM_SELL = 'Shop{0}-Sell'
let V_SHOP_NUM_LEAVE = 'Shop{0}-Leave'
let V_SHOP_NUM_BUY_WHAT = 'Shop{0}-Buy What'
let V_SHOP_NUM_HOW_MANY = 'Shop{0}-Buy Quantity'
let V_SHOP_NUM_BOUGHT = 'Shop{0}-Bought'
let V_SHOP_NUM_SELL_WHAT = 'Shop{0}-Sell What'
let V_SHOP_NUM_SELL_QUANT = 'Shop{0}-Sell Quantity'
let V_SHOP_NUM_SOLD = 'Shop{0}-Sold'
let V_BATTLE_FIGHT = 'Battle-Fight'
let V_BATTLE_AUTO = 'Battle-Auto'
let V_BATTLE_FLEE = 'Battle-Flee'
let V_BATTLE_ATTACK = 'Battle-Attack'
let V_BATTLE_DEFEND = 'Battle-Defend'
let V_BATTLE_ITEM = 'Battle-Item'
let V_BATTLE_SKILL = 'Battle-Skill'
let V_BATTLE_APPEAR = 'Battle-Enemy Appears'
let V_BATTLE_DO_ATTACK = 'Battle-Ally Attacks'
let V_BATTLE_ENEMY_INJURED = 'Battle-Enemy Injured'
let V_BATTLE_ALLY_INJURED = 'Battle-Ally Injured'
let V_BATTLE_ENEMY_MISSED = 'Battle-Enemy Missed'
let V_BATTLE_ALLY_MISSED = 'Battle-Ally Missed'

/*
initialization :
	for i in range(TYPENAMES.Length):
		assert registerType(TYPENAMES[i]) == i
*/