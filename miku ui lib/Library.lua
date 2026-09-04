local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local SoundService = game:GetService('SoundService');
local CoreGui = game:GetService('CoreGui');
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService');
local TweenService = game:GetService('TweenService');
local Lighting = game:GetService('Lighting');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
while not LocalPlayer do
    task.wait();
    LocalPlayer = Players.LocalPlayer;
end
local Mouse = LocalPlayer:GetMouse();

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = nil;

local function EnsureScreenGui()
    if not ScreenGui or not ScreenGui.Parent or not ScreenGui:IsDescendantOf(game) then
        ScreenGui = Instance.new('ScreenGui');
        pcall(function() ProtectGui(ScreenGui); end);
        ScreenGui.Name = "MikuModularGui";
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
        ScreenGui.DisplayOrder = 2147483646;
        ScreenGui.ResetOnSpawn = false;

        local Parented = false;
        if gethui then
            local okHui, Hui = pcall(gethui);
            if okHui and Hui then
                local okSet = pcall(function() ScreenGui.Parent = Hui; end);
                Parented = okSet and ScreenGui.Parent ~= nil;
            end
        end
        if not Parented then
            local okCore = pcall(function() ScreenGui.Parent = CoreGui; end);
            Parented = okCore and ScreenGui.Parent ~= nil;
        end
        if not Parented then
            pcall(function()
                local pg = LocalPlayer:FindFirstChildOfClass('PlayerGui') or LocalPlayer:WaitForChild('PlayerGui', 5);
                ScreenGui.Parent = pg or game:GetService('Players').LocalPlayer.PlayerGui;
            end);
        end
        if Library then Library.ScreenGui = ScreenGui; end
    end
    return ScreenGui;
end
EnsureScreenGui();

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

-- // Miku Liquid Glass Design Tokens
-- ====================================================================
-- CENTRALIZED THEME / DESIGN TOKEN SYSTEM
-- Modify values here to restyle the entire UI without touching code.
-- ====================================================================
local THEME = {
    -- === Colors ===
    Accent          = Color3.fromRGB(180, 145, 255);   -- Purple accent (active states, toggles)
    AccentDim       = Color3.fromRGB(130, 105, 200);   -- Dimmed accent for subtle glows
    WindowBg        = Color3.fromRGB(14, 12, 22);      -- Main window base color
    SidebarBg       = Color3.fromRGB(20, 18, 30);      -- Sidebar panel background
    CardBg          = Color3.fromRGB(22, 17, 34);      -- Feature card outer background
    CardHeader      = Color3.fromRGB(28, 22, 44);      -- Feature card header strip
    CardBody        = Color3.fromRGB(14, 11, 24);      -- Feature card expanded body
    CardActive      = Color3.fromRGB(32, 26, 52);      -- Card header when enabled
    Border          = Color3.fromRGB(68, 62, 92);      -- Default border/outline color
    BorderBright    = Color3.fromRGB(95, 82, 135);     -- Bright border for active states
    FontPrimary     = Color3.fromRGB(245, 243, 255);   -- Main text color
    FontDim         = Color3.fromRGB(150, 145, 172);   -- Dimmed text / placeholders
    FontAccent      = Color3.fromRGB(200, 180, 255);   -- Accent-colored text
    Risk            = Color3.fromRGB(255, 110, 140);   -- Red/danger color
    TabBtnActive    = Color3.fromRGB(52, 42, 80);      -- Sidebar tab button active bg
    TabBtnHover     = Color3.fromRGB(36, 30, 56);      -- Sidebar tab button hover bg
    SwitchOff       = Color3.fromRGB(40, 36, 54);      -- Toggle switch off state
    SearchBg        = Color3.fromRGB(22, 20, 32);      -- Search bar background
    ShortcutBg      = Color3.fromRGB(32, 28, 46);      -- Ctrl+F badge background

    -- === Opacity / Transparency ===
    WindowOpacity       = 0.12;    -- MainWindow BackgroundTransparency (lower = more opaque)
    SidebarOpacity      = 0.22;    -- Sidebar transparency
    CardOpacity         = 0.40;    -- Card outer transparency (LiquidGlass mode)
    CardOpacitySolid    = 0.10;    -- Card outer transparency (solid mode)
    HeaderOpacity       = 0.30;    -- Card header transparency
    BodyOpacity         = 0.52;    -- Card body transparency
    BorderOpacity       = 0.55;    -- Default border transparency
    SheenOpacity        = 0.87;    -- Glass sheen transparency
    ShadowOpacity       = 0.42;    -- Drop shadow transparency
    SearchOpacity       = 0.30;    -- Search bar transparency

    -- === Blur ===
    BlurEnabled     = true;
    BlurSize        = 22;          -- Background blur size (0-30)

    -- === Spacing ===
    CardPadding     = 10;          -- Gap between cards (px)
    ContentPadding  = 8;           -- Gap between content elements inside cards (px)
    SidebarW        = 68;          -- Collapsed sidebar width
    SidebarExpandedW = 182;        -- Expanded sidebar width
    TabBtnSize      = 46;          -- Tab button height+width when collapsed

    -- === Animation Speed ===
    -- Multiply TI_ durations by this. 1.0 = default, 0.5 = twice as fast, 2.0 = slower.
    AnimSpeed       = 1.0;
    HoverIntensity  = 1.0;         -- Multiply hover brightness delta by this
};

local RADIUS = {
    Window = 20;
    Sidebar = 16;
    Groupbox = 14;
    Card = 10;
    Control = 8;
    Small = 6;
    Pill = 10;
    Switch = 10;
};

local TI_FAST   = TweenInfo.new(0.12, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out);
local TI_SMOOTH = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out);
local TI_SOFT   = TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out);
local TI_POP    = TweenInfo.new(0.16, Enum.EasingStyle.Back,  Enum.EasingDirection.Out);
local TI_SPRING = TweenInfo.new(0.28, Enum.EasingStyle.Back,  Enum.EasingDirection.Out);

-- ====================================================================
-- MASTER SOUND & UI AUDIO ENGINE
-- ====================================================================
local SoundEngine = {
    Enabled = true,
    Volume = 0.6,
    Preset = "Modern Click",
    Sounds = {
        ["Modern Click"] = {
            click = "rbxassetid://6895079853",
            toggle = "rbxassetid://6895079853",
            expand = "rbxassetid://6895079853",
            pitch = 1.0,
        },
        ["Soft Pop"] = {
            click = "rbxassetid://6895079853",
            toggle = "rbxassetid://6895079853",
            expand = "rbxassetid://6895079853",
            pitch = 1.38,
        },
        ["Cyber Tick"] = {
            click = "rbxassetid://6895079853",
            toggle = "rbxassetid://6895079853",
            expand = "rbxassetid://6895079853",
            pitch = 1.68,
        },
        ["Mechanical Switch"] = {
            click = "rbxassetid://6895079853",
            toggle = "rbxassetid://6895079853",
            expand = "rbxassetid://6895079853",
            pitch = 0.72,
        },
        ["Sci-Fi Beep"] = {
            click = "rbxassetid://3398620867",
            toggle = "rbxassetid://3398620867",
            expand = "rbxassetid://3398620867",
            pitch = 1.0,
        },
    },
};

function SoundEngine:Play(soundType)
    if not self.Enabled or self.Volume <= 0 then return end
    local presetData = self.Sounds[self.Preset] or self.Sounds["Modern Click"];
    local soundId = presetData[soundType] or presetData.click;
    if not soundId or soundId == "" then return end

    task.spawn(function()
        local basePitch = presetData.pitch or 1.0;
        local typePitch = (soundType == "toggle" and 1.1 or (soundType == "expand" and 0.92 or 1.0));
        local snd = Instance.new("Sound");
        snd.SoundId = soundId;
        snd.Volume = self.Volume;
        snd.PlaybackSpeed = basePitch * typePitch;
        snd.Parent = SoundService or ScreenGui;
        snd:Play();
        snd.Ended:Connect(function() snd:Destroy(); end);
        task.delay(1.5, function() if snd and snd.Parent then snd:Destroy(); end end);
    end);
end

local Library = {
    Registry = {};
    RegistryMap = {};
    HudRegistry = {};

    FontColor = THEME.FontPrimary;
    MainColor = Color3.fromRGB(28, 26, 40);
    BackgroundColor = THEME.WindowBg;
    AccentColor = THEME.Accent;
    OutlineColor = THEME.Border;
    RiskColor = THEME.Risk;
    DimColor = THEME.FontDim;

    Black = Color3.new(0, 0, 0);
    Font = Enum.Font.GothamMedium;

    OpenedFrames = {};
    DependencyBoxes = {};
    Signals = {};
    ScreenGui = ScreenGui;
    Toggled = true;
    Windows = {};
    Tabs = {};
    UseBlur = THEME.BlurEnabled;
    BlurSize = THEME.BlurSize;
    Toggles = Toggles;
    Options = Options;
    Radius = RADIUS;
    Theme = THEME;
    CurrentSearchQuery = "";
    ActiveTab = nil;

    -- Liquid Glass Settings
    GlobalOpacity = 0.85; -- 0.1 to 1.0 (Controls main window opacity)
    FrostVeil = 0.35;     -- Card background transparency
    LiquidGlass = true;   -- Enables gloss sheens and reflections
    SoundEngine = SoundEngine;
};

function Library:PlaySound(soundType) SoundEngine:Play(soundType); end
function Library:SetMenuSounds(enabled) SoundEngine.Enabled = (enabled == true); end
function Library:SetSoundVolume(vol) SoundEngine.Volume = math.clamp(vol or 0.6, 0, 1); end
function Library:SetSoundPreset(preset) if SoundEngine.Sounds[preset] then SoundEngine.Preset = preset; end end

-- Background Blur
local BlurEffect;
pcall(function()
    BlurEffect = Lighting:FindFirstChild("MikuUiBlur");
    if not BlurEffect then
        BlurEffect = Instance.new("BlurEffect");
        BlurEffect.Name = "MikuUiBlur";
        BlurEffect.Size = 0;
        BlurEffect.Enabled = false;
        BlurEffect.Parent = Lighting;
    end
end);
Library.BlurEffect = BlurEffect;

function Library:SetBlur(enabled)
    if not BlurEffect then return end
    if enabled and Library.UseBlur then
        BlurEffect.Enabled = true;
        TweenService:Create(BlurEffect, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = Library.BlurSize or 18
        }):Play();
    else
        local tween = TweenService:Create(BlurEffect, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = 0
        });
        tween:Play();
        task.delay(0.25, function()
            if not Library.Toggled or not Library.UseBlur then
                BlurEffect.Enabled = false;
            end
        end);
    end
end

function Library:UpdateBlur()
    if not BlurEffect then return end
    if Library.Toggled and Library.UseBlur then
        BlurEffect.Enabled = true;
        BlurEffect.Size = Library.BlurSize or 18;
    else
        BlurEffect.Enabled = false;
        BlurEffect.Size = 0;
    end
end

function Library:SetGlobalOpacity(opacity)
    Library.GlobalOpacity = math.clamp(opacity or 0.85, 0.05, 1);
    local targetTrans = 1 - Library.GlobalOpacity;
    if Library.Window and Library.Window.Holder then
        TweenService:Create(Library.Window.Holder, TI_SMOOTH, {
            BackgroundTransparency = math.clamp(targetTrans + 0.1, 0, 0.95)
        }):Play();
    end
    if Library.Sidebar then
        TweenService:Create(Library.Sidebar, TI_SMOOTH, {
            BackgroundTransparency = math.clamp(targetTrans + 0.15, 0, 0.95)
        }):Play();
    end
    if Library.Window and Library.Window.Tabs then
        for _, tab in ipairs(Library.Window.Tabs) do
            if tab.Groupboxes then
                for _, card in pairs(tab.Groupboxes) do
                    if card.Outer then
                        TweenService:Create(card.Outer, TI_SMOOTH, {
                            BackgroundTransparency = math.clamp(targetTrans + 0.15, 0, 0.95)
                        }):Play();
                    end
                    if card.Header then
                        TweenService:Create(card.Header, TI_SMOOTH, {
                            BackgroundTransparency = math.clamp(targetTrans + 0.08, 0, 0.92)
                        }):Play();
                    end
                    if card.Container then
                        TweenService:Create(card.Container, TI_SMOOTH, {
                            BackgroundTransparency = math.clamp(targetTrans + 0.18, 0, 0.96)
                        }):Play();
                    end
                end
            end
        end
    end
end

function Library:SetFrostBlur(val)
    Library.BlurSize = math.clamp(val or 18, 0, 30);
    Library.UseBlur = (Library.BlurSize > 0);
    if BlurEffect then
        BlurEffect.Enabled = (Library.BlurSize > 0) and (Library.Toggled ~= false);
        TweenService:Create(BlurEffect, TI_SMOOTH, { Size = Library.BlurSize }):Play();
    end
end

function Library:SetFrostVeil(val)
    Library.FrostVeil = math.clamp(val or 0.35, 0, 1);
    if Library.Window and Library.Window.Tabs then
        for _, tab in ipairs(Library.Window.Tabs) do
            if tab.Groupboxes then
                for _, card in pairs(tab.Groupboxes) do
                    if card.Outer then
                        TweenService:Create(card.Outer, TI_SMOOTH, {
                            BackgroundTransparency = math.clamp(Library.FrostVeil, 0, 0.95)
                        }):Play();
                    end
                    if card.Container then
                        TweenService:Create(card.Container, TI_SMOOTH, {
                            BackgroundTransparency = math.clamp(Library.FrostVeil + 0.1, 0, 0.95)
                        }):Play();
                    end
                end
            end
        end
    end
end

function Library:SetLiquidGlass(enabled)
    Library.LiquidGlass = (enabled == true);
    if Library.LiquidGlass then
        if Library.Window and Library.Window.Holder then
            TweenService:Create(Library.Window.Holder, TI_SMOOTH, {
                BackgroundColor3 = Color3.fromRGB(16, 12, 28),
                BackgroundTransparency = 0.52,
            }):Play();
        end
        if Library.Sidebar then
            TweenService:Create(Library.Sidebar, TI_SMOOTH, {
                BackgroundColor3 = Color3.fromRGB(20, 15, 34),
                BackgroundTransparency = 0.45,
            }):Play();
        end
        if Library.WindowSheen then
            Library.WindowSheen.Visible = true;
            TweenService:Create(Library.WindowSheen, TI_SMOOTH, { BackgroundTransparency = 0.82 }):Play();
        end
        if Library.Window and Library.Window.Tabs then
            for _, tab in ipairs(Library.Window.Tabs) do
                if tab.Groupboxes then
                    for _, card in pairs(tab.Groupboxes) do
                        if card.Outer then
                            TweenService:Create(card.Outer, TI_SMOOTH, {
                                BackgroundColor3 = Color3.fromRGB(24, 18, 40),
                                BackgroundTransparency = 0.45,
                            }):Play();
                        end
                        if card.Header then
                            TweenService:Create(card.Header, TI_SMOOTH, {
                                BackgroundColor3 = Color3.fromRGB(32, 24, 52),
                                BackgroundTransparency = 0.3,
                            }):Play();
                        end
                        if card.Container then
                            TweenService:Create(card.Container, TI_SMOOTH, {
                                BackgroundColor3 = Color3.fromRGB(14, 10, 24),
                                BackgroundTransparency = 0.5,
                            }):Play();
                        end
                        local sheen = card.Outer and card.Outer:FindFirstChild('Sheen');
                        if sheen then
                            sheen.Visible = true;
                            sheen.BackgroundTransparency = 0.8;
                        end
                    end
                end
            end
        end
        Library:SetFrostBlur(24);
    else
        if Library.Window and Library.Window.Holder then
            TweenService:Create(Library.Window.Holder, TI_SMOOTH, {
                BackgroundColor3 = Color3.fromRGB(18, 16, 26),
                BackgroundTransparency = 0.1,
            }):Play();
        end
        if Library.Sidebar then
            TweenService:Create(Library.Sidebar, TI_SMOOTH, {
                BackgroundColor3 = Color3.fromRGB(22, 20, 32),
                BackgroundTransparency = 0.12,
            }):Play();
        end
        if Library.WindowSheen then
            Library.WindowSheen.Visible = false;
        end
        if Library.Window and Library.Window.Tabs then
            for _, tab in ipairs(Library.Window.Tabs) do
                if tab.Groupboxes then
                    for _, card in pairs(tab.Groupboxes) do
                        if card.Outer then
                            TweenService:Create(card.Outer, TI_SMOOTH, {
                                BackgroundColor3 = Color3.fromRGB(20, 18, 28),
                                BackgroundTransparency = 0.12,
                            }):Play();
                        end
                        if card.Header then
                            TweenService:Create(card.Header, TI_SMOOTH, {
                                BackgroundColor3 = Color3.fromRGB(26, 24, 36),
                                BackgroundTransparency = 0.05,
                            }):Play();
                        end
                        if card.Container then
                            TweenService:Create(card.Container, TI_SMOOTH, {
                                BackgroundColor3 = Color3.fromRGB(15, 13, 22),
                                BackgroundTransparency = 0.1,
                            }):Play();
                        end
                        local sheen = card.Outer and card.Outer:FindFirstChild('Sheen');
                        if sheen then sheen.Visible = false; end
                    end
                end
            end
        end
        Library:SetFrostBlur(14);
    end
end

local RainbowStep = 0;
local Hue = 0;

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta;
    if RainbowStep >= (1 / 60) then
        RainbowStep = 0;
        Hue = Hue + (1 / 400);
        if Hue > 1 then Hue = 0; end
        Library.CurrentRainbowHue = Hue;
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
    end
end));

local function Tween(instance, info, properties)
    if not instance or not info or not properties then return nil end
    local tween = TweenService:Create(instance, info, properties);
    tween:Play();
    return tween;
end

local function GetPlayersString()
    local PlayerList = Players:GetPlayers();
    for i = 1, #PlayerList do
        PlayerList[i] = PlayerList[i].Name;
    end
    table.sort(PlayerList, function(str1, str2) return str1 < str2 end);
    return PlayerList;
end

local function GetTeamsString()
    local TeamList = Teams:GetTeams();
    for i = 1, #TeamList do
        TeamList[i] = TeamList[i].Name;
    end
    table.sort(TeamList, function(str1, str2) return str1 < str2 end);
    return TeamList;
end

function Library:SafeCallback(f, ...)
    if not f then return end
    local success, event = pcall(f, ...);
    if not success and Library.NotifyOnError then
        local _, i = tostring(event):find(":%d+: ");
        if not i then return Library:Notify(tostring(event)); end
        return Library:Notify(tostring(event):sub(i + 1), 3);
    end
end

function Library:AttemptSave()
    if Library.SaveManager then
        pcall(function() Library.SaveManager:Save(); end);
    end
end

function Library:Create(Class, Properties)
    local Instance = Instance.new(Class);
    for Property, Value in next, Properties do
        Instance[Property] = Value;
    end
    return Instance;
end

function Library:IsPointerInput(Input)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.MouseButton2
        or Input.UserInputType == Enum.UserInputType.MouseButton3
        or Input.UserInputType == Enum.UserInputType.Touch;
end

function Library:ApplyTextStroke(Inst)
    if not Inst or not Inst:IsA('TextLabel') then return end
    local stroke = Inst:FindFirstChildOfClass('UIStroke');
    if not stroke then
        stroke = Instance.new('UIStroke');
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual;
        stroke.Color = Library.TextOutlineColor or Color3.fromRGB(0, 0, 0);
        stroke.Transparency = (Library.TextOutline == false) and 1 or 0;
        stroke.Thickness = 1;
        stroke.Parent = Inst;
    end
    return stroke;
end

function Library:CreateLabel(Properties, IsHud)
    local _Properties = {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Library.FontColor;
        TextSize = 12;
        TextStrokeTransparency = 1;
    };
    for Property, Value in next, Properties do
        _Properties[Property] = Value;
    end
    local Label = Library:Create('TextLabel', _Properties);
    Library:AddToRegistry(Label, { TextColor3 = 'FontColor' }, IsHud);
    Library:ApplyTextStroke(Label);
    return Label;
end

function Library:AddShadow(Target, Expand, Transparency, ZIndex)
    local Shadow = Library:Create('ImageLabel', {
        Name = 'DropShadow',
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, Expand or 24, 1, Expand or 24),
        BackgroundTransparency = 1,
        Image = 'rbxassetid://6015897843',
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = Transparency or 0.45,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ScaleType = Enum.ScaleType.Slice,
        SliceScale = 1,
        ZIndex = ZIndex or (Target.ZIndex - 1),
        Parent = Target,
    });
    return Shadow;
end

function Library:MakeDraggable(Instance, DragHandle)
    local handle = DragHandle or Instance;
    local dragging = false;
    local dragStart = Vector3.zero;
    local startPos = UDim2.new();

    local function StartDragging(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
            dragging = true;
            Library.IsDragging = true;
            dragStart = input.Position;
            startPos = Instance.Position;
        end
    end

    local function AttachToChild(child)
        if child:IsA("GuiObject") and not child:IsA("TextButton") and not child:IsA("ImageButton") and not child:IsA("TextBox") then
            pcall(function()
                child.InputBegan:Connect(StartDragging);
            end);
        end
    end

    pcall(function()
        handle.InputBegan:Connect(StartDragging);
    end);
    for _, child in ipairs(handle:GetDescendants()) do
        AttachToChild(child);
    end
    handle.DescendantAdded:Connect(AttachToChild);

    Library:GiveSignal(InputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false;
                Library.IsDragging = false;
                if WebManager then WebManager:Update(); end
            end
        end
    end));

    Library:GiveSignal(InputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart;
            local targetX = startPos.X.Offset + delta.X;
            local targetY = startPos.Y.Offset + delta.Y;

            local cam = workspace.CurrentCamera;
            if cam and cam.ViewportSize.X > 0 then
                local vpX = cam.ViewportSize.X;
                local vpY = cam.ViewportSize.Y;
                local winW = (Instance.AbsoluteSize.X > 0) and Instance.AbsoluteSize.X or (Instance.Size.X.Offset > 0 and Instance.Size.X.Offset or 880);
                local winH = (Instance.AbsoluteSize.Y > 0) and Instance.AbsoluteSize.Y or (Instance.Size.Y.Offset > 0 and Instance.Size.Y.Offset or 540);
                targetX = math.clamp(targetX, 6, math.max(6, vpX - winW - 6));
                targetY = math.clamp(targetY, 6, math.max(6, vpY - winH - 6));
            end

            Instance.Position = UDim2.new(
                startPos.X.Scale,
                targetX,
                startPos.Y.Scale,
                targetY
            );
            if WebManager then WebManager:Update(); end
        end
    end));
