# Editor call my method

A simple plugin that allows calling methods prefixed with `__EDITOR__FNC_` in a tool script from the editor.

A menu will show up for the selected node/resource if it contains prefixed methods. Selecting an entry will cause the method to be called.

Additionally, a tool script can expose the method `__EDITOR_OUT__`that must return a string. The method will be called every frame, and the output will be shown in a label in the editor, useful for tool scripts that can change state.

Example:

```python
tool
extends Node

var value: int = 0


func __EDITOR_FNC__increment() -> void:
	value += 1


func __EDITOR_OUT__() -> String:
	return str(value)
```
