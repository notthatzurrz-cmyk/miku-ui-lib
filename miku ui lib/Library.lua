local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local CoreGui = game:GetService('CoreGui');
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.IgnoreGuiInset = true;
ScreenGui.ResetOnSpawn = false;
ScreenGui.DisplayOrder = 100;
ScreenGui.Name = 'Yuno';
do
    local hudParent = CoreGui;
    pcall(function()
        if type(gethui) == 'function' then
            hudParent = gethui();
        end;
    end);
    ScreenGui.Parent = hudParent;
end;

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

local Library = {
    Registry = {};
    RegistryMap = {};

    HudRegistry = {};

    FontColor = Color3.fromRGB(236, 232, 248);
    MainColor = Color3.fromRGB(18, 14, 28);
    BackgroundColor = Color3.fromRGB(10, 8, 16);
    AccentColor = Color3.fromRGB(168, 92, 255);
    Accent = Color3.fromRGB(168, 92, 255);
    OutlineColor = Color3.fromRGB(48, 40, 68);
    RiskColor = Color3.fromRGB(255, 78, 96),

    Black = Color3.new(0, 0, 0);
    Font = Enum.Font.Arcade,

    OpenedFrames = {};
    Dropdowns = {};
    DependencyBoxes = {};

    Signals = {};
    ScreenGui = ScreenGui;
    LayoutSuspended = 0;
    PendingResizes = {};
    ConfigLoading = false;
    SilentApplyDepth = 0;
};

local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    if Library.Toggled ~= true then
        return
    end
    RainbowStep = RainbowStep + Delta

    if RainbowStep >= (1 / 60) then
        RainbowStep = 0

        Hue = Hue + (1 / 400);

        if Hue > 1 then
            Hue = 0;
        end;

        Library.CurrentRainbowHue = Hue;
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers();

    for i = 1, #PlayerList do
        PlayerList[i] = PlayerList[i].Name;
    end;

    table.sort(PlayerList, function(str1, str2) return str1 < str2 end);

    return PlayerList;
end;

local function GetTeamsString()
    local TeamList = Teams:GetTeams();

    for i = 1, #TeamList do
        TeamList[i] = TeamList[i].Name;
    end;

    table.sort(TeamList, function(str1, str2) return str1 < str2 end);
    
    return TeamList;
end;

function Library:SafeCallback(f, ...)
    if (not f) then
        return;
    end;

    local success, event = pcall(f, ...);

    if success then
        return event;
    end;

    if Library.NotifyOnError then
        local _, i = tostring(event):find(":%d+: ");
        if not i then
            return Library:Notify(tostring(event));
        end;
        return Library:Notify(tostring(event):sub(i + 1), 3);
    end;
end;

function Library:AttemptSave()
    if Library.SaveManager and type(Library.SaveManager.Save) == 'function' then
        pcall(Library.SaveManager.Save, Library.SaveManager);
    end;
end;

function Library:Create(Class, Properties)
    local _Instance = Class;

    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;

    local parent = Properties.Parent;
    for Property, Value in next, Properties do
        if Property ~= 'Parent' then
            if Property == 'Font' and typeof(Value) == 'Font' then
                _Instance.FontFace = Value;
            else
                _Instance[Property] = Value;
            end;
        end;
    end;
    if parent ~= nil then
        _Instance.Parent = parent;
    end;

    return _Instance;
end;

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeColor3 = Color3.fromRGB(8, 6, 16);
    Inst.TextStrokeTransparency = 0.5;
    if Library:IsLayoutSuspended() then
        return;
    end;

    Library:Create('UIStroke', {
        Name = 'YunoTextGlow';
        Color = Color3.fromRGB(196, 168, 255);
        Thickness = 1;
        Transparency = 0.72;
        LineJoinMode = Enum.LineJoinMode.Miter;
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual;
        Parent = Inst;
    });
end;

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Library.FontColor;
        TextSize = 16;
        TextStrokeTransparency = 0;
    });

    Library:ApplyTextStroke(_Instance);

    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor';
    }, IsHud);

    return Library:Create(_Instance, Properties);
end;

function Library:GetGuiScale(Gui)
    if typeof(Gui) == 'Instance' then
        local uiScale = Gui:FindFirstChildOfClass('UIScale');
        if uiScale and type(uiScale.Scale) == 'number' and uiScale.Scale > 0 then
            return uiScale.Scale;
        end;
    end;

    return 1;
end;

function Library:ClampGuiToViewport(Gui)
    if typeof(Gui) ~= 'Instance' or not Gui:IsA('GuiObject') then
        return Gui and Gui.Position;
    end;

    local camera = workspace.CurrentCamera;
    local vp = camera and camera.ViewportSize;
    if not vp or vp.X < 32 or vp.Y < 32 then
        return Gui.Position;
    end;

    local absSize = Gui.AbsoluteSize;
    if absSize.X < 2 or absSize.Y < 2 then
        return Gui.Position;
    end;

    local pad = 4;
    local minX = pad;
    local minY = pad;
    local maxX = vp.X - absSize.X - pad;
    local maxY = vp.Y - absSize.Y - pad;
    if maxX < minX then
        minX = pad;
        maxX = pad;
    end;
    if maxY < minY then
        minY = pad;
        maxY = pad;
    end;

    local absPos = Gui.AbsolutePosition;
    local clampedX = math.clamp(absPos.X, minX, maxX);
    local clampedY = math.clamp(absPos.Y, minY, maxY);
    if math.abs(clampedX - absPos.X) < 0.5 and math.abs(clampedY - absPos.Y) < 0.5 then
        return Gui.Position;
    end;

    local scale = Library:GetGuiScale(Gui);
    local ap = Gui.AnchorPoint;
    local offsetX = (clampedX + absSize.X * ap.X) / scale;
    local offsetY = (clampedY + absSize.Y * ap.Y) / scale;
    local nextPos = UDim2.fromOffset(math.floor(offsetX + 0.5), math.floor(offsetY + 0.5));
    if Gui.Position ~= nextPos then
        Gui.Position = nextPos;
    end;
    return nextPos;
end;

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true;

    local dragging = false;
    local grabOffset;
    local moveConn;
    local endConn;

    local function stopDrag()
        dragging = false;
        grabOffset = nil;
        if moveConn then
            moveConn:Disconnect();
            moveConn = nil;
        end;
        if endConn then
            endConn:Disconnect();
            endConn = nil;
        end;
        Library:ClampGuiToViewport(Instance);
    end;

    local function applyDrag()
        if not dragging or not grabOffset then
            return;
        end;

        local mouse = InputService:GetMouseLocation();
        local scale = Library:GetGuiScale(Instance);
        local absSize = Instance.AbsoluteSize;
        local absX = mouse.X - grabOffset.X;
        local absY = mouse.Y - grabOffset.Y;
        local camera = workspace.CurrentCamera;
        local vp = camera and camera.ViewportSize;
        if vp then
            local pad = 4;
            local minX = pad;
            local minY = pad;
            local maxX = vp.X - absSize.X - pad;
            local maxY = vp.Y - absSize.Y - pad;
            if maxX < minX then
                minX = pad;
                maxX = pad;
            end;
            if maxY < minY then
                minY = pad;
                maxY = pad;
            end;
            absX = math.clamp(absX, minX, maxX);
            absY = math.clamp(absY, minY, maxY);
        end;

        local ap = Instance.AnchorPoint;
        local offsetX = (absX + absSize.X * ap.X) / scale;
        local offsetY = (absY + absSize.Y * ap.Y) / scale;
        local nextPos = UDim2.fromOffset(math.floor(offsetX + 0.5), math.floor(offsetY + 0.5));
        if Instance.Position ~= nextPos then
            Instance.Position = nextPos;
        end;
    end;

    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
            return;
        end;

        local mouse = InputService:GetMouseLocation();
        local absPos = Instance.AbsolutePosition;
        local ObjPos = Vector2.new(mouse.X - absPos.X, mouse.Y - absPos.Y);

        if ObjPos.Y > (Cutoff or 40) then
            return;
        end;

        dragging = true;
        grabOffset = ObjPos;
        if moveConn then
            moveConn:Disconnect();
        end;
        if endConn then
            endConn:Disconnect();
        end;
        moveConn = InputService.InputChanged:Connect(function(move)
            if not dragging then
                return;
            end;
            if move.UserInputType == Enum.UserInputType.MouseMovement or move.UserInputType == Enum.UserInputType.Touch then
                applyDrag();
            end;
        end);
        endConn = InputService.InputEnded:Connect(function(ended)
            if ended.UserInputType == Enum.UserInputType.MouseButton1 or ended.UserInputType == Enum.UserInputType.Touch then
                stopDrag();
            end;
        end);
    end);
end;

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 13);
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,

        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,

        Visible = false,
    })

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y);
        TextSize = 13;
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Tooltip.ZIndex + 1,

        Parent = Tooltip;
    });

    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    Library:AddToRegistry(Label, {
        TextColor3 = 'FontColor',
    });

    local IsHovering = false

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            return
        end

        IsHovering = true

        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true

        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
end

function Library:AddCorner(instance, radius)
    if typeof(instance) ~= 'Instance' then
        return nil;
    end;
    local existing = instance:FindFirstChildOfClass('UICorner');
    if existing then
        existing.CornerRadius = UDim.new(0, radius or 8);
        return existing;
    end;
    local corner = Instance.new('UICorner');
    corner.Name = 'YunoCorner';
    corner.CornerRadius = UDim.new(0, radius or 8);
    corner.Parent = instance;
    return corner;
end;

function Library:AddStroke(instance, colorKey, thickness)
    if typeof(instance) ~= 'Instance' then
        return nil;
    end;
    local stroke = instance:FindFirstChild('YunoStroke');
    if not stroke then
        stroke = Instance.new('UIStroke');
        stroke.Name = 'YunoStroke';
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
        stroke.LineJoinMode = Enum.LineJoinMode.Round;
        stroke.Parent = instance;
    end;
    stroke.Thickness = thickness or 1;
    local color = (type(colorKey) == 'string' and Library[colorKey]) or (typeof(colorKey) == 'Color3' and colorKey) or Library.OutlineColor;
    stroke.Color = color;
    if type(colorKey) == 'string' then
        Library:AddToRegistry(stroke, { Color = colorKey });
    end;
    return stroke;
end;

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)

    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)
end;

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local ok, isOver = pcall(function()
            if Frame.Parent == nil or not Frame.Visible then
                return false;
            end;

            local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

            return Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
                and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y;
        end);

        if not ok then
            Library.OpenedFrames[Frame] = nil;
        elseif isOver then
            return true;
        end;
    end;
end;

function Library:CloseAllDropdowns(Except)
    for _, Dropdown in ipairs(Library.Dropdowns) do
        if Dropdown ~= Except and Dropdown.CloseDropdown then
            Dropdown:CloseDropdown();
        end;
    end;
end;

function Library:CloseAllPopups()
    Library:CloseAllDropdowns();
    for Frame in next, Library.OpenedFrames do
        pcall(function()
            Frame.Visible = false;
        end);
        Library.OpenedFrames[Frame] = nil;
    end;
end;

function Library:IsMobile()
    local preferredOk, preferred = pcall(function()
        return InputService.PreferredInput;
    end);
    if preferredOk and preferred == Enum.PreferredInput.Touch then
        return true;
    end;
    return InputService.TouchEnabled == true and InputService.MouseEnabled == false;
end;

function Library:GetMobileWindowSize()
    local camera = workspace.CurrentCamera;
    local viewport = camera and camera.ViewportSize or Vector2.new(720, 1280);
    local width = math.clamp(math.floor(math.min(viewport.X * 0.94, 720)), 300, 720);
    local height = math.clamp(math.floor(math.min(viewport.Y * 0.68, 460)), 260, 500);
    return UDim2.fromOffset(width, height);
end;

function Library:IsPointerInput(Input)
    return Input ~= nil and (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch);
end;

function Library:GetPointerPosition(Input)
    if Input and Input.UserInputType == Enum.UserInputType.Touch then
        return Vector2.new(Input.Position.X, Input.Position.Y);
    end;
    return Vector2.new(Mouse.X, Mouse.Y);
end;

function Library:RunWhilePointerHeld(Input, Callback)
    if not Library:IsPointerInput(Input) then
        return;
    end;

    local holding = true;
    local lastPos = Library:GetPointerPosition(Input);
    local ended = Input.Changed:Connect(function()
        if Input.UserInputState == Enum.UserInputState.End then
            holding = false;
        else
            lastPos = Library:GetPointerPosition(Input);
        end;
    end);
    local globalEnded = InputService.InputEnded:Connect(function(endedInput)
        if endedInput == Input then
            holding = false;
        end;
    end);
    local moved = InputService.InputChanged:Connect(function(move)
        if not holding then
            return;
        end;
        if move == Input
            or move.UserInputType == Enum.UserInputType.MouseMovement
            or (Input.UserInputType == Enum.UserInputType.Touch and move.UserInputType == Enum.UserInputType.Touch) then
            lastPos = Library:GetPointerPosition(move);
        end;
    end);

    while holding do
        if Input.UserInputType == Enum.UserInputType.MouseButton1
            and not InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            break;
        end;
        if Input.UserInputType ~= Enum.UserInputType.Touch then
            lastPos = Library:GetPointerPosition(Input);
        end;
        Callback(lastPos);
        RenderStepped:Wait();
    end;

    if ended then
        ended:Disconnect();
    end;
    if globalEnded then
        globalEnded:Disconnect();
    end;
    if moved then
        moved:Disconnect();
    end;
end;

