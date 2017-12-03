namespace turbu.RM2K.map.tiles

import System.Linq.Enumerable
import turbu.tilesets
import sdl.sprite
import turbu.constants
import turbu.maps
import TURBU.MapObjects
import turbu.defs
import turbu.script.engine
import tiles
import turbu.map.sprites
import turbu.RM2K.sprite.engine
import turbu.RM2K.environment

class TMapTile(TTile):
	
	public def constructor(AParent as SpriteEngine, tileset as string):
		super(AParent, tileset)
	
	protected FNeighbors as TDirs8

	public override def Open(exceptFor as TMapSprite) as bool:
		lEvent as TMapSprite* = self.Event
		result = super.Open(exceptFor)
		result = result and lEvent.All({ms | ms == exceptFor or ms.BaseTile is null or ms.BaseTile.Z != exceptFor.BaseTile.Z})
		return result

	public def Bump(bumper as TMapSprite):
		return if GMapObjectManager.value.InCutscene
		lEvent as TMapSprite* = self.Event
		return if bumper.Event?.Playing
		if bumper == GEnvironment.value.Party.Sprite:
			for mapObj in lEvent:
				if mapObj.HasPage and (mapObj.Event.CurrentPage.Trigger in (TStartCondition.Touch, TStartCondition.Collision)) \
						and not mapObj.SlipThrough:
					GMapObjectManager.value.RunPageScript(mapObj.Event.CurrentPage)
		elif bumper.HasPage and (bumper.Event.CurrentPage.Trigger == TStartCondition.Collision):
			for mapObj in lEvent:
				if mapObj == GEnvironment.value.Party.Sprite:
					GMapObjectManager.value.RunPageScript(bumper.Event.CurrentPage)

	public Occupied as bool:
		get: return Event.Any()

	public Event as TMapSprite*:
		get: return GSpriteEngine.value.SpritesAt(self.Location, null)

	public Countertop as bool:
		get: return TTileAttribute.Countertop in self.Attributes

class TAnimTile(TMapTile):

	public def constructor(AParent as SpriteEngine, tileset as string):
		super(AParent, tileset)

	private static FDisplacement as ushort

	private static FStepFlag as bool

	private static def constructor():
		EnsureBroadcastList()
		FBroadcastList.Add(TAnimTile.OnHeartbeat)

	private static def OnHeartbeat():
		if (FHeartbeat % ANIM_RATE2) == 0:
			FDisplacement = ((FDisplacement + 1) % ANIM_LCM)
			FStepFlag = true
		else:
			FStepFlag = false

	public override def Draw():
		if FStepFlag:
			ImageIndex = FTileID + ((FDisplacement % 4) * 3)
		super.Draw()

	public override def Place(xCoord as int, yCoord as int, layer as int, tileData as TTileRef, tileset as TTileSet) as TTileAttribute:
		result = super.Place(xCoord, yCoord, layer, tileData, tileset)
		FTileID = ImageIndex
		return result

class TMiniTile(TSprite):

	public def constructor(AParent as TBorderTile, tileset as string):
		super(AParent)
		ImageName = tileset

