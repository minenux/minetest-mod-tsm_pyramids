local S = tsm_pyramids.S

local img = {
	"eye", "men", "sun",
	"ankh", "scarab", "cactus"
}
local desc = {
	S("Sandstone with Eye Engraving"), S("Sandstone with Human Engraving"), S("Sandstone with Sun Engraving"),
	S("Desert Sandstone with Ankh Engraving"), S("Desert Sandstone with Scarab Engraving"), S("Desert Sandstone with Cactus Engraving")
}

local decodesc = ""
if minetest.get_modpath("doc_items") then
	decodesc = doc.sub.items.temp.deco
end

for i=1, #img do
	local sandstone_img, basenode
	if i > 3 then
		sandstone_img = "default_desert_sandstone.png"
		basenode = "default:desert_sandstone"
	else
		sandstone_img = "default_sandstone.png"
		basenode = "default:sandstone"
	end
	minetest.register_node("tsm_pyramids:deco_stone"..i, {
		description = desc[i],
		_doc_items_longdesc = decodesc,
		is_ground_content = false,
		tiles = {sandstone_img, sandstone_img, sandstone_img.."^tsm_pyramids_"..img[i]..".png"},
		groups = minetest.registered_nodes[basenode].groups,
		sounds = minetest.registered_nodes[basenode].sounds,
	})
end

local trap_on_timer = function(pos, elapsed)
	local n = minetest.get_node(pos)
	if not (n and n.name) then
		return true
	end
	-- Drop trap stone when player is nearby
	local objs = minetest.get_objects_inside_radius(pos, 2)
	for i, obj in pairs(objs) do
		if obj:is_player() then
			if minetest.registered_nodes[n.name]._tsm_pyramids_crack and minetest.registered_nodes[n.name]._tsm_pyramids_crack < 2 then
				-- 70% chance to ignore player to make the time of falling less predictable
				if math.random(1, 10) >= 3 then
					return true
				end
				if n.name == "tsm_pyramids:trap" then
					minetest.set_node(pos, {name="tsm_pyramids:trap_2"})
					if minetest.check_for_falling ~= nil then minetest.check_for_falling(pos) else nodeupdate(pos) end
				elseif n.name == "tsm_pyramids:desert_trap" then
					minetest.set_node(pos, {name="tsm_pyramids:desert_trap_2"})
					if minetest.check_for_falling ~= nil then minetest.check_for_falling(pos) else nodeupdate(pos) end
				end
				return true
			end
		end
	end
	return true
end

local register_trap_stone = function(basename, desc_normal, desc_falling, base_tile, drop)
	minetest.register_node("tsm_pyramids:"..basename, {
		description = desc_normal,
		_doc_items_longdesc = S("This brick is old, porous and unstable and is barely able to hold itself. One should be careful not to disturb it."),
		tiles = { base_tile .. "^tsm_pyramids_crack.png" },
		is_ground_content = false,
		groups = {crumbly=3,cracky=3},
		sounds = default.node_sound_stone_defaults(),
		on_construct = function(pos)
			minetest.get_node_timer(pos):start(0.1)
		end,
		_tsm_pyramids_crack = 1,
		on_timer = trap_on_timer,
		drop = drop,
	})

	minetest.register_node("tsm_pyramids:"..basename.."_2", {
		description = desc_falling,
		_doc_items_longdesc = S("This old porous brick falls under its own weight."),
		tiles = { base_tile .. "^tsm_pyramids_crack2.png" },
		is_ground_content = false,
		groups = {crumbly=3,cracky=3,falling_node=1,not_in_creative_inventory=1},
		sounds = default.node_sound_stone_defaults(),
		drop = drop,
	})
end

register_trap_stone("trap",
	S("Cracked Sandstone Brick"), S("Falling Cracked Sandstone Brick"),
	"default_sandstone_brick.png",
	{ items = { { items = { "default:sand" }, rarity = 1 }, { items = { "default:sand" }, rarity = 2 }, } })
register_trap_stone("desert_trap",
	S("Cracked Desert Sandstone Brick"), S("Falling Cracked Desert Sandstone Brick"),
	"default_desert_sandstone_brick.png",
	{ items = { { items = { "default:desert_sand" }, rarity = 1 }, { items = { "default:desert_sand" }, rarity = 2 }, } })

local chest = minetest.registered_nodes["default:chest"]
local def_on_rightclick = chest.on_rightclick
local def_on_timer = chest.on_timer
minetest.override_item(
	"default:chest",
	{
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if minetest.get_meta(pos):get_string("tsm_pyramids:stype") ~= "" then
				local timer = minetest.get_node_timer(pos)
				if not timer:is_started() then
					timer:start(1800) -- remplissages des coffres toutes les 30 minutes
				end
			end
			return def_on_rightclick(pos, node, clicker, itemstack, pointed_thing)
		end,
		on_timer = function(pos, elapsed)
			if minetest.get_meta(pos):get_string("tsm_pyramids:stype") ~= "" then
				minetest.log("action", "[DEBUG] chest refilling")
				tsm_pyramids.fill_chest(pos)
				return false
			else
				if def_on_timer then return def_on_timer(pos, elapsed) else return false end
			end
		end,
})

minetest.register_alias("tsm_pyramids:chest", "default:chest")
