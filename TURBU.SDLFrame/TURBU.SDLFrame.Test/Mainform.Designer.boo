namespace TURBU.SDLFrame.Test

partial class Mainform(System.Windows.Forms.Form):
	private components as System.ComponentModel.IContainer = null
	
	protected override def Dispose(disposing as bool) as void:
		if disposing:
			if components is not null:
				components.Dispose()
		super(disposing)
	
	// This method is required for Windows Forms designer support.
	// Do not change the method contents inside the source code editor. The Forms designer might
	// not be able to load this method if it was changed manually.
	private def InitializeComponent():
		// Mainform
		self.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
		self.Text = 'Mainform'
		self.Name = 'Mainform'

