--[[
     ██╗      ████████╗██████╗      ███████╗██╗  ██╗██████╗ ██╗      ██████╗ ██╗████████╗
     ██║      ╚══██╔══╝╚════██╗     ██╔════╝╚██╗██╔╝██╔══██╗██║     ██╔═══██╗██║╚══██╔══╝
     ██║         ██║    █████╔╝     █████╗   ╚███╔╝ ██████╔╝██║     ██║   ██║██║   ██║
     ██║         ██║   ██╔═══╝      ██╔══╝   ██╔██╗ ██╔═══╝ ██║     ██║   ██║██║   ██║
     ███████╗    ██║   ███████╗     ███████╗██╔╝ ██╗██║     ███████╗╚██████╔╝██║   ██║
     ╚══════╝    ╚═╝   ╚══════╝     ╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝   ╚═╝

    Lumber Tycoon 2  |  Joffer Hub UI + Ancestor Logic Merge
--]]

local Executor = identifyexecutor and identifyexecutor() or "Unknown"
getgenv().Ancestor_Loaded = false

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer and game.Players.LocalPlayer:FindFirstChild('PlayerGui')

-- ─────────────────────────────────────────────────────────────────
-- ANCESTOR CORE INITIALIZATION
-- ─────────────────────────────────────────────────────────────────
local Maid, Ancestor, GUISettings, Connections = loadstring(game:HttpGetAsync('https://raw.githubusercontent.com/KhayneGleave/Ancestor/main/Maid.txt'))(), {
    SelectedTreeType             = 'Generic',
    BringTreeAmount              = 1,
    AutobuyAmount                = 1,
    AutobuySelectedItem          = 'Basic Hatchet',
    BringTreeSelectedPosition    = 'Current Position',
    RotatingObject               = false,
    Sprinting                    = false,
    ModerationType               = 'Vehicle',
    ModerationAction             = 'Kill',
    InventoryDuplicationAmount   = 1,
    PropertyToDuplicate          = 1,
    PlayerToDuplicatePropertyTo  = game.Players:GetPlayers()[1],
    ModWoodSawmill               = nil,
    AutofarmTrees                = false,
    CharacterGodMode             = 'FirstTimeExecutionProtection',
    IsClientFlying               = false,
    TreeToDismember              = false,
    SelectedVehicleColourToSpawn = 'Dark red',
    CurrentlySavingOrLoading     = nil,
    DonatingProperty             = false,
    SpawnItemsAmount             = 1,
    SpawnItemName                = 'BasicHatchet',
    ModdingWood                  = false
}, {
    WalkSpeed                          = 16,
    JumpPower                          = 50,
    HipHeight                          = 0,
    SprintSpeed                        = 20,
    FOV                                = 70,
    InfiniteJump                       = false,
    SelectedDropType                   = 'Both',
    Light                              = false,
    SprintKey                          = 'LeftShift',
    NoclipKey                          = 'LeftControl',
    KeyTP                              = 'G',
    FastCheckout                       = false,
    FixCashierRange                    = false,
    HardDragger                        = false,
    AxeRangeActive                     = false,
    AxeSwingActive                     = false,
    FlyKey                             = 'F',
    WaterWalk                          = false,
    WaterFloat                         = true,
    FlySprintSpeed                     = 10,
    AlwaysDay                          = false,
    AlwaysNight                        = false,
    NoFog                              = false,
    AxeSwing                           = 0,
    AxeRange                           = 0,
    FlySpeed                           = 200,
    CarSpeed                           = 1,
    CarPitch                           = 1,
    AntiAFK                            = (Executor ~= 'Krnl' and true) or false,
    TreesEnabled                       = true,
    StopPlayersLoading                 = false,
    SignDuplicationAmount              = 1,
    TeleportBackAfterBringTree         = true,
    FastRotate                         = false,
    XRotate                            = 1,
    YRotate                            = 1,
    SelectedTreeTypeSize               = 'Largest',
    ActivateVehicleModifications       = true,
    AutoSaveGUIConfiguration           = true,
    Brightness                         = 1,
    GlobalShadows                      = true,
    RejoinExecute                      = false,
    UnboxItems                         = false,
    FreeCamera                         = false,
    WaterGodMode                       = false,
    BetterGraphics                     = false,
    DropToolsAfterInventoryDuplication = false,
    InstantDropAxes                    = false,
    ClickDelete                        = false,
    SellPlankAfterMilling              = false,
    AutoStopOnPinkVehicle              = false,
    DeleteSpawnPadAfterVehicleSpawn    = false,
    AutoChopTrees                      = false,
    SitInAnyVehicle                    = false,
    ClickToSell                        = false
}, {}

