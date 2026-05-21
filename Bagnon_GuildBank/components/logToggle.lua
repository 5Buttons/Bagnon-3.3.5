local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local LogToggle = Bagnon.Classy:New('CheckButton')
Bagnon.GuildLogToggle = LogToggle

local SIZE = 20

LogToggle.Icons = {
	item  = [[Interface\Icons\INV_Crate_03]],
	money = [[Interface\Icons\INV_Misc_Coin_01]],
}

LogToggle.Titles = {
	item  = GUILD_BANK_LOG,
	money = GUILD_BANK_MONEY_LOG,
}


--[[ Constructor ]]--

function LogToggle:New(logType, frameID, parent)
	local b = self:Bind(CreateFrame('CheckButton', nil, parent))
	b:SetWidth(SIZE)
	b:SetHeight(SIZE)
	b.logType = logType
	b.frameID = frameID

	b:SetNormalTexture([[Interface\Buttons\UI-Quickslot2]])
	b:SetPushedTexture([[Interface\Buttons\UI-Quickslot-Depress]])
	b:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
	b:SetCheckedTexture([[Interface\Buttons\CheckButtonHilight]])

	local icon = b:CreateTexture(nil, 'BORDER')
	icon:SetPoint('CENTER')
	icon:SetWidth(SIZE - 4)
	icon:SetHeight(SIZE - 4)
	icon:SetTexture(LogToggle.Icons[logType])

	b:RegisterForClicks('LeftButtonUp')
	b:SetScript('OnClick',  b.OnClick)
	b:SetScript('OnEnter',  b.OnEnter)
	b:SetScript('OnLeave',  b.OnLeave)

	b:RegisterMessage('GUILD_LOG_SELECTED')

	return b
end


--[[ Events ]]--

function LogToggle:GUILD_LOG_SELECTED(msg, frameID, logType)
	if frameID == self.frameID then
		self:SetChecked(logType == self.logType or nil)
	end
end


--[[ Frame Events ]]--

function LogToggle:OnClick()
	if self:GetChecked() then
		self:SendMessage('GUILD_LOG_SELECTED', self.frameID, self.logType)
	else
		self:SendMessage('GUILD_LOG_SELECTED', self.frameID, nil)
	end
end

function LogToggle:OnEnter()
	GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	GameTooltip:SetText(LogToggle.Titles[self.logType])
	GameTooltip:Show()
end

function LogToggle:OnLeave()
	GameTooltip:Hide()
end
