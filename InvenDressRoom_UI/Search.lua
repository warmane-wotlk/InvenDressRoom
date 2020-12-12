local addOnName = ...
local IDR = _G[GetAddOnDependencies(addOnName)]

if GetLocale() ~= "koKR" then return end

local _G = _G
local tonumber = _G.tonumber
local wipe = _G.table.wipe
local sort = _G.table.sort
local tinsert = _G.table.insert
local GetAddOnMetadata = _G.GetAddOnMetadata
local GetItemIcon = _G.GetItemIcon
local i, text, id
local search, hasItemCache, visibleItem = {}, {}, {}
local LBICR = LibStub("LibBlueItemCacheReceiver-1.0")

local searchBox = CreateFrame("EditBox", IDR:GetName().."SearchBox", IDR, "SearchBoxTemplate")
searchBox:SetFrameLevel(IDR:GetFrameLevel() + 1)
searchBox:SetSize(0, 20)
searchBox:SetPoint("TOPRIGHT", -8, -33)
searchBox:SetPoint("LEFT", IDR.raceList, "RIGHT", -9, 0)

IDR.searchItemList:SetPoint("TOP", searchBox, "BOTTOM", -4, 1)

local function updateDetailItem(btn)
	btn:SetText(select(2, GetItemInfo(btn:GetID())):gsub("%[", ""):gsub("%]", ""))
	btn.noItem = nil
end

local function setMenuItem(item)
	hasItemCache[item] = true
	if visibleItem[item] then
		updateDetailItem(IDR.searchItemList.items[visibleItem[item]])
	end
end

local function sortRev(a, b)
	return a > b
end

searchBox:SetScript("OnTextChanged", function(self, name)
	LBICR:UnregisterAllItemCache(setMenuItem)
	wipe(search)
	wipe(hasItemCache)
	wipe(visibleItem)
	if name then
		name = self:GetText()
		name = tostring((name or "")):trim():gsub("[%$%%%^%(%)%-%+%.%[%]]", "%%%1"):lower()
		if name ~= "" and name ~= SEARCH and not name:find("_") then
			name = "_[^_]-"..name.."[^_]-_(%d+)_"
			i, text = 1, GetAddOnMetadata(addOnName, "X-S1")
			while text do
				id = text:match(name)
				while id do
					tinsert(search, tonumber(id))
					text = text:gsub(name, "_", 1)
					id = text:match(name)
				end
				i = i + 1
				text = GetAddOnMetadata(addOnName, "X-S"..i)
			end
			i, text, id = nil
		end
		if #search > 0 then
			sort(search, sortRev)
			IDR.searchItemList:Show()
			FauxScrollFrame_SetOffset(IDR.searchItemList.scroll, 0)
			_G[IDR.searchItemList.scroll:GetName().."ScrollBar"]:SetValue(0)
			IDR:UpdateSearchItems()
			return
		end
	end
	IDR.searchItemList:Hide()
end)

local function clearSearchBox()
	LBICR:UnregisterAllItemCache(setMenuItem)
	--searchBox:SetText(SEARCH)
	searchBox:ClearFocus()
	wipe(search)
	wipe(hasItemCache)
	wipe(visibleItem)
	IDR.searchItemList:Hide()
end

searchBox:SetScript("OnEnterPressed", function(self)
	if #search > 0 then
		searchBox:ClearFocus()
	else
		clearSearchBox()
	end
end)
searchBox:SetScript("OnEscapePressed", clearSearchBox)
searchBox:SetScript("OnHide", clearSearchBox)

function IDR:UpdateSearchItems()
	wipe(visibleItem)
	local offset = FauxScrollFrame_GetOffset(IDR.searchItemList.scroll) or 0
	for i, btn in ipairs(IDR.searchItemList.items) do
		item = search[offset + i]
		if item then
			visibleItem[item] = i
			btn:SetID(item)
			local itemIcon = GetItemIcon(item)
			if itemIcon then
				btn:SetNormalTexture(itemIcon)
				if hasItemCache[item] then
					updateDetailItem(btn)
				else
					btn:SetText("#"..item)
					btn.noItem = true
					LBICR:RegisterItemCache(item, setMenuItem)
				end
				btn:Show()
				if btn:IsMouseOver() and GetMouseFocus() == btn then
					btn:GetScript("OnEnter")(btn)
				end
			end
		else
			btn:Hide()
			btn.noItem = nil
		end
	end
	FauxScrollFrame_Update(IDR.searchItemList.scroll, #search, #IDR.searchItemList.items, 17)
	IDR:HideAllDropdown()
end