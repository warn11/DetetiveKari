extends Control

@onready var title_label: Label = $Margin/VBox/Title
@onready var story_label: RichTextLabel = $Margin/VBox/Story
@onready var dialogue_label: RichTextLabel = $Margin/VBox/Dialogue
@onready var suspect_cards: VBoxContainer = $Margin/VBox/Suspects
@onready var clues_label: RichTextLabel = $Margin/VBox/Clues
@onready var suspect_pick: OptionButton = $Margin/VBox/DeductionPanel/SuspectPick
@onready var motive_pick: OptionButton = $Margin/VBox/DeductionPanel/MotivePick
@onready var method_pick: OptionButton = $Margin/VBox/DeductionPanel/MethodPick
@onready var next_dialogue_button: Button = $Margin/VBox/Actions/DialogueNext
@onready var deduce_button: Button = $Margin/VBox/Actions/Deduce
@onready var reset_button: Button = $Margin/VBox/Actions/Reset
@onready var hotspot_bulb: Button = $Margin/VBox/SceneArea/SceneRoot/HotspotBulb
@onready var hotspot_glove: Button = $Margin/VBox/SceneArea/SceneRoot/HotspotGlove
@onready var hotspot_camera: Button = $Margin/VBox/SceneArea/SceneRoot/HotspotCamera
@onready var hotspot_door: Button = $Margin/VBox/SceneArea/SceneRoot/HotspotDoor
@onready var log_label: RichTextLabel = $Margin/VBox/Log

var case_data: Dictionary = {}
var discovered_clue_ids: Dictionary = {}
var discovered_clues: Array[Dictionary] = []
var dialogue_index: int = 0
var is_case_closed: bool = false

func _ready() -> void:
    load_case_data()
    connect_buttons()
    initialize_case()

func load_case_data() -> void:
    var file := FileAccess.open("res://data/case_01.json", FileAccess.READ)
    if file == null:
        push_error("无法读取案件文件。")
        return
    var parsed := JSON.parse_string(file.get_as_text())
    if typeof(parsed) == TYPE_DICTIONARY:
        case_data = parsed

func connect_buttons() -> void:
    next_dialogue_button.pressed.connect(_on_dialogue_next_pressed)
    deduce_button.pressed.connect(_on_deduce_pressed)
    reset_button.pressed.connect(_on_reset_pressed)
    hotspot_bulb.pressed.connect(func() -> void: _on_hotspot_pressed("broken_bulb", hotspot_bulb))
    hotspot_glove.pressed.connect(func() -> void: _on_hotspot_pressed("ink_stain", hotspot_glove))
    hotspot_camera.pressed.connect(func() -> void: _on_hotspot_pressed("camera_gap", hotspot_camera))
    hotspot_door.pressed.connect(func() -> void: _on_hotspot_pressed("door_mark", hotspot_door))

func initialize_case() -> void:
    discovered_clue_ids.clear()
    discovered_clues.clear()
    dialogue_index = 0
    is_case_closed = false

    title_label.text = "%s - %s" % [case_data.get("hero_name", "卡里"), case_data.get("case_title", "第一章")]
    story_label.text = String(case_data.get("intro", "案件加载失败。"))
    dialogue_label.text = "对话：\n- 等待推进"
    clues_label.text = "证物背包：\n- 暂无"
    log_label.text = "这是2D侦查模式：推进对话后，点击现场线索点。"

    build_suspect_cards()
    build_deduction_options()
    update_hotspots_enabled()
    deduce_button.disabled = true

func update_hotspots_enabled() -> void:
    var dialogue_done := dialogue_index >= (case_data.get("dialogue", []) as Array).size()
    hotspot_bulb.disabled = not dialogue_done
    hotspot_glove.disabled = not dialogue_done
    hotspot_camera.disabled = not dialogue_done
    hotspot_door.disabled = not dialogue_done

