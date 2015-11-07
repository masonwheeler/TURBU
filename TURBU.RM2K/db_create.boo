namespace db.create

import System
import System.IO
import System.IO.Compression
import System.Reflection
import TURBU.RM2K

def ExtractDB(filename as string):
	resource as Stream
	decompressor as BinaryReader
	outfile as FileStream
	size as int
	using resource = Assembly.GetAssembly(TRpgDatabase).GetManifestResourceStream('DB_TEMPLATE'):
		using decompressor = BinaryReader(DeflateStream(resource, CompressionMode.Decompress)), outfile = FileStream(filename, FileMode.Create):
			size = decompressor.ReadInt32()
			decompressor.BaseStream.CopyTo(outfile, size)
