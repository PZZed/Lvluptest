extends Control
class_name LevelUpPanel

signal upgrade_selected(upgrade: UpgradeData)

@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var choices_container: VBoxContainer = $Panel/Margin/VBox/Choices

func show_choices(level: int, choices: Array[UpgradeData]) -> void:
    title_label.text = "Niveau %d atteint ! Choisis une amélioration" % level

    for child in choices_container.get_children():
        child.queue_free()

    for upgrade in choices:
        var button := Button.new()
        button.custom_minimum_size = Vector2(560, 54)
        button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        button.text = "%s\n%s" % [upgrade.display_name, upgrade.description]
        button.pressed.connect(_on_upgrade_button_pressed.bind(upgrade))
        choices_container.add_child(button)

    show()

func hide_panel() -> void:
    hide()

func _on_upgrade_button_pressed(upgrade: UpgradeData) -> void:
    upgrade_selected.emit(upgrade)
