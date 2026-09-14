local HttpService = game:GetService('HttpService')

local function Env(name)
	if type(getgenv) == 'function' then
		local ok, env = pcall(getgenv)
		if ok and type(env) == 'table' and type(env[name]) == 'table' then
			return env[name]
		end
	end
	return nil
end

local SaveManager = {
	Folder = 'yuno',
	Ignore = {},
	Library = nil,
	ActiveConfig = nil,
}

SaveManager.Parser = {
	Toggle = {
		Save = function(idx, object)
			return { type = 'Toggle', idx = idx, value = object.Value == true }
		end,
		Load = function(idx, data)
			local t = Env('Toggles')
			local toggle = t and t[idx]
			if toggle and toggle.Value ~= (data.value == true) then
				toggle:SetValue(data.value == true)
			end
		end,
	},
	Slider = {
		Save = function(idx, object)
			return { type = 'Slider', idx = idx, value = object.Value }
		end,
		Load = function(idx, data)
			local o = Env('Options')
			local option = o and o[idx]
			if option and tonumber(data.value) ~= nil then
				option:SetValue(tonumber(data.value))
			end
		end,
	},
	Dropdown = {
		Save = function(idx, object)
			return { type = 'Dropdown', idx = idx, value = object.Value }
		end,
		Load = function(idx, data)
			local o = Env('Options')
			local option = o and o[idx]
			if option then
				option:SetValue(data.value)
			end
		end,
	},
	ColorPicker = {
		Save = function(idx, object)
			local hex = 'ffffff'
			if typeof(object.Value) == 'Color3' then
				local ok, encoded = pcall(function()
					return object.Value:ToHex()
				end)
				if ok and type(encoded) == 'string' then
					hex = encoded
				end
			end
			return { type = 'ColorPicker', idx = idx, value = hex, transparency = tonumber(object.Transparency) or 0 }
		end,
		Load = function(idx, data)
			local o = Env('Options')
			local option = o and o[idx]
			if not option or type(option.SetValueRGB) ~= 'function' then
				return
			end
			local hex = type(data.value) == 'string' and data.value:gsub('^#', '') or 'ffffff'
			local ok, color = pcall(Color3.fromHex, hex)
			if ok and typeof(color) == 'Color3' then
				option:SetValueRGB(color, tonumber(data.transparency) or 0)
			end
		end,
	},
	GradientPicker = {
		Save = function(idx, object)
			return { type = 'GradientPicker', idx = idx, colors = object.Value }
		end,
		Load = function(idx, data)
			local o = Env('Options')
			local option = o and o[idx]
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
			local o = Env('Options')
			local option = o and o[idx]
			if not option then
				return
			end
			option:SetValue({ data.key, data.mode })
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
			local o = Env('Options')
			local option = o and o[idx]
			if option and type(data.text) == 'string' then
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

function SaveManager:IgnoreThemeSettings()
	self:SetIgnoreIndexes({
		'BackgroundColor', 'MainColor', 'AccentColor', 'OutlineColor', 'FontColor',
		'ThemeManager_ThemeList', 'ThemeManager_CustomThemeList', 'ThemeManager_CustomThemeName',
	})
end

function SaveManager:BuildFolderTree()
	local folder = self.Folder or 'yuno'
	local paths = { folder, folder .. '/themes', folder .. '/settings' }
	for i = 1, #paths do
		if type(isfolder) == 'function' and type(makefolder) == 'function' and not isfolder(paths[i]) then
			pcall(makefolder, paths[i])
		end
	end
end

function SaveManager:SetFolder(folder)
	self.Folder = folder
	self:BuildFolderTree()
end

function SaveManager:SetLibrary(library)
	self.Library = library
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
		if type(isfile) == 'function' and isfile(candidates[i]) then
			return candidates[i]
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
		if type(isfile) == 'function' and isfile(candidates[i]) then
			local ok, raw = pcall(readfile, candidates[i])
			if ok and type(raw) == 'string' then
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
	local options = Env('Options') or (self.Library and self.Library.Options)
	if type(options) == 'table' then
		for _, id in ipairs({ 'SaveManager_ConfigList', 'UILoadConfigName', 'SaveManager_ConfigName' }) do
			local option = options[id]
			local value = option and option.Value
			if type(value) == 'string' and value:gsub(' ', '') ~= '' then
				return value
			end
		end
	end
	return self:ReadAutoloadName() or 'RIVALS'
end

function SaveManager:RefreshConfigList()
	local folder = (self.Folder or 'yuno') .. '/settings'
	if type(listfiles) ~= 'function' or (type(isfolder) == 'function' and not isfolder(folder)) then
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
				out[#out + 1] = name
			end
		end
	end
	table.sort(out)
	return out
end

function SaveManager:Save(name)
	name = name or self:ResolveActiveConfigName()
	if not name or name == '' then
		return false, 'no config selected'
	end
	self.ActiveConfig = name
	self:BuildFolderTree()
	local data = { objects = {} }
	local toggles = Env('Toggles') or (self.Library and self.Library.Toggles) or {}
	local options = Env('Options') or (self.Library and self.Library.Options) or {}
	for idx, toggle in next, toggles do
		if not self.Ignore[idx] and toggle and toggle.Type and self.Parser[toggle.Type] then
			local ok, packed = pcall(self.Parser[toggle.Type].Save, idx, toggle)
			if ok and type(packed) == 'table' then
				data.objects[#data.objects + 1] = packed
			end
		end
	end
	for idx, option in next, options do
		if not self.Ignore[idx] and option and option.Type and self.Parser[option.Type] then
			local ok, packed = pcall(self.Parser[option.Type].Save, idx, option)
			if ok and type(packed) == 'table' then
				data.objects[#data.objects + 1] = packed
			end
		end
	end
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
	if not ok then
		return false, 'encode failed'
	end
	local path = (self.Folder or 'yuno') .. '/settings/' .. name .. '.json'
	local writeOk, writeErr = pcall(writefile, path, encoded)
	if not writeOk then
		return false, tostring(writeErr)
	end
	return true
end

function SaveManager:Load(name)
	name = name or self:ResolveActiveConfigName()
	if not name or name == '' then
		return false, 'no config selected'
	end
	local file = self:GetConfigPath(name)
	if not file or type(isfile) ~= 'function' or not isfile(file) then
		return false, 'invalid file'
	end
	local okDecode, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(file))
	if not okDecode or type(decoded) ~= 'table' or type(decoded.objects) ~= 'table' then
		return false, 'invalid file'
	end
	self.ActiveConfig = name
	local library = self.Library
	if library and type(library.BeginSilentApply) == 'function' then
		pcall(library.BeginSilentApply, library)
	elseif library then
		library.ConfigLoading = true
	end
	local toggles = Env('Toggles') or (library and library.Toggles) or {}
	local options = Env('Options') or (library and library.Options) or {}
	for i = 1, #decoded.objects do
		local object = decoded.objects[i]
		if type(object) == 'table' and object.type and object.idx and self.Parser[object.type] then
			if toggles[object.idx] or options[object.idx] then
				pcall(self.Parser[object.type].Load, object.idx, object)
			end
		end
	end
	if library and type(library.EndSilentApply) == 'function' then
		pcall(library.EndSilentApply, library)
	elseif library then
		library.ConfigLoading = false
	end
	return true
end

function SaveManager:LoadAutoloadConfig()
	local name = self:ReadAutoloadName()
	if not name then
		return
	end
	local success, err = self:Load(name)
	if self.Library and type(self.Library.Notify) == 'function' then
		if success then
			self.Library:Notify(string.format('Auto loaded config %q', name))
		else
			self.Library:Notify('Failed to load autoload config: ' .. tostring(err))
		end
	end
end

function SaveManager:BuildConfigSection(tab)
	assert(self.Library, 'Must set SaveManager.Library')
	local section = tab:AddRightGroupbox('Configuration')
	section:AddInput('SaveManager_ConfigName', { Text = 'Config name' })
	section:AddDropdown('SaveManager_ConfigList', { Text = 'Config list', Values = self:RefreshConfigList(), AllowNull = true })
	section:AddDivider()
	section:AddButton('Create config', function()
		local name = Options.SaveManager_ConfigName.Value
		if not name or name:gsub(' ', '') == '' then
			return self.Library:Notify('Invalid config name (empty)', 2)
		end
		local success, err = self:Save(name)
		if not success then
			return self.Library:Notify('Failed to save config: ' .. tostring(err))
		end
		Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
		self.Library:Notify(string.format('Created config %q', name))
	end):AddButton('Load config', function()
		local name = Options.SaveManager_ConfigList.Value
		local success, err = self:Load(name)
		if not success then
			return self.Library:Notify('Failed to load config: ' .. tostring(err))
		end
		self.Library:Notify(string.format('Loaded config %q', name))
	end)
	section:AddButton('Overwrite config', function()
		local name = Options.SaveManager_ConfigList.Value
		local success, err = self:Save(name)
		if not success then
			return self.Library:Notify('Failed to overwrite config: ' .. tostring(err))
		end
		self.Library:Notify(string.format('Overwrote config %q', name))
	end)
	section:AddButton('Refresh list', function()
		Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
	end)
	section:AddButton('Set as autoload', function()
		local name = Options.SaveManager_ConfigList.Value
		if type(name) ~= 'string' or name == '' then
			return
		end
		pcall(writefile, self.Folder .. '/settings/autoload.txt', name)
		if SaveManager.AutoloadLabel then
			SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. name)
		end
		self.Library:Notify(string.format('Set %q to auto load', name))
	end)
	SaveManager.AutoloadLabel = section:AddLabel('Current autoload config: none', true)
	local current = self:ReadAutoloadName()
	if current then
		SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. current)
	end
	self:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName' })
end

SaveManager:BuildFolderTree()

return SaveManager
