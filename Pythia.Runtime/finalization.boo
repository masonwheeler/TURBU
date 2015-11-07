namespace Pythia.Runtime

import Boo.Lang.Compiler.Ast

macro finalization:
	return [|
		initialization:
			System.AppDomain.CurrentDomain.DomainUnload += do (Sender as object, e as System.EventArgs):
				$(finalization.Body)
	|]
	