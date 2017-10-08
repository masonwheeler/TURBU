namespace TURBU.RM2K.RPGScript

import System
import System.Threading.Tasks
import turbu.script.engine
import commons
import archiveInterface
//import rs_dws_Helpers
import Disharmony
import Pythia.Runtime
import turbu.sounds
import turbu.defs
import turbu.classes
import TURBU.RM2K
import Newtonsoft.Json
import Newtonsoft.Json.Linq

def PlaySound(name as string, volume as int, tempo as int, balance as int):
	if ArchiveUtils.SoundExists(name):
		name = (IncludeTrailingPathDelimiter(GArchives[SFX_ARCHIVE].Root) + name)
		LoadDisharmony().PlaySoundEx(name, volume, tempo, balance)

def StopMusic():
	LoadDisharmony().StopMusic()

def PlayMusic(name as string, time as int, volume as int, tempo as int, balance as int):
	if ArchiveUtils.MusicExists(name) or (name == '(OFF)'):
		LoadDisharmony().PlayMusic((IncludeTrailingPathDelimiter(GArchives[MUSIC_ARCHIVE].Root) + name))
		LoadDisharmony().FadeInMusic(time)
		LoadDisharmony().SetMusicVolume(volume)
		LoadDisharmony().SetMusicSpeed(tempo)
		LoadDisharmony().SetMusicPanpot(cast(uint, balance * 0.64))
		L.LastMusic = name
		L.LastTime = time
		L.LastVolume = volume
		L.LastTempo = tempo
		L.LastBalance = balance

def PlayMusicData(music as TRpgMusic):
	PlayMusic(music.Filename, music.FadeIn, music.Volume, music.Tempo, music.Balance)

def PlaySoundData(sound as TRpgSound):
	if assigned(sound):
		PlaySound(sound.Filename, sound.Volume, sound.Tempo, sound.Balance)

def PlaySystemSound(sound as TSfxTypes):
	PlaySoundData(L.SystemSounds[sound])

def PlaySystemMusic(music as TBgmTypes):
	PlayMusicData(L.SystemMusic[music])

[async]
def PlaySystemMusicOnce(music as TBgmTypes) as Task:
	PlaySystemMusic(music)
	waitFor WaitForMusicPlayed

def FadeOutMusic(time as int):
	LoadDisharmony().FadeOutMusic(time)
	MemorizeMusic(L.FadedBGM)

def FadeInLastMusic(time as int):
	if assigned(L.FadedBGM):
		L.FadedBGM.FadeIn = time
		PlayMusicData(L.FadedBGM)

def MemorizeBGM():
	MemorizeMusic(L.MemorizedBGM)

def PlayMemorizedBGM():
	if assigned(L.MemorizedBGM):
		PlayMusicData(L.MemorizedBGM)

def SetSystemSound(style as TSfxTypes, filename as string, volume as int, tempo as int, balance as int):
	newSound as TRpgSound
	newSound = TRpgSound()
	newSound.Filename = filename
	newSound.Volume = volume
	newSound.Tempo = tempo
	newSound.Balance = balance
	L.SystemSounds[style] = newSound

def SetSystemSoundData(style as TSfxTypes, sound as TRpgSound):
	SetSystemSound(style, sound.Filename, sound.Volume, sound.Tempo, sound.Balance)

def SetSystemMusic(style as TBgmTypes, filename as string, fadeIn as int, volume as int, tempo as int, balance as int):
	newMusic as TRpgMusic
	newMusic = TRpgMusic()
	newMusic.Filename = filename
	newMusic.Volume = volume
	newMusic.Tempo = tempo
	newMusic.Balance = balance
	newMusic.FadeIn = fadeIn
	L.SystemMusic[style] = newMusic

def SetSystemMusicData(style as TBgmTypes, music as TRpgMusic):
	SetSystemMusic(style, music.Filename, music.FadeIn, music.Volume, music.Tempo, music.Balance)

def playMovie(name as string, posX as int, posY as int, width as int, height as int):
	logs.logText("Called PlayMovie($name, $posX, $posY, $width, $height). Not supported yet.")

def SerializeSound(writer as JsonWriter):
	current as TRpgMusic
	current = null
	writeJsonObject writer:
		writer.WritePropertyName('CurrentBGM')
		MemorizeMusic(current)
		current.Serialize(writer)
		if assigned(L.FadedBGM):
			writer.WritePropertyName('FadedBGM')
			L.FadedBGM.Serialize(writer)
		if assigned(L.MemorizedBGM):
			writer.WritePropertyName('MemorizedBGM')
			L.MemorizedBGM.Serialize(writer)
		SerializeSystemSound(writer)

def DeserializeSound(obj as JObject):
	item as JToken
	current as TRpgMusic
	if obj.TryGetValue('FadedBGM', item):
		L.FadedBGM = TRpgMusic()
		L.FadedBGM.Deserialize(item cast JObject)
		obj.Remove('FadedBGM')
	if obj.TryGetValue('MemorizedBGM', item):
		L.MemorizedBGM = TRpgMusic()
		L.MemorizedBGM.Deserialize(item cast JObject)
		obj.Remove('MemorizedBGM')
	DeserializeSystemSound(obj)
	item = obj['CurrentBGM']
	assert assigned(item)
	current = TRpgMusic()
	current.Deserialize(item cast JObject)
	obj.Remove('CurrentBGM')
	PlayMusicData(current)
	obj.CheckEmpty()

private def MemorizeMusic(ref music as TRpgMusic):
	music = TRpgMusic()
	music.Filename = L.LastMusic
	music.FadeIn = L.LastTime
	music.Tempo = L.LastTempo
	music.Volume = L.LastVolume
	music.Balance = L.LastBalance

private def WaitForMusicPlayed() as bool:
	return LoadDisharmony().GetMusicLooping() > 0

private def SerializeSystemSound(writer as JsonWriter):
	currentMusic as TRpgMusic
	currentSound as TRpgSound
	writer.WritePropertyName('SystemSounds')
	writeJsonArray writer:
		for currentSound in L.SystemSounds:
			currentSound.Serialize(writer)
	writer.WritePropertyName('SystemMusic')
	writeJsonArray writer:
		for currentMusic in L.SystemMusic:
			currentMusic.Serialize(writer)

private def DeserializeSystemSound(obj as JObject):
	arr = obj['SystemSounds'] cast JArray
	for sfx in range(TSfxTypes.ItemUsed + 1):
		L.SystemSounds[sfx] = TRpgSound()
		L.SystemSounds[sfx].Deserialize(arr[ord(sfx)] cast JObject)
	obj.Remove('SystemSounds')
	arr = (obj['SystemMusic'] cast JArray)
	for bgm in range(TBgmTypes.BossBattle + 1):
		L.SystemMusic[bgm] = TRpgMusic()
		L.SystemMusic[bgm].Deserialize(arr[ord(bgm)] cast JObject)
	obj.Remove('SystemMusic')

private static class L:
	public SystemSounds = array(TRpgSound, TSfxTypes.ItemUsed + 1)
	
	public SystemMusic = array(TRpgMusic, TBgmTypes.BossBattle + 1)
	
	public FadedBGM as TRpgMusic
	public MemorizedBGM as TRpgMusic

	public LastMusic as string
	public LastTime as int
	public LastTempo as int
	public LastVolume as int
	public LastBalance as int

	def Clear():
		MemorizedBGM = null
		FadedBGM = null
		for i in range(SystemSounds.Length):
			SystemSounds[i] = null
		for i in range(SystemMusic.Length):
			SystemMusic[i] = null
