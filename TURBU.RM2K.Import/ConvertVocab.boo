namespace TURBU.RM2K.Import

import System
import Boo.Adt
import Boo.Lang.Compiler.Ast
import TURBU.RM2K.Import.LCF
import turbu.constants

static class TVocabConverter:
	
	let BASE_VOCAB = (V_ITEMS_OWNED, V_ITEMS_EQUIPPED, V_MONEY_NAME, V_NORMAL_STATUS, V_STAT_EXP,
	V_STAT_SHORT_LV, V_STAT_SHORT_HP, V_STAT_SHORT_MP, V_MP_COST, V_STAT_ATTACK,
	V_STAT_DEFENSE, V_STAT_MIND, V_STAT_SPEED, V_EQ_WEAPON, V_EQ_SHIELD, V_EQ_ARMOR,
	V_EQ_HELMET, V_EQ_ACCESSORY)
	
	let SHOP_VOCAB=('Shop{0}-Greet', 'Shop{0}-Continue', 'Shop{0}-Buy', 'Shop{0}-Sell', 'Shop{0}-Leave',
	'Shop{0}-Buy What', 'Shop{0}-Buy Quantity', 'Shop{0}-Bought', 'Shop{0}-Sell What',
	'Shop{0}-Sell Quantity', 'Shop{0}-Sold')
	
	let BATTLE_VOCAB = (V_BATTLE_FIGHT, V_BATTLE_AUTO, V_BATTLE_FLEE, V_BATTLE_ATTACK,
							  V_BATTLE_DEFEND, V_BATTLE_ITEM, V_BATTLE_SKILL)
	
	let VOCAB_LIST = {
		2: 'Battle-Surprise Attack', 4: 'Battle-Failed Escape', 5: 'Battle-Victory', 6: 'Battle-Defeat',
		0x6C: V_MENU_EQUIP, 0x6E: V_MENU_SAVE, 0x72: V_MENU_NEW, 0x73: V_MENU_LOAD,  0x75: V_MENU_QUIT,
		0x7B: V_STAT_LV, 0x7C: V_STAT_HP, 0x7D: V_STAT_MP, 0x92: V_SAVE_WHERE, 0x93: V_LOAD_WHERE,
		0x94: 'Save-File', 0x97: 'Confirm-Quit', 0x98: 'Confirm-Yes', 0x99: 'Confirm-No'
	}
	
	let VOCAB_LIST_P = {7: 'Battle-Exp Gained',   0xA: 'Battle-Found Item',
						  0x24: 'Character-Level Up', 0x25: 'Character-Learned Skill'}
	
	let VOCAB_LIST_2K = {3: 'Battle-Fled', 0xC: 'Battle-Ally Crit', 0xD: 'Battle-Enemy Crit'}
	
	let VOCAB_LIST_2K_P = {1: V_BATTLE_APPEAR, 0xB: V_BATTLE_DO_ATTACK, 0xE: 'Battle-Ally Defends',
	0xF: 'Battle-Enemy Defends', 0x10: 'Battle-Enemy Building Strength', 0x11: 'Battle-Explodes',
	0x12: 'Battle-Enemy Flees', 0x13: 'Battle-Enemy Transforms', 0x15: V_BATTLE_ENEMY_MISSED, 0x17: V_BATTLE_ALLY_MISSED,
	0x18: 'Battle-Skill Failed 1', 0x19: 'Battle-Skill Failed 2', 0x1A: 'Battle-Skill Failed 3', 0x1B: 'Battle-Dodge'}
	
	let VOCAB_LIST_2K_HP = {0x14: V_BATTLE_ENEMY_INJURED, 0x16: V_BATTLE_ALLY_INJURED}
	
	let VOCAB_LIST_2K_PS = {0x1C: 'Battle-Uses Item', 0x1D: 'Battle-Recovery', 0x1E: 'Battle-Ability Up',
	0x1F: 'Battle-Ability Down', 0x20: 'Battle-Ally Absorb', 0x21: 'Battle-Enemy Absorb', 0x22: 'Battle-Defense Up',
	0x23: 'Battle-Defense Down'}
	
	let VOCAB_LIST_2K3 = {0x26: 'Battle-Begin', 0x27: 'Battle-Miss', 0x70: 'Menu-Quit 2k3', 0x76: 'Menu-Status',
	0x77: 'Menu-Row', 0x78: 'Menu-Order', 0x79: 'ATB-Wait', 0x7A: 'ATB-Active'}
	
	public def Convert(base as RMVocabDict, is2k3 as bool) as MacroStatement:
		result = MacroStatement('Vocab')
		for i, value in enumerate((0x5C, 0x5D, 0x5F)):
			result.Body.Add([|$(BASE_VOCAB[i]) = $(base[value])|])
		for i in range(15):
			result.Body.Add([|$(BASE_VOCAB[i + 3]) = $(base[0x7E + i])|])
		for i in (1, 2):
			name = "Inn$(i)-Greet"
			msg = "$(base[0x50 + (5 * (i - 1))])?n ?$$$(base[0x51 + (5 * (i - 1))])$(Environment.NewLine)$(base[0x52 + (5 * (i - 1))])"
			result.Body.Add([|$name = $msg|])
			name = "Inn$(i)-Stay"
			result.Body.Add([|$name = $(Expression.Lift(base[0x53 + (5 * (i - 1))]))|])
			name = "Inn$(i)-Cancel"
			result.Body.Add([|$name = $(Expression.Lift(base[0x54 + (5 * (i - 1))]))|])
		for i in (1, 2, 3):
			for shop in range(SHOP_VOCAB.Length):
				name = string.Format(SHOP_VOCAB[shop], i)
				result.Body.Add([|$name = $(Expression.Lift(base[0x29 + shop + (13 * (i - 1))]))|])
		for i in range(BATTLE_VOCAB.Length):
			result.Body.Add([|$(BATTLE_VOCAB[i]) = $(Expression.Lift(base[0x65 + i]))|])
		msg = "$(base[8])?n$(base[9])"
		result.Body.Add([|$'Battle-Found Gold' = $msg|])
		for pair in VOCAB_LIST:
			result.Body.Add([|$(pair.Value as string) = $(base[pair.Key])|])
		for pair in VOCAB_LIST_P:
			msg = "?n$(base[pair.Key])"
			result.Body.Add([|$(pair.Value as string) = $msg|])
		for pair in VOCAB_LIST_2K:
			msg = (base[pair.Key] if not is2k3 else "")
			result.Body.Add([|$(pair.Value as string) = $msg|])
		for pair in VOCAB_LIST_2K_P:
			msg = ("?n$(base[pair.Key])" if not is2k3 else "")
			result.Body.Add([|$(pair.Value as string) = $msg|])
		for pair in VOCAB_LIST_2K_HP:
			msg = ("?n ?c$(base[pair.Key])" if not is2k3 else "")
			result.Body.Add([|$(pair.Value as string) = $msg|])
		for pair in VOCAB_LIST_2K_PS:
			msg = ("?n1$(base[pair.Key])?n2" if not is2k3 else "")
			result.Body.Add([|$(pair.Value as string) = $msg|])
		for pair in VOCAB_LIST_2K3:
			msg = (base[pair.Key] if is2k3 else "")
			result.Body.Add([|$(pair.Value as string) = $msg|])
		return result