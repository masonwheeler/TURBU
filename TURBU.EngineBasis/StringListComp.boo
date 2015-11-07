namespace StringListComp

import Pythia.Runtime
import System
import TURBU.Meta

callable TStringEqualProc(value as string, data1 as TObject, data2 as TObject)
def StringListCompare(List1 as TStringList, List2 as TStringList, matchProc as Action[of string, TObject, TObject],
		list1Proc as Action[of string, TObject], list2Proc as Action[of string, TObject], presorted as bool):
	if not presorted:
		List1.Sort()
		List2.Sort()
	i as int = 0
	j as int = 0
	while (i < List1.Count) and (j < List2.Count):
		caseOf Math.Sign(string.Compare(List1[i], List2[j])):
			case 0:
				if assigned(matchProc):
					matchProc(List1[i], List1.Objects[i], List2.Objects[j])
				++i
				++j
			case -1:
				list1Proc(List1[i], List1.Objects[i]) if assigned(list1Proc)
				++i
			case 1:
				list2Proc(List2[i], List2.Objects[i]) if assigned(list2Proc)
				++j
		if assigned(list1Proc):
			for i in range(i, List1.Count):
				list1Proc(List1[i], List1.Objects[i])
		if assigned(list2Proc):
			for j in range(j, List2.Count):
				list2Proc(List2[j], List2.Objects[j])

def StringListMerge(list1 as TStringList, list2 as TStringList, presorted as bool) as TStringList:
	using functor = TSlFunctor():
		StringListCompare(list1, list2, functor.AddEqual, functor.AddSingle, functor.AddSingle, presorted)
		return functor.OutputList

def StringListIntersection(list1 as TStringList, list2 as TStringList, presorted as bool) as TStringList:
	using functor = TSlFunctor():
		StringListCompare(list1, list2, functor.AddEqual, null, null, presorted)
		return functor.OutputList

def StringListMismatch(list1 as TStringList, list2 as TStringList, presorted as bool) as TStringList:
	using functor = TSlFunctor():
		StringListCompare(list1, list2, null, functor.AddSingle, functor.AddSingle, presorted)
		return functor.OutputList

private class TSlFunctor(TObject):

	[Getter(OutputList)]
	private FOutputList as TStringList

	public def constructor():
		FOutputList = TStringList()

	public def AddSingle(value as string, data as TObject):
		FOutputList.Add(value)

	public def AddEqual(value as string, data1 as TObject, data2 as TObject):
		FOutputList.Add(value)

