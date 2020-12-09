local MAJOR_VERSION, MINOR_VERSION = "LibBlueItemDrag-1.0", 1
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

local _G = _G
local type = _G.type
local next = _G.next
local select = _G.select
local GetMouseFocus = _G.GetMouseFocus
local CursorHasItem = _G.CursorHasItem
local GetCursorInfo = _G.GetCursorInfo
local InCombatLockdown = _G.InCombatLockdown

lib.version = MINOR_VERSION
lib.pickupItems = lib.pickupItems or {}
lib.registered = lib.registered or {}

function lib:RegisterItemDrag(key)
	lib.registered[key] = true
end

function lib:UnregisterItemDrag(key)
	lib.registered[key] = nil
	if not next(lib.registered) then
		lib.lastOwner, lib.lastItem = nil
	end
end

function lib:GetCursorItem()
	local cursor, item, link = GetCursorInfo()
	if cursor == "item" then
		return item, link
	elseif cursor == "merchant" then
		link = GetMerchantItemLink(item)
		if type(link) == "string" then
			item = link:match("item:(%d+)")
			if item then
				return tonumber(item), link
			end
		end
	end
	return nil
end

local function pickupItem(self)
	if lib.lastOwner == self and next(lib.registered) and not GetCursorInfo() and type(lib.lastItem) == "string" and lib.lastItem:find("item:.+%[.+%]") and (select(9, GetItemInfo(lib.lastItem)) or ""):find("^INVTYPE_") and not InCombatLockdown() then
		PickupItem(lib.lastItem)
	else
		lib.lastOwner, lib.lastItem = nil
	end
end

lib.pickupItems[pickupItem] = MINOR_VERSION

GameTooltip:HookScript("OnTooltipSetItem", function(self)
	if lib.version == MINOR_VERSION and next(lib.registered) and not GetCursorInfo() and not InCombatLockdown() then
		lib.lastOwner, lib.lastItem = GetMouseFocus(), select(2, self:GetItem())
		if lib.lastOwner and not lib.lastOwner:IsProtected() then
			self = lib.lastOwner:GetScript("OnDragStart")
			if (lib.pickupItems[self] and lib.pickupItems[self] < MINOR_VERSION) or not self then
				lib.lastOwner:RegisterForDrag("LeftButton")
				lib.lastOwner:SetScript("OnDragStart", pickupItem)
			end
		end
	end
end)

DEFAULT_CHAT_FRAME:HookScript("OnHyperlinkEnter", function(self, link, link2, ...)
	if lib.version == MINOR_VERSION and next(lib.registered) and not(GameTooltip:IsShown() and GameTooltip:GetOwner() == self) then
		link = (type(link) == "string" and link) or (type(link2) == "string" and link2)
		if link:find("item:") then
			GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
			GameTooltip:SetHyperlink(link)
			GameTooltip:Show()
			GameTooltip:SetAlpha(0)
		end
	end
end)

DEFAULT_CHAT_FRAME:HookScript("OnHyperlinkLeave", function()
	if lib.version == MINOR_VERSION then
		GameTooltip:Hide()
	end
end)