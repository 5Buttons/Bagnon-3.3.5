--[[
	frame.lua
		A specialized version of the bagnon frame for guild banks
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local Frame = Bagnon.Classy:New('Frame', Bagnon.Frame)
Frame:Hide()
Bagnon.GuildFrame = Frame


--[[
	Log Toggle / Log Frame
--]]

function Frame:CreateLogToggles()
	self.logToggles = {
		Bagnon.GuildLogToggle:New('item',  self:GetFrameID(), self),
		Bagnon.GuildLogToggle:New('money', self:GetFrameID(), self),
	}
	return self.logToggles
end

function Frame:GetLogToggles()
	return self.logToggles or self:CreateLogToggles()
end

function Frame:CreateLogFrame()
	local f = Bagnon.GuildLogFrame:New(self:GetFrameID(), self)
	self.logFrame = f
	return f
end

function Frame:GetLogFrame()
	return self.logFrame or self:CreateLogFrame()
end


--[[
	Events
--]]

function Frame:UpdateEvents()
	Bagnon.Frame.UpdateEvents(self)
	if self:IsVisible() then
		self:RegisterMessage('GUILD_LOG_SELECTED')
	end
end

function Frame:GUILD_LOG_SELECTED(msg, frameID, logType)
	if self:GetFrameID() ~= frameID then return end
	self.logType = logType
	self:Layout()
end

function Frame:OnShow()
	PlaySound('GuildVaultOpen')

	self:UpdateEvents()
	self:UpdateLook()
end

function Frame:OnHide()
--	GuildBankPopupFrame:Hide()
	StaticPopup_Hide('GUILDBANK_WITHDRAW')
	StaticPopup_Hide('GUILDBANK_DEPOSIT')
	StaticPopup_Hide('CONFIRM_BUY_GUILDBANK_TAB')
	CloseGuildBankFrame()
	PlaySound('GuildVaultClose')

	self:UpdateEvents()

	--fix issue where a frame is hidden, but not via bagnon controlled methods (ie, close on escape)
	if self:IsFrameShown() then
		self:HideFrame()
	end
end


--[[
	Actions
--]]

function Frame:CreateItemFrame()
	local f = Bagnon.GuildItemFrame:New(self:GetFrameID(), self)
	self.itemFrame = f
	return f
end

function Frame:CreateBagFrame()
	local f = Bagnon.GuildTabFrame:New(self:GetFrameID(), self)
	self.bagFrame = f
	return f
end

function Frame:CreateMoneyFrame()
	local f = Bagnon.GuildMoneyFrame:New(self:GetFrameID(), self)
	self.moneyFrame = f
	return f
end

function Frame:HasBagFrame()
	return true
end

function Frame:IsBagFrameShown()
	return self.logType ~= 'money'
end

function Frame:HasBagToggle()
	return false
end

function Frame:HasPlayerSelector()
	return false
end


--[[
	Layout overrides
--]]

-- Appends the two log toggle buttons after whatever the base frame placed.
function Frame:PlaceMenuButtons()
	local w, h = Bagnon.Frame.PlaceMenuButtons(self)
	local menuButtons = self:GetMenuButtons()

	for _, toggle in ipairs(self:GetLogToggles()) do
		toggle:ClearAllPoints()
		if #menuButtons > 0 then
			toggle:SetPoint('TOPLEFT', menuButtons[#menuButtons], 'TOPRIGHT', 4, 0)
		else
			toggle:SetPoint('TOPLEFT', self, 'TOPLEFT', 8, -8)
		end
		toggle:SetChecked(self.logType == toggle.logType or nil)
		toggle:Show()
		table.insert(menuButtons, toggle)
	end

	local n = #menuButtons
	if n > 0 then
		return menuButtons[1]:GetWidth() * n + 4 * (n - 1), menuButtons[1]:GetHeight()
	end
	return w, h
end

-- When a log is active, overlay it on the item frame area so the window never resizes.
function Frame:PlaceItemFrame()
	local w, h = Bagnon.Frame.PlaceItemFrame(self)

	if self.logType then
		self:GetItemFrame():Hide()

		local logFrame = self:GetLogFrame()
		logFrame:SetLogType(self.logType)
		logFrame:ClearAllPoints()
		logFrame:SetAllPoints(self:GetItemFrame())
		logFrame:Show()
		logFrame:Update()
	elseif self.logFrame then
		self.logFrame:Hide()
	end

	return w, h
end