require("AFUtils.AFUtils")

local Key = Key
local Constants = require("Scripts.DHUD.Config")
local HUD = require("DHUD.HUD")
local Player = require("DHUD.Player")
local Enemies = require("DHUD.Enemies")

require("DHUD.Diagnostics").Register(Key, Player, HUD, Enemies, Constants)
require("DHUD.Visibility").Start(Key, Constants, HUD, Player, Enemies)