function Library:SetMenuCursorVisible(Visible)
    if Visible ~= true then
        if Library.MenuCursorBody then Library.MenuCursorBody.Visible = false; end;
        if Library.MenuCursorTail then Library.MenuCursorTail.Visible = false; end;
        if Library.MenuCursorBodyOutline then Library.MenuCursorBodyOutline.Visible = false; end;
        if Library.MenuCursorTailOutline then Library.MenuCursorTailOutline.Visible = false; end;
        if Library.MenuCursor then
            Library.MenuCursor.Visible = false;
        end;
        return;
    end;
    Library:EnsureMenuCursor();
    local cursor = Library.MenuCursor;
    if cursor then
        cursor.Visible = Library.Toggled == true;
    end;
end;

function Library:SetMenuCrosshairVisible(Visible)
    Library:SetMenuCursorVisible(Visible);
end;

local function LibraryCreateDrawingTriangle(filled, zIndex, color)
    local ok, triangle = pcall(function()
        local object = Drawing.new('Triangle');
        object.Filled = filled == true;
        object.Thickness = filled and 1 or 1.5;
        object.Visible = false;
        object.ZIndex = zIndex;
        object.Color = color;
        object.Transparency = 1;
        return object;
    end);
    if ok then
        return triangle;
    end;
    return nil;
end;

local function LibrarySetTrianglePoints(triangle, a, b, c)
    if not triangle then
        return;
    end;
    triangle.PointA = a;
    triangle.PointB = b;
    triangle.PointC = c;
end;

local function LibraryHideMenuCursorDrawings()
    if Library.MenuCursorBody then Library.MenuCursorBody.Visible = false; end;
    if Library.MenuCursorTail then Library.MenuCursorTail.Visible = false; end;
    if Library.MenuCursorBodyOutline then Library.MenuCursorBodyOutline.Visible = false; end;
    if Library.MenuCursorTailOutline then Library.MenuCursorTailOutline.Visible = false; end;
end;

function Library:EnsureMenuCursor()
    if Library.MenuCursorBody or (Library.MenuCursor and Library.MenuCursor.Parent) then
        return Library.MenuCursor or Library.MenuCursorBody;
    end;

    local purple = Library.AccentColor or Color3.fromRGB(176, 70, 255);
    local outlineColor = Color3.fromRGB(18, 6, 32);

    local body = LibraryCreateDrawingTriangle(true, 10000, purple);
    local tail = LibraryCreateDrawingTriangle(true, 10000, purple);
    local bodyOutline = LibraryCreateDrawingTriangle(false, 10001, outlineColor);
    local tailOutline = LibraryCreateDrawingTriangle(false, 10001, outlineColor);

    local root = nil;
    local arrow = nil;
    if not body then
        root = Library:Create('Frame', {
            Active = false;
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Size = UDim2.fromOffset(16, 24);
            ZIndex = 10000;
            Visible = false;
            Parent = ScreenGui;
        });
        arrow = Library:Create('ImageLabel', {
            Active = false;
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Image = 'rbxasset://textures/Cursors/KeyboardMouse/ArrowCursor.png';
            ImageColor3 = purple;
            ScaleType = Enum.ScaleType.Fit;
            Size = UDim2.fromOffset(16, 24);
            ZIndex = 10001;
            Parent = root;
        });
    end;

    Library.MenuCursor = root or body;
    Library.MenuCursorImage = arrow;
    Library.MenuCursorBody = body;
    Library.MenuCursorTail = tail;
    Library.MenuCursorBodyOutline = bodyOutline;
    Library.MenuCursorTailOutline = tailOutline;
    Library.MenuCursorOutline = bodyOutline;
    Library.MenuCrosshair = Library.MenuCursor;

    if not Library.MenuCursorConnection then
        Library.MenuCursorConnection = RenderStepped:Connect(function()
            local open = Library.Toggled == true;
            if not open then
                LibraryHideMenuCursorDrawings();
                if Library.MenuCursorImage and Library.MenuCursorImage.Parent then
                    Library.MenuCursor.Visible = false;
                end;
                if Library.MenuCursorSavedMouseIcon ~= nil then
                    InputService.MouseIconEnabled = Library.MenuCursorSavedMouseIcon;
                    Library.MenuCursorSavedMouseIcon = nil;
                end;
                return;
            end;

            if Library.MenuCursorSavedMouseIcon == nil then
                Library.MenuCursorSavedMouseIcon = InputService.MouseIconEnabled;
            end;
            InputService.MouseIconEnabled = false;

            local pos = InputService:GetMouseLocation();
            local tint = Library.AccentColor or Color3.fromRGB(176, 70, 255);

            if Library.MenuCursorBody then
                local tip = Vector2.new(pos.X, pos.Y);
                local left = Vector2.new(pos.X, pos.Y + 17);
                local right = Vector2.new(pos.X + 12, pos.Y + 12);
                local tailLeft = Vector2.new(pos.X + 4, pos.Y + 12);
                local tailBottom = Vector2.new(pos.X + 7, pos.Y + 20);
                local tailRight = Vector2.new(pos.X + 10, pos.Y + 18);

                Library.MenuCursorBody.Color = tint;
                Library.MenuCursorBody.Visible = true;
                LibrarySetTrianglePoints(Library.MenuCursorBody, tip, left, right);
                if Library.MenuCursorTail then
                    Library.MenuCursorTail.Color = tint;
                    Library.MenuCursorTail.Visible = true;
                    LibrarySetTrianglePoints(Library.MenuCursorTail, tailLeft, tailBottom, tailRight);
                end;
                if Library.MenuCursorBodyOutline then
                    Library.MenuCursorBodyOutline.Visible = true;
                    LibrarySetTrianglePoints(Library.MenuCursorBodyOutline, tip, left, right);
                end;
                if Library.MenuCursorTailOutline then
                    Library.MenuCursorTailOutline.Visible = true;
                    LibrarySetTrianglePoints(Library.MenuCursorTailOutline, tailLeft, tailBottom, tailRight);
                end;
            elseif Library.MenuCursor and Library.MenuCursor.Parent then
                Library.MenuCursor.Position = UDim2.fromOffset(pos.X, pos.Y);
                Library.MenuCursor.Visible = true;
                if Library.MenuCursorImage then
                    Library.MenuCursorImage.ImageColor3 = tint;
                end;
            end;
        end);
        table.insert(Library.Signals, Library.MenuCursorConnection);
    end;

    return Library.MenuCursor;
end;

function Library:EnsureMenuCrosshair()
    return Library:EnsureMenuCursor();
end;

function Library:IsPointOverFrame(Frame, Point)
    if typeof(Frame) ~= 'Instance' or not Frame:IsA('GuiObject') or typeof(Point) ~= 'Vector2' then
        return false;
    end;

    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
    return Point.X >= AbsPos.X and Point.X <= AbsPos.X + AbsSize.X
        and Point.Y >= AbsPos.Y and Point.Y <= AbsPos.Y + AbsSize.Y;
end;

function Library:IsMouseOverFrame(Frame)
    return Library:IsPointOverFrame(Frame, Vector2.new(Mouse.X, Mouse.Y));
end;

function Library:IsLayoutSuspended()
    return (self.LayoutSuspended or 0) > 0;
end;

function Library:IsSilentApplying()
    return self.ConfigLoading == true;
end;

function Library:BeginSilentApply()
    self.SilentApplyDepth = (self.SilentApplyDepth or 0) + 1;
    self.ConfigLoading = true;
    self:SuspendLayout();
end;

function Library:EndSilentApply()
    self.SilentApplyDepth = math.max(0, (self.SilentApplyDepth or 0) - 1);
    if self.SilentApplyDepth <= 0 then
        self.ConfigLoading = false;
        self.SilentApplyDepth = 0;
    end;
    task.wait();
    if self.ConfigLoading == false then
        -- Dependency visibility was suppressed per-option during load; reconcile once.
        task.defer(function()
            pcall(function()
                self:UpdateDependencyBoxes();
            end);
        end);
    end;
    self:ResumeLayout();
end;

function Library:SuspendLayout()
    self.LayoutSuspended = (self.LayoutSuspended or 0) + 1;
end;

function Library:ResumeLayout()
    self.LayoutSuspended = math.max(0, (self.LayoutSuspended or 0) - 1);
    if self.LayoutSuspended > 0 then
        return;
    end;
    self:FlushPendingLayout();
end;

function Library:FlushPendingLayout()
    if self._ResumeLayoutRunning then
        self._ResumeLayoutQueued = true;
        return;
    end;
    self._ResumeLayoutRunning = true;
    task.spawn(function()
        self._BulkLayout = true;
        local slice = os.clock();
        local resized = 0;
        for _ = 1, 4 do
            local pending = self.PendingResizes;
            self.PendingResizes = {};
            local any = false;
            for groupbox in pairs(pending) do
                any = true;
                pcall(function()
                    if type(groupbox) == 'table' and type(groupbox.Resize) == 'function' then
                        groupbox:Resize();
                    end;
                end);
                resized = resized + 1;
                if resized % 24 == 0 or os.clock() - slice >= 0.016 then
                    task.wait();
                    slice = os.clock();
                end;
            end;
            if not any then
                break;
            end;
        end;
        self._BulkLayout = false;
        self._PendingDepboxUpdate = false;
        if self.Toggled == true and self.Window and type(self.Window.RelayoutTabs) == 'function' then
            task.defer(self.Window.RelayoutTabs);
        end;
        local updated = 0;
        slice = os.clock();
        for _, Depbox in next, Library.DependencyBoxes do
            if Library.Unloaded then
                break;
            end;
            pcall(function()
                Depbox:Update();
            end);
            updated = updated + 1;
            if updated % 4 == 0 or os.clock() - slice >= 0.003 then
                task.wait();
                slice = os.clock();
            end;
        end;
        self._ResumeLayoutRunning = false;
        if self._ResumeLayoutQueued then
            self._ResumeLayoutQueued = false;
            if not self:IsLayoutSuspended() then
                self:FlushPendingLayout();
                return;
            end;
        end;
        if self._OpenWhenReady and not self.Toggled and type(self.Toggle) == 'function' then
            self._OpenWhenReady = false;
            local toggle = self.Toggle;
            task.defer(function()
                if not self.Toggled then
                    toggle(self);
                end;
            end);
        end;
    end);
end;

function Library:UpdateDependencyBoxes()
    if Library:IsLayoutSuspended() then
        Library._PendingDepboxUpdate = true;
        return;
    end;
    Library._PendingDepboxUpdate = false;
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update();
    end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, FontObj, Size, Resolution)
    local cache = Library._TextBoundsCache;
    if type(cache) ~= 'table' then
        cache = {};
        Library._TextBoundsCache = cache;
    end;
    local key = tostring(Text) .. '\0' .. tostring(Size);
    local hit = cache[key];
    if hit then
        return hit[1], hit[2];
    end;
    local enumFont = Enum.Font.Arcade;
    if typeof(FontObj) == 'EnumItem' then
        enumFont = FontObj;
    end;
    local Bounds = TextService:GetTextSize(Text, Size, enumFont, Resolution or Vector2.new(1920, 1080))
    cache[key] = { Bounds.X, Bounds.Y };
    return Bounds.X, Bounds.Y
end;

function Library:GetDarkerColor(Color)
    if typeof(Color) ~= 'Color3' then
        Color = self.AccentColor or Color3.fromRGB(176, 70, 255)
    end
    local ok, h, s, v = pcall(Color3.toHSV, Color)
    if not ok or type(h) ~= 'number' then
        return Color3.fromRGB(80, 40, 120)
    end
    return Color3.fromHSV(h, s, v / 1.5);
end;
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1;
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    };

    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;

    if IsHud then
        table.insert(Library.HudRegistry, Data);
    end;
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];

    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx);
            end;
        end;

        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx);
            end;
        end;

        Library.RegistryMap[Instance] = nil;
    end;
end;

function Library:UpdateColorsUsingRegistry()
    if Library.Unloaded then
        return;
    end;
    if Library._ColorUpdateRunning then
        Library._ColorUpdateQueued = true;
        return;
    end;
    Library._ColorUpdateRunning = true;
    task.spawn(function()
        local idx = 0;
        for _, Object in next, Library.Registry do
            if Library.Unloaded then
                break;
            end;
            if type(Object) == 'table' and typeof(Object.Instance) == 'Instance' and Object.Instance.Parent and type(Object.Properties) == 'table' then
                for Property, ColorIdx in next, Object.Properties do
                    if type(ColorIdx) == 'string' then
                        pcall(function()
                            Object.Instance[Property] = Library[ColorIdx];
                        end);
                    elseif type(ColorIdx) == 'function' then
                        pcall(function()
                            Object.Instance[Property] = ColorIdx();
                        end);
                    end;
                end;
            end;
            idx = idx + 1;
            if idx % 50 == 0 then
                task.wait();
            end;
        end;
        Library._ColorUpdateRunning = false;
        if Library._ColorUpdateQueued and not Library.Unloaded then
            Library._ColorUpdateQueued = false;
            Library:UpdateColorsUsingRegistry();
        end;
    end);
end;

function Library:GiveSignal(Signal)
    -- Only used for signals not attached to library instances, as those should be cleaned up on object destruction by Roblox
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    -- Unload all of the signals
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        Connection:Disconnect()
    end

     -- Call our unload callback, maybe to undo some hooks etc
    if Library.OnUnload then
        Library.OnUnload()
    end

    ScreenGui:Destroy()

    local function removeDrawing(object)
        if object then
            pcall(function()
                object.Visible = false;
                if object.Remove then
                    object:Remove();
                elseif object.Destroy then
                    object:Destroy();
                end;
            end);
        end;
    end;
    removeDrawing(Library.MenuCursorBody);
    removeDrawing(Library.MenuCursorTail);
    removeDrawing(Library.MenuCursorBodyOutline);
    removeDrawing(Library.MenuCursorTailOutline);
    Library.MenuCursorBody = nil;
    Library.MenuCursorTail = nil;
    Library.MenuCursor = nil;
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

