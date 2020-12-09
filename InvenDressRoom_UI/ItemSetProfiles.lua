local _G = _G
local IDR = _G[GetAddOnDependencies((...))]
local pairs = _G.pairs
local wipe = _G.table.wipe

function IDR:IsCurrentItemSetChanged()
	if self.db.currentItemSet then
		if self.db.itemSets[self.db.currentItemSet] then
			for key, value in pairs(self.db.itemSets[self.db.currentItemSet]) do
				if self.db.currentItems[key] ~= value then
					return true
				end
			end
			for key, value in pairs(self.db.currentItems) do
				if self.db.itemSets[self.db.currentItemSet][key] ~= value then
					return true
				end
			end
		else
			self.db.currentItemSet = nil
		end
	end
	return nil
end

function IDR:IsCurrentItemSetResetable()
	for key in pairs(self.db.currentItems) do
		if key ~= "modelRace" then
			return true
		end
	end
	return nil
end

local function clearCurrentItemSet()
	wipe(IDR.db.currentItems)
	IDR:Refresh()
end

local function newItemSetProfile(profile)
	if not IDR.db.itemSets[profile] then
		IDR.db.currentItemSet = profile
		IDR.db.itemSets[profile] = { modelRace = IDR.defaultModelRace }
		wipe(IDR.db.currentItems)
		IDR.db.currentItems.modelRace = IDR.defaultModelRace
		IDR:Refresh()
		return true
	end
	return nil
end

local function loadItemSetProfile(profile)
	if IDR.db.itemSets[profile] then
		IDR.db.currentItemSet = profile
		profile = IDR.db.itemSets[profile]
		wipe(IDR.db.currentItems)
		for key, value in pairs(profile) do
			IDR.db.currentItems[key] = value
		end
		IDR:Refresh()
	end
end

local function saveItemSetProfile()
	if IDR.db.currentItemSet then
		wipe(IDR.db.itemSets[IDR.db.currentItemSet])
		for key, value in pairs(IDR.db.currentItems) do
			IDR.db.itemSets[IDR.db.currentItemSet][key] = value
		end
		IDR:Refresh()
	end
end

local function saveAsItemSetProfile(profile)
	if profile then
		IDR.db.currentItemSet = profile
		if IDR.db.itemSets[profile] then
			wipe(IDR.db.itemSets[profile])
		else
			IDR.db.itemSets[profile] = {}
		end
		saveItemSetProfile()
	end
end

local function deleteItemSetProfile(profile)
	if IDR.db.itemSets[profile] then
		IDR.db.itemSets[profile] = nil
		if IDR.db.currentItemSet == profile then
			IDR.db.currentItemSet = nil
		end
		IDR:Refresh()
	end
end

local staticPopupData = {}

local saveAsConfirmStaticPopup = IDR:AddStaticPopup("SAVE_AS_CONFIRM", {
	text = "[%s] 프로필이 이미 존재합니다.\n덮어 쓰시겠습니까?",
	button1 = YES,
	button2 = NO,
	hideOnEscape = 1,
	whileDead = 1,
	timeout = 0,
	showAlert = 1,
	OnAccept = function(self, data)
		saveAsItemSetProfile(data.overwrite)
	end,
})

local function applySaveAs(self, profile)
	self:Hide()
	profile = (type(profile) == "string" and profile or ""):trim()
	if profile ~= "" and profile ~= "저장된 프로필 없음" then
		if IDR.db.itemSets[profile] then
			staticPopupData.overwrite = profile
			CloseDropDownMenus(1)
			IDR:CloseAllStaticPopups()
			StaticPopup_Show(saveAsConfirmStaticPopup, profile, "", staticPopupData)
		else
			saveAsItemSetProfile(profile)
		end
	end
end

local saveAsStaticPopup = IDR:AddStaticPopup("SAVE_AS", {
	text = "저장할 프로필 이름을 입력하세요.",
	button1 = OKAY,
	button2 = CANCEL,
	hideOnEscape = 1,
	whileDead = 1,
	timeout = 0,
	hasEditBox = 1,
	maxLetters = 512,
	OnShow = function(self)
		self.editBox:SetText("")
		self.editBox:SetFocus()
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow()
		self.editBox:SetText("")
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	EditBoxOnEnterPressed = function(self)
		applySaveAs(self:GetParent(), self:GetText())
	end,
	OnAccept = function(self)
		applySaveAs(self, self.editBox:GetText())
	end,
})

