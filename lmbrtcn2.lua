-- ╔══════════════════════════════════════════════════╗
-- ║          LT2 MENU  •  Mobile/PC Hybrid UI        ║
-- ║    Draggable • Minimizable • Touch-Friendly      ║
-- ╚══════════════════════════════════════════════════╝

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInput     = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local HttpService   = game:GetService("HttpService")
local Workspace     = game:GetService("Workspace")
local lp            = Players.LocalPlayer
local mouse         = lp:GetMouse()
local char          = lp.Character or lp.CharacterAdded:Wait()
local hum           = char:WaitForChild("Humanoid")
local hrp           = char:WaitForChild("HumanoidRootPart")

-- ═══════════════ THEME ═══════════════
local T = {
    BG        = Color3.fromRGB(10,  13,  18),
    Panel     = Color3.fromRGB(14,  18,  26),
    Card      = Color3.fromRGB(20,  26,  36),
    CardHov   = Color3.fromRGB(25,  33,  46),
    Border    = Color3.fromRGB(38,  50,  70),
    Accent    = Color3.fromRGB(74,  222, 128),   -- green
    Accent2   = Color3.fromRGB(34,  211, 238),   -- cyan
    AccentW   = Color3.fromRGB(249, 158, 11),    -- amber
    Red       = Color3.fromRGB(248, 113, 113),
    Text      = Color3.fromRGB(220, 230, 245),
    TextDim   = Color3.fromRGB(110, 130, 160),
    TextMute  = Color3.fromRGB(60,  75,  100),
    Toggle_ON = Color3.fromRGB(74,  222, 128),
    Toggle_OFF= Color3.fromRGB(38,  50,  70),
    SliderFG  = Color3.fromRGB(74,  222, 128),
    SliderBG  = Color3.fromRGB(22,  30,  44),
    Black     = Color3.fromRGB(0,0,0),
    White     = Color3.fromRGB(255,255,255),
}

-- ═══════════════ STATE ═══════════════
local State = {
    ActiveTab     = 1,
    Minimized     = false,
    Flying        = false,
    FlySpeed      = 50,
    WalkSpeed     = 16,
    SprintSpeed   = 24,
    JumpPower     = 50,
    FlyKeyBind    = "F",
    AlwaysDay     = false,
    AlwaysNight   = false,
    NoFog         = false,
    NoShadows     = false,
    AutoBuying    = false,
    AutoBuyItem   = "",
    AutoBuyPrice  = 100,
    AutoBuyAmt    = 1,
    AxeDupeSlot   = 1,
    AxeDupeWait   = 0.5,
    AxeDupeAmt    = 10,
    AxeDuping     = false,
    SelectedItems = {},
    StackLength   = 4,
    WoodAmount    = 1,
    SelectTree    = "",
    LassoActive   = false,
    ModWood       = false,
    ModSawmill    = false,
    StealTarget   = "",
    WoodPToUse    = "",
    ItemBoxToUse  = "",
}

-- ═══════════════ UI ROOT ═══════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "LT2Menu"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 999
ScreenGui.Parent         = gethui and gethui() or lp:WaitForChild("PlayerGui")

-- ═══════════════ UTILITY ═══════════════
local function Create(class, props, children)
    local obj = Instance.new(class)
    for k,v in pairs(props or {}) do
        obj[k] = v
    end
    for _,c in ipairs(children or {}) do
        c.Parent = obj
    end
    return obj
end

local function Tween(obj, goal, t, style, dir)
    local info = TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    TweenService:Create(obj, info, goal):Play()
end

local function Corner(r, parent)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = parent
    return c
end

local function Stroke(color, thickness, parent)
    local s = Instance.new("UIStroke")
    s.Color     = color or T.Border
    s.Thickness = thickness or 1
    s.Parent    = parent
    return s
end

local function Padding(v, parent)
    local p = Instance.new("UIPadding")
    if type(v) == "number" then
        p.PaddingTop    = UDim.new(0,v)
        p.PaddingBottom = UDim.new(0,v)
        p.PaddingLeft   = UDim.new(0,v)
        p.PaddingRight  = UDim.new(0,v)
    else
        p.PaddingTop    = v.Top    or UDim.new(0,0)
        p.PaddingBottom = v.Bottom or UDim.new(0,0)
        p.PaddingLeft   = v.Left   or UDim.new(0,0)
        p.PaddingRight  = v.Right  or UDim.new(0,0)
    end
    p.Parent = parent
    return p
end

local function ListLayout(parent, dir, spacing, halign, valign)
    local l = Instance.new("UIListLayout")
    l.FillDirection      = dir or Enum.FillDirection.Vertical
    l.SortOrder          = Enum.SortOrder.LayoutOrder
    l.Padding            = UDim.new(0, spacing or 6)
    if halign then l.HorizontalAlignment = halign end
    if valign  then l.VerticalAlignment  = valign  end
    l.Parent = parent
    return l
end

local function notify(msg, col)
    local n = Create("Frame", {
        Size            = UDim2.new(0,220,0,38),
        Position        = UDim2.new(0.5,-110,-0.05,0),
        BackgroundColor3= T.Card,
        BorderSizePixel = 0,
        ZIndex          = 99,
        Parent          = ScreenGui,
    })
    Corner(8, n); Stroke(col or T.Accent, 1, n)
    Create("TextLabel",{
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text  = msg,
        Font  = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = T.Text,
        ZIndex = 100,
        Parent = n,
    })
    Padding(6, n)
    Tween(n, {Position = UDim2.new(0.5,-110,0.02,0)}, 0.3, Enum.EasingStyle.Back)
    task.delay(2.5, function()
        Tween(n, {Position = UDim2.new(0.5,-110,-0.08,0)}, 0.3)
        task.delay(0.35, function() n:Destroy() end)
    end)
end

-- ═══════════════ MAIN WINDOW ═══════════════
local WIN_W = 310
local WIN_H = 480

local MainFrame = Create("Frame", {
    Name             = "MainFrame",
    Size             = UDim2.new(0, WIN_W, 0, WIN_H),
    Position         = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
    BackgroundColor3 = T.BG,
    BorderSizePixel  = 0,
    ClipsDescendants = true,
    Parent           = ScreenGui,
})
Corner(10, MainFrame)
Stroke(T.Border, 1, MainFrame)

