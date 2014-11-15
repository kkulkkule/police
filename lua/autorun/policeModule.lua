if SERVER then
	AddCSLuaFile("police/cl_init.lua")
	AddCSLuaFile("police/shared.lua")
	include("police/init.lua")
end

if CLIENT then
	include("police/cl_init.lua")
end