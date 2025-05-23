# EventEffects.gd
# Contains the functions that implement the logic/effects for events.
# These are called by EventHandler.gd.
extends Node

# We might need RNG here too if effects have random elements independent of EventHandler
var rng = RandomNumberGenerator.new()

@onready var event_handler = $"../EventHandler"

# ================================================================
# --- DEFINE EVENT EFFECT FUNCTIONS HERE ---
# These functions MUST match the names used in the JSON file's "effect_func"
# They receive the list of participants and a reference to the EventHandler node.
# ================================================================

# --- Single Participant Effects ---
func apply_find_water(participants):
	if participants.is_empty() or not is_instance_valid(participants[0]): return
	participants[0].adjust_sanity(2)
	# Example: maybe add item
	# participants[0].add_item("Clean Water")

func apply_minor_injury(participants):
	if participants.is_empty() or not is_instance_valid(participants[0]): return
	participants[0].adjust_health(-3)
	



# --- Four Participant Effects ---
func apply_ring_around_the_rosie(participants):
	if participants.size() < 4: return

	# Require same cell?
	var first_pos = participants[0].pos if is_instance_valid(participants[0]) else null
	if first_pos == null: return # Need at least one valid char
	for i in range(1, participants.size()):
		if not is_instance_valid(participants[i]) or participants[i].pos != first_pos:
			event_handler.emit_signal("event_log_updated", "The group couldn't gather in one place to play.")
			return

	# event_handler.multiline = true # Avoid unless used

	for char in participants:
		if not is_instance_valid(char): continue
		var char_charisma = char.charisma

		var diceroll = rng.randi_range(0, 20)
		var total_score = diceroll + char_charisma
		var target_number = 13

		print("%s's roll is: %d (+%d Charisma) = %d. They needed %d to pass." % [char.char_name, diceroll, char_charisma, total_score, target_number])

		if total_score >= target_number:
			var success_message = "%s enjoyed the nostalgic game." % char.char_name
			event_handler.emit_signal("event_log_updated", success_message)
			print(char.char_name, " passed!")
			char.adjust_sanity(2)
		else:
			var failure_message = "It seems that %s hates ring around the rosie..." % char.char_name
			event_handler.emit_signal("event_log_updated", failure_message)
			print(char.char_name, " failed...")
			char.adjust_sanity(-3)
	# event_handler.multiline = false

func apply_fight(participants):
	if participants.size() < 2: return
	var attacker = participants[0]
	var defender = participants[1]

	if not (is_instance_valid(attacker) and is_instance_valid(defender)):
		printerr("Fight failed: Invalid character instance.")
		return

	# Proximity Check: Attackers near defender
	if defender.pos != attacker.pos:
		event_handler.emit_signal("event_log_updated", "The attacker couldn't coordinate their position around %s." % defender.char_name)
		return

	var defender_endurance = defender.endurance
	var defender_form = defender.form
	var attacker_attack = attacker.attack
	var attacker_form = attacker.form

	var diceroll_a = rng.randi_range(1, 20)
	var diceroll_b = rng.randi_range(1, 20)
	
	if defender_form + diceroll_a > attacker_form + diceroll_b:
		var success_message = attacker.char_name + " fails, as " + defender.char_name + " deftly dodges the assault!"
		event_handler.emit_signal("event_log_updated", success_message)
	elif defender_endurance + diceroll_a > attacker_form + diceroll_b:
		var success_message = attacker.char_name + " lands blows, but " + defender.char_name + "'s endurance lessens the impact!"
		event_handler.emit_signal("event_log_updated", success_message)
		# Reduced damage calculation (example)
		var damage_taken = 2 + (attacker_attack / 2) # Base + half combined attack
		defender.adjust_health(-damage_taken)
	else:
		var failure_message = attacker.char_name + " overwhelms " + defender.char_name + ", dealing damage!"
		event_handler.emit_signal("event_log_updated", failure_message)
		# Full damage calculation (example)
		var damage_taken = 5 + attacker_attack # Base + full combined attack
		defender.adjust_health(-damage_taken)
	print("roll results (def_f: %s def_rng: %s atk_f: %s atk_rng: %s)" % [defender_form, diceroll_a, attacker_form, diceroll_b])


