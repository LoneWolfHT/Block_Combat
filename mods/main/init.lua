main = {
	modes = {},
	playing = {},
	mode_interval = 60 * 10,
	default_drops = {
		default = "shooter_guns:ammo",
		["combat:medkit"] = 20,
		["shooter_guns:rifle_loaded"] = 36,
		["shooter_guns:machine_gun_loaded"] = 60,
		["shooter_guns:shotgun_loaded"] = 60,
		["combat:sword"] = 60,
	},
	default_starter_items = {"combat:knife", "shooter_guns:pistol_loaded", "shooter_guns:ammo 2"},
	default_drop_interval = 20
}

function main.register_mode(name, def)
	main.modes[name] = def
end

function main.start_mode(name)
	main.current_mode = {
		name = name,
		mode = main.modes[name],
	}

	local map = maps.get_rand_map()

	if not map then
		minetest.log("error", "No maps to play on! Create one with /maps new")
		return
	end

	minetest.clear_objects("quick")

	local mapdef = maps.load_map(map)
	main.current_mode.map = mapdef
	main.current_mode.itemspawns = mapdef.itemspawns
	main.current_mode.playerspawns = mapdef.playerspawns

	for _, p in ipairs(minetest.get_connected_players()) do
		if main.playing[p:get_player_name()] then
			main.join_player(p)
		end
	end

	minetest.chat_send_all(minetest.colorize("yellow", "[Voxel Combat] ")..
	"Current mode: "..main.modes[name].full_name..". Current map (By "..mapdef.creator.."): "..mapdef.name)

	main.sethud_all("Current mode: "..main.modes[name].full_name..". Current map: "..mapdef.name, 7)
end

function main.join_player(player)
	local inv = player:get_inventory()
	local name = player:get_player_name()

	main.give_starter_items(inv)

	skybox.set(player, main.get_sky(main.current_mode.map.skybox))
	local one, two, three = player:get_sky()
	player:set_sky(one, two, three, false)

	player:set_pos(main.current_mode.playerspawns[math.random(1, #main.current_mode.playerspawns)])

	main.sethud_player(name,
		"Current mode: "..main.current_mode.mode.full_name..
		". Current map: "..main.current_mode.map.name,
	7)

	minetest.chat_send_player(name,
		minetest.colorize("yellow", "[Voxel Combat] ")..
		"Current mode: "..main.current_mode.mode.full_name..
		". Current map (By "..main.current_mode.map.creator..
		"): "..main.current_mode.map.name
	)

	main.playing[name] = true
end

--
--- Player join/leave/die/damage
--

minetest.register_on_joinplayer(function(p)
	p:set_hp(20, {type = "set_hp"})

	if #minetest.get_connected_players() == 1 then
		main.start_mode("default")
	else
		main.join_player(p)
	end

	skybox.set(p, 6)
	local one, two, three = p:get_sky()
	p:set_sky(one, two, three, false)
end)

minetest.register_on_respawnplayer(function(p)
	p:set_pos(main.current_mode.playerspawns[math.random(1, #main.current_mode.playerspawns)])

	return true
end)

minetest.register_on_player_hpchange(function(_, hp_change, reason)
	if reason.type == "fall" then
		return 0
	else
		return hp_change
	end
end, true)

--
--- Misc
--

function minetest.item_drop() -- Dropping items
	return
end

minetest.set_mapgen_setting("mg_name", "singlenode", true) -- Set mapgen to singlenode

local dirs = minetest.get_dir_list(minetest.get_modpath("main"), false) -- Include all .lua files

for _, filename in ipairs(dirs) do
	if filename:find(".lua") and filename ~= "init.lua" then
		dofile(minetest.get_modpath("main").."/"..filename)
	end
end
