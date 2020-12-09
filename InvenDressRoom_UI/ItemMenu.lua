local modName, dummy = ...
local addOnName = GetAddOnDependencies(modName)
local _G = _G
local IDR = _G[addOnName]
local GetAddOnMetadata = _G.GetAddOnMetadata
local IsModifiedClick = _G.IsModifiedClick

local wowHomeItemURL = "http://kr.battle.net/wow/ko/item/%d"
local wowInvenItemURL = "http://wow.inven.co.kr/dataninfo2/item/detail.php?code=%d"
local wowHeadItemURL = "http://www.wowhead.com/item=%d"

function IDR:HideAllDropdown()
	CloseDropDownMenus(1)
end

local function removeItem(_, btn)
	IDR.db.currentItems[btn.slot] = nil
	IDR:SetPlayerModel()
end

local function equipItem(_, _, item)
	local equipLoc, subType = IDR:GetItemEquipLoc(item)
	if equipLoc:find("_") then
		equipLoc, subType = equipLoc:match("([^_]+)_(.+)")
	end
	if IDR.equipSlots[equipLoc] and IDR.db.currentItems[IDR.equipSlots[equipLoc]] ~= item then
		IDR.db.currentItems[IDR.equipSlots[equipLoc]] = item
		IDR:SetPlayerModel()
	end
end

local function equipItem2(_, _, item)
	if IDR.db.currentItems.SecondaryHandSlot ~= item then
		IDR.db.currentItems.SecondaryHandSlot = item
		IDR:SetPlayerModel()
	end
end

local function addFavoriteItem(_, _, item)
	IDR:AddFavoriteItem(item)
end

local function removeFavoriteItem(_, _, item)
	IDR:RemoveFavoriteItem(item)
end

local function openFavorites(_, btn)
	IDR:OpenFavoriteList(btn.mainCategory)
end

local function chatLink(_, btn, item)
	item = btn.itemLink or select(2, GetItemInfo(item))
	if item then
		if ChatEdit_GetActiveWindow() then
			ChatEdit_GetActiveWindow():Insert(item)
		else
			DEFAULT_CHAT_FRAME.editBox:Show()
			DEFAULT_CHAT_FRAME.editBox:Insert(item)
			DEFAULT_CHAT_FRAME.editBox:SetFocus()
		end
	end
end

local function findSameItem(_, btn, item)
	IDR:ShowItemListMenu(btn, true, item, IDR:GetSameItemList(item))
end

local function findSimilarItem(_, btn, item)
	IDR:ShowItemListMenu(btn, true, item, IDR:GetSimilarItemList(item))
end

local staticPopup = {
	text = "아래 주소를 복사해서 인터넷 브라우저에 붙여넣으세요.",
	button1 = CLOSE,
	hideOnEscape = 1,
	whileDead = 1,
	timeout = 0,
	hasEditBox = 1,
	editBoxWidth = 260,
	maxLetters = 100,
	OnShow = function(self, data)
		self.editBox:SetText(data.url)
		self.editBox:HighlightText()
		self.editBox:SetFocus()
		self.editBox:SetCursorPosition(0)
	end,
	OnHide = function(self, data)
		ChatEdit_FocusActiveWindow()
		self.editBox:HighlightText(0, 0)
		self.editBox:SetText("")
	end,
	OnUpdate = function(self)
		self.editBox:SetFocus()
		self.editBox:HighlightText()
	end,
	EditBoxOnTextChanged = function(self, data)
		if self:GetText() ~= data.url then
			self:SetText(data.url)
			self:SetCursorPosition(0)
			self:HighlightText()
		end
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
}
staticPopup.EditBoxOnEnterPressed = staticPopup.EditBoxOnEscapePressed

local staticPopup = IDR:AddStaticPopup("ITEMURL_LINK", staticPopup)
local urlData = {}

local function urlLink(_, item, url)
	CloseDropDownMenus(1)
	urlData.url = url:format(item)
	StaticPopup_Show(staticPopup, "", "", urlData)
end