-- Ambient glow overlay
Create("Frame", {
    Size = UDim2.new(1,0,0,2),
    Position = UDim2.new(0,0,0,0),
    BackgroundColor3 = T.Accent,
    BorderSizePixel = 0,
    ZIndex = 5,
    Parent = MainFrame,
})

-- ═══════════════ TITLE BAR ═══════════════
local TitleBar = Create("Frame", {
    Name             = "TitleBar",
    Size             = UDim2.new(1,0,0,42),
    Position         = UDim2.new(0,0,0,2),
    BackgroundColor3 = T.Panel,
    BorderSizePixel  = 0,
    ZIndex           = 4,
    Parent           = MainFrame,
})

Create("TextLabel", {
    Size = UDim2.new(1,-90,1,0),
    Position = UDim2.new(0,14,0,0),
    BackgroundTransparency = 1,
    Text = "🪓  LT2 MENU",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = T.Accent,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 5,
    Parent = TitleBar,
})

Create("TextLabel", {
    Size = UDim2.new(0,80,1,0),
    Position = UDim2.new(0,95,0,0),
    BackgroundTransparency = 1,
    Text = "v1.0 • LT2",
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextColor3 = T.TextMute,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 5,
    Parent = TitleBar,
})

-- Minimize button
local MinBtn = Create("TextButton", {
    Size             = UDim2.new(0,30,0,30),
    Position         = UDim2.new(1,-36,0.5,-15),
    BackgroundColor3 = T.Card,
    BorderSizePixel  = 0,
    Text             = "−",
    Font             = Enum.Font.GothamBold,
    TextSize         = 16,
    TextColor3       = T.TextDim,
    ZIndex           = 6,
    Parent           = TitleBar,
})
Corner(6, MinBtn)

-- ═══════════════ FLOATING ICON (minimized) ═══════════════
local FloatIcon = Create("TextButton", {
    Size             = UDim2.new(0,48,0,48),
    Position         = UDim2.new(0,16,0.5,-24),
    BackgroundColor3 = T.Panel,
    BorderSizePixel  = 0,
    Text             = "🪓",
    TextSize         = 22,
    Font             = Enum.Font.GothamBold,
    TextColor3       = T.White,
    ZIndex           = 20,
    Visible          = false,
    Parent           = ScreenGui,
})
Corner(12, FloatIcon)
Stroke(T.Accent, 2, FloatIcon)

-- ═══════════════ TAB BAR ═══════════════
local TABS = {
    {name="Slot",  icon="🏠"},
    {name="Player",icon="🧍"},
    {name="World", icon="🌍"},
    {name="Wood",  icon="🪵"},
    {name="Buy",   icon="🛒"},
    {name="Item",  icon="📦"},
    {name="Dupe",  icon="⚡"},
    {name="Build", icon="🔨"},
}

local TabBar = Create("Frame", {
    Name             = "TabBar",
    Size             = UDim2.new(1,0,0,52),
    Position         = UDim2.new(0,0,1,-52),
    BackgroundColor3 = T.Panel,
    BorderSizePixel  = 0,
    ZIndex           = 4,
    Parent           = MainFrame,
})
Stroke(T.Border, 1, TabBar)

