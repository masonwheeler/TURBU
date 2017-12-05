namespace TURBU.Player

import System
import System.IO

// adapted from code found at https://stackoverflow.com/a/29643803/32914
def IsDotNetAssembly(peFile as string) as bool:
	var dataDictionaryRVA = array(uint, 16)
	var dataDictionarySize = array(uint, 16)

	using fs = FileStream(peFile, FileMode.Open, FileAccess.Read), reader = BinaryReader(fs):

		//PE Header starts @ 0x3C (60). Its a 4 byte header.
		fs.Position = 0x3C 
		var peHeader = reader.ReadUInt32()

		//Moving to PE Header end location...
		fs.Position = peHeader + 24
	
		/*
			Now we are at the end of the PE Header and from here, the
						PE Optional Headers starts...
				To go directly to the datadictionary, we'll increase the	  
				stream’s current position to with 96 (0x60). 96 because,
						28 for Standard fields
						68 for NT-specific fields
			From here DataDictionary starts...and its of total 128 bytes. DataDictionay has 16 directories in total,
			doing simple maths 128/16 = 8.
			So each directory is of 8 bytes.
						In this 8 bytes, 4 bytes is of RVA and 4 bytes of Size.
	
			btw, the 15th directory consist of CLR header! if its 0, its not a CLR file :)
	 */
		dataDictionaryStart = Convert.ToUInt16(Convert.ToUInt16(fs.Position) + 0x60)
		fs.Position = dataDictionaryStart
		for i in range(15):
			dataDictionaryRVA[i] = reader.ReadUInt32()
			dataDictionarySize[i] = reader.ReadUInt32()
		return dataDictionaryRVA[14] > 0