function Library:ResetToFactoryDefaults(Skip)
    Skip = Skip or {};

    for idx, toggle in next, Toggles do
        if Skip[idx] then
            continue;
        end;
        if toggle and toggle.FactoryDefault ~= nil and type(toggle.SetValue) == 'function' then
            pcall(toggle.SetValue, toggle, toggle.FactoryDefault);
        end;
    end;

    for idx, option in next, Options do
        if Skip[idx] then
            continue;
        end;
        if not option then
            continue;
        end;

        local optionType = option.Type;
        if optionType == 'Slider' or optionType == 'Input' then
            if option.FactoryDefault ~= nil and type(option.SetValue) == 'function' then
                pcall(option.SetValue, option, option.FactoryDefault);
            end;
        elseif optionType == 'Dropdown' then
            if type(option.SetValue) == 'function' then
                local def = option.FactoryDefault;
                if option.Multi and type(def) == 'table' then
                    local copied = {};
                    for key, value in next, def do
                        copied[key] = value;
                    end;
                    pcall(option.SetValue, option, copied);
                else
                    pcall(option.SetValue, option, def);
                end;
            end;
        elseif optionType == 'ColorPicker' then
            if option.FactoryDefault ~= nil and type(option.SetValueRGB) == 'function' then
                pcall(option.SetValueRGB, option, option.FactoryDefault, option.FactoryTransparency);
            end;
        elseif optionType == 'GradientPicker' then
            if option.FactoryDefault ~= nil and type(option.SetValue) == 'function' then
                pcall(option.SetValue, option, option.FactoryDefault);
            end;
        elseif optionType == 'KeyPicker' then
            if type(option.SetValue) == 'function' then
                pcall(option.SetValue, option, { option.FactoryDefault, option.FactoryMode });
            end;
            option.Toggled = false;
            if type(option.Update) == 'function' then
                pcall(option.Update, option);
            end;
        end;
    end;
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance);
    end;
end))

local BaseAddons = {};

