namespace PackageRegistry

import System
import Boo.Lang.Useful.Attributes

[Singleton]
class TPackageList:
	def AddPackage(FileName as string, handle as IntPtr, OrigHandle as IntPtr ):
		raise "Not Implemented"
	
	def RemovePackage(FileName as string):
		raise "Not Implemented"
	
	def Verify():
		raise "Not Implemented"