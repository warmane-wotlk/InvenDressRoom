local modName = ...
local addOnName = GetAddOnDependencies(modName)
local _G = _G
local IDR = _G[addOnName]
local type = _G.type
local next = _G.next
local pairs = _G.pairs
local GetItemIcon = _G.GetItemIcon

function IDR:GetFavoriteDB(item, create)
	if type(item) == "number" then
		item = self:GetItemEquipLoc(item)
		if not item then
			return nil
		end
	elseif type(item) == "string" then
		if not GetAddOnMetadata(modName, "X-DB-"..item) then
			return nil
		end
	else
		return nil
	end
	if item:find("_") then
		local equipLoc, subType = item:match("^([^_]+)_(.+)$")
		if create then
			IDR.db.favorites[equipLoc] = IDR.db.favorites[equipLoc] or {}
			IDR.db.favorites[equipLoc][subType] = IDR.db.favorites[equipLoc][subType] or {}
			return IDR.db.favorites[equipLoc][subType]
		elseif IDR.db.favorites[equipLoc] and IDR.db.favorites[equipLoc][subType] and next(IDR.db.favorites[equipLoc][subType]) then
			return IDR.db.favorites[equipLoc][subType]
		else
			return nil
		end
	elseif create then
		IDR.db.favorites[item] = IDR.db.favorites[item] or {}
		return IDR.db.favorites[item]
	elseif IDR.db.favorites[item] and next(IDR.db.favorites[item]) then
		return IDR.db.favorites[item]
	else
		return nil
	end
end

function IDR:IsFavoriteItem(item)
	self = self:GetFavoriteDB(item)
	return self and self[item]
end

function IDR:ClearFavoriteDB()
	for l1, t1 in pairs(self.db.favorites) do
		for l2, t2 in pairs(t1) do
			if type(t2) == "table" then
				for l3 in pairs(t2) do
					if not GetItemIcon(l3) then
						self.db.favorites[l1][l2][l3] = nil
					end
				end
				if not next(t2) then
					self.db.favorites[l1][l2] = nil
				end
			elseif not GetItemIcon(l2) then
				self.db.favorites[l1][l2] = nil
			end
		end
		if not next(t1) then
			self.db.favorites[l1] = nil
		end
	end
end

local function updateFavoriteItem()
	if IDR.selectedModel then
		if IDR.selectedEquipLoc ~= "SET" then
			IDR:UpdateDetailModelPage()
		end
		if IDR.detailItems[1]:IsVisible() then
			IDR:UpdateDetailItems()
		end
	end
	if IDR.itemListMenu:IsVisible() then
		IDR:UpdateItemListMenuItems()
	end
	if IDR.favoriteList:IsVisible() then
		IDR:SetFavoriteList()
	end
end

function IDR:AddFavoriteItem(item)
	if type(item) == "number" and GetItemIcon(item) then
		self = self:GetFavoriteDB(item, true)
		if self and not self[item] then
			self[item] = true
			updateFavoriteItem()
			return true
		end
	end
	return nil
end

function IDR:RemoveFavoriteItem(item)
	self = self:GetFavoriteDB(item)
	if self and self[item] then
		self[item] = nil
		if not next(self) then
			IDR:ClearFavoriteDB()
		end
		updateFavoriteItem()
		return true
	end
	return nil
end

local favoriteButton = CreateFrame("Button", addOnName.."FavoriteButton", IDR, "UIPanelButtonTemplate2")
favoriteButton:SetFrameLevel(IDR:GetFrameLevel() + 1)
favoriteButton:SetPoint("TOPRIGHT", IDR:GetName().."ItemTrinket1Slot", "BOTTOMRIGHT", 4, -3)
favoriteButton:SetText("즐겨찾기 보관함")
favoriteButton:SetSize(100, 38)
favoriteButton:SetScript("OnClick", function()
	if IDR.favoriteList:IsShown() then
		IDR.favoriteList:Hide()
	else
		IDR.favoriteList:Show()
	end
end)

local subCategoryCache = {}

local function mainCategoryOnClick(_, cate)
	if IDR.favoriteList.equipLoc ~= cate then
		if subCategoryCache[cate] then
			IDR:SetFavoriteList(cate.."_"..subCategoryCache[cate], true)
		else
			IDR:SetFavoriteList(cate, true)
		end
	end
end

UIDropDownMenu_Initialize(IDR.favoriteList.mainCategory, function(self, level)
	if level then
		local info = UIDropDownMenu_CreateInfo()
		info.func = mainCategoryOnClick
		for _, cate in ipairs(IDR.mainCategory) do
			info.text = IDR:GetCategoryName(cate)
			info.arg1 = cate
			info.checked = IDR.favoriteList.equipLoc == cate
			UIDropDownMenu_AddButton(info, level)
		end
	end
end)

local function subCategoryOnClick(_, cate)
	if IDR.favoriteList.subType ~= cate then
		if IDR.subCategory[IDR.favoriteList.equipLoc] then
			subCategoryCache[IDR.favoriteList.equipLoc] = cate
			if cate then
				IDR:SetFavoriteList(IDR.favoriteList.equipLoc.."_"..cate, true)
			else
				IDR:SetFavoriteList(IDR.favoriteList.equipLoc, true)
			end
		else
			IDR:SetFavoriteList(IDR.favoriteList.equipLoc, true)
		end
	end