do
    local Funcs = {};
    local SharedHueColorSequence

    local function GetSharedHueColorSequence()
        if SharedHueColorSequence then
            return SharedHueColorSequence
        end
        local sequenceTable = {}
        for hue = 0, 1, 0.1 do
            table.insert(sequenceTable, ColorSequenceKeypoint.new(hue, Color3.fromHSV(hue, 1, 1)))
        end
        SharedHueColorSequence = ColorSequence.new(sequenceTable)
        return SharedHueColorSequence
    end

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;
        -- local Container = self.Container;

        assert(Info.Default, 'AddColorPicker: Missing default value.');

        local ColorPicker = {
            Value = Info.Default;
            FactoryDefault = Info.Default;
            Transparency = Info.Transparency or 0;
            FactoryTransparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end;
        };

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);

            ColorPicker.Hue = H;
            ColorPicker.Sat = S;
            ColorPicker.Vib = V;
        end;

        ColorPicker:SetHSVFromRGB(ColorPicker.Value);

        local SwatchWidth = Library:IsMobile() and 36 or 28;
        local SwatchHeight = Library:IsMobile() and 18 or 14;
        local DisplayFrame = Library:Create('Frame', {
            Active = true;
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            BorderMode = Enum.BorderMode.Inset;
            LayoutOrder = 2;
            Size = UDim2.new(0, SwatchWidth, 0, SwatchHeight);
            ZIndex = 10;
            Parent = ToggleLabel;
        });
        Library:AddCorner(DisplayFrame, 2);

        -- Transparency image taken from https://github.com/matas3535/SplixPrivateDrawingLibrary/blob/main/Library.lua cus i'm lazy
        local CheckerFrame = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(0, SwatchWidth - 1, 0, SwatchHeight - 1);
            ZIndex = 5;
            Image = 'http://www.roblox.com/asset/?id=12977615774';
            Visible = not not Info.Transparency;
            Parent = DisplayFrame;
        });

        -- 1/16/23
        -- Rewrote this to be placed inside the Library ScreenGui
        -- There was some issue which caused RelativeOffset to be way off
        -- Thus the color picker would never show

        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color';
            Active = true;
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
            Visible = false;
            ZIndex = 15;
            Parent = ScreenGui,
        });

        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18);
        end)

        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        });

        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 25);
            Size = UDim2.new(0, 200, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibMapOuter;
        });

        local SatVibMap = Library:Create('ImageLabel', {
            Active = true;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapInner;
        });

        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = SatVibMap;
        });

        local CursorInner = Library:Create('ImageLabel', {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
            Position = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ZIndex = 20;
            Parent = CursorOuter;
        })

        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 208, 0, 25);
            Size = UDim2.new(0, 15, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local HueSelectorInner = Library:Create('Frame', {
            Active = true;
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorOuter;
        });

        local HueCursor = Library:Create('Frame', { 
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0, 0.5);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, 0, 0, 1);
            ZIndex = 18;
            Parent = HueSelectorInner;
        });

        local HueBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner;
        });

        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18,
            Parent = HueBoxOuter;
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = HueBoxInner;
        });

        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = 'Hex color',
            Text = '#FFFFFF',
            TextColor3 = Library.FontColor;
            TextSize = 13;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 20,
            Parent = HueBoxInner;
        });

        Library:ApplyTextStroke(HueBox);

        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner
        });

        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox'), {
            Text = '255, 255, 255',
            PlaceholderText = 'RGB color',
            TextColor3 = Library.FontColor
        });

        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor;
        
        if Info.Transparency then 
            TransparencyBoxOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.fromOffset(4, 251);
                Size = UDim2.new(1, -8, 0, 15);
                ZIndex = 19;
                Parent = PickerFrameInner;
            });

            TransparencyBoxInner = Library:Create('Frame', {
                Active = true;
                BackgroundColor3 = ColorPicker.Value;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 19;
                Parent = TransparencyBoxOuter;
            });

            Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' });

            Library:Create('ImageLabel', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Image = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex = 20;
                Parent = TransparencyBoxInner;
            });

            TransparencyCursor = Library:Create('Frame', { 
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint = Vector2.new(0.5, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(0, 1, 1, 0);
                ZIndex = 21;
                Parent = TransparencyBoxInner;
            });
        end;

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14);
            Position = UDim2.fromOffset(5, 5);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = 13;
            Text = ColorPicker.Title,--Info.Default;
            TextWrapped = false;
            ZIndex = 16;
            Parent = PickerFrameInner;
        });


        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create('Frame', {
                BorderColor3 = Color3.new(),
                ZIndex = 14,

                Visible = false,
                Parent = ScreenGui
            })

            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.fromScale(1, 1);
                ZIndex = 15;
                Parent = ContextMenu.Container;
            });

            Library:Create('UIListLayout', {
                Name = 'Layout',
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = ContextMenu.Inner;
            });

            Library:Create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            });

            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end

            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end

                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end

            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)

            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)

            Library:AddToRegistry(ContextMenu.Inner, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            function ContextMenu:Show()
                self.Container.Visible = true
            end

            function ContextMenu:Hide()
                self.Container.Visible = false
            end

            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then
                    Callback = function() end
                end

                local Button = Library:CreateLabel({
                    Active = true;
                    Size = UDim2.new(1, 0, 0, 15);
                    TextSize = 13;
                    Text = Str;
                    ZIndex = 16;
                    Parent = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left,
                });

                Library:OnHighlight(Button, Button, 
                    { TextColor3 = 'AccentColor' },
                    { TextColor3 = 'FontColor' }
                );

                Button.InputBegan:Connect(function(Input)
                    if not Library:IsPointerInput(Input) then
                        return
                    end

                    Callback()
                end)
            end

            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Copied color!', 2)
            end)

            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then
                    return Library:Notify('You have not copied a color!', 2)
                end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)


            ContextMenu:AddOption('Copy HEX', function()
                pcall(setclipboard, ColorPicker.Value:ToHex())
                Library:Notify('Copied hex code to clipboard!', 2)
            end)

            ContextMenu:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', '))
                Library:Notify('Copied RGB values to clipboard!', 2)
            end)

        end

        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor'; });
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });

        Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBox, { TextColor3 = 'FontColor', });
        Library:AddToRegistry(HueBox, { TextColor3 = 'FontColor', });

        local HueSelectorGradient = Library:Create('UIGradient', {
            Color = GetSharedHueColorSequence();
            Rotation = 90;
            Parent = HueSelectorInner;
        });

        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end

            ColorPicker:Display()
        end)

        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r and g and b then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end

            ColorPicker:Display()
        end)

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);

            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value;
                BackgroundTransparency = ColorPicker.Transparency;
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            });

            if Library.ConfigLoading then
                return;
            end;

            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);

            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value;
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0);
            end;

            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0);
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0);

            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')

            if Library:IsLayoutSuspended() then
                return;
            end;

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value);
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value);
        end;

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func;
            if not Library:IsLayoutSuspended() then
                pcall(Func, ColorPicker.Value)
            end;
        end;

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false;
                    Library.OpenedFrames[Frame] = nil;
                end;
            end;

            PickerFrameOuter.Visible = true;
            Library.OpenedFrames[PickerFrameOuter] = true;
            task.defer(function()
                Library:ClampGuiToViewport(PickerFrameOuter);
            end);
        end;

        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false;
            Library.OpenedFrames[PickerFrameOuter] = nil;
        end;

        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3]);

            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        SatVibMap.InputBegan:Connect(function(Input)
            Library:RunWhilePointerHeld(Input, function(pointer)
                local MinX = SatVibMap.AbsolutePosition.X;
                local MaxX = MinX + SatVibMap.AbsoluteSize.X;
                local MouseX = math.clamp(pointer.X, MinX, MaxX);

                local MinY = SatVibMap.AbsolutePosition.Y;
                local MaxY = MinY + SatVibMap.AbsoluteSize.Y;
                local MouseY = math.clamp(pointer.Y, MinY, MaxY);

                ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX);
                ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY));
                ColorPicker:Display();
            end);
            if Library:IsPointerInput(Input) then
                Library:AttemptSave();
            end;
        end);

        HueSelectorInner.InputBegan:Connect(function(Input)
            Library:RunWhilePointerHeld(Input, function(pointer)
                local MinY = HueSelectorInner.AbsolutePosition.Y;
                local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y;
                local MouseY = math.clamp(pointer.Y, MinY, MaxY);

                ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY));
                ColorPicker:Display();
            end);
            if Library:IsPointerInput(Input) then
                Library:AttemptSave();
            end;
        end);

        DisplayFrame.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide()
                else
                    ContextMenu:Hide()
                    ColorPicker:Show()
                end;
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show()
                ColorPicker:Hide()
            end
        end);

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                Library:RunWhilePointerHeld(Input, function(pointer)
                    local MinX = TransparencyBoxInner.AbsolutePosition.X;
                    local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X;
                    local MouseX = math.clamp(pointer.X, MinX, MaxX);

                    ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX));
                    ColorPicker:Display();
                end);
                if Library:IsPointerInput(Input) then
                    Library:AttemptSave();
                end;
            end);
        end;

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize;
                local pointer = Library:GetPointerPosition(Input);

                if pointer.X < AbsPos.X or pointer.X > AbsPos.X + AbsSize.X
                    or pointer.Y < (AbsPos.Y - 20 - 1) or pointer.Y > AbsPos.Y + AbsSize.Y then

                    ColorPicker:Hide();
                end;

                if not Library:IsMouseOverFrame(ContextMenu.Container) then
                    ContextMenu:Hide()
                end
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))

        ColorPicker:Display();
        ColorPicker.DisplayFrame = DisplayFrame

        Options[Idx] = ColorPicker;

        return self;
    end;

    function Funcs:AddGradientPicker(Idx, Info)
        assert(Info.Default, 'AddGradientPicker: Missing default value.');

        local SharedRainbow
        local function RainbowSequence()
            if SharedRainbow then
                return SharedRainbow
            end
            SharedRainbow = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                ColorSequenceKeypoint.new(0.2, Color3.fromHSV(0.2, 1, 1)),
                ColorSequenceKeypoint.new(0.4, Color3.fromHSV(0.4, 1, 1)),
                ColorSequenceKeypoint.new(0.6, Color3.fromHSV(0.6, 1, 1)),
                ColorSequenceKeypoint.new(0.8, Color3.fromHSV(0.8, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(0.99, 1, 1)),
            })
            return SharedRainbow
        end

        local function CopyColor(value, fallback)
            if typeof(value) == 'Color3' then
                return value
            end
            if type(value) == 'string' then
                local ok, parsed = pcall(Color3.fromHex, value:gsub('^#', ''))
                if ok and typeof(parsed) == 'Color3' then
                    return parsed
                end
            end
            return fallback or Color3.new(1, 1, 1)
        end

        local function MixSequence(c1, c2, c3)
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, c1),
                ColorSequenceKeypoint.new(0.5, c2),
                ColorSequenceKeypoint.new(1, c3),
            })
        end

        local defaults = Info.Default
        local Colors = {
            CopyColor(defaults[1] or defaults.Color1, Color3.fromRGB(255, 80, 160)),
            CopyColor(defaults[2] or defaults.Color2, Color3.fromRGB(255, 210, 70)),
            CopyColor(defaults[3] or defaults.Color3, Color3.fromRGB(70, 170, 255)),
        }

        local GradientPicker = {
            Value = { Colors[1], Colors[2], Colors[3] },
            FactoryDefault = { Colors[1], Colors[2], Colors[3] },
            Type = 'GradientPicker',
            Title = type(Info.Title) == 'string' and Info.Title or 'Color mix',
            Text = Info.Text or 'Color Mix',
            SelectedStop = 1,
            Callback = Info.Callback or function() end,
        }

        local Groupbox = self
        local Container = Groupbox.Container

        Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 10),
            TextSize = 13,
            Text = GradientPicker.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Bottom,
            ZIndex = 5,
            Parent = Container,
        })
        Groupbox:AddBlank(3)

        local PreviewOuter = Library:Create('Frame', {
            Active = true,
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, -4, 0, Library:IsMobile() and 22 or 18),
            ZIndex = 5,
            Parent = Container,
        })
        Library:AddToRegistry(PreviewOuter, { BorderColor3 = 'Black' })

        local PreviewInner = Library:Create('Frame', {
            Active = true,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = PreviewOuter,
        })
        Library:AddToRegistry(PreviewInner, { BorderColor3 = 'OutlineColor' })

        local PreviewGradient = Library:Create('UIGradient', {
            Color = MixSequence(Colors[1], Colors[2], Colors[3]),
            Parent = PreviewInner,
        })

        local MixOverlay = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.55,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 7,
            Parent = PreviewInner,
        })
        Library:Create('UIGradient', {
            Color = RainbowSequence(),
            Rotation = 18,
            Parent = MixOverlay,
        })

        local StopFrames = {}
        for index = 1, 3 do
            local stop = Library:Create('Frame', {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Colors[index],
                BorderColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 1,
                Position = UDim2.new(0.14 + (index - 1) * 0.36, 0, 0.5, 0),
                Size = UDim2.fromOffset(10, 10),
                ZIndex = 8,
                Parent = PreviewInner,
            })
            Library:Create('UICorner', {
                CornerRadius = UDim.new(1, 0),
                Parent = stop,
            })
            StopFrames[index] = stop
        end

        local popup = {
            Built = false,
            Outer = nil,
            MixInner = nil,
            MixCursor = nil,
            LiveMixGradient = nil,
            PickerStops = {},
        }

        local function SampleMixColor(nx, ny)
            nx = math.clamp(nx, 0, 1)
            ny = math.clamp(ny, 0, 1)
            local a = Color3.fromHSV(nx, 0.95, 1)
            local b = Color3.fromHSV(ny, 0.88, 0.98)
            local c = Color3.fromHSV((nx * 0.65 + ny * 0.45) % 1, 0.82, 0.92)
            local r = a.R * 0.46 + b.R * 0.32 + c.R * 0.22
            local g = a.G * 0.46 + b.G * 0.32 + c.G * 0.22
            local bch = a.B * 0.46 + b.B * 0.32 + c.B * 0.22
            local shade = 0.28 + (1 - ny) * 0.72
            return Color3.new(r * shade, g * shade, bch * shade)
        end

        function GradientPicker:Display()
            PreviewGradient.Color = MixSequence(Colors[1], Colors[2], Colors[3])
            for index = 1, 3 do
                StopFrames[index].BackgroundColor3 = Colors[index]
                StopFrames[index].BorderColor3 = (index == GradientPicker.SelectedStop) and Library.AccentColor or Color3.new(1, 1, 1)
                if popup.PickerStops[index] then
                    popup.PickerStops[index].BackgroundColor3 = Colors[index]
                    popup.PickerStops[index].BorderColor3 = (index == GradientPicker.SelectedStop) and Library.AccentColor or Color3.new(1, 1, 1)
                end
            end
            if popup.LiveMixGradient then
                popup.LiveMixGradient.Color = MixSequence(Colors[1], Colors[2], Colors[3])
            end
            GradientPicker.Value = { Colors[1], Colors[2], Colors[3] }
            if Library.ConfigLoading or Library:IsLayoutSuspended() then
                return
            end
            Library:SafeCallback(GradientPicker.Callback, GradientPicker.Value)
            Library:SafeCallback(GradientPicker.Changed, GradientPicker.Value)
        end

        local function EnsurePopup()
            if popup.Built then
                return
            end
            popup.Built = true

            local PickerFrameOuter = Library:Create('Frame', {
                Name = 'Color',
                Active = true,
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderColor3 = Color3.new(0, 0, 0),
                Position = UDim2.fromOffset(PreviewOuter.AbsolutePosition.X, PreviewOuter.AbsolutePosition.Y + 22),
                Size = UDim2.fromOffset(248, 286),
                Visible = false,
                ZIndex = 15,
                Parent = ScreenGui,
            })
            popup.Outer = PickerFrameOuter

            PreviewOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
                if PickerFrameOuter.Visible then
                    PickerFrameOuter.Position = UDim2.fromOffset(PreviewOuter.AbsolutePosition.X, PreviewOuter.AbsolutePosition.Y + 22)
                end
            end)

            local PickerFrameInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 16,
                Parent = PickerFrameOuter,
            })
            Library:AddToRegistry(PickerFrameInner, {
                BackgroundColor3 = 'BackgroundColor',
                BorderColor3 = 'OutlineColor',
            })

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 2),
                ZIndex = 17,
                Parent = PickerFrameInner,
            })
            Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor' })

            Library:CreateLabel({
                Size = UDim2.new(1, -10, 0, 14),
                Position = UDim2.fromOffset(6, 6),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextSize = 13,
                Text = GradientPicker.Title,
                TextWrapped = false,
                ZIndex = 17,
                Parent = PickerFrameInner,
            })

            local MixOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0),
                Position = UDim2.fromOffset(6, 26),
                Size = UDim2.fromOffset(236, 168),
                ZIndex = 17,
                Parent = PickerFrameInner,
            })
            local MixInner = Library:Create('Frame', {
                Active = true,
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                ClipsDescendants = true,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 18,
                Parent = MixOuter,
            })
            popup.MixInner = MixInner
            Library:AddToRegistry(MixInner, { BorderColor3 = 'OutlineColor' })

            local rainbow = RainbowSequence()
            Library:Create('UIGradient', { Color = rainbow, Parent = MixInner })

            local MixLayerA = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.28,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 19,
                Parent = MixInner,
            })
            Library:Create('UIGradient', { Color = rainbow, Rotation = 90, Parent = MixLayerA })

            local MixLayerB = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.42,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 20,
                Parent = MixInner,
            })
            Library:Create('UIGradient', { Color = rainbow, Rotation = 38, Parent = MixLayerB })

            local MixShade = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.22,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 21,
                Parent = MixInner,
            })
            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.new(0.08, 0.08, 0.1)),
                }),
                Rotation = 90,
                Parent = MixShade,
            })

            local MixCursor = Library:Create('Frame', {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.fromOffset(8, 8),
                ZIndex = 22,
                Parent = MixInner,
            })
            popup.MixCursor = MixCursor
            Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = MixCursor })

            local StopRow = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(6, 200),
                Size = UDim2.fromOffset(236, 22),
                ZIndex = 17,
                Parent = PickerFrameInner,
            })
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Parent = StopRow,
            })

            for index = 1, 3 do
                local stop = Library:Create('Frame', {
                    Active = true,
                    BackgroundColor3 = Colors[index],
                    BorderColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 2,
                    LayoutOrder = index,
                    Size = UDim2.fromOffset(22, 22),
                    ZIndex = 18,
                    Parent = StopRow,
                })
                Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = stop })
                popup.PickerStops[index] = stop
                stop.InputBegan:Connect(function(Input)
                    if Library:IsPointerInput(Input) then
                        GradientPicker.SelectedStop = index
                        GradientPicker:Display()
                    end
                end)
            end

            local LiveMix = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Position = UDim2.fromOffset(6, 228),
                Size = UDim2.fromOffset(236, 18),
                ZIndex = 17,
                Parent = PickerFrameInner,
            })
            Library:AddToRegistry(LiveMix, { BorderColor3 = 'OutlineColor' })
            popup.LiveMixGradient = Library:Create('UIGradient', {
                Color = MixSequence(Colors[1], Colors[2], Colors[3]),
                Parent = LiveMix,
            })
            local LiveMixWash = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.62,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 18,
                Parent = LiveMix,
            })
            Library:Create('UIGradient', { Color = rainbow, Rotation = 16, Parent = LiveMixWash })

            Library:CreateLabel({
                Size = UDim2.new(1, -12, 0, 28),
                Position = UDim2.fromOffset(6, 250),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextSize = 12,
                Text = 'Click a stop, then click the mix. Colors blend into one gradient.',
                TextWrapped = true,
                ZIndex = 17,
                Parent = PickerFrameInner,
            })

            MixInner.InputBegan:Connect(function(Input)
                Library:RunWhilePointerHeld(Input, function(pointer)
                    local absPos = MixInner.AbsolutePosition
                    local absSize = MixInner.AbsoluteSize
                    if absSize.X <= 0 or absSize.Y <= 0 then
                        return
                    end
                    local nx = math.clamp((pointer.X - absPos.X) / absSize.X, 0, 1)
                    local ny = math.clamp((pointer.Y - absPos.Y) / absSize.Y, 0, 1)
                    MixCursor.Position = UDim2.new(nx, 0, ny, 0)
                    Colors[GradientPicker.SelectedStop] = SampleMixColor(nx, ny)
                    GradientPicker:Display()
                end)
                if Library:IsPointerInput(Input) then
                    Library:AttemptSave()
                end
            end)

            Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
                if not Library:IsPointerInput(Input) or not PickerFrameOuter.Visible then
                    return
                end
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize
                local pointer = Library:GetPointerPosition(Input)
                if pointer.X < AbsPos.X or pointer.X > AbsPos.X + AbsSize.X
                    or pointer.Y < (AbsPos.Y - 22) or pointer.Y > AbsPos.Y + AbsSize.Y then
                    GradientPicker:Hide()
                end
            end))
        end

        function GradientPicker:OnChanged(Func)
            GradientPicker.Changed = Func
            pcall(Func, GradientPicker.Value)
        end

        function GradientPicker:Show()
            EnsurePopup()
            for Frame in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false
                    Library.OpenedFrames[Frame] = nil
                end
            end
            popup.Outer.Visible = true
            popup.Outer.Position = UDim2.fromOffset(PreviewOuter.AbsolutePosition.X, PreviewOuter.AbsolutePosition.Y + 22)
            Library.OpenedFrames[popup.Outer] = true
            GradientPicker:Display()
            task.defer(function()
                Library:ClampGuiToViewport(popup.Outer)
            end)
        end

        function GradientPicker:Hide()
            if popup.Outer then
                popup.Outer.Visible = false
                Library.OpenedFrames[popup.Outer] = nil
            end
        end

        function GradientPicker:SetValue(Data)
            if type(Data) ~= 'table' then
                return
            end
            Colors[1] = CopyColor(Data[1] or Data.Color1, Colors[1])
            Colors[2] = CopyColor(Data[2] or Data.Color2, Colors[2])
            Colors[3] = CopyColor(Data[3] or Data.Color3, Colors[3])
            GradientPicker:Display()
        end

        PreviewOuter.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame() then
                if popup.Outer and popup.Outer.Visible then
                    GradientPicker:Hide()
                else
                    GradientPicker:Show()
                end
            end
        end)

        GradientPicker:Display()
        Groupbox:AddBlank(5)
        Options[Idx] = GradientPicker
        return GradientPicker
    end;

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self;
        local ToggleLabel = self.TextLabel;
        local Container = self.Container;

        assert(Info.Default, 'AddKeyPicker: Missing default value.');

        local KeyPicker = {
            Value = Info.Default;
            FactoryDefault = Info.Default;
            Toggled = false;
            Held = false;
            Mode = Info.Mode or 'Toggle'; -- Always, Toggle, Hold
            FactoryMode = Info.Mode or 'Toggle';
            Type = 'KeyPicker';
            Callback = Info.Callback or function(Value) end;
            ChangedCallback = Info.ChangedCallback or function(New) end;

            SyncToggleState = Info.SyncToggleState or false;
        };

        if KeyPicker.SyncToggleState then
            Info.Modes = { 'Toggle' }
            Info.Mode = 'Toggle'
            KeyPicker.Mode = 'Toggle'
            KeyPicker.FactoryMode = 'Toggle'
        end

        local PickOuter = Library:Create('Frame', {
            Active = true;
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            LayoutOrder = 1;
            Size = UDim2.new(0, Library:IsMobile() and 44 or 38, 0, Library:IsMobile() and 18 or 15);
            ZIndex = 15;
            Parent = ToggleLabel;
        });
        Library:AddCorner(PickOuter, 2);

        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickOuter;
        });
        Library:AddCorner(PickInner, 2);

        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 11;
            Text = Info.Default;
            TextWrapped = false;
            TextXAlignment = Enum.TextXAlignment.Center;
            ZIndex = 17;
            Parent = PickInner;
        });

        local ModeSelectOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
            Size = UDim2.new(0, 60, 0, 45 + 2);
            Visible = false;
            ZIndex = 50;
            Parent = ScreenGui;
        });

        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
        end);

        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 51;
            Parent = ModeSelectOuter;
        });

        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ModeSelectInner;
        });

        local ContainerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left;
            Size = UDim2.new(1, 0, 0, 18);
            TextSize = 13;
            Visible = false;
            ZIndex = 110;
            Parent = Library.KeybindContainer;
        },  true);

        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' };
        local ModeButtons = {};

        for Idx, Mode in next, Modes do
            local ModeButton = {};

            local Label = Library:CreateLabel({
                Active = true;
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = 13;
                Text = Mode;
                ZIndex = 52;
                Parent = ModeSelectInner;
            });

            function ModeButton:Select()
                for _, Button in next, ModeButtons do
                    Button:Deselect();
                end;

                KeyPicker.Mode = Mode;

                Label.TextColor3 = Library.AccentColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor';

                ModeSelectOuter.Visible = false;
            end;

            function ModeButton:Deselect()
                Label.TextColor3 = Library.FontColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor';
            end;

            Label.InputBegan:Connect(function(Input)
                if Library:IsPointerInput(Input) then
                    ModeButton:Select();
                    Library:AttemptSave();
                end;
            end);

            if Mode == KeyPicker.Mode then
                ModeButton:Select();
            end;

            ModeButtons[Mode] = ModeButton;
        end;

        function KeyPicker:Update()
            if Info.NoUI or Library.ConfigLoading then
                return;
            end;

            local State = KeyPicker:GetState();

            ContainerLabel.Text = string.format('[%s] %s (%s)', KeyPicker.Value, Info.Text, KeyPicker.Mode);

            ContainerLabel.Visible = true;
            ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor;

            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor';

            local YSize = 0
            local XSize = 0

            for _, Label in next, Library.KeybindContainer:GetChildren() do
                if Label:IsA('TextLabel') and Label.Visible then
                    YSize = YSize + 18;
                    if (Label.TextBounds.X > XSize) then
                        XSize = Label.TextBounds.X
                    end
                end;
            end;

            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10, 210), 0, YSize + 23)
            Library.KeybindFrame.Visible = Library.ShowKeybindList == true
        end;

        function KeyPicker:GetKey()
            local Key = KeyPicker.Value;
            if Key == nil or Key == '' or Key == 'None' or Key == 'NONE' or Key == 'Unknown' then
                return nil;
            end;
            return Key;
        end;

        function KeyPicker:GetState()
            local mode = KeyPicker.Mode or KeyPicker.FactoryMode;
            if mode == 'Always' then
                return true;
            elseif mode == 'Hold' then
                if KeyPicker.Value == 'None' or KeyPicker.Value == 'NONE' or KeyPicker.Value == 'Unknown' or KeyPicker.Value == '' then
                    return false;
                end

                local Key = KeyPicker.Value;
                local mouseType = nil;
                if Key == 'MB1' or Key == 'MouseButton1' or Key == 'Button1' then
                    mouseType = Enum.UserInputType.MouseButton1;
                elseif Key == 'MB2' or Key == 'MouseButton2' or Key == 'Button2' then
                    mouseType = Enum.UserInputType.MouseButton2;
                end;

                if mouseType then
                    local ok, pressed = pcall(function()
                        return InputService:IsMouseButtonPressed(mouseType);
                    end);
                    if ok and pressed then
                        return true;
                    end;
                    return KeyPicker.Held == true;
                end;

                local enumKey = Enum.KeyCode[Key];
                if enumKey then
                    local ok, down = pcall(function()
                        return InputService:IsKeyDown(enumKey);
                    end);
                    if ok and down then
                        return true;
                    end;
                end;
                return KeyPicker.Held == true;
            else
                return KeyPicker.Toggled;
            end;
        end;

        function KeyPicker:SetValue(Data)
            local Key, Mode
            if type(Data) == 'string' then
                Key = Data
            elseif type(Data) == 'table' then
                Key = Data[1] or Data.Key or Data.key or Data.Value
                Mode = Data[2] or Data.Mode or Data.mode
            end
            if type(Key) == 'string' then
                DisplayLabel.Text = Key;
                KeyPicker.Value = Key;
            end
            if type(Mode) == 'string' and ModeButtons[Mode] then
                ModeButtons[Mode]:Select();
            end
            if not Library.ConfigLoading then
                KeyPicker:Update();
            end
        end;

        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end

        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback
            if not Library:IsLayoutSuspended() and not Library.ConfigLoading then
                pcall(Callback, KeyPicker.Value)
            end
        end

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        function KeyPicker:DoClick()
            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
        end

        local Picking = false;

        PickOuter.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame() then
                if Library:IsMobile() then
                    local holding = true;
                    local changed = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            holding = false;
                        end;
                    end);
                    local started = os.clock();
                    while holding and os.clock() - started < 0.45 do
                        RenderStepped:Wait();
                    end;
                    if changed then
                        changed:Disconnect();
                    end;
                    if holding then
                        ModeSelectOuter.Visible = true;
                        return;
                    end;
                end;

                Picking = true;

                DisplayLabel.Text = '';

                local Break;
                local Text = '';

                task.spawn(function()
                    while (not Break) do
                        if Text == '...' then
                            Text = '';
                        end;

                        Text = Text .. '.';
                        DisplayLabel.Text = Text;

                        wait(0.4);
                    end;
                end);

                wait(0.2);

                local Event;
                Event = InputService.InputBegan:Connect(function(Input)
                    local Key;

                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode.Name;
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Key = 'MB1';
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Key = 'MB2';
                    elseif Input.UserInputType == Enum.UserInputType.Touch then
                        return;
                    end;

                    if not Key then
                        return;
                    end;

                    Break = true;
                    Picking = false;

                    DisplayLabel.Text = Key;
                    KeyPicker.Value = Key;

                    Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
                    Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType)

                    Library:AttemptSave();

                    Event:Disconnect();
                end);
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ModeSelectOuter.Visible = true;
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (not Picking) then
                local matches = false;
                local Key = KeyPicker.Value;
                if (Key == 'MB1' or Key == 'MouseButton1' or Key == 'Button1') and Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    matches = true;
                elseif (Key == 'MB2' or Key == 'MouseButton2' or Key == 'Button2') and Input.UserInputType == Enum.UserInputType.MouseButton2 then
                    matches = true;
                elseif Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key then
                    matches = true;
                end;

                if matches then
                    KeyPicker.Held = true;
                    if KeyPicker.Mode == 'Toggle' then
                        KeyPicker.Toggled = not KeyPicker.Toggled
                        KeyPicker:DoClick()
                    end;
                end;

                KeyPicker:Update();
            end;

            if Library:IsPointerInput(Input) then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize;
                local pointer = Library:GetPointerPosition(Input);

                if pointer.X < AbsPos.X or pointer.X > AbsPos.X + AbsSize.X
                    or pointer.Y < (AbsPos.Y - 20 - 1) or pointer.Y > AbsPos.Y + AbsSize.Y then

                    ModeSelectOuter.Visible = false;
                end;
            end;
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if (not Picking) then
                local Key = KeyPicker.Value;
                if (Key == 'MB1' or Key == 'MouseButton1' or Key == 'Button1') and Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    KeyPicker.Held = false;
                elseif (Key == 'MB2' or Key == 'MouseButton2' or Key == 'Button2') and Input.UserInputType == Enum.UserInputType.MouseButton2 then
                    KeyPicker.Held = false;
                elseif Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key then
                    KeyPicker.Held = false;
                end;
                KeyPicker:Update();
            end;
        end))

        KeyPicker:Update();

        Options[Idx] = KeyPicker;

        return self;
    end;

    Library.AddGradientPicker = Funcs.AddGradientPicker;

    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