end

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 12);
    local Tooltip = Library:Create('CanvasGroup', {
        GroupTransparency = 1;
        BackgroundColor3 = Library.BackgroundColor,
        Size = UDim2.fromOffset(X + 16, Y + 10),
        ZIndex = 6000,
        Visible = false,
        Parent = ScreenGui,
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Control), Parent = Tooltip });
    Library:Create('UIStroke', { Color = Library.OutlineColor, Thickness = 1, Parent = Tooltip });

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(8, 5),
        Size = UDim2.fromOffset(X, Y),
        TextSize = 12,
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6001,
        Parent = Tooltip,
    });

    local IsHovering = false;
    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then return end
        IsHovering = true;
        Tooltip.Position = UDim2.fromOffset(Mouse.X + 16, Mouse.Y + 12);
        Tooltip.Visible = true;
        Tween(Tooltip, TI_FAST, { GroupTransparency = 0 });
        while IsHovering do
            RunService.Heartbeat:Wait();
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 16, Mouse.Y + 12);
        end
    end);

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false;
        Tooltip.Visible = false;
    end);
end

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        if Frame and Frame.Parent and Frame.Visible then
            local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
            if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
                and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
                return true;
            end
        end
    end
    return false;
end

function Library:IsMouseOverFrame(Frame)
    if not Frame or not Frame.Parent then return false end
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
    if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
                and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
        return true;
    end
    return false;
end

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        if Depbox and Depbox.Update then Depbox:Update(); end
    end
end

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    if MaxA == MinA then return MinB end
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local TextStr = tostring(Text);
    local ok, X, Y = pcall(function()
        local Bounds = TextService:GetTextSize(TextStr, Size, Font or Library.Font, Resolution or Vector2.new(1920, 1080));
        return Bounds.X, Bounds.Y;
    end);
    if ok and X and X > 0 then return X, Y end
    return math.max(#TextStr * 7, 8), math.max(Size or 12, 12);
end

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 1.5);
end
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1;
    local Data = { Instance = Instance, Properties = Properties, Idx = Idx };
    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;
    if IsHud then table.insert(Library.HudRegistry, Data); end
end

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];
    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then table.remove(Library.Registry, Idx); end
        end
        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then table.remove(Library.HudRegistry, Idx); end
        end
        Library.RegistryMap[Instance] = nil;
    end
end

function Library:UpdateColorsUsingRegistry()
    for _, Object in next, Library.Registry do
        if Object.Instance and Object.Instance.Parent then
            for Property, ColorIdx in next, Object.Properties do
                if type(ColorIdx) == 'string' then
                    Object.Instance[Property] = Library[ColorIdx];
                elseif type(ColorIdx) == 'function' then
                    Object.Instance[Property] = ColorIdx();
                end
            end
        end
    end
end

function Library:SetAccentColor(Color)
    if not Color then return end
    Library.AccentColor = Color;
    Library.AccentColorDark = Library:GetDarkerColor(Color);
    Library:UpdateColorsUsingRegistry();
    if Library.ActiveTab and Library.ActiveTab.RefreshPill then
        Library.ActiveTab:RefreshPill(false);
    end
end

function Library:GiveSignal(Signal)
    table.insert(Library.Signals, Signal);
end

function Library:Unload()
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx);
        pcall(function() Connection:Disconnect(); end);
    end
    if Library.OnUnload then pcall(Library.OnUnload); end
    if BlurEffect then pcall(function() BlurEffect:Destroy(); end); end
    if getgenv()._MikuStudioGui then pcall(function() getgenv()._MikuStudioGui:Destroy(); end); end
    ScreenGui:Destroy();
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback;
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then Library:RemoveFromRegistry(Instance); end
end));

local BaseAddons = {};
local BaseGroupbox = {};

