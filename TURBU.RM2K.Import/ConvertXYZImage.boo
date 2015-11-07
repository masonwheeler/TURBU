namespace TURBU.RM2K.Import

import System
import System.Drawing
import System.Drawing.Imaging
import System.IO
import System.IO.Compression

def XYZImage(filename as string) as Bitmap:
	using inStream = File.OpenRead(filename), reader = BinaryReader(inStream):
		header = reader.ReadBytes(4)
		raise 'Invalid XYZ image.' unless System.Text.Encoding.ASCII.GetString(header) == 'XYZ1'
		width = reader.ReadUInt16()
		height = reader.ReadUInt16()
		result as System.Drawing.Bitmap = Bitmap(width, height, PixelFormat.Format8bppIndexed)
		//throw away the next 2 bytes as described here:
		//http://george.chiramattel.com/blog/2007/09/deflatestream-block-length-does-not-match.html
		reader.ReadInt16()
		using zStream = DeflateStream(inStream, CompressionMode.Decompress):
			// Need to assign the palette and set it back later, because Image.Palette is stupid like that
			// http://www.charlespetzold.com/pwcs/PaletteChange.html
			pal = result.Palette
			for i in range(256):
				r = zStream.ReadByte()
				g = zStream.ReadByte()
				b = zStream.ReadByte()
				pal.Entries[i] = Color.FromArgb(r, g, b)
			result.Palette = pal
			pixels = array(byte, height * width)
			assert zStream.Read(pixels, 0, pixels.Length) == pixels.Length
			assert inStream.Position == inStream.Length
			data = result.LockBits(Rectangle(0, 0, width, height), ImageLockMode.WriteOnly, PixelFormat.Format8bppIndexed)
			if data.Stride == data.Width:
				Marshal.Copy(pixels, 0, data.Scan0, pixels.Length)
			else:
				idx = 0
				ptr = data.Scan0.ToInt64()
				for i in range(data.Height):
					Marshal.Copy(pixels, idx, IntPtr(ptr), data.Width)
					ptr += data.Stride
					idx += data.Width
			result.UnlockBits(data)
			return result