local BaseGroupbox = {};

do
    local Funcs = {};

    function Funcs:AddBlank(Size)
        local Groupbox = self;
        local Container = Groupbox.Container;

        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            ZIndex = 1;
            Parent = Container;
        });
    end;

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {};

        local Groupbox = self;
        local Container = Groupbox.Container;

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15);
            TextSize = 13;
            Text = Text;
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            });
        end

        Label.TextLabel = TextLabel;
        Label.Container = Container;

        function Label:SetText(Text)
            TextLabel.Text = Text

            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end

            Groupbox:Resize();
        end

        if (not DoesWrap) then
            setmetatable(Label, BaseAddons);
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Label;
    end;

    function Funcs:AddButton(...)
        -- TODO: Eventually redo this
        local Button = {};
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end

            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.');
        end

        ProcessButtonParams('Button', Button, ...)

        local Groupbox = self;
        local Container = Groupbox.Container;

        local function CreateBaseButton(Button)
            local Outer = Library:Create('Frame', {
                Active = true;
                BackgroundColor3 = Library.MainColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, -4, 0, Library:IsMobile() and 26 or 22);
                ZIndex = 5;
            });

            Library:AddCorner(Outer, 4);
            local Stroke = Library:AddStroke(Outer, 'OutlineColor', 1);

            local Inner = Library:Create('Frame', {
                BackgroundTransparency = 1;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = Outer;
            });

            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = 13;
                Text = Button.Text;
                ZIndex = 6;
                Parent = Inner;
            });

            Library:AddToRegistry(Outer, {
                BackgroundColor3 = 'MainColor';
            });

            Outer.MouseEnter:Connect(function()
                Stroke.Color = Library.AccentColor;
                Stroke.Thickness = 1.4;
                Label.TextColor3 = Library.AccentColor;
            end);
            Outer.MouseLeave:Connect(function()
                Stroke.Color = Library.OutlineColor;
                Stroke.Thickness = 1;
                Label.TextColor3 = Library.FontColor;
                Outer.BackgroundColor3 = Library.MainColor;
            end);
            Outer.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Outer.BackgroundColor3 = Library.MainColor:Lerp(Library.AccentColor, 0.18);
                end;
            end);
            Outer.InputEnded:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Outer.BackgroundColor3 = Library.MainColor;
                end;
            end);

            return Outer, Inner, Label
        end

        local function InitEvents(Button)
            local function WaitForEvent(event, timeout, validator)
                local bindable = Instance.new('BindableEvent')
                local connection
                local fired = false
                local function handler(...)
                    if fired then
                        return
                    end
                    fired = true
                    if connection then
                        pcall(function()
                            connection:Disconnect()
                        end)
                    end
                    if type(validator) == 'function' and validator(...) then
                        bindable:Fire(true)
                    else
                        bindable:Fire(false)
                    end
                end
                if typeof(event.Once) == 'function' then
                    connection = event:Once(handler)
                else
                    connection = event:Connect(handler)
                end
                task.delay(timeout, function()
                    if fired then
                        return
                    end
                    fired = true
                    if connection then
                        pcall(function()
                            connection:Disconnect()
                        end)
                    end
                    bindable:Fire(false)
                end)
                return bindable.Event:Wait()
            end

            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame() then
                    return false
                end

                if not Library:IsPointerInput(Input) then
                    return false
                end

                return true
            end

            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) then return end
                if Button.Locked then return end

                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'AccentColor' })

                    Button.Label.TextColor3 = Library.AccentColor
                    Button.Label.Text = 'Are you sure?'
                    Button.Locked = true

                    local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)

                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' })

                    Button.Label.TextColor3 = Library.FontColor
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, 'Locked', false)

                    if clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    return
                end

                Library:SafeCallback(Button.Func);
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container

        InitEvents(Button)

        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then
                Library:AddToolTip(tooltip, self.Outer)
            end
            return self
        end


        function Button:AddButton(...)
            local SubButton = {}

            ProcessButtonParams('SubButton', SubButton, ...)

            self.Outer.Size = UDim2.new(0.5, -3, 0, Library:IsMobile() and 26 or 22)

            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)

            SubButton.Outer.Position = UDim2.new(1, 6, 0, 0)
            SubButton.Outer.Size = UDim2.new(1, 0, 1, 0)
            SubButton.Outer.Parent = self.Outer

            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == 'string' then
                    Library:AddToolTip(tooltip, self.Outer)
                end
                return SubButton
            end

            if type(SubButton.Tooltip) == 'string' then
                SubButton:AddTooltip(SubButton.Tooltip)
            end

            InitEvents(SubButton)
            return SubButton
        end

        if type(Button.Tooltip) == 'string' then
            Button:AddTooltip(Button.Tooltip)
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Button;
    end;

    function Funcs:AddDivider()
        local Groupbox = self;
        local Container = self.Container

        local Divider = {
            Type = 'Divider',
        }

        Groupbox:AddBlank(2);
        local DividerOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 5);
            ZIndex = 5;
            Parent = Container;
        });

        local DividerInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DividerOuter;
        });

        Library:AddToRegistry(DividerOuter, {
            BorderColor3 = 'Black';
        });

        Library:AddToRegistry(DividerInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Groupbox:AddBlank(9);
        Groupbox:Resize();
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Textbox = {
            Value = Info.Default or '';
            FactoryDefault = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type = 'Input';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15);
            TextSize = 13;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        Groupbox:AddBlank(1);

        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddCorner(TextBoxOuter, 3);

        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = TextBoxOuter;
        });
        Library:AddCorner(TextBoxInner, 3);

        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, TextBoxOuter)
        end

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = TextBoxInner;
        });

        local Container = Library:Create('Frame', {
            BackgroundTransparency = 1;
            ClipsDescendants = true;

            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);

            ZIndex = 7;
            Parent = TextBoxInner;
        })

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;

            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),

            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = Info.Placeholder or '';

            Text = Info.Default or '';
            TextColor3 = Library.FontColor;
            TextSize = 13;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;

            ZIndex = 7;
            Parent = Container;
        });

        Library:ApplyTextStroke(Box);

        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength);
            end;

            if Textbox.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then
                    Text = Textbox.Value
                end
            end

            Textbox.Value = Text;
            Box.Text = Text;

            if Library.ConfigLoading or Library:IsLayoutSuspended() then
                return;
            end;

            Library:SafeCallback(Textbox.Callback, Textbox.Value);
            Library:SafeCallback(Textbox.Changed, Textbox.Value);
        end;

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end

                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end);
        end

        -- https://devforum.roblox.com/t/how-to-make-textboxes-follow-current-cursor-position/1368429/6
        -- thank you nicemike40 :)

        local function Update()
            local PADDING = 2
            local reveal = Container.AbsoluteSize.X

            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                -- we aren't focused, or we fit so be normal
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                -- we are focused and don't fit, so adjust position
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    -- calculate pixel width of text from start to cursor
                    local subtext = string.sub(Box.Text, 1, cursor-1)
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X

                    -- check if we're inside the box with the cursor
                    local currentCursorPos = Box.Position.X.Offset + width

                    -- adjust if necessary
                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING-width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
                    end
                end
            end
        end

        if not Library:IsLayoutSuspended() then
            task.spawn(Update)
        end

        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)

        Library:AddToRegistry(Box, {
            TextColor3 = 'FontColor';
        });

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func;
            if not Library:IsLayoutSuspended() then
                pcall(Func, Textbox.Value);
            end;
        end;

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        Options[Idx] = Textbox;

        return Textbox;
    end;

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddToggle: Missing `Text` string.')

        local Toggle = {
            Value = Info.Default or false;
            FactoryDefault = not not (Info.Default or false);
            Type = 'Toggle';
            Text = Info.Text;
            Callback = Info.Callback or function(Value) end;
            Addons = {},
            Risky = Info.Risky,
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddCorner(ToggleOuter, 2);

        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = 'Black';
        });

        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter;
        });
        Library:AddCorner(ToggleInner, 2);

        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local ToggleLabel = Library:Create('Frame', {
            BackgroundTransparency = 1;
            AutomaticSize = Enum.AutomaticSize.X;
            Size = UDim2.fromOffset(0, 13);
            Position = UDim2.new(1, 6, 0, 0);
            ZIndex = 6;
            Parent = ToggleInner;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 5);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Left;
            VerticalAlignment = Enum.VerticalAlignment.Center;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        });

        local ToggleNameLabel = Library:CreateLabel({
            AutomaticSize = Enum.AutomaticSize.X;
            Size = UDim2.fromOffset(0, 13);
            TextSize = 13;
            Text = Info.Text;
            TextWrapped = false;
            TextXAlignment = Enum.TextXAlignment.Left;
            LayoutOrder = 0;
            ZIndex = 6;
            Parent = ToggleLabel;
        });

        local ToggleRegion = Library:Create('Frame', {
            Active = true;
            BackgroundTransparency = 1;
            Size = UDim2.new(0, Library:IsMobile() and 220 or 170, 1, Library:IsMobile() and 6 or 0);
            ZIndex = 8;
            Parent = ToggleOuter;
        });

        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        function Toggle:UpdateColors()
            Toggle:Display();
        end;

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, ToggleRegion)
        end

        function Toggle:Display()
            ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor;
            ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;

            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor';
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';
        end;

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func;
            if not Library:IsLayoutSuspended() then
                pcall(Func, Toggle.Value);
            end;
        end;

        function Toggle:SetValue(Bool)
            Bool = (not not Bool);

            Toggle.Value = Bool;
            Toggle:Display();

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    if not Library.ConfigLoading then
                        Addon:Update()
                    end
                end
            end

            if Library.ConfigLoading or Library:IsLayoutSuspended() then
                return;
            end;

            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed, Toggle.Value);
            Library:UpdateDependencyBoxes();
        end;

        ToggleRegion.InputBegan:Connect(function(Input)
            if not Library:IsPointerInput(Input) or Library:MouseIsOverOpenedFrame() then
                return;
            end;
            local pointer = Library:GetPointerPosition(Input);
            for _, child in ipairs(ToggleLabel:GetChildren()) do
                if child ~= ToggleNameLabel and child:IsA('GuiObject') and Library:IsPointOverFrame(child, pointer) then
                    return;
                end;
            end;
            Toggle:SetValue(not Toggle.Value)
            Library:AttemptSave();
        end);

        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleNameLabel)
            ToggleNameLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleNameLabel, { TextColor3 = 'RiskColor' })
        end

        Toggle:Display();
        Groupbox:AddBlank(Info.BlankSize or 5 + 2);
        Groupbox:Resize();

        Toggle.TextLabel = ToggleLabel;
        Toggle.Container = Container;
        setmetatable(Toggle, BaseAddons);

        Toggles[Idx] = Toggle;

        Library:UpdateDependencyBoxes();

        return Toggle;
    end;

    function Funcs:AddGradientPicker(Idx, Info)
        return Library.AddGradientPicker(self, Idx, Info);
    end

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default ~= nil, 'AddSlider: Missing default value.');
        assert(Info.Text, 'AddSlider: Missing slider text.');
        assert(Info.Min, 'AddSlider: Missing minimum value.');
        assert(Info.Max, 'AddSlider: Missing maximum value.');
        if Info.Rounding == nil then
            Info.Rounding = 0;
        end;

        local Slider = {
            Value = Info.Default;
            FactoryDefault = Info.Default;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            MaxSize = 1;
            Type = 'Slider';
            Text = Info.Text;
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 13;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });

            Groupbox:AddBlank(3);
        end

        local SliderOuter = Library:Create('Frame', {
            Active = true;
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, Library:IsMobile() and 18 or 13);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddCorner(SliderOuter, 3);

        Library:AddToRegistry(SliderOuter, {
            BorderColor3 = 'Black';
        });

        local SliderInner = Library:Create('Frame', {
            Active = true;
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = SliderOuter;
        });
        Library:AddCorner(SliderInner, 3);

        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderColor3 = Library.AccentColorDark;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderInner;
        });
        Library:AddCorner(Fill, 2);

        Library:AddToRegistry(Fill, {
            BackgroundColor3 = 'AccentColor';
            BorderColor3 = 'AccentColorDark';
        });

        local HideBorderRight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, 1, 1, 0);
            ZIndex = 8;
            Parent = Fill;
        });

        Library:AddToRegistry(HideBorderRight, {
            BackgroundColor3 = 'AccentColor';
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 13;
            Text = 'Infinite';
            ZIndex = 9;
            Parent = SliderInner;
        });

        Library:OnHighlight(SliderOuter, SliderOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, SliderOuter)
        end

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor;
            Fill.BorderColor3 = Library.AccentColorDark;
        end;

        function Slider:RefreshMaxSize()
            Slider.MaxSize = math.max(1, math.floor(SliderInner.AbsoluteSize.X + 0.5));
        end;

        function Slider:Display()
            Slider:RefreshMaxSize();
            local Suffix = Info.Suffix or '';
            local clamped = math.clamp(Slider.Value, Slider.Min, Slider.Max);
            Slider.Value = clamped;

            if Info.Compact then
                DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix
            elseif Info.HideMax then
                DisplayLabel.Text = string.format('%s', Slider.Value .. Suffix)
            else
                DisplayLabel.Text = string.format('%s/%s', Slider.Value .. Suffix, Slider.Max .. Suffix);
            end

            local span = Slider.Max - Slider.Min;
            local alpha = span == 0 and 1 or ((Slider.Value - Slider.Min) / span);
            local X = math.floor(math.clamp(alpha, 0, 1) * Slider.MaxSize + 0.5);
            Fill.Size = UDim2.new(0, X, 1, 0);

            HideBorderRight.Visible = not (X >= Slider.MaxSize or X == 0);
        end;

        function Slider:OnChanged(Func)
            Slider.Changed = Func;
            if not Library:IsLayoutSuspended() then
                pcall(Func, Slider.Value);
            end;
        end;
        function Slider:OnReleased(Func)
            Slider.Released = Func;
            Slider.OnChanged(Slider, Func);
        end;

        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value);
            end;


            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
        end;

        function Slider:GetValueFromXOffset(X)
            Slider:RefreshMaxSize();
            return Round(Library:MapValue(math.clamp(X, 0, Slider.MaxSize), 0, Slider.MaxSize, Slider.Min, Slider.Max));
        end;

        function Slider:SetValue(Str)
            local Num = tonumber(Str);

            if (not Num) then
                return;
            end;

            Num = math.clamp(Num, Slider.Min, Slider.Max);

            Slider.Value = Num;
            if not Library.ConfigLoading then
                Slider:Display();
            end

            if Library.ConfigLoading or Library:IsLayoutSuspended() then
                return;
            end;

            Library:SafeCallback(Slider.Callback, Slider.Value);
            Library:SafeCallback(Slider.Changed, Slider.Value);
        end;

        SliderInner.InputBegan:Connect(function(Input)
            if Library:MouseIsOverOpenedFrame() then
                return;
            end;

            Library:RunWhilePointerHeld(Input, function(pointer)
                Slider:RefreshMaxSize();
                local nX = math.clamp(pointer.X - SliderInner.AbsolutePosition.X, 0, Slider.MaxSize);
                local nValue = Slider:GetValueFromXOffset(nX);
                local OldValue = Slider.Value;
                Slider.Value = math.clamp(nValue, Slider.Min, Slider.Max);
                Slider:Display();

                if Slider.Value ~= OldValue then
                    Library:SafeCallback(Slider.Callback, Slider.Value);
                    Library:SafeCallback(Slider.Changed, Slider.Value);
                end;
            end);

            if Library:IsPointerInput(Input) then
                Library:AttemptSave();
            end;
        end);

        SliderInner:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
            Slider:Display();
        end);

        Slider:Display();
        Groupbox:AddBlank(Info.BlankSize or 6);
        Groupbox:Resize();

        Options[Idx] = Slider;

        return Slider;
    end;

    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then
            Info.Values = GetPlayersString();
            Info.AllowNull = true;
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString();
            Info.AllowNull = true;
        end;

        if type(Info.Values) ~= 'table' then
            Info.Values = {};
        end;
        if Info.Default == nil and Info.AllowNull ~= true then
            if type(Info.Values) == 'table' and Info.Values[1] ~= nil and not Info.Multi then
                Info.Default = Info.Values[1];
            else
                Info.AllowNull = true;
            end
        end
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')

        if (not Info.Text) then
            Info.Compact = true;
        end;

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            Multi = Info.Multi;
            Type = 'Dropdown';
            Text = Info.Text;
            SpecialType = Info.SpecialType; -- can be either 'Player' or 'Team'
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local RelativeOffset = 0;

        if not Info.Compact then
            local DropdownLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 13;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });

            Groupbox:AddBlank(3);
        end

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
            end;
        end;

        local DropdownRowHeight = Library:IsMobile() and 24 or 20;

        local DropdownHolder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, -4, 0, DropdownRowHeight);
            ZIndex = 5;
            Parent = Container;
        });

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = DropdownHolder;
        });

        local DropdownOuter = Library:Create('Frame', {
            Active = true;
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            LayoutOrder = 1;
            Size = UDim2.new(1, 0, 0, DropdownRowHeight);
            ZIndex = 5;
            Parent = DropdownHolder;
        });
        Library:AddCorner(DropdownOuter, 3);

        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = 'Black';
        });

        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter;
        });
        Library:AddCorner(DropdownInner, 3);

        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = DropdownInner;
        });

        local DropdownArrow = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = 'http://www.roblox.com/asset/?id=6282522798';
            ZIndex = 8;
            Parent = DropdownInner;
        });

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            TextSize = 13;
            Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true;
            ZIndex = 7;
            Parent = DropdownInner;
        });

        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, DropdownOuter)
        end

        local MAX_DROPDOWN_ITEMS = 8;

        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            LayoutOrder = 2;
            Size = UDim2.new(1, 0, 0, 0);
            ZIndex = 20;
            Visible = false;
            Parent = DropdownHolder;
        });

        local function RecalculateListSize(YSize)
            local ListHeight = 0;
            if ListOuter.Visible then
                ListHeight = YSize or (MAX_DROPDOWN_ITEMS * 20 + 2);
            end;
            ListOuter.Size = UDim2.new(1, 0, 0, ListHeight);
            DropdownHolder.Size = UDim2.new(1, -4, 0, DropdownRowHeight + ListHeight);
            if Groupbox.Resize then
                Groupbox:Resize();
            end;
        end;

        RecalculateListSize(0);

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        });

        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListInner;

            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        });

        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = 'AccentColor'
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        });

        function Dropdown:Display()
            local Values = Dropdown.Values;
            local Str = '';

            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. Value .. ', ';
                    end;
                end;

                Str = Str:sub(1, #Str - 2);
            else
                Str = Dropdown.Value or '';
            end;

            ItemList.Text = (Str == '' and '--' or Str);
        end;

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {};

                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value);
                end;

                return T;
            else
                return Dropdown.Value and 1 or 0;
            end;
        end;

        local DropdownListBuilt = false;

        function Dropdown:BuildDropdownList()
            DropdownListBuilt = true;
            local Values = Dropdown.Values;
            local Buttons = {};

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then
                    Element:Destroy();
                end;
            end;

            local Count = 0;

            for Idx, Value in next, Values do
                local Table = {};

                Count = Count + 1;

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    Size = UDim2.new(1, -1, 0, 20);
                    ZIndex = 23;
                    Active = true,
                    Parent = Scrolling;
                });

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                    BorderColor3 = 'OutlineColor';
                });

                local ButtonLabel = Library:CreateLabel({
                    Active = true;
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = 13;
                    Text = Value;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 25;
                    Parent = Button;
                });

                Library:OnHighlight(Button, Button,
                    { BorderColor3 = 'AccentColor', ZIndex = 24 },
                    { BorderColor3 = 'OutlineColor', ZIndex = 23 }
                );

                local Selected;

                if Info.Multi then
                    Selected = Dropdown.Value[Value];
                else
                    Selected = Dropdown.Value == Value;
                end;

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value];
                    else
                        Selected = Dropdown.Value == Value;
                    end;

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
                end;

                Button.InputBegan:Connect(function(Input)
                    if Library:IsPointerInput(Input) then
                        local Try = not Selected;

                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value[Value] = true;
                                else
                                    Dropdown.Value[Value] = nil;
                                end;
                            else
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value = Value;
                                else
                                    Dropdown.Value = nil;
                                end;

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton();
                                end;
                            end;

                            Table:UpdateButton();
                            Dropdown:Display();

                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);

                            Library:AttemptSave();
                            if not Dropdown.Multi then
                                Dropdown:CloseDropdown();
                            end;
                        end;
                    end;
                end);

                Table:UpdateButton();
                Buttons[Button] = Table;
            end;

            Dropdown:Display();

            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1);

            local Y = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1;
            RecalculateListSize(Y);
        end;

        function Dropdown:EnsureDropdownList()
            if DropdownListBuilt then
                return;
            end;
            DropdownListBuilt = true;
            Dropdown:BuildDropdownList();
        end;

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues;
            end;

            if DropdownListBuilt or ListOuter.Visible then
                DropdownListBuilt = true;
                Dropdown:BuildDropdownList();
            else
                Dropdown:Display();
            end;
        end;

        function Dropdown:OpenDropdown()
            Dropdown:EnsureDropdownList();
            Library:CloseAllDropdowns(Dropdown);

            local Count = 0;
            for _, Value in next, Dropdown.Values do
                if Value ~= nil then
                    Count = Count + 1;
                end;
            end;
            local ListHeight = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 2;
            local OpenUpward = false;
            local Camera = workspace.CurrentCamera;
            if Camera then
                local DropdownBottom = DropdownOuter.AbsolutePosition.Y + DropdownOuter.AbsoluteSize.Y;
                local SpaceBelow = Camera.ViewportSize.Y - DropdownBottom - 24;
                local SpaceAbove = DropdownOuter.AbsolutePosition.Y - 24;
                OpenUpward = ListHeight > SpaceBelow and SpaceAbove > SpaceBelow;
            end;
            if OpenUpward then
                ListOuter.LayoutOrder = 0;
                DropdownOuter.LayoutOrder = 1;
            else
                DropdownOuter.LayoutOrder = 0;
                ListOuter.LayoutOrder = 1;
            end;

            ListOuter.Visible = true;
            Library.OpenedFrames[ListOuter] = true;
            DropdownArrow.Rotation = OpenUpward and 0 or 180;
            RecalculateListSize(ListHeight);
        end;

        function Dropdown:CloseDropdown()
            ListOuter.Visible = false;
            Library.OpenedFrames[ListOuter] = nil;
            DropdownArrow.Rotation = 0;
            DropdownOuter.LayoutOrder = 0;
            ListOuter.LayoutOrder = 1;
            RecalculateListSize(0);
        end;

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func;
            if not Library:IsLayoutSuspended() then
                pcall(Func, Dropdown.Value);
            end;
        end;

        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {};

                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then
                        nTable[Value] = true
                    end;
                end;

                Dropdown.Value = nTable;
            else
                if (not Val) then
                    Dropdown.Value = nil;
                elseif table.find(Dropdown.Values, Val) then
                    Dropdown.Value = Val;
                end;
            end;

            if DropdownListBuilt and not Library.ConfigLoading then
                Dropdown:BuildDropdownList();
            else
                Dropdown:Display();
            end;

            if Library.ConfigLoading or Library:IsLayoutSuspended() then
                return;
            end;

            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
        end;

        DropdownOuter.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown();
                else
                    Dropdown:OpenDropdown();
                end;
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if not Library:IsPointerInput(Input) then
                return;
            end;
            if not ListOuter.Visible then
                return;
            end;
            if Library:IsMouseOverFrame(DropdownHolder) then
                return;
            end;
            Dropdown:CloseDropdown();
        end));

        Dropdown:Display();

        local Defaults = {}

        if type(Info.Default) == 'string' then
            local Idx = table.find(Dropdown.Values, Info.Default)
            if Idx then
                table.insert(Defaults, Idx)
            end
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local Idx = table.find(Dropdown.Values, Value)
                if Idx then
                    table.insert(Defaults, Idx)
                end
            end
        elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index];
                end

                if (not Info.Multi) then break end
            end

            Dropdown:Display();
        end

        if Info.Multi then
            local copied = {};
            if type(Dropdown.Value) == 'table' then
                for key, value in next, Dropdown.Value do
                    copied[key] = value;
                end;
            end;
            Dropdown.FactoryDefault = copied;
        else
            Dropdown.FactoryDefault = Dropdown.Value;
        end;

        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();

        table.insert(Library.Dropdowns, Dropdown);
        Options[Idx] = Dropdown;

        return Dropdown;
    end;

    function Funcs:AddDependencyBox()
        local Depbox = {
            Dependencies = {};
        };
        
        local Groupbox = self;
        local Container = Groupbox.Container;

        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            Parent = Container;
        });

        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            Parent = Holder;
        });

        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Frame;
        });

        function Depbox:Resize()
            if Library:IsLayoutSuspended() then
                Library.PendingResizes[Groupbox] = true;
                return;
            end;
            if Library._BulkLayout then
                Library.PendingResizes[Groupbox] = true;
                return;
            end;
            if Depbox._Resizing then
                return;
            end;
            Depbox._Resizing = true;
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y);
            Groupbox:Resize();
            Depbox._Resizing = false;
        end;

        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            if Library:IsLayoutSuspended() or Library._BulkLayout then
                Library.PendingResizes[Groupbox] = true;
                return;
            end;
            Depbox:Resize();
        end);

        Holder:GetPropertyChangedSignal('Visible'):Connect(function()
            if Library:IsLayoutSuspended() or Library._BulkLayout then
                Library.PendingResizes[Groupbox] = true;
                return;
            end;
            Depbox:Resize();
        end);

        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1];
                local Value = Dependency[2];

                if Elem.Type == 'Toggle' and Elem.Value ~= Value then
                    Holder.Visible = false;
                    Depbox:Resize();
                    return;
                end;
            end;

            Holder.Visible = true;
            Depbox:Resize();
        end;

        function Depbox:SetupDependencies(Dependencies)
            local cleaned = {};
            for _, Dependency in next, Dependencies or {} do
                if type(Dependency) == 'table' and Dependency[1] ~= nil and Dependency[2] ~= nil then
                    table.insert(cleaned, Dependency);
                end;
            end;

            Depbox.Dependencies = cleaned;
            Depbox:Update();
        end;

        Depbox.Container = Frame;

        setmetatable(Depbox, BaseGroupbox);

        table.insert(Library.DependencyBoxes, Depbox);

        return Depbox;
    end;

    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

