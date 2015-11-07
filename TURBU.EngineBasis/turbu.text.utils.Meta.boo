namespace TURBU.TextUtils

import Pythia.Runtime

[Metaclass(TRpgFont)]
class TRpgFontClass(TClass):

	virtual def Create(name as string, size as uint) as TURBU.TextUtils.TRpgFont:
		return TURBU.TextUtils.TRpgFont(name, size)
