namespace TURBU.RM2K.Import.LCF

import System
import Boo.Adt
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

interface ILCFObject:
	def Save(output as System.IO.Stream)

macro LCFObject(name as ReferenceExpression, body as Statement*):
	
	private def Flatten(input as Statement*) as ExpressionStatement*:
		for value in input:
			if value isa ExpressionStatement:
				yield value
			else:
				for sub as ExpressionStatement in (value cast Block).Statements:
					yield sub
	
	let mapping = {'bool': [|LCFBool|], 'int': [|LCFInt|], 'string': [|LCFString|], 'byteArray': [|LCFByteArray|],
		'wordArray': [|LCFUshortArray|], 'intArray': [|LCFIntArray|], 'boolArray': [|LCFBoolArray|], 'skip': null}
	
	macro skipSec(value as Expression):
		match value:
			case IntegerLiteralExpression():
				yield ExpressionStatement([|$value = blank as skip|])
			case [|range($l, $h)|]:
				i = (l cast IntegerLiteralExpression).Value
				while i <= (h cast IntegerLiteralExpression).Value:
					yield ExpressionStatement([|$i = blank as skip|])
					++i
	
	macro header(value as StringLiteralExpression):
		LCFObject['header'] = value
	
	macro hasID:
		LCFObject['hasID'] = hasID
	
	macro noZeroEnd:
		LCFObject['noZeroEnd'] = noZeroEnd
	
	cls = [|
		class $name(ILCFObject):
			pass
	|]
	ctr = [|
		public def constructor(input as System.IO.Stream):
			current = BERInt(input)
	|]
	
	save = [|
		public def Save(output as System.IO.Stream):
			pass
	|]
	
	if LCFObject.ContainsAnnotation('header'):
		hdr = LCFObject['header'] cast StringLiteralExpression
		errstr = "File header '$(hdr.Value)' not found"
		readHeader = [|assert ReadLCFString(input) == $hdr, $errstr|]
		ctr.Body.Insert(0, readHeader)
		readHeader.LexicalInfo = hdr.ParentNode.LexicalInfo
		writeHeader = [|WriteValue(output, $hdr)|].withLexicalInfoFrom(readHeader)
		save.Body.Add(writeHeader)
	if LCFObject.ContainsAnnotation('hasID'):
		idLine = [|_ID = BERInt(input)|].withLexicalInfoFrom(LCFObject['hasID'] cast Node)
		ctr.Body.Insert(0, idLine)
		exprField = Field(SimpleTypeReference('int'), null,
			Name: '_ID', Modifiers: TypeMemberModifiers.Private | TypeMemberModifiers.Final)
		attr = Boo.Lang.Compiler.Ast.Attribute('Getter')
		attr.Arguments.Add(ReferenceExpression('ID'))
		exprField.Attributes.Add(attr)
		cls.Members.Add(exprField)
		writeSave = [|WriteBERInt(output, _ID)|].withLexicalInfoFrom(idLine)
		save.Body.Add(writeSave)

	last = 0
	skipping = false
	var initBlock = Block()
	for decl in Flatten(body):
		writeUnless as Expression = null
		match decl.Expression:
			case [|$num = $fld as $type|]:
				id = $num as IntegerLiteralExpression
				raise "Left side must be an integer: $(decl.ToCodeString())" if id is null
				raise "ID numbers must be declared in order" if id.Value <= last
				last = id.Value
				ifBlock = [|
					if current == $id:
						current = BERInt(input)
					elif current < $id and current > 0:
						raise LCFUnexpectedSection(current, $id, $name)
				|]
				if mapping.ContainsKey(type.ToString()):
					isMapping = true
					tr = mapping[type.ToString()] cast ReferenceExpression
					mappedType = (SimpleTypeReference(tr.Name) if tr is not null else null)
				else: isMapping = false
				if isMapping and mappedType is null:
					skipping = true
					ifBlock.TrueBlock.Insert(0, ExpressionStatement([|_legacy.Add($id, LCFByteArray(input))|]))
					type = null
					writeExpr = [|WriteByteArray(output, _legacy[$id])|]
					writeUnless = [|not _legacy.ContainsKey($id)|]
				else:
					match fld:
						case [|$fld($default)|]:
							fldName = (fld cast ReferenceExpression).Name
							iFldName = ReferenceExpression('_' + fldName)
							writeUnless = [|$iFldName == $default|]
						case ReferenceExpression(Name: fldName):
							iFldName = ReferenceExpression('_' + fldName)
							default = null
					if (not isMapping) and type isa ArrayTypeReference:
						basetype = ReferenceExpression((type cast ArrayTypeReference).ElementType.ToString())
						initBlock.Add([|$iFldName = System.Collections.Generic.List[of $basetype]()|])
						extra =[|
							check = BERInt(input) + input.Position
							for i in range(BERInt(input)):
								$fld.Add($basetype(input))
							raise "Unexpected input position" unless input.Position == check
						|]
						type = GenericTypeReference('System.Collections.Generic.List', SimpleTypeReference(basetype.Name))
						ifBlock.TrueBlock.Insert(0, extra)
						writeExpr = [|WriteList(output, $iFldName)|]
					elif type isa GenericTypeReference:
						gtr = type cast GenericTypeReference
						assert gtr.Name == 'System.Collections.Generic.IEnumerable'
						type = gtr.GenericArguments[0] cast SimpleTypeReference
						basetype = ReferenceExpression(type.ToString())
						initBlock.Add([|$iFldName = System.Collections.Generic.List[of $basetype]()|])
						extra = [|
							check = BERInt(input) + input.Position
							while input.Position < check:
								$iFldName.Add($basetype(input))
							raise "Unexpected input position" unless input.Position == check
						|]
						type = GenericTypeReference('System.Collections.Generic.List', SimpleTypeReference(basetype.Name))
						ifBlock.TrueBlock.Insert(0, extra)
						writeExpr = [|WriteSequence(output, $iFldName)|]
					else:
						fldClass = ReferenceExpression((mappedType.ToString() if isMapping else type.ToString()))
						ifBlock.TrueBlock.Insert(0, ExpressionStatement([|$iFldName = $fldClass(input)|]))
						if isMapping: //skip length specifier on object types
							writeExpr = [|WriteValue(output, $iFldName)|]
						else:
							ifBlock.TrueBlock.Insert(0, ExpressionStatement([|BERInt(input)|]))
							writeExpr = [|WriteValue(output, $iFldName)|]
					if default is not null and not (default isa NullLiteralExpression):
						ifs = ifBlock.FalseBlock.FirstStatement cast IfStatement
						assert ifs.FalseBlock is null
						ifs.FalseBlock = Block(ExpressionStatement([|$iFldName = $fldClass($default)|]))
					type = mappedType if (isMapping and type.ToString().EndsWith('Array'))
		if writeUnless is not null:
			unlessStmt = UnlessStatement(writeUnless)
			writeBlock = unlessStmt.Block
			save.Body.Add(unlessStmt)
		else: writeBlock = save.Body
		writeBlock.Add([|WriteBERInt(output, $id)|])
		writeBlock.Add(writeExpr)
		writeBlock.LexicalInfo = decl.LexicalInfo
		ctr.Body.Add(ifBlock)
		ifBlock.LexicalInfo = decl.LexicalInfo
		unless type is null:
			exprField = Field(decl.Expression.LexicalInfo, type, null, Name: iFldName.Name,
				Modifiers: TypeMemberModifiers.Private)
			attr = Boo.Lang.Compiler.Ast.Attribute('Property')
			attr.Arguments.Add(ReferenceExpression(fldName))
			exprField.Attributes.Add(attr)
			cls.Members.Add(exprField)
	
	if skipping:
			exprField = Field(LCFObject.LexicalInfo, null, [|System.Collections.Generic.Dictionary[of int, (byte)]()|],
				Name: '_legacy', Modifiers: TypeMemberModifiers.Private | TypeMemberModifiers.Final)
			attr = Boo.Lang.Compiler.Ast.Attribute('Getter')
			attr.Arguments.Add(ReferenceExpression('Legacy'))
			exprField.Attributes.Add(attr)
			cls.Members.Add(exprField)
		
	unless LCFObject.ContainsAnnotation('noZeroEnd'):
		ctr.Body.Add([|assert current == 0, "Ending 0 not found at offset $(input.Position.ToString('X'))"|])
		save.Body.Add([|output.WriteByte(0)|])
	ctr.Body.Insert(0, initBlock)
	cls.Members.Add(ctr)
	cls.Members.Add(save)
	yield cls
