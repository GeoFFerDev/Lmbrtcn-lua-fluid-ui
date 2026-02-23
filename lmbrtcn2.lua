--[[
     ██╗      ████████╗██████╗      ███████╗██╗  ██╗██████╗ ██╗      ██████╗ ██╗████████╗
     ██║      ╚══██╔══╝╚════██╗     ██╔════╝╚██╗██╔╝██╔══██╗██║     ██╔═══██╗██║╚══██╔══╝
     ██║         ██║    █████╔╝     █████╗   ╚███╔╝ ██████╔╝██║     ██║   ██║██║   ██║
     ██║         ██║   ██╔═══╝      ██╔══╝   ██╔██╗ ██╔═══╝ ██║     ██║   ██║██║   ██║
     ███████╗    ██║   ███████╗     ███████╗██╔╝ ██╗██║     ███████╗╚██████╔╝██║   ██║
     ╚══════╝    ╚═╝   ╚══════╝     ╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝   ╚═╝

    Lumber Tycoon 2  |  Joffer Hub v10.0  |  Toggle: RightCtrl  |  Mobile: tap LT icon

    ── v10 FIX NOTES (AXE DUPE — 3 BUGS FOUND & FIXED) ──────────────────────────────

    BUG 1 — WRONG ORDER (root cause of "land screen appears but no dupe"):
      v9 did: Equip axe → Save → Load → hope equipped axe survives reset.
      This is WRONG. Under FilteringEnabled (FE), setting axe.Parent = char
      from the client is a LOCAL GHOST — the server never sees it.
      When RequestLoad fires, the server destroys your entire character model.
      Both char children AND backpack are wiped. You ended up with exactly
      1 axe (the one restored by save). The land screen appeared because
      RequestLoad fired, but there was never a second axe anywhere.

    BUG 2 — MISSING DROP STEP (this is the actual dupe mechanic):
      Workspace objects survive a character reset. Only the character
      model and backpack are cleared by the server on reset/load.
      CORRECT ORDER:
        1. Save (while axe is in inventory — server records axe in save data)
        2. Drop axe into workspace via ClientInteracted:FireServer("Drop tool")
           (this is the confirmed remote from RBXLX ObjectInteractionClient)
        3. Load → character resets → land screen → axe restored from save
        4. The dropped axe is still in workspace exactly where it fell
        5. GrabTools picks it up → 2 axes total

    BUG 3 — WRONG REMOTE SIGNATURES:
      v9: RequestSave:InvokeServer(slot, LP)    ← LP arg rejected by server
          ClientMayLoad:InvokeServer(LP)         ← LP arg rejected by server
          RequestLoad:InvokeServer(slot, LP, nil) ← LP arg rejected by server
      FIXED:
          RequestSave:InvokeServer(slot)          ← matches LoadSaveClient source
          ClientMayLoad:InvokeServer()            ← no args, confirmed from RBXLX
          RequestLoad:InvokeServer(slot, nil)     ← no LP, confirmed from RBXLX
      Passing LP as an argument caused the server RemoteFunction to receive
      wrong parameter types, leading to silent rejection or wrong slot number.
--]]

-- ─────────────────────────────────────────────────────────────────
-- SERVICES
-- ─────────────────────────────────────────────────────────────────
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")

local LP    = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- ─────────────────────────────────────────────────────────────────
-- THEME
-- ─────────────────────────────────────────────────────────────────
local T = {
    WindowBG     = Color3.fromRGB(16,  20,  30),
    SidebarBG    = Color3.fromRGB(11,  14,  22),
    ContentBG    = Color3.fromRGB(20,  26,  36),
    ElementBG    = Color3.fromRGB(26,  33,  48),
    ElementHover = Color3.fromRGB(34,  44,  62),
    Accent       = Color3.fromRGB(0,   200, 175),
    AccentDim    = Color3.fromRGB(0,   130, 115),
    AccentText   = Color3.fromRGB(80,  230, 210),
    TextPri      = Color3.fromRGB(228, 234, 245),
    TextSec      = Color3.fromRGB(138, 155, 178),
    ToggleOn     = Color3.fromRGB(0,   200, 175),
    ToggleOff    = Color3.fromRGB(50,  62,  85),
    Thumb        = Color3.fromRGB(235, 240, 255),
    SliderTrack  = Color3.fromRGB(38,  48,  68),
    Separator    = Color3.fromRGB(30,  40,  58),
    Corner       = UDim.new(0, 7),
    SmallCorner  = UDim.new(0, 5),
    SidebarW     = 110,
    RowH         = 32,
    WinW         = 340,
    WinH         = 260,
}

-- ─────────────────────────────────────────────────────────────────
-- HELPERS
-- ─────────────────────────────────────────────────────────────────
local function New(cls, props, ch)
    local i = Instance.new(cls)
    for k, v in pairs(props or {}) do if k ~= "Parent" then i[k] = v end end
    for _, c in ipairs(ch or {}) do c.Parent = i end
    if props and props.Parent then i.Parent = props.Parent end
    return i
end
local function Corner(p, r)    return New("UICorner", {CornerRadius = r or T.Corner, Parent = p}) end
local function Stroke(p, c, w) return New("UIStroke", {Color = c, Thickness = w or 1, Parent = p}) end
local function Pad(p, t, b, l, r)
    return New("UIPadding", {
        PaddingTop=UDim.new(0,t or 6), PaddingBottom=UDim.new(0,b or 6),
        PaddingLeft=UDim.new(0,l or 10), PaddingRight=UDim.new(0,r or 10), Parent=p,
    })
end
local function List(p, dir, gap)
    return New("UIListLayout", {
        FillDirection=dir or Enum.FillDirection.Vertical, Padding=UDim.new(0,gap or 4),
        SortOrder=Enum.SortOrder.LayoutOrder, HorizontalAlignment=Enum.HorizontalAlignment.Left, Parent=p,
    })
end

local TI  = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TIF = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TIS = TweenInfo.new(0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local function Tw(o,p)  TweenService:Create(o,TI,p):Play() end
local function TwF(o,p) TweenService:Create(o,TIF,p):Play() end
local function TwS(o,p) TweenService:Create(o,TIS,p):Play() end

-- ─────────────────────────────────────────────────────────────────
-- DRAG HELPER
-- ─────────────────────────────────────────────────────────────────
local function MakeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset+d.X,
                startPos.Y.Scale, startPos.Y.Offset+d.Y
            )
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────
-- DESTROY OLD
-- ─────────────────────────────────────────────────────────────────
pcall(function()
    for _, parent in ipairs({
        (typeof(gethui)=="function" and gethui()) or false,
        game:GetService("CoreGui"),
        LP:FindFirstChild("PlayerGui"),
    }) do
        if parent then
            local old = parent:FindFirstChild("JofferHub")
            if old then old:Destroy() end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- SCREEN GUI
-- ─────────────────────────────────────────────────────────────────
local guiParent
pcall(function()
    if gethui then guiParent = gethui()
    else guiParent = game:GetService("CoreGui") end
end)
if not guiParent then guiParent = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui") end

local ScreenGui = New("ScreenGui", {
    Name="JofferHub", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset=true, DisplayOrder=999, Parent=guiParent,
})

-- ─────────────────────────────────────────────────────────────────
-- FLOATING ICON
-- ─────────────────────────────────────────────────────────────────
local Icon = New("Frame", {
    Name="FloatIcon", Size=UDim2.new(0,56,0,56), Position=UDim2.new(0,18,0.5,-28),
    BackgroundColor3=T.SidebarBG, BorderSizePixel=0, Visible=false, ZIndex=20, Parent=ScreenGui,
})
Corner(Icon, UDim.new(0,15)); Stroke(Icon, T.Accent, 2)
local IconBtn = New("TextButton", {
    Text="LT", Size=UDim2.new(1,0,0.72,0), BackgroundTransparency=1,
    Font=Enum.Font.GothamBold, TextSize=18, TextColor3=T.Accent, ZIndex=21, Parent=Icon,
})
New("TextLabel", {
    Text="Hub", Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,1,-15),
    BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=9, TextColor3=T.TextSec, ZIndex=21, Parent=Icon,
})
MakeDraggable(Icon, Icon)

-- ─────────────────────────────────────────────────────────────────
-- MAIN WINDOW
-- ─────────────────────────────────────────────────────────────────
local Main = New("Frame", {
    Name="Main", Size=UDim2.new(0,T.WinW,0,T.WinH), Position=UDim2.new(0.5,-T.WinW/2,0.1,20),
    BackgroundColor3=T.WindowBG, BorderSizePixel=0, ClipsDescendants=true, ZIndex=5, Parent=ScreenGui,
})
Corner(Main); Stroke(Main, Color3.fromRGB(38,52,72), 1)

