AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- Shared, dependency-free bootstrap for WoW WotLK 3.3.5a / Lua 5.1.
-- Feature modules must not place implementation code in this file.
addon.Name = addon.Name or "AzerothAdmin"
addon.InterfaceVersion = addon.InterfaceVersion or 30300
addon.ClientBuild = addon.ClientBuild or 12340
addon.FrameworkVersion = addon.FrameworkVersion or "1.0.0"
addon.ModuleRegistry = addon.ModuleRegistry or {}
addon.ModuleOrder = addon.ModuleOrder or {}
addon.LocalePacks = addon.LocalePacks or {}
addon.L = addon.L or {}