class TBorderTile(TMapTile):

	protected minitiles = array(TMiniTile, 4)

	protected virtual def DoPlace():
		minis = array(ushort, 4)
		base = array(ushort, 4)
		minis[0] = 26
		minis[1] = minis[0] + 1
		minis[2] = minis[0] + 6
		minis[3] = minis[2] + 1
		self.SetMinisPosition()
		for i in range(4):
			minitiles[i].ImageName = self.ImageName
		if Neighbors != TDirs8.None:
			if (TDirs8.n | TDirs8.e | TDirs8.w | TDirs8.s) in FNeighbors:
				minis = (of ushort: 12, 17, 42, 47)
			elif (TDirs8.n | TDirs8.e | TDirs8.w) in FNeighbors:
				minis[0] -= 14
				minis[1] -= 10
				minis[2] -= 14
				minis[3] -= 10
			elif (TDirs8.n | TDirs8.e | TDirs8.s) in FNeighbors:
				minis[0] -= 10
				minis[1] -= 10
				minis[2] += 14
				minis[3] += 14
			elif (TDirs8.e | TDirs8.w | TDirs8.s) in FNeighbors:
				minis[0] += 10
				minis[1] += 14
				minis[2] += 10
				minis[3] += 14
			elif (TDirs8.n | TDirs8.w | TDirs8.s) in FNeighbors:
				minis[0] -= 14
				minis[1] -= 14
				minis[2] += 10
				minis[3] += 10
			elif (TDirs8.n | TDirs8.w) in FNeighbors:
				minis[0] -= 14
				minis[1] -= 14
				minis[2] -= 14
				minis[3] -= (22 if TDirs8.se in FNeighbors else 14)
			elif (TDirs8.n | TDirs8.e) in FNeighbors:
				minis[0] -= 10
				minis[1] -= 10
				minis[2] -= (22 if TDirs8.sw in FNeighbors else 10)
				minis[3] -= 10
			elif (TDirs8.e | TDirs8.s) in FNeighbors:
				minis[1] += 14
				minis[2] += 14
				minis[3] += 14
				if TDirs8.nw in FNeighbors:
					minis[0] -= 22
				else: minis[0] += 14
			elif (TDirs8.s | TDirs8.w) in FNeighbors:
				minis[0] += 10
				minis[2] += 10
				minis[3] += 10
				if TDirs8.ne in FNeighbors:
					minis[1] -= 22
				else: minis[1] += 10
			else:
				for i in range(4):
					base[i] = minis[i]
				if TDirs8.nw in FNeighbors:
					base[0] -= 22
				if TDirs8.ne in FNeighbors:
					base[1] -= 22
				if TDirs8.sw in FNeighbors:
					base[2] -= 22
				if TDirs8.se in FNeighbors:
					base[3] -= 22
				if TDirs8.n in FNeighbors:
					base[0] = minis[0] - 12
					base[1] = minis[1] - 12
				elif TDirs8.s in FNeighbors:
					base[0] = minis[0] + 12 unless TDirs8.nw in FNeighbors
					base[1] = minis[1] + 12 unless TDirs8.ne in FNeighbors
				if TDirs8.s in FNeighbors:
					base[2] = minis[2] + 12
					base[3] = minis[3] + 12
				elif TDirs8.n in FNeighbors:
					base[2] = minis[2] - 12 unless TDirs8.sw in FNeighbors
					base[3] = minis[3] - 12 unless TDirs8.se in FNeighbors
				if TDirs8.w in FNeighbors:
					base[0] = minis[0] - 2
					base[2] = minis[2] - 2
				elif TDirs8.e in FNeighbors:
					base[0] = minis[0] + 2 unless TDirs8.nw in FNeighbors
					base[2] = minis[2] + 2 unless TDirs8.sw in FNeighbors
				if TDirs8.e in FNeighbors:
					base[1] = minis[1] + 2
					base[3] = minis[3] + 2
				elif TDirs8.w in FNeighbors:
					base[1] = minis[1] - 2 unless TDirs8.ne in FNeighbors
					base[3] = minis[3] - 2 unless TDirs8.se in FNeighbors
				for i in range(4):
					minis[i] = base[i]
		for i in range(4):
			minitiles[i].ImageIndex = minis[i]

	protected def SetMinisPosition():
		minitiles[0].X = self.X
		minitiles[0].Y = self.Y
		minitiles[0].Z = self.Z
		minitiles[1].X = self.X + (self.Width / 2)
		minitiles[1].Y = self.Y
		minitiles[1].Z = self.Z
		minitiles[2].X = self.X
		minitiles[2].Y = self.Y + (self.Height / 2)
		minitiles[2].Z = self.Z
		minitiles[3].X = self.X + (self.Width / 2)
		minitiles[3].Y = self.Y + (self.Height / 2)
		minitiles[3].Z = self.Z

	protected override def SetEngine(newEngine as SpriteEngine):
		super.SetEngine(newEngine)
		for i in range(4):
			minitiles[i].Engine = newEngine

	protected override def DoDraw():
		i as int
		lX as single
		lY as single
		overlap as TFacing
		overlap = (FEngine cast T2kSpriteEngine).Overlapping
		if overlap != TFacing.None:
			lX = self.X
			lY = self.Y
			AdjustOverlap(overlap)
			self.SetMinisPosition()
		for i in range(4):
			minitiles[i].DoDraw()
		if overlap != TFacing.None:
			self.X = lX
			self.Y = lY
			self.SetMinisPosition()

	public def constructor(AParent as SpriteEngine, tileset as string):
		super(AParent, tileset)
		for i in range(4):
			minitiles[i] = TMiniTile(self, tileset)
			minitiles[i].Width = TILE_SIZE.x / 2
			minitiles[i].Height = TILE_SIZE.y / 2

	public override def Place(xCoord as int, yCoord as int, layer as int, tileData as TTileRef, tileset as TTileSet) as TTileAttribute:
		tileRef as TTileRef
		tileRef.Group = tileData.Group
		tileRef.Tile = 0
		result = super.Place(xCoord, yCoord, layer, tileRef, tileset)
		FNeighbors = tileData.Tile cast TDirs8
		DoPlace()
		return result

	public virtual def SharesBorder(neighbor as TTile) as bool:
		return (neighbor.GetType() == self.GetType()) and (neighbor.ImageName == self.ImageName)

	public Neighbors as TDirs8:
		get: return FNeighbors

