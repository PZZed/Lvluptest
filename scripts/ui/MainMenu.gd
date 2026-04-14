extends Control

@onready var essence_label: Label = $Panel/VBox/EssenceLabel
@onready var class_selector: OptionButton = $Panel/VBox/ClassSelector
@onready var shop_list: VBoxContainer = $Panel/VBox/ShopList

func _ready() -> void:
    $Panel/VBox/StartButton.pressed.connect(_on_start_pressed)
    $Panel/VBox/QuitButton.pressed.connect(_on_quit_pressed)
    class_selector.item_selected.connect(_on_class_selected)

    MetaProgression.essence_changed.connect(_refresh_essence_label)
    MetaProgression.upgrade_purchased.connect(_on_upgrade_purchased)
    MetaProgression.classes_changed.connect(_refresh_class_selector)

    _refresh_essence_label(MetaProgression.essence)
    _refresh_class_selector(MetaProgression.get_unlocked_class_ids())
    _build_shop_buttons()

func _on_start_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

func _on_quit_pressed() -> void:
    get_tree().quit()

func _on_class_selected(index: int) -> void:
    var class_id := StringName(class_selector.get_item_metadata(index))
    MetaProgression.set_selected_class(class_id)

func _refresh_essence_label(total: int) -> void:
    essence_label.text = "Essence: %d" % total

func _refresh_class_selector(unlocked_class_ids: Array[StringName]) -> void:
    class_selector.clear()

    for class_id in unlocked_class_ids:
        var class_data := MetaProgression.get_class_data(class_id)
        if class_data == null:
            continue

        class_selector.add_item(class_data.display_name)
        var new_index := class_selector.item_count - 1
        class_selector.set_item_metadata(new_index, class_id)

        if class_id == MetaProgression.selected_class_id:
            class_selector.select(new_index)

func _build_shop_buttons() -> void:
    for child in shop_list.get_children():
        child.queue_free()

    for upgrade in MetaProgression.get_shop_upgrades():
        var button := Button.new()
        button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        button.custom_minimum_size = Vector2(520, 46)
        button.text = _format_upgrade_label(upgrade)
        button.disabled = not MetaProgression.can_purchase(upgrade)
        button.pressed.connect(_on_upgrade_pressed.bind(upgrade))
        shop_list.add_child(button)

func _on_upgrade_pressed(upgrade: PermanentUpgradeData) -> void:
    var purchased := MetaProgression.purchase_upgrade(upgrade)
    if purchased:
        _build_shop_buttons()

func _on_upgrade_purchased(_upgrade_id: StringName, _new_rank: int) -> void:
    _build_shop_buttons()

func _format_upgrade_label(upgrade: PermanentUpgradeData) -> String:
    var rank := MetaProgression.get_upgrade_rank(upgrade.id)
    var cost := upgrade.get_cost_for_rank(rank)

    if rank >= upgrade.max_rank:
        return "%s [MAX]" % upgrade.display_name

    return "%s (Rang %d/%d) - Coût: %d" % [upgrade.display_name, rank, upgrade.max_rank, cost]
