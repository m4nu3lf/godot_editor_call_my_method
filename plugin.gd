#########################################################################
# Copyright (c) 2022 Manuele Finocchiaro.                               #
#                                                                       #
# Permission is hereby granted, free of charge, to any person obtaining #
# a copy of this software and associated documentation files (the       #
# "Software"), to deal in the Software without restriction, including   #
# without limitation the rights to use, copy, modify, merge, publish,   #
# distribute, sublicense, and/or sell copies of the Software, and to    #
# permit persons to whom the Software is furnished to do so, subject to #
# the following conditions:                                             #
#                                                                       #
# The above copyright notice and this permission notice shall be        #
# included in all copies or substantial portions of the Software.       #
#                                                                       #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       #
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    #
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.#
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  #
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  #
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     #
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                #
#########################################################################


tool
extends EditorPlugin

const EDITOR_METHOD_PREFIX = "__EDITOR_FNC__"
const OUTPUT_METHOD_NAME = "__EDITOR_OUT__"

var _menu_buttons: Array
var _output_labels: Array
var _output_label_containers: Array
var _object: Object
var _prev_output: String
var _got_object_in_frame: bool = false


func _init() -> void:
	var base_control = get_editor_interface().get_base_control()
	for button_contnainer in [EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,
			EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU]:
		var menu_button = MenuButton.new()
		menu_button.visible = false
		var menu: PopupMenu = menu_button.get_popup()
		menu.connect("id_pressed", self, "_on_menu_item_pressed")
		add_control_to_container(button_contnainer, menu_button)
		_menu_buttons.push_back(menu_button)
	
	for outupt_label_container in [EditorPlugin.CONTAINER_SPATIAL_EDITOR_BOTTOM,
			EditorPlugin.CONTAINER_CANVAS_EDITOR_BOTTOM]:
		var output_label = Label.new()
		output_label.visible = false
		var output_label_container = PanelContainer.new()
		output_label_container.add_child(output_label)
		add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_BOTTOM, output_label_container)
		_output_labels.push_back(output_label)
		_output_label_containers.push_back(output_label_container)


func make_visible(visible: bool) -> void:
	for menu_button in _menu_buttons:
		menu_button.visible = visible
	for output_label in _output_labels:
		output_label.visible = visible


func handles(object: Object) -> bool:
	if _got_object_in_frame:
		return true
	var script = object.get_script()
	if not script or not script.is_tool():
		return false
	var methods = object.get_method_list()
	for method in methods:
		if method["name"].begins_with(EDITOR_METHOD_PREFIX):
			return true
	return false


func _identifier_to_label(method_name: String) -> String:
	var words: PoolStringArray = method_name.trim_prefix(EDITOR_METHOD_PREFIX).split("_")
	var label: String = ""
	for word in words:
		label = label + word.capitalize() + " "
	label = label.trim_suffix(" ")
	return label


func _label_to_identifier(label: String) -> String:
	return str(EDITOR_METHOD_PREFIX, label.replacen(" ", "_").to_lower())


func edit(object: Object) -> void:
	if _got_object_in_frame:
		return
	if object:
		_got_object_in_frame = true
		_object = object
		_prev_output = ""
		for menu_button in _menu_buttons:
			menu_button.disabled = false
			var script_name = object.get_script().resource_path.get_file()
			var script_name_extension = object.get_script().resource_path.get_extension()
			script_name = script_name \
					.substr(0, script_name.length() - script_name_extension.length() - 1)
			menu_button.text = _identifier_to_label(script_name)
			var menu: PopupMenu = menu_button.get_popup()
			menu.clear()
			for method in object.get_method_list():
				var method_name = method["name"]
				if method_name.begins_with(EDITOR_METHOD_PREFIX):
					menu.add_item(_identifier_to_label(method_name))
	else:
		_object = null


func _on_menu_item_pressed(id: int) -> void:
	var label = _menu_buttons[0].get_popup().get_item_text(id)
	var method_name = _label_to_identifier(label)
	_object.call(method_name)


func _process(_dt: float) -> void:
	if is_instance_valid(_object) and _object.has_method(OUTPUT_METHOD_NAME):
		var output = _object.call(OUTPUT_METHOD_NAME)
		if output != _prev_output:
			var object_name = _object.get_instance_id()
			if _object.has_method("get_name"):
				object_name = _object.get_name()
			for output_label in _output_labels:
				output_label.text = str(" ".repeat(220), "[", object_name, "]: ", output)
			_prev_output = output
	else:
		for output_label in _output_labels:
			output_label.text = ""
	_got_object_in_frame = false