local Players, TeleportService, UIS, CoreGui, StarterGui, Lighting, RunService, ReplicatedStorage, HttpService, PerformanceStats, UserInputService, Terrain = game:GetService('Players'), game:GetService('TeleportService'), game:GetService('UserInputService'), game:GetService('CoreGui'), game:GetService('StarterGui'), game:GetService('Lighting'), game:GetService('RunService'), game:GetService('ReplicatedStorage'), game:GetService('HttpService'), game:GetService('Stats').PerformanceStats, game:GetService('UserInputService'), workspace.Terrain

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
getgenv().Character = Player.Character or Player.CharacterAdded:Wait()
local PlayerGui, Camera = Player.PlayerGui, workspace.CurrentCamera

local Properties, Stores, PlayerModels = Workspace.Properties:GetChildren(), Workspace.Stores:GetChildren(), Workspace.PlayerModels

local NPCChattingClient = getsenv(PlayerGui.ChatGUI.NPCChattingClient)
local CharacterFloat = getsenv(PlayerGui.Scripts.CharacterFloat)
local PropertyPurchasingClient = getsenv(PlayerGui.PropertyPurchasingGUI.PropertyPurchasingClient)
local LoadSaveClient = getsenv(PlayerGui.LoadSaveGUI.LoadSaveClient)
local UserInput = getsenv(PlayerGui.Scripts.UserInput)
local SettingsClient = getsenv(PlayerGui.SettingsGUI.SettingsClient)
local InteractionPermission = require(ReplicatedStorage.Interaction.InteractionPermission)

local RequestLoad = ReplicatedStorage.LoadSaveRequests.RequestLoad
local RequestSave = ReplicatedStorage.LoadSaveRequests.RequestSave
local GetMetaData = ReplicatedStorage.LoadSaveRequests.GetMetaData
local ClientMayLoad = ReplicatedStorage.LoadSaveRequests.ClientMayLoad
local SendUserNotice = ReplicatedStorage.Notices.SendUserNotice
local ClientGetUserPermissions = ReplicatedStorage.Interaction.ClientGetUserPermissions
local ClientExpandedProperty = ReplicatedStorage.PropertyPurchasing.ClientExpandedProperty
local ClientPurchasedProperty = ReplicatedStorage.PropertyPurchasing.ClientPurchasedProperty
local ClientInteracted = ReplicatedStorage.Interaction.ClientInteracted
local ClientIsDragging = ReplicatedStorage.Interaction.ClientIsDragging
local RemoteProxy = ReplicatedStorage.Interaction.RemoteProxy
local PromptChat = ReplicatedStorage.NPCDialog.PromptChat
local PlayerChatted = ReplicatedStorage.NPCDialog.PlayerChatted
local SetChattingValue = ReplicatedStorage.NPCDialog.SetChattingValue
local TestPing = ReplicatedStorage.TestPing
local UpdateUserSettings = ReplicatedStorage.Interaction.UpdateUserSettings
local ClientPlacedStructure = ReplicatedStorage.PlaceStructure.ClientPlacedStructure
local SelectLoadPlot = ReplicatedStorage.PropertyPurchasing.SelectLoadPlot
local ClientPlacedBlueprint = ReplicatedStorage.PlaceStructure.ClientPlacedBlueprint
local DestroyStructure = ReplicatedStorage.Interaction.DestroyStructure

local LoadPass = getupvalue(LoadSaveClient.saveSlot, 12)
local AxeFolder, LogModels, ClientItemInfo, Util = ReplicatedStorage.AxeClasses, workspace.LogModels, ReplicatedStorage.ClientItemInfo, ReplicatedStorage:WaitForChild('Util', 10) 
local TransientFunctionCache = require(Util:WaitForChild('TransientFunctionCache', 10))

