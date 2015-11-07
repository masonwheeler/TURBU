namespace Pythia.Runtime

import System

macro Abort:
	return [|raise EAbort()|]

public class EAbort(Exception):
	pass