local function itemSlotOnMenu(self, level)
	if level == 1 then
		local info = UIDropDownMenu_CreateInfo()
		self = self:GetParent()
		info.arg1, info.arg2 = self, self.item
		info.notCheckable = true

		if info.arg2 then
			info.text, info.func = "아이템 착용 해제하기", removeItem
			UIDropDownMenu_AddButton(info, level)

			if not self.noItem then
				if IDR:IsFavoriteItem(info.arg2) then
					info.text, info.func = "즐겨찾기에서 제거", removeFavoriteItem
				else
					info.text, info.func = "즐겨찾기에 추가", addFavoriteItem
				end
				UIDropDownMenu_AddButton(info, level)

				info.text, info.func = "동일한 외형의 다른 아이템 찾기", findSameItem
				info.disabled = not IDR:GetSameItemList(info.arg2):find(",")
				UIDropDownMenu_AddButton(info, level)

				info.text, info.func = "비슷한 외형의 다른 아이템 찾기", findSimilarItem
				info.disabled = not IDR:GetSimilarItemList(info.arg2):find(",")
				UIDropDownMenu_AddButton(info, level)
				info.disabled = nil

				info.text, info.func = "채팅창에 아이템 링크", chatLink
				UIDropDownMenu_AddButton(info, level)

				info.text, info.func, info.value, info.hasArrow = "인터넷 주소 링크", nil, "URL", true
				UIDropDownMenu_AddButton(info, level)
				info.value, info.hasArrow = nil
			end
		end

		info.text, info.func, info.disabled = "즐겨찾기 보관함 열기", openFavorites
		UIDropDownMenu_AddButton(info, level)

		info.text, info.func = CLOSE
		UIDropDownMenu_AddButton(info, level)
	elseif level == 2 and UIDROPDOWNMENU_MENU_VALUE == "URL" then
		local info = UIDropDownMenu_CreateInfo()
		info.func, info.arg1, info.notCheckable = urlLink, self:GetParent().item, true
		info.text, info.arg2 = "와우 공홈 아이템 URL 링크", wowHomeItemURL
		UIDropDownMenu_AddButton(info, level)
		info.text, info.arg2 = "와우 인벤 아이템 URL 링크", wowInvenItemURL
		UIDropDownMenu_AddButton(info, level)
		info.text, info.arg2 = "와우 헤드 아이템 URL 링크", wowHeadItemURL
		UIDropDownMenu_AddButton(info, level)
	end
end

local function itemOnMenu(self, level)
	if level == 1 then
		local info = UIDropDownMenu_CreateInfo()
		self = self:GetParent()
		info.arg1, info.arg2 = self, self:GetID()
		info.notCheckable = true

		info.equip = IDR:GetItemEquipLoc(info.arg2)
		if info.equip then
			if info.equip:find("_") then
				info.equip, info.subType = info.equip:match("([^_]+)_(.+)")
			end
			if info.equip == "WEAPON" or (info.equip == "2HWEAPON" and info.subType and info.subType:find("_2H$")) then
				info.text, info.func = "착용하기 - 주장비", equipItem
				UIDropDownMenu_AddButton(info, level)

				info.text, info.func = "착용하기 - 보조장비", equipItem2
				UIDropDownMenu_AddButton(info, level)
			else
				info.text, info.func = "착용하기", equipItem
				UIDropDownMenu_AddButton(info, level)
			end
		end

		if IDR:IsFavoriteItem(info.arg2) then
			info.text, info.func = "즐겨찾기에서 제거", removeFavoriteItem
		else
			info.text, info.func = "즐겨찾기에 추가", addFavoriteItem
		end
		UIDropDownMenu_AddButton(info, level)

		if self.findType == 0 then
			if IDR.selectedEquipLoc == "SET" then
				info.text, info.func = "동일한 외형의 다른 아이템 찾기", findSameItem
				info.disabled = not IDR:GetSameItemList(info.arg2):find(",")
				UIDropDownMenu_AddButton(info, level)
			end
			info.text, info.func = "비슷한 외형의 다른 아이템 찾기", findSimilarItem
			info.disabled = not IDR:GetSimilarItemList(info.arg2):find(",")
			UIDropDownMenu_AddButton(info, level)
			info.disabled = nil
		elseif self.findType == 1 then
			info.text, info.func = "동일한 외형의 다른 아이템 찾기", findSameItem
			info.disabled = not IDR:GetSameItemList(info.arg2):find(",")
			UIDropDownMenu_AddButton(info, level)

			info.text, info.func = "비슷한 외형의 다른 아이템 찾기", findSimilarItem
			info.disabled = not IDR:GetSimilarItemList(info.arg2):find(",")
			UIDropDownMenu_AddButton(info, level)
			info.disabled = nil
		end

		info.text, info.func = "채팅창에 아이템 링크", chatLink
		UIDropDownMenu_AddButton(info, level)

		info.text, info.func, info.value, info.hasArrow = "인터넷 URL 링크", nil, "URL", true
		UIDropDownMenu_AddButton(info, level)
		info.value, info.hasArrow = nil

		info.text, info.func = CLOSE
		UIDropDownMenu_AddButton(info, level)
	elseif level == 2 and UIDROPDOWNMENU_MENU_VALUE == "URL" then
		local info = UIDropDownMenu_CreateInfo()
		info.func, info.arg1, info.notCheckable = urlLink, self:GetParent():GetID(), true
		info.text, info.arg2 = "와우 공홈 아이템 URL 링크", wowHomeItemURL
		UIDropDownMenu_AddButton(info, level)
		info.text, info.arg2 = "와우 인벤 아이템 URL 링크", wowInvenItemURL
		UIDropDownMenu_AddButton(info, level)
		info.text, info.arg2 = "와우 헤드 아이템 URL 링크", wowHeadItemURL
		UIDropDownMenu_AddButton(info, level)
	end