local VehicleColours = {'Dark red','Sand red','Sand yellow metalic','Lemon metalic','Gun metalic','Earth orange','Earth yellow','Brick yellow','Rust','Really black','Faded green','Sand green','Black metalic','Dark grey metallic','Dark grey','Silver','Medium stone grey','Mid grey', 'Hot pink'}

if not getgenv().UserCanInteract then
    getgenv().CharacterFloatOld = CharacterFloat.isInWater
    getgenv().UserCanInteract = InteractionPermission.UserCanInteract
    getgenv().BetterGraphicsEnabled = false
end

getgenv().LoadedTrees = {
    ['Update'] = function(_, Tree)
        LoadedTrees[#LoadedTrees + 1] = {Parent = Tree.Parent, Model = Tree}
        Tree.Parent = (GUISettings.TreesEnabled and Tree.Parent) or Lighting
    end
}

local CashiersAutobuy = {}
local CashierIDConnection = PromptChat.OnClientEvent:Connect(function(_, Cashier)
    if CashiersAutobuy[Cashier.Name] == nil then
        CashiersAutobuy[Cashier.Name] = Cashier.ID
    end
end)

Maid.Threads:Create(function()  
    SetChattingValue:InvokeServer(1)
    repeat Maid.Timer:Wait() until CashiersAutobuy['Hoover'] ~= nil
    CashierIDConnection:Disconnect()
    CashierIDConnection = nil
    SetChattingValue:InvokeServer(0)
end)

function Ancestor:DropTool(Axe)
    ClientInteracted:FireServer(Axe, 'Drop tool',Player.Character.PrimaryPart.CFrame)
end

function Ancestor:DropTools()
    Player.Character.Humanoid:UnequipTools()
    if GUISettings.InstantDropAxes then 
        Player.Character.Humanoid.Health = 0
        return
    end
    local Axes = self:GetAxes()
    for i = 1, #Axes do 
        self:DropTool(Axes[i])
        Maid.Timer:Wait(.125)
    end
end

function Ancestor:SellSigns()
    self:BringAll('PropertySoldSign', CFrame.new(315, 3, 85))
end

function Ancestor:CheckClientPrivilege(Player, Privilege)
    return TransientFunctionCache:New(function(...)
        return ClientGetUserPermissions:InvokeServer(...)
    end, 1, {ReturnOldResultInsteadOfYielding = true}).Callback(Player, Privilege)
end

function Ancestor:ApplyLight()
    if Player.Character.Head:FindFirstChild('PointLight') then
        return Player.Character.Head.PointLight:Destroy()
    end
    if not GUISettings.Light then return end
    local Light = Instance.new('PointLight', Player.Character.Head)
    Light.Range, Light.Brightness = 150, 1.7
end

function Ancestor:SetAxeRange(Active, Value)
    local Tool = Player.Character:FindFirstChildOfClass('Tool')
    if not Tool then return end
    local AttemptChop = getconnections(Tool.Activated)[1].Function
    local OldStats = getupvalues(AttemptChop)
    local NewStats = OldStats[1]
    NewStats.Range = (Active and Value) or require(AxeFolder:FindFirstChild('AxeClass_'..tostring(Tool.ToolName.Value))).new().Range
    setupvalue(AttemptChop, 1, NewStats)
end

function Ancestor:SetSwingCooldown(Active)
    local Tool = Player.Character:FindFirstChildOfClass('Tool')
    if not Tool then return end
    local AttemptChop = getconnections(Tool.Activated)[1].Function
    local OldStats = getupvalues(AttemptChop)
    local NewStats = OldStats[1]
    local Cooldown = require(AxeFolder:FindFirstChild('AxeClass_'..tostring(Tool.ToolName.Value))).new().SwingCooldown
    NewStats.SwingCooldown = (Active and Cooldown / 2) or Cooldown
    setupvalue(AttemptChop, 1, NewStats)
end

function Ancestor:GetAxes()
    local Axes = {}
    local Tools = self:MergeTables(Player.Backpack:GetChildren(), Player.Character:GetChildren())
    for i = 1, #Tools do
        local Axe = Tools[i]
        if Axe:FindFirstChild('CuttingTool') then
            Axes[#Axes + 1] = Axe
        end
    end
    return Axes
end

function Ancestor:MergeTables(Tbl, NewTbl)
    for Index, Value in next, Tbl do NewTbl[#NewTbl + 1] = Value end
    return NewTbl
end

function Ancestor:GetBestAxe()
    local Axes, BestAxe, BestDamage, Damage = {}, nil, 0, nil
    local Tools = self:MergeTables(Player.Backpack:GetChildren(),Player.Character:GetChildren())
    for i = 1, #Tools do 
        if Tools[i]:FindFirstChild('CuttingTool') then Axes[#Axes + 1] = Tools[i] end
    end
    for i = 1, #Axes do 
        local Axe = Axes[i]
        if Axe:FindFirstChild('ToolName') and AxeFolder:FindFirstChild('AxeClass_'..tostring(Axe.ToolName.Value)) then
            if self.SelectedTreeType == 'LoneCave' and Axe.ToolName.Value == 'EndTimesAxe' then return Axe end
            if self.SelectedTreeType == 'Volcano' and Axe.ToolName.Value == 'FireAxe' then return Axe end
            if self.SelectedTreeType == 'CaveCrawler' and Axe.ToolName.Value == 'CaveAxe' then return Axe end
            if self.SelectedTreeType == 'Frost' and Axe.ToolName.Value == 'IceAxe' then return Axe end
            if self.SelectedTreeType == 'GoldSwampy' and Axe.ToolName.Value == 'AxeSwamp' then return Axe end
            
            local AxeStats = require(AxeFolder:FindFirstChild('AxeClass_'..tostring(Axe.ToolName.Value))).new()
            if AxeStats.SpecialTrees and AxeStats.SpecialTrees[Ancestor.SelectedTreeType] then return Axe end
            Damage = AxeStats.Damage
            if Damage > BestDamage then BestDamage = Damage; BestAxe = Axe end
        end
    end
    return BestAxe
end

function Ancestor:Teleport(CF)
    repeat Maid.Timer:Wait() until Player.Character:FindFirstChild('HumanoidRootPart')
    xpcall(function()
        Player.Character.Humanoid.SeatPart.Parent:PivotTo(CF * CFrame.Angles(math.rad(Player.Character.Humanoid.SeatPart.Parent.PrimaryPart.Orientation.X), math.rad(Player.Character.Humanoid.SeatPart.Parent.PrimaryPart.Orientation.Y), math.rad(Player.Character.Humanoid.SeatPart.Parent.PrimaryPart.Orientation.Z)))
    end, function()
        Player.Character:PivotTo(CF)
    end)
end

function Ancestor:GetHitPoint(Axe)
    local AxeModule = require(AxeFolder['AxeClass_'..tostring(Axe.ToolName.Value)]).new()
    if self.SelectedTreeType == 'LoneCave' and Axe.ToolName.Value == 'EndTimesAxe' then return AxeModule.SpecialTrees.LoneCave.Damage end
    if self.SelectedTreeType == 'Volcano' and Axe.ToolName.Value == 'FireAxe' then return AxeModule.SpecialTrees.Volcano.Damage end
    return (AxeModule.SpecialTrees and AxeModule.SpecialTrees[self.SelectedTreeType] and AxeModule.SpecialTrees[self.SelectedTreeType].Damage) or AxeModule.Damage
end

function Ancestor:AttemptChop(Tree, Dismember)
    local Axe = self:GetBestAxe()
    if not Axe or not Tree or not Tree.Parent then return end
    local Hitpoint, CutEvent = self:GetHitPoint(Axe), Tree.Parent:FindFirstChild('CutEvent') or Tree:FindFirstChild('CutEvent')
    local WoodSections = tostring(Tree):match('WoodSection') and Tree.Parent:GetChildren() or Tree:GetChildren()
    local LowestIndex = 9e9
    local DismemberHeight
    for i = 1, #WoodSections do 
        local WoodSection = WoodSections[i]
        if tostring(WoodSection):match('WoodSection') and WoodSection.ID.Value < LowestIndex then
            LowestIndex = WoodSection.ID.Value
            DismemberHeight = WoodSection.Size.Y
        end
    end
    RemoteProxy:FireServer(CutEvent, {
        ['tool'] = Axe,
        ['faceVector'] = Vector3.new(1, 0, 0),
        ['height'] = (Dismember and DismemberHeight) or .3,
        ['sectionId'] = LowestIndex,
        ['hitPoints'] = Hitpoint,
        ['cooldown'] = .1,
        ['cuttingClass'] = 'Axe'
    })
end

function Ancestor:GetTree()
    local Largest, Smallest, LargestTree, SmallestTree, LargestIndex, SmallestIndex = 0, 9e9, nil, nil, nil, nil
    for i = 1, #LoadedTrees do
        if LoadedTrees[i] ~= nil then
            local Tree = LoadedTrees[i].Model
            if Tree and Tree:FindFirstChild('WoodSection') and Tree:FindFirstChild('TreeClass') and Tree.TreeClass.Value == Ancestor.SelectedTreeType then
                local Sections = Tree:GetChildren()
                local OriginWoodSection
                for j = 1, #Sections do 
                    local WoodSection = Sections[j]
                    if tostring(WoodSection):match('WoodSection') and WoodSection.ID.Value == 1 and WoodSection.Size.Y >= .6 then
                        OriginWoodSection = WoodSection
                    end
                end
                if OriginWoodSection then
                    if GUISettings.SelectedTreeTypeSize == 'Largest' and #Tree:GetChildren() >= Largest then 
                        Largest = #Tree:GetChildren()
                        LargestTree = OriginWoodSection
                        LargestIndex = i
                    elseif GUISettings.SelectedTreeTypeSize == 'Smallest' and #Tree:GetChildren() <= Smallest then 
                        Smallest = #Tree:GetChildren()
                        SmallestTree = OriginWoodSection
                        SmallestIndex = i
                    end
                end
            end
        end
    end
    local targetIndex = (GUISettings.SelectedTreeTypeSize == 'Largest' and LargestIndex) or SmallestIndex
    if targetIndex then LoadedTrees[targetIndex] = nil end
    return (GUISettings.SelectedTreeTypeSize == 'Largest' and LargestTree) or SmallestTree
end

function Ancestor:IsNetworkOwnerOfModel(Model)
    if (Executor == 'Krnl' or Executor == 'Fluxus' or Executor == 'Valyse') then 
        for i = 1, 4 do TestPing:InvokeServer() end
        return true
    end
    local Children = Model:GetChildren()
    for i = 1, #Children do 
        if Children[i]:IsA('BasePart') and isnetworkowner(Children[i]) then return true end
    end
    return false
end

function Ancestor:BringTree()
    local Tool = self:GetBestAxe()
    if not Player.Character or Player.Character:FindFirstChild('Humanoid') and Player.Character:FindFirstChild('Humanoid').Health <= 0 then return end
    if self.BringingTree then return SendUserNotice:Fire('You\'re Already Using This Feature!') end
    if not Tool then return SendUserNotice:Fire(string.format('You Need An %s Axe To Use This Feature!', (self.SelectedTreeType == 'LoneCave' and 'EndTimes') or '')) end

    local OldPos = (self.BringTreeSelectedPosition == 'Current Position' and Player.Character.HumanoidRootPart.CFrame) or (self.BringTreeSelectedPosition == 'Sell Point' and CFrame.new(315, 3, 85)) or (self.BringTreeSelectedPosition == 'Spawn' and CFrame.new(174, 15, 66))

    for i = 1, self.BringTreeAmount do
        self.BringingTree = true
        local Tree = self:GetTree()
        if not Tree then 
            self.BringingTree = false
            return SendUserNotice:Fire(string.format('There Are No %s Trees In This Server At The Moment!', self.SelectedTreeType))
        end

        Player.Character:SetPrimaryPartCFrame(CFrame.new(Tree.CFrame.p))
        
        local treeConn
        treeConn = LogModels.ChildAdded:Connect(function(LogTree)
            local Owner = LogTree:WaitForChild('Owner', 10)
            if Owner and Owner.Value == Player then
                if treeConn then treeConn:Disconnect() end
                LogTree.PrimaryPart = LogTree:WaitForChild('WoodSection', 10)
                for _ = 1, 25 do
                    ClientIsDragging:FireServer(LogTree)
                    LogTree:SetPrimaryPartCFrame(OldPos)
                    Maid.Timer:Wait()
                end
                repeat Maid.Timer:Wait() until self:IsNetworkOwnerOfModel(LogTree)
                for _ = 1, 25 do
                    ClientIsDragging:FireServer(LogTree)
                    LogTree:SetPrimaryPartCFrame(OldPos)
                    Maid.Timer:Wait()
                end
            end
        end)

        for _ = 1, 8 do TestPing:InvokeServer() end

        repeat Maid.Timer:Wait()
            self:AttemptChop(Tree)
            Player.Character.PrimaryPart.Anchored = not Player.Character.PrimaryPart.Anchored
            GUISettings.Noclip = true
        until not self:GetBestAxe()

        self.BringingTree = false
        Player.Character.PrimaryPart.Anchored = false
        GUISettings.Noclip = false
    end

    if GUISettings.TeleportBackAfterBringTree then 
        Player.Character:PivotTo(OldPos)
    end
end

-- ─────────────────────────────────────────────────────────────────
-- JOFFER HUB UI THEME & SETUP
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
    WinW         = 450,
    WinH         = 320,
}

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

local function MakeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)
end

pcall(function()
    for _, parent in ipairs({
        (typeof(gethui)=="function" and gethui()) or false,
        game:GetService("CoreGui"),
        Player:FindFirstChild("PlayerGui"),
    }) do
        if parent then
            local old = parent:FindFirstChild("JofferHub")
            if old then old:Destroy() end
        end
    end
end)

local guiParent = gethui and gethui() or game:GetService("CoreGui")
if not pcall(function() local _ = guiParent.Name end) then guiParent = Player:WaitForChild("PlayerGui") end

local ScreenGui = New("ScreenGui", {
    Name="JofferHub", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset=true, DisplayOrder=999, Parent=guiParent,
})

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
New("TextLabel", {Text="Joffer Hub UI + Ancestor V2 Logic", Size=UDim2.new(0,200,1,0), Position=UDim2.new(0,152,0,0), BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=10, TextColor3=T.Accent, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=7, Parent=TBar})
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
IconBtn.MouseButton1Click:Connect(function() if minimized then ShowMain() end end)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode==Enum.KeyCode.RightControl then
        if minimized then ShowMain() else ShowIcon() end
    end
end)

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
        track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; drag(i.Position) end end)
        UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then drag(i.Position) end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
        return {Set=SetVal, Get=function() return val end}
    end

    function Tab:AddButton(text, cb)
        local btn2=New("TextButton",{Size=UDim2.new(1,0,0,T.RowH),BackgroundColor3=T.ElementBG,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=T.Accent,Text=text,BorderSizePixel=0,Parent=page})
        Corner(btn2); Stroke(btn2,T.AccentDim,1)
        btn2.MouseButton1Click:Connect(function()
            Tw(btn2,{BackgroundColor3=T.AccentDim}); task.delay(0.14,function() Tw(btn2,{BackgroundColor3=T.ElementBG}) end)
            if cb then pcall(cb) end
        end)
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
            local function pick() current=opt; valLbl.Text=opt; closeDD(); if cb then pcall(cb,opt) end end
            ib.MouseButton1Click:Connect(pick)
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
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                local mp=i.Position; local ddPos=dd.AbsolutePosition; local ddSz=dd.AbsoluteSize
                local hPos=header.AbsolutePosition; local hSz=header.AbsoluteSize
                if not (mp.X>=ddPos.X and mp.X<=ddPos.X+ddSz.X and mp.Y>=ddPos.Y and mp.Y<=ddPos.Y+ddSz.Y) and not (mp.X>=hPos.X and mp.X<=hPos.X+hSz.X and mp.Y>=hPos.Y and mp.Y<=hPos.Y+hSz.Y) then closeDD() end
            end
        end)
        header.MouseButton1Click:Connect(toggle)
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
    Tabs[name]=Tab; return Tab
