namespace dm.shaders

import Jv.StringHolder
import Pythia.Runtime
import System
import System.Collections.Generic
import System.Linq.Enumerable
import System.Text
import SDL2.SDL2_GPU
import TURBU.Meta

[Disposable(Destroy, true)]
partial class TdmShaders():

	public FragLibs as Dictionary[of string, string]

	public Vertex as Dictionary[of string, string]

	public Fragment as Dictionary[of string, string]

	public def Destroy():
		for handle in FPrograms.Values:
			GPU_FreeShaderProgram(handle)
		for handle in FMap.Values:
			GPU_FreeShader(handle)

	private struct TUniform:

		prog as int

		name as string

		def constructor(aProg as int, aName as string):
			self.prog = aProg
			self.name = aName
	
	private class UniformComparer(IEqualityComparer of TUniform):
		def Equals (left as TUniform, right as TUniform) as bool:
			return (left.prog == right.prog) and (left.name == right.name)
		
		def GetHashCode(obj as TUniform) as int:
			return BooHashCodeProvider.Default.GetHashCode(obj)

	private class IntArrayEqualityComparer(IEqualityComparer of (int)):
		def Equals(x as (int), y as (int)) as bool:
			return false if x.Length != y.Length
			for i in range(x.Length):
				return false if x[i] != y[i]
			return true
		
		def GetHashCode(obj as (int)) as int:
			var result = 17
			for i in obj:
				unchecked:
					result = result * 23 + i
			return result
	
	private FMap = Dictionary[of string, int]()

	private FPrograms = Dictionary[of (int), int](IntArrayEqualityComparer())

	private FUniforms = Dictionary[of TUniform, int]()

	def constructor():
		try:
			super()
			Initialize()
			for name in FragLibs.Keys:
				self.GetShader(name, FragLibs)
			for name in Vertex.Keys:
				self.GetShader(name, Vertex)
			for name in Fragment.Keys:
				self.GetShader(name, Fragment)
		failure:
			self.Dispose()

	private def GetShader(name as string, container as Dictionary[of string, string]) as int:
		shaderText as string
		strShaderType as string
		result as int
		if not FMap.TryGetValue(name, result):
			if name[0] == '#':
				shaderText = name
			else:
				shaderText = container[name]
			result = GPU_CompileShader(GetShaderType(container), shaderText)
			if result == 0:
				caseOf GetShaderType(container):
					case GPU_ShaderEnum.GPU_VERTEX_SHADER:
						strShaderType = 'Vertex'
					case GPU_ShaderEnum.GPU_FRAGMENT_SHADER:
						strShaderType = 'Fragment'
					default :
						strShaderType = ''
				raise Exception("Compile failure in $strShaderType shader: $(GPU_GetShaderMessage())")
			FMap.Add(name, result)
		return result

	private def GetShaderType(container as Dictionary[of string, string]) as GPU_ShaderEnum:
		if container == Vertex:
			return GPU_ShaderEnum.GPU_VERTEX_SHADER
		elif (container == Fragment) or (container == FragLibs):
			return GPU_ShaderEnum.GPU_FRAGMENT_SHADER
		else: raise Exception('Bad container')

	private def BuildProgram(units as (int)) as int:
		shader as int
		glCheckError()
		result = GPU_CreateShaderProgram()
		for shader in units:
			GPU_AttachShader(result, shader)
			glCheckError()
		if GPU_LinkShaderProgram(result) == 0:
			raise Exception("Shader link failure: $(GPU_GetShaderMessage())")
		FPrograms.Add(units, result)
		return result

	private def GetUniformLocation(handle as int, name as string) as int:
		uni as TUniform
		result as int
		glCheckError()
		uni = TUniform(handle, name)
		unless FUniforms.TryGetValue(uni, result):
			result = GPU_GetUniformLocation(handle, name)
			glCheckError()
			if result == -1:
				raise Exception("No uniform \"$name\" found in program $handle")
			FUniforms.Add(uni, result)
		return result

	public def ShaderProgram(vert as string, frag as string) as int:
		return ShaderProgram(vert, frag, '')

	public def ShaderProgram(vert as string, frag as string, libs as string) as int:
		result as int
		glCheckError()
		vertMain as int = GetShader(vert, Vertex)
		fragMain as int = GetShader(frag, Fragment)
		units as (int) = (vertMain, fragMain)
		if libs != '':
			units = units.Concat(libs.Split(*(char(','),)) \
						 .Select({name | GetShader(name, FragLibs)})) \
						 .ToArray()
		Array.Sort[of int](units)
		unless FPrograms.TryGetValue(units, result):
			result = BuildProgram(units)
		return result

	public def UseShaderProgram(value as int):
		glCheckError()
		block = GPU_LoadShaderBlock(value, "RPG_Vertex", "RPG_TexCoord", "RPG_Color", "RPG_ModelViewProjectionMatrix")
		GPU_ActivateShaderProgram(value, block)
		glCheckError()

	public def SetUniformValue(handle as int, name as string, value as int):
		GPU_SetUniformi(GetUniformLocation(handle, name), value)
		glCheckError()

	public def SetUniformValue(handle as int, name as string, value as single):
		GPU_SetUniformf(GetUniformLocation(handle, name), value)
		glCheckError()

	public def SetUniformValue(handle as int, name as string, value as (single)):
		GPU_SetUniformfv(GetUniformLocation(handle, name), value.Length, 1, value)
		glCheckError()

def glCheckError():
	/*
	err = gl.GetError()
	if err != GL.NO_ERROR:
		System.Diagnostics.Debugger.Break()
	*/
	pass
