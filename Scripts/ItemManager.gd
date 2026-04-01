extends CanvasLayer

var item_power_up_slots: Array[Node2D] = []

func _ready():
	var last_power_up = GridState.PowerUpType.values()[GridState.PowerUpType.size()-1]+1
	for i in range(1, last_power_up):
		for team: SpecialTile.TeamRelation in [SpecialTile.TeamRelation.Red, SpecialTile.TeamRelation.Blue]:
			create_item_slot(team, i, last_power_up)

func create_item_slot(team: SpecialTile.TeamRelation, power_up: SpecialTile.TeamRelation, last_power_up: GridState.PowerUpType):
	var slot_instance = UID.item_slot.instantiate()
	slot_instance.setup(self, item_power_up_slots, power_up, team, last_power_up)

const hovered_slot_modulate = Color(0xfffc96ff)

func _process(_delta):
	for item_slot: ItemSlot in item_power_up_slots:
		item_slot.update_slot()
		var hovering_over_slot = item_slot.is_mouse_inside_slot()
		if hovering_over_slot: item_slot.main_sprite.modulate = hovered_slot_modulate
