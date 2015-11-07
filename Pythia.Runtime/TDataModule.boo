namespace Pythia.Runtime

import System

class TDataModule(System.ComponentModel.Component):
	def constructor():
		super()
		self.Initialize()

	abstract def Initialize():
		pass