do
    local Funcs = {};

    function Funcs:AddColorPicker(Idx, Info)
        Info = Info or {};
        assert(Info.Default, 'AddColorPicker: Missing default value.');

        local targetParent = nil;
        local isDirectGroupbox = (self and self.Container and self.Type ~= 'Toggle' and self.Type ~= 'Slider' and self.Type ~= 'Dropdown');

        if isDirectGroupbox then
            local Row = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 24),
                ZIndex = 2,
                Parent = self.Container,
            });
            local Label = Library:CreateLabel({
                Size = UDim2.new(1, -50, 1, 0),
                Position = UDim2.new(0, 4, 0, 0),
                TextSize = 12,
                Text = Info.Title or Info.Text or 'Color picker',
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Color3.fromRGB(205, 200, 225),
                ZIndex = 3,
                Parent = Row,
            });
            local SwatchHolder = Library:Create('Frame', {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -4, 0.5, 0),
                Size = UDim2.fromOffset(24, 16),
                BackgroundTransparency = 1,
                ZIndex = 4,
                Parent = Row,
            });
            targetParent = SwatchHolder;
            if self.AddBlank then self:AddBlank(2); end
            if self.Resize then self:Resize(); end
        else
            local foundAddons = (self and self.RightAddons) 
                or (self and self.Outer and (self.Outer:FindFirstChild('RightAddons', true) or self.Outer:FindFirstChild('HeaderRight', true)))
                or (self and self.Groupbox and self.Groupbox.HeaderRight)
                or (self and self.TextLabel and self.TextLabel.Parent and self.TextLabel.Parent:FindFirstChild('RightAddons'));

            targetParent = foundAddons or (self and self.Outer) or (self and self.Container) or ScreenGui;
        end

        local ColorPicker = {
            Value = Info.Default;
            Transparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end;
            TextLabel = targetParent;
        };

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);
            ColorPicker.Hue = H;
            ColorPicker.Sat = S;
            ColorPicker.Vib = V;
        end
        ColorPicker:SetHSVFromRGB(ColorPicker.Value);

        local DisplayFrame = Library:Create('TextButton', {
            BackgroundColor3 = ColorPicker.Value;
            Size = UDim2.fromOffset(16, 16);
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Text = '';
            AutoButtonColor = false;
            ZIndex = 20;
            Parent = targetParent;
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, 4), Parent = DisplayFrame });
        local DisplayStroke = Library:Create('UIStroke', { Color = Color3.fromRGB(120, 110, 160), Transparency = 0.3, Thickness = 1.2, Parent = DisplayFrame });
        DisplayFrame.MouseEnter:Connect(function() Tween(DisplayStroke, TI_FAST, { Color = Color3.fromRGB(240, 235, 255), Transparency = 0.1 }); end);
        DisplayFrame.MouseLeave:Connect(function() Tween(DisplayStroke, TI_FAST, { Color = Color3.fromRGB(120, 110, 160), Transparency = 0.3 }); end);

        local PickerFrameOuter = Library:Create('CanvasGroup', {
            Name = 'ColorPickerPopup';
            GroupTransparency = 1;
            BackgroundColor3 = Library.BackgroundColor;
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 20),
            Size = UDim2.fromOffset(230, 255);
            Visible = false;
            ZIndex = 3000;
            Parent = ScreenGui,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, 10), Parent = PickerFrameOuter });
        Library:Create('UIStroke', { Color = Library.OutlineColor, Thickness = 1.2, Parent = PickerFrameOuter });

        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 20);
        end);

        local SatVibMapOuter = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            Position = UDim2.new(0, 8, 0, 25),
            Size = UDim2.new(0, 192, 0, 192),
            ZIndex = 3001;
            Parent = PickerFrameOuter;
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Control), Parent = SatVibMapOuter });

        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 3002;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapOuter;
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Control), Parent = SatVibMap });

        local CursorOuter = Library:Create('Frame', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 10, 0, 10);
            BackgroundColor3 = Color3.new(1, 1, 1);
            ZIndex = 3003;
            Parent = SatVibMap;
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = CursorOuter });
        local CursorInner = Library:Create('Frame', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Position = UDim2.fromScale(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundColor3 = ColorPicker.Value;
            ZIndex = 3004;
            Parent = CursorOuter;
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = CursorInner });

        local HueSlider = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            Position = UDim2.new(0, 208, 0, 25),
            Size = UDim2.new(0, 14, 0, 192),
            ZIndex = 3001;
            Parent = PickerFrameOuter;
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Small), Parent = HueSlider });
        local HueGrad = Library:Create('UIGradient', {
            Rotation = 90;
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
            });
            Parent = HueSlider;
        });

        local HueCursor = Library:Create('Frame', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Position = UDim2.new(0.5, 0, ColorPicker.Hue, 0);
            Size = UDim2.new(1, 4, 0, 4);
            BackgroundColor3 = Color3.new(1, 1, 1);
            ZIndex = 3002;
            Parent = HueSlider;
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = HueCursor });

        local HexInput = Library:Create('TextBox', {
            BackgroundColor3 = Library.MainColor;
            Position = UDim2.new(0, 8, 0, 224),
            Size = UDim2.new(0, 80, 0, 22),
            Font = Library.Font;
            Text = '#' .. ColorPicker.Value:ToHex();
            TextColor3 = Library.FontColor;
            TextSize = 11;
            ZIndex = 3001;
            Parent = PickerFrameOuter;
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Small), Parent = HexInput });

        local function UpdateColor()
            local color = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
            ColorPicker.Value = color;
            DisplayFrame.BackgroundColor3 = color;
            CursorInner.BackgroundColor3 = color;
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);
            HexInput.Text = '#' .. color:ToHex();
            Library:SafeCallback(ColorPicker.Callback, color);
            Library:SafeCallback(ColorPicker.Changed, color);
        end

        local function SetFromSatVib(input)
            local relX = math.clamp((input.Position.X - SatVibMap.AbsolutePosition.X) / SatVibMap.AbsoluteSize.X, 0, 1);
            local relY = math.clamp((input.Position.Y - SatVibMap.AbsolutePosition.Y) / SatVibMap.AbsoluteSize.Y, 0, 1);
            ColorPicker.Sat = relX;
            ColorPicker.Vib = 1 - relY;
            CursorOuter.Position = UDim2.fromScale(relX, relY);
            UpdateColor();
        end

        local function SetFromHue(input)
            local relY = math.clamp((input.Position.Y - HueSlider.AbsolutePosition.Y) / HueSlider.AbsoluteSize.Y, 0, 1);
            ColorPicker.Hue = relY;
            HueCursor.Position = UDim2.new(0.5, 0, relY, 0);
            UpdateColor();
        end

        SatVibMap.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                SetFromSatVib(input);
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    SetFromSatVib(input);
                    RenderStepped:Wait();
                end
                Library:AttemptSave();
            end
        end);

        HueSlider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                SetFromHue(input);
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    SetFromHue(input);
                    RenderStepped:Wait();
                end
                Library:AttemptSave();
            end
        end);

        HexInput.FocusLost:Connect(function()
            local hex = HexInput.Text:gsub('#', '');
            local success, col = pcall(Color3.fromHex, hex);
            if success and col then
                ColorPicker:SetValueRGB(col);
                Library:AttemptSave();
            else
                HexInput.Text = '#' .. ColorPicker.Value:ToHex();
            end
        end);

        function ColorPicker:SetValueRGB(Color)
            ColorPicker.Value = Color;
            ColorPicker:SetHSVFromRGB(Color);
            CursorOuter.Position = UDim2.fromScale(ColorPicker.Sat, 1 - ColorPicker.Vib);
            HueCursor.Position = UDim2.new(0.5, 0, ColorPicker.Hue, 0);
            UpdateColor();
        end

        function ColorPicker:SetValue(Color)
            ColorPicker:SetValueRGB(Color);
        end

        function ColorPicker:OnChanged(Func) ColorPicker.Changed = Func; Func(ColorPicker.Value); end

        DisplayFrame.MouseButton1Click:Connect(function()
            Library:PlaySound('click');
            if PickerFrameOuter.Visible then
                Tween(PickerFrameOuter, TI_FAST, { GroupTransparency = 1 });
                task.delay(0.12, function() PickerFrameOuter.Visible = false; end);
                Library.OpenedFrames[PickerFrameOuter] = nil;
            else
                PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 20);
                PickerFrameOuter.Visible = true;
                Tween(PickerFrameOuter, TI_FAST, { GroupTransparency = 0 });
                Library.OpenedFrames[PickerFrameOuter] = true;
            end
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and PickerFrameOuter.Visible then
                if not Library:IsMouseOverFrame(PickerFrameOuter) and not Library:IsMouseOverFrame(DisplayFrame) then
                    Tween(PickerFrameOuter, TI_FAST, { GroupTransparency = 1 });
                    task.delay(0.12, function() PickerFrameOuter.Visible = false; end);
                    Library.OpenedFrames[PickerFrameOuter] = nil;
                end
            end
        end));

        ColorPicker:SetValueRGB(ColorPicker.Value);
        ColorPicker.Outer = DisplayFrame;
        setmetatable(ColorPicker, BaseAddons);

        Options[Idx] = ColorPicker;
        return ColorPicker;
    end

    function Funcs:AddKeyPicker(Idx, Info)
        Info = Info or {};
        assert(Info.Default, 'AddKeyPicker: Missing default value.');

        local targetParent = (self and self.MasterKeybindHolder) or (self and self.RightAddons) or self.TextLabel or self.Outer or self.Container or ScreenGui;
        if self and self.MasterKeybindHolder then
            self.MasterKeybindHolder.Visible = true;
        end

        local KeyPicker = {
            Value = Info.Default;
            Toggled = (Info.Mode == 'Always' or Info.Default == 'None');
            Mode = Info.Mode or 'Always';
            Type = 'KeyPicker';
            Callback = Info.Callback or function(Value) end;
            ChangedCallback = Info.ChangedCallback or function(New) end;
            SyncToggleState = Info.SyncToggleState or false;
            TextLabel = targetParent;
        };

        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then
                return true;
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' or KeyPicker.Value == '' then return true; end
                local key = KeyPicker.Value;
                if key == 'MB1' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1);
                elseif key == 'MB2' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2);
                elseif key == 'MB3' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3);
                elseif key == 'MB4' or key == 'MOUSE 4' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton4 or Enum.UserInputType.MouseButton2);
                elseif key == 'MB5' or key == 'MOUSE 5' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton5 or Enum.UserInputType.MouseButton2);
                else
                    local code = Enum.KeyCode[key];
                    if code then return InputService:IsKeyDown(code); end
                end
                return false;
            elseif KeyPicker.Mode == 'Toggle' then
                if KeyPicker.Value == 'None' or KeyPicker.Value == '' then return true; end
                return KeyPicker.Toggled;
            end
            return true;
        end

        if self and self.Type == 'Toggle' then
            self.KeyPicker = KeyPicker;
        end

        local PickOuter = Library:Create('TextButton', {
            BackgroundColor3 = Color3.fromRGB(32, 28, 44);
            BackgroundTransparency = 0.2;
            Size = UDim2.new(0, 48, 0, 18);
            Text = '';
            AutoButtonColor = false;
            ZIndex = 20;
            Parent = targetParent;
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Small), Parent = PickOuter });
        local PickStroke = Library:Create('UIStroke', { Color = Library.OutlineColor, Transparency = 0.45, Thickness = 1, Parent = PickOuter });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 11;
            Text = '[' .. tostring(Info.Default) .. ']';
            TextColor3 = Color3.fromRGB(210, 205, 230);
            ZIndex = 21;
            Active = false;
            Parent = PickOuter;
        });

        local ModeSelectOuter = Library:Create('CanvasGroup', {
            GroupTransparency = 1;
            BackgroundColor3 = Library.BackgroundColor;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(0, 88, 0, 72);
            Visible = false;
            ZIndex = 3000;
            Parent = ScreenGui;
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Control), Parent = ModeSelectOuter });
        Library:Create('UIStroke', { Color = Library.OutlineColor, Thickness = 1, Parent = ModeSelectOuter });

        local function UpdateModePosition()
            local absPos = PickOuter.AbsolutePosition;
            ModeSelectOuter.Position = UDim2.fromOffset(absPos.X + PickOuter.AbsoluteSize.X + 4, absPos.Y);
        end

        PickOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(UpdateModePosition);
        Library:Create('UIListLayout', { FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Parent = ModeSelectOuter });

        local Modes = Info.Modes or { 'Always', 'Hold', 'Toggle' };
        local ModeButtons = {};

        for _, Mode in next, Modes do
            local ModeButton = {};
            local Btn = Library:Create('TextButton', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 24);
                Font = Library.Font;
                TextSize = 12;
                Text = Mode;
                TextColor3 = (KeyPicker.Mode == Mode) and Library.AccentColor or Library.FontColor;
                ZIndex = 3001;
                Parent = ModeSelectOuter;
            });

            Btn.MouseEnter:Connect(function() Tween(Btn, TI_FAST, { TextColor3 = Library.AccentColor }); end);
            Btn.MouseLeave:Connect(function()
                if KeyPicker.Mode ~= Mode then Tween(Btn, TI_FAST, { TextColor3 = Library.FontColor }); end
            end);

            function ModeButton:Select()
                for _, Button in next, ModeButtons do Button:Deselect(); end
                KeyPicker.Mode = Mode;
                if Mode == 'Always' then
                    KeyPicker.Toggled = true;
                elseif Mode == 'Hold' then
                    KeyPicker.Toggled = false;
                end
                Btn.TextColor3 = Library.AccentColor;
                ModeSelectOuter.Visible = false;
                if KeyPicker.UpdateBindRow then KeyPicker:UpdateBindRow(); end
                Library:SafeCallback(KeyPicker.Callback, KeyPicker:GetState());
            end
            function ModeButton:Deselect() Btn.TextColor3 = Library.FontColor; end

            Btn.MouseButton1Click:Connect(function() ModeButton:Select(); Library:AttemptSave(); end);
            if Mode == KeyPicker.Mode then ModeButton:Select(); end
            ModeButtons[Mode] = ModeButton;
        end

        local BindRow;
        if (not Info.NoUI) and Library.KeybindContainer then
            BindRow = Library:CreateLabel({
                Size = UDim2.new(1, -12, 0, 18);
                Position = UDim2.new(0, 8, 0, 0);
                TextSize = 12;
                Text = string.format('[%s] %s', tostring(KeyPicker.Value), tostring(Info.Text or Idx));
                TextColor3 = Library.DimColor;
                TextXAlignment = Enum.TextXAlignment.Left;
                LayoutOrder = #Library.KeybindContainer:GetChildren();
                ZIndex = 102;
                Parent = Library.KeybindContainer;
            });

            function KeyPicker:UpdateBindRow()
                if not BindRow then return end
                BindRow.Text = string.format('[%s] %s (%s)', tostring(KeyPicker.Value), tostring(Info.Text or Idx), tostring(KeyPicker.Mode));
                if KeyPicker:GetState() then
                    Tween(BindRow, TI_FAST, { TextColor3 = Library.AccentColor });
                else
                    Tween(BindRow, TI_FAST, { TextColor3 = Library.DimColor });
                end
            end
            KeyPicker:UpdateBindRow();
            if Library.ResizeKeybindFrame then Library.ResizeKeybindFrame(); end
        end

        function KeyPicker:SetValue(Key, Mode)
            if type(Key) == 'table' then
                Mode = Key[2] or Key.Mode or Key.mode or Mode;
                Key = Key[1] or Key.Key or Key.key or Key.Value or 'None';
            end
            DisplayLabel.Text = '[' .. tostring(Key) .. ']';
            KeyPicker.Value = Key;
            if Mode and ModeButtons[Mode] then ModeButtons[Mode]:Select(); end
            if KeyPicker.UpdateBindRow then KeyPicker:UpdateBindRow(); end
        end

        function KeyPicker:OnClick(Callback) KeyPicker.Clicked = Callback; end
        function KeyPicker:OnChanged(Callback) KeyPicker.Changed = Callback; Callback(KeyPicker.Value); end

        if self and self.Addons then table.insert(self.Addons, KeyPicker); end

        function KeyPicker:DoClick()
            if self and self.Type == 'Toggle' and KeyPicker.SyncToggleState then
                self:SetValue(not self.Value);
            end
            if KeyPicker.UpdateBindRow then KeyPicker:UpdateBindRow(); end
            Library:SafeCallback(KeyPicker.Callback, KeyPicker:GetState());
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker:GetState());
        end

        local Picking = false;
        local function StartPicking()
            if Picking then return end
            Picking = true;
            DisplayLabel.Text = '...';
            Tween(PickStroke, TI_FAST, { Color = Library.AccentColor, Transparency = 0 });

            local conn;
            conn = InputService.InputBegan:Connect(function(input)
                if not Picking then return conn:Disconnect(); end
                local key = nil;
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode == Enum.KeyCode.Escape then
                        key = 'None';
                    else
                        key = input.KeyCode.Name;
                    end
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                    key = 'MB1';
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                    key = 'MB2';
                elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                    key = 'MB3';
                end

                if key then
                    Picking = false;
                    conn:Disconnect();
                    KeyPicker:SetValue(key);
                    Tween(PickStroke, TI_FAST, { Color = Library.OutlineColor, Transparency = 0.45 });
                    Library:SafeCallback(KeyPicker.ChangedCallback, key);
                    Library:AttemptSave();
                end
            end);
        end

        PickOuter.MouseButton1Click:Connect(function()
            Library:PlaySound('click');
            if not Library:MouseIsOverOpenedFrame() then
                StartPicking();
            end
        end);

        PickOuter.MouseButton2Click:Connect(function()
            Library:PlaySound('click');
            if not Library:MouseIsOverOpenedFrame() then
                UpdateModePosition();
                ModeSelectOuter.Visible = true;
                Tween(ModeSelectOuter, TI_FAST, { GroupTransparency = 0 });
                Library.OpenedFrames[ModeSelectOuter] = true;
            end
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and ModeSelectOuter.Visible then
                if not Library:IsMouseOverFrame(ModeSelectOuter) and not Library:IsMouseOverFrame(PickOuter) then
                    Tween(ModeSelectOuter, TI_FAST, { GroupTransparency = 1 });
                    task.delay(0.12, function() ModeSelectOuter.Visible = false; end);
                    Library.OpenedFrames[ModeSelectOuter] = nil;
                end
            end
        end));

        Library:GiveSignal(InputService.InputBegan:Connect(function(input)
            if not Picking then
                local isMatch = false;
                if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == KeyPicker.Value then
                    isMatch = true;
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 and KeyPicker.Value == 'MB1' then
                    isMatch = true;
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 and KeyPicker.Value == 'MB2' then
                    isMatch = true;
                elseif input.UserInputType == Enum.UserInputType.MouseButton3 and KeyPicker.Value == 'MB3' then
                    isMatch = true;
                end

                if isMatch then
                    if KeyPicker.Mode == 'Toggle' then
                        KeyPicker.Toggled = not KeyPicker.Toggled;
                    end
                    KeyPicker:DoClick();
                end
            end
        end));

        Library:GiveSignal(InputService.InputEnded:Connect(function(input)
            if not Picking and KeyPicker.Mode == 'Hold' then
                local isMatch = false;
                if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == KeyPicker.Value then
                    isMatch = true;
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 and KeyPicker.Value == 'MB1' then
                    isMatch = true;
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 and KeyPicker.Value == 'MB2' then
                    isMatch = true;
                elseif input.UserInputType == Enum.UserInputType.MouseButton3 and KeyPicker.Value == 'MB3' then
                    isMatch = true;
                end

                if isMatch then
                    KeyPicker:DoClick();
                end
            end
        end));

        KeyPicker.Outer = PickOuter;
        setmetatable(KeyPicker, BaseAddons);

        Options[Idx] = KeyPicker;
        return KeyPicker;
    end

    function Funcs:AddBlank(Size)
        local Groupbox = self;
        local Blank = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size or 2);
            ZIndex = 1;
            Parent = Groupbox.Container;
        });
        return Blank;
    end

    function Funcs:AddLabel(Text, DoesWrap)
        local Groupbox = self;
        local Label = { Text = Text or '' };

        local Row = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 20);
            ZIndex = 2;
            Parent = Groupbox.Container;
        });

        local TextLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, -70, 1, 0);
            TextSize = 12;
            Text = Text or '';
            TextWrapped = DoesWrap or false;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextColor3 = Color3.fromRGB(200, 195, 220);
            ZIndex = 3;
            Parent = Row;
        });

        local RightAddons = Library:Create('Frame', {
            AnchorPoint = Vector2.new(1, 0.5);
            Position = UDim2.new(1, 0, 0.5, 0);
            Size = UDim2.new(0, 65, 1, 0);
            BackgroundTransparency = 1;
            ZIndex = 4;
            Parent = Row;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 6);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            VerticalAlignment = Enum.VerticalAlignment.Center;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = RightAddons;
        });

        function Label:SetText(NewText)
            TextLabel.Text = tostring(NewText);
            if DoesWrap then
                local _, Y = Library:GetTextBounds(NewText, Library.Font, 12, Vector2.new(Row.AbsoluteSize.X - 70, math.huge));
                Row.Size = UDim2.new(1, 0, 0, math.max(20, Y));
            end
            Groupbox:Resize();
        end

        Label.Outer = Row;
        Label.TextLabel = TextLabel;
        Label.RightAddons = RightAddons;
        setmetatable(Label, BaseAddons);

        Groupbox:AddBlank(2);
        Groupbox:Resize();
        return Label;
    end

    function Funcs:AddButton(...)
        local Button = {};
        local function ProcessButtonParams(Obj, ...)
            local Props = select(1, ...);
            if type(Props) == 'table' then
                Obj.Text = Props.Text;
                Obj.Func = Props.Func;
                Obj.DoubleClick = Props.DoubleClick;
                Obj.Tooltip = Props.Tooltip;
            else
                Obj.Text = select(1, ...);
                Obj.Func = select(2, ...);
            end
            Obj.Func = Obj.Func or function() end;
        end
        ProcessButtonParams(Button, ...);

        local Groupbox = self;
        local Container = Groupbox.Container;

        local Outer = Library:Create('TextButton', {
            AutoButtonColor = false;
            BackgroundColor3 = Color3.fromRGB(34, 30, 48);
            BackgroundTransparency = 0.4;
            Size = UDim2.new(1, 0, 0, 26);
            Text = '';
            ZIndex = 2;
            Parent = Container;
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Control), Parent = Outer });
        local Stroke = Library:Create('UIStroke', { Color = Library.OutlineColor, Transparency = 0.45, Thickness = 1, Parent = Outer });

        local BtnScale = Library:Create('UIScale', { Scale = 1, Parent = Outer });

        local Label = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 12;
            Text = Button.Text or 'Button';
            TextColor3 = Color3.fromRGB(230, 225, 245);
            ZIndex = 3;
            Parent = Outer;
        });

        local function getBtnTrans(hover)
            local target = 1 - (Library.GlobalOpacity or 0.85);
            if Library.LiquidGlass then
                return hover and 0.35 or 0.55;
            end
            local base = math.clamp(target + 0.25, 0, 0.95);
            return hover and math.max(0, base - 0.18) or base;
        end

        Outer.MouseEnter:Connect(function()
            local t = getBtnTrans(true);
            Tween(Stroke, TI_FAST, { Color = Library.AccentColor, Transparency = 0.2 });
            Tween(Outer, TI_FAST, { BackgroundColor3 = Color3.fromRGB(44, 38, 62), BackgroundTransparency = t });
            Tween(Label, TI_FAST, { TextColor3 = Color3.fromRGB(255, 255, 255) });
        end);
        Outer.MouseLeave:Connect(function()
            local t = getBtnTrans(false);
            Tween(Stroke, TI_SMOOTH, { Color = Library.OutlineColor, Transparency = 0.45 });
            Tween(Outer, TI_SMOOTH, { BackgroundColor3 = Color3.fromRGB(34, 30, 48), BackgroundTransparency = t });
            Tween(Label, TI_SMOOTH, { TextColor3 = Color3.fromRGB(230, 225, 245) });
        end);

        Outer.MouseButton1Click:Connect(function()
            if not Library:MouseIsOverOpenedFrame() then
                Library:PlaySound('click');
                Tween(BtnScale, TI_FAST, { Scale = 0.96 });
                task.delay(0.08, function() Tween(BtnScale, TI_SPRING, { Scale = 1 }); end);
                Library:SafeCallback(Button.Func);
            end
        end);

        Button.Outer = Outer;
        Button.Label = Label;
        Button.TextLabel = Label;
        setmetatable(Button, BaseAddons);
        if type(Button.Tooltip) == 'string' then Library:AddToolTip(Button.Tooltip, Outer); end

        function Button:AddButton(...)
            local SubButton = {};
            ProcessButtonParams(SubButton, ...);

            local RowHolder = Outer.Parent:FindFirstChild('ButtonRow_' .. tostring(Outer));
            if not RowHolder then
                RowHolder = Library:Create('Frame', {
                    Name = 'ButtonRow_' .. tostring(Outer),
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 26),
                    ZIndex = 2,
                    LayoutOrder = Outer.LayoutOrder,
                    Parent = Container,
                });
                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 6),
                    Parent = RowHolder,
                });
                Outer.Parent = RowHolder;
                Outer.Size = UDim2.new(0.5, -3, 1, 0);
            end

            local SubOuter = Library:Create('TextButton', {
                AutoButtonColor = false;
                BackgroundColor3 = Color3.fromRGB(34, 30, 48);
                BackgroundTransparency = getBtnTrans(false);
                Size = UDim2.new(0.5, -3, 1, 0);
                Text = '';
                ZIndex = 2;
                Parent = RowHolder;
            });
            Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Control), Parent = SubOuter });
            local SubStroke = Library:Create('UIStroke', { Color = Library.OutlineColor, Transparency = 0.45, Thickness = 1, Parent = SubOuter });
            local SubBtnScale = Library:Create('UIScale', { Scale = 1, Parent = SubOuter });

            local SubLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = 12;
                Text = SubButton.Text or 'Button';
                TextColor3 = Color3.fromRGB(230, 225, 245);
                ZIndex = 3;
                Parent = SubOuter;
            });

            SubOuter.MouseEnter:Connect(function()
                local t = getBtnTrans(true);
                Tween(SubStroke, TI_FAST, { Color = Library.AccentColor, Transparency = 0.2 });
                Tween(SubOuter, TI_FAST, { BackgroundColor3 = Color3.fromRGB(44, 38, 62), BackgroundTransparency = t });
                Tween(SubLabel, TI_FAST, { TextColor3 = Color3.fromRGB(255, 255, 255) });
            end);
            SubOuter.MouseLeave:Connect(function()
                local t = getBtnTrans(false);
                Tween(SubStroke, TI_SMOOTH, { Color = Library.OutlineColor, Transparency = 0.45 });
                Tween(SubOuter, TI_SMOOTH, { BackgroundColor3 = Color3.fromRGB(34, 30, 48), BackgroundTransparency = t });
                Tween(SubLabel, TI_SMOOTH, { TextColor3 = Color3.fromRGB(230, 225, 245) });
            end);

            SubOuter.MouseButton1Click:Connect(function()
                if not Library:MouseIsOverOpenedFrame() then
                    Library:PlaySound('click');
                    Tween(SubBtnScale, TI_FAST, { Scale = 0.96 });
                    task.delay(0.08, function() Tween(SubBtnScale, TI_SPRING, { Scale = 1 }); end);
                    Library:SafeCallback(SubButton.Func);
                end
            end);

            SubButton.Outer = SubOuter;
            SubButton.Label = SubLabel;
            SubButton.TextLabel = SubLabel;
            setmetatable(SubButton, BaseAddons);
            if type(SubButton.Tooltip) == 'string' then Library:AddToolTip(SubButton.Tooltip, SubOuter); end

            Groupbox:Resize();
            return SubButton;
        end

        Groupbox:AddBlank(3);
        Groupbox:Resize();
        return Button;
    end

    function Funcs:AddDivider()
        local Groupbox = self;
        local Divider = Library:Create('Frame', {
            BackgroundColor3 = Library.OutlineColor,
            BackgroundTransparency = 0.65,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            ZIndex = 2,
            Parent = Groupbox.Container,
        });
        Library:AddToRegistry(Divider, { BackgroundColor3 = 'OutlineColor' });
        Groupbox:AddBlank(3);
        Groupbox:Resize();
    end

    function Funcs:AddInput(Idx, Info)
        Info = Info or {};
        local Textbox = {
            Value = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type = 'Input';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local Row = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 28);
            ZIndex = 2;
            Parent = Container;
        });

        if Info.Text then
            Library:CreateLabel({
                Position = UDim2.new(0, 4, 0, 0);
                Size = UDim2.new(0.44, -4, 1, 0);
                TextSize = 12;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextColor3 = Color3.fromRGB(200, 195, 220);
                ZIndex = 3;
                Parent = Row;
            });
        end

        local TextBoxOuter = Library:Create('Frame', {
            AnchorPoint = Vector2.new(1, 0.5);
            Position = UDim2.new(1, -2, 0.5, 0);
            Size = Info.Text and UDim2.new(0.54, 0, 0, 24) or UDim2.new(1, -4, 0, 24);
            BackgroundColor3 = Color3.fromRGB(28, 25, 40);
            BackgroundTransparency = 0.4;
            ZIndex = 3;
            Parent = Row;
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Control), Parent = TextBoxOuter });
        local BoxStroke = Library:Create('UIStroke', { Color = Library.OutlineColor, Transparency = 0.45, Thickness = 1, Parent = TextBoxOuter });

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 6, 0, 0);
            Size = UDim2.new(1, -12, 1, 0);
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(115, 110, 135);
            PlaceholderText = Info.Placeholder or '...';
            Text = Info.Default or '';
            TextColor3 = Color3.fromRGB(240, 235, 255);
            TextSize = 11;
            TextXAlignment = Enum.TextXAlignment.Left;
            ClearTextOnFocus = false;
            ZIndex = 4;
            Parent = TextBoxOuter;
        });

        Box.Focused:Connect(function()
            Tween(BoxStroke, TI_SMOOTH, { Color = Library.AccentColor, Transparency = 0.1 });
        end);
        Box.FocusLost:Connect(function()
            Tween(BoxStroke, TI_SMOOTH, { Color = Library.OutlineColor, Transparency = 0.45 });
        end);

        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then Text = Text:sub(1, Info.MaxLength); end
            if Textbox.Numeric and (not tonumber(Text)) and Text:len() > 0 then Text = Textbox.Value; end
            Textbox.Value = Text;
            Box.Text = Text;
            Library:SafeCallback(Textbox.Callback, Textbox.Value);
            Library:SafeCallback(Textbox.Changed, Textbox.Value);
        end

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end);
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end);
        end

        function Textbox:OnChanged(Func) Textbox.Changed = Func; Func(Textbox.Value); end

        Groupbox:AddBlank(2);
        Groupbox:Resize();
        Textbox.Outer = Row;
        setmetatable(Textbox, BaseAddons);

        Options[Idx] = Textbox;
        return Textbox;
    end

    -- Clean Minimalist Flat Feature Toggle Row (Inside Card)
    function Funcs:AddToggle(Idx, Info)
        Info = Info or {};
        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';
            Callback = Info.Callback or function(Value) end;
            Addons = {};
            Risky = Info.Risky;
            KeyPicker = nil;
            Text = Info.Text or 'Toggle';
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local isMasterToggle = false;
        local lowerText = string.lower(Info.Text or Idx or '');
        if Groupbox.HasMasterToggle and (Info.Master == true or lowerText == 'enable' or lowerText == 'enabled' or lowerText:find('enable') or not Groupbox.HasBoundMasterToggle) and Groupbox.MasterToggleSwitch and not Groupbox.HasBoundMasterToggle then
            isMasterToggle = true;
            Groupbox.HasBoundMasterToggle = true;
        end

        if isMasterToggle then
            local SwitchTrack = Groupbox.MasterToggleSwitch;
            local SwitchThumb = SwitchTrack:FindFirstChild("Thumb");

            function Toggle:Display()
                local isOn = Toggle.Value;
                Groupbox.Enabled = isOn;
                local trackCol = isOn and Library.AccentColor or Color3.fromRGB(42, 38, 56);
                local trackTrans = isOn and 0.15 or 0.35;
                local thumbPos = isOn and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0);

                Tween(SwitchTrack, TI_SMOOTH, { BackgroundColor3 = trackCol, BackgroundTransparency = trackTrans });
                local stroke = SwitchTrack:FindFirstChildOfClass("UIStroke");
                if stroke then
                    Tween(stroke, TI_SMOOTH, { Color = isOn and Library.AccentColor or Color3.fromRGB(68, 62, 90), Transparency = isOn and 0.25 or 0.55 });
                end
                if SwitchThumb then
                    Tween(SwitchThumb, TI_POP, { Position = thumbPos });
                end
            end

            function Toggle:GetState()
                if not Toggle.Value then return false end
                if Toggle.KeyPicker then return Toggle.KeyPicker:GetState(); end
                return true;
            end

            function Toggle:OnChanged(Func) Toggle.Changed = Func; Func(Toggle.Value); end

            function Toggle:SetValue(Bool)
                Bool = (not not Bool);
                Toggle.Value = Bool;
                Groupbox.Enabled = Bool;
                if Groupbox.SetEnabled and Groupbox.Enabled ~= Bool then
                    Groupbox:SetEnabled(Bool);
                end
                Toggle:Display();

                for _, Addon in next, Toggle.Addons do
                    if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                        Addon.Toggled = Bool;
                        if Addon.Update then Addon:Update(); end
                        if Addon.UpdateBindRow then Addon:UpdateBindRow(); end
                    end
                end

                Library:SafeCallback(Toggle.Callback, Toggle.Value);
                Library:SafeCallback(Toggle.Changed, Toggle.Value);
                Library:UpdateDependencyBoxes();
            end

            Groupbox.MasterToggle = Toggle;
            if Groupbox.SetEnabled then
                Groupbox:SetEnabled(Toggle.Value);
            end

            Toggle:Display();
            Toggle.Outer = Groupbox.HeaderRight;
            Toggle.TextLabel = Groupbox.MasterKeybindHolder;
            Toggle.Container = Container;
            setmetatable(Toggle, BaseAddons);

            Toggles[Idx] = Toggle;
            Library:UpdateDependencyBoxes();
            return Toggle;
        end

        -- Standard Sub-Toggle Row (Flat & Minimalist)
        local ToggleRow = Library:Create('TextButton', {
            AutoButtonColor = false;
            BackgroundTransparency = 1;
            BackgroundColor3 = Color3.fromRGB(36, 32, 50);
            Size = UDim2.new(1, 0, 0, 24);
            Text = '';
            ZIndex = 2;
            Parent = Container;
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Small), Parent = ToggleRow });

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(1, -125, 1, 0);
            Position = UDim2.new(0, 4, 0, 0);
            TextSize = 12;
            Text = Info.Text or 'Toggle';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextColor3 = Toggle.Value and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(205, 200, 225);
            ZIndex = 3;
            Active = false;
            Selectable = false;
            Parent = ToggleRow;
        });

        local RightAddons = Library:Create('Frame', {
            AnchorPoint = Vector2.new(1, 0.5);
            Position = UDim2.new(1, -42, 0.5, 0);
            Size = UDim2.new(0, 110, 1, 0);
            BackgroundTransparency = 1;
            ZIndex = 4;
            Parent = ToggleRow;
        });
        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            VerticalAlignment = Enum.VerticalAlignment.Center;
            Padding = UDim.new(0, 5);
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = RightAddons;
        });

        local SwitchTrack = Library:Create('Frame', {
            AnchorPoint = Vector2.new(1, 0.5);
            Position = UDim2.new(1, -2, 0.5, 0);
            Size = UDim2.fromOffset(32, 16);
            BackgroundColor3 = Toggle.Value and Library.AccentColor or Color3.fromRGB(42, 38, 56);
            BackgroundTransparency = Toggle.Value and 0.15 or 0.35;
            ZIndex = 4;
            Parent = ToggleRow;
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = SwitchTrack });
        local SwitchStroke = Library:Create('UIStroke', {
            Color = Toggle.Value and Library.AccentColor or Color3.fromRGB(68, 62, 90),
            Transparency = Toggle.Value and 0.25 or 0.55,
            Thickness = 1,
            Parent = SwitchTrack,
        });

        local SwitchThumb = Library:Create('Frame', {
            AnchorPoint = Vector2.new(0, 0.5);
            Position = Toggle.Value and UDim2.new(1, -13, 0.5, 0) or UDim2.new(0, 3, 0.5, 0);
            Size = UDim2.fromOffset(10, 10);
            BackgroundColor3 = Color3.fromRGB(255, 255, 255);
            BorderSizePixel = 0;
            ZIndex = 5;
            Parent = SwitchTrack,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = SwitchThumb });

        function Toggle:Display()
            local isOn = Toggle.Value;
            local trackCol = isOn and Library.AccentColor or Color3.fromRGB(42, 38, 56);
            local trackTrans = isOn and 0.15 or 0.35;
            local thumbPos = isOn and UDim2.new(1, -13, 0.5, 0) or UDim2.new(0, 3, 0.5, 0);
            local textCol = isOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(205, 200, 225);

            Tween(SwitchTrack, TI_SMOOTH, { BackgroundColor3 = trackCol, BackgroundTransparency = trackTrans });
            Tween(SwitchStroke, TI_SMOOTH, { Color = isOn and Library.AccentColor or Color3.fromRGB(68, 62, 90), Transparency = isOn and 0.25 or 0.55 });
            Tween(SwitchThumb, TI_POP, { Position = thumbPos });

            if not Toggle.Risky then
                Tween(ToggleLabel, TI_FAST, { TextColor3 = textCol });
            end
        end

        function Toggle:GetState()
            if not Toggle.Value then return false end
            if Groupbox.HasMasterToggle and Groupbox.MasterToggle and not Groupbox.MasterToggle.Value then
                return false;
            end
            if Toggle.KeyPicker then return Toggle.KeyPicker:GetState(); end
            return true;
        end

        function Toggle:OnChanged(Func) Toggle.Changed = Func; Func(Toggle.Value); end

        function Toggle:SetValue(Bool)
            Bool = (not not Bool);
            Toggle.Value = Bool;
            Toggle:Display();

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool;
                    if Addon.Update then Addon:Update(); end
                    if Addon.UpdateBindRow then Addon:UpdateBindRow(); end
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed, Toggle.Value);
            Library:UpdateDependencyBoxes();
        end

        ToggleRow.MouseEnter:Connect(function()
            Tween(ToggleRow, TI_FAST, { BackgroundTransparency = 0.7 });
            if not Toggle.Risky then
                Tween(ToggleLabel, TI_FAST, { TextColor3 = Color3.fromRGB(255, 255, 255) });
            end
        end);

        ToggleRow.MouseLeave:Connect(function()
            Tween(ToggleRow, TI_SMOOTH, { BackgroundTransparency = 1 });
            if not Toggle.Risky then
                Tween(ToggleLabel, TI_SMOOTH, { TextColor3 = Toggle.Value and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(205, 200, 225) });
            end
        end);

        ToggleRow.MouseButton1Click:Connect(function()
            if not Library:MouseIsOverOpenedFrame() then
                Library:PlaySound('toggle');
                Toggle:SetValue(not Toggle.Value);
                Library:AttemptSave();
            end
        end);

        if Toggle.Risky then ToggleLabel.TextColor3 = Library.RiskColor; end

        Toggle:Display();
        Groupbox:AddBlank(2);
        Groupbox:Resize();

        Toggle.Outer = ToggleRow;
        Toggle.TextLabel = RightAddons;
        Toggle.Container = Container;
        setmetatable(Toggle, BaseAddons);

        Toggles[Idx] = Toggle;
        Library:UpdateDependencyBoxes();
        return Toggle;
    end

    -- Sleek Minimalist Sub-Slider Inside Card
    function Funcs:AddSlider(Idx, Info)
        Info = Info or {};
        local Slider = {
            Value = Info.Default or Info.Min or 0;
            Min = Info.Min or 0;
            Max = Info.Max or 100;
            Rounding = Info.Rounding or 0;
            Type = 'Slider';
            Callback = Info.Callback or function(Value) end;
            Text = Info.Text or 'Slider';
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local SliderRow = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 36);
            ZIndex = 2;
            Parent = Container;
        });

        local HeaderFrame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 4, 0, 2),
            Size = UDim2.new(1, -8, 0, 16);
            ZIndex = 3;
            Parent = SliderRow;
        });

        local TitleLabel = Library:CreateLabel({
            Size = UDim2.new(1, -60, 1, 0);
            Position = UDim2.new(0, 0, 0, 0);
            TextSize = 12;
            Text = Info.Text or 'Slider';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextColor3 = Color3.fromRGB(205, 200, 225);
            ZIndex = 3;
            Parent = HeaderFrame;
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(0, 55, 1, 0);
            Position = UDim2.new(1, -55, 0, 0);
            TextSize = 11;
            Text = tostring(Slider.Value);
            TextColor3 = Library.AccentColor;
            TextXAlignment = Enum.TextXAlignment.Right;
            ZIndex = 3;
            Parent = HeaderFrame;
        });

        local Track = Library:Create('TextButton', {
            AutoButtonColor = false;
            Text = '';
            BackgroundColor3 = Color3.fromRGB(20, 18, 28);
            BorderSizePixel = 0;
            Position = UDim2.new(0, 4, 0, 24);
            Size = UDim2.new(1, -8, 0, 5);
            ZIndex = 3;
            Parent = SliderRow;
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = Track });
        local TrackStroke = Library:Create('UIStroke', { Color = Color3.fromRGB(56, 51, 74), Transparency = 0.45, Thickness = 1, Parent = Track });

        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0),
            ZIndex = 4,
            Parent = Track,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = Fill });

        local Knob = Library:Create('Frame', {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(9, 9),
            ZIndex = 5,
            Parent = Fill,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = Knob });
        Library:Create('UIStroke', { Color = Library.AccentColor, Transparency = 0.25, Thickness = 1, Parent = Knob });

        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value + 0.5);
            end
            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value)) or Value;
        end

        function Slider:Display()
            local Suffix = Info.Suffix or '';
            DisplayLabel.Text = string.format('%s%s', tostring(Slider.Value), Suffix);
            local fraction = math.clamp((Slider.Value - Slider.Min) / math.max(Slider.Max - Slider.Min, 0.0001), 0, 1);
            Tween(Fill, TweenInfo.new(0.06), { Size = UDim2.new(fraction, 0, 1, 0) });
        end

        function Slider:OnChanged(Func) Slider.Changed = Func; Func(Slider.Value); end

        function Slider:SetValue(Str)
            local Num = tonumber(Str);
            if not Num then return end
            Num = math.clamp(Num, Slider.Min, Slider.Max);
            Slider.Value = Round(Num);
            Slider:Display();
            Library:SafeCallback(Slider.Callback, Slider.Value);
            Library:SafeCallback(Slider.Changed, Slider.Value);
        end

        local function HandleSliderDrag()
            local trackPos = Track.AbsolutePosition.X;
            local trackWidth = Track.AbsoluteSize.X;
            local fraction = math.clamp((Mouse.X - trackPos) / trackWidth, 0, 1);
            local nVal = Round(Slider.Min + (Slider.Max - Slider.Min) * fraction);
            if nVal ~= Slider.Value then
                Slider.Value = nVal;
                Slider:Display();
                Library:SafeCallback(Slider.Callback, Slider.Value);
                Library:SafeCallback(Slider.Changed, Slider.Value);
            end
        end

        Track.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Library:PlaySound('slider');
                HandleSliderDrag();
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    HandleSliderDrag();
                    RenderStepped:Wait();
                end
                Library:AttemptSave();
            end
        end);

        Slider:Display();
        Groupbox:AddBlank(3);
        Groupbox:Resize();
        Slider.Outer = SliderRow;
        setmetatable(Slider, BaseAddons);

        Options[Idx] = Slider;
        return Slider;
    end

    -- Clean Minimalist Inline Sub-Dropdown (Matches Reference UI Pill Dropdown)
    function Funcs:AddDropdown(Idx, Info)
        Info = Info or {};
        if Info.SpecialType == 'Player' then Info.Values = GetPlayersString(); Info.AllowNull = true;
        elseif Info.SpecialType == 'Team' then Info.Values = GetTeamsString(); Info.AllowNull = true; end

        Info.Values = Info.Values or {};
        local defaultVal;
        if Info.Multi then
            defaultVal = type(Info.Default) == 'table' and Info.Default or {};
        else
            if type(Info.Default) == 'number' and Info.Values[Info.Default] then
                defaultVal = Info.Values[Info.Default];
            else
                defaultVal = Info.Default or Info.Values[1];
            end
        end

        local Dropdown = {
            Values = Info.Values;
            Value = defaultVal;
            Multi = Info.Multi;
            Type = 'Dropdown';
            SpecialType = Info.SpecialType;
            Callback = Info.Callback or function(Value) end;
            Text = Info.Text or 'Dropdown';
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local DropdownRow = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 26);
            ZIndex = 2;
            Parent = Container;
        });

        if Info.Text then
            Library:CreateLabel({
                Position = UDim2.new(0, 4, 0, 0);
                Size = UDim2.new(0.44, -4, 1, 0);
                TextSize = 12;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextColor3 = Color3.fromRGB(205, 200, 225);
                ZIndex = 3;
                Parent = DropdownRow;
            });
        end

        local DropdownOuter = Library:Create('TextButton', {
            AutoButtonColor = false;
            AnchorPoint = Vector2.new(1, 0.5);
            Position = UDim2.new(1, -2, 0.5, 0);
            Size = Info.Text and UDim2.new(0.54, 0, 0, 22) or UDim2.new(1, -4, 0, 22);
            BackgroundColor3 = Color3.fromRGB(32, 29, 44);
            BackgroundTransparency = 0.3;
            Text = '';
            ZIndex = 3;
            Parent = DropdownRow;
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Small), Parent = DropdownOuter });
        local DropStroke = Library:Create('UIStroke', { Color = Library.OutlineColor, Transparency = 0.45, Thickness = 1, Parent = DropdownOuter });

        local ItemLabel = Library:CreateLabel({
            Position = UDim2.new(0, 6, 0, 0);
            Size = UDim2.new(1, -22, 1, 0);
            TextSize = 11;
            Text = '--';
            TextColor3 = Color3.fromRGB(230, 225, 245);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextTruncate = Enum.TextTruncate.AtEnd;
            ZIndex = 4;
            Active = false;
            Parent = DropdownOuter;
        });

        local Arrow = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(1, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -5, 0.5, 0);
            Size = UDim2.new(0, 11, 0, 11);
            Image = 'rbxassetid://10709790948';
            ImageColor3 = Color3.fromRGB(170, 165, 190);
            ZIndex = 4;
            Parent = DropdownOuter;
        });

        local ListOuter = Library:Create('CanvasGroup', {
            GroupTransparency = 1;
            BackgroundColor3 = Color3.fromRGB(18, 16, 26);
            Size = UDim2.fromOffset(180, 120);
            Visible = false;
            ZIndex = 8000;
            Parent = ScreenGui;
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, 8), Parent = ListOuter });
        local ListStroke = Library:Create('UIStroke', { Color = Library.OutlineColor, Transparency = 0.2, Thickness = 1.2, Parent = ListOuter });

        local DropScale = Library:Create('UIScale', { Scale = 0.95, Parent = ListOuter });

        Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, 16, 1, 16),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://6015897843',
            ImageColor3 = Color3.fromRGB(0, 0, 0),
            ImageTransparency = 0.45,
            SliceCenter = Rect.new(49, 49, 450, 450),
            ScaleType = Enum.ScaleType.Slice,
            SliceScale = 1,
            ZIndex = 7999,
            Parent = ListOuter,
        });

        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.fromOffset(4, 4);
            Size = UDim2.new(1, -8, 1, -8);
            ScrollBarThickness = 3;
            ScrollBarImageColor3 = Library.AccentColor;
            ScrollBarImageTransparency = 0.4;
            ZIndex = 8001;
            Parent = ListOuter;
        });

        local ListLayout = Library:Create('UIListLayout', {
            Padding = UDim.new(0, 3);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        });

        local function RecalculateListPosition()
            local cam = workspace.CurrentCamera;
            local vpY = cam and cam.ViewportSize.Y or 1080;
            local listHeight = math.min(#Dropdown.Values * 25 + 10, 160);
            local targetY = DropdownOuter.AbsolutePosition.Y + DropdownOuter.AbsoluteSize.Y + 4;
            if targetY + listHeight > vpY - 20 then
                targetY = math.max(10, DropdownOuter.AbsolutePosition.Y - listHeight - 4);
            end
            ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, targetY);
            ListOuter.Size = UDim2.fromOffset(math.max(DropdownOuter.AbsoluteSize.X, 150), listHeight);
            Scrolling.CanvasSize = UDim2.fromOffset(0, ListLayout.AbsoluteContentSize.Y + 6);
        end

        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition);

        function Dropdown:Display()
            if Info.Multi then
                local str = '';
                for _, val in next, Dropdown.Values do
                    if Dropdown.Value[val] then str = str .. val .. ', '; end
                end
                str = str:sub(1, #str - 2);
                ItemLabel.Text = (str == '' and '--' or str);
            else
                ItemLabel.Text = (Dropdown.Value or '--');
            end
        end

        function Dropdown:BuildDropdownList()
            for _, child in next, Scrolling:GetChildren() do
                if not child:IsA('UIListLayout') then child:Destroy(); end
            end
            for _, val in next, Dropdown.Values do
                local Btn = Library:Create('TextButton', {
                    AutoButtonColor = false;
                    BackgroundColor3 = Library.MainColor;
                    BackgroundTransparency = 1;
                    Size = UDim2.new(1, -4, 0, 22);
                    Position = UDim2.new(0, 2, 0, 0);
                    Font = Library.Font;
                    Text = '  ' .. tostring(val);
                    TextColor3 = Library.FontColor;
                    TextSize = 11;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 8002;
                    Parent = Scrolling;
                });
                Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Small), Parent = Btn });

                Btn.MouseEnter:Connect(function()
                    local isSelected = Info.Multi and Dropdown.Value[val] or (Dropdown.Value == val);
                    Tween(Btn, TI_FAST, { BackgroundTransparency = isSelected and 0.4 or 0.75, TextColor3 = Library.AccentColor });
                end);
                Btn.MouseLeave:Connect(function()
                    local isSelected = Info.Multi and Dropdown.Value[val] or (Dropdown.Value == val);
                    Tween(Btn, TI_FAST, { BackgroundTransparency = isSelected and 0.55 or 1, TextColor3 = isSelected and Library.AccentColor or Library.FontColor });
                end);

                Btn.MouseButton1Click:Connect(function()
                    Library:PlaySound('dropdown');
                    if Info.Multi then Dropdown.Value[val] = not Dropdown.Value[val];
                    else Dropdown.Value = val; Dropdown:Close(); end
                    Dropdown:Display();
                    Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
                    Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
                    Library:AttemptSave();
                end);

                local isSelected = Info.Multi and Dropdown.Value[val] or (Dropdown.Value == val);
                if isSelected then
                    Btn.BackgroundTransparency = 0.55;
                    Btn.TextColor3 = Library.AccentColor;
                end
            end
            RecalculateListPosition();
        end

        function Dropdown:Open()
            Library:PlaySound('dropdown');
            Dropdown:BuildDropdownList();
            RecalculateListPosition();
            ListOuter.GroupTransparency = 1;
            ListOuter.Visible = true;
            DropScale.Scale = 0.94;
            Tween(DropScale, TI_SPRING, { Scale = 1.0 });
            Tween(ListOuter, TI_FAST, { GroupTransparency = 0 });
            Tween(Arrow, TI_SPRING, { Rotation = 180, ImageColor3 = Library.AccentColor });
            Tween(DropStroke, TI_SMOOTH, { Color = Library.AccentColor, Transparency = 0.1 });
            Library.OpenedFrames[ListOuter] = true;
        end

        function Dropdown:Close()
            Tween(DropScale, TI_FAST, { Scale = 0.94 });
            Tween(ListOuter, TI_FAST, { GroupTransparency = 1 });
            Tween(Arrow, TI_SPRING, { Rotation = 0, ImageColor3 = Color3.fromRGB(170, 165, 190) });
            Tween(DropStroke, TI_SMOOTH, { Color = Library.OutlineColor, Transparency = 0.45 });
            task.delay(0.12, function()
                if not Library.OpenedFrames[ListOuter] then
                    ListOuter.Visible = false;
                end
            end);
            Library.OpenedFrames[ListOuter] = nil;
        end

        DropdownOuter.MouseButton1Click:Connect(function()
            if not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then Dropdown:Close(); else Dropdown:Open(); end
            end
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and ListOuter.Visible then
                if not Library:IsMouseOverFrame(ListOuter) and not Library:IsMouseOverFrame(DropdownOuter) then Dropdown:Close(); end
            end
        end));

        function Dropdown:SetValue(Val) Dropdown.Value = Val; Dropdown:Display(); Library:SafeCallback(Dropdown.Callback, Dropdown.Value); Library:SafeCallback(Dropdown.Changed, Dropdown.Value); end
        function Dropdown:SetValues(NewValues) Dropdown.Values = NewValues; Dropdown:BuildDropdownList(); Dropdown:Display(); end
        function Dropdown:OnChanged(Func) Dropdown.Changed = Func; Func(Dropdown.Value); end

        Dropdown:Display();
        Groupbox:AddBlank(2);
        Groupbox:Resize();
        Dropdown.Outer = DropdownRow;
        setmetatable(Dropdown, BaseAddons);

        Options[Idx] = Dropdown;
        return Dropdown;
    end

    function Funcs:AddDependencyBox()
        local Depbox = { Dependencies = {} };
        local Groupbox = self;

        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            ZIndex = 1;
            Parent = Groupbox.Container;
        });

        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            ZIndex = 1;
            Parent = Holder;
        });

        Library:Create('UIListLayout', { FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Parent = Frame });

        function Depbox:Resize()
            local Size = 0;
            for _, Element in next, Frame:GetChildren() do
                if not Element:IsA('UIListLayout') and Element.Visible then Size = Size + Element.Size.Y.Offset; end
            end
            Holder.Size = UDim2.new(1, 0, 0, Size);
            Groupbox:Resize();
        end

        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1];
                local Expected = Dependency[2];
                if (not Elem) or Elem.Value ~= Expected then
                    Holder.Visible = false;
                    Depbox:Resize();
                    return;
                end
            end
            Holder.Visible = true;
            Depbox:Resize();
        end

        function Depbox:SetupDependencies(Dependencies)
            Depbox.Dependencies = Dependencies;
            Depbox:Update();
        end

        Depbox.Container = Frame;
        setmetatable(Depbox, BaseGroupbox);
        table.insert(Library.DependencyBoxes, Depbox);
        return Depbox;
    end

    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Table, Key, ...) return Funcs[Key](...); end
    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Table, Key, ...) return Funcs[Key](...); end
