namespace engine.manager

import Jv.PluginManager
import PackageRegistry
import Boo.Lang.Useful.Attributes
import Pythia.Runtime
import System

[Singleton]
class TdmEngineManager(TDataModule):

	public pluginManager as TJvPluginManager

	public def pluginManagerAfterLoad(Sender as TObject, FileName as string, ALibHandle as IntPtr, ref AllowLoad as bool):
		TPackageList.Instance.AddPackage(FileName, ALibHandle, IntPtr.Zero)

	public def pluginManagerBeforeUnload(Sender as TObject, FileName as string, ALibHandle as IntPtr):
		TPackageList.Instance.RemovePackage(FileName)

	public def pluginManagerAfterUnload(Sender as TObject, FileName as string):
		TPackageList.Instance.Verify()
