namespace Disharmony

import System.Runtime.InteropServices
import Boo.Lang.Useful.Attributes

interface IDisharmony:
	def PlayMusic(FileName as string)
	def PlaySoundEx(FileName as string, Volume as uint, Speed as uint, Panpot as uint)
	def FadeInMusic(TimeFactor as uint)
	def FadeOutMusic(TimeFactor as uint)
	def GetMusicPlaying() as bool
	def GetMusicLooping() as uint
	def GetMusicPosition() as bool
	def StopMusic()
	def StopSound()
	def SetMusicPanpot(Panpot as uint)
	def SetMusicSpeed(Speed as uint)
	def SetMusicVolume(Volume as uint)
	def ReserveSound(FileName as string)
	def CancelSound(FileName as string)

def LoadDisharmony() as IDisharmony:
	return TDisharmony.Instance

[Transient, Singleton]
private class TDisharmony(IDisharmony):
	def constructor():
		HarmonyCreate()
		HarmonyInitMidi()
		HarmonyInitWave()
	
	def destructor():
		HarmonyTermWave()
		HarmonyTermMidi()
		HarmonyRelease()
		
	DisharmonyImport Create, noPublic
	DisharmonyImport InitMidi, noPublic
	DisharmonyImport InitWave, noPublic
	DisharmonyImport TermMidi, noPublic
	DisharmonyImport TermWave, noPublic
	DisharmonyImport Release, noPublic
	DisharmonyImport PlayMusic, FileName as string
	DisharmonyImport PlaySoundEx, FileName as string, Volume as uint, Speed as uint, Panpot as uint
	DisharmonyImport FadeInMusic, TimeFactor as uint
	DisharmonyImport FadeOutMusic, TimeFactor as uint
	DisharmonyImport GetMusicPlaying, bool
	DisharmonyImport GetMusicLooping, uint
	DisharmonyImport GetMusicPosition, bool
	DisharmonyImport StopMusic
	DisharmonyImport StopSound
	DisharmonyImport SetMusicPanpot, Panpot as uint
	DisharmonyImport SetMusicSpeed, Speed as uint
	DisharmonyImport SetMusicVolume, Volume as uint
	DisharmonyImport ReserveSound, FileName as string
	DisharmonyImport CancelSound, FileName as string

