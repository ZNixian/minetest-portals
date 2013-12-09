-- Minetest 0.4 Mod: portals

-- Based off nether mod by PilzAdam

local types = {
	{name = "teleport",																			particle = "portals_particle.png",},
	{name = "nether",	depth = -5000,	up = {0,		20},		down = {-500,	-1500},		particle = "portals_nether.png",},
	{name = "nyanland",	depth = 30680,	up = {30688,	30688},		down = {0,		20},		particle = "default_nc_front.png",},
}



local get_type_by_name = function(name)
	for i=1, #types do
		if types[i].name==name then
			return types[i]
		end
	end
	return nil
end

minetest.register_node("portals:portal", {
	description = "portals Portal",
	tiles = {
		"portals_transparent.png",
		"portals_transparent.png",
		"portals_transparent.png",
		"portals_transparent.png",
		{
			name = "portals_portal.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.5,
			},
		},
		{
			name = "portals_portal.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.5,
			},
		},
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	use_texture_alpha = true,
	walkable = false,
	digable = false,
	pointable = false,
	buildable_to = false,
	drop = "",
	light_source = 5,
	post_effect_color = {a=180, r=128, g=0, b=128},
	alpha = 192,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.1,  0.5, 0.5, 0.1},
		},
	},
	groups = {not_in_creative_inventory=1}
})

local function build_portal(pos, target, type)
	local p = {x=pos.x-1, y=pos.y-1, z=pos.z}
	local p1 = {x=pos.x-1, y=pos.y-1, z=pos.z}
	local p2 = {x=p1.x+3, y=p1.y+4, z=p1.z}
	for i=1,4 do
		minetest.env:set_node(p, {name="default:obsidian"})
		p.y = p.y+1
	end
	for i=1,3 do
		minetest.env:set_node(p, {name="default:obsidian"})
		p.x = p.x+1
	end
	for i=1,4 do
		minetest.env:set_node(p, {name="default:obsidian"})
		p.y = p.y-1
	end
	for i=1,3 do
		minetest.env:set_node(p, {name="default:obsidian"})
		p.x = p.x-1
	end
	for x=p1.x,p2.x do
	for y=p1.y,p2.y do
		p = {x=x, y=y, z=p1.z}
		if not (x == p1.x or x == p2.x or y==p1.y or y==p2.y) then
			minetest.env:set_node(p, {name="portals:portal", param2=0})
		end
		local meta = minetest.env:get_meta(p)
		meta:set_string("p1", minetest.pos_to_string(p1))
		meta:set_string("p2", minetest.pos_to_string(p2))
		meta:set_string("target", minetest.pos_to_string(target))
		meta:set_string("type", type)
		
		if y ~= p1.y then
			for z=-2,2 do
				if z ~= 0 then
					p.z = p.z+z
					if minetest.registered_nodes[minetest.env:get_node(p).name].is_ground_content then
						minetest.env:remove_node(p)
					end
					p.z = p.z-z
				end
			end
		end
		
	end
	end
end

minetest.register_abm({
	nodenames = {"portals:portal"},
	interval = 1,
	chance = 2,
	action = function(pos, node)
		local particle_name = ""
		local portal_type = get_type_by_name(minetest.get_meta(pos):get_string("type"))
		if portal_type~=nil then
			if portal_type.particle~=nil then
				particle_name = portal_type.particle
			end
		end
		minetest.add_particlespawner(
			32, --amount
			4, --time
			{x=pos.x-0.25, y=pos.y-0.25, z=pos.z-0.25}, --minpos
			{x=pos.x+0.25, y=pos.y+0.25, z=pos.z+0.25}, --maxpos
			{x=-0.8, y=-0.8, z=-0.8}, --minvel
			{x=0.8, y=0.8, z=0.8}, --maxvel
			{x=0,y=0,z=0}, --minacc
			{x=0,y=0,z=0}, --maxacc
			0.5, --minexptime
			1, --maxexptime
			1, --minsize
			2, --maxsize
			false, --collisiondetection
			particle_name --texture
		)
		for _,obj in ipairs(minetest.env:get_objects_inside_radius(pos, 1)) do
			if obj:is_player() then
				local meta = minetest.env:get_meta(pos)
				local target = minetest.string_to_pos(meta:get_string("target"))
				local type = meta:get_string("type")
				if target then
					minetest.after(3, function(obj, pos, target, type)
						local objpos = obj:getpos()
						if objpos~=nil then -- If the client disconnects
							objpos.y = objpos.y+0.1 -- Fix some glitches at -8000
							if minetest.env:get_node(objpos).name ~= "portals:portal" then
								return
							end
							
							obj:setpos(target)
							
							local function check_and_build_portal(pos, target, type)
								local n = minetest.env:get_node_or_nil(target)
								if n and n.name ~= "portals:portal" then
									build_portal(target, pos, type)
									minetest.after(2, check_and_build_portal, pos, target, type)
									minetest.after(4, check_and_build_portal, pos, target, type)
								elseif not n then
									minetest.after(1, check_and_build_portal, pos, target, type)
								end
							end
							
							minetest.after(1, check_and_build_portal, pos, target, type)
						end
						
					end, obj, pos, target, type)
				end
			end
		end
	end,
})

local function move_check(p1, max, dir)
	local p = {x=p1.x, y=p1.y, z=p1.z}
	local d = math.abs(max-p1[dir]) / (max-p1[dir])
	while p[dir] ~= max do
		p[dir] = p[dir] + d
		if minetest.env:get_node(p).name ~= "default:obsidian" then
			return false
		end
	end
	return true
end

