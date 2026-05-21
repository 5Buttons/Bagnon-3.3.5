local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local LogFrame = Bagnon.Classy:New('ScrollingMessageFrame')
Bagnon.GuildLogFrame = LogFrame

LogFrame.WIDTH  = 300
LogFrame.HEIGHT = 200

local MAX_LINES  = 25
local MSG_COLOR  = '|cff009999   '


--[[ Time formatting — 3.3.5 stores time as "units ago" tuples ]]--

local TIME_WRAPPER = GUILD_BANK_LOG_TIME         or '(%s ago)'
local TIME_YEARS   = GUILD_BANK_LOG_TIME_YEARS   or '%d yr'
local TIME_MONTHS  = GUILD_BANK_LOG_TIME_MONTHS  or '%d mo'
local TIME_DAYS    = GUILD_BANK_LOG_TIME_DAYS    or '%d d'
local TIME_HOURS   = GUILD_BANK_LOG_TIME_HOURS   or '%d hr'

local function FormatTime(year, month, day, hour)
	if year  > 0 then return format(TIME_WRAPPER, format(TIME_YEARS,  year))  end
	if month > 0 then return format(TIME_WRAPPER, format(TIME_MONTHS, month)) end
	if day   > 0 then return format(TIME_WRAPPER, format(TIME_DAYS,   day))   end
	return format(TIME_WRAPPER, format(TIME_HOURS, hour or 0))
end


--[[ Constructor ]]--

function LogFrame:New(frameID, parent)
	local f = self:Bind(CreateFrame('ScrollingMessageFrame', nil, parent))
	f:SetWidth(LogFrame.WIDTH)
	f:SetHeight(LogFrame.HEIGHT)
	f:SetFontObject(GameFontHighlight)
	f:SetMaxLines(MAX_LINES)
	f:SetJustifyH('LEFT')
	f:SetFading(false)
	f:EnableMouse(true)
	f:SetHyperlinksEnabled(true)
	f:SetScript('OnMouseWheel',     f.OnMouseWheel)
	f:SetScript('OnHyperlinkClick', f.OnHyperlinkClick)
	f:SetScript('OnEvent',          f.OnEvent)
	f.frameID = frameID
	f:Hide()
	return f
end


--[[ Event dispatch ]]--

function LogFrame:OnEvent(event, ...)
	local action = self[event]
	if action then action(self, event, ...) end
end


--[[ Event / message registration ]]--

function LogFrame:UpdateEvents()
	self:UnregisterAllEvents()
	self:UnregisterAllMessages()

	if self.logType then
		self:RegisterEvent('GUILDBANKLOG_UPDATE')
		if self.logType == 'item' then
			self:RegisterMessage('GUILD_BANK_TAB_CHANGE')
		end
	end
end

function LogFrame:SetLogType(logType)
	self.logType = logType
	self:UpdateEvents()
end


--[[ WoW events ]]--

function LogFrame:GUILDBANKLOG_UPDATE()
	self:UpdateContent()
end

function LogFrame:GUILD_BANK_TAB_CHANGE()
	self:Update()
end


--[[ Data ]]--

function LogFrame:Update()
	if not self.logType then return end

	if self.logType == 'money' then
		QueryGuildBankLog(MAX_GUILDBANK_TABS + 1)
	else
		local tab = GetCurrentGuildBankTab()
		QueryGuildBankTab(tab)
		QueryGuildBankLog(tab)
	end

	self:UpdateContent()
end

function LogFrame:UpdateContent()
	self:Clear()
	if self.logType == 'item' then
		self:PrintItems()
	elseif self.logType == 'money' then
		self:PrintMoney()
	end
	self:ScrollToBottom()
end



--[[ Rendering ]]--

function LogFrame:PrintItems()
	local tab = GetCurrentGuildBankTab()
	local num = GetNumGuildBankTransactions(tab)
	local added = 0

	for i = 1, num do
		local txType, name, itemLink, count, tab1, tab2, year, month, day, hour =
			GetGuildBankTransaction(tab, i)

		name = NORMAL_FONT_COLOR_CODE .. (name or UNKNOWN) .. FONT_COLOR_CODE_CLOSE
		local msg

		if txType == 'deposit' then
			msg = format(GUILDBANK_DEPOSIT_FORMAT, name, itemLink)
			if count > 1 then msg = msg .. format(GUILDBANK_LOG_QUANTITY, count) end
		elseif txType == 'withdraw' then
			msg = format(GUILDBANK_WITHDRAW_FORMAT, name, itemLink)
			if count > 1 then msg = msg .. format(GUILDBANK_LOG_QUANTITY, count) end
		elseif txType == 'move' then
			local fromTab = GetGuildBankTabInfo(tab1)
			local toTab   = GetGuildBankTabInfo(tab2)
			msg = format(GUILDBANK_MOVE_FORMAT, name, itemLink, count, fromTab, toTab)
		end

		if msg then
			self:AddMessage(msg .. MSG_COLOR .. FormatTime(year, month, day, hour))
			added = added + 1
		end
	end
	return added
end

function LogFrame:PrintMoney()
	local num = GetNumGuildBankMoneyTransactions()
	local added = 0

	for i = 1, num do
		local txType, name, amount, year, month, day, hour = GetGuildBankMoneyTransaction(i)

		name = NORMAL_FONT_COLOR_CODE .. (name or UNKNOWN) .. FONT_COLOR_CODE_CLOSE
		local money = GetMoneyString(amount)
		local msg

		if txType == 'deposit' then
			msg = format(GUILDBANK_DEPOSIT_MONEY_FORMAT, name, money)
		elseif txType == 'withdraw' then
			msg = format(GUILDBANK_WITHDRAW_MONEY_FORMAT, name, money)
		elseif txType == 'repair' then
			msg = format(GUILDBANK_REPAIR_MONEY_FORMAT, name, money)
		elseif txType == 'withdrawForTab' then
			msg = format(GUILDBANK_WITHDRAWFORTAB_MONEY_FORMAT, name, money)
		elseif txType == 'buyTab' then
			if amount and amount > 0 and GUILDBANK_BUYTAB_MONEY_FORMAT then
				msg = format(GUILDBANK_BUYTAB_MONEY_FORMAT, name, money)
			else
				msg = format(GUILDBANK_UNLOCKTAB_FORMAT, name)
			end
		end

		if msg then
			self:AddMessage(msg .. MSG_COLOR .. FormatTime(year, month, day, hour))
			added = added + 1
		end
	end
	return added
end


--[[ Frame Events ]]--

function LogFrame:OnMouseWheel(delta)
	if delta > 0 then self:ScrollUp() else self:ScrollDown() end
end

function LogFrame:OnHyperlinkClick(link, text, button)
	SetItemRef(link, text, button)
end