end

-- < Master Notification Engine >
do
    local NotifConfig = {
        Preset = 'Bottom Right',
        CustomX = 98,
        CustomY = 98,
        Width = 280,
    };

    Library.NotificationArea = Library:Create('Frame', {
        Name = 'MikuNotificationArea',
        BackgroundTransparency = 1;
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 280, 0, 400),
        ZIndex = 5000;
        Parent = ScreenGui;
    });

    local NotifLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, 8);
        FillDirection = Enum.FillDirection.Vertical;
        VerticalAlignment = Enum.VerticalAlignment.Bottom;
        HorizontalAlignment = Enum.HorizontalAlignment.Right;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.NotificationArea;
    });

    function Library:ConfigureNotifications(cfg)
        cfg = cfg or {};
        if cfg.Preset then NotifConfig.Preset = cfg.Preset; end
        if cfg.CustomX ~= nil then NotifConfig.CustomX = cfg.CustomX; end
        if cfg.CustomY ~= nil then NotifConfig.CustomY = cfg.CustomY; end
        if cfg.PositionX ~= nil then NotifConfig.CustomX = cfg.PositionX; NotifConfig.Preset = 'Custom'; end
        if cfg.PositionY ~= nil then NotifConfig.CustomY = cfg.PositionY; NotifConfig.Preset = 'Custom'; end
        if cfg.Width then NotifConfig.Width = cfg.Width; end

        local area = Library.NotificationArea;
        if not area then return end

        local p = NotifConfig.Preset;
        local w = NotifConfig.Width or 280;
        area.Size = UDim2.new(0, w, 0, 450);

        if p == 'Bottom Right' then
            area.AnchorPoint = Vector2.new(1, 1);
            area.Position = UDim2.new(1, -16, 1, -16);
            NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom;
            NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right;
        elseif p == 'Bottom Left' then
            area.AnchorPoint = Vector2.new(0, 1);
            area.Position = UDim2.new(0, 16, 1, -16);
            NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom;
            NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left;
        elseif p == 'Bottom Center' then
            area.AnchorPoint = Vector2.new(0.5, 1);
            area.Position = UDim2.new(0.5, 0, 1, -16);
            NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom;
            NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
        elseif p == 'Top Right' then
            area.AnchorPoint = Vector2.new(1, 0);
            area.Position = UDim2.new(1, -16, 0, 16);
            NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Top;
            NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right;
        elseif p == 'Top Left' then
            area.AnchorPoint = Vector2.new(0, 0);
            area.Position = UDim2.new(0, 16, 0, 16);
            NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Top;
            NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left;
        elseif p == 'Top Center' then
            area.AnchorPoint = Vector2.new(0.5, 0);
            area.Position = UDim2.new(0.5, 0, 0, 16);
            NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Top;
            NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
        elseif p == 'Middle Right' then
            area.AnchorPoint = Vector2.new(1, 0.5);
            area.Position = UDim2.new(1, -16, 0.5, 0);
            NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Center;
            NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right;
        elseif p == 'Middle Left' then
            area.AnchorPoint = Vector2.new(0, 0.5);
            area.Position = UDim2.new(0, 16, 0.5, 0);
            NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Center;
            NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left;
        elseif p == 'Custom' then
            local xNorm = math.clamp((NotifConfig.CustomX or 98) / 100, 0, 1);
            local yNorm = math.clamp((NotifConfig.CustomY or 98) / 100, 0, 1);
            area.AnchorPoint = Vector2.new(xNorm, yNorm);
            local offsetXPx = (xNorm <= 0.2 and 16) or (xNorm >= 0.8 and -16) or 0;
            local offsetYPx = (yNorm <= 0.2 and 16) or (yNorm >= 0.8 and -16) or 0;
            area.Position = UDim2.new(xNorm, offsetXPx, yNorm, offsetYPx);
            NotifLayout.VerticalAlignment = yNorm > 0.5 and Enum.VerticalAlignment.Bottom or Enum.VerticalAlignment.Top;
            NotifLayout.HorizontalAlignment = xNorm > 0.6 and Enum.HorizontalAlignment.Right or (xNorm < 0.4 and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center);
        end
    end

    local WatermarkOuter = Library:Create('Frame', {
        BackgroundColor3 = Color3.fromRGB(18, 17, 26);
        BackgroundTransparency = 0.15;
        Position = UDim2.new(0, 20, 0, 20);
        Size = UDim2.new(0, 180, 0, 28);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Control), Parent = WatermarkOuter });
    local WStroke = Library:Create('UIStroke', { Color = Library.OutlineColor, Transparency = 0.35, Thickness = 1, Parent = WatermarkOuter });
    Library:AddToRegistry(WStroke, { Color = 'OutlineColor' });

    Library:Create('ImageLabel', {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 16, 1, 16),
        BackgroundTransparency = 1,
        Image = 'rbxassetid://6015897843',
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.5,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ScaleType = Enum.ScaleType.Slice,
        SliceScale = 1,
        ZIndex = 199,
        Parent = WatermarkOuter,
    });

    local WatermarkAccent = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0.5, -3);
        Size = UDim2.new(0, 6, 0, 6);
        ZIndex = 201;
        Parent = WatermarkOuter;
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = WatermarkAccent });
    Library:AddToRegistry(WatermarkAccent, { BackgroundColor3 = 'AccentColor' });

    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 18, 0, 0);
        Size = UDim2.new(1, -24, 1, 0);
        TextSize = 12;
        Text = 'miku';
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 201;
        Parent = WatermarkOuter;
    });

    Library.Watermark = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;
    Library:MakeDraggable(Library.Watermark);

    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5);
        BackgroundColor3 = Color3.fromRGB(18, 17, 26);
        BackgroundTransparency = 0.15;
        Position = UDim2.new(0, 20, 0.5, 0);
        Size = UDim2.new(0, 190, 0, 30);
        Visible = false;
        ZIndex = 100;
        Parent = ScreenGui;
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Control), Parent = KeybindOuter });
    local KbStroke = Library:Create('UIStroke', { Color = Library.OutlineColor, Transparency = 0.35, Thickness = 1, Parent = KeybindOuter });
    Library:AddToRegistry(KbStroke, { Color = 'OutlineColor' });

    Library:Create('ImageLabel', {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 16, 1, 16),
        BackgroundTransparency = 1,
        Image = 'rbxassetid://6015897843',
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.5,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ScaleType = Enum.ScaleType.Slice,
        SliceScale = 1,
        ZIndex = 99,
        Parent = KeybindOuter,
    });

    local KeybindHeader = Library:CreateLabel({
        Size = UDim2.new(1, -16, 0, 28);
        Position = UDim2.fromOffset(10, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = 'keybinds',
        TextColor3 = Library.AccentColor;
        TextSize = 12,
        ZIndex = 104,
        Parent = KeybindOuter;
    });
    Library:AddToRegistry(KeybindHeader, { TextColor3 = 'AccentColor' });

    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        ClipsDescendants = true;
        Size = UDim2.new(1, -16, 1, -28);
        Position = UDim2.new(0, 8, 0, 28);
        ZIndex = 101;
        Parent = KeybindOuter;
    });

    local kbLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    });
    Library.KeybindFrame = KeybindOuter;
    Library.KeybindContainer = KeybindContainer;

    local function ResizeKeybindFrame()
        task.defer(function()
            if not KeybindOuter or not KeybindOuter.Parent or not kbLayout or not kbLayout.Parent then return end
            local contentH = kbLayout.AbsoluteContentSize.Y;
            Tween(KeybindOuter, TI_SMOOTH, { Size = UDim2.new(0, 190, 0, math.max(30, 34 + contentH)) });
        end);
    end
    Library.ResizeKeybindFrame = ResizeKeybindFrame;
    kbLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(ResizeKeybindFrame);

    Library:MakeDraggable(KeybindOuter);
end

function Library:SetWatermarkVisibility(Bool) Library.Watermark.Visible = Bool; end
function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, 13);
    Library.Watermark.Size = UDim2.new(0, X + 27, 0, 28);
    Library.WatermarkText.Text = Text;
    Library:SetWatermarkVisibility(true);
end