func build_suspect_cards() -> void:
    for child in suspect_cards.get_children():
        child.queue_free()
    for suspect in case_data.get("suspects", []):
        var card := Label.new()
        card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        card.text = "嫌疑人：%s | 动机：%s | 证词：%s" % [
            String(suspect.get("name", "未知")),
            String(suspect.get("motive", "无")),
            String(suspect.get("alibi", "无"))
        ]
        suspect_cards.add_child(card)

func build_deduction_options() -> void:
    suspect_pick.clear()
    motive_pick.clear()
    method_pick.clear()
    for suspect in case_data.get("suspects", []):
        suspect_pick.add_item(String(suspect.get("name", "未知")))
    motive_pick.add_item("合同破裂后报复")
    motive_pick.add_item("掩盖揭露失败风险")
    motive_pick.add_item("争夺编辑主导权")
    method_pick.add_item("伪造访客登记")
    method_pick.add_item("制造停电后潜入篡改")
    method_pick.add_item("远程替换文档")

func _on_dialogue_next_pressed() -> void:
    if is_case_closed:
        log_label.text = "案件已结案。"
        return
    var dialogue: Array = case_data.get("dialogue", [])
    if dialogue_index >= dialogue.size():
        log_label.text = "对话已结束，直接点击2D现场线索点。"
        update_hotspots_enabled()
        return

    var line: Dictionary = dialogue[dialogue_index]
    dialogue_index += 1
    dialogue_label.text = "对话：\n- %s：%s" % [line.get("speaker", "旁白"), line.get("text", "")]
    update_hotspots_enabled()

    if dialogue_index >= dialogue.size():
        log_label.text = "对话结束，2D现场线索点已解锁。"
    else:
        log_label.text = "已推进对话 %d/%d" % [dialogue_index, dialogue.size()]

func _on_hotspot_pressed(clue_id: String, button: Button) -> void:
    if is_case_closed:
        return
    if discovered_clue_ids.has(clue_id):
        log_label.text = "该线索已调查。"
        return

    var clue := get_clue_by_id(clue_id)
    if clue.is_empty():
        return

    discovered_clue_ids[clue_id] = true
    discovered_clues.append(clue)
    button.disabled = true
    refresh_clues_panel()
    log_label.text = "发现证物：%s" % String(clue.get("title", "未知证物"))

    if discovered_clues.size() >= 4:
        deduce_button.disabled = false
        log_label.text = "全部关键证物已拿到，可提交推理。"

func get_clue_by_id(clue_id: String) -> Dictionary:
    for clue in case_data.get("clues", []):
        if String(clue.get("id", "")) == clue_id:
            return clue
    return {}

func refresh_clues_panel() -> void:
    if discovered_clues.is_empty():
        clues_label.text = "证物背包：\n- 暂无"
        return
    var lines: PackedStringArray = ["证物背包："]
    for clue in discovered_clues:
        lines.append("- %s：%s" % [clue.get("title", "未知"), clue.get("desc", "")])
    clues_label.text = "\n".join(lines)

func _on_deduce_pressed() -> void:
    if is_case_closed:
        return
    if discovered_clues.size() < 4:
        log_label.text = "证物不足，请继续点击2D现场线索点。"
        return

    var deduction: Dictionary = case_data.get("deduction", {})
    var suspect_ok := suspect_pick.get_item_text(suspect_pick.selected) == String(deduction.get("correct_suspect", ""))
    var motive_ok := motive_pick.get_item_text(motive_pick.selected) == String(deduction.get("correct_motive", ""))
    var method_ok := method_pick.get_item_text(method_pick.selected) == String(deduction.get("correct_method", ""))
    is_case_closed = true

    if suspect_ok and motive_ok and method_ok:
        story_label.text = String(deduction.get("success_text", "卡里还原了全部真相。"))
        log_label.text = "推理成立：三要素全部正确。"
    else:
        story_label.text = String(deduction.get("failure_text", "推理失败。"))
        log_label.text = "推理未闭环：可重开后再试。"

func _on_reset_pressed() -> void:
    initialize_case()