local TabScroll = Create("ScrollingFrame", {
    Size                  = UDim2.new(1,0,1,0),
    BackgroundTransparency= 1,
    BorderSizePixel       = 0,
    CanvasSize            = UDim2.new(0, #TABS * 70, 0, 0),
    ScrollBarThickness    = 0,
    ScrollingDirection    = Enum.ScrollingDirection.X,
    ZIndex                = 5,
    Parent                = TabBar,
})

ListLayout(TabScroll, Enum.FillDirection.Horizontal, 2, nil, Enum.VerticalAlignment.Center)
Padding(4, TabScroll)

local TabBtns = {}
for i, tab in ipairs(TABS) do
    local btn = Create("TextButton", {
        Size             = UDim2.new(0,62,0,40),
        BackgroundColor3 = i == 1 and T.Card or T.Panel,
        BorderSizePixel  = 0,
        Text             = "",
        ZIndex           = 6,
        LayoutOrder      = i,
        Parent           = TabScroll,
    })
    Corner(6, btn)
    if i == 1 then Stroke(T.Accent, 1, btn) end

    Create("TextLabel", {
        Size = UDim2.new(1,0,0,20),
        Position = UDim2.new(0,0,0,2),
        BackgroundTransparency = 1,
        Text = tab.icon,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextColor3 = T.Text,
        ZIndex = 7,
        Parent = btn,
    })
    Create("TextLabel", {
        Size = UDim2.new(1,0,0,14),
        Position = UDim2.new(0,0,1,-16),
        BackgroundTransparency = 1,
        Text = tab.name,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextColor3 = i == 1 and T.Accent or T.TextDim,
        ZIndex = 7,
        Parent = btn,
    })
    TabBtns[i] = btn
end

-- ═══════════════ CONTENT AREA ═══════════════
local ContentArea = Create("ScrollingFrame", {
    Name                  = "Content",
    Size                  = UDim2.new(1,0,1,-96),
    Position              = UDim2.new(0,0,0,44),
    BackgroundTransparency= 1,
    BorderSizePixel       = 0,
    CanvasSize            = UDim2.new(0,0,0,0),
    ScrollBarThickness    = 3,
    ScrollBarImageColor3  = T.Border,
    AutomaticCanvasSize   = Enum.AutomaticSize.Y,
    ScrollingDirection    = Enum.ScrollingDirection.Y,
    ZIndex                = 3,
    Parent                = MainFrame,
})

local ContentList = ListLayout(ContentArea, Enum.FillDirection.Vertical, 0)
Padding({Top=UDim.new(0,6), Bottom=UDim.new(0,6), Left=UDim.new(0,8), Right=UDim.new(0,8)}, ContentArea)

-- ═══════════════ UI COMPONENT BUILDERS ═══════════════

-- Section header
local function SectionHeader(title, parent, order)
    local f = Create("Frame", {
        Size = UDim2.new(1,0,0,28),
        BackgroundTransparency = 1,
        LayoutOrder = order or 0,
        Parent = parent,
    })
    Create("TextLabel", {
        Size = UDim2.new(1,-8,1,0),
        Position = UDim2.new(0,4,0,0),
        BackgroundTransparency = 1,
        Text = "▸  " .. title:upper(),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = T.Accent2,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
        Parent = f,
    })
    Create("Frame", {
        Size = UDim2.new(1,0,0,1),
        Position = UDim2.new(0,0,1,-1),
        BackgroundColor3 = T.Border,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = f,
    })
    return f
end

-- Button
local function MakeButton(text, color, parent, order, callback)
    color = color or T.Accent
    local btn = Create("TextButton", {
        Size             = UDim2.new(1,0,0,36),
        BackgroundColor3 = T.Card,
        BorderSizePixel  = 0,
        Text             = "",
        ZIndex           = 4,
        LayoutOrder      = order or 0,
        Parent           = parent,
    })
    Corner(6, btn)
    Stroke(T.Border, 1, btn)

    Create("Frame",{
        Size = UDim2.new(0,3,0,18),
        Position = UDim2.new(0,8,0.5,-9),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = btn,
    })
    Corner(2, btn:FindFirstChild("Frame"))

    Create("TextLabel", {
        Size = UDim2.new(1,-22,1,0),
        Position = UDim2.new(0,18,0,0),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
        Parent = btn,
    })

    btn.MouseButton1Click:Connect(function()
        Tween(btn, {BackgroundColor3 = T.CardHov}, 0.08)
        task.delay(0.12, function() Tween(btn, {BackgroundColor3 = T.Card}, 0.15) end)
        if callback then callback() end
    end)
    btn.TouchTap:Connect(function()
        Tween(btn, {BackgroundColor3 = T.CardHov}, 0.08)
        task.delay(0.12, function() Tween(btn, {BackgroundColor3 = T.Card}, 0.15) end)
        if callback then callback() end
    end)
    return btn
end

-- Danger Button
local function DangerButton(text, parent, order, callback)
    return MakeButton(text, T.Red, parent, order, callback)
end

-- Warning Button
local function WarnButton(text, parent, order, callback)
    return MakeButton(text, T.AccentW, parent, order, callback)
end

-- Toggle
local function MakeToggle(label, default, parent, order, callback)
    local on = default or false
    local row = Create("Frame", {
        Size = UDim2.new(1,0,0,36),
        BackgroundColor3 = T.Card,
        BorderSizePixel = 0,
        LayoutOrder = order or 0,
        Parent = parent,
    })
    Corner(6, row)
    Stroke(T.Border, 1, row)

    Create("TextLabel",{
        Size = UDim2.new(1,-52,1,0),
        Position = UDim2.new(0,12,0,0),
        BackgroundTransparency = 1,
        Text = label,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
        Parent = row,
    })

    local track = Create("Frame",{
        Size = UDim2.new(0,36,0,20),
        Position = UDim2.new(1,-44,0.5,-10),
        BackgroundColor3 = on and T.Toggle_ON or T.Toggle_OFF,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = row,
    })
    Corner(10, track)

    local knob = Create("Frame",{
        Size = UDim2.new(0,14,0,14),
        Position = on and UDim2.new(0,19,0.5,-7) or UDim2.new(0,3,0.5,-7),
        BackgroundColor3 = T.White,
        BorderSizePixel = 0,
        ZIndex = 6,
        Parent = track,
    })
    Corner(7, knob)

    local function setToggle(val)
        on = val
        Tween(track, {BackgroundColor3 = on and T.Toggle_ON or T.Toggle_OFF}, 0.15)
        Tween(knob,  {Position = on and UDim2.new(0,19,0.5,-7) or UDim2.new(0,3,0.5,-7)}, 0.15)
        if callback then callback(on) end
    end

    local clickBtn = Create("TextButton",{
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 7,
        Parent = row,
    })
    clickBtn.MouseButton1Click:Connect(function() setToggle(not on) end)
    clickBtn.TouchTap:Connect(function() setToggle(not on) end)

    return row, function() return on end, setToggle
end

-- Slider
local function MakeSlider(label, min, max, default, parent, order, callback)
    local val = default or min
    local dragging = false

    local wrap = Create("Frame",{
        Size = UDim2.new(1,0,0,56),
        BackgroundColor3 = T.Card,
        BorderSizePixel = 0,
        LayoutOrder = order or 0,
        Parent = parent,
    })
    Corner(6, wrap)
    Stroke(T.Border, 1, wrap)
    Padding(8, wrap)

    local topRow = Create("Frame",{
        Size = UDim2.new(1,0,0,18),
        BackgroundTransparency = 1,
        ZIndex = 4,
        Parent = wrap,
    })
    Create("TextLabel",{
        Size = UDim2.new(0.7,0,1,0),
        BackgroundTransparency = 1,
        Text = label,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
        Parent = topRow,
    })
    local valLabel = Create("TextLabel",{
        Size = UDim2.new(0.3,0,1,0),
        Position = UDim2.new(0.7,0,0,0),
        BackgroundTransparency = 1,
        Text = tostring(val),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = T.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 5,
        Parent = topRow,
    })

    local track = Create("Frame",{
        Size = UDim2.new(1,0,0,6),
        Position = UDim2.new(0,0,1,-6),
        BackgroundColor3 = T.SliderBG,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = wrap,
    })
    Corner(3, track)

    local fill = Create("Frame",{
        Size = UDim2.new((val-min)/(max-min), 0, 1, 0),
        BackgroundColor3 = T.SliderFG,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = track,
    })
    Corner(3, fill)

    local knob = Create("Frame",{
        Size = UDim2.new(0,14,0,14),
        Position = UDim2.new((val-min)/(max-min),0,0.5,-7),
        AnchorPoint = Vector2.new(0.5,0),
        BackgroundColor3 = T.White,
        BorderSizePixel = 0,
        ZIndex = 6,
        Parent = track,
    })
    Corner(7, knob)
    Stroke(T.SliderFG, 2, knob)

    local hitbox = Create("TextButton",{
        Size = UDim2.new(1,0,0,30),
        Position = UDim2.new(0,0,0.5,-15),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 7,
        Parent = track,
    })

    local function updateSlider(pct)
        pct = math.clamp(pct, 0, 1)
        val = math.floor(min + (max-min)*pct + 0.5)
        valLabel.Text = tostring(val)
        Tween(fill,  {Size = UDim2.new(pct, 0, 1, 0)}, 0.05)
        Tween(knob,  {Position = UDim2.new(pct, 0, 0.5, -7)}, 0.05)
        if callback then callback(val) end
    end

    hitbox.MouseButton1Down:Connect(function()
        dragging = true
    end)
    hitbox.TouchLongPress:Connect(function()
        dragging = true
    end)
    UserInput.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging then
            local pos = UserInput:GetMouseLocation()
            local abs = track.AbsolutePosition
            local sz  = track.AbsoluteSize
            local pct = (pos.X - abs.X) / sz.X
            updateSlider(pct)
        end
    end)

    return wrap, function() return val end
