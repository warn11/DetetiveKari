extends Control

@onready var title_label: Label = $Margin/VBox/Title
@onready var story_label: RichTextLabel = $Margin/VBox/Story
@onready var clues_label: RichTextLabel = $Margin/VBox/Clues
@onready var suspect_buttons: VBoxContainer = $Margin/VBox/Suspects
@onready var inspect_button: Button = $Margin/VBox/Actions/Inspect
@onready var deduce_button: Button = $Margin/VBox/Actions/Deduce
@onready var reset_button: Button = $Margin/VBox/Actions/Reset
@onready var log_label: RichTextLabel = $Margin/VBox/Log

var case_data: Dictionary = {}
var discovered_clues: Array = []
var current_clue_index: int = 0
var selected_suspect: String = ""
var is_case_closed: bool = false

func _ready() -> void:
    randomize()
    load_case_data()
    connect_buttons()
    initialize_case()

func load_case_data() -> void:
    var file := FileAccess.open("res://data/case_01.json", FileAccess.READ)
    if file == null:
        push_error("Failed to open case file.")
        return
    var parsed := JSON.parse_string(file.get_as_text())
    if typeof(parsed) == TYPE_DICTIONARY:
        case_data = parsed
    else:
        push_error("Case data format is invalid.")

func connect_buttons() -> void:
    inspect_button.pressed.connect(_on_inspect_pressed)
    deduce_button.pressed.connect(_on_deduce_pressed)
    reset_button.pressed.connect(_on_reset_pressed)

func initialize_case() -> void:
    discovered_clues.clear()
    current_clue_index = 0
    selected_suspect = ""
    is_case_closed = false

    title_label.text = "%s - %s" % [case_data.get("hero_name", "Kari"), case_data.get("case_title", "Case")]
    story_label.text = case_data.get("intro", "No case data loaded.")
    clues_label.text = "Discovered clues:\n- None"
    log_label.text = "Investigation started. Use Inspect to find clues."

    rebuild_suspect_buttons()
    deduce_button.disabled = true

func rebuild_suspect_buttons() -> void:
    for child in suspect_buttons.get_children():
        child.queue_free()

    var suspects: Array = case_data.get("suspects", [])
    for suspect_data in suspects:
        var btn := Button.new()
        var suspect_name := String(suspect_data.get("name", "Unknown"))
        btn.text = "Select suspect: %s" % suspect_name
        btn.toggle_mode = true
        btn.pressed.connect(func() -> void:
            _on_select_suspect(suspect_name)
        )
        suspect_buttons.add_child(btn)

func _on_select_suspect(suspect_name: String) -> void:
    selected_suspect = suspect_name
    for child in suspect_buttons.get_children():
        if child is Button:
            child.button_pressed = child.text.ends_with(selected_suspect)
    log_label.text = "Kari marked %s as primary suspect." % selected_suspect

func _on_inspect_pressed() -> void:
    if is_case_closed:
        log_label.text = "Case is closed. Press Reset to replay."
        return

    var clues: Array = case_data.get("clues", [])
    if current_clue_index >= clues.size():
        log_label.text = "No new clues left. Time to deduce."
        deduce_button.disabled = false
        return

    var clue: Dictionary = clues[current_clue_index]
    discovered_clues.append(clue)
    current_clue_index += 1

    update_clue_panel()
    log_label.text = "Clue found: %s" % clue.get("title", "Unknown")

    if current_clue_index >= clues.size():
        deduce_button.disabled = false

func update_clue_panel() -> void:
    if discovered_clues.is_empty():
        clues_label.text = "Discovered clues:\n- None"
        return

    var lines: PackedStringArray = []
    lines.append("Discovered clues:")
    for clue in discovered_clues:
        lines.append("- %s: %s" % [clue.get("title", "Unknown"), clue.get("desc", "")])
    clues_label.text = "\n".join(lines)

func _on_deduce_pressed() -> void:
    if is_case_closed:
        log_label.text = "Case is already closed."
        return

    if selected_suspect.is_empty():
        log_label.text = "Select a suspect before deduction."
        return

    var correct_answer := String(case_data.get("correct_answer", ""))
    is_case_closed = true

    if selected_suspect == correct_answer:
        story_label.text = "Kari solved it. %s tampered with the manuscript and sabotaged the lights." % selected_suspect
        log_label.text = "Deduction success. Justice served."
    else:
        story_label.text = "Kari accused %s, but contradictions remain. The real culprit escaped for now." % selected_suspect
        log_label.text = "Deduction failed. Re-open and investigate again."

func _on_reset_pressed() -> void:
    initialize_case()