end

-- ─────────────────────────────────────────────────────────────────
-- BUILD TABS
-- ─────────────────────────────────────────────────────────────────

local PlayerTab = CreateTab("Player","👤")
PlayerTab:AddSection("Movement")
PlayerTab:AddSlider("Walk Speed", {Min=16, Max=400, Default=GUISettings.WalkSpeed}, function(v) GUISettings.WalkSpeed = v end)
PlayerTab:AddSlider("Jump Power", {Min=50, Max=400, Default=GUISettings.JumpPower}, function(v) GUISettings.JumpPower = v end)
PlayerTab:AddToggle("Infinite Jump", {Default=GUISettings.InfiniteJump}, function(v) GUISettings.InfiniteJump = v end)
PlayerTab:AddToggle("Noclip", {Default=GUISettings.Noclip}, function(v) GUISettings.Noclip = v end)
PlayerTab:AddSection("Misc")
PlayerTab:AddToggle("Anti-AFK", {Default=GUISettings.AntiAFK}, function(v) GUISettings.AntiAFK = v end)
PlayerTab:AddButton("BTools", function() Ancestor:BTools() end)
PlayerTab:AddButton("Safe Suicide", function() Ancestor:SafeSuicide() end)

local TeleportTab = CreateTab("Teleports","🌍")
TeleportTab:AddSection("Quick Teleports")
local locs = {'Spawn', 'Wood R Us', 'Land Store', 'Bridge', 'Dock', 'Palm', 'Cave', 'The Den', 'Volcano', 'Swamp', 'Fancy Furnishings', 'Boxed Cars', 'Links Logic', 'Bobs Shack', 'Fine Arts Store', 'Ice Mountain', 'Shrine Of Sight', 'Strange Man', 'Volcano Win', 'Ski Lodge', 'Fur Wood'}
local LocationsCFrames = {
    ['Wood R Us']         = CFrame.new(270, 4, 60),
    ['Spawn']             = CFrame.new(174, 10.5, 66),
    ['Land Store']        = CFrame.new(270, 3, -98),
    ['Bridge']            = CFrame.new(112, 37, -892),
    ['Dock']              = CFrame.new(1136, 0, -206),
    ['Palm']              = CFrame.new(2614, -4, -34),
    ['Cave']              = CFrame.new(3590, -177, 415),
    ['Volcano']           = CFrame.new(-1588, 623, 1069),
    ['Swamp']             = CFrame.new(-1216, 131, -822),
    ['Fancy Furnishings'] = CFrame.new(486, 3, -1722),
    ['Boxed Cars']        = CFrame.new(509, 3, -1458),
    ['Ice Mountain']      = CFrame.new(1487, 415, 3259),
    ['Links Logic']       = CFrame.new(4615, 7, -794),
    ['Bobs Shack']        = CFrame.new(292, 8, -2544),
    ['Fine Arts Store']   = CFrame.new(5217, -166, 721),
    ['Shrine Of Sight']   = CFrame.new(-1608, 195, 928),
    ['Strange Man']       = CFrame.new(1071, 16, 1141),
    ['Volcano Win']       = CFrame.new(-1667, 349, 147),
    ['Ski Lodge']         = CFrame.new(1244, 59, 2290),
    ['Fur Wood']          = CFrame.new(-1080, -5, -942),
    ['The Den']           = CFrame.new(330, 45, 1943),
}
local locDropdown = TeleportTab:AddDropdown("Location", {Options=locs, Default='Spawn'})
TeleportTab:AddButton("Teleport", function() Ancestor:Teleport(LocationsCFrames[locDropdown:Get()]) end)

