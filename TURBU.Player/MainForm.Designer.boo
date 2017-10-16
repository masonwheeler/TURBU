namespace TURBU.Player

partial class frmTURBUPlayer(System.Windows.Forms.Form):
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
		self.imgGame = sdl.frame.TSdlFrame()
		self.SuspendLayout()
		# 
		# imgGame
		# 
		self.imgGame.Active = false
		self.imgGame.Dock = System.Windows.Forms.DockStyle.Fill
		self.imgGame.Location = System.Drawing.Point(0, 0)
		self.imgGame.LogicalSize = System.Drawing.Point(954, 687)
		self.imgGame.Name = "imgGame"
		self.imgGame.OnAvailable = null
		self.imgGame.OnPaintEvent = null
		self.imgGame.OnTimer = null
		self.imgGame.RendererType = sdl.frame.TRendererType.rtOpenGL
		self.imgGame.Size = System.Drawing.Size(954, 687)
		self.imgGame.TabIndex = 0
		# 
		# frmTURBUPlayer
		# 
		self.AutoScaleDimensions = System.Drawing.SizeF(8, 16)
		self.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
		self.ClientSize = System.Drawing.Size(954, 687)
		self.Controls.Add(self.imgGame)
		self.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog
		self.MaximizeBox = false
		self.MinimizeBox = false
		self.Name = "frmTURBUPlayer"
		self.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen
		self.Text = "TURBU Player"
		self.Load += self.FrmTURBUPlayerLoad as System.EventHandler
		self.ResumeLayout(false)
		self.FormClosing += self.FrmTURBUPlayerClosing as System.Windows.Forms.FormClosingEventHandler
		
	private imgGame as sdl.frame.TSdlFrame
	