end

local function itemOnClick(self)
	IDR:ModelPreviewHide()
	if self.noClick then
		self.noClick = nil
	elseif self.noItem then
		return
	elseif IsModifiedClick("CHATLINK") then
		if self:GetName():find(IDR.itemSlotPattern) then
			if self.item then
				return chatLink(_, self, self.item)
			end
		elseif self:GetID() > 0 then
			return chatLink(_, self, self:GetID())
		end

	elseif IsModifiedClick("DRESSUP") then
		if self:GetName():find(IDR.itemSlotPattern) then
			if self.item then
				return DressUpItemLink(self.item)
			end
		elseif self:GetID() > 0 then
			return DressUpItemLink(self:GetID())
		end
	end
	self = self:GetName()
	ToggleDropDownMenu(1, nil, _G[self.."DropDown"], self, 0, 0)
end

local function updateDressUpCursor(self)
	if IsModifiedClick("CHATLINK") and self.enter and GameTooltip:GetItem() and GameTooltip:GetOwner() == self.enter then
		GameTooltip_ShowCompareItem(GameTooltip, 1)
	elseif GameTooltip.shoppingTooltips[1]:IsVisible() then
		for _, compare in ipairs(GameTooltip.shoppingTooltips) do
			compare:Hide()
		end
	end
	if IsModifiedClick("DRESSUP") and self.enter then
		if self.enter:GetName():find(IDR.itemSlotPattern) then
			if self.enter.item then
				return SetCursor("INSPECT_CURSOR")
			end
		elseif self.enter:GetID() > 0 then
			return SetCursor("INSPECT_CURSOR")
		end
	end
	ResetCursor()
end

local dressUpCursor = CreateFrame("Frame", nil, IDR)
dressUpCursor:SetScript("OnEvent", updateDressUpCursor)
dressUpCursor:SetScript("OnShow", function(self)
	self:RegisterEvent("MODIFIER_STATE_CHANGED")
	updateDressUpCursor(self)
end)
dressUpCursor:SetScript("OnHide", function(self)
	self:UnregisterEvent("MODIFIER_STATE_CHANGED")
	ResetCursor()
end)

local function itemSlotOnEnter(self)
	dressUpCursor.enter = self
	dressUpCursor:Show()
end

local function itemSlotOnLeave(self)
	dressUpCursor.enter = nil
	dressUpCursor:Hide()
end

do
	local function setItemSlots(slots, menu, findType)
		for _, btn in pairs(slots) do
			UIDropDownMenu_Initialize(CreateFrame("Frame", btn:GetName().."DropDown", btn, "UIDropDownMenuTemplate"), menu, "MENU")
			btn.findType = findType
			btn:SetScript("OnClick", itemOnClick)
			btn:HookScript("OnEnter", itemSlotOnEnter)
			btn:HookScript("OnLeave", itemSlotOnLeave)
		end
	end

	setItemSlots(IDR.itemSlots, itemSlotOnMenu)
	setItemSlots(IDR.detailItems, itemOnMenu, 0)
	setItemSlots(IDR.itemListMenu.items, itemOnMenu, nil)
	setItemSlots(IDR.favoriteList.items, itemOnMenu, 1)
	setItemSlots(IDR.searchItemList.items, itemOnMenu, 1)
end

function IDR:DropDownButtonOnMenu()
	IDR:CloseAllStaticPopups()
	ToggleDropDownMenu(1, nil, self:GetParent(), self:GetParent():GetName(), 12, 12)
end