local allP = {}
for _, p in ipairs(Players:GetPlayers()) do if p ~= Player then table.insert(allP, p.Name) end end
if #allP == 0 then allP = {"(no other players)"} end
TeleportTab:AddSection("Player Teleport")
local plrDrop = TeleportTab:AddDropdown("Player", {Options=allP, Default=allP[1]})
TeleportTab:AddButton("Teleport to Player", function()
    local t = Players:FindFirstChild(plrDrop:Get())
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
        Ancestor:Teleport(CFrame.new(t.Character.HumanoidRootPart.Position + Vector3.new(0,5,0)))
    end
end)

local WorldTab = CreateTab("World","⚙")
WorldTab:AddSection("Environment")
WorldTab:AddToggle("Always Day", {Default=GUISettings.AlwaysDay}, function(v) GUISettings.AlwaysDay = v end)
WorldTab:AddToggle("Always Night", {Default=GUISettings.AlwaysNight}, function(v) GUISettings.AlwaysNight = v end)
WorldTab:AddToggle("No Fog", {Default=GUISettings.NoFog}, function(v) GUISettings.NoFog = v end)
WorldTab:AddToggle("Global Shadows", {Default=GUISettings.GlobalShadows}, function(v) GUISettings.GlobalShadows = v end)
WorldTab:AddSection("Water")
WorldTab:AddToggle("Water Walk", {Default=GUISettings.WaterWalk}, function(v)
    GUISettings.WaterWalk = v
    for _, w in ipairs(workspace.Water:GetChildren()) do w.CanCollide = v end
end)