abstract class TWaterTile(TBorderTile):

	public def constructor(AParent as SpriteEngine, tileset as string):
		super(AParent, tileset)
	
	private static FDisplacement as ushort

	private static def constructor():
		EnsureBroadcastList()
		FBroadcastList.Add(TWaterTile.OnHeartbeat)

	private static def OnHeartbeat():
		if (FHeartbeat % ANIM_RATE) == 0:
			FDisplacement = (FDisplacement + 1) % ANIM_LCM

	protected FLinkedFilename = ''

	protected FMiniIndices = matrix(int, 4, 4)

	protected def DisplaceMinis():
		displacement as int = FDisplacement % 4
		for i in range(4):
			minitiles[i].ImageIndex = FMiniIndices[displacement, i]

	protected override def DoDraw():
		DisplaceMinis()
		super.DoDraw()

	public override def Place(xCoord as int, yCoord as int, layer as int, tileData as TTileRef, tileset as TTileSet) as TTileAttribute:
		FLinkedFilename = tileset.Records[tileData.Group].Group.LinkedFilename
		return super.Place(xCoord, yCoord, layer, tileData, tileset)

	public override def SharesBorder(neighbor as TTile) as bool:
		return neighbor isa TWaterTile

class TShoreTile(TWaterTile):

	public def constructor(AParent as SpriteEngine, tileset as string):
		super(AParent, tileset)
	
	protected override def DoPlace():
		minis = array(ushort, 4)
		base = array(ushort, 4)
		changed = array(bool, 4)
		
		def ChangeBase(index as int, length as int):
			base[index] += length
			changed[index] = false
		
		def OffsetBase(index as int, length as int):
			base[index] = minis[index] + length
			changed[index] = false
		
		def UnchangeAll():
			for i in range(4):
				changed[i] = false
		
		minis[0] = 0
		minis[1] = minis[0] + 1
		minis[2] = minis[0] + 6
		minis[3] = minis[2] + 1
		self.SetMinisPosition()
		for i in range(4):
			minitiles[i].ImageName = FLinkedFilename
			changed[i] = true
		if Neighbors != TDirs8.None:
			if (TDirs8.n | TDirs8.e | TDirs8.w | TDirs8.s) in FNeighbors:
				UnchangeAll()
			elif (TDirs8.n | TDirs8.e | TDirs8.w) in FNeighbors:
				minis[2] += 12
				minis[3] += 12
				UnchangeAll()
			elif (TDirs8.n | TDirs8.e | TDirs8.s) in FNeighbors:
				minis[0] += 24
				minis[2] += 24
				UnchangeAll()
			elif (TDirs8.e | TDirs8.w | TDirs8.s) in FNeighbors:
				minis[0] += 12
				minis[1] += 12
				UnchangeAll()
			elif (TDirs8.n | TDirs8.w | TDirs8.s) in FNeighbors:
				minis[1] += 24
				minis[3] += 24
				UnchangeAll()
			elif (TDirs8.n | TDirs8.w) in FNeighbors:
				minis[1] += 24
				minis[2] += 12
				for i in range(3):
					changed[i] = false
				if TDirs8.se in FNeighbors:
					minis[3] += 36
					changed[3] = false
			elif (TDirs8.n | TDirs8.e) in FNeighbors:
				minis[0] += 24
				minis[3] += 12
				changed[0] = false
				changed[1] = false
				changed[3] = false
				if TDirs8.sw in FNeighbors:
					minis[2] += 36
					changed[2] = false
			elif (TDirs8.s | TDirs8.e) in FNeighbors:
				minis[1] += 12
				minis[2] += 24
				changed[1] = false
				changed[2] = false
				changed[3] = false
				if TDirs8.nw in FNeighbors:
					minis[0] += 36
					changed[0] = false
			elif (TDirs8.s | TDirs8.w) in FNeighbors:
				minis[0] += 12
				minis[3] += 24
				changed[0] = false
				changed[2] = false
				changed[3] = false
				if TDirs8.ne in FNeighbors:
					minis[1] += 36
					changed[1] = false
			else:
				for i in range(4):
					base[i] = minis[i]
				ChangeBase(0, 36) if TDirs8.nw in FNeighbors
				ChangeBase(1, 36) if TDirs8.ne in FNeighbors
				ChangeBase(2, 36) if TDirs8.sw in FNeighbors
				ChangeBase(3, 36) if TDirs8.se in FNeighbors
				if TDirs8.n in FNeighbors:
					OffsetBase(0, 24)
					OffsetBase(1, 24)
				if TDirs8.s in FNeighbors:
					OffsetBase(2, 24)
					OffsetBase(3, 24)
				if TDirs8.w in FNeighbors:
					OffsetBase(0, 12)
					OffsetBase(2, 12)
				if TDirs8.e in FNeighbors:
					OffsetBase(1, 12)
					OffsetBase(3, 12)
				for i in range(4):
					minis[i] = base[i]
		for i in range(4):
			FMiniIndices[0, i] = minis[i]
			FMiniIndices[1, i] = minis[i] + 2
			FMiniIndices[2, i] = minis[i] + 4
			FMiniIndices[3, i] = minis[i] + 2
			DisplaceMinis()
			if not changed[i]:
				minitiles[i].ImageName = self.ImageName