local TBar = New("Frame", {Size=UDim2.new(1,0,0,32), BackgroundColor3=T.SidebarBG, BorderSizePixel=0, ZIndex=6, Parent=Main})
New("Frame", {Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), BackgroundColor3=T.Accent, BackgroundTransparency=0.55, BorderSizePixel=0, ZIndex=7, Parent=TBar})
local dot = New("Frame", {Size=UDim2.new(0,7,0,7), Position=UDim2.new(0,12,0.5,-3), BackgroundColor3=T.Accent, BorderSizePixel=0, ZIndex=7, Parent=TBar})
Corner(dot, UDim.new(1,0))
New("TextLabel", {Text="LT2 Exploit", Size=UDim2.new(0,120,1,0), Position=UDim2.new(0,26,0,0), BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=14, TextColor3=T.TextPri, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=7, Parent=TBar})
New("TextLabel", {Text="Joffer Hub v10.0  •  #13822889", Size=UDim2.new(0,200,1,0), Position=UDim2.new(0,152,0,0), BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=10, TextColor3=T.Accent, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=7, Parent=TBar})
MakeDraggable(TBar, Main)

local CloseBtn = New("TextButton", {Text="✕", Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,-34,0.5,-14), BackgroundColor3=Color3.fromRGB(185,55,55), BackgroundTransparency=0.35, Font=Enum.Font.GothamBold, TextSize=12, TextColor3=T.TextPri, BorderSizePixel=0, ZIndex=8, Parent=TBar})
Corner(CloseBtn, UDim.new(0,5))
local MinBtn = New("TextButton", {Text="─", Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,-66,0.5,-14), BackgroundColor3=T.ElementBG, BackgroundTransparency=0.35, Font=Enum.Font.GothamBold, TextSize=12, TextColor3=T.TextSec, BorderSizePixel=0, ZIndex=8, Parent=TBar})
Corner(MinBtn, UDim.new(0,5))

local Body = New("Frame", {Size=UDim2.new(1,0,1,-32), Position=UDim2.new(0,0,0,32), BackgroundTransparency=1, BorderSizePixel=0, Parent=Main})
local Sidebar = New("Frame", {Size=UDim2.new(0,T.SidebarW,1,0), BackgroundColor3=T.SidebarBG, BorderSizePixel=0, Parent=Body})
New("Frame", {Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,-1,0,0), BackgroundColor3=T.Separator, BorderSizePixel=0, Parent=Sidebar})
local TabListFrame = New("ScrollingFrame", {
    Size=UDim2.new(1,0,1,-6), Position=UDim2.new(0,0,0,6), BackgroundTransparency=1,
    ScrollBarThickness=0, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, Parent=Sidebar,
})
Pad(TabListFrame,4,4,5,5); List(TabListFrame,nil,2)
local Content = New("Frame", {Size=UDim2.new(1,-T.SidebarW,1,0), Position=UDim2.new(0,T.SidebarW,0,0), BackgroundColor3=T.ContentBG, BorderSizePixel=0, Parent=Body})
local PageContainer = New("Frame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Parent=Content})

local minimized = false
local function ShowMain()
    minimized=false; Icon.Visible=false; Main.Visible=true
    Main.Size=UDim2.new(0,0,0,0); TwS(Main,{Size=UDim2.new(0,T.WinW,0,T.WinH)})
end
local function ShowIcon()
    minimized=true
    local abs=MinBtn.AbsolutePosition; Icon.Position=UDim2.new(0,abs.X,0,abs.Y)
    TwF(Main,{Size=UDim2.new(0,0,0,0)})
    task.delay(0.22,function()
        Main.Visible=false; Icon.Visible=true; Icon.Size=UDim2.new(0,0,0,0)
        Icon.Position=UDim2.new(0,18,0.5,-28); TwS(Icon,{Size=UDim2.new(0,56,0,56)})
    end)
end
MinBtn.MouseButton1Click:Connect(ShowIcon)
MinBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then ShowIcon() end end)
IconBtn.MouseButton1Click:Connect(function() if minimized then ShowMain() end end)
IconBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch and minimized then ShowMain() end end)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
CloseBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then ScreenGui:Destroy() end end)
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode==Enum.KeyCode.RightControl then
        if minimized then ShowMain() else ShowIcon() end
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- TAB + COMPONENT FACTORY
-- ─────────────────────────────────────────────────────────────────
local Tabs = {}
local ActiveTab = nil

