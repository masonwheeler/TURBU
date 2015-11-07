namespace LCF_Parser

partial class RMProjectConverterForm(System.Windows.Forms.Form):
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
		self.label3 = System.Windows.Forms.Label()
		self.label2 = System.Windows.Forms.Label()
		self.label1 = System.Windows.Forms.Label()
		self.panel1 = System.Windows.Forms.Panel()
		self.lblStatus = System.Windows.Forms.Label()
		self.lblStatusLabel = System.Windows.Forms.Label()
		self.panel4 = System.Windows.Forms.Panel()
		self.lblErrors = System.Windows.Forms.Label()
		self.panel3 = System.Windows.Forms.Panel()
		self.lblWarnings = System.Windows.Forms.Label()
		self.panel2 = System.Windows.Forms.Panel()
		self.lblHints = System.Windows.Forms.Label()
		self.lblSteps = System.Windows.Forms.Label()
		self.lblProgress = System.Windows.Forms.Label()
		self.prgSteps = System.Windows.Forms.ProgressBar()
		self.prgConversion = System.Windows.Forms.ProgressBar()
		self.btnDone = System.Windows.Forms.Button()
		self.panel1.SuspendLayout()
		self.panel4.SuspendLayout()
		self.panel3.SuspendLayout()
		self.panel2.SuspendLayout()
		self.SuspendLayout()
		# 
		# label3
		# 
		self.label3.Location = System.Drawing.Point(3, 6)
		self.label3.Name = "label3"
		self.label3.Size = System.Drawing.Size(54, 23)
		self.label3.TabIndex = 1
		self.label3.Text = "Errors:"
		# 
		# label2
		# 
		self.label2.Location = System.Drawing.Point(3, 6)
		self.label2.Name = "label2"
		self.label2.Size = System.Drawing.Size(46, 23)
		self.label2.TabIndex = 1
		self.label2.Text = "Notes:"
		# 
		# label1
		# 
		self.label1.Location = System.Drawing.Point(3, 6)
		self.label1.Name = "label1"
		self.label1.Size = System.Drawing.Size(46, 23)
		self.label1.TabIndex = 0
		self.label1.Text = "Hints:"
		# 
		# panel1
		# 
		self.panel1.Controls.Add(self.lblStatus)
		self.panel1.Controls.Add(self.lblStatusLabel)
		self.panel1.Controls.Add(self.panel4)
		self.panel1.Controls.Add(self.panel3)
		self.panel1.Controls.Add(self.panel2)
		self.panel1.Controls.Add(self.lblSteps)
		self.panel1.Controls.Add(self.lblProgress)
		self.panel1.Controls.Add(self.prgSteps)
		self.panel1.Controls.Add(self.prgConversion)
		self.panel1.Location = System.Drawing.Point(10, 21)
		self.panel1.Name = "panel1"
		self.panel1.Size = System.Drawing.Size(380, 284)
		self.panel1.TabIndex = 0
		# 
		# lblStatus
		# 
		self.lblStatus.Location = System.Drawing.Point(142, 18)
		self.lblStatus.Name = "lblStatus"
		self.lblStatus.Size = System.Drawing.Size(184, 23)
		self.lblStatus.TabIndex = 8
		self.lblStatus.Text = "Converting Project"
		self.lblStatus.TextAlign = System.Drawing.ContentAlignment.TopRight
		# 
		# lblStatusLabel
		# 
		self.lblStatusLabel.Location = System.Drawing.Point(52, 17)
		self.lblStatusLabel.Name = "lblStatusLabel"
		self.lblStatusLabel.Size = System.Drawing.Size(100, 23)
		self.lblStatusLabel.TabIndex = 7
		self.lblStatusLabel.Text = "Status:"
		# 
		# panel4
		# 
		self.panel4.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D
		self.panel4.Controls.Add(self.lblErrors)
		self.panel4.Controls.Add(self.label3)
		self.panel4.Location = System.Drawing.Point(267, 220)
		self.panel4.Name = "panel4"
		self.panel4.Size = System.Drawing.Size(95, 32)
		self.panel4.TabIndex = 6
		# 
		# lblErrors
		# 
		self.lblErrors.Location = System.Drawing.Point(50, 3)
		self.lblErrors.Name = "lblErrors"
		self.lblErrors.Size = System.Drawing.Size(38, 23)
		self.lblErrors.TabIndex = 3
		self.lblErrors.Text = "0"
		self.lblErrors.TextAlign = System.Drawing.ContentAlignment.MiddleRight
		# 
		# panel3
		# 
		self.panel3.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D
		self.panel3.Controls.Add(self.lblWarnings)
		self.panel3.Controls.Add(self.label2)
		self.panel3.Location = System.Drawing.Point(148, 220)
		self.panel3.Name = "panel3"
		self.panel3.Size = System.Drawing.Size(95, 32)
		self.panel3.TabIndex = 5
		# 
		# lblWarnings
		# 
		self.lblWarnings.Location = System.Drawing.Point(50, 3)
		self.lblWarnings.Name = "lblWarnings"
		self.lblWarnings.Size = System.Drawing.Size(38, 23)
		self.lblWarnings.TabIndex = 2
		self.lblWarnings.Text = "0"
		self.lblWarnings.TextAlign = System.Drawing.ContentAlignment.MiddleRight
		# 
		# panel2
		# 
		self.panel2.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D
		self.panel2.Controls.Add(self.lblHints)
		self.panel2.Controls.Add(self.label1)
		self.panel2.Location = System.Drawing.Point(21, 220)
		self.panel2.Name = "panel2"
		self.panel2.Size = System.Drawing.Size(95, 32)
		self.panel2.TabIndex = 4
		# 
		# lblHints
		# 
		self.lblHints.Location = System.Drawing.Point(50, 3)
		self.lblHints.Name = "lblHints"
		self.lblHints.Size = System.Drawing.Size(38, 23)
		self.lblHints.TabIndex = 1
		self.lblHints.Text = "0"
		self.lblHints.TextAlign = System.Drawing.ContentAlignment.MiddleRight
		# 
		# lblSteps
		# 
		self.lblSteps.Location = System.Drawing.Point(53, 105)
		self.lblSteps.Name = "lblSteps"
		self.lblSteps.Size = System.Drawing.Size(274, 23)
		self.lblSteps.TabIndex = 3
		self.lblSteps.Text = "Conversion:"
		self.lblSteps.TextAlign = System.Drawing.ContentAlignment.MiddleCenter
		# 
		# lblProgress
		# 
		self.lblProgress.Location = System.Drawing.Point(53, 41)
		self.lblProgress.Name = "lblProgress"
		self.lblProgress.Size = System.Drawing.Size(274, 23)
		self.lblProgress.TabIndex = 2
		self.lblProgress.Text = "Progress:"
		self.lblProgress.TextAlign = System.Drawing.ContentAlignment.MiddleCenter
		# 
		# prgSteps
		# 
		self.prgSteps.Location = System.Drawing.Point(52, 131)
		self.prgSteps.Name = "prgSteps"
		self.prgSteps.Size = System.Drawing.Size(274, 33)
		self.prgSteps.Step = 1
		self.prgSteps.TabIndex = 1
		# 
		# prgConversion
		# 
		self.prgConversion.Location = System.Drawing.Point(52, 66)
		self.prgConversion.Name = "prgConversion"
		self.prgConversion.Size = System.Drawing.Size(274, 33)
		self.prgConversion.Step = 1
		self.prgConversion.TabIndex = 0
		# 
		# btnDone
		# 
		self.btnDone.Location = System.Drawing.Point(152, 324)
		self.btnDone.Name = "btnDone"
		self.btnDone.Size = System.Drawing.Size(98, 33)
		self.btnDone.TabIndex = 1
		self.btnDone.Text = "&Cancel"
		self.btnDone.UseVisualStyleBackColor = true
		self.btnDone.Click += self.BtnDoneClick as System.EventHandler
		# 
		# RMProjectConverterForm
		# 
		self.AutoScaleDimensions = System.Drawing.SizeF(8, 16)
		self.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
		self.ClientSize = System.Drawing.Size(400, 364)
		self.ControlBox = false
		self.Controls.Add(self.btnDone)
		self.Controls.Add(self.panel1)
		self.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle
		self.MaximizeBox = false
		self.MinimizeBox = false
		self.Name = "RMProjectConverterForm"
		self.SizeGripStyle = System.Windows.Forms.SizeGripStyle.Hide
		self.Text = "Converting..."
		self.Shown += self.RMProjectConverterShown as System.EventHandler
		self.panel1.ResumeLayout(false)
		self.panel4.ResumeLayout(false)
		self.panel3.ResumeLayout(false)
		self.panel2.ResumeLayout(false)
		self.ResumeLayout(false)
	private label1 as System.Windows.Forms.Label
	private label2 as System.Windows.Forms.Label
	private label3 as System.Windows.Forms.Label
	private panel2 as System.Windows.Forms.Panel
	private panel3 as System.Windows.Forms.Panel
	private panel4 as System.Windows.Forms.Panel
	private panel1 as System.Windows.Forms.Panel
	private lblStatusLabel as System.Windows.Forms.Label
	private lblStatus as System.Windows.Forms.Label
	private btnDone as System.Windows.Forms.Button
	private prgConversion as System.Windows.Forms.ProgressBar
	private prgSteps as System.Windows.Forms.ProgressBar
	private lblProgress as System.Windows.Forms.Label
	private lblSteps as System.Windows.Forms.Label
	private lblHints as System.Windows.Forms.Label
	private lblWarnings as System.Windows.Forms.Label
	private lblErrors as System.Windows.Forms.Label