class TOceanTile(TWaterTile):

	public def constructor(AParent as SpriteEngine, tileset as string):
		super(AParent, tileset)
	
	protected override def DoPlace():
		minis = array(ushort, 4)
		base = array(ushort, 4)
		changed = array(bool, 4)
		def ChangeAll():
			for i in range(4):
				changed[i] = true
		minis[0] = 0
		minis[1] = minis[0] + 1
		minis[2] = minis[0] + 6
		minis[3] = minis[2] + 1
		self.SetMinisPosition()
		for i in range(4):
			changed[i] = false
		if Neighbors != TDirs8.None:
			if (TDirs8.n | TDirs8.e | TDirs8.w | TDirs8.s) in FNeighbors:
				ChangeAll()
			elif (TDirs8.n | TDirs8.e | TDirs8.w) in FNeighbors:
				minis[2] += 12
				minis[3] += 12
				ChangeAll()
			elif (TDirs8.n | TDirs8.e | TDirs8.s) in FNeighbors:
				minis[0] += 24
				minis[2] += 24
				ChangeAll()
			elif (TDirs8.s | TDirs8.e | TDirs8.w) in FNeighbors:
				minis[0] += 12
				minis[1] += 12
				ChangeAll()
			elif (TDirs8.n | TDirs8.s | TDirs8.w) in FNeighbors:
				minis[1] += 24
				minis[3] += 24
				ChangeAll()
			elif (TDirs8.n | TDirs8.w) in FNeighbors:
				minis[1] += 24
				minis[2] += 12
				for i in range(3):
					changed[i] = true
				if TDirs8.se in FNeighbors:
					minis[3] += 36
					changed[3] = true
			elif Neighbors & (TDirs8.n | TDirs8.e) == (TDirs8.n | TDirs8.e):
				minis[0] += 24
				changed[0] = true
				changed[1] = true
				minis[3] += 12
				changed[3] = true
				if TDirs8.sw in FNeighbors:
					minis[2] += 36
					changed[2] = true
			elif Neighbors & (TDirs8.s | TDirs8.e) == (TDirs8.s | TDirs8.e):
				minis[1] += 12
				minis[2] += 24
				for i in range(1, 4):
					changed[i] = true
				if TDirs8.nw in FNeighbors:
					minis[0] += 36
					changed[1] = true
			elif Neighbors & (TDirs8.s | TDirs8.w) == (TDirs8.s | TDirs8.w):
				minis[0] += 12
				changed[0] = true
				changed[2] = true
				minis[3] += 24
				changed[3] = true
				if TDirs8.ne in FNeighbors:
					minis[1] += 36
					changed[0] = true
			else:
				for i in range(4):
					base[i] = minis[i]
				if TDirs8.nw in FNeighbors:
					base[0] += 36
					changed[1] = true
				if TDirs8.ne in FNeighbors:
					base[1] += 36
					changed[0] = true
				if TDirs8.sw in FNeighbors:
					base[2] += 36
					changed[2] = true
				if TDirs8.se in FNeighbors:
					base[3] += 36
					changed[3] = true
				if TDirs8.n in FNeighbors:
					base[0] = minis[0] + 24
					base[1] = minis[1] + 24
					changed[0] = true
					changed[1] = true
				if TDirs8.s in FNeighbors:
					base[2] = minis[2] + 24
					base[3] = minis[3] + 24
					changed[2] = true
					changed[3] = true
				if TDirs8.w in FNeighbors:
					base[0] = minis[0] + 12
					base[2] = minis[2] + 12
					changed[0] = true
					changed[2] = true
				if TDirs8.e in FNeighbors:
					base[1] = minis[1] + 12
					base[3] = minis[3] + 12
					changed[1] = true
					changed[3] = true
				for i in range(4):
					minis[i] = base[i]
		for i in range(4):
			if changed[i]:
				minitiles[i].ImageName = FLinkedFilename
			else:
				minis[i] += 36
				minitiles[i].ImageName = self.ImageName
			FMiniIndices[0, i] = minis[i]
			FMiniIndices[1, i] = minis[i] + 2
			FMiniIndices[2, i] = minis[i] + 4
			FMiniIndices[3, i] = minis[i] + 2
			DisplaceMinis()
