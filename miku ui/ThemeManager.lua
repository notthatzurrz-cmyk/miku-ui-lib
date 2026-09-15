local HttpService = game:GetService('HttpService')

local ThemeManager = {
	Folder = 'yuno',
	Library = nil,
	DefaultTheme = 'Yuno',
	_Applying = false,
}

ThemeManager.BuiltInThemes = {
	['Yuno'] = { 0, { FontColor = 'ece8f8', MainColor = '120e1c', AccentColor = 'a85cff', BackgroundColor = '0a0810', OutlineColor = '302844' } },
	['Default'] = { 1, { FontColor = 'ffffff', MainColor = '1c1c1c', AccentColor = '0055ff', BackgroundColor = '141414', OutlineColor = '323232' } },
	['BBot'] = { 2, { FontColor = 'ffffff', MainColor = '1e1e1e', AccentColor = '7e48a3', BackgroundColor = '232323', OutlineColor = '141414' } },
	['Fatality'] = { 3, { FontColor = 'ffffff', MainColor = '1e1842', AccentColor = 'c50754', BackgroundColor = '191335', OutlineColor = '3c355d' } },
	['Jester'] = { 4, { FontColor = 'ffffff', MainColor = '242424', AccentColor = 'db4467', BackgroundColor = '1c1c1c', OutlineColor = '373737' } },
	['Mint'] = { 5, { FontColor = 'ffffff', MainColor = '242424', AccentColor = '3db488', BackgroundColor = '1c1c1c', OutlineColor = '373737' } },
	['Tokyo Night'] = { 6, { FontColor = 'ffffff', MainColor = '191925', AccentColor = '6759b3', BackgroundColor = '16161f', OutlineColor = '323232' } },
	['Ubuntu'] = { 7, { FontColor = 'ffffff', MainColor = '3e3e3e', AccentColor = 'e2581e', BackgroundColor = '323232', OutlineColor = '191919' } },
	['Quartz'] = { 8, { FontColor = 'ffffff', MainColor = '232330', AccentColor = '426e87', BackgroundColor = '1d1b26', OutlineColor = '27232f' } },
}

local function OptionsTable(self)
	if type(Options) == 'table' then
		return Options
	end
	if self.Library and type(self.Library.Options) == 'table' then
		return self.Library.Options
	end
	return nil
end

function ThemeManager:BuildFolderTree()
	local folder = self.Folder or 'yuno'
	local paths = { folder, folder .. '/themes', folder .. '/settings' }
	for i = 1, #paths do
		if type(isfolder) == 'function' and type(makefolder) == 'function' and not isfolder(paths[i]) then
			pcall(makefolder, paths[i])
		end
	end
end

function ThemeManager:SetLibrary(lib)
	self.Library = lib
end

function ThemeManager:SetFolder(folder)
	self.Folder = folder
	self:BuildFolderTree()
end

function ThemeManager:ThemeUpdate()
	if not self.Library then
		return
	end
	local options = OptionsTable(self)
	local fields = { 'FontColor', 'MainColor', 'AccentColor', 'BackgroundColor', 'OutlineColor' }
	for i = 1, #fields do
		local field = fields[i]
		if options and options[field] and typeof(options[field].Value) == 'Color3' then
			self.Library[field] = options[field].Value
		end
	end
	if type(self.Library.GetDarkerColor) == 'function' then
		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
	end
	self.Library.Accent = self.Library.AccentColor
	if type(self.Library.UpdateColorsUsingRegistry) == 'function' then
		self.Library:UpdateColorsUsingRegistry()
	end
end

function ThemeManager:ApplyTheme(theme)
	if self._Applying or not self.Library then
		return
	end
	local custom = self:GetCustomTheme(theme)
	local builtin = self.BuiltInThemes[theme]
	local scheme = custom or (builtin and builtin[2])
	if type(scheme) ~= 'table' then
		return
	end
	self._Applying = true
	local options = OptionsTable(self)
	for idx, col in next, scheme do
		local ok, color = pcall(Color3.fromHex, col)
		if ok and typeof(color) == 'Color3' then
			self.Library[idx] = color
			if options and options[idx] and type(options[idx].SetValueRGB) == 'function' then
				options[idx]:SetValueRGB(color)
			end
		end
	end
	self:ThemeUpdate()
	self._Applying = false
end

function ThemeManager:GetCustomTheme(file)
	if type(file) ~= 'string' or file == '' then
		return nil
	end
	local path = self.Folder .. '/themes/' .. file
	if not path:find('%.json$') then
		path = path .. '.json'
	end
	if type(isfile) ~= 'function' or not isfile(path) then
		return nil
	end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(path))
	if ok and type(decoded) == 'table' then
		return decoded
	end
	return nil
end

