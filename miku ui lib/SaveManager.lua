local httpService = game:GetService('HttpService')

local SaveManager = {} do
	SaveManager.Folder = 'miku/rivals'
	SaveManager.Ignore = {}
	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, object) 
				return { type = 'Toggle', idx = idx, value = object.Value } 
			end,
			Load = function(idx, data)
				if Toggles[idx] then 
					pcall(function() Toggles[idx]:SetValue(data.value) end)
				end
			end,
		},
		Slider = {
			Save = function(idx, object)
				return { type = 'Slider', idx = idx, value = tostring(object.Value) }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					pcall(function() Options[idx]:SetValue(data.value) end)
				end
			end,
		},
		Dropdown = {
			Save = function(idx, object)
				return { type = 'Dropdown', idx = idx, value = object.Value, multi = object.Multi }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					pcall(function() Options[idx]:SetValue(data.value) end)
				end
			end,
		},
		ColorPicker = {
			Save = function(idx, object)
				local colHex = (typeof(object.Value) == "Color3") and object.Value:ToHex() or "FFFFFF"
				return { type = 'ColorPicker', idx = idx, value = colHex, transparency = object.Transparency or 0 }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					pcall(function() 
						Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency or 0) 
					end)
				end
			end,
		},
		KeyPicker = {
			Save = function(idx, object)
				return { type = 'KeyPicker', idx = idx, mode = object.Mode, key = object.Value }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					pcall(function() Options[idx]:SetValue({ data.key, data.mode }) end)
				end
			end,
		},
		Input = {
			Save = function(idx, object)
				return { type = 'Input', idx = idx, text = tostring(object.Value or "") }
			end,
			Load = function(idx, data)
				if Options[idx] and type(data.text) == 'string' then
					pcall(function() Options[idx]:SetValue(data.text) end)
				end
			end,
		},
	}

	function SaveManager:SetLibrary(library)
		self.Library = library
	end

	function SaveManager:SetIgnoreIndexes(list)
		for _, key in next, list do
			self.Ignore[key] = true
		end
	end

	function SaveManager:SetFolder(folder)
		self.Folder = folder;
		self:BuildFolderTree()
	end

	function SaveManager:Save(name)
		if (not name) or name:gsub(' ', '') == '' then
			return false, 'no config file name provided'
		end

		name = name:gsub('%.json$', '')
		self:BuildFolderTree()
		local fullPath = self.Folder .. '/settings/' .. name .. '.json'

		local data = {
			objects = {},
			theme = {},
			version = 2,
			savedAt = os.date("%Y-%m-%d %H:%M:%S"),
		}

		for idx, toggle in next, Toggles do
			if self.Ignore[idx] then continue end
			if self.Parser[toggle.Type] then
				local ok, parsed = pcall(self.Parser[toggle.Type].Save, idx, toggle)
				if ok and parsed then table.insert(data.objects, parsed) end
			end
		end

		for idx, option in next, Options do
			if self.Ignore[idx] then continue end
			if self.Parser[option.Type] then
				local ok, parsed = pcall(self.Parser[option.Type].Save, idx, option)
				if ok and parsed then table.insert(data.objects, parsed) end
			end
		end

		if self.Library then
			pcall(function()
				data.theme = {
					AccentColor = self.Library.AccentColor and self.Library.AccentColor:ToHex(),
					BackgroundColor = self.Library.BackgroundColor and self.Library.BackgroundColor:ToHex(),
					MainColor = self.Library.MainColor and self.Library.MainColor:ToHex(),
					OutlineColor = self.Library.OutlineColor and self.Library.OutlineColor:ToHex(),
					FontColor = self.Library.FontColor and self.Library.FontColor:ToHex(),
				}
			end)
		end

		local success, encoded = pcall(httpService.JSONEncode, httpService, data)
		if not success then
			return false, 'failed to encode data'
		end

		local writeOk, writeErr = pcall(writefile, fullPath, encoded)
		if not writeOk then
			return false, tostring(writeErr)
		end
		return true
	end

	function SaveManager:Load(name)
		if (not name) or name:gsub(' ', '') == '' then
			return false, 'no config file selected'
		end
		
		name = name:gsub('%.json$', '')
		local file = self.Folder .. '/settings/' .. name .. '.json'
		if not isfile(file) then return false, 'invalid file: ' .. file end

		local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
		if not success or type(decoded) ~= 'table' then return false, 'decode error' end

		if decoded.objects and type(decoded.objects) == 'table' then
			for _, option in next, decoded.objects do
				if option and option.type and self.Parser[option.type] then
					pcall(function() self.Parser[option.type].Load(option.idx, option) end)
				end
			end
		end

		if decoded.theme and type(decoded.theme) == 'table' and self.Library then
			pcall(function()
				if decoded.theme.AccentColor and self.Library.SetThemeColor then
					self.Library:SetThemeColor('AccentColor', Color3.fromHex(decoded.theme.AccentColor))
				end
			end)
		end

		return true
	end

	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({ 
			"BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor",
			"ThemeManager_ThemeList", 'ThemeManager_CustomThemeList', 'ThemeManager_CustomThemeName',
		})
	end

	function SaveManager:BuildFolderTree()
		local paths = {
			'miku',
			self.Folder,
			self.Folder .. '/themes',
			self.Folder .. '/settings'
		}

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				pcall(makefolder, str)
			end
		end
	end

	function SaveManager:RefreshConfigList()
		self:BuildFolderTree()
		local path = self.Folder .. '/settings'
		local ok, list = pcall(listfiles, path)
		if not ok or type(list) ~= 'table' then
			return {}
		end

		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file and (file:sub(-5):lower() == '.json') then
				local name = file:match("([^/\\]+)%.json$") or file:sub(1, -6)
				if name and name ~= "" then
					table.insert(out, name)
				end
			end
		end
		table.sort(out)
		return out
	end

	function SaveManager:GetAutoloadConfig()
		local path = self.Folder .. '/settings/autoload.txt'
		if isfile(path) then
			local ok, name = pcall(readfile, path)
			if ok and name and name:gsub(' ', '') ~= '' then
				return name:gsub('%s+', '')
			end
		end
		return 'none'
	end

	function SaveManager:SaveAutoloadConfig(name)
		if not name or name:gsub(' ', '') == '' then return false, 'invalid name' end
		name = name:gsub('%.json$', ''):gsub('%s+', '')
		self:BuildFolderTree()
		local ok, err = pcall(writefile, self.Folder .. '/settings/autoload.txt', name)
		if not ok then return false, tostring(err) end
		if self.AutoloadLabel and self.AutoloadLabel.SetText then
			pcall(self.AutoloadLabel.SetText, self.AutoloadLabel, 'autoload: ' .. name)
		end
		return true
	end

	function SaveManager:DeleteAutoLoadConfig()
		local path = self.Folder .. '/settings/autoload.txt'
		if isfile(path) then
			pcall(delfile, path)
		end
		if self.AutoloadLabel and self.AutoloadLabel.SetText then
			pcall(self.AutoloadLabel.SetText, self.AutoloadLabel, 'autoload: none')
		end
		return true
	end

	function SaveManager:Delete(name)
		if not name or name:gsub(' ', '') == '' then return false, 'no name' end
		name = name:gsub('%.json$', '')
		local fullPath = self.Folder .. '/settings/' .. name .. '.json'
		if isfile(fullPath) then
			local ok, err = pcall(delfile, fullPath)
			if ok then return true else return false, tostring(err) end
		end
		return false, 'file does not exist'
	end

	function SaveManager:LoadAutoloadConfig()
		local path = self.Folder .. '/settings/autoload.txt'
		if isfile(path) then
			local ok, name = pcall(readfile, path)
			if ok and name and name:gsub(' ', '') ~= '' then
				name = name:gsub('%s+', '')
				local success, err = self:Load(name)
				if not success then
					if self.Library and self.Library.Notify then
						return self.Library:Notify('Failed to load autoload config: ' .. tostring(err))
					end
					return
				end
				if self.Library and self.Library.Notify then
					self.Library:Notify(string.format('Auto loaded config %q', name))
				end
			end
		end
	end

	function SaveManager:BuildConfigSection(tab)
		assert(self.Library, 'Must set SaveManager.Library')

		local section = tab:AddLeftGroupbox('configs')

		section:AddInput('SaveManager_ConfigName', { Text = 'config name', Placeholder = 'my config' })
		section:AddDropdown('SaveManager_ConfigList', { Text = 'saved configs', Values = self:RefreshConfigList(), AllowNull = true })

		section:AddDivider()

		section:AddButton('load config', function()
			local name = Options.SaveManager_ConfigList and Options.SaveManager_ConfigList.Value
			if not name or name == "" then
				name = Options.SaveManager_ConfigName and Options.SaveManager_ConfigName.Value
			end
			if not name or name:gsub(' ', '') == '' then
				return self.Library:Notify('No config selected or entered to load', 3)
			end
			local success, err = self:Load(name)
			if not success then
				return self.Library:Notify('Failed to load config: ' .. tostring(err), 3)
			end
			self.Library:Notify(string.format('Loaded config %q', name), 3)
		end):AddButton('save config', function()
			local name = Options.SaveManager_ConfigName and Options.SaveManager_ConfigName.Value
			if not name or name:gsub(' ', '') == '' then
				name = Options.SaveManager_ConfigList and Options.SaveManager_ConfigList.Value
			end
			if not name or name:gsub(' ', '') == '' then 
				return self.Library:Notify('Enter a config name to save', 3)
			end

			local success, err = self:Save(name)
			if not success then
				return self.Library:Notify('Failed to save config: ' .. tostring(err), 3)
			end

			self.Library:Notify(string.format('Saved config %q', name), 3)
			if Options.SaveManager_ConfigList then
				Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
				Options.SaveManager_ConfigList:SetValue(name)
			end
		end)

		section:AddButton('overwrite config', function()
			local name = Options.SaveManager_ConfigList and Options.SaveManager_ConfigList.Value
			if not name or name == "" then
				name = Options.SaveManager_ConfigName and Options.SaveManager_ConfigName.Value
			end
			if not name or name:gsub(' ', '') == '' then
				return self.Library:Notify('No config selected to overwrite', 3)
			end

			local success, err = self:Save(name)
			if not success then
				return self.Library:Notify('Failed to overwrite config: ' .. tostring(err), 3)
			end

			self.Library:Notify(string.format('Overwrote config %q', name), 3)
		end):AddButton('delete config', function()
			local name = Options.SaveManager_ConfigList and Options.SaveManager_ConfigList.Value
			if not name or name == "" then
				name = Options.SaveManager_ConfigName and Options.SaveManager_ConfigName.Value
			end
			if not name or name:gsub(' ', '') == '' then
				return self.Library:Notify('No config selected to delete', 3)
			end

			local success, err = self:Delete(name)
			if not success then
				return self.Library:Notify('Failed to delete config: ' .. tostring(err), 3)
			end

			self.Library:Notify(string.format('Deleted config %q', name), 3)
			if Options.SaveManager_ConfigList then
				Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
				Options.SaveManager_ConfigList:SetValue(nil)
			end
		end)

		section:AddButton('refresh config list', function()
			if Options.SaveManager_ConfigList then
				local list = self:RefreshConfigList()
				Options.SaveManager_ConfigList:SetValues(list)
				self.Library:Notify(string.format('Refreshed config list (%d found)', #list), 2)
			end
		end)

		section:AddDivider()

		section:AddButton('set as autoload', function()
			local name = Options.SaveManager_ConfigList and Options.SaveManager_ConfigList.Value
			if not name or name == "" then
				name = Options.SaveManager_ConfigName and Options.SaveManager_ConfigName.Value
			end
			if not name or name:gsub(' ', '') == '' then
				return self.Library:Notify('No config selected to set as autoload', 3)
			end
			local ok, err = self:SaveAutoloadConfig(name)
			if ok then
				self.Library:Notify(string.format('Set %q as autoload', name), 3)
			else
				self.Library:Notify('Failed to set autoload: ' .. tostring(err), 3)
			end
		end):AddButton('reset autoload', function()
			self:DeleteAutoLoadConfig()
			self.Library:Notify('Reset autoload config to none', 3)
		end)

		SaveManager.AutoloadLabel = section:AddLabel('autoload: ' .. self:GetAutoloadConfig(), true)

		SaveManager:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName' })
	end

	SaveManager.ApplyToTab = SaveManager.BuildConfigSection

	SaveManager:BuildFolderTree()
end

return SaveManager