end

-- Input Field
local function MakeInput(label, placeholder, parent, order, callback)
    local wrap = Create("Frame",{
        Size = UDim2.new(1,0,0,52),
        BackgroundColor3 = T.Card,
        BorderSizePixel = 0,
        LayoutOrder = order or 0,
        Parent = parent,
    })
    Corner(6, wrap)
    Stroke(T.Border, 1, wrap)
    Padding(8, wrap)

    Create("TextLabel",{
        Size = UDim2.new(1,0,0,18),
        BackgroundTransparency = 1,
        Text = label,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = T.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
        Parent = wrap,
    })

    local box = Create("TextBox",{
        Size = UDim2.new(1,0,0,22),
        Position = UDim2.new(0,0,1,-22),
        BackgroundColor3 = T.BG,
        BorderSizePixel = 0,
        PlaceholderText = placeholder or "Enter value...",
        PlaceholderColor3 = T.TextMute,
        Text = "",
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = T.Text,
        ClearTextOnFocus = false,
        ZIndex = 6,
        Parent = wrap,
    })
    Corner(4, box)
    Stroke(T.Border, 1, box)
    Padding(4, box)

    box.FocusLost:Connect(function()
        if callback then callback(box.Text) end
    end)

    return wrap, box
end

-- Dropdown (simple)
local function MakeDropdown(label, options, parent, order, callback)
    local selected = options[1] or ""
    local open = false

    local wrap = Create("Frame",{
        Size = UDim2.new(1,0,0,54),
        BackgroundColor3 = T.Card,
        BorderSizePixel = 0,
        LayoutOrder = order or 0,
        ClipsDescendants = false,
        ZIndex = 4,
        Parent = parent,
    })
    Corner(6, wrap)
    Stroke(T.Border, 1, wrap)
    Padding(8, wrap)

    Create("TextLabel",{
        Size = UDim2.new(1,0,0,16),
        BackgroundTransparency = 1,
        Text = label,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = T.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
        Parent = wrap,
    })

    local selBtn = Create("TextButton",{
        Size = UDim2.new(1,0,0,22),
        Position = UDim2.new(0,0,1,-22),
        BackgroundColor3 = T.BG,
        BorderSizePixel = 0,
        Text = "",
        ZIndex = 6,
        Parent = wrap,
    })
    Corner(4, selBtn)
    Stroke(T.Border, 1, selBtn)

    local selLabel = Create("TextLabel",{
        Size = UDim2.new(1,-24,1,0),
        Position = UDim2.new(0,6,0,0),
        BackgroundTransparency = 1,
        Text = selected,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7,
        Parent = selBtn,
    })
    Create("TextLabel",{
        Size = UDim2.new(0,18,1,0),
        Position = UDim2.new(1,-20,0,0),
        BackgroundTransparency = 1,
        Text = "▾",
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextColor3 = T.TextDim,
        ZIndex = 7,
        Parent = selBtn,
    })

    -- Dropdown list (in ScreenGui to avoid clipping)
    local dropList = Create("Frame",{
        Size = UDim2.new(0,1,0,1),
        BackgroundColor3 = T.Card,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 50,
        Parent = ScreenGui,
    })
    Corner(6, dropList)
    Stroke(T.Border, 1, dropList)

    local dropScroll = Create("ScrollingFrame",{
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Border,
        ZIndex = 51,
        Parent = dropList,
    })
    ListLayout(dropScroll, nil, 2)
    Padding(4, dropScroll)

    local function closeDropdown()
        open = false
        dropList.Visible = false
    end

    local function buildOptions()
        for _,c in ipairs(dropScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, opt in ipairs(options) do
            local ob = Create("TextButton",{
                Size = UDim2.new(1,0,0,26),
                BackgroundColor3 = T.CardHov,
                BorderSizePixel = 0,
                Text = opt,
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                TextColor3 = T.Text,
                ZIndex = 52,
                Parent = dropScroll,
            })
            Corner(4, ob)
            ob.MouseButton1Click:Connect(function()
                selected = opt
                selLabel.Text = opt
                closeDropdown()
                if callback then callback(opt) end
            end)
            ob.TouchTap:Connect(function()
                selected = opt
                selLabel.Text = opt
                closeDropdown()
                if callback then callback(opt) end
            end)
        end
    end
    buildOptions()

    selBtn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            local abs = selBtn.AbsolutePosition
            local sz  = selBtn.AbsoluteSize
            local listH = math.min(#options * 30 + 10, 140)
            dropList.Size     = UDim2.new(0, sz.X, 0, listH)
            dropList.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + 4)
            dropList.Visible  = true
        else
            closeDropdown()
        end
    end)
    selBtn.TouchTap:Connect(function()
        open = not open
        if open then
            local abs = selBtn.AbsolutePosition
            local sz  = selBtn.AbsoluteSize
            local listH = math.min(#options * 30 + 10, 140)
            dropList.Size     = UDim2.new(0, sz.X, 0, listH)
            dropList.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + 4)
            dropList.Visible  = true
        else
            closeDropdown()
        end
    end)

    return wrap, function() return selected end, function(newOpts)
        options = newOpts
        buildOptions()
        selLabel.Text = options[1] or ""
        selected = options[1] or ""
    end
end

-- Gap frame
local function Gap(h, parent, order)
    return Create("Frame",{
        Size = UDim2.new(1,0,0,h or 4),
        BackgroundTransparency = 1,
        LayoutOrder = order or 0,
        Parent = parent,
    })
end

-- ═══════════════ TAB PAGES ═══════════════
local Pages = {}