local function CreateTab(name, icon)
    local btn = New("TextButton", {
        Name=name, Size=UDim2.new(1,0,0,28), BackgroundColor3=T.ElementBG, BackgroundTransparency=1,
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=T.TextSec,
        Text=(icon or "  ").."  "..name, TextXAlignment=Enum.TextXAlignment.Left,
        BorderSizePixel=0, Parent=TabListFrame,
    })
    Corner(btn, T.SmallCorner); Pad(btn,0,0,9,6)
    local indicator = New("Frame", {
        Size=UDim2.new(0,3,0.55,0), Position=UDim2.new(0,0,0.225,0),
        BackgroundColor3=T.Accent, BorderSizePixel=0, Visible=false, Parent=btn,
    })
    Corner(indicator, UDim.new(0,2))
    local page = New("ScrollingFrame", {
        Name=name.."Page", Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        ScrollBarThickness=3, ScrollBarImageColor3=T.Accent,
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollingDirection=Enum.ScrollingDirection.Y,
        BottomImage="rbxasset://textures/ui/Scroll/scroll-middle.png",
        Visible=false, Parent=PageContainer,
    })
    Pad(page,8,0,10,10); List(page,nil,4)
    New("Frame",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,LayoutOrder=9999,Parent=page})

    local Tab = {Button=btn, Page=page, Indicator=indicator}

    function Tab:AddSection(text)
        local f=New("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Parent=page})
        New("TextLabel",{Text=text:upper(),Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=9,TextColor3=T.Accent,TextXAlignment=Enum.TextXAlignment.Left,Parent=f})
        New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=T.Separator,BorderSizePixel=0,Parent=f})
    end

    function Tab:AddToggle(text, opts, cb)
        opts=opts or {}; local state=opts.Default or false
        local row=New("Frame",{Size=UDim2.new(1,0,0,T.RowH),BackgroundColor3=T.ElementBG,BorderSizePixel=0,Parent=page})
        Corner(row)
        New("TextLabel",{Text=text,Size=UDim2.new(1,-56,1,0),Position=UDim2.new(0,11,0,0),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=12,TextColor3=T.TextPri,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
        local track=New("Frame",{Size=UDim2.new(0,38,0,20),Position=UDim2.new(1,-48,0.5,-10),BackgroundColor3=state and T.ToggleOn or T.ToggleOff,BorderSizePixel=0,Parent=row})
        Corner(track,UDim.new(1,0))
        local thumb=New("Frame",{Size=UDim2.new(0,14,0,14),Position=state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),BackgroundColor3=T.Thumb,BorderSizePixel=0,Parent=track})
        Corner(thumb,UDim.new(1,0))
        local function Set(s)
            state=s; Tw(track,{BackgroundColor3=state and T.ToggleOn or T.ToggleOff})
            Tw(thumb,{Position=state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)})
            if cb then pcall(cb,state) end
        end
        New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",Parent=row}).MouseButton1Click:Connect(function() Set(not state) end)
        row.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then Set(not state) end end)
        row.MouseEnter:Connect(function() Tw(row,{BackgroundColor3=T.ElementHover}) end)
        row.MouseLeave:Connect(function() Tw(row,{BackgroundColor3=T.ElementBG}) end)
        return {Set=Set, Get=function() return state end}
    end

    function Tab:AddSlider(text, opts, cb)
        opts=opts or {}; local mn=opts.Min or 0; local mx=opts.Max or 100; local step=opts.Step or 1; local val=opts.Default or mn
        local row=New("Frame",{Size=UDim2.new(1,0,0,50),BackgroundColor3=T.ElementBG,BorderSizePixel=0,Parent=page}); Corner(row)
        local topRow=New("Frame",{Size=UDim2.new(1,-22,0,22),Position=UDim2.new(0,11,0,6),BackgroundTransparency=1,Parent=row})
        New("TextLabel",{Text=text,Size=UDim2.new(1,-46,1,0),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=12,TextColor3=T.TextPri,TextXAlignment=Enum.TextXAlignment.Left,Parent=topRow})
        local valLbl=New("TextLabel",{Text=tostring(val),Size=UDim2.new(0,44,1,0),Position=UDim2.new(1,-44,0,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=T.Accent,TextXAlignment=Enum.TextXAlignment.Right,Parent=topRow})
        local track=New("Frame",{Size=UDim2.new(1,-22,0,5),Position=UDim2.new(0,11,0,34),BackgroundColor3=T.SliderTrack,BorderSizePixel=0,Parent=row}); Corner(track,UDim.new(1,0))
        local p0=(val-mn)/(mx-mn)
        local fill=New("Frame",{Size=UDim2.new(p0,0,1,0),BackgroundColor3=T.Accent,BorderSizePixel=0,Parent=track}); Corner(fill,UDim.new(1,0))
        local knob=New("Frame",{Size=UDim2.new(0,13,0,13),Position=UDim2.new(p0,-6,0.5,-6),BackgroundColor3=T.Thumb,BorderSizePixel=0,ZIndex=3,Parent=track}); Corner(knob,UDim.new(1,0))
        local function SetVal(v)
            v=math.clamp(math.round((v-mn)/step)*step+mn,mn,mx); val=v; local p=(v-mn)/(mx-mn)
            Tw(fill,{Size=UDim2.new(p,0,1,0)}); Tw(knob,{Position=UDim2.new(p,-6,0.5,-6)}); valLbl.Text=tostring(v); if cb then pcall(cb,v) end
        end
        local dragging=false
        local function drag(pos) local rel=math.clamp((pos.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1); SetVal(mn+rel*(mx-mn)) end
        track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; drag(i.Position) end end)
        UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then drag(i.Position) end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
        return {Set=SetVal, Get=function() return val end}
    end

    function Tab:AddButton(text, cb)
        local btn2=New("TextButton",{Size=UDim2.new(1,0,0,T.RowH),BackgroundColor3=T.ElementBG,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=T.Accent,Text=text,BorderSizePixel=0,Parent=page})
        Corner(btn2); Stroke(btn2,T.AccentDim,1)
        btn2.MouseEnter:Connect(function() Tw(btn2,{BackgroundColor3=T.ElementHover}) end)
        btn2.MouseLeave:Connect(function() Tw(btn2,{BackgroundColor3=T.ElementBG}) end)
        local function fire()
            Tw(btn2,{BackgroundColor3=T.AccentDim}); task.delay(0.14,function() Tw(btn2,{BackgroundColor3=T.ElementBG}) end)
            if cb then pcall(cb) end
        end
        btn2.MouseButton1Click:Connect(fire)
        btn2.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then fire() end end)
        return btn2
    end

    function Tab:AddDropdown(text, opts, cb)
        opts=opts or {}; local options=opts.Options or {}; local current=opts.Default or options[1] or "Select..."; local open=false
        local wrapper=New("Frame",{Size=UDim2.new(1,0,0,T.RowH),BackgroundTransparency=1,ClipsDescendants=false,Parent=page})
        local header=New("TextButton",{Size=UDim2.new(1,0,0,T.RowH),BackgroundColor3=T.ElementBG,Font=Enum.Font.Gotham,TextSize=12,TextColor3=T.TextPri,Text="",BorderSizePixel=0,Parent=wrapper}); Corner(header)
        New("TextLabel",{Text=text,Size=UDim2.new(0.5,-8,1,0),Position=UDim2.new(0,11,0,0),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=12,TextColor3=T.TextPri,TextXAlignment=Enum.TextXAlignment.Left,Parent=header})
        local valLbl=New("TextLabel",{Text=current,Size=UDim2.new(0.5,-28,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=11,TextColor3=T.Accent,TextXAlignment=Enum.TextXAlignment.Right,Parent=header})
        local arrow=New("TextLabel",{Text="▾",Size=UDim2.new(0,18,1,0),Position=UDim2.new(1,-20,0,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=T.TextSec,Parent=header})
        local ddW=200; local ddH=math.min(#options*30+8,148)
        local dd=New("Frame",{Size=UDim2.new(0,ddW,0,0),Position=UDim2.new(0,0,0,0),BackgroundColor3=T.ElementBG,BorderSizePixel=0,ClipsDescendants=false,Visible=false,ZIndex=50,Parent=ScreenGui}); Corner(dd); Stroke(dd,T.Accent,1)
        local ddScroll=New("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=T.Accent,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=51,Parent=dd})
        local itemFrame=New("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=51,Parent=ddScroll})
        Pad(itemFrame,3,3,4,4); List(itemFrame,nil,2)
        local function closeDD()
            open=false; arrow.Text="▾"
            TwF(dd,{Size=UDim2.new(0,dd.AbsoluteSize.X,0,0)})
            task.delay(0.22,function() dd.Visible=false end)
        end
        for _,opt in ipairs(options) do
            local ib=New("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=T.ElementBG,BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=11,TextColor3=T.TextSec,Text=opt,TextXAlignment=Enum.TextXAlignment.Left,BorderSizePixel=0,ZIndex=52,Parent=itemFrame}); Pad(ib,0,0,8,4); Corner(ib,T.SmallCorner)
            ib.MouseEnter:Connect(function() Tw(ib,{BackgroundTransparency=0.6,TextColor3=T.TextPri}) end)
            ib.MouseLeave:Connect(function() Tw(ib,{BackgroundTransparency=1,TextColor3=T.TextSec}) end)
            local function pick() current=opt; valLbl.Text=opt; closeDD(); if cb then pcall(cb,opt) end end
            ib.MouseButton1Click:Connect(pick)
            ib.InputBegan:Connect(function(i)
                if i.UserInputType~=Enum.UserInputType.Touch then return end
                local startPos=i.Position; local maxDelta=0
                local mc=UserInputService.InputChanged:Connect(function(mi) if mi.UserInputType==Enum.UserInputType.Touch then maxDelta=math.max(maxDelta,(mi.Position-startPos).Magnitude) end end)
                local ec; ec=UserInputService.InputEnded:Connect(function(ei) if ei.UserInputType==Enum.UserInputType.Touch then mc:Disconnect(); ec:Disconnect(); if maxDelta<20 then pick() end end end)
            end)
        end
        local function toggle()
            open=not open
            if open then
                local abs=header.AbsolutePosition; local absSize=header.AbsoluteSize; local panelW=absSize.X
                ddH=math.min(#options*30+8,148); dd.Size=UDim2.new(0,panelW,0,0)
                dd.Position=UDim2.new(0,abs.X,0,abs.Y+absSize.Y+2); dd.Visible=true
                TwF(dd,{Size=UDim2.new(0,panelW,0,ddH)}); arrow.Text="▴"
            else closeDD() end
        end
        UserInputService.InputBegan:Connect(function(i)
            if not open then return end
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                local mp=i.Position; local ddPos=dd.AbsolutePosition; local ddSz=dd.AbsoluteSize
                local hPos=header.AbsolutePosition; local hSz=header.AbsoluteSize
                local inDD=mp.X>=ddPos.X and mp.X<=ddPos.X+ddSz.X and mp.Y>=ddPos.Y and mp.Y<=ddPos.Y+ddSz.Y
                local inH=mp.X>=hPos.X and mp.X<=hPos.X+hSz.X and mp.Y>=hPos.Y and mp.Y<=hPos.Y+hSz.Y
                if not inDD and not inH then closeDD() end
            end
        end)
        header.MouseButton1Click:Connect(toggle)
        header.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then toggle() end end)
        return {Set=function(v) current=v; valLbl.Text=v end, Get=function() return current end}
    end

    function Tab:AddLabel(text)
        local row=New("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=T.ElementBG,BackgroundTransparency=0.55,BorderSizePixel=0,Parent=page}); Corner(row)
        local lbl=New("TextLabel",{Text=text,Size=UDim2.new(1,-22,1,0),Position=UDim2.new(0,11,0,0),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=11,TextColor3=T.TextSec,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Parent=row})
        return {Set=function(v) lbl.Text=v end}
    end

    local function Activate()
        for _,t in pairs(Tabs) do t.Page.Visible=false; t.Indicator.Visible=false; Tw(t.Button,{BackgroundTransparency=1,TextColor3=T.TextSec}) end
        page.Visible=true; indicator.Visible=true; Tw(btn,{BackgroundTransparency=0.82,TextColor3=T.TextPri}); ActiveTab=Tab
    end
    btn.MouseButton1Click:Connect(Activate)
    btn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then Activate() end end)
    btn.MouseEnter:Connect(function() if ActiveTab~=Tab then Tw(btn,{BackgroundTransparency=0.88}) end end)
    btn.MouseLeave:Connect(function() if ActiveTab~=Tab then Tw(btn,{BackgroundTransparency=1}) end end)
    Tabs[name]=Tab; return Tab
end

-- ═══════════════════════════════════════════════════════════════════
-- GAME LOGIC
-- ═══════════════════════════════════════════════════════════════════

-- ── Remote cache ─────────────────────────────────────────────────
local _Interaction, _TransactionsC2S, _TransactionsS2C, _LoadSaveRequests, _PropertyPurchasing

local function GetInteraction()
    if not _Interaction then _Interaction = ReplicatedStorage:FindFirstChild("Interaction") end
    return _Interaction
end
local function GetTransactionsC2S()
    if not _TransactionsC2S then
        local tr = ReplicatedStorage:FindFirstChild("Transactions")
        if tr then _TransactionsC2S = tr:FindFirstChild("ClientToServer") end
    end
    return _TransactionsC2S
end
local function GetLoadSave()
    if not _LoadSaveRequests then _LoadSaveRequests = ReplicatedStorage:FindFirstChild("LoadSaveRequests") end
    return _LoadSaveRequests
end
local function GetPropertyPurchasing()
    if not _PropertyPurchasing then _PropertyPurchasing = ReplicatedStorage:FindFirstChild("PropertyPurchasing") end
    return _PropertyPurchasing
end

-- ── Character helpers ─────────────────────────────────────────────
local function GetChar() return LP.Character end
local function GetHRP()  local c = GetChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum()  local c = GetChar(); return c and c:FindFirstChildOfClass("Humanoid") end

-- ── Flags ─────────────────────────────────────────────────────────
local Flags = {
    Fly=false, Noclip=false, AutoChop=false, AutoSell=false,
    InfJump=false, SpeedVal=16, JumpVal=50, FlySpeed=50,
    AlwaysDay=false, AlwaysNight=false,
    SelWood="Any", AutoBuyRunning=false, AutBuyItem="Rukiryaxe",
}

LP.CharacterAdded:Connect(function(c)
    task.wait(1)
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = Flags.SpeedVal; h.JumpPower = Flags.JumpVal end
end)

-- ═══════════════════════════════════════════════════════════════════
-- SAFE TELEPORT
-- ═══════════════════════════════════════════════════════════════════
local function SafeTeleport(cf, retries)
    retries = retries or 3
    local hrp = GetHRP()
    local char = GetChar()
    if not hrp or not char then return end
    local collidable = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            collidable[part] = true; part.CanCollide = false
        end
    end
    local safeCF = cf + Vector3.new(0, 8, 0)
    for i = 1, retries do
        pcall(function()
            hrp.AssemblyLinearVelocity  = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = safeCF
        end)
        task.wait(0.15)
        if (hrp.Position - safeCF.Position).Magnitude < 15 then break end
    end
    task.delay(0.5, function()
        for part in pairs(collidable) do
            pcall(function() part.CanCollide = true end)
        end
        pcall(function()
            local h = GetHRP()
            if h then h.AssemblyLinearVelocity = Vector3.zero end
        end)
    end)
end

-- ── WAYPOINTS ─────────────────────────────────────────────────────
local Locations = {
    ["Spawn"]             = CFrame.new(163,    5,    58),
    ["Main Forest"]       = CFrame.new(300,    5,  -200),
    ["Wood Dropoff"]      = CFrame.new(322.5,  16,   97.1),
    ["Sell Wood"]         = CFrame.new(258,     8,   66.1),
    ["Wood R' Us"]        = CFrame.new(301.7,   5,   30),
    ["Land Store"]        = CFrame.new(284,     5,  -80),
    ["Car Store"]         = CFrame.new(508.6,  15, -1445),
    ["Fancy Furnishings"] = CFrame.new(507.6,  20, -1768.5),
    ["Snow Biome"]        = CFrame.new(1127,   75,  1882),
    ["Volcano Biome"]     = CFrame.new(-1684, 420,  1109),
    ["Swamp Biome"]       = CFrame.new(-1137, 155,  -996),
    ["Tropics / Ferry"]   = CFrame.new(4500,   20,   -80),
    ["Mountain"]          = CFrame.new(-862,  200,   -46),
}
local function TeleportTo(name)
    local cf = Locations[name]; if not cf then return end; SafeTeleport(cf)
end

-- ═══════════════════════════════════════════════════════════════════
-- WOOD DETECTION — FIXED v7
--
-- PROBLEM WITH OLD VERSION:
--   GetWoodPieces grabbed ANY BasePart with Size.Magnitude > 1 in
--   Workspace. This swept up furniture, glass doors, walls, floor
--   boards — everything. That's why TeleportWoodToMe pulled random
--   objects to you and why auto-sell failed (server rejected non-wood).
--
-- FIX — TWO-PASS SCAN:
--   Pass 1 — Standing trees: a Model with a BindableEvent child
--             (the CutEvent). These are whole uncut trees. IsTreeModel().
--   Pass 2 — Cut log sections: a Model that has a StringValue child
--             whose value matches a known wood type, AND has at least
--             one BasePart, AND has NO BindableEvent (already cut).
--             These are the sellable log pieces. IsWoodLog().
--
-- Real wood types confirmed from RBXLX TreeClass values:
--   Oak, Birch, Walnut, Koa, Palm, Pine, Fir, SnowGlow, Volcano,
--   GreenSwampy, GoldSwampy, Cherry — that's the complete list.
-- ═══════════════════════════════════════════════════════════════════

-- Known real tree type strings (from RBXLX TreeClass analysis)
local WOOD_TYPES = {
    Oak=true, Birch=true, Walnut=true, Koa=true, Palm=true, Pine=true, Fir=true,
    SnowGlow=true, Volcano=true, GreenSwampy=true, GoldSwampy=true, Cherry=true,
}

local function IsTreeModel(model)
    -- Standing tree: Model with a BindableEvent (CutEvent) AND a BasePart
    if not model:IsA("Model") then return false end
    local hasBE, hasBP = false, false
    for _, c in ipairs(model:GetChildren()) do
        if c:IsA("BindableEvent") then hasBE = true end
        if c:IsA("BasePart") then hasBP = true end
    end
    return hasBE and hasBP
end

local function IsWoodLog(model)
    -- Cut log section: Model with a known TreeClass StringValue, a BasePart,
    -- but NO BindableEvent (so it's already cut, not a standing tree).
    if not model:IsA("Model") then return false end
    local hasBP = false
    local hasBE = false
    local hasWoodClass = false
    for _, c in ipairs(model:GetChildren()) do
        if c:IsA("BindableEvent") then hasBE = true end
        if c:IsA("BasePart") then hasBP = true end
        if c:IsA("StringValue") and WOOD_TYPES[c.Value] then hasWoodClass = true end
    end
    -- Also check descendants for the StringValue (sometimes nested)
    if not hasWoodClass then
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("StringValue") and WOOD_TYPES[d.Value] then
                hasWoodClass = true; break
            end
        end
    end
    return hasBP and hasWoodClass and not hasBE
end

local function GetCutEvent(model)
    for _, c in ipairs(model:GetChildren()) do
        if c:IsA("BindableEvent") then return c end
    end
end

local function GetTreeClass(model)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("StringValue") and WOOD_TYPES[d.Value] then return d.Value end
    end
    return "Generic"
end

-- Returns only ACTUAL cut log Models (not furniture, not standing trees)
local function GetWoodLogs()
    local list = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if IsWoodLog(v) then table.insert(list, v) end
    end
    return list
end

-- Returns the main BasePart of a wood log model
local function GetLogPart(logModel)
    -- Prefer the largest BasePart
    local biggest, biggestMag = nil, 0
    for _, c in ipairs(logModel:GetChildren()) do
        if c:IsA("BasePart") then
            local m = c.Size.Magnitude
            if m > biggestMag then biggest = c; biggestMag = m end
        end
    end
    return biggest
end

-- ═══════════════════════════════════════════════════════════════════
-- SELLING — Wood log Models placed at SELLWOOD trigger
--
-- SELLWOOD wall: X=255.7, Y=3.9, Z=66.1, size 0.2 × 1.8 × 5.4
-- Server's Touched event on SELLWOOD fires when a WoodSection BasePart
-- contacts it. We move the whole log Model so its parts touch the wall.
-- Only real wood logs (IsWoodLog) are moved — no furniture/doors.
-- ═══════════════════════════════════════════════════════════════════
local SELLWOOD_POS = Vector3.new(255.7, 3.9, 66.1)

local function SellWood()
    local logs = GetWoodLogs()
    if #logs == 0 then warn("[JofferHub] No cut wood logs found."); return end

    -- Teleport player to sell zone first (server grants us network ownership of nearby parts)
    SafeTeleport(CFrame.new(258, 8, 66.1))
    task.wait(0.6)

    local n = 0
    for _, logModel in ipairs(logs) do
        if n >= 150 then break end
        pcall(function()
            -- Move the model into SELLWOOD trigger zone
            local bp = GetLogPart(logModel)
            if not bp then return end
            local row = math.floor(n / 5)
            local col = n % 5
            -- Position at SELLWOOD face, stacked vertically, spread across Z
            local targetCF = CFrame.new(
                256.0,               -- just past SELLWOOD X=255.7 face
                4.5 + row * 1.8,     -- stack upward
                63.5 + col * 1.1     -- spread across SELLWOOD Z span (~63.4 to 68.8)
            )
            -- Move entire model by offset from its primary part
            if logModel.PrimaryPart then
                logModel:SetPrimaryPartCFrame(targetCF)
            else
                logModel.PrimaryPart = bp
                logModel:SetPrimaryPartCFrame(targetCF)
            end
            bp.AssemblyLinearVelocity  = Vector3.zero
            bp.AssemblyAngularVelocity = Vector3.zero
        end)
        n = n + 1
        if n % 8 == 0 then task.wait(0.04) end
    end
    task.wait(1.2) -- let server detect all touches
end

-- ═══════════════════════════════════════════════════════════════════
-- TELEPORT WOOD TO ME — FIXED v7
-- Only teleports actual cut wood log Models. No more furniture/doors.
-- ═══════════════════════════════════════════════════════════════════
local function TeleportWoodToMe()
    local hrp = GetHRP(); if not hrp then return end
    local pos = hrp.Position
    local logs = GetWoodLogs()
    if #logs == 0 then warn("[JofferHub] No cut wood logs found."); return end
    local n = 0
    for _, logModel in ipairs(logs) do
        if n >= 100 then break end
        pcall(function()
            local bp = GetLogPart(logModel)
            if not bp then return end
            local targetCF = CFrame.new(
                pos.X + (n % 5) * 3 - 6,
                pos.Y + 2,
                pos.Z + math.floor(n / 5) * 3 - 6
            )
            if logModel.PrimaryPart then
                logModel:SetPrimaryPartCFrame(targetCF)
            else
                logModel.PrimaryPart = bp
                logModel:SetPrimaryPartCFrame(targetCF)
            end
            bp.AssemblyLinearVelocity  = Vector3.zero
            bp.AssemblyAngularVelocity = Vector3.zero
        end)
        n = n + 1
    end
    print("[JofferHub] Teleported "..n.." wood log(s) to you.")
end

-- ═══════════════════════════════════════════════════════════════════
-- MOVE TREES TO DROPOFF
-- Moves whole uncut tree Models near the Wood Dropoff zone.
-- ═══════════════════════════════════════════════════════════════════
local function DupeWood()
    local targetBase = Vector3.new(310, 12, 97)
    local moved = 0
    for _, v in ipairs(Workspace:GetDescendants()) do
        if moved >= 20 then break end
        if IsTreeModel(v) then
            pcall(function()
                local offset = Vector3.new((moved % 4) * 8, 0, math.floor(moved / 4) * 8)
                if v.PrimaryPart then
                    v:SetPrimaryPartCFrame(CFrame.new(targetBase + offset))
                else
                    local bp = v:FindFirstChildWhichIsA("BasePart")
                    if bp then bp.CFrame = CFrame.new(targetBase + offset) end
                end
            end)
            moved = moved + 1
        end
    end
    if moved == 0 then warn("[JofferHub] No tree models found. Load trees near your base first.") end
end

-- ═══════════════════════════════════════════════════════════════════
-- AUTO CHOP
-- Fires the CutEvent BindableEvent on the nearest matching tree.
-- ═══════════════════════════════════════════════════════════════════
local autoChopConn
local function StartAutoChop()
    if autoChopConn then autoChopConn:Disconnect() end
    autoChopConn = RunService.Heartbeat:Connect(function()
        if not Flags.AutoChop then return end
        local hrp = GetHRP(); if not hrp then return end
        local nearest, nearestDist, nearestCE = nil, 200, nil
        for _, v in ipairs(Workspace:GetDescendants()) do
            if IsTreeModel(v) then
                local tClass = GetTreeClass(v)
                local typeMatch = (Flags.SelWood == "Any") or (tClass == Flags.SelWood)
                if typeMatch then
                    local bp = v:FindFirstChildWhichIsA("BasePart")
                    if bp then
                        local d = (hrp.Position - bp.Position).Magnitude
                        if d < nearestDist then
                            nearest = v; nearestDist = d; nearestCE = GetCutEvent(v)
                        end
                    end
                end
            end
        end
        if nearest and nearestCE then
            -- Move player right next to the tree for range check
            local bp = nearest:FindFirstChildWhichIsA("BasePart")
            if bp and nearestDist > 10 then
                SafeTeleport(CFrame.new(bp.Position + Vector3.new(3, 2, 0)))
            end
            pcall(function() nearestCE:Fire() end)
        end
    end)
end
local function StopAutoChop()
    Flags.AutoChop = false
    if autoChopConn then autoChopConn:Disconnect(); autoChopConn = nil end
end

-- ── AUTO SELL LOOP ────────────────────────────────────────────────
local autoSellThread
local function StartAutoSell()
    Flags.AutoSell = true
    if autoSellThread then task.cancel(autoSellThread) end
    autoSellThread = task.spawn(function()
        while Flags.AutoSell do SellWood(); task.wait(5) end
    end)
end
local function StopAutoSell()
    Flags.AutoSell = false
    if autoSellThread then task.cancel(autoSellThread); autoSellThread = nil end
end

-- ── FUNDS ─────────────────────────────────────────────────────────
local function GetFunds()
    local c2s = GetTransactionsC2S(); if not c2s then return "?" end
    local rf = c2s:FindFirstChild("GetFunds")
    if rf and rf:IsA("RemoteFunction") then
        local ok, v = pcall(function() return rf:InvokeServer() end)
        if ok and v then return tostring(v) end
    end
    -- Fallback: read from leaderstats
    local ls = LP:FindFirstChild("leaderstats")
    if ls then local m = ls:FindFirstChild("Money"); if m then return tostring(m.Value) end end
    return "?"
end

-- ── BUY AXE ───────────────────────────────────────────────────────
local autoBuyThread
local function BuyAxe(item)
    SafeTeleport(CFrame.new(301.7, 13, 57.5)); task.wait(1.2)
    local c2s = GetTransactionsC2S()
    if c2s then
        local rf = c2s:FindFirstChild("AttemptPurchase")
        if rf and rf:IsA("RemoteFunction") then
            local ok, result = pcall(function() return rf:InvokeServer(item) end)
            if ok then print("[JofferHub] Purchase:", tostring(result)) end
        end
    end
end
local function StartAutoBuy(item, amount)
    Flags.AutoBuyRunning = true
    if autoBuyThread then task.cancel(autoBuyThread) end
    autoBuyThread = task.spawn(function()
        local done = 0
        while Flags.AutoBuyRunning and done < amount do BuyAxe(item); done = done + 1; task.wait(2) end
        Flags.AutoBuyRunning = false
    end)
end
local function StopAutoBuy()
    Flags.AutoBuyRunning = false
    if autoBuyThread then task.cancel(autoBuyThread); autoBuyThread = nil end
end


-- ═══════════════════════════════════════════════════════════════════
-- AXE DUPE — v10 CORRECT METHOD (verified against RBXLX decompile)
--
-- ── WHY v9 WAS BROKEN (3 fatal bugs) ─────────────────────────────
--
--  BUG 1 — WRONG ORDER (root cause of "only land screen, no dupe"):
--    v9 did:  Equip axe → Save → Load → (hope axe survives reset)
--    The "equipped axe survives reset" theory is FALSE under FE.
--    When RequestLoad fires, the SERVER destroys your entire character
--    model. Setting axe.Parent = char client-side is a local ghost —
--    the server never sees it because FE blocks unauthorised parent
--    changes from the client. The reset wipes both char and backpack.
--    Result: you end up with exactly 1 axe (the one restored by save).
--    The land screen appeared because RequestLoad fired, but there
--    was never a second axe to collect.
--
--  BUG 2 — MISSING DROP STEP (the actual mechanic):
--    The real dupe mechanic (confirmed from RBXLX DropTool logic):
--      • Items physically in WORKSPACE survive a character reset because
--        they are not owned by the character. Only character children
--        and backpack contents are wiped on reset.
--      • Drop the axe into workspace BEFORE saving/loading.
--      • Save (server records: you have axe in inventory — it was in
--        backpack at save time before the drop was registered... wait,
--        actually the correct order is: Save FIRST while axe is in
--        inventory, THEN drop it, THEN load. That way:
--          - Save recorded: axe is yours
--          - Drop: axe leaves inventory, now sits in workspace
--          - Load: character resets, save restores axe to backpack
--          - Workspace axe is still there (it was never in char)
--          - GrabTools picks it up → 2 axes
--
--  BUG 3 — WRONG REMOTE SIGNATURES:
--    v9 called:  RequestSave:InvokeServer(slot, LP)
--                ClientMayLoad:InvokeServer(LP)
--                RequestLoad:InvokeServer(slot, LP, nil)
--    From RBXLX LoadSaveClient decompile, the actual client calls are:
--                RequestSave:InvokeServer(slot)
--                ClientMayLoad:InvokeServer()      ← no args
--                RequestLoad:InvokeServer(slot, nil)  ← no LP arg
--    Passing LP as an argument causes the server RemoteFunction to
--    receive the wrong parameter types → silent rejection/wrong slot.
--
-- ── CORRECT SEQUENCE (Save → Drop → Load → Grab) ─────────────────
--   1. Find axe in backpack or character
--   2. Save to slot   — server records: axe is in your inventory
--   3. Drop axe       — fire ClientInteracted("Drop tool") so the
--                       server physically drops the handle to workspace
--                       (confirmed remote from RBXLX ObjectInteraction)
--   4. Wait ~1.5s     — let server process the drop
--   5. Load slot      — character resets + land selection screen appears
--   6. Confirm plot   — (manual, normal LT2 flow)
--   7. Wait for CharacterAdded + settle
--   8. GrabTools(120) — pick up the workspace axe that survived reset
--   Result: backpack axe (restored by load) + grabbed workspace axe = 2
-- ═══════════════════════════════════════════════════════════════════
local axeDupeThread
local axeDupeRunning = false

local function GrabTools(radius)
    radius = radius or 40
    local hrp = GetHRP(); if not hrp then return end
    local grabbed = 0
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Tool") then
            local h = v:FindFirstChild("Handle")
            if h and (hrp.Position - h.Position).Magnitude < radius then
                pcall(function() v.Parent = LP.Backpack end)
                grabbed = grabbed + 1
            end
        end
    end
    print("[JofferHub] GrabTools: picked up "..grabbed.." tool(s) within "..radius.." studs.")
    return grabbed
end

-- Drop axe via the confirmed ClientInteracted remote (RBXLX ObjectInteractionClient)
-- FireServer(tool, "Drop tool", handle.CFrame)
-- This is the exact same path LT2's own drop-tool button uses.
local function DropToolRemote(tool)
    if not tool then return false end
    local h = tool:FindFirstChild("Handle")
    if not h then return false end
    local ci = GetInteraction()
    if not ci then
        -- Fallback: parent directly to workspace (works on some executors)
        pcall(function() tool.Parent = Workspace end)
        return false, "ClientInteracted not found — used parent fallback"
    end
    local evt = ci:FindFirstChild("ClientInteracted")
    if not evt then
        pcall(function() tool.Parent = Workspace end)
        return false, "ClientInteracted event missing — used parent fallback"
    end
    local ok, err = pcall(function()
        evt:FireServer(tool, "Drop tool", h.CFrame)
    end)
    return ok, ok and "OK" or tostring(err)
end

local function DropAllAxes()
    local char = GetChar()
    local hrp  = GetHRP()
    -- Drop from backpack
    for _, tool in ipairs(LP.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local ok, msg = DropToolRemote(tool)
            if not ok then
                -- fallback: move to workspace manually
                pcall(function()
                    tool.Parent = Workspace
                    local h = tool:FindFirstChild("Handle")
                    if h and hrp then
                        h.CFrame = hrp.CFrame * CFrame.new(math.random(-3,3), 1, math.random(-3,3))
                    end
                end)
            end
            task.wait(0.1)
        end
    end
    -- Drop from character (currently equipped)
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local ok = DropToolRemote(tool)
                if not ok then pcall(function() tool.Parent = Workspace end) end
                task.wait(0.1)
            end
        end
    end
    print("[JofferHub] DropAllAxes: done.")
end

-- saveSlot = slot number to save+load (1-6). Both operations use the same slot.
--            Using the same slot is the standard method and is correct.
local function StartAxeDupe(saveSlot, _unused)
    if axeDupeRunning then warn("[JofferHub] Dupe already running."); return end
    saveSlot = saveSlot or 1

    axeDupeThread = task.spawn(function()
        axeDupeRunning = true

        -- ── Pre-flight checks ──────────────────────────────────────
        local char = GetChar()
        local hrp  = GetHRP()
        if not char or not hrp then
            warn("[JofferHub] No character found."); axeDupeRunning = false; return
        end

        -- Find axe — prefer the one already equipped (in char), else backpack
        local axe = char:FindFirstChildWhichIsA("Tool")
        if not axe then axe = LP.Backpack:FindFirstChildWhichIsA("Tool") end
        if not axe then
            warn("[JofferHub] No tool found! Have an axe in your backpack or hand.")
            axeDupeRunning = false; return
        end
        print("[JofferHub] Axe found: ["..axe.Name.."] in ["..axe.Parent.Name.."]")

        -- ── STEP 1 — SAVE (axe must be in inventory at this moment) ──
        -- The server records your current inventory. The axe is still in
        -- backpack/char here so the save data will include it.
        local ls = GetLoadSave()
        if not ls then
            warn("[JofferHub] LoadSaveRequests folder not found in ReplicatedStorage.")
            axeDupeRunning = false; return
        end

        local saveRF = ls:FindFirstChild("RequestSave")
        if not saveRF or not saveRF:IsA("RemoteFunction") then
            warn("[JofferHub] RequestSave RemoteFunction not found.")
            axeDupeRunning = false; return
        end

        print("[JofferHub] (1/4) Saving to slot "..saveSlot.."...")
        -- FIXED SIGNATURE: InvokeServer(slotNumber) only — no LP argument
        local saveOk, saveRes = pcall(function()
            return saveRF:InvokeServer(saveSlot)
        end)
        print("[JofferHub] RequestSave → ok="..tostring(saveOk).."  res="..tostring(saveRes))
        if not saveOk or saveRes == false then
            warn("[JofferHub] Save FAILED. Ensure you own a land plot and try again.")
            axeDupeRunning = false; return
        end
        task.wait(1.5) -- let server commit the save to datastore

        -- ── STEP 2 — DROP AXE INTO WORKSPACE ─────────────────────────
        -- After saving, we drop the axe. It now lives in workspace.
        -- When the character resets in Step 4, workspace objects are
        -- NOT cleared — only the character model and backpack are wiped.
        -- This is the axe copy that will survive the reset.
        print("[JofferHub] (2/4) Dropping axe into workspace...")
        local dropOk, dropMsg = DropToolRemote(axe)
        print("[JofferHub] Drop → "..tostring(dropMsg))
        task.wait(1.5) -- let server process the drop before we load

        -- ── STEP 3 — CHECK LOAD PERMISSION ────────────────────────────
        local mayRF = ls:FindFirstChild("ClientMayLoad")
        if not mayRF or not mayRF:IsA("RemoteFunction") then
            warn("[JofferHub] ClientMayLoad RemoteFunction not found.")
            axeDupeRunning = false; return
        end
        print("[JofferHub] (3/4) Checking load permission...")
        -- FIXED SIGNATURE: InvokeServer() with no arguments
        local mayOk, mayRes = pcall(function() return mayRF:InvokeServer() end)
        print("[JofferHub] ClientMayLoad → ok="..tostring(mayOk).."  res="..tostring(mayRes))
        if not mayOk or mayRes == false then
            warn("[JofferHub] Server denied load — wait 30s and try again (cooldown).")
            axeDupeRunning = false; return
        end

        -- ── STEP 4 — REQUEST LOAD (triggers reset + land screen) ──────
        local loadRF = ls:FindFirstChild("RequestLoad")
        if not loadRF or not loadRF:IsA("RemoteFunction") then
            warn("[JofferHub] RequestLoad RemoteFunction not found.")
            axeDupeRunning = false; return
        end
        print("[JofferHub] (4/4) Loading slot "..saveSlot.."...")
        print("[JofferHub] ★ Character will reset. Land selection screen will appear.")
        print("[JofferHub] ★ Click your land plot to confirm — then wait ~5s for auto-grab.")

        -- FIXED SIGNATURE: InvokeServer(slot, nil) — no LP argument
        pcall(function() loadRF:InvokeServer(saveSlot, nil) end)

        -- ── STEP 5 — WAIT FOR RESPAWN ─────────────────────────────────
        -- CharacterAdded fires when the server has reset and respawned us.
        -- The land screen confirmation is manual — we wait generously.
        local newChar = LP.CharacterAdded:Wait()
        print("[JofferHub] Character respawned. Waiting for land screen confirmation...")
        task.wait(6) -- 6s buffer: land screen + LT2 load settle time

        -- ── STEP 6 — GRAB THE DROPPED AXE ────────────────────────────
        -- The axe we dropped in Step 2 is still in workspace exactly
        -- where it fell. GrabTools parents it to our backpack.
        local newHRP = newChar and newChar:FindFirstChild("HumanoidRootPart")
        if newHRP then
            -- Teleport to where the axe dropped so we're within range
            pcall(function()
                -- Find the dropped tool in workspace
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("Tool") and v.Name == axe.Name then
                        local h = v:FindFirstChild("Handle")
                        if h then
                            newHRP.CFrame = CFrame.new(h.Position + Vector3.new(0, 4, 0))
                            task.wait(0.3)
                            break
                        end
                    end
                end
            end)
        end

        local grabbed = GrabTools(60)
        task.wait(0.5)

        -- Count total tools to confirm success
        local total = 0
        for _, t in ipairs(LP.Backpack:GetChildren()) do if t:IsA("Tool") then total += 1 end end
        local c2 = GetChar()
        if c2 then for _, t in ipairs(c2:GetChildren()) do if t:IsA("Tool") then total += 1 end end end

        if total >= 2 then
            print("[JofferHub] ✓ DUPE SUCCESS — Total tools: "..total..". Run again to stack more.")
        else
            print("[JofferHub] ✗ Tools found: "..total..". The dropped axe may be out of range.")
            print("[JofferHub]   Use 'Grab Nearby Tools' with a larger radius, or run dupe again.")
        end
        axeDupeRunning = false
    end)
end

local function StopAxeDupe()
    axeDupeRunning = false
    if axeDupeThread then task.cancel(axeDupeThread); axeDupeThread = nil end
    print("[JofferHub] Dupe stopped.")
end

-- ═══════════════════════════════════════════════════════════════════
-- PLOT SYSTEM
-- ═══════════════════════════════════════════════════════════════════
local function GetMyPlot()
    local props = Workspace:FindFirstChild("Properties"); if not props then return nil end
    for _, plot in ipairs(props:GetChildren()) do
        local ow = plot:FindFirstChild("Owner")
        if ow and ow.Value == LP then return plot end
    end
    return nil
end

local function BaseHelp()
    local plot = GetMyPlot()
    if not plot then warn("[JofferHub] No owned plot found. Buy land first."); return end
    for _, v in ipairs(plot:GetDescendants()) do
        if v:IsA("BasePart") then SafeTeleport(CFrame.new(v.Position + Vector3.new(0, 10, 0))); return end
    end
end

-- ── CLAIM FREE LAND ──────────────────────────────────────────────
-- Finds an unclaimed plot, teleports you there, and invokes SelectLoadPlot.
local function FreeLand()
    local props = Workspace:FindFirstChild("Properties"); if not props then return end
    for _, plot in ipairs(props:GetChildren()) do
        local ow = plot:FindFirstChild("Owner")
        if ow and not ow.Value then
            -- Find the plot's base position
            local origin = plot:FindFirstChild("OriginSquare") or plot:FindFirstChild("Square")
            local dest
            if origin and origin:IsA("BasePart") then
                dest = CFrame.new(origin.Position + Vector3.new(0, 10, 0))
            else
                for _, v in ipairs(plot:GetDescendants()) do
                    if v:IsA("BasePart") then dest = CFrame.new(v.Position + Vector3.new(0, 10, 0)); break end
                end
            end
            if dest then
                SafeTeleport(dest); task.wait(0.8)
                local pp = GetPropertyPurchasing()
                if pp then
                    local rf = pp:FindFirstChild("SelectLoadPlot")
                    if rf and rf:IsA("RemoteFunction") then
                        local ok, r = pcall(function() return rf:InvokeServer() end)
                        print("[JofferHub] SelectLoadPlot:", ok, tostring(r))
                    end
                end
                return
            end
        end
    end
    warn("[JofferHub] No unclaimed plots found.")
end

-- ── EXPAND LAND TO MAX ───────────────────────────────────────────
-- Fires ClientExpandedProperty 20× to push your plot to max size.
-- Each fire expands by one step. LT2 max is typically 20 expansions.
local function ExpandMaxLand()
    local pp = GetPropertyPurchasing()
    if not pp then warn("[JofferHub] PropertyPurchasing not found."); return end
    local evt = pp:FindFirstChild("ClientExpandedProperty")
    if not evt or not evt:IsA("RemoteEvent") then
        warn("[JofferHub] ClientExpandedProperty remote not found."); return
    end
    -- Fire 20 times with a short delay to avoid throttle
    local fired = 0
    for i = 1, 20 do
        pcall(function() evt:FireServer() end)
        fired = fired + 1
        task.wait(0.15)
    end
    print("[JofferHub] Expand fired "..fired.."× — land should be at max size now.")
end

-- ── FORCE SAVE ───────────────────────────────────────────────────
local function ForceSave()
    local ls = GetLoadSave(); if not ls then return end
    local rf = ls:FindFirstChild("RequestSave")
    if rf and rf:IsA("RemoteFunction") then pcall(function() rf:InvokeServer() end) end
end

-- ── STEAL PLOT ───────────────────────────────────────────────────
local function StealPlot(playerName)
    local target = Players:FindFirstChild(playerName); if not target then return end
    local props  = Workspace:FindFirstChild("Properties"); if not props then return end
    for _, plot in ipairs(props:GetChildren()) do
        local ow = plot:FindFirstChild("Owner")
        if ow and ow.Value == target then
            local origin = plot:FindFirstChild("OriginSquare") or plot:FindFirstChild("Square")
            if origin and origin:IsA("BasePart") then
                SafeTeleport(CFrame.new(origin.Position + Vector3.new(0, 5, 0))); task.wait(0.8)
                local pp = GetPropertyPurchasing()
                if pp then
                    local rf = pp:FindFirstChild("SelectLoadPlot")
                    if rf and rf:IsA("RemoteFunction") then pcall(function() rf:InvokeServer() end) end
                end
            end
            return
        end
    end
end

-- ── FLY ──────────────────────────────────────────────────────────
local flyConn, flyBV, flyBG
local function StartFly()
    local hrp = GetHRP(); if not hrp then return end
    flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce=Vector3.new(1e5,1e5,1e5); flyBV.Velocity=Vector3.zero; flyBV.Parent=hrp
    flyBG = Instance.new("BodyGyro"); flyBG.MaxTorque=Vector3.new(9e9,9e9,9e9); flyBG.CFrame=hrp.CFrame; flyBG.Parent=hrp
    flyConn = RunService.Heartbeat:Connect(function()
        if not Flags.Fly then return end
        local h2=GetHRP(); if not h2 then return end
        local cam=Workspace.CurrentCamera; local dir=Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
        flyBV.Velocity=dir.Magnitude>0 and dir.Unit*Flags.FlySpeed or Vector3.zero
        flyBG.CFrame=cam.CFrame
    end)
end
local function StopFly()
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if flyBV   then flyBV:Destroy();     flyBV=nil  end
    if flyBG   then flyBG:Destroy();     flyBG=nil  end
end

-- ── NOCLIP ───────────────────────────────────────────────────────
local noclipConn
local function SetNoclip(s)
    if s then
        noclipConn = RunService.Stepped:Connect(function()
            local c=GetChar(); if not c then return end
            for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
        local c=GetChar(); if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end
    end
end

-- INFINITE JUMP
UserInputService.JumpRequest:Connect(function()
    if Flags.InfJump then local h=GetHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

-- LIGHTING LOOP
RunService.Heartbeat:Connect(function()
    if Flags.AlwaysDay then Lighting.ClockTime=14; Lighting.Brightness=2
    elseif Flags.AlwaysNight then Lighting.ClockTime=0; Lighting.Brightness=0.5 end
end)

-- ═══════════════════════════════════════════════════════════════════
-- BUILD TABS
-- ═══════════════════════════════════════════════════════════════════

-- PLAYER TAB
local PlayerTab = CreateTab("Player","👤")
PlayerTab:AddSection("Movement")
PlayerTab:AddSlider("Walk Speed",{Min=1,Max=150,Default=16,Step=1},function(v)
    Flags.SpeedVal=v; local h=GetHum(); if h then h.WalkSpeed=v end
end)
PlayerTab:AddSlider("Jump Power",{Min=0,Max=250,Default=50,Step=1},function(v)
    Flags.JumpVal=v; local h=GetHum(); if h then h.JumpPower=v end
end)
PlayerTab:AddToggle("Infinite Jump",{Default=false},function(v) Flags.InfJump=v end)
PlayerTab:AddToggle("Noclip",{Default=false},function(v) Flags.Noclip=v; SetNoclip(v) end)
PlayerTab:AddSection("Flight")
PlayerTab:AddSlider("Fly Speed",{Min=10,Max=300,Default=50,Step=5},function(v) Flags.FlySpeed=v end)
PlayerTab:AddToggle("Fly  (WASD + Space/LShift)",{Default=false},function(v)
    Flags.Fly=v; if v then StartFly() else StopFly() end
end)
PlayerTab:AddSection("Misc")
PlayerTab:AddButton("Reset Character",function() local h=GetHum(); if h then h.Health=0 end end)
PlayerTab:AddButton("Grab Nearby Tools", function() GrabTools(30) end)
local fundsLbl = PlayerTab:AddLabel("Funds: press Refresh")
PlayerTab:AddButton("Refresh Funds",function() fundsLbl:Set("Funds: $"..GetFunds()) end)

-- SLOT TAB
local SlotTab = CreateTab("Slot","🏠")
SlotTab:AddSection("Base & Land")
SlotTab:AddButton("Teleport → My Base", BaseHelp)
SlotTab:AddButton("Claim Free Land", FreeLand)
SlotTab:AddButton("Expand Land → Max",function()
    ExpandMaxLand()
end)
SlotTab:AddSection("Save")
SlotTab:AddButton("Force Save", ForceSave)
SlotTab:AddSection("Steal Plot")
local stealOpts = {}
for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then table.insert(stealOpts, p.Name) end end
if #stealOpts == 0 then stealOpts = {"(no other players)"} end
local stealDrop = SlotTab:AddDropdown("Target Player",{Options=stealOpts,Default=stealOpts[1]})
SlotTab:AddButton("Steal Plot",function() StealPlot(stealDrop:Get()) end)

-- WORLD TAB
local WorldTab = CreateTab("World","🌍")
WorldTab:AddSection("Lighting")
WorldTab:AddToggle("Always Day",{Default=false},function(v) Flags.AlwaysDay=v; Flags.AlwaysNight=false; if v then Lighting.FogEnd=100000 end end)
WorldTab:AddToggle("Always Night",{Default=false},function(v) Flags.AlwaysNight=v; Flags.AlwaysDay=false end)
WorldTab:AddToggle("No Fog",{Default=false},function(v)
    if v then Lighting.FogEnd=100000; Lighting.FogStart=99999 else Lighting.FogEnd=1000; Lighting.FogStart=0 end
end)
WorldTab:AddToggle("Shadows",{Default=true},function(v) Lighting.GlobalShadows=v end)
WorldTab:AddSection("Quick Teleport")
WorldTab:AddButton("→ Spawn",             function() TeleportTo("Spawn") end)
WorldTab:AddButton("→ Wood Dropoff",      function() TeleportTo("Wood Dropoff") end)
WorldTab:AddButton("→ Sell Wood Zone",    function() TeleportTo("Sell Wood") end)
WorldTab:AddButton("→ Wood R' Us",        function() TeleportTo("Wood R' Us") end)
WorldTab:AddButton("→ Land Store",        function() TeleportTo("Land Store") end)
WorldTab:AddButton("→ Car Store",         function() TeleportTo("Car Store") end)
WorldTab:AddButton("→ Fancy Furnishings", function() TeleportTo("Fancy Furnishings") end)
WorldTab:AddButton("→ Main Forest",       function() TeleportTo("Main Forest") end)
WorldTab:AddButton("→ Snow Biome",        function() TeleportTo("Snow Biome") end)
WorldTab:AddButton("→ Volcano Biome",     function() TeleportTo("Volcano Biome") end)
WorldTab:AddButton("→ Swamp Biome",       function() TeleportTo("Swamp Biome") end)
WorldTab:AddButton("→ Tropics / Ferry",   function() TeleportTo("Tropics / Ferry") end)
WorldTab:AddButton("→ Mountain",          function() TeleportTo("Mountain") end)
WorldTab:AddSection("Teleport to Player")
local allP = {}
for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then table.insert(allP, p.Name) end end
if #allP == 0 then allP = {"(no other players)"} end
local tpPDrop = WorldTab:AddDropdown("Player",{Options=allP,Default=allP[1]})
WorldTab:AddButton("Teleport to Player",function()
    local tgt = Players:FindFirstChild(tpPDrop:Get())
    if not tgt or not tgt.Character then return end
    local root = tgt.Character:FindFirstChild("HumanoidRootPart")
    if root then SafeTeleport(root.CFrame * CFrame.new(3, 0, 0)) end
end)

-- WOOD TAB
local WoodTab = CreateTab("Wood","🪵")
WoodTab:AddSection("Auto Chop")
WoodTab:AddLabel("Moves near each tree and fires CutEvent")
local woodTypes = {"Any","Oak","Birch","Walnut","Koa","Palm","Pine","Fir","SnowGlow","Volcano","GreenSwampy","GoldSwampy","Cherry"}
WoodTab:AddDropdown("Target Wood",{Options=woodTypes,Default="Any"},function(v) Flags.SelWood=v end)
WoodTab:AddToggle("Auto Chop",{Default=false},function(v)
    Flags.AutoChop=v; if v then StartAutoChop() else StopAutoChop() end
end)
WoodTab:AddToggle("Auto Sell Wood",{Default=false},function(v)
    Flags.AutoSell=v; if v then StartAutoSell() else StopAutoSell() end
end)
WoodTab:AddSection("Manual Actions")
WoodTab:AddButton("Sell All Wood Now", SellWood)
WoodTab:AddButton("Teleport Wood → Me", TeleportWoodToMe)
WoodTab:AddButton("Move Trees → Dropoff", DupeWood)
WoodTab:AddSection("Info")
local treeLbl = WoodTab:AddLabel("Press Scan to count")
WoodTab:AddButton("Scan Trees & Logs",function()
    local trees, logs = 0, 0
    for _, v in ipairs(Workspace:GetDescendants()) do
        if IsTreeModel(v) then trees = trees + 1 end
        if IsWoodLog(v)   then logs  = logs  + 1 end
    end
    treeLbl:Set("Standing: "..trees.."  |  Cut logs: "..logs)
end)

-- AUTO BUY TAB
local BuyTab = CreateTab("Buy","💰")
BuyTab:AddSection("Quick Purchase")
BuyTab:AddButton("Rukiryaxe",        function() BuyAxe("Rukiryaxe") end)
BuyTab:AddButton("BluesteelAxe",     function() BuyAxe("BluesteelAxe") end)
BuyTab:AddButton("FireAxe",          function() BuyAxe("FireAxe") end)
BuyTab:AddButton("IceAxe",           function() BuyAxe("IceAxe") end)
BuyTab:AddButton("CaveAxe",          function() BuyAxe("CaveAxe") end)
BuyTab:AddButton("SilverAxe",        function() BuyAxe("SilverAxe") end)
BuyTab:AddSection("Auto Buy Loop")
local shopItems = {"Rukiryaxe","BluesteelAxe","FireAxe","IceAxe","CaveAxe","RefinedAxe","SilverAxe"}
local buyItemDrop = BuyTab:AddDropdown("Item",{Options=shopItems,Default="Rukiryaxe"},function(v) Flags.AutBuyItem=v end)
local buyAmtSlider = BuyTab:AddSlider("Amount",{Min=1,Max=50,Default=1,Step=1})
BuyTab:AddToggle("Auto Buy Loop",{Default=false},function(v)
    if v then StartAutoBuy(Flags.AutBuyItem, buyAmtSlider:Get()) else StopAutoBuy() end
end)

-- DUPE TAB
local DupeTab = CreateTab("Dupe","📦")
DupeTab:AddSection("Axe Dupe")
DupeTab:AddLabel("STEP 1: Have an axe in backpack or hand")
DupeTab:AddLabel("STEP 2: Press Dupe Axe — script saves, drops, then loads")
DupeTab:AddLabel("STEP 3: Confirm land plot when screen appears")
DupeTab:AddLabel("STEP 4: Wait ~6s — script auto-grabs the dropped axe")
local slotSlider = DupeTab:AddSlider("Save/Load Slot",{Min=1,Max=6,Default=1,Step=1})
DupeTab:AddButton("▶ Dupe Axe",function()
    local s = slotSlider:Get()
    StartAxeDupe(s)
end)
DupeTab:AddButton("■ Stop",function()
    StopAxeDupe()
end)
DupeTab:AddSection("Helpers")
DupeTab:AddLabel("Grab Nearby: picks up tools in workspace around you")
DupeTab:AddButton("Grab Nearby Tools (60 stud)",  function() GrabTools(60)  end)
DupeTab:AddButton("Grab Nearby Tools (120 stud)", function() GrabTools(120) end)
DupeTab:AddButton("Drop All Tools (uses remote)", DropAllAxes)
DupeTab:AddSection("Wood Dupe")
DupeTab:AddButton("Move Trees → Dropoff", DupeWood)
DupeTab:AddButton("Sell Current Wood",    SellWood)

-- SETTINGS TAB
local SettingsTab = CreateTab("Settings","⚙")
SettingsTab:AddSection("Controls")
SettingsTab:AddLabel("PC: Right Ctrl = toggle  |  ─ = minimize")
SettingsTab:AddLabel("Mobile: Tap LT icon to restore window")
SettingsTab:AddLabel("Drag title bar or LT icon to move")
SettingsTab:AddSection("Feature Guide")
SettingsTab:AddLabel("FLY: WASD, Space=up, LShift=down")
SettingsTab:AddLabel("AXE DUPE: Have axe in backpack. Script: Save → Drop axe to world → Load → Confirm land → Auto-grab dropped axe.")
SettingsTab:AddLabel("WHY: Dropped axes survive character reset (workspace ≠ character). Saved axe restores on load = 2 total.")
SettingsTab:AddLabel("NOTE: Cloning tools client-side is impossible — server destroys them instantly (FilteringEnabled).")
SettingsTab:AddLabel("WOOD SELL: Moves cut logs (only) to SELLWOOD trigger at (255.7, 3.9, 66.1).")
SettingsTab:AddLabel("TP WOOD: Only teleports actual cut logs. No furniture or doors.")
SettingsTab:AddLabel("CLAIM FREE LAND: TPs to unclaimed plot + SelectLoadPlot remote.")
SettingsTab:AddLabel("EXPAND MAX LAND: Fires ClientExpandedProperty 20× to max plot size.")
SettingsTab:AddSection("Debug")
SettingsTab:AddButton("Reset Remote Cache",function()
    _Interaction=nil; _TransactionsC2S=nil; _TransactionsS2C=nil
    _LoadSaveRequests=nil; _PropertyPurchasing=nil
    print("[JofferHub] Remote cache cleared.")
end)
SettingsTab:AddButton("Rejoin Server",function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
end)
SettingsTab:AddButton("Destroy GUI",function() ScreenGui:Destroy() end)
SettingsTab:AddSection("About")
SettingsTab:AddLabel("Joffer Hub v10.0  |  LT2 #13822889")
SettingsTab:AddLabel("Remotes verified from deep RBXLX analysis")

-- ═══════════════════════════════════════════════════════════════════
-- ACTIVATE FIRST TAB + OPEN ANIMATION
-- ═══════════════════════════════════════════════════════════════════
task.defer(function()
    task.wait()
    for _, t in pairs(Tabs) do
        t.Page.Visible=false; t.Indicator.Visible=false
        t.Button.BackgroundTransparency=1; t.Button.TextColor3=T.TextSec
    end
    if Tabs["Player"] then
        local pt = Tabs["Player"]
        pt.Page.Visible=true; pt.Indicator.Visible=true
        pt.Button.BackgroundTransparency=0.82; pt.Button.TextColor3=T.TextPri
        ActiveTab=pt
    end
end)

Main.Size=UDim2.new(0,0,0,0); Main.BackgroundTransparency=1
TwF(Main,{BackgroundTransparency=0}); TwS(Main,{Size=UDim2.new(0,T.WinW,0,T.WinH)})

print("[JofferHub v10.0] Loaded! GUI → "..tostring(guiParent).." | RightCtrl = toggle")
print("[JofferHub] DUPE: Have axe in backpack → Dupe Axe → confirm land plot → auto-grabs dropped axe.")
