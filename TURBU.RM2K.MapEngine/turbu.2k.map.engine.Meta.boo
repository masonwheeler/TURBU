namespace TURBU.RM2K.MapEngine

import Pythia.Runtime
import TURBU.MapEngine

[Metaclass(T2kMapEngine)]
class T2kMapEngineClass(TMapEngineClass):
	override def Create() as TURBU.PluginInterface.TRpgPlugBase:
		return TURBU.RM2K.MapEngine.T2kMapEngine()