local function clearContent()
    for _,c in ipairs(ContentArea:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") or c:IsA("ScrollingFrame") then
            c:Destroy()
        end
    end
end

local function switchTab(idx)
    State.ActiveTab = idx
    for i, btn in ipairs(TabBtns) do
        local isActive = (i == idx)
        Tween(btn, {BackgroundColor3 = isActive and T.Card or T.Panel}, 0.1)
        btn:FindFirstChildWhichIsA("UIStroke", true).Color = isActive and T.Accent or T.Border
        local lbl = btn:FindFirstChildOfClass("TextLabel")
        local lbl2
        for _,c in ipairs(btn:GetChildren()) do
            if c:IsA("TextLabel") and c.TextSize == 9 then lbl2 = c end
        end
        if lbl2 then lbl2.TextColor3 = isActive and T.Accent or T.TextDim end
    end
    clearContent()
    if Pages[idx] then Pages[idx]() end
end

-- ═══════════════ PAGE 1: SLOT ═══════════════
Pages[1] = function()
    local lo = 0
    local function L() lo=lo+1; return lo end

    SectionHeader("Base Help", ContentArea, L())

    MakeButton("Free Land", T.Accent, ContentArea, L(), function()
        -- LT2 free land logic placeholder
        local players = Players:GetPlayers()
        notify("Free Land activated", T.Accent)
        -- game logic would call relevant remote here
    end)

    MakeButton("Max Land", T.Accent2, ContentArea, L(), function()
        notify("Max Land activated", T.Accent2)
    end)

    MakeButton("Land Art", T.AccentW, ContentArea, L(), function()
        notify("Land Art activated", T.AccentW)
    end)

    WarnButton("Force Save", ContentArea, L(), function()
        local rs = game:GetService("ReplicatedStorage")
        local lsr = rs:FindFirstChild("LoadSaveRequests")
        if lsr then
            local saveFn = lsr:FindFirstChild("ForceSave") or lsr:FindFirstChild("Save")
            if saveFn and saveFn:IsA("RemoteFunction") then
                pcall(function() saveFn:InvokeServer() end)
                notify("Force save sent!", T.AccentW)
            else
                notify("Save remote not found", T.Red)
            end
        else
            notify("LoadSaveRequests not found", T.Red)
        end
    end)

    Gap(4, ContentArea, L())
end

-- ═══════════════ PAGE 2: PLAYER ═══════════════
Pages[2] = function()
    local lo = 0
    local function L() lo=lo+1; return lo end

    SectionHeader("Movement Sliders", ContentArea, L())

    local wsSlider, getWS = MakeSlider("Walk Speed",    1, 100, State.WalkSpeed,   ContentArea, L(), function(v)
        State.WalkSpeed = v
        if hum then hum.WalkSpeed = v end
    end)

    local ssSlider, getSS = MakeSlider("Sprint Speed",  1, 150, State.SprintSpeed, ContentArea, L(), function(v)
        State.SprintSpeed = v
    end)

    local jpSlider, getJP = MakeSlider("Jump Power",    1, 200, State.JumpPower,   ContentArea, L(), function(v)
        State.JumpPower = v
        if hum then hum.JumpPower = v end
    end)

    local fsSlider, getFS = MakeSlider("Fly Speed",     1, 200, State.FlySpeed,    ContentArea, L(), function(v)
        State.FlySpeed = v
    end)

    Gap(4, ContentArea, L())
    SectionHeader("Movement Toggles", ContentArea, L())

    -- Keybind display
    local kbWrap, kbBox = MakeInput("Fly Keybind (letter)", State.FlyKeyBind, ContentArea, L(), function(v)
        State.FlyKeyBind = v:upper():sub(1,1)
        kbBox.Text = State.FlyKeyBind
        notify("Fly keybind set to: " .. State.FlyKeyBind, T.Accent)
    end)

    -- Fly toggle
    local flyConn
    local function startFly()
        if flyConn then flyConn:Disconnect() end
        local bp = Instance.new("BodyPosition")
        bp.MaxForce = Vector3.new(1e5,1e5,1e5)
        bp.Parent = hrp
        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
        bg.Parent = hrp
        if hum then hum.PlatformStand = true end

        flyConn = RunService.RenderStepped:Connect(function()
            if not State.Flying then
                bp:Destroy(); bg:Destroy()
                if hum then hum.PlatformStand = false end
                flyConn:Disconnect()
                return
            end
            local dir = Vector3.new()
            local cam = Workspace.CurrentCamera
            local cf  = cam.CFrame
            if UserInput:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
            if UserInput:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
            if UserInput:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
            if UserInput:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
            if UserInput:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
            bp.Position = hrp.Position + dir.Unit * State.FlySpeed * 0.1
            if dir.Magnitude > 0 then
                bg.CFrame = CFrame.new(Vector3.new(), dir)
            end
        end)
    end

    MakeToggle("Fly", false, ContentArea, L(), function(on)
        State.Flying = on
        if on then
            startFly()
            notify("Fly ON", T.Accent)
        else
            State.Flying = false
            notify("Fly OFF", T.Red)
        end
    end)

    -- Keyboard fly keybind
    UserInput.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode[State.FlyKeyBind] or
           inp.KeyCode == Enum.KeyCode.F then
            State.Flying = not State.Flying
            if State.Flying then startFly() end
        end
    end)

    Gap(4, ContentArea, L())
end

