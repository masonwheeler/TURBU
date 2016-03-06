namespace turbu.RM2K.savegames

import turbu.classes
import TURBU.RM2K.RPGScript
import System
import System.IO
import turbu.RM2K.environment
import TURBU.RM2K.MapEngine
import Newtonsoft.Json
import Newtonsoft.Json.Linq
import System.Diagnostics

def SaveTo(filename as string, MapID as int, explicit as bool):
	timer = Stopwatch.StartNew()
	using tw = StringWriter(), writer = JsonTextWriter(tw):
		writeJsonObject writer:
			writeJsonProperty writer, 'Map', MapID
			writer.WritePropertyName('Environment')
			GEnvironment.value.Serialize(writer, explicit)
			writer.WritePropertyName('Sound')
			SerializeSound(writer)
			writer.WritePropertyName('Messages')
			SerializeMessageState(writer)
		File.WriteAllText(filename, tw.ToString(), System.Text.Encoding.UTF8)
		timer.Stop()
		Diagnostics.Debug.Write("Saved to $filename in $(timer.ElapsedMilliseconds) milliseconds")

def Load(filename as string, OnInitializeParty as Action):
	using obj = JObject.Parse(File.ReadAllText(filename)):
		value as JToken = obj['Map']
		GGameEngine.value.LoadMap(value cast int)
		obj.Remove('Map')
		OnInitializeParty()
		value = obj['Environment']
		GEnvironment.value.Deserialize(value cast JObject)
		obj.Remove('Environment') if (value cast JObject).Count == 0
		if obj.TryGetValue('Sound', value):
			DeserializeSound(value cast JObject)
			obj.Remove('Sound')
		if obj.TryGetValue('Messages', value):
			DeserializeMessageState(value cast JObject)
			obj.Remove('Messages')
		obj.CheckEmpty()