-- < Create other UI elements >
do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 0, 40);
        Size = UDim2.new(0, 300, 0, 200);
        ZIndex = 100;
        Parent = ScreenGui;
    });

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.NotificationArea;
    });

    local WatermarkOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, -25);
        Size = UDim2.new(0, 213, 0, 20);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    });

    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = WatermarkOuter;
    });

    Library:AddToRegistry(WatermarkInner, {
        BorderColor3 = 'AccentColor';
    });

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 202;
        Parent = WatermarkInner;
    });

    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });

    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });

    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 5, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        TextSize = 13;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 203;
        Parent = InnerFrame;
    });

    Library.Watermark = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;
    Library:MakeDraggable(Library.Watermark);



    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 10, 0.5, 0);
        Size = UDim2.new(0, 210, 0, 20);
        Visible = false;
        ZIndex = 100;
        Parent = ScreenGui;
    });

    local KeybindInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = KeybindOuter;
    });

    Library:AddToRegistry(KeybindInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);

    local ColorFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 102;
        Parent = KeybindInner;
    });

    Library:AddToRegistry(ColorFrame, {
        BackgroundColor3 = 'AccentColor';
    }, true);

    local KeybindLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20);
        Position = UDim2.fromOffset(5, 2),
        TextXAlignment = Enum.TextXAlignment.Left,

        Text = 'Keybinds';
        ZIndex = 104;
        Parent = KeybindInner;
    });

    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -20);
        Position = UDim2.new(0, 0, 0, 20);
        ZIndex = 1;
        Parent = KeybindInner;
    });

    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    });

    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        Parent = KeybindContainer,
    })

    Library.KeybindFrame = KeybindOuter;
    Library.KeybindContainer = KeybindContainer;
    Library:MakeDraggable(KeybindOuter);