-- ═══════════════ PAGE 3: WORLD ═══════════════
Pages[3] = function()
    local lo = 0
    local function L() lo=lo+1; return lo end
    local lighting = game:GetService("Lighting")

    SectionHeader("Lighting", ContentArea, L())

    MakeToggle("Always Day", false, ContentArea, L(), function(on)
        State.AlwaysDay = on
        if on then
            lighting.ClockTime = 14
            lighting.FogEnd = 100000
            notify("Always Day ON", T.AccentW)
        end
    end)

    MakeToggle("Always Night", false, ContentArea, L(), function(on)
        State.AlwaysNight = on
        if on then
            lighting.ClockTime = 0
            notify("Always Night ON", T.Accent2)
        end
    end)

    MakeToggle("No Fog", false, ContentArea, L(), function(on)
        State.NoFog = on
        lighting.FogEnd   = on and 100000 or 1000
        lighting.FogStart = on and 99999  or 0
        notify(on and "Fog Removed" or "Fog Restored", on and T.Accent or T.TextDim)
    end)

    MakeToggle("Shadows", true, ContentArea, L(), function(on)
        lighting.GlobalShadows = on
        notify(on and "Shadows ON" or "Shadows OFF", T.TextDim)
    end)

    MakeButton("Lost Content (Fog Toggle)", T.AccentW, ContentArea, L(), function()
        lighting.FogEnd   = 300
        lighting.FogStart = 0
        lighting.FogColor = Color3.fromRGB(200,200,210)
        notify("Lost content fog applied", T.AccentW)
    end)

    Gap(4, ContentArea, L())
    SectionHeader("Teleports", ContentArea, L())

    -- Waypoints
    local waypoints = {
        "Main Area", "Snow Biome", "Swamp", "Volcano", "Tropics",
        "Mountainside", "Cave", "Plains", "Sand Islands", "SnowPeak"
    }
    local wpPositions = {
        Vector3.new(-57, 8, -53),
        Vector3.new(-714, 207, -135),
        Vector3.new(480, 5, 310),
        Vector3.new(1200, 80, -140),
        Vector3.new(-350, 5, 900),
        Vector3.new(-850, 220, -250),
        Vector3.new(-620, 30, 270),
        Vector3.new(200, 5, 100),
        Vector3.new(-180, 5, 1300),
        Vector3.new(-700, 430, -120),
    }

    local _, getWP = MakeDropdown("Teleport to Waypoint", waypoints, ContentArea, L(), function(v)
        State.SelectedWP = v
    end)

    MakeButton("Teleport to Waypoint ⟶", T.Accent2, ContentArea, L(), function()
        local sel = getWP()
        for i, name in ipairs(waypoints) do
            if name == sel then
                hrp.CFrame = CFrame.new(wpPositions[i])
                notify("Teleported to " .. name, T.Accent2)
                return
            end
        end
    end)

    -- Teleport to player
    local playerNames = {"(Select Player)"}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            table.insert(playerNames, p.Name)
        end
    end

    local _, getPName, refreshPDD = MakeDropdown("Teleport to Player", playerNames, ContentArea, L(), function(v)
        State.TeleportPlayer = v
    end)

    MakeButton("Refresh Players", T.TextDim, ContentArea, L(), function()
        local names = {"(Select Player)"}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then table.insert(names, p.Name) end
        end
        refreshPDD(names)
        notify("Player list refreshed", T.TextDim)
    end)

    MakeButton("Teleport to Player ⟶", T.Accent2, ContentArea, L(), function()
        local pname = getPName()
        if pname == "(Select Player)" then notify("Select a player first", T.Red); return end
        local target = Players:FindFirstChild(pname)
        if target and target.Character then
            local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                hrp.CFrame = tHRP.CFrame * CFrame.new(3,0,0)
                notify("Teleported to " .. pname, T.Accent2)
            end
        end
    end)

    Gap(4, ContentArea, L())
end

-- ═══════════════ PAGE 4: WOOD ═══════════════
Pages[4] = function()
    local lo = 0
    local function L() lo=lo+1; return lo end

    SectionHeader("Get Tree", ContentArea, L())

    local treeTypes = {"Oak","Birch","Cherry","Elm","Walnut","Pine","Koa","Palm","Fir","Frost","Spooky","Gold","Green","Bewitched","Zombie","Phantom"}
    local _, getTreeType = MakeDropdown("Select Tree", treeTypes, ContentArea, L())
    local _, getTreeAmt = MakeSlider("Amount", 1, 50, 1, ContentArea, L())

    MakeButton("Get Tree 🌲", T.Accent, ContentArea, L(), function()
        local tType = getTreeType()
        local amt   = getTreeAmt()
        notify("Getting " .. amt .. "x " .. tType .. " trees...", T.Accent)
        -- LT2 tree spawning via game remotes would go here
        local rs = game:GetService("ReplicatedStorage")
        local regions = rs:FindFirstChild("Regions")
        if regions then
            -- hook into tree spawner region
        end
    end)

    MakeButton("Stop 🛑", T.Red, ContentArea, L(), function()
        notify("Tree getter stopped", T.Red)
    end)

    MakeButton("Sell Tree 💰", T.AccentW, ContentArea, L(), function()
        -- sell logic
        notify("Selling trees...", T.AccentW)
    end)

    Gap(4, ContentArea, L())
    SectionHeader("Mods", ContentArea, L())

    MakeToggle("ModWood", false, ContentArea, L(), function(on)
        State.ModWood = on
        notify("ModWood " .. (on and "ON" or "OFF"), on and T.Accent or T.TextDim)
    end)

    MakeToggle("ModSawmill", false, ContentArea, L(), function(on)
        State.ModSawmill = on
        notify("ModSawmill " .. (on and "ON" or "OFF"), on and T.Accent or T.TextDim)
    end)

    Gap(4, ContentArea, L())
    SectionHeader("Lasso", ContentArea, L())

    MakeButton("Wood Selector Lasso", T.Accent2, ContentArea, L(), function()
        State.LassoActive = true
        notify("Lasso active – drag to select wood", T.Accent2)
    end)

    MakeButton("Sell Selected Wood 💰", T.AccentW, ContentArea, L(), function()
        if next(State.SelectedItems) == nil then
            notify("Nothing selected", T.Red); return
        end
        notify("Selling selected wood...", T.AccentW)
        State.SelectedItems = {}
    end)

    MakeButton("Deselect ✕", T.Red, ContentArea, L(), function()
        State.SelectedItems = {}
        State.LassoActive   = false
        notify("Selection cleared", T.TextDim)
    end)

    Gap(4, ContentArea, L())
end

-- ═══════════════ PAGE 5: AUTO BUY ═══════════════
Pages[5] = function()
    local lo = 0
    local function L() lo=lo+1; return lo end

    SectionHeader("Auto Buy", ContentArea, L())

    local items = {"BasicHatchet","RustyAxe","Axe1","Axe2","Axe3","SilverAxe","BluesteelAxe","RefinedAxe","CaveAxe","FireAxe","IceAxe","BeesAxe","CandyCaneAxe"}
    local _, getItem = MakeDropdown("Select Item", items, ContentArea, L(), function(v)
        State.AutoBuyItem = v
    end)

    local _, getPrice = MakeSlider("Max Price", 0, 10000, State.AutoBuyPrice, ContentArea, L(), function(v)
        State.AutoBuyPrice = v
    end)

    local _, getAmt = MakeSlider("Amount", 1, 100, State.AutoBuyAmt, ContentArea, L(), function(v)
        State.AutoBuyAmt = v
    end)

    MakeButton("Purchase ✓", T.Accent, ContentArea, L(), function()
        local itm   = getItem()
        local price = getPrice()
        local amt   = getAmt()
        notify("Buying " .. amt .. "x " .. itm, T.Accent)
        -- purchase remote logic here
    end)

    MakeButton("Stop Purchasing ✕", T.Red, ContentArea, L(), function()
        State.AutoBuying = false
        notify("Auto buy stopped", T.Red)
    end)

    Gap(4, ContentArea, L())
    SectionHeader("Other", ContentArea, L())

    WarnButton("Purchase Rukiryaxe  —  $7,400 🦆", ContentArea, L(), function()
        notify("Purchasing Rukiryaxe...", T.AccentW)
        -- rukiryaxe purchase remote
        local rs = game:GetService("ReplicatedStorage")
        local trans = rs:FindFirstChild("Transactions")
        if trans then
            local buyFn = trans:FindFirstChild("PurchaseItem")
            if buyFn then
                pcall(function()
                    buyFn:InvokeServer({ItemName="Rukiryaxe", Price=7400})
                end)
            end
        end
    end)

    Gap(4, ContentArea, L())
