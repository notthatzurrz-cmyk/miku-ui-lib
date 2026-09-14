local httpService = game:GetService('HttpService')

local function EnvTable(name)
	if type(getgenv) == 'function' then
		local ok, env = pcall(getgenv)
		if ok and type(env) == 'table' and type(env[name]) == 'table' then
			return env[name]
		end
	end
	return nil
end

local function ValuesMatch(a, b)
	if a == b then
		return true
	end
	if type(a) == 'number' or type(b) == 'number' then
		return tonumber(a) == tonumber(b)
	end
	if type(a) ~= 'table' or type(b) ~= 'table' then
		return false
	end
	for k, v in next, a do
		if not ValuesMatch(v, b[k]) then
			return false
		end
	end
	for k in next, b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

local SaveManager = {} do
	SaveManager.Folder = 'LinoriaLibSettings'
	SaveManager.Ignore = {}
	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, object) 
				return { type = 'Toggle', idx = idx, value = object.Value } 
			end,
			Load = function(idx, data)
				local toggles = EnvTable('Toggles')
				local toggle = toggles and toggles[idx]
				if toggle and toggle.Value ~= (data.value == true) then
					toggle:SetValue(data.value)
				end
			end,
		},
		Slider = {
			Save = function(idx, object)
				return { type = 'Slider', idx = idx, value = tostring(object.Value) }
			end,
			Load = function(idx, data)
				local options = EnvTable('Options')
				local option = options and options[idx]
				if option and tonumber(option.Value) ~= tonumber(data.value) then
					option:SetValue(data.value)
				end
			end,
		},
		Dropdown = {
			Save = function(idx, object)
				return { type = 'Dropdown', idx = idx, value = object.Value, mutli = object.Multi }
			end,
			Load = function(idx, data)
				local options = EnvTable('Options')
				local option = options and options[idx]
				if option and not ValuesMatch(option.Value, data.value) then
					option:SetValue(data.value)
				end
			end,
		},
		ColorPicker = {
			Save = function(idx, object)
				local hex = 'ffffff'
				local value = object and object.Value
				if typeof(value) == 'Color3' then
					local ok, encoded = pcall(function()
						return value:ToHex()
					end)
					if ok and type(encoded) == 'string' then
						hex = encoded
					end
				elseif type(value) == 'string' and value ~= '' then
					hex = value:gsub('^#', '')
				end
				return { type = 'ColorPicker', idx = idx, value = hex, transparency = tonumber(object and object.Transparency) or 0 }
			end,
			Load = function(idx, data)
				local options = EnvTable('Options')
				local option = options and options[idx]
				if not option or type(option.SetValueRGB) ~= 'function' then
					return
				end
				local hex = type(data.value) == 'string' and data.value:gsub('^#', '') or 'ffffff'
				local wantTransparency = tonumber(data.transparency) or 0
				local currentHex
				if typeof(option.Value) == 'Color3' then
					local okHex, encoded = pcall(function()
						return option.Value:ToHex()
					end)
					if okHex then
						currentHex = encoded
					end
				end
				if currentHex == hex and (tonumber(option.Transparency) or 0) == wantTransparency then
					return
				end
				local ok, color = pcall(Color3.fromHex, hex)
				if ok and typeof(color) == 'Color3' then
					option:SetValueRGB(color, wantTransparency)
				end
			end,
		},
		GradientPicker = {
			Save = function(idx, object)
				local colors = object.Value or {}
				local hexes = {}
				for i = 1, 3 do
					local color = colors[i]
					hexes[i] = typeof(color) == 'Color3' and color:ToHex() or 'ffffff'
				end
				return { type = 'GradientPicker', idx = idx, colors = hexes }
			end,
			Load = function(idx, data)
				local options = EnvTable('Options')
				local option = options and options[idx]
				if option and type(option.SetValue) == 'function' then
					option:SetValue(data.colors or data.value)
				end
			end,
		},
		KeyPicker = {
			Save = function(idx, object)
				return {
					type = 'KeyPicker',
					idx = idx,
					mode = object.Mode or object.FactoryMode,
					key = object.Value,
					toggled = object.Toggled == true,
				}
			end,
			Load = function(idx, data)
				local options = EnvTable('Options')
				local option = options and options[idx]
				if not option then
					return
				end
				if option.Value ~= data.key or option.Mode ~= data.mode then
					option:SetValue({ data.key, data.mode })
				end
				if data.toggled ~= nil then
					option.Toggled = data.toggled == true
				end
			end,
		},

		Input = {
			Save = function(idx, object)
				return { type = 'Input', idx = idx, text = object.Value }
			end,
			Load = function(idx, data)
				local options = EnvTable('Options')
				local option = options and options[idx]
				if option and type(data.text) == 'string' and option.Value ~= data.text then
					option:SetValue(data.text)
				end
			end,
		},
	}

	function SaveManager:SetIgnoreIndexes(list)
		for _, key in next, list do
			self.Ignore[key] = true
		end
	end

	function SaveManager:SetFolder(folder)
		self.Folder = folder;
		self:BuildFolderTree()
	end

	function SaveManager:GetConfigPath(name)
		if not name or name == '' then
			return nil
		end
		local folder = self.Folder or 'yuno'
		local candidates = {
			folder .. '/settings/' .. name .. '.json',
			folder .. '/Configs/' .. name .. '.json',
			folder .. '/' .. name .. '.json',
		}
		for i = 1, #candidates do
			local path = candidates[i]
			local ok, exists = pcall(function()
				return type(isfile) == 'function' and isfile(path)
			end)
			if ok and exists then
				return path
			end
		end
		return folder .. '/settings/' .. name .. '.json'
	end

	function SaveManager:ReadAutoloadName()
		local folder = self.Folder or 'yuno'
		local candidates = {
			folder .. '/settings/autoload.txt',
			folder .. '/Autoload.txt',
			folder .. '/settings/Autoload.txt',
			folder .. '/Configs/Autoload.txt',
		}
		for i = 1, #candidates do
			local path = candidates[i]
			local ok, exists = pcall(function()
				return type(isfile) == 'function' and isfile(path)
			end)
			if ok and exists then
				local readOk, raw = pcall(readfile, path)
				if readOk and type(raw) == 'string' then
					local name = raw:match('^%s*(.-)%s*$')
					if name and name ~= '' then
						return name:gsub('%.[jJ][sS][oO][nN]$', '')
					end
				end
			end
		end
		return nil
	end

	function SaveManager:ResolveActiveConfigName()
		if type(self.ActiveConfig) == 'string' and self.ActiveConfig ~= '' then
			return self.ActiveConfig
		end
		local options = EnvTable('Options') or (self.Library and self.Library.Options)
		if type(options) == 'table' then
			local ids = { 'SaveManager_ConfigList', 'UILoadConfigName', 'SaveManager_ConfigName' }
			for i = 1, #ids do
				local option = options[ids[i]]
				local value = option and option.Value
				if type(value) == 'string' and value:gsub(' ', '') ~= '' then
					return value
				end
			end
		end
		local autoload = self:ReadAutoloadName()
		if autoload and autoload ~= '' then
			return autoload
		end
		return 'RIVALS'
	end

	function SaveManager:Save(name)
		name = name or self:ResolveActiveConfigName()
		if (not name) or name == '' then
			return false, 'no config file is selected'
		end

		self.ActiveConfig = name
		self:BuildFolderTree()
		local fullPath = (self.Folder or 'yuno') .. '/settings/' .. name .. '.json'

		local data = {
			objects = {}
		}

		local toggles = EnvTable('Toggles') or (self.Library and self.Library.Toggles) or {}
		local options = EnvTable('Options') or (self.Library and self.Library.Options) or {}

		for idx, toggle in next, toggles do
			if self.Ignore[idx] then continue end
			if not toggle or not toggle.Type or not self.Parser[toggle.Type] then continue end
			local ok, packed = pcall(self.Parser[toggle.Type].Save, idx, toggle)
			if ok and type(packed) == 'table' then
				table.insert(data.objects, packed)
			end
		end

		for idx, option in next, options do
			if not option or not self.Parser[option.Type] then continue end
			if self.Ignore[idx] then continue end
			local ok, packed = pcall(self.Parser[option.Type].Save, idx, option)
			if ok and type(packed) == 'table' then
				table.insert(data.objects, packed)
			end
		end	

		local success, encoded = pcall(httpService.JSONEncode, httpService, data)
		if not success then
			return false, 'failed to encode data'
		end

		if type(writefile) ~= 'function' then
			return false, 'writefile is unavailable'
		end

		local writeOk, writeErr = pcall(writefile, fullPath, encoded)
		if not writeOk then
			return false, tostring(writeErr or 'failed to write config')
		end
		return true
	end

	function SaveManager:Load(name)
		if (not name) or name == '' then
			name = self:ResolveActiveConfigName()
		end
		if (not name) or name == '' then
			return false, 'no config file is selected'
		end
		
		local file = self:GetConfigPath(name)
		if not file or not isfile or not isfile(file) then return false, 'invalid file' end

		local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
		if not success then return false, 'decode error' end
		if type(decoded) ~= 'table' or type(decoded.objects) ~= 'table' then
			return false, 'invalid file'
		end

		self.ActiveConfig = name
		local library = self.Library
		if library and type(library.BeginSilentApply) == 'function' then
			pcall(library.BeginSilentApply, library)
		elseif library then
			library.ConfigLoading = true
		end
		local ok, err = pcall(function()
			local slice = os.clock()
			local applied = 0
			local toggles = EnvTable('Toggles') or (self.Library and self.Library.Toggles) or {}
			local options = EnvTable('Options') or (self.Library and self.Library.Options) or {}
			for _, option in next, decoded.objects do
				if type(option) == 'table' and option.type and self.Parser[option.type] then
					local idx = option.idx
					if idx ~= nil and (toggles[idx] ~= nil or options[idx] ~= nil) then
						pcall(self.Parser[option.type].Load, idx, option)
						applied = applied + 1
					end
					-- Skip stale per-weapon cosmetic entries that no longer have UI
					-- controls. Applying them used to stall the client after inject.
					if applied % 120 == 0 or os.clock() - slice >= 0.05 then
						task.wait()
						slice = os.clock()
					end
				end
			end
		end)
		if library and type(library.EndSilentApply) == 'function' then
			pcall(library.EndSilentApply, library)
		elseif library then
			library.ConfigLoading = false
		end
		if not ok then
			return false, tostring(err or 'apply error')
		end

		return true
	end

	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({ 
			"BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor", -- themes
			"ThemeManager_ThemeList", 'ThemeManager_CustomThemeList', 'ThemeManager_CustomThemeName', -- themes
		})
	end

	function SaveManager:BuildFolderTree()
		local paths = {
			self.Folder,
			self.Folder .. '/themes',
			self.Folder .. '/settings'
		}

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

	function SaveManager:RefreshConfigList()
		local list = listfiles(self.Folder .. '/settings')

		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == '.json' then
				-- i hate this but it has to be done ...

				local pos = file:find('.json', 1, true)
				local start = pos

				local char = file:sub(pos, pos)
				while char ~= '/' and char ~= '\\' and char ~= '' do
					pos = pos - 1
					char = file:sub(pos, pos)
				end

				if char == '/' or char == '\\' then
					table.insert(out, file:sub(pos + 1, start - 1))
				end
			end
		end
		
		return out
	end

	function SaveManager:SetLibrary(library)
		self.Library = library
	end

	function SaveManager:LoadAutoloadConfig()
		if isfile(self.Folder .. '/settings/autoload.txt') then
			local name = readfile(self.Folder .. '/settings/autoload.txt')

			local success, err = self:Load(name)
			if not success then
				return self.Library:Notify('Failed to load autoload config: ' .. err)
			end

			self.Library:Notify(string.format('Auto loaded config %q', name))
		end
	end


	function SaveManager:BuildConfigSection(tab)
		assert(self.Library, 'Must set SaveManager.Library')

		local section = tab:AddRightGroupbox('Configuration')

		section:AddInput('SaveManager_ConfigName',    { Text = 'Config name' })
		section:AddDropdown('SaveManager_ConfigList', { Text = 'Config list', Values = self:RefreshConfigList(), AllowNull = true })

		section:AddDivider()

		section:AddButton('Create config', function()
			local name = Options.SaveManager_ConfigName.Value

			if name:gsub(' ', '') == '' then 
				return self.Library:Notify('Invalid config name (empty)', 2)
			end

			local success, err = self:Save(name)
			if not success then
				return self.Library:Notify('Failed to save config: ' .. err)
			end

			self.Library:Notify(string.format('Created config %q', name))

			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			Options.SaveManager_ConfigList:SetValue(nil)
		end):AddButton('Load config', function()
			local name = Options.SaveManager_ConfigList.Value

			local success, err = self:Load(name)
			if not success then
				return self.Library:Notify('Failed to load config: ' .. err)
			end

			self.Library:Notify(string.format('Loaded config %q', name))
		end)

		section:AddButton('Overwrite config', function()
			local name = Options.SaveManager_ConfigList.Value

			local success, err = self:Save(name)
			if not success then
				return self.Library:Notify('Failed to overwrite config: ' .. err)
			end

			self.Library:Notify(string.format('Overwrote config %q', name))
		end)

		section:AddButton('Refresh list', function()
			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			Options.SaveManager_ConfigList:SetValue(nil)
		end)

		section:AddButton('Set as autoload', function()
			local name = Options.SaveManager_ConfigList.Value
			writefile(self.Folder .. '/settings/autoload.txt', name)
			SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. name)
			self.Library:Notify(string.format('Set %q to auto load', name))
		end)

		SaveManager.AutoloadLabel = section:AddLabel('Current autoload config: none', true)

		if isfile(self.Folder .. '/settings/autoload.txt') then
			local name = readfile(self.Folder .. '/settings/autoload.txt')
			SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. name)
		end

		SaveManager:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName' })
	end

	SaveManager:BuildFolderTree()
end

return SaveManager