end

UIDropDownMenu_Initialize(IDR.favoriteList.subCategory, function(self, level)
	if level then
		local info = UIDropDownMenu_CreateInfo()
		info.func = subCategoryOnClick
		info.text = ALL
		info.arg1 = nil
		info.checked = not IDR.favoriteList.subType
		UIDropDownMenu_AddButton(info, level)
		for _, cate in ipairs(IDR.subCategory[IDR.favoriteList.equipLoc]) do
			info.text = IDR:GetCategoryName(IDR.favoriteList.equipLoc.."_"..cate)
			info.arg1 = cate
			info.checked = IDR.favoriteList.subType == cate
			UIDropDownMenu_AddButton(info, level)
		end
	end
end)

IDR.favoriteList.mainCategory.button:SetScript("OnClick", IDR.DropDownButtonOnMenu)
IDR.favoriteList.subCategory.button:SetScript("OnClick", IDR.DropDownButtonOnMenu)

local favoriteItems, visibleItem, hasItemCache = {}, {}, {}

function IDR:OpenFavoriteList(cate)
	if subCategoryCache[cate] then
		IDR:SetFavoriteList(cate.."_"..subCategoryCache[cate], true)
	else
		IDR:SetFavoriteList(cate, true)
	end
	IDR.favoriteList:Show()
end

function IDR:SetFavoriteList(equip, reset)
	if type(equip) == "string" then
		if equip:find("_") then
			self.favoriteList.equipLoc, self.favoriteList.subType = equip:match("^([^_]+)_(.+)$")
		else
			self.favoriteList.equipLoc, self.favoriteList.subType = equip
		end
	elseif not self.favoriteList.equipLoc then
		self.favoriteList.equipLoc, self.favoriteList.subType = "HEAD"
	end
	UIDropDownMenu_SetText(self.favoriteList.mainCategory, self:GetCategoryName(self.favoriteList.equipLoc))
	if self.subCategory[self.favoriteList.equipLoc] then
		if self.favoriteList.subType then
			UIDropDownMenu_SetText(self.favoriteList.subCategory, self:GetCategoryName(self.favoriteList.equipLoc.."_"..self.favoriteList.subType))
		else
			UIDropDownMenu_SetText(self.favoriteList.subCategory, ALL)
		end
		UIDropDownMenu_EnableDropDown(self.favoriteList.subCategory)
	else
		UIDropDownMenu_SetText(self.favoriteList.subCategory, ALL)
		UIDropDownMenu_DisableDropDown(self.favoriteList.subCategory)
	end

	wipe(favoriteItems)
	wipe(visibleItem)
	wipe(hasItemCache)

	if self.db.favorites[self.favoriteList.equipLoc] then
		if self.subCategory[self.favoriteList.equipLoc] then
			if self.favoriteList.subType then
				if self.db.favorites[self.favoriteList.equipLoc][self.favoriteList.subType] then
					for item in pairs(self.db.favorites[self.favoriteList.equipLoc][self.favoriteList.subType]) do
						tinsert(favoriteItems, item)
					end
				end
			else
				for _, items in pairs(self.db.favorites[self.favoriteList.equipLoc]) do
					for item in pairs(items) do
						tinsert(favoriteItems, item)
					end
				end
			end
		else
			for item in pairs(self.db.favorites[self.favoriteList.equipLoc]) do
				tinsert(favoriteItems, item)
			end
		end
	end
	sort(favoriteItems)
	FauxScrollFrame_Update(self.favoriteList.scroll, #favoriteItems, #self.favoriteList.items, 17)
	if reset then
		FauxScrollFrame_SetOffset(self.favoriteList.scroll, 0)
		_G[self.favoriteList.scroll:GetName().."ScrollBar"]:SetValue(0)
	end
	self:UpdateFavoriteList()
end

local LBICR = LibStub("LibBlueItemCacheReceiver-1.0")

local function updateDetailItem(btn)
	btn:SetText((select(2, GetItemInfo(btn:GetID())):gsub("%[", ""):gsub("%]", "")))
	btn.noItem = nil
end

local function setDetailItem(item)
	hasItemCache[item] = true
	if visibleItem[item] then
		updateDetailItem(IDR.favoriteList.items[visibleItem[item]])
	end
end

function IDR:UpdateFavoriteList()
	local offset = FauxScrollFrame_GetOffset(IDR.favoriteList.scroll) or 0
	for i, btn in ipairs(IDR.favoriteList.items) do
		item = favoriteItems[offset + i]
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
					LBICR:RegisterItemCache(item, setDetailItem)
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
	IDR:HideAllDropdown()
end

IDR.favoriteList:SetScript("OnShow", function()
	IDR.modelFrame:EnableMouse(nil)
	IDR:SetFavoriteList()
end)
IDR.favoriteList:SetScript("OnHide", function()
	IDR.modelFrame:EnableMouse(true)
	LBICR:UnregisterItemCache(setDetailItem)
end)