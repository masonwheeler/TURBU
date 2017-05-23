namespace TURBU.RM2K.RPGScript

import System
import System.Linq.Enumerable
import System.Threading.Tasks

import Boo.Lang.Compiler.Ast
import turbu.defs
import turbu.script.engine
import commons
import turbu.classes
import Pythia.Runtime
import TURBU.RM2K
import turbu.RM2K.sprite.engine
import TURBU.RM2K.Menus
import turbu.RM2K.environment
import TURBU.RM2K.MapEngine
import TURBU.Meta
import Newtonsoft.Json
import Newtonsoft.Json.Linq

macro ShowMessage(body as ExpressionStatement*):
	message = string.Join(Environment.NewLine, body.Select({es | (es.Expression cast StringLiteralExpression).Value}))
	return ExpressionStatement([|await(ShowMessage($message))|])

[async]
def ShowMessage(msg as string) as Task:
	oldValue as TMboxLocation
	lock L.MessageLock:
		if assigned(L.ShowMessageHandler):
			L.ShowMessageHandler(msg)
		else:
			PrepareMbox(oldValue)
			await GMenuEngine.Value.ShowMessage(msg, L.MboxModal)
			SetMessageBoxPosition(oldValue)

def SetMessageBoxPosition(position as TMboxLocation):
	GMenuEngine.Value.Position = position

def SetMessageBoxVisible(value as bool):
	GMenuEngine.Value.BoxVisible = value

def SetMessageModal(value as bool):
	L.MboxModal = value

def MessageOptions(transparent as bool, position as TMboxLocation, dontHideHero as bool, modal as bool):
	SetMessageBoxVisible(transparent)
	SetMessageBoxPosition(position)
	SetMessageBoxCaution(dontHideHero)
	SetMessageModal(modal)

def ClearPortrait():
	GMenuEngine.Value.Portrait.Visible = false

def SetPortrait(filename as string, index as int, rightside as bool, flipped as bool):
	valid as bool
	return unless ArchiveUtils.GraphicExists(filename, 'Portraits')
	commons.runThreadsafe(true) def ():
		path as string = 'Portraits\\' + filename
		valid = clamp(index, 0, (GSpriteEngine.value.Images.EnsureImage(path, filename, GDatabase.value.Layout.PortraitSize).Count - 1)) == index
	return unless valid
	SetRightside(rightside)
	GMenuEngine.Value.SetPortrait(filename, index)
	SetFlipped(flipped)

[async]
def ShowChoice(msg as string, choices as (string), allowCancel as bool) as Task of int:
	oldValue as TMboxLocation
	PrepareMbox(oldValue)
	await (GMenuEngine.Value.ChoiceBox(msg, choices, allowCancel, null))
	SetMessageBoxPosition(oldValue)
	return GMenuEngine.Value.MenuInt

[async]
def InputNumber(msg as string, digits as int) as Task of int:
	oldValue as TMboxLocation
	PrepareMbox(oldValue)
	await GMenuEngine.Value.InputNumber(msg, digits)
	SetMessageBoxPosition(oldValue)
	return GMenuEngine.Value.MenuInt

[async]
def Inn(messageStyle as int, cost as int) as Task of bool:
	oldValue as TMboxLocation
	PrepareMbox(oldValue)
	await GMenuEngine.Value.Inn(messageStyle, cost)
	SetMessageBoxPosition(oldValue)
	if GMenuEngine.Value.MenuInt == 1:
		result = true
		GGameEngine.value.EnterCutscene()
		try:
			for i in range(1, (GEnvironment.value.HeroCount + 1)):
				GEnvironment.value.Heroes[i].FullHeal()
			assert GEnvironment.value.Money >= cost
			GEnvironment.value.Money -= cost
			GSpriteEngine.value.FadeOut(1500)
			FadeOutMusic(1500)
			await GScriptEngine.value.Sleep(1750, true)
			await PlaySystemMusicOnce(TBgmTypes.Inn)
			GSpriteEngine.value.FadeIn(1500)
			FadeInLastMusic(1500)
			await GScriptEngine.value.Sleep(1500, true)
		ensure:
			GGameEngine.value.LeaveCutscene()
	else: result = false
	return result

def SetSkin(Name as string, tiled as bool):
	GMenuEngine.Value.SetSkin(Name, not tiled)

[async]
def OpenMenu() as Task:
	GMenuEngine.Value.OpenMenu('Main')
	waitFor WaitForMenuClosed

[async]
def SaveMenu() as Task:
	GMenuEngine.Value.MenuInt = 0
	GMenuEngine.Value.OpenMenu('Save')
	waitFor WaitForMenuClosed

def WaitForMenuClosed() as bool:
	return GMenuEngine.Value.State == TMenuState.None

def SerializeMessageState(writer as JsonWriter):
	writeJsonObject writer:
		writeJsonProperty writer, 'Visible', GMenuEngine.Value.BoxVisible
		writeJsonProperty writer, 'Position', ord(GMenuEngine.Value.Position)
		writeJsonProperty writer, 'Cautious', L.MboxCautious
		writeJsonProperty writer, 'Modal', L.MboxModal
		writer.WritePropertyName('Portrait')
		writeJsonObject writer:
			GMenuEngine.Value.SerializePortrait(writer)

def DeserializeMessageState(obj as JObject):
	portrait as JObject
	GMenuEngine.Value.BoxVisible = obj.Value[of bool]('Visible')
	SetMessageBoxPosition(obj.Value[of int]('Position'))
	obj.Remove('Visible')
	obj.Remove('Position')
	obj.CheckRead('Cautious', L.MboxCautious)
	obj.CheckRead('Modal', L.MboxModal)
	portrait = (obj.Item['Portrait'] cast JObject)
	GMenuEngine.Value.DeserializePortrait(portrait)
	obj.Remove('Portrait')
	obj.CheckEmpty()

def SetShowMessageHandler(Event as Action of string):
	L.ShowMessageHandler = Event

private def PrepareMbox(ref oldValue as TMboxLocation):
	oldValue = GMenuEngine.Value.Position
	newValue as TMboxLocation = oldValue
	if L.MboxCautious and GSpriteEngine.value.IsHeroIn(oldValue):
		caseOf oldValue:
			case TMboxLocation.Top:
				newValue = TMboxLocation.Bottom
			case TMboxLocation.Middle:
				if GSpriteEngine.value.IsHeroIn(TMboxLocation.Top):
					newValue = TMboxLocation.Bottom
				else:
					newValue = TMboxLocation.Top
			case TMboxLocation.Bottom:
				newValue = TMboxLocation.Top
	SetMessageBoxPosition(newValue)

private def SetMessageBoxCaution(value as bool):
	L.MboxCautious = value

private def SetFlipped(value as bool):
	GMenuEngine.Value.Portrait.MirrorX = value

private def SetRightside(value as bool):
	GMenuEngine.Value.SetRightside(value)

internal static class L:
	public ShowMessageHandler as Action of string
	public MboxCautious as bool
	public MboxModal as bool
	public MessageLock = object()