end;

function Library:SetWatermarkVisibility(Bool)
    Library.Watermark.Visible = Bool;
end;

function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, 14);
    Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3);
    Library:SetWatermarkVisibility(true)

    Library.WatermarkText.Text = Text;
end;

function Library:Notify(Text, Time)
    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 14);

    YSize = YSize + 7

    local NotifyOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, 10);
        Size = UDim2.new(0, 0, 0, YSize);
        ClipsDescendants = true;
        ZIndex = 100;
        Parent = Library.NotificationArea;
    });

    local NotifyInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = NotifyOuter;
    });

    Library:AddToRegistry(NotifyInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 102;
        Parent = NotifyInner;
    });

    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });

    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });

    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, 4, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        Text = Text;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextSize = 13;
        ZIndex = 103;
        Parent = InnerFrame;
    });

    local LeftColor = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, -1, 0, -1);
        Size = UDim2.new(0, 3, 1, 2);
        ZIndex = 104;
        Parent = NotifyOuter;
    });

    Library:AddToRegistry(LeftColor, {
        BackgroundColor3 = 'AccentColor';
    }, true);

    pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize + 8 + 4, 0, YSize), 'Out', 'Quad', 0.4, true);

    task.spawn(function()
        wait(Time or 5);

        pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), 'Out', 'Quad', 0.4, true);

        wait(0.4);

        NotifyOuter:Destroy();
    end);
end;