end

-- ═══════════════ PAGE 6: ITEM ═══════════════
Pages[6] = function()
    local lo = 0
    local function L() lo=lo+1; return lo end

    SectionHeader("Selection Tools", ContentArea, L())

    MakeButton("Lasso Selector (Click & Drag)", T.Accent2, ContentArea, L(), function()
        State.LassoActive = true
        notify("Lasso active — drag to select", T.Accent2)
    end)

    MakeButton("Click Group Selection", T.Accent2, ContentArea, L(), function()
        notify("Click-group mode ON", T.Accent2)
    end)

    MakeButton("Click Selection", T.Accent, ContentArea, L(), function()
        notify("Click-select mode ON", T.Accent)
    end)

    Gap(4, ContentArea, L())
    SectionHeader("Item Teleport", ContentArea, L())

    MakeButton("Teleport Selected ⟶", T.Accent, ContentArea, L(), function()
        if next(State.SelectedItems) == nil then
            notify("Nothing selected", T.Red); return
        end
        local dest = hrp.Position + Vector3.new(0,3,0)
        for _, item in ipairs(State.SelectedItems) do
            if item and item.PrimaryPart then
                item:SetPrimaryPartCFrame(CFrame.new(dest))
            end
        end
        notify("Items teleported to you", T.Accent)
    end)

    MakeButton("Deselect ✕", T.Red, ContentArea, L(), function()
        State.SelectedItems = {}
        State.LassoActive   = false
        notify("Deselected all", T.TextDim)
    end)

    Gap(4, ContentArea, L())
    SectionHeader("Stacker", ContentArea, L())

    MakeSlider("Stack Length", 1, 20, State.StackLength, ContentArea, L(), function(v)
        State.StackLength = v
    end)

    Gap(4, ContentArea, L())
end

-- ═══════════════ PAGE 7: DUPE ═══════════════
Pages[7] = function()
    local lo = 0
    local function L() lo=lo+1; return lo end

    SectionHeader("Axe Dupe", ContentArea, L())

    MakeSlider("Slot (1–8)", 1, 8, State.AxeDupeSlot, ContentArea, L(), function(v)
        State.AxeDupeSlot = math.floor(v)
    end)

    MakeSlider("Wait Time (s)", 0, 5, State.AxeDupeWait, ContentArea, L(), function(v)
        State.AxeDupeWait = v / 10
    end)

    MakeSlider("Amount", 1, 100, State.AxeDupeAmt, ContentArea, L(), function(v)
        State.AxeDupeAmt = math.floor(v)
    end)

    MakeButton("Start Axe Dupe ⚡", T.Accent, ContentArea, L(), function()
        if State.AxeDuping then notify("Already duping", T.Red); return end
        State.AxeDuping = true
        notify("Axe dupe started ×" .. State.AxeDupeAmt, T.Accent)

        local rs = game:GetService("ReplicatedStorage")
        local count = 0
        task.spawn(function()
            while State.AxeDuping and count < State.AxeDupeAmt do
                count = count + 1
                pcall(function()
                    -- drop + pick dupe pattern used in LT2 exploits
                    local tool = lp.Character and lp.Character:FindFirstChildOfClass("Tool")
                    if tool then
                        local drop = rs:FindFirstChild("Transactions")
                        if drop then
                            local dropFn = drop:FindFirstChild("DropItem") or drop:FindFirstChild("Drop")
                            if dropFn then dropFn:InvokeServer(tool) end
                        end
                    end
                end)
                task.wait(State.AxeDupeWait > 0 and State.AxeDupeWait or 0.1)
            end
            State.AxeDuping = false
            notify("Axe dupe complete!", T.Accent)
        end)
    end)

    DangerButton("Drop All Axes 💥", ContentArea, L(), function()
        pcall(function()
            for _, item in ipairs(lp.Backpack:GetChildren()) do
                if item:IsA("Tool") and item.Name:lower():find("axe") then
                    item.Parent = Workspace
                    item:FindFirstChildOfClass("BasePart").CFrame =
                        hrp.CFrame * CFrame.new(math.random(-3,3), 0, math.random(-3,3))
                end
            end
        end)
        notify("Dropped all axes", T.Red)
    end)

    Gap(4, ContentArea, L())
end

-- ═══════════════ PAGE 8: AUTO BUILD ═══════════════
Pages[8] = function()
    local lo = 0
    local function L() lo=lo+1; return lo end

    SectionHeader("Auto Build", ContentArea, L())

    local allPlayers = {}
    for _, p in ipairs(Players:GetPlayers()) do table.insert(allPlayers, p.Name) end

    local _, getWoodPlayer,  _ = MakeDropdown("Player's Wood to Use",      allPlayers, ContentArea, L(), function(v) State.WoodPToUse  = v end)
    local _, getItemPlayer,  _ = MakeDropdown("Player's Items/Boxes to Use",allPlayers, ContentArea, L(), function(v) State.ItemBoxToUse = v end)

    MakeButton("Open AutoBuild UI 🔧", T.Accent2, ContentArea, L(), function()
        notify("Opening AutoBuild UI...", T.Accent2)
    end)

    MakeButton("Load Preview 👁", T.Accent, ContentArea, L(), function()
        notify("Loading blueprint preview...", T.Accent)
    end)

    MakeButton("Unload Preview ✕", T.Red, ContentArea, L(), function()
        notify("Preview unloaded", T.Red)
    end)

    Gap(4, ContentArea, L())
    SectionHeader("Steal Plot", ContentArea, L())

    local _, getStealTarget, _ = MakeDropdown("Player's Base to Steal", allPlayers, ContentArea, L(), function(v)
        State.StealTarget = v
    end)

    MakeButton("Steal Plot 😈", T.Red, ContentArea, L(), function()
        local target = getStealTarget()
        if not target then notify("Select a player first", T.Red); return end
        notify("Stealing " .. target .. "'s plot...", T.Red)
        -- plot steal logic
    end)

    Gap(4, ContentArea, L())
    SectionHeader("Auto Fill", ContentArea, L())

    MakeButton("Lasso Selector (Click & Drag)", T.Accent2, ContentArea, L(), function()
        State.LassoActive = true
        notify("Lasso active — drag to select", T.Accent2)
    end)

    MakeButton("Deselect ✕", T.Red, ContentArea, L(), function()
        State.SelectedItems = {}; State.LassoActive = false
        notify("Deselected", T.TextDim)
    end)

    MakeButton("Fill Blueprints 🔨", T.Accent, ContentArea, L(), function()
        notify("Auto-filling blueprints...", T.Accent)
    end)

    Gap(4, ContentArea, L())
    SectionHeader("Helper", ContentArea, L())

    MakeButton("Blueprint Lasso (Click & Drag)", T.Accent2, ContentArea, L(), function()
        State.LassoActive = true
        notify("Blueprint lasso active", T.Accent2)
    end)

    MakeButton("Deselect ✕", T.Red, ContentArea, L(), function()
        State.SelectedItems = {}; State.LassoActive = false
        notify("Deselected blueprints", T.TextDim)
    end)

    DangerButton("Destroy Selected Blueprints 💥", ContentArea, L(), function()
        local count = 0
        for _, item in ipairs(State.SelectedItems) do
            pcall(function()
                if item and item.Parent then
                    item:Destroy(); count = count + 1
                end
            end)
        end
        State.SelectedItems = {}
        notify("Destroyed " .. count .. " blueprints", T.Red)
    end)

    Gap(4, ContentArea, L())
