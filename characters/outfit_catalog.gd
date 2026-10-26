@tool
class_name OutfitCatalog
## Every outfit piece in the game, in one list.
##
## Each item goes in one SLOT and is made of PARTS. A part is a simple shape
## glued to one bone of the shared skeleton (see chibi.gd for the bone list).
## Because every item uses the same skeleton, any hat works with any hair,
## any top works with any bottom, and they all animate together.
##
## To add your own item: copy one of the entries below, give it a new id,
## and change the shapes and colours. It shows up in the wardrobe (C key).
##
## Part fields:
##   bone   which bone it follows: Hips, Chest, Head, Arm.L, Arm.R, Leg.L, Leg.R
##          ("Arm" or "Leg" means "make one for each side")
##   shape  box, sphere, hemisphere, capsule, cylinder, cone, prism, torus
##   size   width, height, depth
##   pos    position from the bone, rot = rotation in degrees
##   color  "dye" (the colour players can change), "accent", or a fixed Color
##   tag    optional label used by the hiding rules ("crown" = top of the hair)
##
## Item fields:
##   hides_crown  true for hats that cover the top of the hair
##   one_piece    true for dresses: the bottom slot is hidden
##   covers       body parts hidden under this item, e.g. ["feet"] for shoes

const SLOTS := ["hair", "head", "top", "bottom", "shoes", "back"]

const SLOT_NAMES := {
	"hair": "Hair",
	"head": "Head",
	"top": "Top",
	"bottom": "Bottom",
	"shoes": "Shoes",
	"back": "Back",
}

## Dye colours players can pick from (soft pastels, never neon).
const DYES: Array[Color] = [
	Color("#f4b6cb"), Color("#d86a9a"), Color("#e2384c"), Color("#f0955a"),
	Color("#f3d27a"), Color("#a8d58a"), Color("#6fb3a8"), Color("#6aa6d8"),
	Color("#4c8fd6"), Color("#8b5fb8"), Color("#b97a44"), Color("#6b3b22"),
	Color("#fbefcb"), Color("#f6f3f8"), Color("#42352b"),
]

const EYE_COLORS: Array[Color] = [
	Color("#5b8cd9"), Color("#3fa67a"), Color("#c0566b"), Color("#8b5fb8"),
	Color("#b8742a"), Color("#3fc7bd"),
]

## Where the middle of the head is, measured from the Head bone.
const HEAD := Vector3(0.0, 0.24, 0.0)

static var _items := {}


## All items, keyed by id. Built once, the first time it is needed.
static func items() -> Dictionary:
	if _items.is_empty():
		_items = _build()
	return _items


static func get_item(id: String) -> Dictionary:
	return items().get(id, {})


## Item ids for one slot, in wardrobe order. "none" (empty slot) comes first
## for slots that are allowed to be empty.
static func ids_for_slot(slot: String) -> Array[String]:
	var ids: Array[String] = []
	if slot != "hair" and slot != "top":
		ids.append("none")
	for id in items():
		if items()[id].slot == slot:
			ids.append(id)
	return ids


static func display_name(id: String) -> String:
	if id == "none" or id == "":
		return "(none)"
	return get_item(id).get("name", id)