function Library:Notify(Text, Time)
    Time = Time or 4;
    local cardWidth = 280;
    local textBoundsX, textBoundsY = Library:GetTextBounds(Text, Library.Font, 12, Vector2.new(cardWidth - 40, math.huge));
    local cardHeight = math.max(textBoundsY + 22, 42);

    local NotifyCard = Library:Create('CanvasGroup', {
        Name = 'NotifyCard',
        GroupTransparency = 1;
        BackgroundColor3 = Library.BackgroundColor,
        Size = UDim2.new(0, cardWidth, 0, cardHeight),
        ZIndex = 5001,
        Parent = Library.NotificationArea,
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Control), Parent = NotifyCard });
    local Stroke = Library:Create('UIStroke', { Color = Library.OutlineColor, Transparency = 0.15, Thickness = 1.2, Parent = NotifyCard });
    Library:AddToRegistry(Stroke, { Color = 'OutlineColor' });
    Library:AddToRegistry(NotifyCard, { BackgroundColor3 = 'BackgroundColor' });

    local CardScale = Library:Create('UIScale', { Scale = 0.88, Parent = NotifyCard });

    local LeftBar = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, -8),
        AnchorPoint = Vector2.new(0, 0.5);
        Position = UDim2.new(0, 5, 0.5, 0);
        ZIndex = 5002,
        Parent = NotifyCard,
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = LeftBar });
    Library:AddToRegistry(LeftBar, { BackgroundColor3 = 'AccentColor' });

    local Dot = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(4, 4),
        Position = UDim2.new(0, 14, 0, 8),
        ZIndex = 5003,
        Parent = NotifyCard,
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = Dot });
    Library:AddToRegistry(Dot, { BackgroundColor3 = 'AccentColor' });

    local HeaderTag = Library:CreateLabel({
        Position = UDim2.new(0, 22, 0, 3),
        Size = UDim2.new(1, -26, 0, 14),
        Text = 'NOTIFICATION',
        TextColor3 = Library.AccentColor,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5003,
        Parent = NotifyCard,
    });
    Library:AddToRegistry(HeaderTag, { TextColor3 = 'AccentColor' });

    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, 14, 0, 18),
        Size = UDim2.new(1, -22, 0, textBoundsY + 2),
        Text = Text,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5002,
        Parent = NotifyCard,
    });

    local TimeTrack = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        BorderSizePixel = 0,
        ZIndex = 5003,
        Parent = NotifyCard,
    });
    local TimeFill = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 5004,
        Parent = TimeTrack,
    });
    Library:AddToRegistry(TimeFill, { BackgroundColor3 = 'AccentColor' });

    Tween(NotifyCard, TI_SMOOTH, { GroupTransparency = 0 });
    Tween(CardScale, TI_POP, { Scale = 1 });
    Tween(TimeFill, TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { Size = UDim2.new(0, 0, 1, 0) });

    task.delay(Time, function()
        Tween(NotifyCard, TI_SMOOTH, { GroupTransparency = 1 });
        Tween(CardScale, TI_SMOOTH, { Scale = 0.92 });
        task.wait(0.25);
        NotifyCard:Destroy();
    end);
end

function Library:Loader(Info)
    Info = Info or {};
    local Name = Info.Name or 'MIKU';
    local Duration = Info.Duration or 2;

    task.spawn(function()
        local LoaderGui = Library:Create('CanvasGroup', {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(280, 116),
            GroupTransparency = 1;
            BackgroundColor3 = Library.BackgroundColor,
            ZIndex = 9000,
            Parent = ScreenGui,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Window), Parent = LoaderGui });
        Library:Create('UIStroke', { Color = Library.OutlineColor, Thickness = 1.2, Parent = LoaderGui });

        local AccentDot = Library:Create('Frame', {
            AnchorPoint = Vector2.new(0.5, 0);
            Position = UDim2.new(0.5, 0, 0, 16),
            Size = UDim2.fromOffset(6, 6),
            BackgroundColor3 = Library.AccentColor,
            ZIndex = 9001,
            Parent = LoaderGui,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = AccentDot });

        Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 30),
            Size = UDim2.new(1, 0, 0, 26),
            Text = Name,
            TextColor3 = Library.AccentColor,
            TextSize = 20,
            ZIndex = 9001,
            Parent = LoaderGui,
        });

        local ProgressTrack = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            Position = UDim2.new(0, 28, 0, 72),
            Size = UDim2.new(1, -56, 0, 5),
            ZIndex = 9001,
            Parent = LoaderGui,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = ProgressTrack });

        local ProgressBar = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0),
            ZIndex = 9002,
            Parent = ProgressTrack,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = ProgressBar });

        Tween(LoaderGui, TI_SMOOTH, { GroupTransparency = 0 });
        Tween(AccentDot, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Size = UDim2.fromOffset(10, 10) });
        Tween(ProgressBar, TweenInfo.new(Duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 1, 0) });
        task.wait(Duration + 0.25);
        Tween(LoaderGui, TI_SMOOTH, { GroupTransparency = 1 });
        task.wait(0.3);
        LoaderGui:Destroy();
    end);
end

-- Spiderweb Physics Engine Support
local WebManager = {
    Container = nil,
    StrandPool = {},
    ActiveStrands = 0,
    Window = nil,
    Enabled = false,
};

function WebManager:Init(Window)
    self.Window = Window;
end
function WebManager:Update() end
function WebManager:SetEnabled(enabled) self.Enabled = (enabled == true); end

Library.WebManager = WebManager;
function Library:SetWebMesh(enabled) WebManager:SetEnabled(enabled); end
function Library:ToggleWebMesh(enabled) WebManager:SetEnabled(enabled); end

-- Global Font & Outline Management System
Library.FontMap = {
    ["Code"] = Enum.Font.Code,
    ["Gotham"] = Enum.Font.Gotham,
    ["GothamMedium"] = Enum.Font.GothamMedium,
    ["GothamBold"] = Enum.Font.GothamBold,
    ["RobotoMono"] = Enum.Font.RobotoMono,
    ["Ubuntu"] = Enum.Font.Ubuntu,
    ["SourceSans"] = Enum.Font.SourceSans,
    ["SourceSansBold"] = Enum.Font.SourceSansBold,
    ["Arcade"] = Enum.Font.Arcade,
};

Library.DrawingFontMap = {
    ["Code"] = 3,
    ["Gotham"] = 1,
    ["GothamMedium"] = 1,
    ["GothamBold"] = 1,
    ["RobotoMono"] = 3,
    ["Ubuntu"] = 1,
    ["SourceSans"] = 0,
    ["SourceSansBold"] = 0,
    ["Arcade"] = 2,
};

Library.TextOutline = true;
Library.TextOutlineColor = Color3.fromRGB(0, 0, 0);

function Library:SetFont(fontName)
    local targetFont = Library.FontMap[fontName] or Enum.Font.GothamMedium;
    Library.Font = targetFont;
    getgenv().MikuCurrentFont = targetFont;
    getgenv().MikuCurrentDrawingFont = Library.DrawingFontMap[fontName] or 1;

    for _, obj in ipairs(ScreenGui:GetDescendants()) do
        if obj:IsA('TextLabel') or obj:IsA('TextButton') or obj:IsA('TextBox') then
            pcall(function()
                obj.Font = targetFont;
            end);
        end
    end
    if getgenv().MikuRefreshESPFont then
        pcall(getgenv().MikuRefreshESPFont);
    end
end

function Library:SetTextOutline(enabled, color)
    Library.TextOutline = (enabled == true);
    if color then Library.TextOutlineColor = color; end
    getgenv().MikuTextOutlineEnabled = Library.TextOutline;
    getgenv().MikuTextOutlineColor = Library.TextOutlineColor;

    for _, obj in ipairs(ScreenGui:GetDescendants()) do
        if obj:IsA('TextLabel') and obj.Name ~= "TabBtnText" and obj.Name ~= "BrandText" then
            local stroke = obj:FindFirstChildOfClass('UIStroke');
            if Library.TextOutline then
                if not stroke then
                    stroke = Instance.new('UIStroke');
                    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual;
                    stroke.Color = Library.TextOutlineColor;
                    stroke.Transparency = 0;
                    stroke.Thickness = 1;
                    stroke.Parent = obj;
                else
                    stroke.Color = Library.TextOutlineColor;
                    stroke.Transparency = 0;
                end
            else
                if stroke then
                    stroke.Transparency = 1;
                end
                pcall(function()
                    obj.TextStrokeTransparency = 1;
                end);
            end
        end
    end
    if getgenv().MikuRefreshESPFont then
        pcall(getgenv().MikuRefreshESPFont);
    end
end