local clearStaticPopup = IDR:AddStaticPopup("UNDRESS_ALL", {
	text = "착용중인 모든 장비를 초기화하시겠습니까?",
	button1 = YES,
	button2 = NO,
	hideOnEscape = 1,
	whileDead = 1,
	timeout = 0,
	showAlert = 1,
	OnAccept = function(self, data)
		clearCurrentItemSet()
	end,
})

local loadConfirmStaticPopup = IDR:AddStaticPopup("LOAD_CONFIRM", {
	text = "[%s] 프로필을 불러오면 저장되지 않은 현재 내용이 사라집니다. 정말 프로필을 불러오시겠습니까?",
	button1 = YES,
	button2 = NO,
	hideOnEscape = 1,
	whileDead = 1,
	timeout = 0,
	showAlert = 1,
	OnAccept = function(self, data)
		loadItemSetProfile(data.loadprofile)
		data.loadprofile = nil
	end,
})

local function loadProfile(_, profile)
	if IDR:IsCurrentItemSetChanged() or not IDR.db.currentItemSet then
		staticPopupData.loadprofile = profile
		CloseDropDownMenus(1)
		IDR:CloseAllStaticPopups()
		StaticPopup_Show(loadConfirmStaticPopup, profile, "", staticPopupData)
	else
		loadItemSetProfile(profile)
	end
end

IDR.profileSelector.button:SetScript("OnClick", IDR.DropDownButtonOnMenu)
UIDropDownMenu_Initialize(IDR.profileSelector, function(self, level)
	if level then
		local info = UIDropDownMenu_CreateInfo()
		info.func = loadProfile
		wipe(staticPopupData)
		for profile in pairs(IDR.db.itemSets) do
			tinsert(staticPopupData, profile)
		end
		sort(staticPopupData)
		for _, name in pairs(staticPopupData) do
			info.text, info.arg1 = name, name
			info.checked = IDR.db.currentItemSet == name
			UIDropDownMenu_AddButton(info, level)
		end
		wipe(staticPopupData)
	end
end)

IDR.profileSave:SetScript("OnClick", saveItemSetProfile)

IDR.profileSaveAs:SetScript("OnClick", function()
	CloseDropDownMenus(1)
	IDR:CloseAllStaticPopups()
	StaticPopup_Show(saveAsStaticPopup, "", "")
end)

IDR.undressAllItems:SetScript("OnClick", function()
	CloseDropDownMenus(1)
	IDR:CloseAllStaticPopups()
	StaticPopup_Show(clearStaticPopup, "", "")
end)

local deleteConfirmStaticPopup = IDR:AddStaticPopup("DELETE_PROFILE_CONFIRM", {
	text = "[%s] 프로필을 정말 삭제하시겠습니까?",
	button1 = YES,
	button2 = NO,
	hideOnEscape = 1,
	whileDead = 1,
	timeout = 0,
	showAlert = 1,
	OnAccept = function(self, data)
		deleteItemSetProfile(data.delprofile)
		data.delprofile = nil
		CloseDropDownMenus(1)
		IDR:CloseAllStaticPopups()
	end,
})

local function delProfile(_, profile)
	staticPopupData.delprofile = profile
	CloseDropDownMenus(1)
	IDR:CloseAllStaticPopups()
	StaticPopup_Show(deleteConfirmStaticPopup, profile, "", staticPopupData)
end

IDR.profileDelete.button:SetScript("OnClick", IDR.DropDownButtonOnMenu)
UIDropDownMenu_Initialize(IDR.profileDelete, function(self, level)
	if level then
		local info = UIDropDownMenu_CreateInfo()
		info.func, info.notCheckable = delProfile, true
		wipe(staticPopupData)
		for profile in pairs(IDR.db.itemSets) do
			tinsert(staticPopupData, profile)
		end
		sort(staticPopupData)
		for _, name in pairs(staticPopupData) do
			info.text, info.arg1 = name, name
			UIDropDownMenu_AddButton(info, level)
		end
		wipe(staticPopupData)
	end
end)