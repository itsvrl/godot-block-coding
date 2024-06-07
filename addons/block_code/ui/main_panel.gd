@tool
class_name MainPanel
extends Control

var eia: EditorInterfaceAccess

@onready var _picker: Picker = %Picker
@onready var _block_canvas: BlockCanvas = %NodeBlockCanvas
@onready var _drag_manager: DragManager = %DragManager
#@onready var _node_canvas := %NodeCanvas
#@onready var _node_list: NodeList = %NodeList
@onready var _title_bar: TitleBar = %TitleBar

var _current_path: String
var _current_bsd: BlockScriptData


func _ready():
	_picker.block_picked.connect(_drag_manager.copy_picked_block_and_drag)
	_block_canvas.reconnect_block.connect(_drag_manager.connect_block_canvas_signals)
	_drag_manager.block_dropped.connect(save_script)
	_drag_manager.block_modified.connect(save_script)
	#_node_list.node_selected.connect(_title_bar.node_selected)
	#_title_bar.node_name_changed.connect(_node_list.on_node_name_changed)


func _on_button_pressed():
	# FIXME: hardcoded, get the blocks from selected node in tree?
	var path = "res://test_game/my_character_bsd.tres"
	var bsd = load(path)
	# var bsd = preload("res://test_game/my_character_bsd.tres")
	# var bsd: BlockScriptData = ResourceLoader.load(bsd_path, "BlockScriptData", ResourceLoader.CACHE_MODE_IGNORE)
	switch_script(path, bsd)


func _on_bsd_changed():
	prints("main panel bsd changed!")


func switch_script(path: String, bsd: BlockScriptData):
	_current_path = path
	_current_bsd = bsd
	_current_bsd.changed.connect(_on_bsd_changed)
	_picker.bsd_selected(bsd)
	_title_bar.bsd_selected(bsd)
	_block_canvas.bsd_selected(bsd)


func create_and_switch_script(path: String, bsd: BlockScriptData):
	switch_script(path, bsd)
	save_script()


func save_script():
	if _current_bsd == null:
		print("No script loaded to save.")
		return

	var block_trees := _block_canvas.get_canvas_block_trees()
	var script_text: String = _block_canvas.generate_script_from_current_window(_current_bsd.script_class_name, _current_bsd.script_inherits)
	_current_bsd.block_trees = block_trees
	_current_bsd.script_source_code = script_text
	var error: Error = ResourceSaver.save(_current_bsd, _current_path)

	if error == OK:
		print("Saved block script to " + _current_path)
	else:
		print("Failed to create block script: " + str(error))


func _input(event):
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				# Release focus
				var focused_node := get_viewport().gui_get_focus_owner()
				if focused_node:
					focused_node.release_focus()
			else:
				_drag_manager.drag_ended()

	# HACK: play the topmost block
	if event is InputEventKey:
		if event.keycode == KEY_F and event.pressed:
			if _current_bsd:
				var script: String = _block_canvas.generate_script_from_current_window(_current_bsd.script_class_name, _current_bsd.script_inherits)

				print(script)
				print("Debug script! (not saved)")