end

-- ═══════════════ TAB BUTTON CONNECTIONS ═══════════════
for i, btn in ipairs(TabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(i) end)
    btn.TouchTap:Connect(function() switchTab(i) end)
end

-- ═══════════════ DRAGGING ═══════════════
local dragging, dragStart, startPos = false, nil, nil

local function startDrag(pos)
    dragging  = true
    dragStart = pos
    startPos  = MainFrame.Position
end

local function updateDrag(pos)
    if not dragging then return end
    local delta = pos - dragStart
    local vp    = Workspace.CurrentCamera.ViewportSize
    local newX  = math.clamp(startPos.X.Offset + delta.X, 0, vp.X - WIN_W)
    local newY  = math.clamp(startPos.Y.Offset + delta.Y, 0, vp.Y - WIN_H)
    MainFrame.Position = UDim2.new(0, newX, 0, newY)
end

TitleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or
       inp.UserInputType == Enum.UserInputType.Touch then
        startDrag(inp.UserInputType == Enum.UserInputType.Touch
            and inp.Position or UserInput:GetMouseLocation())
    end
end)

UserInput.InputChanged:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseMovement then
        updateDrag(UserInput:GetMouseLocation())
    elseif inp.UserInputType == Enum.UserInputType.Touch then
        updateDrag(inp.Position)
    end
end)

UserInput.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or
       inp.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ═══════════════ FLOAT ICON DRAGGING ═══════════════
local iconDragging, iconDragStart, iconStartPos = false, nil, nil

FloatIcon.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or
       inp.UserInputType == Enum.UserInputType.Touch then
        iconDragging  = true
        iconDragStart = inp.UserInputType == Enum.UserInputType.Touch
            and inp.Position or UserInput:GetMouseLocation()
        iconStartPos  = FloatIcon.Position
    end
end)

UserInput.InputChanged:Connect(function(inp)
    if not iconDragging then return end
    local pos
    if inp.UserInputType == Enum.UserInputType.MouseMovement then
        pos = UserInput:GetMouseLocation()
    elseif inp.UserInputType == Enum.UserInputType.Touch then
        pos = inp.Position
    end
    if pos then
        local delta = pos - iconDragStart
        local vp = Workspace.CurrentCamera.ViewportSize
        local nx = math.clamp(iconStartPos.X.Offset + delta.X, 0, vp.X - 48)
        local ny = math.clamp(iconStartPos.Y.Offset + delta.Y, 0, vp.Y - 48)
        FloatIcon.Position = UDim2.new(0, nx, 0, ny)
    end
end)

UserInput.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or
       inp.UserInputType == Enum.UserInputType.Touch then
        iconDragging = false
    end
end)

-- ═══════════════ MINIMIZE / RESTORE ═══════════════
MinBtn.MouseButton1Click:Connect(function()
    State.Minimized = true
    Tween(MainFrame, {Size = UDim2.new(0, WIN_W, 0, 0)}, 0.2, Enum.EasingStyle.Quint)
    task.delay(0.2, function()
        MainFrame.Visible = false
        FloatIcon.Visible = true
        -- Position float icon near minimize button
        local abs = MinBtn.AbsolutePosition
        FloatIcon.Position = UDim2.new(0, abs.X - 4, 0, abs.Y - 4)
    end)
end)

FloatIcon.MouseButton1Click:Connect(function()
    State.Minimized = false
    MainFrame.Visible = true
    FloatIcon.Visible = false
    MainFrame.Size    = UDim2.new(0, WIN_W, 0, 0)
    Tween(MainFrame, {Size = UDim2.new(0, WIN_W, 0, WIN_H)}, 0.25, Enum.EasingStyle.Back)
end)
FloatIcon.TouchTap:Connect(function()
    State.Minimized = false
    MainFrame.Visible = true
    FloatIcon.Visible = false
    MainFrame.Size    = UDim2.new(0, WIN_W, 0, 0)
    Tween(MainFrame, {Size = UDim2.new(0, WIN_W, 0, WIN_H)}, 0.25, Enum.EasingStyle.Back)
end)

-- ═══════════════ CHARACTER RE-CONNECT ═══════════════
lp.CharacterAdded:Connect(function(c)
    char = c
    hum  = c:WaitForChild("Humanoid")
    hrp  = c:WaitForChild("HumanoidRootPart")
    hum.WalkSpeed = State.WalkSpeed
    hum.JumpPower = State.JumpPower
end)

-- ═══════════════ BOOT ═══════════════
switchTab(1)

-- Opening animation
MainFrame.Size = UDim2.new(0, WIN_W, 0, 0)
MainFrame.Position = UDim2.new(0.5, -WIN_W/2, 0.5, 0)
Tween(MainFrame, {
    Size     = UDim2.new(0, WIN_W, 0, WIN_H),
    Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

notify("LT2 Menu loaded  🪓", T.Accent)