static func _build() -> Dictionary:
	var all := {}
	var H := HEAD

	# ---------------- HAIR ----------------
	# Every hairstyle starts with a "crown" (a dome over the top and back of
	# the head) and bangs over the forehead. Hats can hide the crown.
	var crown := [
		{bone = "Head", shape = "hemisphere", size = Vector3(0.6, 0.6, 0.6), pos = H, rot = Vector3(-22, 0, 0), color = "dye", tag = "crown"},
	]
	var bangs := []
	for az: float in [-44.0, -16.0, 16.0, 44.0]:
		var el := 32.0
		var r := 0.27
		var p := H + Vector3(r * cos(deg_to_rad(el)) * sin(deg_to_rad(az)), r * sin(deg_to_rad(el)), r * cos(deg_to_rad(el)) * cos(deg_to_rad(az)))
		bangs.append({bone = "Head", shape = "sphere", size = Vector3(0.15, 0.19, 0.08), pos = p, rot = Vector3(-el, az, 0), color = "dye"})
	var side_locks := [
		{bone = "Head", shape = "sphere", size = Vector3(0.1, 0.32, 0.12), pos = H + Vector3(0.245, -0.08, 0.04), rot = Vector3(0, 0, 6), color = "dye"},
		{bone = "Head", shape = "sphere", size = Vector3(0.1, 0.32, 0.12), pos = H + Vector3(-0.245, -0.08, 0.04), rot = Vector3(0, 0, -6), color = "dye"},
	]

	all["hair_bob"] = {
		name = "Bob Cut", slot = "hair", dye = Color("#b97a44"),
		parts = crown + bangs + side_locks + [
			{bone = "Head", shape = "sphere", size = Vector3(0.58, 0.44, 0.42), pos = H + Vector3(0, -0.04, -0.1), color = "dye"},
			{bone = "Head", shape = "cone", size = Vector3(0.05, 0.14, 0.0), pos = H + Vector3(0.02, 0.33, -0.02), rot = Vector3(-30, 0, -25), color = "dye"},
		],
	}

	all["hair_twintails"] = {
		name = "Twin Tails", slot = "hair", dye = Color("#f4b6cb"), accent = Color("#e2384c"),
		parts = crown + bangs + side_locks + [
			{bone = "Head", shape = "sphere", size = Vector3(0.52, 0.36, 0.36), pos = H + Vector3(0, -0.02, -0.1), color = "dye"},
			{bone = "Head", shape = "sphere", size = Vector3(0.17, 0.46, 0.17), pos = H + Vector3(0.33, -0.16, -0.08), rot = Vector3(0, 0, 14), color = "dye"},
			{bone = "Head", shape = "sphere", size = Vector3(0.17, 0.46, 0.17), pos = H + Vector3(-0.33, -0.16, -0.08), rot = Vector3(0, 0, -14), color = "dye"},
			{bone = "Head", shape = "sphere", size = Vector3(0.09, 0.09, 0.09), pos = H + Vector3(0.28, 0.07, -0.07), color = "accent"},
			{bone = "Head", shape = "sphere", size = Vector3(0.09, 0.09, 0.09), pos = H + Vector3(-0.28, 0.07, -0.07), color = "accent"},
		],
	}

	var spikes := []
	for s in [[0.0, 0.3, -0.06, -20.0, 0.0], [0.15, 0.24, -0.1, -35.0, -30.0], [-0.15, 0.24, -0.1, -35.0, 30.0],
			[0.0, 0.18, -0.22, -70.0, 0.0], [0.18, 0.08, -0.18, -75.0, -40.0], [-0.18, 0.08, -0.18, -75.0, 40.0]]:
		spikes.append({bone = "Head", shape = "cone", size = Vector3(0.16, 0.24, 0.0), pos = H + Vector3(s[0], s[1], s[2]), rot = Vector3(s[3], 0, s[4]), color = "dye", tag = "crown"})
	all["hair_spiky"] = {
		name = "Spiky", slot = "hair", dye = Color("#42352b"),
		parts = crown + bangs + spikes + [
			{bone = "Head", shape = "sphere", size = Vector3(0.52, 0.34, 0.36), pos = H + Vector3(0, -0.02, -0.11), color = "dye"},
		],
	}

	all["hair_long"] = {
		name = "Long Straight", slot = "hair", dye = Color("#6aa6d8"),
		parts = crown + bangs + [
			{bone = "Head", shape = "sphere", size = Vector3(0.1, 0.52, 0.13), pos = H + Vector3(0.25, -0.17, 0.04), rot = Vector3(0, 0, 4), color = "dye"},
			{bone = "Head", shape = "sphere", size = Vector3(0.1, 0.52, 0.13), pos = H + Vector3(-0.25, -0.17, 0.04), rot = Vector3(0, 0, -4), color = "dye"},
			{bone = "Head", shape = "sphere", size = Vector3(0.58, 0.44, 0.42), pos = H + Vector3(0, -0.04, -0.1), color = "dye"},
			{bone = "Head", shape = "sphere", size = Vector3(0.48, 0.9, 0.18), pos = H + Vector3(0, -0.4, -0.2), rot = Vector3(8, 0, 0), color = "dye"},
		],
	}

	# ---------------- HEAD ----------------
	all["hat_witch"] = {
		name = "Witch Hat", slot = "head", dye = Color("#8b5fb8"), accent = Color("#f3d27a"), hides_crown = true,
		parts = [
			{bone = "Head", shape = "cylinder", size = Vector3(0.8, 0.03, 0.8), pos = H + Vector3(0, 0.15, -0.02), rot = Vector3(-8, 0, 0), color = "dye"},
			{bone = "Head", shape = "cone", size = Vector3(0.56, 0.52, 0.0), pos = H + Vector3(0, 0.41, -0.06), rot = Vector3(-14, 0, 6), color = "dye"},
			{bone = "Head", shape = "cylinder", size = Vector3(0.55, 0.06, 0.53), pos = H + Vector3(0, 0.2, -0.03), rot = Vector3(-8, 0, 0), color = "accent"},
			{bone = "Head", shape = "sphere", size = Vector3(0.07, 0.07, 0.07), pos = H + Vector3(0.03, 0.66, -0.12), color = "accent"},
		],
	}
	all["hat_beret"] = {
		name = "Beret", slot = "head", dye = Color("#e2384c"),
		parts = [
			{bone = "Head", shape = "sphere", size = Vector3(0.64, 0.18, 0.62), pos = H + Vector3(0.04, 0.27, -0.03), rot = Vector3(-6, 0, -12), color = "dye"},
			{bone = "Head", shape = "cylinder", size = Vector3(0.03, 0.06, 0.03), pos = H + Vector3(0.06, 0.37, -0.02), color = "dye"},
		],
	}
	all["acc_ribbon"] = {
		name = "Big Ribbon", slot = "head", dye = Color("#d86a9a"),
		parts = [
			{bone = "Head", shape = "sphere", size = Vector3(0.18, 0.13, 0.06), pos = H + Vector3(0.16, 0.24, 0.07), rot = Vector3(0, 40, 20), color = "dye"},
			{bone = "Head", shape = "sphere", size = Vector3(0.18, 0.13, 0.06), pos = H + Vector3(0.21, 0.26, -0.08), rot = Vector3(0, 40, -20), color = "dye"},
			{bone = "Head", shape = "sphere", size = Vector3(0.07, 0.07, 0.07), pos = H + Vector3(0.2, 0.25, 0.0), color = "dye"},
		],
	}
	all["acc_cat_ears"] = {
		name = "Cat Ears", slot = "head", dye = Color("#f0955a"), accent = Color("#f4b6cb"),
		parts = [
			{bone = "Head", shape = "cone", size = Vector3(0.15, 0.17, 0.0), pos = H + Vector3(0.15, 0.27, -0.03), rot = Vector3(-8, 0, -24), color = "dye"},
			{bone = "Head", shape = "cone", size = Vector3(0.15, 0.17, 0.0), pos = H + Vector3(-0.15, 0.27, -0.03), rot = Vector3(-8, 0, 24), color = "dye"},
			{bone = "Head", shape = "cone", size = Vector3(0.08, 0.1, 0.0), pos = H + Vector3(0.155, 0.27, 0.015), rot = Vector3(-8, 0, -24), color = "accent"},
			{bone = "Head", shape = "cone", size = Vector3(0.08, 0.1, 0.0), pos = H + Vector3(-0.155, 0.27, 0.015), rot = Vector3(-8, 0, 24), color = "accent"},
		],
	}
	var flowers := [{bone = "Head", shape = "torus", size = Vector3(0.6, 0.04, 0.6), pos = H + Vector3(0, 0.2, -0.02), rot = Vector3(-14, 0, 0), color = Color("#6fb3a8")}]
	var flower_colors := [Color("#fbefcb"), Color("#f4b6cb"), Color("#f3d27a"), Color("#f4b6cb"), Color("#fbefcb")]
	for i in 5:
		var a := deg_to_rad(-70.0 + i * 35.0)
		flowers.append({bone = "Head", shape = "sphere", size = Vector3(0.09, 0.07, 0.09), pos = H + Vector3(0.3 * sin(a), 0.22 + 0.06 * cos(a), 0.3 * cos(a) - 0.04), color = flower_colors[i]})
	all["acc_flower_crown"] = {name = "Flower Crown", slot = "head", dye = Color("#6fb3a8"), parts = flowers}

	# ---------------- TOPS ----------------
	all["top_tunic"] = {
		name = "Traveler Tunic", slot = "top", dye = Color("#6aa6d8"), accent = Color("#fbefcb"),
		parts = [
			{bone = "Chest", shape = "sphere", size = Vector3(0.34, 0.31, 0.25), pos = Vector3(0, 0.07, 0), color = "dye"},
			{bone = "Chest", shape = "cylinder", size = Vector3(0.37, 0.13, 0.31), pos = Vector3(0, -0.07, 0), color = "dye"},
			{bone = "Chest", shape = "torus", size = Vector3(0.2, 0.035, 0.2), pos = Vector3(0, 0.19, 0.0), color = "accent"},
			{bone = "Arm", shape = "capsule", size = Vector3(0.12, 0.19, 0.12), pos = Vector3(0, -0.06, 0), color = "dye"},
		],
	}
	all["top_apron_dress"] = {
		name = "Cafe Apron Dress", slot = "top", dye = Color("#d86a9a"), accent = Color("#ffffff"), one_piece = true,
		parts = [
			{bone = "Chest", shape = "sphere", size = Vector3(0.34, 0.31, 0.25), pos = Vector3(0, 0.07, 0), color = "dye"},
			{bone = "Hips", shape = "cylinder", size = Vector3(0.54, 0.3, 0.3), pos = Vector3(0, -0.06, 0), color = "dye"},
			{bone = "Hips", shape = "box", size = Vector3(0.26, 0.26, 0.02), pos = Vector3(0, -0.06, 0.19), rot = Vector3(-18, 0, 0), color = "accent"},
			{bone = "Chest", shape = "box", size = Vector3(0.16, 0.13, 0.02), pos = Vector3(0, 0.05, 0.125), color = "accent"},
			{bone = "Chest", shape = "torus", size = Vector3(0.18, 0.035, 0.18), pos = Vector3(0, 0.19, 0.0), color = "accent"},
			{bone = "Arm", shape = "sphere", size = Vector3(0.15, 0.13, 0.15), pos = Vector3(0, -0.03, 0), color = "dye"},
		],
	}
	all["top_coat"] = {
		name = "Scholar Coat", slot = "top", dye = Color("#3e9b5a"), accent = Color("#e3b34e"),
		parts = [
			{bone = "Chest", shape = "sphere", size = Vector3(0.35, 0.32, 0.26), pos = Vector3(0, 0.07, 0), color = "dye"},
			{bone = "Hips", shape = "cylinder", size = Vector3(0.44, 0.3, 0.33), pos = Vector3(0, -0.07, 0), color = "dye"},
			{bone = "Chest", shape = "cylinder", size = Vector3(0.24, 0.06, 0.18), pos = Vector3(0, 0.2, 0), color = "dye"},
			{bone = "Arm", shape = "capsule", size = Vector3(0.115, 0.3, 0.115), pos = Vector3(0, -0.13, 0), color = "dye"},
			{bone = "Chest", shape = "sphere", size = Vector3(0.035, 0.035, 0.035), pos = Vector3(0, 0.1, 0.13), color = "accent"},
			{bone = "Chest", shape = "sphere", size = Vector3(0.035, 0.035, 0.035), pos = Vector3(0, 0.02, 0.135), color = "accent"},
			{bone = "Chest", shape = "sphere", size = Vector3(0.035, 0.035, 0.035), pos = Vector3(0, -0.06, 0.13), color = "accent"},
		],
	}
	all["top_hoodie"] = {
		name = "Cozy Hoodie", slot = "top", dye = Color("#f3d27a"), accent = Color("#fbefcb"),
		parts = [
			{bone = "Chest", shape = "sphere", size = Vector3(0.36, 0.33, 0.27), pos = Vector3(0, 0.06, 0), color = "dye"},
			{bone = "Chest", shape = "cylinder", size = Vector3(0.38, 0.1, 0.33), pos = Vector3(0, -0.07, 0), color = "dye"},
			{bone = "Chest", shape = "sphere", size = Vector3(0.3, 0.14, 0.18), pos = Vector3(0, 0.2, -0.08), color = "dye"},
			{bone = "Chest", shape = "box", size = Vector3(0.18, 0.08, 0.03), pos = Vector3(0, -0.02, 0.13), color = "accent"},
			{bone = "Arm", shape = "capsule", size = Vector3(0.125, 0.3, 0.125), pos = Vector3(0, -0.13, 0), color = "dye"},
		],
	}

	# ---------------- BOTTOMS ----------------
	all["bottom_shorts"] = {
		name = "Shorts", slot = "bottom", dye = Color("#7e4a20"),
		parts = [
			{bone = "Hips", shape = "sphere", size = Vector3(0.3, 0.2, 0.22), pos = Vector3(0, 0.02, 0), color = "dye"},
			{bone = "Leg", shape = "capsule", size = Vector3(0.12, 0.15, 0.12), pos = Vector3(0, -0.06, 0), color = "dye"},
		],
	}
	all["bottom_skirt"] = {
		name = "Pleated Skirt", slot = "bottom", dye = Color("#4c8fd6"),
		parts = [
			{bone = "Hips", shape = "sphere", size = Vector3(0.29, 0.19, 0.21), pos = Vector3(0, 0.03, 0), color = "dye"},
			{bone = "Hips", shape = "cylinder", size = Vector3(0.46, 0.2, 0.29), pos = Vector3(0, -0.03, 0), color = "dye", segments = 10},
		],
	}
	all["bottom_pants"] = {
		name = "Long Pants", slot = "bottom", dye = Color("#42352b"),
		parts = [
			{bone = "Hips", shape = "sphere", size = Vector3(0.3, 0.2, 0.22), pos = Vector3(0, 0.02, 0), color = "dye"},
			{bone = "Leg", shape = "capsule", size = Vector3(0.115, 0.34, 0.115), pos = Vector3(0, -0.16, 0), color = "dye"},
		],
	}

	# ---------------- SHOES ----------------
	all["shoes_boots"] = {
		name = "Walking Boots", slot = "shoes", dye = Color("#b97a44"), accent = Color("#7e4a20"), covers = ["feet"],
		parts = [
			{bone = "Leg", shape = "sphere", size = Vector3(0.14, 0.1, 0.21), pos = Vector3(0, -0.37, 0.03), color = "dye"},
			{bone = "Leg", shape = "cylinder", size = Vector3(0.13, 0.13, 0.13), pos = Vector3(0, -0.29, 0), color = "dye"},
			{bone = "Leg", shape = "torus", size = Vector3(0.14, 0.025, 0.14), pos = Vector3(0, -0.23, 0), color = "accent"},
		],
	}
	all["shoes_slippers"] = {
		name = "Bunny Slippers", slot = "shoes", dye = Color("#f6f3f8"), accent = Color("#f4b6cb"), covers = ["feet"],
		parts = [
			{bone = "Leg", shape = "sphere", size = Vector3(0.15, 0.09, 0.22), pos = Vector3(0, -0.375, 0.03), color = "dye"},
			{bone = "Leg", shape = "sphere", size = Vector3(0.035, 0.09, 0.02), pos = Vector3(0.03, -0.32, 0.08), rot = Vector3(-20, 0, -15), color = "accent"},
			{bone = "Leg", shape = "sphere", size = Vector3(0.035, 0.09, 0.02), pos = Vector3(-0.03, -0.32, 0.08), rot = Vector3(-20, 0, 15), color = "accent"},
		],
	}

	# ---------------- BACK ----------------
	# Wings flap: parts with "flap" swing around their "pivot".
	var wings := []
	for side: float in [1.0, -1.0]:
		for i in 3:
			var angle := side * (38.0 + i * 24.0)
			var length := 0.36 - i * 0.06
			var dir := Vector3(sin(deg_to_rad(angle)), cos(deg_to_rad(angle)), 0.0)
			wings.append({bone = "Chest", pivot = Vector3(side * 0.06, 0.1, -0.13), flap = side,
				shape = "sphere", size = Vector3(0.1, length, 0.035), pos = dir * length * 0.5, rot = Vector3(0, 0, -angle), color = "dye"})
	all["back_wings"] = {name = "Feather Wings", slot = "back", dye = Color("#f6f3f8"), parts = wings}
	all["back_cape"] = {
		name = "Adventurer Cape", slot = "back", dye = Color("#e2384c"), accent = Color("#e3b34e"),
		parts = [
			{bone = "Chest", shape = "box", size = Vector3(0.38, 0.52, 0.03), pos = Vector3(0, -0.07, -0.145), rot = Vector3(10, 0, 0), color = "dye"},
			{bone = "Chest", shape = "sphere", size = Vector3(0.05, 0.05, 0.05), pos = Vector3(0.1, 0.17, 0.09), color = "accent"},
			{bone = "Chest", shape = "sphere", size = Vector3(0.05, 0.05, 0.05), pos = Vector3(-0.1, 0.17, 0.09), color = "accent"},
		],
	}
	all["back_backpack"] = {
		name = "Satchel Pack", slot = "back", dye = Color("#b97a44"), accent = Color("#7e4a20"),
		parts = [
			{bone = "Chest", shape = "box", size = Vector3(0.25, 0.25, 0.13), pos = Vector3(0, 0.03, -0.18), color = "dye"},
			{bone = "Chest", shape = "box", size = Vector3(0.26, 0.1, 0.14), pos = Vector3(0, 0.13, -0.18), rot = Vector3(-8, 0, 0), color = "accent"},
			{bone = "Chest", shape = "sphere", size = Vector3(0.04, 0.04, 0.04), pos = Vector3(0, 0.08, -0.105), color = Color("#e3b34e")},
		],
	}
	return all
