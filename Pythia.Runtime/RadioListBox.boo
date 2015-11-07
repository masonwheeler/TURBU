# Downloaded from http://www.codeproject.com/Articles/18526/RadioListBox-A-ListBox-with-Radio-Buttons-Winforms
# and converted from C# to Boo
namespace System.Windows.Forms

import System
import System.ComponentModel
import System.Drawing
import System.Windows.Forms.VisualStyles

public class RadioListBox(ListBox):

	private Align as StringFormat

	private IsTransparent = false

	private BackBrush as Brush

	
	// Allows the BackColor to be transparent
	public override BackColor as Color:
		get:
			if IsTransparent:
				return Color.Transparent
			else:
				return super.BackColor
		set:
			if value == Color.Transparent:
				IsTransparent = true
				super.BackColor = (SystemColors.Window if (self.Parent is null) else self.Parent.BackColor)
			else:
				IsTransparent = false
				super.BackColor = value
			if self.BackBrush is not null:
			
				self.BackBrush.Dispose()
			BackBrush = SolidBrush(super.BackColor)
			Invalidate()
			

	
	// Hides these properties in the designer
	[Browsable(false)]
	public override DrawMode as DrawMode:
		get:
			return super.DrawMode
		set:
			if value != DrawMode.OwnerDrawFixed:
				raise Exception('Invalid value for DrawMode property')
			else:
				super.DrawMode = value

	[Browsable(false)]
	public override SelectionMode as SelectionMode:
		get:
			return super.SelectionMode
		set:
			if value != SelectionMode.One:
				raise Exception('Invalid value for SelectionMode property')
			else:
				super.SelectionMode = value

	
	// Public constructor
	public def constructor():
		self.DrawMode = DrawMode.OwnerDrawFixed
		self.SelectionMode = SelectionMode.One
		self.ItemHeight = self.FontHeight
		self.Align = StringFormat(StringFormat.GenericDefault)
		
		// Force transparent analisys
		self.Align.LineAlignment = StringAlignment.Center
		bc = self.BackColor
		self.BackColor = bc

	
	// Main paiting method
	protected override def OnDrawItem(e as DrawItemEventArgs):
		maxItem as int = (self.Items.Count - 1)
		if (e.Index < 0) or (e.Index > maxItem):
		
			e.Graphics.FillRectangle(BackBrush, self.ClientRectangle)
			// Erase all background if control has no items
			return
		
		backRect as Rectangle = e.Bounds
		// button size depends on font height, not on item height
		// Calculate bounds for background, if last item paint up to bottom of control
		if e.Index == maxItem:
			backRect.Height = ((self.ClientRectangle.Top + self.ClientRectangle.Height) - e.Bounds.Top)
		e.Graphics.FillRectangle(BackBrush, backRect)
		textBrush as Brush
		
		// Determines text color/brush
		isChecked as bool = ((e.State & DrawItemState.Selected) == DrawItemState.Selected)
		state as RadioButtonState = (RadioButtonState.CheckedNormal if isChecked else RadioButtonState.UncheckedNormal)
		
		if (e.State & DrawItemState.Disabled) == DrawItemState.Disabled:
			textBrush = SystemBrushes.GrayText
			state = (RadioButtonState.CheckedDisabled if isChecked else RadioButtonState.UncheckedDisabled)
		elif (e.State & DrawItemState.Grayed) == DrawItemState.Grayed:
			textBrush = SystemBrushes.GrayText
			state = (RadioButtonState.CheckedDisabled if isChecked else RadioButtonState.UncheckedDisabled)
		else:
			textBrush = SystemBrushes.FromSystemColor(self.ForeColor)
		glyphSize as Size = RadioButtonRenderer.GetGlyphSize(e.Graphics, state)
		
		// Determines bounds for text and radio button
		glyphLocation as Point = e.Bounds.Location
		glyphLocation.Y += ((e.Bounds.Height - glyphSize.Height) / 2)
		bounds = Rectangle((e.Bounds.X + glyphSize.Width), e.Bounds.Y, (e.Bounds.Width - glyphSize.Width), e.Bounds.Height)
		
		RadioButtonRenderer.DrawRadioButton(e.Graphics, glyphLocation, state)
		
		// Draws the radio button
		if not string.IsNullOrEmpty(DisplayMember):
		
		// Draws the text
			e.Graphics.DrawString((self.Items[e.Index] cast System.Data.DataRowView)[self.DisplayMember].ToString(), e.Font, textBrush, bounds, self.Align)
			// Bound Datatable? Then show the column written in Displaymember
		else:
			e.Graphics.DrawString(self.Items[e.Index].ToString(), e.Font, textBrush, bounds, self.Align)
		e.DrawFocusRectangle()
		
		// If the ListBox has focus, draw a focus rectangle around the selected item.

	// Prevent background erasing
	protected override def DefWndProc(ref m as Message):
		if m.Msg == 20: // WM_ERASEBKGND
			m.Result = (1 cast IntPtr) // avoid default background erasing
			return
		super.DefWndProc(m)

	// Other event handlers
	protected override def OnHandleCreated(e as EventArgs):
		if self.FontHeight > self.ItemHeight:
			self.ItemHeight = self.FontHeight
		super.OnHandleCreated(e)
		

	protected override def OnFontChanged(e as EventArgs):
		super.OnFontChanged(e)
		if self.FontHeight > self.ItemHeight:
		
			self.ItemHeight = self.FontHeight
		Update()

	protected override def OnParentChanged(e as EventArgs):
		// Force to change backcolor
		bc = self.BackColor
		self.BackColor = bc

	protected override def OnParentBackColorChanged(e as EventArgs):
		// Force to change backcolor
		bc = self.BackColor
		self.BackColor = bc