func apply_gang_attack(participants):
	if participants.size() < 4: return
	# Assign roles carefully
	var attacker1 = participants[0]
	var attacker2 = participants[1]
	var attacker3 = participants[2]
	var defender = participants[3]

	if not (is_instance_valid(attacker1) and is_instance_valid(attacker2) and is_instance_valid(attacker3) and is_instance_valid(defender)):
		printerr("Gang attack failed: Invalid character instance.")
		return

	# Proximity Check: Attackers near defender
	if defender.pos != attacker1.pos or defender.pos != attacker2.pos or defender.pos != attacker3.pos:
		event_handler.emit_signal("event_log_updated", "The attackers couldn't coordinate their positions around %s." % defender.char_name)
		return

	# Get stats safely
	var defender_endurance = defender.endurance
	var defender_form = defender.form
	var atk1_attack = attacker1.attack
	var atk2_attack = attacker2.attack
	var atk3_attack = attacker3.attack

	var diceroll = rng.randi_range(1, 20)
	var endurance_score = diceroll + defender_endurance
	# Maybe roll form separately? Or use same roll? Let's use same for now.
	var form_score = diceroll + defender_form
	var target_number = 18

	# event_handler.multiline = true

	if form_score >= target_number:
		var success_message = "They fail, as " + defender.char_name + " deftly dodges the assault!"
		event_handler.emit_signal("event_log_updated", success_message)
		print(defender.char_name, " passed with form!")
	elif endurance_score >= target_number:
		var success_message = "They land blows, but " + defender.char_name + "'s endurance lessens the impact!"
		event_handler.emit_signal("event_log_updated", success_message)
		print(defender.char_name, " passed with endurance!")
		var total_attack = atk1_attack + atk2_attack + atk3_attack
		# Reduced damage calculation (example)
		var damage_taken = 2 + (total_attack / 2) # Base + half combined attack
		# Call adjust_health last so if the defender dies, the damage source message comes first in the log
		defender.adjust_health(-damage_taken)
	else:
		var failure_message = "They overwhelm " + defender.char_name + ", dealing massive damage!!!"
		event_handler.emit_signal("event_log_updated", failure_message)
		print(defender.char_name, " failed...")
		# Full damage calculation (example)
		var damage_taken = 15 + atk1_attack + atk2_attack + atk3_attack # Base + full combined attack
		# Call adjust_health last so if the defender dies, the damage source message comes first in the log
		defender.adjust_health(-damage_taken)

func attempt_heal(participants):
	if participants.size() < 1: return
	var healer = participants[0]
	
	var diceroll1 = rng.randi_range(1, 20)
	var diceroll2 = rng.randi_range(1, 20)
	
	if diceroll1 + healer.perception >= 10:
		var successmsg = healer.char_name + " finds something to use as a bandage. They wonder how to use it..."
		event_handler.emit_signal("event_log_updated", successmsg)
		if diceroll2 + healer.ingenuity >= 20:
			var successmsg2 = healer.char_name + " is able to wrap up their wounds quite tightly! They recover a lot of health!!!"
			healer.adjust_health(10)
			event_handler.emit_signal("event_log_updated", successmsg2)
		elif diceroll2 + healer.ingenuity >= 15:
			var successmsg2 = healer.char_name + " is able to wrap up their wounds sloppily, recovering a little health!"
			healer.adjust_health(4)
			event_handler.emit_signal("event_log_updated", successmsg2)
		elif diceroll2 + healer.ingenuity < 15:
			var failmsg = healer.char_name + " wasn't able to use the supplies they found effectively."
			event_handler.emit_signal("event_log_updated", failmsg)
	else:
		var failmsg = healer.char_name + " seemingly couldn't find anything to heal with!"
		event_handler.emit_signal("event_log_updated", failmsg)
	
func attempt_to_manipulate(participants):
	if participants.size() < 3: return
	
	var manipulator = participants[0]
	var manipulated = participants[1]
	var victim = participants[2]
	
	var diceroll1 = rng.randi_range(1, 20)
	var diceroll2 = rng.randi_range(1, 20)
	
	if diceroll1 + manipulator.charisma > diceroll2 + manipulated.charisma:
		var fightmsg = manipulator.char_name + " successfully convinces " + manipulated.char_name + " to attack " + victim.char_name + "!!!"
		event_handler.emit_signal("event_log_updated", fightmsg)
		apply_fight([manipulated, victim])
	elif diceroll1 + manipulator.charisma < diceroll2 + manipulated.charisma:
		var fightmsg = manipulated.char_name + " sees through " + manipulator.char_name + "'s lies!"
		event_handler.emit_signal("event_log_updated", fightmsg)
		var diceroll3 = rng.randi_range(1, 20) 
		var diceroll4 = rng.randi_range(1, 20) 
		if diceroll3 + manipulated.form > diceroll4 + manipulator.charisma:
			var fightmsg2 = manipulator.char_name + " tries to convince " + manipulated.char_name + " to calm down, but they attack in retaliation!"
			event_handler.emit_signal("event_log_updated", fightmsg2)
			apply_fight([manipulated, manipulator])
		if diceroll3 + manipulated.form < diceroll4 + manipulator.charisma:
			var fightmsg2 = manipulator.char_name + " tries to convince " + manipulated.char_name + " to calm down, and they thankfully do."
			event_handler.emit_signal("event_log_updated", fightmsg2)

# ================================================================
# --- OPTIONAL: DEFINE EVENT CONDITION FUNCTIONS HERE ---
# These return true or false. They also receive the EventHandler.
# ================================================================

# Example condition function
# func check_can_attack(participants: Array[Character], event_handler) -> bool:
#     if participants.size() < 2: return false
#     var attacker = participants[0]
#     var defender = participants[1]
#     if not (is_instance_valid(attacker) and is_instance_valid(defender)): return false
#     # Check for proximity
#     if attacker.pos == defender.pos:
#         return true # Simple proximity check
#     else:
#         return false
#     return false # Default deny