function ThemeManager:SaveCustomTheme(file)
	if type(file) ~= 'string' or file:gsub(' ', '') == '' then
		return self.Library:Notify('Invalid file name for theme (empty)', 3)
	end
	local options = OptionsTable(self)
	local theme = {}
	for _, field in ipairs({ 'FontColor', 'MainColor', 'AccentColor', 'BackgroundColor', 'OutlineColor' }) do
		if options and options[field] and typeof(options[field].Value) == 'Color3' then
			theme[field] = options[field].Value:ToHex()
		end
	end
	pcall(writefile, self.Folder .. '/themes/' .. file .. '.json', HttpService:JSONEncode(theme))
end

function ThemeManager:ReloadCustomThemes()
	local folder = self.Folder .. '/themes'
	if type(listfiles) ~= 'function' then
		return {}
	end
	local ok, list = pcall(listfiles, folder)
	if not ok or type(list) ~= 'table' then
		return {}
	end
	local out = {}
	for i = 1, #list do
		local file = list[i]
		if type(file) == 'string' and file:sub(-5) == '.json' then
			local name = file:match('([^/\\]+)%.json$')
			if name then
				out[#out + 1] = name .. '.json'
			end
		end
	end
	return out
end

function ThemeManager:SaveDefault(theme)
	if type(theme) == 'string' and theme ~= '' then
		pcall(writefile, self.Folder .. '/themes/default.txt', theme)
	end
end

function ThemeManager:LoadDefault()
	local theme = self.DefaultTheme
	local path = self.Folder .. '/themes/default.txt'
	if type(isfile) == 'function' and isfile(path) then
		local ok, content = pcall(readfile, path)
		if ok and type(content) == 'string' and content ~= '' then
			theme = content
		end
	end
	local options = OptionsTable(self)
	if options and options.ThemeManager_ThemeList and self.BuiltInThemes[theme] then
		options.ThemeManager_ThemeList:SetValue(theme)
	else
		self:ApplyTheme(theme)
	end
end

function ThemeManager:CreateThemeManager(groupbox)
	groupbox:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor })
	groupbox:AddLabel('Main color'):AddColorPicker('MainColor', { Default = self.Library.MainColor })
	groupbox:AddLabel('Accent color'):AddColorPicker('AccentColor', { Default = self.Library.AccentColor })
	groupbox:AddLabel('Outline color'):AddColorPicker('OutlineColor', { Default = self.Library.OutlineColor })
	groupbox:AddLabel('Font color'):AddColorPicker('FontColor', { Default = self.Library.FontColor })

	local themes = {}
	for name in next, self.BuiltInThemes do
		themes[#themes + 1] = name
	end
	table.sort(themes, function(a, b)
		return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1]
	end)

	groupbox:AddDivider()
	groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Theme list', Values = themes, Default = 1 })
	groupbox:AddButton('Set as default', function()
		local options = OptionsTable(self)
		local name = options.ThemeManager_ThemeList.Value
		self:SaveDefault(name)
		self.Library:Notify(string.format('Set default theme to %q', name))
	end)

	local options = OptionsTable(self)
	options.ThemeManager_ThemeList:OnChanged(function()
		if self._Applying then
			return
		end
		self:ApplyTheme(options.ThemeManager_ThemeList.Value)
	end)

	groupbox:AddDivider()
	groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' })
	groupbox:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
	groupbox:AddButton('Save theme', function()
		self:SaveCustomTheme(options.ThemeManager_CustomThemeName.Value)
		options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
	end):AddButton('Load theme', function()
		self:ApplyTheme(options.ThemeManager_CustomThemeList.Value)
	end)
	groupbox:AddButton('Refresh list', function()
		options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
	end)
	groupbox:AddButton('Set as default', function()
		local name = options.ThemeManager_CustomThemeList.Value
		if type(name) == 'string' and name ~= '' then
			self:SaveDefault(name)
			self.Library:Notify(string.format('Set default theme to %q', name))
		end
	end)

	self:LoadDefault()

	local function bump()
		if self._Applying then
			return
		end
		self:ThemeUpdate()
	end
	options.BackgroundColor:OnChanged(bump)
	options.MainColor:OnChanged(bump)
	options.AccentColor:OnChanged(bump)
	options.OutlineColor:OnChanged(bump)
	options.FontColor:OnChanged(bump)
end

function ThemeManager:CreateGroupBox(tab)
	return tab:AddLeftGroupbox('Themes')
end

function ThemeManager:ApplyToTab(tab)
	self:CreateThemeManager(self:CreateGroupBox(tab))
end

function ThemeManager:ApplyToGroupbox(groupbox)
	self:CreateThemeManager(groupbox)
end

ThemeManager:BuildFolderTree()

return ThemeManager