local function check_portal(p1, p2)
	if p1.x ~= p2.x then
		if not move_check(p1, p2.x, "x") then
			return false
		end
		if not move_check(p2, p1.x, "x") then
			return false
		end
	elseif p1.z ~= p2.z then
		if not move_check(p1, p2.z, "z") then
			return false
		end
		if not move_check(p2, p1.z, "z") then
			return false
		end
	else
		return false
	end
	
	if not move_check(p1, p2.y, "y") then
		return false
	end
	if not move_check(p2, p1.y, "y") then
		return false
	end
	
	return true
end

local function is_portal(pos)
	for d=-3,3 do
		for y=-4,4 do
			local px = {x=pos.x+d, y=pos.y+y, z=pos.z}
			local pz = {x=pos.x, y=pos.y+y, z=pos.z+d}
			if check_portal(px, {x=px.x+3, y=px.y+4, z=px.z}) then
				return px, {x=px.x+3, y=px.y+4, z=px.z}
			end
			if check_portal(pz, {x=pz.x, y=pz.y+4, z=pz.z+3}) then
				return pz, {x=pz.x, y=pz.y+4, z=pz.z+3}
			end
		end
	end
end

local function make_portal(pos, target, type)
	local p1, p2 = is_portal(pos)
	if not p1 or not p2 then
		return false
	end
	
	for d=1,2 do
	for y=p1.y+1,p2.y-1 do
		local p
		if p1.z == p2.z then
			p = {x=p1.x+d, y=y, z=p1.z}
		else
			p = {x=p1.x, y=y, z=p1.z+d}
		end
		if minetest.env:get_node(p).name ~= "air" then
			return false
		end
	end
	end
	
	local param2
	if p1.z == p2.z then param2 = 0 else param2 = 1 end
	
	for d=0,3 do
	for y=p1.y,p2.y do
		local p = {}
		if param2 == 0 then p = {x=p1.x+d, y=y, z=p1.z} else p = {x=p1.x, y=y, z=p1.z+d} end
		if minetest.env:get_node(p).name == "air" then
			minetest.env:set_node(p, {name="portals:portal", param2=param2})
		end
		local meta = minetest.env:get_meta(p)
		meta:set_string("p1", minetest.pos_to_string(p1))
		meta:set_string("p2", minetest.pos_to_string(p2))
		meta:set_string("target", minetest.pos_to_string(target))
		meta:set_string("type", type)
	end
	end
	return true
end

minetest.register_node(":default:obsidian", {
	description = "Obsidian",
	tiles = {"default_obsidian.png"},
	is_ground_content = true,
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky=1,level=2},
	
	on_destruct = function(pos)
		local meta = minetest.env:get_meta(pos)
		local p1 = minetest.string_to_pos(meta:get_string("p1"))
		local p2 = minetest.string_to_pos(meta:get_string("p2"))
		local target = minetest.string_to_pos(meta:get_string("target"))
		if not p1 or not p2 then
			return
		end
		for x=p1.x,p2.x do
		for y=p1.y,p2.y do
		for z=p1.z,p2.z do
			local nn = minetest.env:get_node({x=x,y=y,z=z}).name
			if nn == "default:obsidian" or nn == "portals:portal" then
				if nn == "portals:portal" then
					minetest.env:remove_node({x=x,y=y,z=z})
				end
				local m = minetest.env:get_meta({x=x,y=y,z=z})
				m:set_string("p1", "")
				m:set_string("p2", "")
				m:set_string("target", "")
			end
		end
		end
		end
		meta = minetest.env:get_meta(target)
		if not meta then
			return
		end
		p1 = minetest.string_to_pos(meta:get_string("p1"))
		p2 = minetest.string_to_pos(meta:get_string("p2"))
		if not p1 or not p2 then
			return
		end
		for x=p1.x,p2.x do
		for y=p1.y,p2.y do
		for z=p1.z,p2.z do
			local nn = minetest.env:get_node({x=x,y=y,z=z}).name
			if nn == "default:obsidian" or nn == "portals:portal" then
				if nn == "portals:portal" then
					minetest.env:remove_node({x=x,y=y,z=z})
				end
				local m = minetest.env:get_meta({x=x,y=y,z=z})
				m:set_string("p1", "")
				m:set_string("p2", "")
				m:set_string("target", "")
			end
		end
		end
		end
	end,
})

for i=1, #types do
	minetest.register_craftitem("portals:activator_"..types[i].name, {
		description = "Mese Activator "..types[i].name,
		inventory_image = "default_mese_crystal_fragment.png^[lowpart:50:default_obsidian_shard.png", --"default_mese_crystal_fragment.png",
		stack_max = 1,
		on_place = function(stack,_, pt)
			if pt.under then
				local theitemtable = stack:to_table()
				if types[i].depth~=nil then
					local p1, p2 = is_portal(pt.under)
					if not p1 or not p2 then
						return
					end
					local target = {x=p1.x, y=p1.y, z=p1.z}
					target.x = target.x + 1
					if target.y < types[i].depth then
						target.y = math.random(types[i].up[1], types[i].up[2])
					else
						target.y = types[i].depth - math.random(types[i].down[1], types[i].down[2])
					end
					theitemtable.metadata = minetest.pos_to_string(target)
					stack = ItemStack(theitemtable)
				end
				if theitemtable.metadata==nil or theitemtable.metadata=="" then
					theitemtable.metadata = minetest.pos_to_string(pt.under)
					stack = ItemStack(theitemtable)
				elseif minetest.env:get_node(pt.under).name == "default:obsidian" then
					local portalpos = minetest.string_to_pos(theitemtable.metadata)
					portalpos.y = portalpos.y + 2
					local done = make_portal(pt.under, portalpos, types[i].name)
					if done then
						stack:take_item()
					end
				end
			end
			return stack
		end,
	})
end
