namespace TURBU.EngineBasis

import System
import System.Collections.Generic

public class TreeNode[of T](IEnumerable[of T]):
	property Value as T

	[Getter(Children)]
	private _children = List[of TreeNode[of T]]()

	private _parent as TreeNode[of T]

	public def constructor(value as T):
		super()
		Value = value
	
	public def Add(node as TreeNode[of T]):
		_children.Add(node)
		node.Parent = self

	public def Add(value as T):
		Add(TreeNode[of T](value))

	def System.Collections.IEnumerable.GetEnumerator() as System.Collections.IEnumerator:
		return self.DoGetEnumerator()

	def GetEnumerator() as IEnumerator[of T]:
		return self.DoGetEnumerator()

	private def DoGetEnumerator() as IEnumerator[of T]:
		yield Value
		for child in _children:
			yieldAll child

	public Parent as TreeNode[of T]:
		get: return _parent
		set:
			if _parent is not null:
				_parent.Children.Remove(self)
			if value is not null:
				value.Add(self)

	public Level as int:
		get:
			if _parent is null:
				return 0
			return _parent.Level + 1