local WoodTab = CreateTab("Trees","🌲")
WoodTab:AddSection("Auto Chop / Bring")
local treeTypes = {'Generic','GoldSwampy','CaveCrawler','Cherry','Frost','Volcano','Oak','Walnut','Birch','SnowGlow','Fir','Pine','GreenSwampy','Koa','Palm','Spooky','SpookyNeon','LoneCave'}
WoodTab:AddDropdown("Tree Type", {Options=treeTypes, Default='Generic'}, function(v) Ancestor.SelectedTreeType = v end)
WoodTab:AddSlider("Quantity", {Min=1, Max=10, Default=1}, function(v) Ancestor.BringTreeAmount = v end)
WoodTab:AddButton("Bring Tree", function() Ancestor:BringTree() end)
WoodTab:AddSection("Actions")
WoodTab:AddButton("Sell Land Signs", function() Ancestor:SellSigns() end)

local AxeTab = CreateTab("Axe/Item","⛏")
AxeTab:AddSection("Axe Hacks")
AxeTab:AddSlider("Axe Range", {Min=1, Max=400, Default=GUISettings.AxeRange}, function(v) GUISettings.AxeRange = v; if GUISettings.AxeRangeActive then Ancestor:SetAxeRange(true, v) end end)
AxeTab:AddToggle("Activate Axe Range", {Default=GUISettings.AxeRangeActive}, function(v) GUISettings.AxeRangeActive = v; Ancestor:SetAxeRange(v, GUISettings.AxeRange) end)
AxeTab:AddToggle("No Axe Cooldown", {Default=GUISettings.AxeSwingActive}, function(v) GUISettings.AxeSwingActive = v; Ancestor:SetSwingCooldown(v) end)
AxeTab:AddSection("Item Dropping")
AxeTab:AddToggle("Instant Drop (Respawn)", {Default=GUISettings.InstantDropAxes}, function(v) GUISettings.InstantDropAxes = v end)
AxeTab:AddButton("Drop All Axes", function() Ancestor:DropTools() end)

