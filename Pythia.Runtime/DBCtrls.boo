namespace Pythia.Runtime

import System
import System.Windows.Forms

class TDBComboBox(ComboBox):
	pass

class TDBGrid(DataGridView):
	private FRowSelect = false
	
	public RowSelect as bool:
		get: return FRowSelect
		set:
			return if FRowSelect == value
			FRowSelect = value
			if value:
				self.SelectionMode = DataGridViewSelectionMode.FullRowSelect
				self.MultiSelect = false
				self.RowPrePaint += self.DoRowPrePaint
			else:
				self.SelectionMode = DataGridViewSelectionMode.CellSelect
				self.RowPrePaint -= self.DoRowPrePaint

	private def DoRowPrePaint(sender as object , e as DataGridViewRowPrePaintEventArgs):
		e.PaintParts &= ~DataGridViewPaintParts.Focus

class TDBLookupComboBox(ComboBox):
	pass

class TDBEdit(TextBox):
	def test():
		pass //self.DataBindings.Add('Text', ds, 'property')