-- ====================================================================
-- UNIFIED LIQUID GLASS MAIN WINDOW WITH EXPANDABLE LEFT SIDEBAR
-- ====================================================================
function Library:CreateWindow(...)
    EnsureScreenGui();
    local Arguments = { ... };
    local Config = { AnchorPoint = Vector2.zero };

    if type(...) == 'table' then Config = ...;
    else Config.Title = Arguments[1]; Config.AutoShow = Arguments[2] or false; end

    Config.Title = Config.Title or 'MIKU';
    Config.TabPadding = Config.TabPadding or 6;
    Config.MenuFadeTime = Config.MenuFadeTime or 0.2;

    local Window = { Tabs = {}, ModularWindows = {} };
    Window.AutoShow = (Config.AutoShow ~= false);

    WebManager:Init(Window);

    local cam = workspace.CurrentCamera;
    local vpX = cam and cam.ViewportSize.X or 1920;
    local vpY = cam and cam.ViewportSize.Y or 1080;
    local winW = 880;
    local winH = 540;
    local startX = math.max(16, math.floor((vpX - winW) / 2));
    local startY = math.max(16, math.floor((vpY - winH) / 2));

    -- Master Unified Window Container (Glossy Frosted Liquid Glass)
    local MainWindow = Library:Create('Frame', {
        Name = 'MikuMainWindow',
        Position = UDim2.fromOffset(startX, startY),
        Size = UDim2.fromOffset(winW, winH),
        BackgroundColor3 = THEME.WindowBg,
        BackgroundTransparency = THEME.WindowOpacity,
        ZIndex = 10,
        Active = true,
        Parent = ScreenGui,
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Window), Parent = MainWindow });
    local MainStroke = Library:Create('UIStroke', {
        Color = THEME.Border,
        Transparency = 0.18,
        Thickness = 1.5,
        Parent = MainWindow,
    });
    Library:AddToRegistry(MainStroke, { Color = 'OutlineColor' });

    -- Deep outer shadow (large spread, low opacity)
    Library:Create('ImageLabel', {
        Name = 'WindowShadowOuter',
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 56, 1, 56),
        BackgroundTransparency = 1,
        Image = 'rbxassetid://6015897843',
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.55,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ScaleType = Enum.ScaleType.Slice,
        SliceScale = 1,
        ZIndex = 8,
        Parent = MainWindow,
    });
    -- Inner shadow (tighter, stronger)
    Library:Create('ImageLabel', {
        Name = 'WindowShadow',
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 24, 1, 24),
        BackgroundTransparency = 1,
        Image = 'rbxassetid://6015897843',
        ImageColor3 = Color3.fromRGB(5, 0, 20),
        ImageTransparency = THEME.ShadowOpacity,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ScaleType = Enum.ScaleType.Slice,
        SliceScale = 1,
        ZIndex = 9,
        Parent = MainWindow,
    });

    -- Top-left Mica specular highlight — soft diagonal light sheen from top
    local WindowSheen = Library:Create('Frame', {
        Name = 'WindowGlassSheen',
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = THEME.SheenOpacity,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 0, 120),
        ZIndex = 11,
        Parent = MainWindow,
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Window), Parent = WindowSheen });
    Library:Create('UIGradient', {
        Rotation = 110,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.28, Color3.fromRGB(220, 200, 255)),
            ColorSequenceKeypoint.new(0.65, Color3.fromRGB(160, 130, 240)),
            ColorSequenceKeypoint.new(1,    Color3.fromRGB(100, 80, 180)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,    0.32),
            NumberSequenceKeypoint.new(0.35, 0.78),
            NumberSequenceKeypoint.new(0.75, 0.94),
            NumberSequenceKeypoint.new(1,    1),
        }),
        Parent = WindowSheen,
    });
    Library.WindowSheen = WindowSheen;

    -- Bottom edge inner glow (subtle purple tint at base)
    local WindowBottomGlow = Library:Create('Frame', {
        Name = 'WindowBottomGlow',
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = THEME.Accent,
        BackgroundTransparency = 0.92,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 11,
        Parent = MainWindow,
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Window), Parent = WindowBottomGlow });
    Library:Create('UIGradient', {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = WindowBottomGlow,
    });

    local WinScale = Library:Create('UIScale', { Scale = 1, Parent = MainWindow });

    -- Drag Handle (Main Header Area)
    local WindowDragHandle = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 50),
        ZIndex = 12,
        Parent = MainWindow,
    });
    Library:MakeDraggable(MainWindow, WindowDragHandle);

    -- ================================================================
    -- EXPANDABLE LEFT NAVIGATION RAIL (SIDEBAR)
    -- ================================================================
    local CollapsedSidebarW = THEME.SidebarW;
    local ExpandedSidebarW = THEME.SidebarExpandedW;
    local isSidebarExpanded = false;

    local Sidebar = Library:Create('Frame', {
        Name = 'MikuSidebarRail',
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.new(0, CollapsedSidebarW, 1, -20),
        BackgroundColor3 = THEME.SidebarBg,
        BackgroundTransparency = THEME.SidebarOpacity,
        ClipsDescendants = true,
        ZIndex = 50,
        Parent = MainWindow,
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Sidebar), Parent = Sidebar });
    local SidebarStroke = Library:Create('UIStroke', {
        Color = THEME.Border,
        Transparency = 0.28,
        Thickness = 1.2,
        Parent = Sidebar,
    });
    Library:AddToRegistry(SidebarStroke, { Color = 'OutlineColor' });
    Library.Sidebar = Sidebar;

    -- Sidebar top-edge inner highlight (glass top-light effect)
    local SidebarTopEdge = Library:Create('Frame', {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 0, 60),
        ZIndex = 51,
        Parent = Sidebar,
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Sidebar), Parent = SidebarTopEdge });
    Library:Create('UIGradient', {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.65),
            NumberSequenceKeypoint.new(0.6, 0.92),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = SidebarTopEdge,
    });

    -- Sidebar ambient drop shadow
    Library:Create('ImageLabel', {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 18, 1, 18),
        BackgroundTransparency = 1,
        Image = 'rbxassetid://6015897843',
        ImageColor3 = Color3.fromRGB(0, 0, 5),
        ImageTransparency = 0.50,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ScaleType = Enum.ScaleType.Slice,
        SliceScale = 1,
        ZIndex = 49,
        Parent = Sidebar,
    });

    -- ================================================================
    -- BRANDING HEADER (Non-Interactive — just logo + name)
    -- ================================================================
    local BrandPill = Library:Create('Frame', {
        Name = 'MikuBrandPill',
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(1, -16, 0, 46),
        BackgroundColor3 = Color3.fromRGB(28, 24, 42),
        BackgroundTransparency = 0.28,
        ClipsDescendants = true,
        ZIndex = 51,
        Parent = Sidebar,
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(0, 12), Parent = BrandPill });
    local BrandStroke = Library:Create('UIStroke', {
        Color = THEME.Accent,
        Transparency = 0.72,
        Thickness = 1,
        Parent = BrandPill
    });
    -- Subtle accent gradient for branding feel
    Library:Create('UIGradient', {
        Rotation = 135,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 35, 70)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(26, 22, 40)),
        }),
        Parent = BrandPill,
    });

    local customLogoAsset = nil
    pcall(function()
        local getAsset = getcustomasset or getsynasset
        if getAsset then
            for _, p in ipairs({ "miku/logo.png", "miku ui/logo.png", "logo.png" }) do
                if isfile and isfile(p) then
                    local ok, res = pcall(getAsset, p)
                    if ok and res and type(res) == "string" and #res > 0 then
                        customLogoAsset = res
                        break
                    end
                end
            end
        end
    end)

    local BrandIcon = Library:Create('ImageLabel', {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.fromOffset(26, 26),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = customLogoAsset or 'rbxassetid://138635884129147',
        ImageColor3 = Color3.fromRGB(255, 255, 255),
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 52,
        Parent = BrandPill,
    });

    local BrandText = Library:Create('TextLabel', {
        Name = 'BrandText',
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0, 4),
        Size = UDim2.new(1, -48, 0.55, 0),
        Font = Enum.Font.GothamBold,
        Text = 'MIKU',
        TextSize = 13,
        TextColor3 = THEME.FontPrimary,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
        Visible = false,
        ZIndex = 52,
        Parent = BrandPill,
    });

    local BrandSubText = Library:Create('TextLabel', {
        Name = 'BrandSubText',
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0.58, 0),
        Size = UDim2.new(1, -48, 0.4, 0),
        Font = Enum.Font.Gotham,
        Text = 'Rivals',
        TextSize = 10,
        TextColor3 = THEME.FontDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
        Visible = false,
        ZIndex = 52,
        Parent = BrandPill,
    });

    -- Subtle pulse for branding icon (soft glow, not distracting)
    task.spawn(function()
        local t = 0;
        while BrandIcon.Parent do
            t = t + 1;
            Tween(BrandIcon, TweenInfo.new(2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                ImageTransparency = (t % 2 == 0) and 0.0 or 0.28,
            });
            task.wait(2.0);
        end
    end);


    local TabScroll = Library:Create('ScrollingFrame', {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 64),
        Size = UDim2.new(1, -16, 1, -114),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 51,
        Parent = Sidebar,
    });

    local TabLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, 8),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabScroll,
    });

    local SidebarFooter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -8),
        Size = UDim2.new(1, -8, 0, 32),
        BackgroundTransparency = 1,
        ZIndex = 51,
        Parent = Sidebar,
    });
    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = SidebarFooter,
    });

    local function CreateSidebarActionBtn(iconAsset, tooltip, defaultCol, hoverCol)
        local btn = Library:Create('TextButton', {
            AutoButtonColor = false,
            BackgroundColor3 = Color3.fromRGB(26, 22, 38),
            BackgroundTransparency = 0.25,
            Size = UDim2.fromOffset(26, 26),
            Text = '',
            ZIndex = 52,
            Parent = SidebarFooter,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, 8), Parent = btn });
        local st = Library:Create('UIStroke', { Color = THEME.Border, Transparency = 0.35, Thickness = 1, Parent = btn });

        local ic = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            Image = iconAsset,
            ImageColor3 = defaultCol,
            ZIndex = 53,
            Parent = btn,
        });

        btn.MouseEnter:Connect(function()
            Tween(btn, TI_FAST, { BackgroundColor3 = Color3.fromRGB(40, 34, 58), BackgroundTransparency = 0.12 });
            Tween(ic, TI_FAST, { ImageColor3 = hoverCol });
            Tween(st, TI_FAST, { Color = hoverCol, Transparency = 0.08 });
        end);
        btn.MouseLeave:Connect(function()
            Tween(btn, TI_FAST, { BackgroundColor3 = Color3.fromRGB(26, 22, 38), BackgroundTransparency = 0.25 });
            Tween(ic, TI_FAST, { ImageColor3 = defaultCol });
            Tween(st, TI_FAST, { Color = THEME.Border, Transparency = 0.35 });
        end);

        if tooltip then Library:AddToolTip(tooltip, btn); end
        return btn;
    end

    local PanicBtn = CreateSidebarActionBtn('rbxassetid://114995877719925', 'Panic (Disable All)', Library.DimColor, Color3.fromRGB(255, 95, 105));
    local CloseAllBtn = CreateSidebarActionBtn('rbxassetid://96479131758775', 'Hide Menu [RightShift]', Library.DimColor, Library.AccentColor);

    PanicBtn.MouseButton1Click:Connect(function()
        Library:PlaySound('click');
        Library:Panic();
    end);

    CloseAllBtn.MouseButton1Click:Connect(function()
        Library:PlaySound('click');
        Library:Toggle();
    end);

    -- Force refreshes all tab buttons to ensure NO leftover hover styles
    local function RefreshAllTabButtons()
        for _, tab in ipairs(Window.Tabs) do
            if tab.RefreshPill then
                tab:RefreshPill(false);
            end
        end
    end

    -- Floating tab preview pill when hovering over collapsed sidebar tab (Reference UI Match)
    local TabTooltipPill = Library:Create('CanvasGroup', {
        Name = 'MikuTabTooltipPill',
        GroupTransparency = 1,
        Size = UDim2.fromOffset(90, 30),
        BackgroundColor3 = Color3.fromRGB(24, 22, 34),
        Visible = false,
        ZIndex = 6000,
        Parent = ScreenGui,
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(0, 8), Parent = TabTooltipPill });
    local TtStroke = Library:Create('UIStroke', { Color = Library.OutlineColor, Transparency = 0.35, Thickness = 1, Parent = TabTooltipPill });

    local TtAccentBar = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.fromOffset(3, 14),
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        ZIndex = 6001,
        Parent = TabTooltipPill,
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = TtAccentBar });
    Library:AddToRegistry(TtAccentBar, { BackgroundColor3 = 'AccentColor' });

    local TtLabel = Library:CreateLabel({
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(250, 250, 255),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6001,
        Parent = TabTooltipPill,
    });

    local function ShowTabTooltip(tabObj)
        if isSidebarExpanded or not tabObj or not tabObj.TabButton then
            TabTooltipPill.Visible = false;
            return;
        end
        local abs = tabObj.TabButton.AbsolutePosition;
        local nameText = tabObj.Name:sub(1,1):upper() .. tabObj.Name:sub(2);
        local tw, th = Library:GetTextBounds(nameText, Enum.Font.GothamBold, 12);
        TabTooltipPill.Size = UDim2.fromOffset(tw + 28, 30);
        TabTooltipPill.Position = UDim2.fromOffset(abs.X + tabObj.TabButton.AbsoluteSize.X + 8, abs.Y + 7);
        TtLabel.Text = nameText;
        TabTooltipPill.Visible = true;
        Tween(TabTooltipPill, TI_FAST, { GroupTransparency = 0 });
    end

    local function HideTabTooltip()
        Tween(TabTooltipPill, TI_FAST, { GroupTransparency = 1 });
        task.delay(0.12, function()
            if TabTooltipPill.GroupTransparency >= 0.9 then
                TabTooltipPill.Visible = false;
            end
        end);
    end

    local HeaderBar, HeaderSep, TabViewport;

    -- Instant Text Hiding on Sidebar Collapse (Zero Lingering Microsecond)
    local function UpdateSidebarExpansion(expand)
        if isSidebarExpanded == expand then return end
        isSidebarExpanded = expand;

        local targetW = expand and ExpandedSidebarW or CollapsedSidebarW;

        if not expand then
            -- INSTANTLY hide brand text and all tab texts on frame 0
            BrandText.Visible = false;
            BrandText.TextTransparency = 1;
            if BrandSubText then BrandSubText.Visible = false; BrandSubText.TextTransparency = 1; end
            for _, tab in ipairs(Window.Tabs) do
                if tab.TabBtnText then
                    tab.TabBtnText.Visible = false;
                    tab.TabBtnText.TextTransparency = 1;
                end
            end
            HideTabTooltip();
        end

        local curSidebarTrans = Library.LiquidGlass and THEME.SidebarOpacity or math.clamp(1 - (Library.GlobalOpacity or 0.85) + 0.15, 0, 0.95);
        Tween(Sidebar, TI_SMOOTH, {
            Size = UDim2.new(0, targetW, 1, -20),
            BackgroundColor3 = expand and Color3.fromRGB(18, 16, 28) or THEME.SidebarBg,
            BackgroundTransparency = curSidebarTrans,
        });

        if expand then
            BrandText.Visible = true;
            Tween(BrandText, TI_FAST, { TextTransparency = 0 });
            if BrandSubText then BrandSubText.Visible = true; Tween(BrandSubText, TI_FAST, { TextTransparency = 0 }); end
            HideTabTooltip();
        end

        local CollapsedContentX = 82;
        local ExpandedContentX = 196;
        local targetContentX = expand and ExpandedContentX or CollapsedContentX;

        if HeaderBar then
            Tween(HeaderBar, TI_SMOOTH, {
                Position = UDim2.fromOffset(targetContentX, 10),
                Size = UDim2.new(1, -(targetContentX + 14), 0, 38)
            });
        end
        if HeaderSep then
            Tween(HeaderSep, TI_SMOOTH, {
                Position = UDim2.fromOffset(targetContentX, 50),
                Size = UDim2.new(1, -(targetContentX + 14), 0, 1)
            });
        end
        if TabViewport then
            Tween(TabViewport, TI_SMOOTH, {
                Position = UDim2.fromOffset(targetContentX, 56),
                Size = UDim2.new(1, -(targetContentX + 14), 1, -66)
            });
        end

        for _, tab in ipairs(Window.Tabs) do
            if tab.TabButton and tab.TabBtnIcon and tab.TabBtnText then
                if expand then
                    tab.TabBtnText.Visible = true;
                    Tween(tab.TabButton, TI_SMOOTH, { Size = UDim2.new(1, 0, 0, 44) });
                    Tween(tab.TabBtnIcon, TI_SMOOTH, { Position = UDim2.new(0, 14, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5) });
                    Tween(tab.TabBtnText, TI_FAST, { TextTransparency = 0 });
                else
                    Tween(tab.TabButton, TI_SMOOTH, { Size = UDim2.fromOffset(THEME.TabBtnSize, 44) });
                    Tween(tab.TabBtnIcon, TI_SMOOTH, { Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5) });
                end
            end
        end

        if not expand then
            RefreshAllTabButtons();
        end
    end

    Sidebar.MouseEnter:Connect(function()
        UpdateSidebarExpansion(true);
    end);

    Sidebar.MouseLeave:Connect(function()
        UpdateSidebarExpansion(false);
    end);

    -- ================================================================
    -- CONTENT AREA (RIGHT SIDE OF WINDOW)
    -- ================================================================
    local ContentAreaX = 82;
    HeaderBar = Library:Create('Frame', {
        Name = 'MikuHeaderBar',
        Position = UDim2.fromOffset(ContentAreaX, 10),
        Size = UDim2.new(1, -(ContentAreaX + 14), 0, 38),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 13,
        Parent = MainWindow,
    });

    local HeaderLeft = Library:Create('Frame', {
        Position = UDim2.fromOffset(4, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 14,
        Parent = HeaderBar,
    });

    local HeaderTabIcon = Library:Create('ImageLabel', {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        BackgroundTransparency = 1,
        Image = 'rbxassetid://81872698913435',
        ImageColor3 = THEME.Accent,
        ZIndex = 15,
        Parent = HeaderLeft,
    });
    Library:AddToRegistry(HeaderTabIcon, { ImageColor3 = 'AccentColor' });

    local HeaderTabTitle = Library:CreateLabel({
        Position = UDim2.new(0, 26, 0, 0),
        Size = UDim2.new(1, -26, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = 'Combat',
        TextSize = 14,
        TextColor3 = Color3.fromRGB(250, 250, 255),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
        Parent = HeaderLeft,
    });

    local SearchBar = Library:Create('Frame', {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(220, 30),
        BackgroundColor3 = Color3.fromRGB(24, 22, 34),
        BackgroundTransparency = 0.25,
        ZIndex = 14,
        Parent = HeaderBar,
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(0, 10), Parent = SearchBar });
    local SearchStroke = Library:Create('UIStroke', {
        Color = Library.OutlineColor,
        Transparency = 0.4,
        Thickness = 1,
        Parent = SearchBar,
    });

    local SearchIcon = Library:Create('ImageLabel', {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
        Image = 'rbxassetid://121018724060431',
        ImageColor3 = Library.DimColor,
        ZIndex = 15,
        Parent = SearchBar,
    });

    local SearchBox = Library:Create('TextBox', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 28, 0, 0),
        Size = UDim2.new(1, -78, 1, 0),
        Font = Library.Font,
        PlaceholderColor3 = Color3.fromRGB(120, 115, 140),
        PlaceholderText = 'Search...',
        Text = '',
        TextColor3 = Color3.fromRGB(245, 245, 255),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 15,
        Parent = SearchBar,
    });

    local ShortcutBadge = Library:Create('Frame', {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.fromOffset(40, 18),
        BackgroundColor3 = Color3.fromRGB(36, 32, 50),
        BackgroundTransparency = 0.2,
        ZIndex = 15,
        Parent = SearchBar,
    });
    Library:Create('UICorner', { CornerRadius = UDim.new(0, 6), Parent = ShortcutBadge });
    Library:CreateLabel({
        Size = UDim2.fromScale(1, 1),
        Text = 'Ctrl+F',
        TextSize = 10,
        TextColor3 = Library.DimColor,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 16,
        Parent = ShortcutBadge,
    });

    SearchBox.Focused:Connect(function()
        Tween(SearchStroke, TI_FAST, { Color = Library.AccentColor, Transparency = 0.1 });
        Tween(SearchIcon, TI_FAST, { ImageColor3 = Library.AccentColor });
    end);

    SearchBox.FocusLost:Connect(function()
        Tween(SearchStroke, TI_SMOOTH, { Color = Library.OutlineColor, Transparency = 0.4 });
        Tween(SearchIcon, TI_SMOOTH, { ImageColor3 = Library.DimColor });
    end);

    HeaderSep = Library:Create('Frame', {
        BackgroundColor3 = Color3.fromRGB(90, 80, 130),
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(ContentAreaX, 50),
        Size = UDim2.new(1, -(ContentAreaX + 14), 0, 1),
        ZIndex = 13,
        Parent = MainWindow,
    });

    TabViewport = Library:Create('Frame', {
        Name = 'MikuTabViewport',
        Position = UDim2.fromOffset(ContentAreaX, 56),
        Size = UDim2.new(1, -(ContentAreaX + 14), 1, -66),
        BackgroundTransparency = 1,
        ZIndex = 13,
        Parent = MainWindow,
    });

    local TabIcons = {
        ['rage'] = 'rbxassetid://81872698913435',        -- Lucide: swords (Crossed Swords)
        ['combat'] = 'rbxassetid://81872698913435',      -- Lucide: swords
        ['main'] = 'rbxassetid://81872698913435',        -- Lucide: swords
        ['aim'] = 'rbxassetid://81872698913435',         -- Lucide: swords
        ['player'] = 'rbxassetid://81589895647169',      -- Lucide: user (Person Profile)
        ['character'] = 'rbxassetid://81589895647169',   -- Lucide: user
        ['visuals'] = 'rbxassetid://100033680381365',    -- Lucide: eye (Sharp Eye)
        ['esp'] = 'rbxassetid://100033680381365',        -- Lucide: eye
        ['world'] = 'rbxassetid://114238209622913',      -- Lucide: globe (Clean Globe)
        ['environment'] = 'rbxassetid://114238209622913',-- Lucide: globe
        ['misc'] = 'rbxassetid://81344910161871',        -- Lucide: layout-grid (Modular 2x2 Grid)
        ['utilities'] = 'rbxassetid://81344910161871',   -- Lucide: layout-grid
        ['automation'] = 'rbxassetid://81344910161871',  -- Lucide: layout-grid
        ['skins'] = 'rbxassetid://106579555405966',      -- Lucide: shirt (T-Shirt)
        ['cosmetics'] = 'rbxassetid://106579555405966',  -- Lucide: shirt
        ['ui'] = 'rbxassetid://85538382643347',          -- Lucide: sliders-horizontal (Equalizer Sliders)
        ['ui settings'] = 'rbxassetid://85538382643347', -- Lucide: sliders-horizontal
        ['config'] = 'rbxassetid://85538382643347',       -- Lucide: sliders-horizontal
        ['settings'] = 'rbxassetid://85538382643347',     -- Lucide: sliders-horizontal
    };

    local function ResolveTabIcon(name, customIcon)
        if customIcon then return customIcon; end
        local lower = string.lower(name or '');
        for key, icon in pairs(TabIcons) do
            if lower:find(key) then return icon; end
        end
        return 'rbxassetid://81344910161871'; -- Lucide layout-grid fallback
    end

    local tabIndex = 0;

    local function FilterSearch(query)
        Library.CurrentSearchQuery = string.lower(query or "");
        for _, tab in ipairs(Window.Tabs) do
            if tab.Groupboxes then
                for _, card in pairs(tab.Groupboxes) do
                    if type(card) == 'table' and card.Outer and card.Name then
                        if Library.CurrentSearchQuery == "" then
                            card.Outer.Visible = true;
                        else
                            local lowerCardName = string.lower(card.Name);
                            local matched = string.find(lowerCardName, Library.CurrentSearchQuery, 1, true);
                            card.Outer.Visible = (matched ~= nil);
                        end
                    end
                end
            end
        end
    end

    SearchBox:GetPropertyChangedSignal('Text'):Connect(function()
        FilterSearch(SearchBox.Text);
    end);

    Library:GiveSignal(InputService.InputBegan:Connect(function(input)
        if (input.KeyCode == Enum.KeyCode.F) and (InputService:IsKeyDown(Enum.KeyCode.LeftControl) or InputService:IsKeyDown(Enum.KeyCode.RightControl)) then
            SearchBox:CaptureFocus();
        end
    end));

    function Window:AddTab(Name, Icon)
        tabIndex = tabIndex + 1;
        Name = Name or ('Tab ' .. tabIndex);
        local isFirstTab = (tabIndex == 1);

        local Tab = {
            Name = Name;
            Groupboxes = {};
            Tabboxes = {};
            IsOpen = isFirstTab;
            Active = isFirstTab;
            LayoutOrder = tabIndex;
            isHovered = false;
        };

        local iconAsset = ResolveTabIcon(Name, Icon);

        local TabButton = Library:Create('TextButton', {
            AutoButtonColor = false,
            BackgroundColor3 = isFirstTab and THEME.TabBtnActive or Color3.fromRGB(18, 15, 28),
            BackgroundTransparency = isFirstTab and 0.18 or 1,
            Size = UDim2.fromOffset(THEME.TabBtnSize, 44),
            Text = '',
            ClipsDescendants = true,
            ZIndex = 52,
            LayoutOrder = tabIndex,
            Parent = TabScroll,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, 10), Parent = TabButton });

        local TabBtnIcon = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(20, 20),
            BackgroundTransparency = 1,
            Image = iconAsset,
            ImageColor3 = isFirstTab and THEME.Accent or Color3.fromRGB(130, 125, 155),
            ZIndex = 53,
            Parent = TabButton,
        });

        local TabBtnText = Library:Create('TextLabel', {
            Name = 'TabBtnText',
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 42, 0, 0),
            Size = UDim2.new(1, -46, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = Name:sub(1,1):upper() .. Name:sub(2),
            TextSize = 12,
            TextColor3 = isFirstTab and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 125, 155),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextTransparency = 1,
            Visible = false,
            ZIndex = 53,
            Parent = TabButton,
        });

        local ContentBody = Library:Create('Frame', {
            Name = 'Content_' .. Name,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Visible = isFirstTab,
            ZIndex = 14,
            Parent = TabViewport,
        });

        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0.5, -6, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
            ScrollBarImageTransparency = 0.45,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ZIndex = 14,
            Parent = ContentBody,
        });

        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 6, 0, 0),
            Size = UDim2.new(0.5, -6, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
            ScrollBarImageTransparency = 0.45,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ZIndex = 14,
            Parent = ContentBody,
        });

        for _, sideFrame in ipairs({ LeftSide, RightSide }) do
            sideFrame.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseWheel then
                    local maxScroll = math.max(0, sideFrame.AbsoluteCanvasSize.Y - sideFrame.AbsoluteWindowSize.Y);
                    sideFrame.CanvasPosition = Vector2.new(
                        0,
                        math.clamp(sideFrame.CanvasPosition.Y - input.Position.Z * 45, 0, maxScroll)
                    );
                end
            end);
        end

        for _, Side in next, { LeftSide, RightSide } do
            local layout = Library:Create('UIListLayout', {
                Padding = UDim.new(0, 10),
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Parent = Side,
            });
            layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 14);
            end);
        end

        function Tab:RefreshPill(hovered)
            if Tab.Active then
                Tween(TabButton, TI_FAST, { BackgroundColor3 = THEME.TabBtnActive, BackgroundTransparency = 0.18 });
                Tween(TabBtnIcon, TI_FAST, { ImageColor3 = THEME.Accent });
                Tween(TabBtnText, TI_FAST, { TextColor3 = Color3.fromRGB(255, 255, 255) });
            elseif hovered == true then
                Tween(TabButton, TI_FAST, { BackgroundColor3 = THEME.TabBtnHover, BackgroundTransparency = 0.45 });
                Tween(TabBtnIcon, TI_FAST, { ImageColor3 = Color3.fromRGB(215, 210, 240) });
                Tween(TabBtnText, TI_FAST, { TextColor3 = Color3.fromRGB(215, 210, 240) });
            else
                Tween(TabButton, TI_FAST, { BackgroundColor3 = Color3.fromRGB(18, 15, 28), BackgroundTransparency = 1 });
                Tween(TabBtnIcon, TI_FAST, { ImageColor3 = Color3.fromRGB(120, 116, 145) });
                Tween(TabBtnText, TI_FAST, { TextColor3 = Color3.fromRGB(120, 116, 145) });
            end
        end

        TabButton.MouseEnter:Connect(function()
            if not Tab.Active then
                Tab.isHovered = true;
                Tab:RefreshPill(true);
            end
            if not isSidebarExpanded then
                ShowTabTooltip(Tab);
            end
        end);
        TabButton.MouseLeave:Connect(function()
            Tab.isHovered = false;
            Tab:RefreshPill(false);
            HideTabTooltip();
        end);

        function Tab:OpenWindow()
            for _, otherTab in ipairs(Window.Tabs) do
                otherTab.IsOpen = false;
                otherTab.Active = false;
                otherTab.isHovered = false;
                if otherTab.ContentBody then otherTab.ContentBody.Visible = false; end
                if otherTab.RefreshPill then otherTab:RefreshPill(false); end
            end

            Tab.IsOpen = true;
            Tab.Active = true;
            Tab.isHovered = false;
            Library.ActiveTab = Tab;
            ContentBody.Visible = true;
            HeaderTabTitle.Text = Name:sub(1,1):upper() .. Name:sub(2);
            HeaderTabIcon.Image = iconAsset;
            Tab:RefreshPill(false);
            task.defer(function()
                if Tab.Groupboxes then
                    for _, gb in pairs(Tab.Groupboxes) do
                        if type(gb) == 'table' and gb.Resize then
                            gb:Resize();
                        end
                    end
                end
                if SearchBox and SearchBox.Text ~= "" then
                    FilterSearch(SearchBox.Text);
                end
            end);
            if WebManager then WebManager:Update(); end
        end

        function Tab:CloseWindow()
            Tab.IsOpen = false;
            Tab.Active = false;
            ContentBody.Visible = false;
            Tab:RefreshPill(false);
        end

        function Tab:ToggleWindow()
            if Tab.Active then return; end
            Tab:OpenWindow();
        end

        TabButton.MouseButton1Click:Connect(function()
            Library:PlaySound('click');
            Tab:OpenWindow();
        end);

        function Tab:ShowTab() Tab:OpenWindow(); end
        function Tab:HideTab() Tab:CloseWindow(); end

        -- Standalone Feature Card / Section Dropdown (Groupbox or SubTab)
        local NonToggleSections = {
            ['appearance'] = true,
            ['system & sound'] = true,
            ['shortcuts'] = true,
            ['about'] = true,
            ['themes'] = true,
            ['fonts'] = true,
            ['menu'] = true,
            ['configs'] = true,
            ['presets'] = true,
            ['presets & notifications'] = true,
            ['batch tools'] = true,
            ['customization & batch tools'] = true,
            ['stats & region'] = true,
            ['identity'] = true,
            ['crosshair'] = true,
            ['lighting'] = true,
            ['color'] = true,
            ['bloom'] = true,
            ['screen & fps'] = true,
            ['hit effects'] = true,
            ['hit sounds'] = true,
            ['notifs'] = true,
            ['view model'] = true,
            ['viewport'] = true,
            ['bullet tracers'] = true,
            ['kill sounds'] = true,
            ['qol'] = true,
            ['textures'] = true,
            ['device spoof'] = true,
            ['interface & display'] = true,
            ['glow & fx'] = true,
            ['media & music'] = true,
            ['keybinds'] = true,
            ['skin & cosmetic studio'] = true,
            ['skin studio'] = true,
            ['cosmetic studio'] = true,
            ['skin changer'] = true,
            ['skins'] = true,
            ['cosmetics'] = true,
        };

        local function CreateFeatureCard(cardName, parentSide, startExpanded, customOptions)
            customOptions = customOptions or {};
            local lowerName = string.lower(cardName or '');
            local isNonToggle = (customOptions.NoToggle == true) or (customOptions.IsSection == true) or (NonToggleSections[lowerName] == true);
            if customOptions.Toggle == true or customOptions.HasToggle == true then
                isNonToggle = false;
            end

            local shouldExpand = (startExpanded ~= false) and (customOptions.Collapsed ~= true);

            local Card = {
                Name = cardName,
                IsExpanded = shouldExpand,
                IsFavorited = false,
                HasBoundMasterToggle = false,
                HasMasterToggle = not isNonToggle,
                Enabled = false,
                MasterToggle = nil,
                Groupboxes = {},
            };

            local BoxOuter = Library:Create('Frame', {
                Name = 'FeatureCard_' .. cardName,
                BackgroundColor3 = THEME.CardBg,
                BackgroundTransparency = Library.LiquidGlass and THEME.CardOpacity or THEME.CardOpacitySolid,
                Size = UDim2.new(1, 0, 0, shouldExpand and 120 or 44),
                ClipsDescendants = true,
                ZIndex = 15,
                Parent = parentSide,
            });
            Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Groupbox), Parent = BoxOuter });
            local BoxStroke = Library:Create('UIStroke', {
                Color = THEME.Border,
                Transparency = THEME.BorderOpacity,
                Thickness = 1.2,
                Parent = BoxOuter,
            });

            -- Top-edge specular sheen (mica glass effect on card)
            local CardSheen = Library:Create('Frame', {
                Name = 'Sheen',
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.84,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, 44),
                ZIndex = 16,
                Parent = BoxOuter,
            });
            Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Groupbox), Parent = CardSheen });
            Library:Create('UIGradient', {
                Rotation = 120,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.4,  Color3.fromRGB(200, 175, 255)),
                    ColorSequenceKeypoint.new(1,    Color3.fromRGB(140, 110, 220)),
                }),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0,    0.65),
                    NumberSequenceKeypoint.new(0.45, 0.88),
                    NumberSequenceKeypoint.new(1,    1),
                }),
                Parent = CardSheen,
            });

            -- Card Header Frame (glass-layered surface with subtle gradient)
            local Header = Library:Create('Frame', {
                BackgroundColor3 = THEME.CardHeader,
                BackgroundTransparency = Library.LiquidGlass and THEME.HeaderOpacity or 0.05,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, 44),
                ZIndex = 16,
                Parent = BoxOuter,
            });
            Library:Create('UICorner', { CornerRadius = UDim.new(0, RADIUS.Groupbox), Parent = Header });
            -- Header bottom-fade gradient (gives depth/separation from card body)
            Library:Create('UIGradient', {
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0,   0.0),
                    NumberSequenceKeypoint.new(0.7, 0.0),
                    NumberSequenceKeypoint.new(1,   0.5),
                }),
                Parent = Header,
            });

            -- Title / Expand Click Target
            local ExpandBtn = Library:Create('TextButton', {
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 0),
                Size = isNonToggle and UDim2.fromScale(1, 1) or UDim2.new(1, -120, 1, 0),
                Text = '',
                ZIndex = 17,
                Parent = Header,
            });

            -- Title Label (Neatly left-aligned with no redundant left arrow)
            local TitleLabel = Library:CreateLabel({
                Position = UDim2.new(0, 14, 0, 0),
                Size = isNonToggle and UDim2.new(1, -48, 1, 0) or UDim2.new(1, -150, 1, 0),
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                Text = cardName:sub(1,1):upper() .. cardName:sub(2),
                TextColor3 = Color3.fromRGB(245, 243, 255),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 18,
                Parent = Header,
            });

            local Chevron = nil;
            local HeaderRight = nil;
            local KeybindHolder = nil;
            local StarBtn = nil;
            local MasterToggleBtn = nil;
            local MasterSwitchTrack = nil;
            local MasterSwitchThumb = nil;
            local MasterStroke = nil;

            if isNonToggle then
                -- Pure Clean Section Pill Dropdown (Single Chevron Arrow on Far Right)
                Chevron = Library:Create('ImageLabel', {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -14, 0.5, 0),
                    Size = UDim2.fromOffset(14, 14),
                    BackgroundTransparency = 1,
                    Image = 'rbxassetid://10709790948',
                    ImageColor3 = Color3.fromRGB(160, 155, 185),
                    Rotation = Card.IsExpanded and 180 or 0,
                    ZIndex = 18,
                    Parent = Header,
                });
            else
                -- Feature Card with Master Enable Switch, Keybind, Star
                HeaderRight = Library:Create('Frame', {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.new(0, 130, 1, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 20,
                    Parent = Header,
                });
                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 6),
                    Parent = HeaderRight,
                });

                KeybindHolder = Library:Create('Frame', {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 56, 0, 20),
                    Visible = false, -- Only visible when keypicker is attached
                    ZIndex = 21,
                    Parent = HeaderRight,
                });

                StarBtn = Library:Create('ImageButton', {
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(16, 16),
                    Image = 'rbxassetid://10734964522',
                    ImageColor3 = Color3.fromRGB(150, 145, 175),
                    ZIndex = 22,
                    Parent = HeaderRight,
                });
                StarBtn.MouseButton1Click:Connect(function()
                    Library:PlaySound('click');
                    Card.IsFavorited = not Card.IsFavorited;
                    Tween(StarBtn, TI_FAST, {
                        Image = Card.IsFavorited and 'rbxassetid://10734964687' or 'rbxassetid://10734964522',
                        ImageColor3 = Card.IsFavorited and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(150, 145, 175),
                    });
                end);

                MasterToggleBtn = Library:Create('TextButton', {
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(36, 20),
                    Text = '',
                    ZIndex = 25,
                    Parent = HeaderRight,
                });

                MasterSwitchTrack = Library:Create('Frame', {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = Color3.fromRGB(42, 38, 56),
                    BackgroundTransparency = 0.35,
                    ZIndex = 26,
                    Parent = MasterToggleBtn,
                });
                Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = MasterSwitchTrack });
                MasterStroke = Library:Create('UIStroke', {
                    Color = Color3.fromRGB(68, 62, 90),
                    Transparency = 0.55,
                    Thickness = 1,
                    Parent = MasterSwitchTrack,
                });

                MasterSwitchThumb = Library:Create('Frame', {
                    Name = 'Thumb',
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 3, 0.5, 0),
                    Size = UDim2.fromOffset(14, 14),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    ZIndex = 27,
                    Parent = MasterSwitchTrack,
                });
                Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = MasterSwitchThumb });

                function Card:SetEnabled(bool)
                    Card.Enabled = (bool == true);
                    local isOn = Card.Enabled;
                    local trackCol = isOn and Library.AccentColor or Color3.fromRGB(42, 38, 56);
                    local trackTrans = isOn and 0.15 or 0.35;
                    local thumbPos = isOn and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0);

                    Tween(MasterSwitchTrack, TI_SMOOTH, { BackgroundColor3 = trackCol, BackgroundTransparency = trackTrans });
                    if MasterStroke then
                        Tween(MasterStroke, TI_SMOOTH, { Color = isOn and Library.AccentColor or Color3.fromRGB(68, 62, 90), Transparency = isOn and 0.25 or 0.55 });
                    end
                    if MasterSwitchThumb then
                        Tween(MasterSwitchThumb, TI_POP, { Position = thumbPos });
                    end
                    if Card.MasterToggle and Card.MasterToggle.Value ~= Card.Enabled then
                        Card.MasterToggle:SetValue(Card.Enabled);
                    end
                end

                MasterToggleBtn.MouseButton1Click:Connect(function()
                    Library:PlaySound('toggle');
                    Card:SetEnabled(not Card.Enabled);
                    Library:AttemptSave();
                end);
            end

            local Container = Library:Create('Frame', {
                BackgroundColor3 = THEME.CardBody,
                BackgroundTransparency = Library.LiquidGlass and THEME.BodyOpacity or 0.1,
                Position = UDim2.new(0, 8, 0, 48),
                Size = UDim2.new(1, -16, 1, -54),
                ClipsDescendants = true,
                Visible = Card.IsExpanded,
                ZIndex = 15,
                Parent = BoxOuter,
            });
            Library:Create('UICorner', { CornerRadius = UDim.new(0, 8), Parent = Container });

            local containerLayout = Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4),
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Container
            });

            function Card:Resize(animate)
                if not BoxOuter or not BoxOuter.Parent or not containerLayout or not containerLayout.Parent then return end
                if Card.IsExpanded then
                    local contentH = containerLayout.AbsoluteContentSize.Y;
                    local targetH = math.max(44, contentH + 58);
                    if animate then
                        Tween(BoxOuter, TI_SMOOTH, { Size = UDim2.new(1, 0, 0, targetH) });
                    else
                        BoxOuter.Size = UDim2.new(1, 0, 0, targetH);
                    end
                    Container.Visible = true;
                else
                    if animate then
                        Tween(BoxOuter, TI_SMOOTH, { Size = UDim2.new(1, 0, 0, 44) });
                    else
                        BoxOuter.Size = UDim2.new(1, 0, 0, 44);
                    end
                end
            end

            containerLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                if Card.IsExpanded then
                    Card:Resize(false);
                end
            end);

            function Card:ToggleExpand()
                Library:PlaySound('expand');
                Card.IsExpanded = not Card.IsExpanded;
                if Chevron then
                    Tween(Chevron, TI_SPRING, { Rotation = Card.IsExpanded and 180 or 0, ImageColor3 = Card.IsExpanded and Library.AccentColor or Color3.fromRGB(160, 155, 185) });
                end
                if not Card.IsExpanded then
                    task.delay(0.12, function()
                        if not Card.IsExpanded then Container.Visible = false; end
                    end);
                else
                    Container.Visible = true;
                end
                Card:Resize(true);
            end

            ExpandBtn.MouseButton1Click:Connect(function() Card:ToggleExpand(); end);
            ExpandBtn.MouseButton2Click:Connect(function() Card:ToggleExpand(); end);

            local function getHeaderTrans()
                if Library.LiquidGlass then return THEME.HeaderOpacity; end
                return math.clamp(1 - (Library.GlobalOpacity or 0.85) + 0.08, 0, 0.92);
            end

            ExpandBtn.MouseEnter:Connect(function()
                local baseT = getHeaderTrans();
                Tween(Header, TI_FAST, { BackgroundColor3 = THEME.CardActive, BackgroundTransparency = math.max(0, baseT - 0.08) });
                Tween(BoxStroke, TI_FAST, { Color = THEME.BorderBright, Transparency = THEME.BorderOpacity - 0.15 });
            end);
            ExpandBtn.MouseLeave:Connect(function()
                local baseT = getHeaderTrans();
                Tween(Header, TI_SMOOTH, { BackgroundColor3 = THEME.CardHeader, BackgroundTransparency = baseT });
                Tween(BoxStroke, TI_SMOOTH, { Color = THEME.Border, Transparency = THEME.BorderOpacity });
            end);

            Card.Container = Container;
            Card.Outer = BoxOuter;
            Card.Header = Header;
            Card.HeaderRight = HeaderRight;
            Card.MasterKeybindHolder = KeybindHolder;
            Card.MasterToggleBtn = MasterToggleBtn;
            Card.MasterToggleSwitch = MasterSwitchTrack;
            setmetatable(Card, BaseGroupbox);
            Card:AddBlank(2);
            Card:Resize(false);
            return Card;
        end

        function Tab:AddGroupbox(Info)
            if type(Info) == 'string' then
                Info = { Name = Info, Side = 1 };
            elseif type(Info) ~= 'table' then
                Info = { Name = '', Side = 1 };
            end
            Info.Side = Info.Side or 1;
            Info.Name = Info.Name or '';

            local parentSide = (Info.Side == 1) and (Tab.LeftSide or LeftSide) or (Tab.RightSide or RightSide);
            local Card = CreateFeatureCard(Info.Name, parentSide, Info.Expanded ~= false and Info.Collapsed ~= true, Info);
            local boxKey = (Info.Name and Info.Name ~= '') and Info.Name or ('Groupbox_' .. tostring(#(Tab.LeftSide or LeftSide):GetChildren() + #(Tab.RightSide or RightSide):GetChildren() + 1));
            Tab.Groupboxes[boxKey] = Card;
            Tab.Groupboxes[string.lower(boxKey)] = Card;
            table.insert(Tab.Groupboxes, Card);
            return Card;
        end

        function Tab:AddLeftGroupbox(Name, Info)
            Info = Info or {};
            Info.Side = 1;
            Info.Name = type(Name) == 'string' and Name or (Info.Name or '');
            return Tab:AddGroupbox(Info);
        end

        function Tab:AddRightGroupbox(Name, Info)
            Info = Info or {};
            Info.Side = 2;
            Info.Name = type(Name) == 'string' and Name or (Info.Name or '');
            return Tab:AddGroupbox(Info);
        end

        function Tab:AddSection(Name, Side)
            return Tab:AddGroupbox({ Name = Name, Side = Side or 1, NoToggle = true });
        end

        function Tab:AddPillTab(Name, Side)
            return Tab:AddGroupbox({ Name = Name, Side = Side or 1, NoToggle = true });
        end

        function Tab:AddPillDropdown(Name, Side)
            return Tab:AddGroupbox({ Name = Name, Side = Side or 1, NoToggle = true });
        end

        function Tab:AddFeature(Name, Side, Info)
            Info = Info or {};
            Info.Name = Name;
            Info.Side = Side or 1;
            Info.Toggle = true;
            return Tab:AddGroupbox(Info);
        end

        -- Standalone Feature Card / Section Pill Dropdown (Groupbox or SubTab)
        function Tab:AddTabbox(Info)
            if type(Info) == 'string' then
                Info = { Name = Info, Side = 1 };
            elseif type(Info) ~= 'table' then
                Info = { Name = '', Side = 1 };
            end
            Info.Side = Info.Side or 1;
            Info.Name = Info.Name or '';

            local parentSide = (Info.Side == 1) and (Tab.LeftSide or LeftSide) or (Tab.RightSide or RightSide);
            local Tabbox = { Tabs = {} };

            function Tabbox:AddTab(SubTabName, CustomOptions)
                SubTabName = SubTabName or 'Feature';
                CustomOptions = CustomOptions or {};
                local Card = CreateFeatureCard(SubTabName, parentSide, true, CustomOptions);
                table.insert(Tabbox.Tabs, Card);
                Tab.Groupboxes[SubTabName] = Card;
                Tab.Groupboxes[string.lower(SubTabName)] = Card;
                table.insert(Tab.Groupboxes, Card);
                return Card;
            end

            return Tabbox;
        end

        function Tab:AddLeftTabbox(Name) return Tab:AddTabbox({ Name = type(Name) == 'string' and Name or '', Side = 1 }); end
        function Tab:AddRightTabbox(Name) return Tab:AddTabbox({ Name = type(Name) == 'string' and Name or '', Side = 2 }); end

        Tab.TabButton = TabButton;
        Tab.TabBtnIcon = TabBtnIcon;
        Tab.TabBtnText = TabBtnText;
        Tab.ContentBody = ContentBody;
        Tab.LeftSide = LeftSide;
        Tab.RightSide = RightSide;
        Tab.ModWindow = MainWindow;

        table.insert(Window.Tabs, Tab);
        Window.Tabs[Name] = Tab;
        Window.ModularWindows[Name] = MainWindow;

        if isFirstTab then
            Library.ActiveTab = Tab;
            HeaderTabTitle.Text = '•  ' .. Name:sub(1,1):upper() .. Name:sub(2);
            HeaderTabIcon.Image = iconAsset;
        end

        return Tab;
    end

    function Library:Toggle(forceState)
        if forceState ~= nil then
            Library.Toggled = forceState;
        else
            Library.Toggled = not Library.Toggled;
        end
        Library:SetBlur(Library.Toggled);

        MainWindow.Visible = Library.Toggled;
        if Library.Toggled then
            WinScale.Scale = 0.94;
            local targetTrans = Library.LiquidGlass and 0.52 or math.clamp(1 - (Library.GlobalOpacity or 0.85) + 0.1, 0, 0.95);
            MainWindow.BackgroundTransparency = math.clamp(targetTrans - 0.15, 0, 1);
            Tween(WinScale, TI_SPRING, { Scale = 1 });
            Tween(MainWindow, TI_SMOOTH, { BackgroundTransparency = targetTrans });
        else
            pcall(function()
                local roots = { game:GetService("CoreGui"), (game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")) }
                local okHui, hui = pcall(function() return gethui and gethui() or nil end)
                if okHui and hui then table.insert(roots, hui) end
                for _, root in ipairs(roots) do
                    if root then
                        local studio = root:FindFirstChild("MikuCosmeticStudioGui")
                        if studio then studio.Enabled = false end
                    end
                end
            end)
        end
        WebManager:Update();
        if Library.OnToggle then
            for _, cb in ipairs(Library.OnToggle) do
                pcall(cb, Library.Toggled);
            end
        end
    end

    local lastMenuToggle = 0;
    local function HandleMenuToggle(Input, Processed)
        if InputService:GetFocusedTextBox() ~= nil then
            return;
        end

        local isMenuKey = false;
        local keyName = Input.KeyCode and Input.KeyCode.Name;

        if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
            if keyName == Library.ToggleKeybind.Value then isMenuKey = true; end
        elseif type(Library.ToggleKeybind) == 'string' then
            if keyName == Library.ToggleKeybind then isMenuKey = true; end
        end

        if not isMenuKey and Options and Options.MenuKeybind and Options.MenuKeybind.Value then
            if keyName == Options.MenuKeybind.Value then isMenuKey = true; end
        end

        if not isMenuKey then
            if Input.KeyCode == Enum.KeyCode.RightShift 
               or Input.KeyCode == Enum.KeyCode.RightControl 
               or Input.KeyCode == Enum.KeyCode.Insert then
                isMenuKey = true;
            end
        end

        if isMenuKey then
            if (tick() - lastMenuToggle) > 0.15 then
                lastMenuToggle = tick();
                task.spawn(function()
                    Library:Toggle();
                end);
            end
        end
    end

    Library:GiveSignal(InputService.InputBegan:Connect(HandleMenuToggle));

    if Window.AutoShow then
        Library:SetBlur(true);
    else
        Library.Toggled = false;
        MainWindow.Visible = false;
        if BlurEffect then BlurEffect.Enabled = false; end
    end

    Window.Holder = MainWindow;
    Library.Window = Window;
    return Window;
end

-- ====================================================================
-- MASTER EXTENSIONS: TargetHUD, MiniMap, DamageNumbers, WeatherEngine, MusicPlayer, Hitmarker & ScreenFlash
-- ====================================================================

-- 1. TARGET HUD
do
    local TargetHUD = {
        Frame = nil,
        CardStroke = nil,
        Enabled = false,
        Target = nil,
        LastSeen = 0,
        CurrentHpFrac = 1,
        _lastUserId = 0,
    };

    function TargetHUD:Init()
        if self.Frame then return end

        local Card = Library:Create('CanvasGroup', {
            Name = 'MikuTargetHUD',
            GroupTransparency = 1,
            Position = UDim2.new(0.5, -135, 0.74, 0),
            Size = UDim2.fromOffset(270, 78),
            BackgroundColor3 = Library.BackgroundColor,
            Visible = false,
            ZIndex = 500,
            Parent = ScreenGui,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, 10), Parent = Card });
        local CardScale = Library:Create('UIScale', { Scale = 0.94, Parent = Card });
        local CardStroke = Library:Create('UIStroke', { Color = Library.OutlineColor, Transparency = 1, Thickness = 1.2, Parent = Card });
        Library:AddToRegistry(CardStroke, { Color = 'OutlineColor' });
        Library:AddToRegistry(Card, { BackgroundColor3 = 'BackgroundColor' });

        local TopGlow = Library:Create('Frame', {
            BorderSizePixel = 0,
            BackgroundColor3 = Library.AccentColor,
            Size = UDim2.new(1, 0, 0, 2),
            ZIndex = 505,
            Parent = Card,
        });
        Library:AddToRegistry(TopGlow, { BackgroundColor3 = 'AccentColor' });

        local AvatarBg = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            Position = UDim2.fromOffset(8, 12),
            Size = UDim2.fromOffset(54, 54),
            ZIndex = 501,
            Parent = Card,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, 8), Parent = AvatarBg });
        local AvatarStroke = Library:Create('UIStroke', { Color = Library.AccentColor, Transparency = 0.4, Thickness = 1, Parent = AvatarBg });
        Library:AddToRegistry(AvatarStroke, { Color = 'AccentColor' });
        Library:AddToRegistry(AvatarBg, { BackgroundColor3 = 'MainColor' });

        local AvatarImg = Library:Create('ImageLabel', {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = '',
            ZIndex = 502,
            Parent = AvatarBg,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, 8), Parent = AvatarImg });

        local StatusDot = Library:Create('Frame', {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -2, 1, -2),
            Size = UDim2.fromOffset(8, 8),
            BackgroundColor3 = Color3.fromRGB(0, 255, 128),
            BorderSizePixel = 0,
            ZIndex = 504,
            Parent = AvatarBg,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = StatusDot });
        local DotStroke = Library:Create('UIStroke', { Color = Color3.fromRGB(10, 10, 15), Thickness = 1.2, Parent = StatusDot });

        local NameLabel = Library:CreateLabel({
            Position = UDim2.fromOffset(70, 10),
            Size = UDim2.new(1, -78, 0, 16),
            Text = 'Target Name',
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 502,
            Parent = Card,
        });

        local InfoRow = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(70, 28),
            Size = UDim2.new(1, -78, 0, 16),
            ZIndex = 502,
            Parent = Card,
        });
        local InfoList = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5),
            Parent = InfoRow,
        });

        local DistBadge = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            Size = UDim2.new(0, 48, 1, 0),
            ZIndex = 503,
            Parent = InfoRow,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, 4), Parent = DistBadge });
        Library:AddToRegistry(DistBadge, { BackgroundColor3 = 'MainColor' });
        local DistText = Library:CreateLabel({
            Size = UDim2.fromScale(1, 1),
            Text = '0m',
            TextColor3 = Library.FontColor,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 504,
            Parent = DistBadge,
        });

        local WepBadge = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            Size = UDim2.new(0, 80, 1, 0),
            ZIndex = 503,
            Parent = InfoRow,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, 4), Parent = WepBadge });
        Library:AddToRegistry(WepBadge, { BackgroundColor3 = 'MainColor' });
        local WepText = Library:CreateLabel({
            Size = UDim2.fromScale(1, 1),
            Text = 'Weapon',
            TextColor3 = Library.DimColor,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 504,
            Parent = WepBadge,
        });

        local HpTrack = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(16, 18, 26),
            Position = UDim2.fromOffset(70, 48),
            Size = UDim2.new(1, -78, 0, 14),
            ZIndex = 502,
            Parent = Card,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, 4), Parent = HpTrack });
        local HpTrackStroke = Library:Create('UIStroke', { Color = Library.OutlineColor, Transparency = 0.5, Thickness = 1, Parent = HpTrack });
        Library:AddToRegistry(HpTrackStroke, { Color = 'OutlineColor' });

        local HpLag = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(255, 80, 90),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 503,
            Parent = HpTrack,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, 4), Parent = HpLag });

        local HpFill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 504,
            Parent = HpTrack,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, 4), Parent = HpFill });
        Library:AddToRegistry(HpFill, { BackgroundColor3 = 'AccentColor' });

        local HpText = Library:CreateLabel({
            Size = UDim2.fromScale(1, 1),
            Text = '100 HP',
            TextSize = 10,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 505,
            Parent = HpTrack,
        });

        local ShieldTrack = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(14, 16, 24),
            Position = UDim2.fromOffset(70, 66),
            Size = UDim2.new(1, -78, 0, 4),
            ZIndex = 502,
            Parent = Card,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, 2), Parent = ShieldTrack });

        local ShieldFill = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(0, 210, 255),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 503,
            Parent = ShieldTrack,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(0, 2), Parent = ShieldFill });

        Library:MakeDraggable(Card);

        self.Frame = Card;
        self.CardStroke = CardStroke;
        self.CardScale = CardScale;
        self.AvatarImg = AvatarImg;
        self.StatusDot = StatusDot;
        self.NameLabel = NameLabel;
        self.DistText = DistText;
        self.DistBadge = DistBadge;
        self.WepText = WepText;
        self.WepBadge = WepBadge;
        self.HpFill = HpFill;
        self.HpLag = HpLag;
        self.HpText = HpText;
        self.ShieldTrack = ShieldTrack;
        self.ShieldFill = ShieldFill;
    end

    function TargetHUD:Update(info)
        if not self.Enabled then
            if self.Frame then
                self.Frame.Visible = false;
                self.Frame.GroupTransparency = 1;
                if self.CardStroke then self.CardStroke.Transparency = 1; end
            end
            return;
        end
        self:Init();
        if not info then
            if self.Frame and self.Frame.Visible and (tick() - self.LastSeen) > 1.2 then
                self.Target = nil;
                Tween(self.Frame, TI_SMOOTH, { GroupTransparency = 1 });
                if self.CardStroke then
                    Tween(self.CardStroke, TI_SMOOTH, { Transparency = 1 });
                end
                Tween(self.CardScale, TI_SMOOTH, { Scale = 0.94 });
                task.delay(0.25, function()
                    if not self.Target and self.Frame then
                        self.Frame.Visible = false;
                        if self.CardStroke then self.CardStroke.Transparency = 1; end
                    end
                end);
            end
            return;
        end

        self.LastSeen = tick();
        self.Target = info.Target;
        if not self.Frame.Visible or self.Frame.GroupTransparency > 0.5 then
            self.Frame.Visible = true;
            Tween(self.Frame, TI_FAST, { GroupTransparency = 0 });
            if self.CardStroke then
                Tween(self.CardStroke, TI_FAST, { Transparency = 0.15 });
            end
            Tween(self.CardScale, TI_POP, { Scale = 1 });
        end

        if info.UserId and info.UserId > 0 and self._lastUserId ~= info.UserId then
            self._lastUserId = info.UserId;
            self.AvatarImg.Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=100&height=100&format=png", info.UserId);
        end

        self.NameLabel.Text = tostring(info.Name or 'Target');
        local distVal = math.floor((info.Distance or 0) * 0.28);
        self.DistText.Text = string.format("%dm", distVal);
        self.DistBadge.Size = UDim2.new(0, math.max(38, #self.DistText.Text * 7 + 14), 1, 0);

        local wepStr = tostring(info.Weapon or 'None');
        self.WepText.Text = wepStr;
        self.WepBadge.Size = UDim2.new(0, math.clamp(#wepStr * 6.5 + 14, 50, 110), 1, 0);

        local hp = math.max(0, tonumber(info.Health) or 100);
        local maxHp = math.max(1, tonumber(info.MaxHealth) or 100);
        local hpFrac = math.clamp(hp / maxHp, 0, 1);

        if hpFrac > 0.5 then
            self.StatusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 128);
        elseif hpFrac > 0.25 then
            self.StatusDot.BackgroundColor3 = Color3.fromRGB(255, 200, 0);
        else
            self.StatusDot.BackgroundColor3 = Color3.fromRGB(255, 50, 70);
        end

        Tween(self.HpFill, TI_FAST, { Size = UDim2.new(hpFrac, 0, 1, 0) });
        if hpFrac < self.CurrentHpFrac then
            task.delay(0.12, function()
                if self.HpLag then
                    Tween(self.HpLag, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(hpFrac, 0, 1, 0) });
                end
            end);
        else
            self.HpLag.Size = UDim2.new(hpFrac, 0, 1, 0);
        end
        self.CurrentHpFrac = hpFrac;
        self.HpText.Text = string.format("%d / %d HP (%d%%)", math.floor(hp), math.floor(maxHp), math.floor(hpFrac * 100));

        local shield = math.max(0, tonumber(info.Shield) or 0);
        local maxShield = math.max(1, tonumber(info.MaxShield) or 50);
        local shieldFrac = math.clamp(shield / maxShield, 0, 1);
        if shield > 0 then
            self.ShieldTrack.Visible = true;
            Tween(self.ShieldFill, TI_FAST, { Size = UDim2.new(shieldFrac, 0, 1, 0) });
        else
            self.ShieldTrack.Visible = false;
        end
    end

    Library.TargetHUD = TargetHUD;
    function Library:SetTargetHUD(info) TargetHUD:Update(info); end
    function Library:ToggleTargetHUD(bool)
        TargetHUD.Enabled = bool;
        if TargetHUD.Frame then
            TargetHUD.Frame.Visible = bool;
            if not bool then
                TargetHUD.Target = nil;
                TargetHUD.Frame.GroupTransparency = 1;
                if TargetHUD.CardStroke then TargetHUD.CardStroke.Transparency = 1; end
            end
        end
    end
end

-- 2. MINI MAP
do
    local MiniMap = {
        Frame = nil,
        Enabled = false,
        BlipPool = {},
        ActiveBlips = 0,
        Range = 180,
    };

    function MiniMap:Init()
        if self.Frame then return end
        local MapOuter = Library:Create('CanvasGroup', {
            Name = 'MikuMiniMap',
            Position = UDim2.new(1, -210, 0, 70),
            Size = UDim2.fromOffset(160, 160),
            BackgroundColor3 = Library.BackgroundColor,
            Visible = false,
            ZIndex = 400,
            Parent = ScreenGui,
        });
        Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = MapOuter });
        local Stroke = Library:Create('UIStroke', { Color = Library.OutlineColor, Transparency = 0.1, Thickness = 2, Parent = MapOuter });
        Library:AddToRegistry(Stroke, { Color = 'OutlineColor' });
        Library:AddToRegistry(MapOuter, { BackgroundColor3 = 'BackgroundColor' });

        local CrossH = Library:Create('Frame', {
            BackgroundColor3 = Library.OutlineColor,
            BackgroundTransparency = 0.6,
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 0, 1),
            ZIndex = 401,
            Parent = MapOuter,
        });
        local CrossV = Library:Create('Frame', {
            BackgroundColor3 = Library.OutlineColor,
            BackgroundTransparency = 0.6,
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(0, 1, 1, 0),
            ZIndex = 401,
            Parent = MapOuter,
        });

        local Sweep = Library:Create('Frame', {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ZIndex = 402,
            Parent = MapOuter,
        });
        local SweepGrad = Library:Create('UIGradient', {
            Color = ColorSequence.new(Library.AccentColor),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.6),
                NumberSequenceKeypoint.new(0.3, 0.95),
                NumberSequenceKeypoint.new(1, 1),
            }),
            Rotation = 0,
            Parent = Sweep,
        });

        task.spawn(function()
            while MapOuter.Parent do
                SweepGrad.Rotation = (SweepGrad.Rotation + 3) % 360;
                task.wait(0.02);
            end
        end);

        local CenterBlip = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(12, 12),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://4944686940',
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ZIndex = 410,
            Parent = MapOuter,
        });

        Library:MakeDraggable(MapOuter);

        self.Frame = MapOuter;
        self.CenterBlip = CenterBlip;
    end

    function MiniMap:GetBlip()
        self.ActiveBlips = self.ActiveBlips + 1;
        local blip = self.BlipPool[self.ActiveBlips];
        if not blip then
            blip = Library:Create('Frame', {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromOffset(6, 6),
                BorderSizePixel = 0,
                ZIndex = 405,
                Parent = self.Frame,
            });
            Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = blip });
            table.insert(self.BlipPool, blip);
        end
        blip.Visible = true;
        return blip;
    end

    function MiniMap:ResetBlips()
        for _, blip in ipairs(self.BlipPool) do blip.Visible = false; end
        self.ActiveBlips = 0;
    end

    function MiniMap:Update(myPos, myYaw, entities, currentTarget, zoom)
        if not self.Enabled then
            if self.Frame and self.Frame.Visible then self.Frame.Visible = false; end
            return;
        end
        self:Init();
        self.Frame.Visible = true;
        self:ResetBlips();

        local radarRadius = 72;
        local maxDist = zoom or self.Range or 180;
        self.CenterBlip.Rotation = -math.deg(myYaw or 0);

        for _, ent in ipairs(entities or {}) do
            local dx = ent.Pos.X - myPos.X;
            local dz = ent.Pos.Z - myPos.Z;

            local cosY = math.cos(-myYaw);
            local sinY = math.sin(-myYaw);
            local rx = dx * cosY - dz * sinY;
            local rz = dx * sinY + dz * cosY;

            local dist = math.sqrt(rx * rx + rz * rz);
            local clampedDist = math.min(dist, maxDist);
            local scale = clampedDist / maxDist;

            local screenX = 80 + (rx / math.max(dist, 0.001)) * scale * radarRadius;
            local screenY = 80 + (rz / math.max(dist, 0.001)) * scale * radarRadius;

            local blip = self:GetBlip();
            blip.Position = UDim2.fromOffset(screenX, screenY);

            if ent.IsTarget or ent.Player == currentTarget then
                blip.Size = UDim2.fromOffset(8, 8);
                blip.BackgroundColor3 = Color3.fromRGB(255, 215, 0);
            elseif ent.IsTeammate then
                blip.Size = UDim2.fromOffset(5, 5);
                blip.BackgroundColor3 = Color3.fromRGB(0, 230, 115);
            else
                blip.Size = UDim2.fromOffset(6, 6);
                blip.BackgroundColor3 = Color3.fromRGB(255, 60, 80);
            end
        end
    end

    Library.MiniMap = MiniMap;
    function Library:UpdateMiniMap(myPos, myYaw, entities, currentTarget, zoom)
        MiniMap:Update(myPos, myYaw, entities, currentTarget, zoom);
    end
    function Library:ToggleMiniMap(bool)
        MiniMap.Enabled = bool;
        if MiniMap.Frame then MiniMap.Frame.Visible = bool; end
    end
