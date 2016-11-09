namespace turbu.versioning

import System

//[Pythia.Attributes.DelphiPacked]
struct TVersion:

	def constructor(a as byte, b as byte, c as ushort):
		self.major = a
		self.minor = b
		self.build = c

	def constructor(value as uint):
		self.value = value

	static def op_LessThan(a as TVersion, b as TVersion) as bool:
		return a.value < b.value

	static def op_GreaterThan(a as TVersion, b as TVersion) as bool:
		return a.value > b.value

	public Name as string:
		get: return "$major.$minor.$build"

	//[Pythia.Attributes.VariantRecord(true)]
	build as ushort

	//[Pythia.Attributes.VariantRecord(true)]
	minor as byte

	//[Pythia.Attributes.VariantRecord(true)]
	major as byte

	//[Pythia.Attributes.VariantRecord(false)]
	value as uint