function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }

    if type(...) == 'table' then
        Config = ...;
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false;
    end

    if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 4 end
    if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end

    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
    if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(700, 520) end

    if Library:IsMobile() then
        Config.Size = Library:GetMobileWindowSize();
        Config.Center = true;
    end

    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position = UDim2.fromScale(0.5, 0.5)
    end

    local Window = {
        Tabs = {};
        TabButtons = {};
    };

    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Color3.fromRGB(6, 5, 10);
        BorderSizePixel = 0;
        Position = Config.Position,
        Size = Config.Size,
        Visible = false;
        ZIndex = 1;
        Parent = ScreenGui;
    });
    Library:AddCorner(Outer, 6);
    Library:AddStroke(Outer, 'OutlineColor', 1);

    -- Soft outer glow (rendered behind the window body, cheap single frame).
    local WindowGlow = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0.5, 0.5);
        BackgroundColor3 = Library.AccentColor;
        BackgroundTransparency = 0.9;
        BorderSizePixel = 0;
        Position = UDim2.new(0.5, 0, 0.5, 0);
        Size = UDim2.new(1, 16, 1, 16);
        ZIndex = 0;
        Parent = Outer;
    });
    Library:AddCorner(WindowGlow, 10);
    Library:AddToRegistry(WindowGlow, {
        BackgroundColor3 = 'AccentColor';
    });

    Library:MakeDraggable(Outer, 32);

    if Library:IsMobile() then
        local camera = workspace.CurrentCamera;
        if camera then
            Library:GiveSignal(camera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                Outer.Size = Library:GetMobileWindowSize();
                Library:ClampGuiToViewport(Outer);
            end));
        end;
    end

    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 2, 0, 2);
        Size = UDim2.new(1, -4, 1, -4);
        ZIndex = 1;
        Parent = Outer;
    });
    Library:AddCorner(Inner, 5);

    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'MainColor';
    });

    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 14, 0, 0);
        Size = UDim2.new(1, -28, 0, 26);
        Text = Config.Title or '';
        TextSize = 16;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 1;
        Parent = Inner;
    });
    do
        local titleGlow = WindowLabel:FindFirstChild('YunoTextGlow');
        if titleGlow then
            titleGlow.Transparency = 0.42;
        end;
        WindowLabel.TextStrokeTransparency = 0.34;
    end;

    local MainSectionOuter = Library:Create('Frame', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 10, 0, 32);
        Size = UDim2.new(1, -20, 1, -42);
        ZIndex = 1;
        Parent = Inner;
    });

    local MainSectionInner = Library:Create('Frame', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = MainSectionOuter;
    });

    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 0, 36);
        ClipsDescendants = false;
        ZIndex = 1;
        Parent = MainSectionInner;
    });

    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, 6);
        FillDirection = Enum.FillDirection.Horizontal;
        HorizontalAlignment = Enum.HorizontalAlignment.Left;
        VerticalAlignment = Enum.VerticalAlignment.Center;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = TabArea;
    });

    local TAB_BUTTON_HEIGHT = 30;
    local TAB_TEXT_PAD = 12;
    local relayoutScheduled = false;

    local function RelayoutWindowTabs()
        if Library:IsLayoutSuspended() then
            return;
        end;
        if relayoutScheduled then
            return;
        end;
        relayoutScheduled = true;
        task.defer(function()
            relayoutScheduled = false;
            local entries = Window.TabButtons;
            local count = #entries;
            if count == 0 then
                return;
            end;

            local padding = 6;
            TabListLayout.Padding = UDim.new(0, padding);
            local totalPad = padding * math.max(count - 1, 0);
            local shrink = math.floor(totalPad / count);
            local leftover = totalPad - (shrink * count);
            local textSize = (count >= 11) and 11 or 12;
            for index, entry in ipairs(entries) do
                local extra = (index <= leftover) and 1 or 0;
                entry.Button.Size = UDim2.new(1 / count, -(shrink + extra), 0, TAB_BUTTON_HEIGHT);
                entry.Label.TextSize = textSize;
                entry.Label.TextTruncate = Enum.TextTruncate.AtEnd;
            end;
        end);
    end;

    Window.RelayoutTabs = RelayoutWindowTabs;

    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0, 42);
        Size = UDim2.new(1, 0, 1, -42);
        ZIndex = 2;
        Parent = MainSectionInner;
    });
    Library:AddCorner(TabContainer, 5);
    Library:AddStroke(TabContainer, 'OutlineColor', 1);

    TabArea:GetPropertyChangedSignal('AbsoluteSize'):Connect(RelayoutWindowTabs);
    

    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = 'BackgroundColor';
    });

    function Window:SetWindowTitle(Title)
        WindowLabel.Text = Title;
    end;

    function Window:AddTab(Name)
        if Window.Tabs[Name] then
            return Window.Tabs[Name];
        end;

        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
        };

        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 13);

        local TabButton = Library:Create('Frame', {
            Active = true;
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel = 0;
            Size = UDim2.fromOffset(TabButtonWidth + TAB_TEXT_PAD, TAB_BUTTON_HEIGHT);
            LayoutOrder = #Window.TabButtons + 1;
            ZIndex = 1;
            Parent = TabArea;
        });
        Library:AddCorner(TabButton, 4);
        local TabStroke = Library:AddStroke(TabButton, 'OutlineColor', 1);

        Library:AddToRegistry(TabButton, {
            BackgroundColor3 = 'MainColor';
        });

        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Text = Name;
            TextSize = 12;
            TextXAlignment = Enum.TextXAlignment.Center;
            TextTruncate = Enum.TextTruncate.AtEnd;
            ZIndex = 1;
            Parent = TabButton;
        });

        local LabelGlow = TabButtonLabel:FindFirstChild('YunoTextGlow');

        local TabFrame = Library:Create('Frame', {
            Name = 'TabFrame',
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
        });

        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 12, 0, 12);
            Size = UDim2.new(0.5, -18, 1, -24);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });

        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 6, 0, 12);
            Size = UDim2.new(0.5, -18, 1, -24);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = LeftSide;
        });
        Library:Create('UIPadding', {
            PaddingTop = UDim.new(0, 2);
            PaddingBottom = UDim.new(0, 8);
            Parent = LeftSide;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = RightSide;
        });
        Library:Create('UIPadding', {
            PaddingTop = UDim.new(0, 2);
            PaddingBottom = UDim.new(0, 8);
            Parent = RightSide;
        });

        for _, Side in next, { LeftSide, RightSide } do
            local layout = Side:FindFirstChild('UIListLayout') or Side:WaitForChild('UIListLayout', 0.5)
            if layout then
                layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                    if Library:IsLayoutSuspended() or Library._BulkLayout then
                        return;
                    end;
                    Side.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y);
                end);
            end;
        end;

        function Tab:ShowTab()
            for _, OtherTab in next, Window.Tabs do
                if OtherTab ~= Tab then
                    OtherTab:HideTab();
                end;
            end;

            TabButton.BackgroundColor3 = Library.MainColor:Lerp(Library.AccentColor, 0.24);
            TabButtonLabel.TextColor3 = Library.FontColor;
            TabButtonLabel.TextStrokeTransparency = 0.34;
            if LabelGlow then
                LabelGlow.Transparency = 0.42;
            end;
            TabStroke.Color = Library.AccentColor;
            TabStroke.Thickness = 1;
            TabStroke.Transparency = 0.15;
            local registry = Library.RegistryMap[TabButton];
            if registry and registry.Properties then
                registry.Properties.BackgroundColor3 = 'MainColor';
            end;
            local strokeReg = Library.RegistryMap[TabStroke];
            if strokeReg and strokeReg.Properties then
                strokeReg.Properties.Color = 'AccentColor';
            end;
            if TabFrame.Parent ~= TabContainer then
                TabFrame.Parent = TabContainer;
                task.defer(function()
                    for _, Side in next, { LeftSide, RightSide } do
                        local layout = Side:FindFirstChild('UIListLayout');
                        if layout then
                            Side.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y);
                        end;
                    end;
                end);
            end;
            TabFrame.Visible = true;
            Window._PendingDefaultTab = nil;
        end;

        function Tab:HideTab()
            Library:CloseAllPopups();
            TabButton.BackgroundColor3 = Library.MainColor;
            TabButtonLabel.TextColor3 = Library.FontColor:Lerp(Library.BackgroundColor, 0.35);
            TabButtonLabel.TextStrokeTransparency = 0.5;
            if LabelGlow then
                LabelGlow.Transparency = 0.72;
            end;
            TabStroke.Color = Library.OutlineColor;
            TabStroke.Thickness = 1;
            TabStroke.Transparency = 0;
            local registry = Library.RegistryMap[TabButton];
            if registry and registry.Properties then
                registry.Properties.BackgroundColor3 = 'MainColor';
            end;
            local strokeReg = Library.RegistryMap[TabStroke];
            if strokeReg and strokeReg.Properties then
                strokeReg.Properties.Color = 'OutlineColor';
            end;
            TabFrame.Visible = false;
        end;

        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position;
            task.defer(RelayoutWindowTabs);
        end;

        function Tab:AddGroupbox(Info)
            local Groupbox = {};

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 507 + 2);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });
            Library:AddCorner(BoxOuter, 5);
            Library:AddStroke(BoxOuter, 'OutlineColor', 1);

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'MainColor';
            });

            local BoxInner = Library:Create('Frame', {
                BackgroundTransparency = 1;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 1, 0);
                Position = UDim2.new(0, 0, 0, 0);
                ZIndex = 4;
                Parent = BoxOuter;
            });

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Position = UDim2.new(0, 10, 0, 8);
                Size = UDim2.new(0, 3, 0, 12);
                ZIndex = 5;
                Parent = BoxInner;
            });
            Library:AddCorner(Highlight, 2);

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor';
            });

            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, -28, 0, 18);
                Position = UDim2.new(0, 18, 0, 5);
                TextSize = 13;
                Text = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 5;
                Parent = BoxInner;
            });
            do
                local headerGlow = GroupboxLabel:FindFirstChild('YunoTextGlow');
                if headerGlow then
                    headerGlow.Transparency = 0.55;
                end;
                GroupboxLabel.TextStrokeTransparency = 0.4;
            end;

            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 10, 0, 26);
                Size = UDim2.new(1, -20, 1, -34);
                ZIndex = 1;
                Parent = BoxInner;
            });

            local ContainerLayout = Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container;
            });

            function Groupbox:Resize()
                if Library:IsLayoutSuspended() then
                    Library.PendingResizes[Groupbox] = true;
                    return;
                end;

                local Size = 0;
                local visibleCount = 0;

                for _, Element in next, Groupbox.Container:GetChildren() do
                    if Element:IsA('GuiObject') and Element.Visible then
                        Size = Size + Element.Size.Y.Offset;
                        visibleCount = visibleCount + 1;
                    end;
                end;

                local pad = ContainerLayout.Padding.Offset;
                if visibleCount > 1 then
                    Size = Size + pad * (visibleCount - 1);
                end;

                -- Header is 26px (label row) + content + 10px bottom breathing room.
                BoxOuter.Size = UDim2.new(1, 0, 0, 26 + Size + 10);
            end;

            Groupbox.Container = Container;
            setmetatable(Groupbox, BaseGroupbox);

            Groupbox:AddBlank(4);
            Groupbox:Resize();

            Tab.Groupboxes[Info.Name] = Groupbox;

            return Groupbox;
        end;

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1; Name = Name; });
        end;

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2; Name = Name; });
        end;

        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {};
            };

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });
            Library:AddCorner(BoxOuter, 5);
            Library:AddStroke(BoxOuter, 'OutlineColor', 1);

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'MainColor';
            });

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                -- BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 10;
                Parent = BoxInner;
            });

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor';
            });

            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 1);
                Size = UDim2.new(1, 0, 0, 18);
                ZIndex = 5;
                Parent = BoxInner;
            });

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TabboxButtons;
            });

            function Tabbox:AddTab(Name)
                local Tab = {};

                local Button = Library:Create('Frame', {
                    Active = true;
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    Size = UDim2.new(0.5, 0, 1, 0);
                    ZIndex = 6;
                    Parent = TabboxButtons;
                });

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                });

                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = 13;
                    Text = Name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = Button;
                });

                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(1, 0, 0, 1);
                    Visible = false;
                    ZIndex = 9;
                    Parent = Button;
                });

                Library:AddToRegistry(Block, {
                    BackgroundColor3 = 'BackgroundColor';
                });

                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 4, 0, 20);
                    Size = UDim2.new(1, -4, 1, -20);
                    ZIndex = 1;
                    Visible = false;
                    Parent = BoxInner;
                });

                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                });

                function Tab:Show()
                    for _, Tab in next, Tabbox.Tabs do
                        Tab:Hide();
                    end;

                    Container.Visible = true;
                    Block.Visible = true;

                    Button.BackgroundColor3 = Library.BackgroundColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';

                    Tab:Resize();
                end;

                function Tab:Hide()
                    Container.Visible = false;
                    Block.Visible = false;

                    Button.BackgroundColor3 = Library.MainColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
                end;

                function Tab:Resize()
                    local TabCount = 0;

                    for _, Tab in next, Tabbox.Tabs do
                        TabCount = TabCount + 1;
                    end;

                    for _, Button in next, TabboxButtons:GetChildren() do
                        if not Button:IsA('UIListLayout') then
                            Button.Size = UDim2.new(1 / TabCount, 0, 1, 0);
                        end;
                    end;

                    if (not Container.Visible) then
                        return;
                    end;

                    local Size = 0;

                    for _, Element in next, Tab.Container:GetChildren() do
                        if (not Element:IsA('UIListLayout')) and Element.Visible then
                            Size = Size + Element.Size.Y.Offset;
                        end;
                    end;

                    BoxOuter.Size = UDim2.new(1, 0, 0, 24 + Size + 10);
                end;

                Button.InputBegan:Connect(function(Input)
                    if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show();
                        Tab:Resize();
                    end;
                end);

                Tab.Container = Container;
                Tabbox.Tabs[Name] = Tab;

                setmetatable(Tab, BaseGroupbox);

                Tab:AddBlank(3);
                Tab:Resize();

                -- Show first tab (number is 2 cus of the UIListLayout that also sits in that instance)
                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show();
                end;

                return Tab;
            end;

            Tab.Tabboxes[Info.Name or ''] = Tabbox;

            return Tabbox;
        end;

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1; });
        end;

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2; });
        end;

        TabButton.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) then
                Tab:ShowTab();
            end;
        end);

        TabButton.MouseEnter:Connect(function()
            if not TabFrame.Visible then
                TabButton.BackgroundColor3 = Library.MainColor:Lerp(Library.AccentColor, 0.12);
                TabButtonLabel.TextColor3 = Library.FontColor;
            end;
        end);
        TabButton.MouseLeave:Connect(function()
            if not TabFrame.Visible then
                TabButton.BackgroundColor3 = Library.MainColor;
                TabButtonLabel.TextColor3 = Library.FontColor:Lerp(Library.BackgroundColor, 0.35);
            end;
        end);

        -- Remember the first tab, but do not parent it until the menu is opened.
        if Window._PendingDefaultTab == nil then
            Window._PendingDefaultTab = Tab;
        end;

        Window.Tabs[Name] = Tab;
        table.insert(Window.TabButtons, {
            Name = Name;
            Button = TabButton;
            Label = TabButtonLabel;
        });
        task.defer(RelayoutWindowTabs);
        return Tab;
    end;

    function Window:SelectTab(Name)
        local Tab = Window.Tabs[Name];
        if Tab and type(Tab.ShowTab) == 'function' then
            Tab:ShowTab();
        end;
    end;

    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = ScreenGui;
    });

    local Toggled = false;
    Library.Toggled = false;

    function Library:Toggle()
        local layoutBusy = Library:IsLayoutSuspended() or Library._BulkLayout or Library._ResumeLayoutRunning;
        if (not Toggled) and layoutBusy then
            Library._OpenWhenReady = true;
            return;
        end;
        Toggled = (not Toggled);
        Library.Toggled = Toggled;
        ModalElement.Modal = Toggled;
        if Toggled then
            local pending = Window._PendingDefaultTab;
            if pending and type(pending.ShowTab) == 'function' then
                Window._PendingDefaultTab = nil;
                pending:ShowTab();
            end;
            Outer.Visible = true;
            Library:EnsureMenuCursor();
        else
            Outer.Visible = false;
            Library:CloseAllPopups();
        end;
        Library:SetMenuCursorVisible(Toggled);
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
            task.spawn(Library.Toggle)
        end
    end))

    if Config.AutoShow then task.spawn(Library.Toggle) end

    Window.Holder = Outer;
    Library.Window = Window;

    return Window;
end;

local function OnPlayerChange()
    local PlayerList = GetPlayersString();

    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList);
        end;
    end;
end;

Players.PlayerAdded:Connect(OnPlayerChange);
Players.PlayerRemoving:Connect(OnPlayerChange);

Library.Toggles = Toggles;
Library.Options = Options;
Library.Accent = Library.AccentColor;

getgenv().Library = Library
return Library