end

-- 3. DAMAGE NUMBERS
do
    local DamageNumbers = {
        Enabled = true,
        Container = nil,
    };

    function DamageNumbers:Init()
        if self.Container then return end
        self.Container = Library:Create('Frame', {
            Name = 'MikuDamageContainer',
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 2000,
            Parent = ScreenGui,
        });
    end

    function DamageNumbers:Spawn(worldPos, damage, isCrit, isShield)
        if not self.Enabled then return end
        self:Init();
        local cam = workspace.CurrentCamera;
        if not cam then return end

        local screenPos, onScreen = cam:WorldToViewportPoint(worldPos);
        if not onScreen or screenPos.Z <= 0 then return end

        local randOffsetX = math.random(-16, 16);
        local randOffsetY = math.random(-8, 8);

        local startX = screenPos.X + randOffsetX;
        local startY = screenPos.Y + randOffsetY;

        local col = isCrit and Color3.fromRGB(255, 50, 80) or (isShield and Color3.fromRGB(0, 220, 255) or Color3.fromRGB(255, 230, 100));
        local prefix = isCrit and "CRIT " or "";
        local text = prefix .. tostring(math.floor(damage));

        local Tag = Library:Create('TextLabel', {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(startX, startY),
            Size = UDim2.fromOffset(100, 24),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Font = Enum.Font.GothamBold,
            Text = text,
            TextColor3 = col,
            TextSize = isCrit and 18 or 14,
            TextStrokeTransparency = 0.2,
            TextStrokeColor3 = Color3.new(0, 0, 0),
            ZIndex = 2001,
            Parent = self.Container,
        });

        local Scale = Library:Create('UIScale', { Scale = 1.35, Parent = Tag });
        Tween(Scale, TI_POP, { Scale = 1 });

        local targetY = startY - math.random(35, 60);
        local targetX = startX + math.random(-20, 20);

        Tween(Tag, TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.fromOffset(targetX, targetY),
            TextTransparency = 1,
            TextStrokeTransparency = 1,
        });

        task.delay(0.85, function()
            Tag:Destroy();
        end);
    end

    Library.DamageNumbers = DamageNumbers;
    function Library:CreateDamageNumber(worldPos, damage, isCrit, isShield)
        DamageNumbers:Spawn(worldPos, damage, isCrit, isShield);
    end
    function Library:ToggleDamageNumbers(bool)
        DamageNumbers.Enabled = bool;
    end
