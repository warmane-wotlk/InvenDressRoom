local MAJOR_VERSION, MINOR_VERSION = "LibBlueItemCacheReceiver-1.0", 1
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

local _G = _G
local type = _G.type
local next = _G.next
local pairs = _G.pairs
local tonumber = _G.tonumber
local GetItemInfo = _G.GetItemInfo
local GetItemIcon = _G.GetItemIcon

function lib:GetItemID(item)
	if type(item) == "string" then
		return tonumber(item:match("item:(%d+)") or "")
	elseif type(item) == "number" then
		return item
	else
		return nil
	end
end

local function itemCacheReceived(item)
	lib.itemIds[item], lib.noItem[item] = nil
	for handler, items in pairs(lib.handler) do
		if items[item] then
			items[item] = nil
			handler(item)
		end
	end
	if not next(lib.itemIds) then
		lib.frames:Hide()
	end
end

function lib:RegisterItemCache(item, handler)
	item = lib:GetItemID(item)
	if item and type(handler) == "function" and GetItemIcon(item) then
		if GetItemInfo(item) then
			if not lib.handler[handler] or not lib.handler[handler][item] then
				handler(item)
			end
			itemCacheReceived(item)
			return true
		elseif not lib.noItem[item] then
			lib.handler[handler] = lib.handler[handler] or {}
			lib.handler[handler][item] = true
			lib.itemIds[item] = lib.itemIds[item] or 25
			if not lib.frames.registered then
				lib.frames.registered = true
				lib.frames:RegisterEvent("GET_ITEM_INFO_RECEIVED")
				lib.frames:RegisterEvent("EJ_LOOT_DATA_RECIEVED")
				lib.frames:RegisterEvent("PLAYER_ENTERING_WORLD")
			end
		end
	end
	return nil
end

function lib:UnregisterItemCache(item, handler)
	if lib.handler[handler] then
		item = lib:GetItemID(item)
		if lib.handler[handler][item] then
			lib.handler[handler][item] = nil
			for _, items in pairs(lib.handler) do
				if items[item] then
					return
				end
			end
			lib.itemIds[item] = nil
			if not next(lib.itemIds) then
				lib.frames:Hide()
			end
		end
	end
end

function lib:UnregisterAllItemCache(handler)
	if lib.handler[handler] then
		for item in pairs(lib.handler[handler]) do
			lib.handler[handler][item] = nil
			for _, items in pairs(lib.handler) do
				if items[item] then
					item = nil
					break
				end
			end
			if item then
				lib.itemIds[item] = nil
				if not next(lib.itemIds) then
					lib.frames:Hide()
				end
			end
		end
	end
end

function lib:GetItemStackNum()
	return #lib.itemIds
end

lib.itemIds = lib.itemIds or {}
lib.noItem = lib.noItem or {}
lib.handler = lib.handler or {}
lib.frames = lib.frames or CreateFrame("Frame")
lib.frames.timer = 0
lib.frames:Hide()
lib.frames:UnregisterAllEvents()

lib.frames:SetScript("OnHide", function(self)
	self.registered = nil
	self:UnregisterAllEvents()
end)

lib.frames:SetScript("OnEvent", function(self)
	if next(lib.itemIds) then
		self:Show()
	else
		self:Hide()
	end
end)

lib.frames:SetScript("OnUpdate", function(self, timer)
	self.timer = self.timer + timer
	if self.timer > 0.2 then
		self.timer = 0
		for item in pairs(lib.itemIds) do
			if GetItemInfo(item) then
				itemCacheReceived(item)
			else
				lib.itemIds[item] = lib.itemIds[item] - 1
				if lib.itemIds[item] < 0 then
					lib.itemIds[item] = nil
					lib.noItem[item] = true
					for handler, items in pairs(lib.handler) do
						items[item] = nil
					end
				end
			end
		end
		if not next(lib.itemIds) then
			self:Hide()
		end
	end
end)

if next(lib.itemIds) then
	lib.frames.registered = true
	lib.frames:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	lib.frames:RegisterEvent("EJ_LOOT_DATA_RECIEVED")
	lib.frames:RegisterEvent("PLAYER_ENTERING_WORLD")
	lib.frames:GetScript("OnEvent")(lib.frames)
else
	lib.frames.registered = nil
end