local CarTab = CreateTab("Vehicle","🚗")
CarTab:AddSection("Modifications")
CarTab:AddSlider("Car Speed", {Min=1, Max=5, Default=GUISettings.CarSpeed}, function(v) GUISettings.CarSpeed = v end)
CarTab:AddSlider("Car Pitch", {Min=1, Max=10, Default=GUISettings.CarPitch}, function(v) GUISettings.CarPitch = v end)
CarTab:AddToggle("Activate Vehicle Mods", {Default=GUISettings.ActivateVehicleModifications}, function(v) GUISettings.ActivateVehicleModifications = v end)

-- ─────────────────────────────────────────────────────────────────
-- BACKGROUND LOOPS (from Ancestor)
-- ─────────────────────────────────────────────────────────────────
RunService.Stepped:Connect(function()
    if UIS:IsKeyDown(Enum.KeyCode[GUISettings.SprintKey]) then
        Player.Character.Humanoid.WalkSpeed = GUISettings.WalkSpeed + GUISettings.SprintSpeed
    else
        Player.Character.Humanoid.WalkSpeed = GUISettings.WalkSpeed
    end

    if GUISettings.Noclip then
        for _, p in ipairs(Player.Character:GetChildren()) do
            if p:IsA('BasePart') then p.CanCollide = false end
        end
    end

    Lighting.TimeOfDay = (GUISettings.AlwaysDay and '12:00:00') or (GUISettings.AlwaysNight and '2:00:00') or Lighting.TimeOfDay
    Lighting.GlobalShadows = GUISettings.GlobalShadows
    Lighting.FogEnd = (GUISettings.NoFog and 1000000) or Lighting.FogEnd

    pcall(function()
        Player.Character.Humanoid.JumpPower = GUISettings.JumpPower
    end)
end)

UIS.JumpRequest:Connect(function()
    if GUISettings.InfiniteJump then
        Player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- ACTIVATE FIRST TAB + OPEN ANIMATION
-- ─────────────────────────────────────────────────────────────────
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

print("[JofferHub + Ancestor Logic] Loaded successfully!")