end

-- 4. WEATHER PARTICLE ENGINE
do
    local WeatherEngine = {
        Enabled = false,
        Canvas = nil,
        Type = 'Snow',
        Density = 60,
        Speed = 1,
        Wind = 0.5,
        Particles = {},
    };

    function WeatherEngine:Init()
        if self.Canvas then return end
        self.Canvas = Library:Create('Frame', {
            Name = 'MikuWeatherCanvas',
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ClipsDescendants = true,
            ZIndex = 1,
            Parent = ScreenGui,
        });

        Library:GiveSignal(RenderStepped:Connect(function(dt)
            if not self.Enabled then return end
            self:Update(dt);
        end));
    end

    function WeatherEngine:SetWeather(wType, density, speed, wind)
        self.Type = wType or 'Snow';
        self.Density = math.clamp(density or 60, 10, 150);
        self.Speed = speed or 1;
        self.Wind = wind or 0.5;
        self:Rebuild();
    end

    function WeatherEngine:Rebuild()
        for _, p in ipairs(self.Particles) do p.Inst:Destroy(); end
        self.Particles = {};
        if not self.Enabled then return end
        self:Init();

        local cam = workspace.CurrentCamera;
        local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080);

        for i = 1, self.Density do
            local inst = Library:Create('Frame', {
                BorderSizePixel = 0,
                ZIndex = 1,
                Parent = self.Canvas,
            });

            local pData = {
                Inst = inst,
                X = math.random(0, vp.X),
                Y = math.random(-50, vp.Y),
                VelX = (math.random() - 0.5) * 20 + self.Wind * 40,
                VelY = math.random(80, 180) * self.Speed,
                Size = math.random(3, 6),
                Rot = math.random(0, 360),
                RotSpeed = (math.random() - 0.5) * 120,
                Phase = math.random() * math.pi * 2,
            };

            if self.Type == 'Snow' then
                inst.BackgroundColor3 = Color3.fromRGB(240, 245, 255);
                inst.BackgroundTransparency = math.random(2, 6) / 10;
                inst.Size = UDim2.fromOffset(pData.Size, pData.Size);
                Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = inst });
            elseif self.Type == 'Rain' then
                inst.BackgroundColor3 = Color3.fromRGB(180, 215, 255);
                inst.BackgroundTransparency = 0.5;
                inst.Size = UDim2.fromOffset(2, math.random(12, 22));
                pData.VelY = math.random(400, 650) * self.Speed;
                pData.VelX = self.Wind * 80;
            elseif self.Type == 'Sakura' then
                inst.BackgroundColor3 = Color3.fromRGB(255, 180, 205);
                inst.BackgroundTransparency = 0.3;
                inst.Size = UDim2.fromOffset(math.random(6, 10), math.random(4, 7));
                Library:Create('UICorner', { CornerRadius = UDim.new(0.5, 0), Parent = inst });
            elseif self.Type == 'Autumn' then
                local hues = { Color3.fromRGB(235, 130, 40), Color3.fromRGB(215, 80, 40), Color3.fromRGB(240, 190, 45) };
                inst.BackgroundColor3 = hues[math.random(1, #hues)];
                inst.BackgroundTransparency = 0.25;
                inst.Size = UDim2.fromOffset(math.random(7, 12), math.random(5, 9));
                Library:Create('UICorner', { CornerRadius = UDim.new(0.4, 0), Parent = inst });
            elseif self.Type == 'Cyber Sparks' then
                inst.BackgroundColor3 = Library.AccentColor;
                inst.BackgroundTransparency = 0.2;
                inst.Size = UDim2.fromOffset(math.random(2, 4), math.random(2, 4));
                pData.VelY = -math.random(60, 140) * self.Speed;
                Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = inst });
            end

            table.insert(self.Particles, pData);
        end
    end

    local thunderTimer = 0;
    function WeatherEngine:Update(dt)
        local cam = workspace.CurrentCamera;
        local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080);

        if self.Type == 'Thunder' or self.Type == 'Rain' then
            thunderTimer = thunderTimer + dt;
            if thunderTimer > math.random(8, 16) then
                thunderTimer = 0;
                Library:PlayScreenFlash(Color3.fromRGB(220, 235, 255), 0.45, 0.25);
            end
        end

        local timeSec = tick();
        for _, p in ipairs(self.Particles) do
            local drift = math.sin(timeSec * 1.5 + p.Phase) * 15;
            p.X = p.X + (p.VelX + drift) * dt;
            p.Y = p.Y + p.VelY * dt;
            p.Rot = p.Rot + p.RotSpeed * dt;

            if p.Y > vp.Y + 20 then
                p.Y = -20;
                p.X = math.random(0, vp.X);
            elseif p.Y < -30 then
                p.Y = vp.Y + 10;
                p.X = math.random(0, vp.X);
            end

            if p.X > vp.X + 20 then p.X = -20;
            elseif p.X < -20 then p.X = vp.X + 20; end

            p.Inst.Position = UDim2.fromOffset(p.X, p.Y);
            if p.RotSpeed ~= 0 then p.Inst.Rotation = p.Rot; end
        end
    end

    Library.Weather = WeatherEngine;
    function Library:SetWeather(wType, density, speed, wind)
        WeatherEngine:SetWeather(wType, density, speed, wind);
    end
    function Library:ToggleWeather(bool)
        WeatherEngine.Enabled = bool;
        if WeatherEngine.Canvas then WeatherEngine.Canvas.Visible = bool; end
        WeatherEngine:Rebuild();
    end
end

-- 5. CYBER MUSIC PLAYER
do
    local MusicPlayer = {
        Sound = nil,
        Playing = false,
        CurrentTrack = 1,
        Volume = 0.5,
        Pitch = 1,
        Loop = true,
        Tracks = {
            { Name = "Cyberpunk Phonk", Id = "rbxassetid://9043887091" },
            { Name = "Synthwave Neon",  Id = "rbxassetid://1837849285" },
            { Name = "Lofi Chill Beats", Id = "rbxassetid://9048375035" },
            { Name = "Hyperpop Drift",  Id = "rbxassetid://6998634863" },
            { Name = "Anime Nightcore", Id = "rbxassetid://1843404009" },
        },
    };

    function MusicPlayer:Init()
        if self.Sound then return end
        local snd = Instance.new("Sound");
        snd.Name = "MikuMusicStream";
        snd.Volume = self.Volume;
        snd.PlaybackSpeed = self.Pitch;
        snd.Looped = self.Loop;
        snd.Parent = ScreenGui;
        self.Sound = snd;
    end

    function MusicPlayer:Play(customId)
        self:Init();
        local id = customId or (self.Tracks[self.CurrentTrack] and self.Tracks[self.CurrentTrack].Id);
        if not id or id == "" then return end
        self.Sound.SoundId = tostring(id);
        self.Sound.Volume = self.Volume;
        self.Sound.PlaybackSpeed = self.Pitch;
        self.Sound.Looped = self.Loop;
        self.Sound:Play();
        self.Playing = true;
    end

    function MusicPlayer:Pause()
        if self.Sound then self.Sound:Pause(); end
        self.Playing = false;
    end

    function MusicPlayer:Stop()
        if self.Sound then self.Sound:Stop(); end
        self.Playing = false;
    end

    function MusicPlayer:Next()
        self.CurrentTrack = (self.CurrentTrack % #self.Tracks) + 1;
        if self.Playing then self:Play(); end
    end

    function MusicPlayer:Prev()
        self.CurrentTrack = ((self.CurrentTrack - 2 + #self.Tracks) % #self.Tracks) + 1;
        if self.Playing then self:Play(); end
    end

    function MusicPlayer:SetVolume(vol)
        self.Volume = math.clamp(vol or 0.5, 0, 1);
        if self.Sound then self.Sound.Volume = self.Volume; end
    end

    function MusicPlayer:SetPitch(pitch)
        self.Pitch = math.clamp(pitch or 1, 0.5, 2.0);
        if self.Sound then self.Sound.PlaybackSpeed = self.Pitch; end
    end

    Library.MusicPlayer = MusicPlayer;
    function Library:PlayMusic(id) MusicPlayer:Play(id); end
    function Library:StopMusic() MusicPlayer:Stop(); end
end

-- 6. HITMARKER & SCREEN FLASH
do
    local FlashFrame = nil;

    function Library:PlayScreenFlash(color, intensity, duration)
        if not FlashFrame then
            FlashFrame = Library:Create('Frame', {
                Name = 'MikuScreenFlash',
                BackgroundColor3 = color or Color3.fromRGB(255, 50, 80),
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                ZIndex = 9999,
                Parent = ScreenGui,
            });
        end
        FlashFrame.BackgroundColor3 = color or Color3.fromRGB(255, 50, 80);
        FlashFrame.BackgroundTransparency = 1 - (intensity or 0.4);
        Tween(FlashFrame, TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1,
        });
    end

    function Library:PlayHitmarker(isHeadshot, style, customSoundId, vol, pitch)
        local center = workspace.CurrentCamera and (workspace.CurrentCamera.ViewportSize * 0.5) or Vector2.new(960, 540);
        local col = isHeadshot and Color3.fromRGB(255, 50, 80) or Color3.fromRGB(255, 255, 255);

        local Marker = Library:Create('Frame', {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(center.X, center.Y),
            Size = UDim2.fromOffset(24, 24),
            BackgroundTransparency = 1,
            ZIndex = 8000,
            Parent = ScreenGui,
        });

        local L1 = Library:Create('Frame', { BackgroundColor3 = col, BorderSizePixel = 0, Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 2), Rotation = 45, Parent = Marker });
        local L2 = Library:Create('Frame', { BackgroundColor3 = col, BorderSizePixel = 0, Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 2), Rotation = -45, Parent = Marker });

        local Scale = Library:Create('UIScale', { Scale = 0.6, Parent = Marker });
        Tween(Scale, TI_POP, { Scale = 1.25 });
        Tween(L1, TweenInfo.new(0.22), { BackgroundTransparency = 1 });
        Tween(L2, TweenInfo.new(0.22), { BackgroundTransparency = 1 });

        task.delay(0.25, function() Marker:Destroy(); end);

        if customSoundId and customSoundId ~= "" then
            local s = Instance.new("Sound");
            s.SoundId = tostring(customSoundId);
            s.Volume = vol or 1;
            s.PlaybackSpeed = pitch or (isHeadshot and 1.2 or 1);
            s.Parent = ScreenGui;
            s:Play();
            s.Ended:Connect(function() s:Destroy(); end);
        end
    end
end

-- 7. CUSTOM BACKGROUND
do
    local CustomBgImage = nil;
    function Library:SetCustomBackground(imageId, trans, scaleType)
        if not imageId or imageId == "" then
            if CustomBgImage then CustomBgImage.Visible = false; end
            return;
        end
        if not CustomBgImage then
            CustomBgImage = Library:Create('ImageLabel', {
                Name = 'MikuCustomUIBackground',
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                ScaleType = Enum.ScaleType.Crop,
                ZIndex = 0,
                Parent = ScreenGui,
            });
        end
        CustomBgImage.Image = tostring(imageId);
        CustomBgImage.ImageTransparency = math.clamp(trans or 0.65, 0, 1);
        if scaleType == 'Fit' then CustomBgImage.ScaleType = Enum.ScaleType.Fit;
        elseif scaleType == 'Stretch' then CustomBgImage.ScaleType = Enum.ScaleType.Stretch;
        else CustomBgImage.ScaleType = Enum.ScaleType.Crop; end
        CustomBgImage.Visible = true;
    end
end

local function OnPlayerChange()
    local PlayerList = GetPlayersString();
    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList);
        end
    end
end

Players.PlayerAdded:Connect(OnPlayerChange);
Players.PlayerRemoving:Connect(OnPlayerChange);

function Library:Panic()
    pcall(function()
        for idx, toggle in next, Toggles do
            if toggle and toggle.Value == true then
                pcall(function() toggle:SetValue(false) end)
            end
        end
        if getgenv then
            getgenv().MikuAutoExecFlag = false
            getgenv().StaffDetector = false
            getgenv().ProtectedDetector = false
            getgenv().UIGlow = false
            getgenv().KnifeRagebot = false
            getgenv().KnifeAbilitySpam = false
            getgenv().KnifeBackstabLock = false
            getgenv().AlwaysBackstab = false
            getgenv().AntiRiotEnabled = false
            getgenv().KnifeHitboxExpander = false
            getgenv().CustomHitmarkers = false
            getgenv().HitScreenFlash = false
            getgenv().KillScreenFlash = false
        end
        local cam = workspace.CurrentCamera
        if cam then pcall(function() cam.CameraType = Enum.CameraType.Custom end) end
        local lp = game:GetService("Players").LocalPlayer
        local char = lp and lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum.WalkSpeed = 16
                hum.JumpPower = 50
                hum.JumpHeight = 7.2
                hum.PlatformStand = false
            end)
        end
        if Library.WebManager then Library.WebManager:SetEnabled(false) end
    end)
    Library:Notify("🚨 PANIC: All features disabled!", 4)
end

getgenv().Library = Library;
return Library;
