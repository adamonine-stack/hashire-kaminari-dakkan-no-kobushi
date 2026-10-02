extends Node

## Snapshot contact eligibility before either special cancels the other actor.
## All admitted contacts in this physics step can trade; no player priority.
var contacts: Array[Dictionary] = []
var scheduled := false


func enqueue(attacker: Node, target: Node, packet: Dictionary, direction: float, point: Vector2) -> void:
	if not target.can_receive_attack():
		return
	contacts.append({"attacker": weakref(attacker), "target": weakref(target),
		"packet": packet.duplicate(true), "direction": direction, "point": point})
	if not scheduled:
		scheduled = true
		call_deferred("resolve_contacts")


func resolve_contacts() -> void:
	var batch := contacts
	contacts = []
	scheduled = false
	for contact in batch:
		var attacker: Node = contact.attacker.get_ref()
		var target: Node = contact.target.get_ref()
		if not is_instance_valid(attacker) or not is_instance_valid(target) or target.current_hp <= 0:
			continue
		# Invulnerability granted by another contact in this batch must not erase
		# an already admitted simultaneous hit. Existing immunity was checked above.
		var invincible_before: bool = target.is_invincible
		target.is_invincible = false
		var hit: bool = target.receive_attack(contact.packet, contact.direction, contact.point, attacker)
		target.is_invincible = target.is_invincible or invincible_before
		attacker._complete_special_contact(target, contact.packet, contact.point, hit)
