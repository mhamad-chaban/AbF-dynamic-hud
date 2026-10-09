require("AFUtils.AFUtils")

local Key = Key
local Config = require("DHUD.Config")
local HUD = require("DHUD.HUD")
local Player = require("DHUD.Player")
local Enemies = require("DHUD.Enemies")

require("DHUD.Diagnostics").Register(Key, Player, HUD, Enemies, Config)
require("DHUD.Visibility").Start(Key, Config, HUD, Player, Enemies)
