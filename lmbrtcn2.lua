--[[
     ██╗      ████████╗██████╗      ███████╗██╗  ██╗██████╗ ██╗      ██████╗ ██╗████████╗
     ██║      ╚══██╔══╝╚════██╗     ██╔════╝╚██╗██╔╝██╔══██╗██║     ██╔═══██╗██║╚══██╔══╝
     ██║         ██║    █████╔╝     █████╗   ╚███╔╝ ██████╔╝██║     ██║   ██║██║   ██║
     ██║         ██║   ██╔═══╝      ██╔══╝   ██╔██╗ ██╔═══╝ ██║     ██║   ██║██║   ██║
     ███████╗    ██║   ███████╗     ███████╗██╔╝ ██╗██║     ███████╗╚██████╔╝██║   ██║
     ╚══════╝    ╚═╝   ╚══════╝     ╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝   ╚═╝

    Lumber Tycoon 2  |  FULL Ancestor V2 Logic + Joffer Hub UI
--]]

local Executor = identifyexecutor and identifyexecutor() or "Unknown"
getgenv().Ancestor_Loaded = false

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer and game.Players.LocalPlayer:FindFirstChild('PlayerGui')

-- ─────────────────────────────────────────────────────────────────
-- ANCESTOR CORE INITIALIZATION & LOGIC VARIABLES
-- ─────────────────────────────────────────────────────────────────
local Maid = {Threads = {Create = function(_, f) task.spawn(f) end}, Timer = {Wait = task.wait}}
local Ancestor, GUISettings, Connections = {
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
    ModdingWood                  = false,
    SelectedBlueprint            = nil,
    SelectedPlank                = nil
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

local Players = game:GetService('Players')
local TeleportService = game:GetService('TeleportService')
local UIS = game:GetService('UserInputService')
local CoreGui = game:GetService('CoreGui')
local Lighting = game:GetService('Lighting')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local HttpService = game:GetService('HttpService')
local PerformanceStats = game:GetService('Stats').PerformanceStats
local Terrain = workspace.Terrain

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
getgenv().Character = Player.Character or Player.CharacterAdded:Wait()
local PlayerGui, Camera = Player.PlayerGui, workspace.CurrentCamera
local Properties, Stores, PlayerModels = workspace.Properties:GetChildren(), workspace.Stores:GetChildren(), workspace.PlayerModels

local NPCChattingClient = getsenv(PlayerGui.ChatGUI.NPCChattingClient)
local CharacterFloat = getsenv(PlayerGui.Scripts.CharacterFloat)
local PropertyPurchasingClient = getsenv(PlayerGui.PropertyPurchasingGUI.PropertyPurchasingClient)
local LoadSaveClient = getsenv(PlayerGui.LoadSaveGUI.LoadSaveClient)
local UserInput = getsenv(PlayerGui.Scripts.UserInput)
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

if not getgenv().UserCanInteract then
    getgenv().CharacterFloatOld = CharacterFloat.isInWater
    getgenv().UserCanInteract = InteractionPermission.UserCanInteract
end

getgenv().LoadedTrees = {
    ['Update'] = function(_, Tree)
        LoadedTrees[#LoadedTrees + 1] = { Parent = Tree.Parent, Model  = Tree }
        Tree.Parent = (GUISettings.TreesEnabled and Tree.Parent) or Lighting
    end
}

local CashiersAutobuy = {}
local CashierIDConnection = PromptChat.OnClientEvent:Connect(function(_, Cashier)
    if CashiersAutobuy[Cashier.Name] == nil then CashiersAutobuy[Cashier.Name] = Cashier.ID end
end)
Maid.Threads:Create(function()  
    SetChattingValue:InvokeServer(1)
    repeat Maid.Timer:Wait() until CashiersAutobuy['Hoover'] ~= nil
    CashierIDConnection:Disconnect(); CashierIDConnection = nil
    SetChattingValue:InvokeServer(0)
end)

-- ─────────────────────────────────────────────────────────────────
-- FULL ANCESTOR API FUNCTIONS
-- ─────────────────────────────────────────────────────────────────
function Ancestor:Teleport(CF)
    repeat Maid.Timer:Wait() until Player.Character:FindFirstChild('HumanoidRootPart')
    xpcall(function()
        if Player.Character.Humanoid.SeatPart then
            Player.Character.Humanoid.SeatPart.Parent:PivotTo(CF * CFrame.Angles(math.rad(Player.Character.Humanoid.SeatPart.Parent.PrimaryPart.Orientation.X), math.rad(Player.Character.Humanoid.SeatPart.Parent.PrimaryPart.Orientation.Y), math.rad(Player.Character.Humanoid.SeatPart.Parent.PrimaryPart.Orientation.Z)))
        else Player.Character:PivotTo(CF) end
    end, function() Player.Character:PivotTo(CF) end)
end

function Ancestor:GodMode(BruteForce, State)
    if not BruteForce and Ancestor.CharacterGodMode == 'FirstTimeExecutionProtection' then return end
    if (BruteForce and not State) or (not Ancestor.CharacterGodMode) then return self:SafeSuicide() end
    local OriginalHumanoidRootPartClone = Player.Character.HumanoidRootPart.RootJoint:Clone()
    local OriginalHumanoidRootPart = Player.Character.HumanoidRootPart.RootJoint
    OriginalHumanoidRootPartClone.Parent = Player.Character.HumanoidRootPart
    OriginalHumanoidRootPart.Parent = nil 
    OriginalHumanoidRootPartClone:Destroy()
    OriginalHumanoidRootPart.Parent = Player.Character
end

function Ancestor:SafeSuicide()
    xpcall(function() Player.Character.Head:Destroy() end, function() SendUserNotice:Fire('Character Is Already Dead.') end)
end

function Ancestor:ApplyLight()
    if Player.Character.Head:FindFirstChild('PointLight') then return Player.Character.Head.PointLight:Destroy() end
    if not GUISettings.Light then return end
    local Light = Instance.new('PointLight', Player.Character.Head); Light.Range, Light.Brightness = 150, 1.7
end

function Ancestor:MergeTables(Tbl, NewTbl)
    for _, Value in next, Tbl do NewTbl[#NewTbl + 1] = Value end
    return NewTbl
end

function Ancestor:GetAxes()
    local Axes = {}
    local Tools = self:MergeTables(Player.Backpack:GetChildren(), Player.Character:GetChildren())
    for i = 1, #Tools do
        if Tools[i]:FindFirstChild('CuttingTool') then Axes[#Axes + 1] = Tools[i] end
    end
    return Axes
end

function Ancestor:DropTool(Axe)
    ClientInteracted:FireServer(Axe, 'Drop tool', Player.Character.PrimaryPart.CFrame)
end

function Ancestor:DropTools()
    Player.Character.Humanoid:UnequipTools()
    if GUISettings.InstantDropAxes then Player.Character.Humanoid.Health = 0 return end
    local Axes = self:GetAxes()
    for i = 1, #Axes do 
        self:DropTool(Axes[i])
        Maid.Timer:Wait(.125)
    end
end

function Ancestor:GetBestAxe()
    local Axes, BestAxe, BestDamage, Damage = {}, nil, 0, nil
    local Tools = self:MergeTables(Player.Backpack:GetChildren(),Player.Character:GetChildren())
    for i = 1, #Tools do if Tools[i]:FindFirstChild('CuttingTool') then Axes[#Axes + 1] = Tools[i] end end
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

function Ancestor:SetAxeRange(Active, Value)
    local Tool = Player.Character:FindFirstChildOfClass('Tool')
    if not Tool then return end
    local AttemptChop = getconnections(Tool.Activated)[1].Function
    local Stats = getupvalues(AttemptChop)[1]
    Stats.Range = (Active and Value) or require(AxeFolder:FindFirstChild('AxeClass_'..tostring(Tool.ToolName.Value))).new().Range
    setupvalue(AttemptChop, 1, Stats)
end

function Ancestor:SetSwingCooldown(Active)
    local Tool = Player.Character:FindFirstChildOfClass('Tool')
    if not Tool then return end
    local AttemptChop = getconnections(Tool.Activated)[1].Function
    local Stats = getupvalues(AttemptChop)[1]
    local Cooldown = require(AxeFolder:FindFirstChild('AxeClass_'..tostring(Tool.ToolName.Value))).new().SwingCooldown
    Stats.SwingCooldown = (Active and Cooldown / 2) or Cooldown
    setupvalue(AttemptChop, 1, Stats)
end

function Ancestor:GetAllTrees()
    LoadedTrees = {['Update'] = function(_, Tree) LoadedTrees[#LoadedTrees + 1] = {Parent = Tree.Parent, Model = Tree}; Tree.Parent = (GUISettings.TreesEnabled and Tree.Parent) or Lighting end}
    local Children = workspace:GetChildren()
    for i = 1, #Children do
        if tostring(Children[i]):match('TreeRegion') then
            local Trees = Children[i]:GetChildren()
            for j = 1, #Trees do
                if Trees[j]:FindFirstChild('TreeClass') and #Trees[j]:GetChildren() >= 4 then
                    LoadedTrees[#LoadedTrees + 1] = {Parent = Trees[j].Parent, Model = Trees[j]}
                end
            end
        end
    end
    return LoadedTrees
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
                    if tostring(Sections[j]):match('WoodSection') and Sections[j].ID.Value == 1 and Sections[j].Size.Y >= .6 then
                        OriginWoodSection = Sections[j]
                    end
                end
                if OriginWoodSection then
                    if GUISettings.SelectedTreeTypeSize == 'Largest' and #Tree:GetChildren() >= Largest then 
                        Largest = #Tree:GetChildren(); LargestTree = OriginWoodSection; LargestIndex = i
                    elseif GUISettings.SelectedTreeTypeSize == 'Smallest' and #Tree:GetChildren() <= Smallest then 
                        Smallest = #Tree:GetChildren(); SmallestTree = OriginWoodSection; SmallestIndex = i
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

function Ancestor:GetHitPoint(Axe)
    local AxeModule = require(AxeFolder['AxeClass_'..tostring(Axe.ToolName.Value)]).new()
    if self.SelectedTreeType == 'LoneCave' and Axe.ToolName.Value == 'EndTimesAxe' then return AxeModule.SpecialTrees.LoneCave.Damage end
    if self.SelectedTreeType == 'Volcano' and Axe.ToolName.Value == 'FireAxe' then return AxeModule.SpecialTrees.Volcano.Damage end
    return (AxeModule.SpecialTrees and AxeModule.SpecialTrees[self.SelectedTreeType] and AxeModule.SpecialTrees[self.SelectedTreeType].Damage) or AxeModule.Damage
end

function Ancestor:AttemptChop(Tree, Dismember)
    local Axe = self:GetBestAxe()
    if not Axe or not Tree or not Tree.Parent then return end
    local Hitpoint = self:GetHitPoint(Axe)
    local CutEvent = Tree.Parent:FindFirstChild('CutEvent') or Tree:FindFirstChild('CutEvent')
    local WoodSections = tostring(Tree):match('WoodSection') and Tree.Parent:GetChildren() or Tree:GetChildren()
    local LowestIndex, DismemberHeight = 9e9, 0.3
    for i = 1, #WoodSections do 
        local WoodSection = WoodSections[i]
        if tostring(WoodSection):match('WoodSection') and WoodSection.ID.Value < LowestIndex then
            LowestIndex = WoodSection.ID.Value; DismemberHeight = WoodSection.Size.Y
        end
    end
    RemoteProxy:FireServer(CutEvent, {
        ['tool'] = Axe, ['faceVector'] = Vector3.new(1, 0, 0), ['height'] = (Dismember and DismemberHeight) or .3,
        ['sectionId'] = LowestIndex, ['hitPoints'] = Hitpoint, ['cooldown'] = .1, ['cuttingClass'] = 'Axe'
    })
end

function Ancestor:BringTree()
    local Tool = self:GetBestAxe()
    if not Player.Character or Player.Character:FindFirstChild('Humanoid') and Player.Character.Humanoid.Health <= 0 then return end
    if self.Autobuying then return SendUserNotice:Fire('Cannot Use While Autobuying.') end
    if self.BringingTree then return SendUserNotice:Fire('You\'re Already Using This Feature!') end
    if not Tool then return SendUserNotice:Fire('You Need An Axe To Use This Feature!') end
    
    local OldPos = (self.BringTreeSelectedPosition == 'Current Position' and Player.Character.HumanoidRootPart.CFrame) or (self.BringTreeSelectedPosition == 'Sell Point' and CFrame.new(315, 3, 85)) or (self.BringTreeSelectedPosition == 'Spawn' and CFrame.new(174, 15, 66)) or (self.BringTreeSelectedPosition == 'To Property' and self:GetPlayersBase() and self:GetPlayersBase().OriginSquare.CFrame + Vector3.new(0, 5, 0))
    if self.BringTreeSelectedPosition == 'To Property' and not self:GetPlayersBase() then return SendUserNotice:Fire('You Need A Property.') end

    local OldFly = Ancestor.IsClientFlying
    for i = 1, self.BringTreeAmount do
        if self.CurrentlySavingOrLoading then break end
        self.BringingTree = true
        local Tree = self:GetTree()
        if not Tree then 
            self.BringingTree = false; self.AutofarmTrees = false
            return SendUserNotice:Fire(string.format('There Are No %s Trees Left!', self.SelectedTreeType))
        end
        if self.SelectedTreeType == 'LoneCave' then self:GodMode(true, true) end
        
        Player.Character:SetPrimaryPartCFrame(CFrame.new(Tree.CFrame.p))
        
        local treeConn
        treeConn = LogModels.ChildAdded:Connect(function(LogTree)
            local Owner = LogTree:WaitForChild('Owner', 10)
            if Owner.Value == Player then
                if treeConn then treeConn:Disconnect() end
                if Ancestor.AutofarmTrees then self.ModWoodTree = LogTree; Maid.Timer:Wait(1); self:ModWood(true) end
                LogTree.PrimaryPart = LogTree:WaitForChild('WoodSection', 10)
                for _ = 1, (self.SelectedTreeType == 'LoneCave' and 140) or 25 do
                    ClientIsDragging:FireServer(LogTree)
                    LogTree:SetPrimaryPartCFrame(OldPos)
                    Maid.Timer:Wait()
                end
                repeat Maid.Timer:Wait() until self:IsNetworkOwnerOfModel(LogTree)
                for _ = 1, (self.SelectedTreeType == 'LoneCave' and 140) or 25 do
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
            if self.SelectedTreeType == 'LoneCave' or self.AutofarmTrees then 
                Player.Character:SetPrimaryPartCFrame(CFrame.new(Tree.CFrame.p + Vector3.new(4, 4, 4)))
            end
        until not self:GetBestAxe() or self.CurrentlySavingOrLoading or not treeConn.Connected

        self.BringingTree = false
        Player.Character.PrimaryPart.Anchored = false
        GUISettings.Noclip = false
    end

    if GUISettings.TeleportBackAfterBringTree then Player.Character:PivotTo(OldPos) end
    if self.SelectedTreeType == 'LoneCave' then self:SafeSuicide() end
end

function Ancestor:GetLava()
    local Lava = workspace['Region_Volcano']:GetChildren()
    for i = 1, #Lava do 
        if Lava[i]:FindFirstChild('Lava') and Lava[i].Lava.CFrame == CFrame.new(-1675.2002, 255.002533, 1284.19983, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268) then return Lava[i] end
    end
end
local LavaPart = Ancestor:GetLava()

function Ancestor:ModWood(BruteForce)
    if self.ModdingWood then return SendUserNotice:Fire('You\'re Already Using This Feature.') end
    local OldPosition = Player.Character.HumanoidRootPart.CFrame
    if not self:GetBestAxe() then return SendUserNotice:Fire('You Need An Axe To Use This Feature') end
    if not BruteForce then
        -- Assuming target is selected via another function
        if not self.ModWoodTree or not self.ModWoodSawmill then return SendUserNotice:Fire('Select a tree and sawmill first.') end
    end
    self.ModdingWood = true
    local Object = self.ModWoodTree
    local WoodSections, SmallestWoodSection, Size, MainSection, SellPointPiece = Object:GetDescendants(), nil, 9e9, nil, nil
    
    for i = 1, #WoodSections do 
        local WoodSection = WoodSections[i]
        if (self.ModWoodTree.TreeClass.Value == 'Pine' or self.ModWoodTree.TreeClass.Value == 'Fir') then 
            if tostring(WoodSection):match('WoodSection') and WoodSection.Size.X <= Size and WoodSection.Size.X >= .5 then 
                Size = WoodSection.Size.X; SmallestWoodSection = WoodSection
            end
        elseif not (self.ModWoodTree.TreeClass.Value == 'Pine' or self.ModWoodTree.TreeClass.Value == 'Fir') and tostring(WoodSection):match('WoodSection') and WoodSection.ID.Value >= 3 and WoodSection:FindFirstChild('ParentID') then  
            Size = WoodSection.Size.X; SmallestWoodSection = WoodSection
        end
    end
    if not SmallestWoodSection then self.ModdingWood = false; return SendUserNotice:Fire('This Tree Is Not Moddable.') end
    for i = 1, #WoodSections do 
        local WoodSection = WoodSections[i]
        if tostring(WoodSection):match('WoodSection') and WoodSection.ID.Value == SmallestWoodSection.ParentID.Value and WoodSection.Parent == SmallestWoodSection.Parent then SellPointPiece = WoodSection end
        if tostring(WoodSection):match('WoodSection') and WoodSection.ID.Value == 1 then MainSection = WoodSection end
    end
    Object.PrimaryPart = SellPointPiece
    if (Player.Character.Head.CFrame.p - MainSection.CFrame.p).Magnitude >= 5 then 
        repeat Maid.Timer:Wait(); self:Teleport(CFrame.new(MainSection.CFrame.p + Vector3.new(0, 5, 0))) until (Player.Character.Head.CFrame.p - MainSection.CFrame.p).Magnitude <= 10
    end
    repeat Maid.Timer:Wait(); ClientIsDragging:FireServer(Object) until self:IsNetworkOwnerOfModel(Object)
    
    self:Teleport(MainSection.CFrame)
    repeat Maid.Timer:Wait()
        for i = 1, 25 do 
            ClientIsDragging:FireServer(Object); Object:PivotTo(CFrame.new(-1425, 489, 1244))
            Object.PrimaryPart.Velocity = Vector3.new(); Object.PrimaryPart.RotVelocity = Vector3.new()
            Maid.Timer:Wait()
        end
        firetouchinterest(LavaPart.Lava, Object.PrimaryPart, 0); firetouchinterest(LavaPart.Lava, Object.PrimaryPart, 1)
    until Object.PrimaryPart:FindFirstChild('LavaFire')
    Object.PrimaryPart:FindFirstChild('LavaFire'):Destroy()

    for i = 1, 25 do ClientIsDragging:FireServer(Object); Object:PivotTo(CFrame.new(-1055, 291, -458)); Maid.Timer:Wait() end
    self:Teleport(CFrame.new(-1055, 291, -458))
    local SellPieceSold = false
    SellPointPiece.AncestryChanged:Connect(function() SellPieceSold = true end)
    Maid.Threads:Create(function()
        repeat Maid.Timer:Wait()
            for i = 1, 25 do Maid.Timer:Wait(); SellPointPiece.CFrame = CFrame.new(315, 0, 85); ClientIsDragging:FireServer(Object) end
        until SellPieceSold
    end)
    repeat Maid.Timer:Wait() until SellPieceSold
    self:Teleport(SmallestWoodSection.CFrame)
    
    for i = 1, #WoodSections do 
        if tostring(WoodSections[i]):match('WoodSection') and WoodSections[i] ~= SmallestWoodSection then Object.PrimaryPart = WoodSections[i] end
    end
    Maid.Threads:Create(function()
        repeat Maid.Timer:Wait(); ClientIsDragging:FireServer(Object) until self:IsNetworkOwnerOfModel(Object)
        for i = 1, 25 do
            if not self.ModWoodSawmill:IsDescendantOf(PlayerModels) then break end
            Maid.Timer:Wait(); SmallestWoodSection.CFrame = self.ModWoodSawmill.Particles.CFrame + Vector3.new(0, .5, 0); ClientIsDragging:FireServer(Object)
        end
    end)
    
    self:Teleport(CFrame.new(Object.PrimaryPart.CFrame.p + Vector3.new(0, 5, 4)))
    local Threshold = 0 
    repeat Maid.Timer:Wait()
        self:Teleport(CFrame.new(Object.WoodSection.CFrame.p + Vector3.new(0, 0, 5)))
        self:AttemptChop(Object)
        for i = 1, 40 do
            Maid.Timer:Wait(); SmallestWoodSection.CFrame = self.ModWoodSawmill.Particles.CFrame; ClientIsDragging:FireServer(Object)
            if (SmallestWoodSection.CFrame.p - self.ModWoodSawmill.Particles.CFrame.p).Magnitude <= 10 then Threshold = Threshold + 1; if Threshold >= 45 then break end end
        end
    until not Object or not Object.Parent

    self:Teleport(OldPosition)
    self.ModdingWood = false
end

function Ancestor:GetStoreItems()
    return {
        'Basic Hatchet - $12', 'Switch Conveyor - $320', 'Funnel Conveyor - $60', 'Fair Sawmill - $1600', 'Basic Door - $100', 'Steep Stairs - $140', 'Stairs - $100', '1 / 4 Wedge - $80', 'Mundane Chair - $60', '2 / 4 Wedge - $100', 'Corrugated Wall Corner Stub - $30', 'Shabby Sawmill - $130', '4 / 4 Wedge - $140', '3 / 4 Wedge - $120', 'Wood Sweeper - $430', 'Conveyor Supports - $12', 'Tilted Conveyor - $95', 'Half Door - $60', 'Work Light - $80', 'Smooth Wall Stub - $40', 'Straight Conveyor - $80', 'Tight Turn Conveyor - $100', 'Turn Conveyor Supports - $20', 'Post - $30', 'Corrugated Wall - $100', 'Sawmax 01 - $11000', 'Short Smooth Wall Corner - $50', 'Smooth Wall - $100', 'Short Fence - $50', 'Fence - $80', 'Small Floor - $20', 'Small Tile - $20', 'Corrugate Wall Stub - $40', 'Short Corrugated Wall - $60', 'Short Corrugated Wall Corner - $50', 'Corrugated Wall Corner - $80', 'Corrugated Wall - $60', 'Smooth Wall Corner Stub - $30', 'Smooth Wall Stub - $30', 'Short Smooth Wall - $60', 'Smooth Wall - $60', 'Smooth Wall Corner - $80', 'Short Fence - $30', 'Short Fence Corner - $40', 'Fence Corner - $30', 'Plain Axe - $90', 'Large Floor - $180', 'Floor - $60', 'Large Tile - $80', 'Tile - $20', 'Fence - $50', 'Steel Axe - $190', '3 / 3 Wedge - $100', 'Square Table - $80', 'Long Table - $140', 'Ladder - $60', 'Tiny Tile - $20', 'Tiny Floor - $20', 'Bag of Sand - $1600', 'Sawmax 02 - $22500', 'Hardened Axe - $550', 'Wire - $205', 'Chop Saw - $12200', 'Silver Axe - $2040', 'Straight Conveyor Switch Right - $480', 'Button - $320', 'Pressure Plate - $640', 'Straight Conveyor Switch Left - $480', 'Lever - $520', '1 / 1 Wedge - $40', '1 / 1 x 1 Wedge - $10', '4 / 4 x 1 Wedge - $50', '3 / 4 x 1 Wedge - $40', '2 / 4 x 1 Wedge - $30', '1 / 4 x 1 Wedge - $30', '1 / 2 x 1 Wedge - $20', '1 / 2 Wedge - $60', '2 / 2 x 1 Wedge - $30', '2 / 2 Wedge - $80', '1 / 3 x 1 Wedge - $20', '1 / 3 Wedge - $60', '2 / 3 x 1 Wedge - $30', '2 / 3 Wedge - $80', '3 / 3 x 1 Wedge - $30', 'Sawmax 02L - $86500', 'Fat Door - $180', 'Utility Vehicle - $400', 'Floor Lamp - $110', 'Armchair - $140', 'Bed - $350', 'Light Bulb - $2600', 'Floodlight - $90', 'Wall Light - $90', 'Dishwasher - $380', 'Loveseat - $200', 'Stove - $340', 'Toilet - $90', 'Refrigerator - $310', 'Couch - $320', 'Thin Countertop - $100', 'Countertop With Sink - $300', 'Countertop - $180', 'Wide Kitchen Cabinet Corner - $220', 'Kitchen Cabinet Corner - $150', 'Kitchen Cabinet - $220', 'Thin Cabinet - $80', 'Lamp - $90', 'Tiny Glass Pane - $12', 'Small Glass Pane - $50', 'Glass Pane - $220', 'Large Glass Pane - $550', 'Basic Glass Door - $720', 'Amber Icicle Lights - $750', 'Red Icicle Lights - $750', 'Green Icicle Lights - $750', 'Blue Icicle Lights - $750', 'Firework Launcher - $7500', 'Candy Cane Icicle Lights - $1050', 'Spooky Icicle Lights - $910', 'Utility Vehicle XL - $5000', 'Small Trailer - $1800', 'Val\'s All-Purpose Hauler - $19000', '531 Hauler - $13000', 'Can of Worms - $3200', 'Dynamite - $220', 'Title Unknown - $5980', 'Disturbed Painting - $2006', 'Outdoor Watercolor Sketch - $6', 'Arctic Light - $16000', 'Gloomy Seascape at Dusk - $16800', 'Pineapple - $2406000', 'The Lonely Giraffe - $26800', 'Signal Sustain - $520', 'AND Gate - $260', 'XOR Gate - $260', 'Wood Detector - $11300', 'OR Gate - $260', 'Signal Delay - $520', 'Hatch - $830', 'Signal Inverter - $200', 'Laser - $11300', 'Laser Detector - $3200', 'Orange Neon Wire - $720', 'Green Neon Wire - $720', 'Yellow Neon Wire - $720', 'White Neon Wire - $720', 'Violet Neon Wire - $720', 'Red Neon Wire - $720', 'Cyan Neon Wire - $720', 'Blue Neon Wire - $720', 'Clock Switch - $902'
    }
end

function Ancestor:GetClientMoney() return Player.leaderstats.Money.Value end
function Ancestor:GetItemInfo(SelectedItem)
    local Items = ClientItemInfo:GetChildren()
    for i = 1, #Items do if Items[i].ItemName.Value == SelectedItem then return Items[i] end end
end

function Ancestor:LocateStoreObject(Object)
    for i = 1, #Stores do 
        if tostring(Stores[i]) == 'ShopItems' then 
            local StoreItems = Stores[i]:GetChildren()
            for j = 1, #StoreItems do 
                if StoreItems[j]:WaitForChild('BoxItemName') and StoreItems[j].BoxItemName.Value == Object then return StoreItems[j] end
            end
        end
    end
end

function Ancestor:MoveObject(Object, Position, OldPosition, Sell, Amount)
    local PrimaryPart = Object:FindFirstChild('WoodSection') or Object.PrimaryPart
    for i = 1, (tostring(PrimaryPart):match('WoodSection') and 45) or 1 do 
        repeat Maid.Timer:Wait()
            if (Player.Character.PrimaryPart.CFrame.p - PrimaryPart.CFrame.p).Magnitude >= 10 then self:Teleport(CFrame.new(PrimaryPart.CFrame.p + Vector3.new(0, 5, 4))) end
            ClientIsDragging:FireServer(Object)
        until not Object or Object.Parent == nil or self:IsNetworkOwnerOfModel(Object)
    end
    for i = 1, Amount or 1 do
        if not Object or not Object.Parent then break end
        self:Teleport(CFrame.new(PrimaryPart.CFrame.p + Vector3.new(0, 5, 4)))
        ClientIsDragging:FireServer(Object); Object:PivotTo(Position)
    end
    if OldPosition then self:Teleport(OldPosition) end
end

function Ancestor:AutobuyItem()
    local LastPosition = Player.Character.PrimaryPart.CFrame 
    local ItemInfo = Ancestor:GetItemInfo(Ancestor.AutobuySelectedItem)
    if not ItemInfo then return end
    if self:GetClientMoney() < ItemInfo.Price.Value * Ancestor.AutobuyAmount then return SendUserNotice:Fire("Not enough money.") end
    
    for i = 1, Ancestor.AutobuyAmount do
        local Item = Ancestor:LocateStoreObject(tostring(ItemInfo))
        if not Item then repeat Maid.Timer:Wait(); Item = Ancestor:LocateStoreObject(tostring(ItemInfo)) until Item end
        self:Teleport(CFrame.new(Item.PrimaryPart.CFrame.p + Vector3.new(0, 2, 4)))
        
        local PurchaseInformation = nil
        for j = 1, #CashierList do if (Player.Character.Head.CFrame.p - CashierList[j].Model.Head.CFrame.p).Magnitude < 100 then PurchaseInformation = CashierList[j] end end
        if PurchaseInformation then
            self:MoveObject(Item, CFrame.new(PurchaseInformation.Counter.CFrame.p + Vector3.new(0, 2, 0)), nil, false, 5)
            PlayerChatted:InvokeServer({Character = PurchaseInformation.Model, Name = PurchaseInformation.Model.Name, ID = CashiersAutobuy[PurchaseInformation.Model.Name]}, 'ConfirmPurchase')
            task.wait(1)
            self:Teleport(LastPosition)
        end
    end
end

function Ancestor:GetFreeLand()
    local Max, NearestProperty = 9e9, nil
    for i = 1, #Properties do
        local Property = Properties[i]
        if Property.Owner.Value == nil and (Property.OriginSquare.CFrame.p - Player.Character.Head.CFrame.p).Magnitude < Max then
            NearestProperty = Property; Max = (Property.OriginSquare.CFrame.p - Player.Character.Head.CFrame.p).Magnitude
        end
    end
    return NearestProperty
end

function Ancestor:FreeLand()
    local Property = self:GetFreeLand()
    if not Property then return end
    ClientPurchasedProperty:FireServer(Property, Property.OriginSquare.CFrame.p)
    self:Teleport(CFrame.new(Property.OriginSquare.CFrame.p) + Vector3.new(0, 5, 0))
end

function Ancestor:GetPlayersBase(Target)
    Target = Target or Player
    for i = 1, #Properties do if tostring(Properties[i].Owner.Value):match(tostring(Target)) then return Properties[i] end end
    return false
end

function Ancestor:MaxLand()
    local Property = Ancestor:GetPlayersBase(Player)
    if not Property then Ancestor:FreeLand(); repeat task.wait() until Ancestor:GetPlayersBase(Player); Property = Ancestor:GetPlayersBase(Player) end
    local OriginSquare = Property.OriginSquare
    local expansions = {
        CFrame.new(40,0,0), CFrame.new(-40,0,0), CFrame.new(0,0,40), CFrame.new(0,0,-40),
        CFrame.new(40,0,40), CFrame.new(40,0,-40), CFrame.new(-40,0,40), CFrame.new(-40,0,-40),
        CFrame.new(80,0,0), CFrame.new(-80,0,0), CFrame.new(0,0,80), CFrame.new(0,0,-80),
        CFrame.new(80,0,80), CFrame.new(80,0,-80), CFrame.new(-80,0,80), CFrame.new(-80,0,-80),
        CFrame.new(40,0,80), CFrame.new(-40,0,80), CFrame.new(80,0,40), CFrame.new(80,0,-40),
        CFrame.new(-80,0,40), CFrame.new(-80,0,-40), CFrame.new(40,0,-80), CFrame.new(-40,0,-80)
    }
    for _, offset in ipairs(expansions) do
        ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position) * offset)
        task.wait(0.05)
    end
end

function Ancestor:PlankToBlueprint()
    local PlankToBP = Instance.new('Tool', Player.Backpack)
    PlankToBP.Name = 'Plank To Blueprint'; PlankToBP.RequiresHandle = false
    PlankToBP.Equipped:Connect(function() SendUserNotice:Fire("Select a Blueprint, then select a Plank.") end)
    PlankToBP.Activated:Connect(function()
        local Target = Mouse.Target
        if not Target then return end
        Target = Target.Parent
        if Target:FindFirstChild('BuildDependentWood') and not Target:FindFirstChild('BlueprintWoodClass') then
            self.SelectedBlueprint = Target; SendUserNotice:Fire("Blueprint Selected. Now click a plank.")
        elseif Target:FindFirstChild('WoodSection') and Target:FindFirstChild('TreeClass') and Target.Owner.Value == Player then
            self.SelectedPlank = Target
            if self.SelectedBlueprint and self.SelectedPlank then
                repeat task.wait(); ClientIsDragging:FireServer(self.SelectedPlank) until self:IsNetworkOwnerOfModel(self.SelectedPlank)
                for i=1, 20 do
                    self.SelectedPlank.WoodSection.CFrame = self.SelectedBlueprint.PrimaryPart.CFrame
                    task.wait()
                end
                self.SelectedBlueprint = nil; self.SelectedPlank = nil
            end
        end
    end)
end

function Ancestor:HardDragger(State)
    if State then
        Connections.HardDragger = workspace.ChildAdded:Connect(function(Dragger)
            if tostring(Dragger) == 'Dragger' then
                local BodyGyro = Dragger:WaitForChild('BodyGyro')
                local BodyPosition = Dragger:WaitForChild('BodyPosition')
                BodyPosition.P = 10000 * 8; BodyPosition.D = 1000
                BodyPosition.maxForce = Vector3.new(1, 1, 1) * 1000000
                BodyGyro.maxTorque = Vector3.new(1, 1, 1) * 200
                BodyGyro.P = 1200; BodyGyro.D = 140
            end
        end)
    else
        if Connections.HardDragger then Connections.HardDragger:Disconnect() end
    end
end

function Ancestor:FastRotate(State)
    setconstant(UserInput.getSteerFromKeys, 1, (State and GUISettings.FastRotate and GUISettings.XRotate) or 1)
    setconstant(UserInput.getThrottleFromKeys, 1, (State and GUISettings.FastRotate and GUISettings.YRotate) or 1)
end

function Ancestor:SellSigns()
    local PlayerModels = workspace.PlayerModels:GetChildren()
    for i = 1, #PlayerModels do
        local Model = PlayerModels[i]
        if Model:FindFirstChild('Owner') and Model.Owner.Value == Player and Model:FindFirstChild('ItemName') and tostring(Model.ItemName.Value):match('PropertySoldSign') then
            if (Model.PrimaryPart.CFrame.p - Player.Character.Head.CFrame.p).Magnitude > 20 then self:Teleport(CFrame.new(Model.PrimaryPart.CFrame.p + Vector3.new(0, 8, 0))) end
            if Model.PrimaryPart.Anchored then repeat Maid.Timer:Wait(); ClientInteracted:FireServer(Model, 'Take down sold sign') until not Model.PrimaryPart.Anchored end
            for _=1, 25 do ClientIsDragging:FireServer(Model); Model:PivotTo(CFrame.new(315, 3, 85)); task.wait() end
        end
    end
    self:Teleport(CFrame.new(315, 3, 85))
end

function Ancestor:ClickDelete()
    if not GUISettings.ClickDelete then pcall(function() Player.Backpack:FindFirstChild('DeleteTool'):Destroy() end) return end
    local DeleteTool = Instance.new('Tool', Player.Backpack); DeleteTool.Name = 'DeleteTool'; DeleteTool.RequiresHandle = false
    DeleteTool.Activated:Connect(function()
        local Target = Mouse.Target; if not Target then return end
        Target = Target.Parent
        if Target:FindFirstChild('Owner') and Target.Owner.Value == Player and not tostring(Target.Parent):match('Properties') then 
            DestroyStructure:FireServer(Target)
        end
    end)
end

function Ancestor:ClickToSell()
    if not GUISettings.ClickToSell then pcall(function() Player.Backpack:FindFirstChild('Click To Sell'):Destroy() end) return end
    local ClickToSell = Instance.new('Tool', Player.Backpack); ClickToSell.Name = 'Click To Sell'; ClickToSell.RequiresHandle = false
    ClickToSell.Activated:Connect(function()
        local Tree = Mouse.Target; if not Tree then return end; Tree = Tree.Parent
        if Tree:FindFirstChild('WoodSection') and ((Tree.Owner.Value == nil or Tree.Owner.Value == Player)) then 
            repeat Maid.Timer:Wait(); ClientIsDragging:FireServer(Tree) until self:IsNetworkOwnerOfModel(Tree)
            for i = 1, 25 do ClientIsDragging:FireServer(Tree); Tree:FindFirstChild('WoodSection').CFrame = CFrame.new(315, 3, 85) end
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────
-- ANTIKICK BYPASS (From hookmetamethod block)
-- ─────────────────────────────────────────────────────────────────
local Antikick
Antikick = hookmetamethod(game, '__namecall', function(self, ...)
    local Method = getnamecallmethod()
    local NewArgs = {...}
    if Ancestor_Loaded then
        if Method == 'Kick' and self == game:GetService('Players').LocalPlayer then return end
        if Method == 'FireServer' and tostring(...) == 'DamageHumanoid' and GUISettings.WaterGodMode then return end
        if Method == 'FireServer' and tostring(...) == 'Ban' then return end
        if Method == 'FireServer' and tostring(...) == 'RunSounds' and GUISettings.ActivateVehicleModifications then rawset(NewArgs, 3, GUISettings.CarPitch) end
        setnamecallmethod(Method)
    end
    return Antikick(self, unpack(NewArgs))
end)

-- ─────────────────────────────────────────────────────────────────
-- BACKGROUND LOOPS (Stepped and JumpRequest)
-- ─────────────────────────────────────────────────────────────────
RunService.Stepped:Connect(function()
    if UIS:IsKeyDown(Enum.KeyCode[GUISettings.SprintKey]) then Player.Character.Humanoid.WalkSpeed = GUISettings.WalkSpeed + GUISettings.SprintSpeed
    else Player.Character.Humanoid.WalkSpeed = GUISettings.WalkSpeed end

    if GUISettings.Noclip then
        for _, p in ipairs(Player.Character:GetChildren()) do if p:IsA('BasePart') then p.CanCollide = false end end
    end

    Lighting.TimeOfDay = (GUISettings.AlwaysDay and '12:00:00') or (GUISettings.AlwaysNight and '2:00:00') or Lighting.TimeOfDay
    Lighting.GlobalShadows = GUISettings.GlobalShadows
    Lighting.FogEnd = (GUISettings.NoFog and 1000000) or Lighting.FogEnd

    pcall(function() Player.Character.Humanoid.JumpPower = GUISettings.JumpPower end)
    
    if Player.Character.Humanoid.SeatPart and GUISettings.ActivateVehicleModifications then 
        local Vehicle = Player.Character.Humanoid.SeatPart.Parent
        if Vehicle:FindFirstChild("Configuration") and Vehicle.Configuration:FindFirstChild("MaxSpeed") then
            Vehicle.Configuration.MaxSpeed.Value = GUISettings.CarSpeed
        end
    end
end)

UIS.JumpRequest:Connect(function() if GUISettings.InfiniteJump then Player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end)

-- ─────────────────────────────────────────────────────────────────
-- JOFFER HUB UI FRAMEWORK (Theme & Window System)
-- ─────────────────────────────────────────────────────────────────
local T = {
    WindowBG = Color3.fromRGB(16, 20, 30), SidebarBG = Color3.fromRGB(11, 14, 22), ContentBG = Color3.fromRGB(20, 26, 36),
    ElementBG = Color3.fromRGB(26, 33, 48), ElementHover = Color3.fromRGB(34, 44, 62), Accent = Color3.fromRGB(0, 200, 175),
    AccentDim = Color3.fromRGB(0, 130, 115), TextPri = Color3.fromRGB(228, 234, 245), TextSec = Color3.fromRGB(138, 155, 178),
    ToggleOn = Color3.fromRGB(0, 200, 175), ToggleOff = Color3.fromRGB(50, 62, 85), Thumb = Color3.fromRGB(235, 240, 255),
    SliderTrack = Color3.fromRGB(38, 48, 68), Separator = Color3.fromRGB(30, 40, 58), Corner = UDim.new(0, 7),
    SmallCorner = UDim.new(0, 5), SidebarW = 110, RowH = 32, WinW = 440, WinH = 300
}

local function New(cls, props, ch) local i = Instance.new(cls); for k, v in pairs(props or {}) do if k ~= "Parent" then i[k] = v end end; for _, c in ipairs(ch or {}) do c.Parent = i end; if props and props.Parent then i.Parent = props.Parent end; return i end
local function Corner(p, r) return New("UICorner", {CornerRadius = r or T.Corner, Parent = p}) end
local function Stroke(p, c, w) return New("UIStroke", {Color = c, Thickness = w or 1, Parent = p}) end
local function Pad(p, t, b, l, r) return New("UIPadding", {PaddingTop=UDim.new(0,t or 6), PaddingBottom=UDim.new(0,b or 6), PaddingLeft=UDim.new(0,l or 10), PaddingRight=UDim.new(0,r or 10), Parent=p}) end
local function List(p, dir, gap) return New("UIListLayout", {FillDirection=dir or Enum.FillDirection.Vertical, Padding=UDim.new(0,gap or 4), SortOrder=Enum.SortOrder.LayoutOrder, HorizontalAlignment=Enum.HorizontalAlignment.Left, Parent=p}) end

local TI = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function Tw(o,p) TweenService:Create(o,TI,p):Play() end
local function TwF(o,p) TweenService:Create(o,TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),p):Play() end
local function TwS(o,p) TweenService:Create(o,TweenInfo.new(0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out),p):Play() end

local function MakeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging=true; dragStart=input.Position; startPos=target.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging=false end end) end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart; target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)
end

pcall(function() for _, parent in ipairs({gethui and gethui() or false, game:GetService("CoreGui"), Player:FindFirstChild("PlayerGui")}) do if parent then local old = parent:FindFirstChild("JofferHub") if old then old:Destroy() end end end end)

local guiParent = gethui and gethui() or game:GetService("CoreGui")
if not pcall(function() local _ = guiParent.Name end) then guiParent = Player:WaitForChild("PlayerGui") end

local ScreenGui = New("ScreenGui", {Name="JofferHub", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, IgnoreGuiInset=true, DisplayOrder=999, Parent=guiParent})
local Icon = New("Frame", {Name="FloatIcon", Size=UDim2.new(0,56,0,56), Position=UDim2.new(0,18,0.5,-28), BackgroundColor3=T.SidebarBG, BorderSizePixel=0, Visible=false, ZIndex=20, Parent=ScreenGui})
Corner(Icon, UDim.new(0,15)); Stroke(Icon, T.Accent, 2)
local IconBtn = New("TextButton", {Text="LT", Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=18, TextColor3=T.Accent, ZIndex=21, Parent=Icon})
MakeDraggable(Icon, Icon)

local Main = New("Frame", {Name="Main", Size=UDim2.new(0,T.WinW,0,T.WinH), Position=UDim2.new(0.5,-T.WinW/2,0.1,20), BackgroundColor3=T.WindowBG, BorderSizePixel=0, ClipsDescendants=true, ZIndex=5, Parent=ScreenGui})
Corner(Main); Stroke(Main, Color3.fromRGB(38,52,72), 1)

local TBar = New("Frame", {Size=UDim2.new(1,0,0,32), BackgroundColor3=T.SidebarBG, BorderSizePixel=0, ZIndex=6, Parent=Main})
New("TextLabel", {Text="LT2 Exploit | Ancestor V2 + Joffer UI", Size=UDim2.new(0,250,1,0), Position=UDim2.new(0,15,0,0), BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=12, TextColor3=T.TextPri, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=7, Parent=TBar})
MakeDraggable(TBar, Main)

local CloseBtn = New("TextButton", {Text="✕", Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,-34,0.5,-14), BackgroundColor3=Color3.fromRGB(185,55,55), BackgroundTransparency=0.35, Font=Enum.Font.GothamBold, TextSize=12, TextColor3=T.TextPri, BorderSizePixel=0, ZIndex=8, Parent=TBar})
Corner(CloseBtn, UDim.new(0,5))
local MinBtn = New("TextButton", {Text="─", Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,-66,0.5,-14), BackgroundColor3=T.ElementBG, BackgroundTransparency=0.35, Font=Enum.Font.GothamBold, TextSize=12, TextColor3=T.TextSec, BorderSizePixel=0, ZIndex=8, Parent=TBar})
Corner(MinBtn, UDim.new(0,5))

local Body = New("Frame", {Size=UDim2.new(1,0,1,-32), Position=UDim2.new(0,0,0,32), BackgroundTransparency=1, BorderSizePixel=0, Parent=Main})
local Sidebar = New("Frame", {Size=UDim2.new(0,T.SidebarW,1,0), BackgroundColor3=T.SidebarBG, BorderSizePixel=0, Parent=Body})
local TabListFrame = New("ScrollingFrame", {Size=UDim2.new(1,0,1,-6), Position=UDim2.new(0,0,0,6), BackgroundTransparency=1, ScrollBarThickness=0, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, Parent=Sidebar})
Pad(TabListFrame,4,4,5,5); List(TabListFrame,nil,2)
local PageContainer = New("Frame", {Size=UDim2.new(1,-T.SidebarW,1,0), Position=UDim2.new(0,T.SidebarW,0,0), BackgroundColor3=T.ContentBG, BorderSizePixel=0, Parent=Body})

local minimized = false
local function ShowMain() minimized=false; Icon.Visible=false; Main.Visible=true; Main.Size=UDim2.new(0,0,0,0); TwS(Main,{Size=UDim2.new(0,T.WinW,0,T.WinH)}) end
local function ShowIcon() minimized=true; local abs=MinBtn.AbsolutePosition; Icon.Position=UDim2.new(0,abs.X,0,abs.Y); TwF(Main,{Size=UDim2.new(0,0,0,0)}); task.delay(0.22,function() Main.Visible=false; Icon.Visible=true; Icon.Size=UDim2.new(0,0,0,0); Icon.Position=UDim2.new(0,18,0.5,-28); TwS(Icon,{Size=UDim2.new(0,56,0,56)}) end) end
MinBtn.MouseButton1Click:Connect(ShowIcon); IconBtn.MouseButton1Click:Connect(ShowMain); CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
UIS.InputBegan:Connect(function(input, gpe) if not gpe and input.KeyCode==Enum.KeyCode.RightControl then if minimized then ShowMain() else ShowIcon() end end end)

local Tabs = {}
local ActiveTab = nil

local function CreateTab(name, icon)
    local btn = New("TextButton", {Name=name, Size=UDim2.new(1,0,0,28), BackgroundColor3=T.ElementBG, BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=11, TextColor3=T.TextSec, Text=(icon or "  ").."  "..name, TextXAlignment=Enum.TextXAlignment.Left, BorderSizePixel=0, Parent=TabListFrame})
    Corner(btn, T.SmallCorner); Pad(btn,0,0,9,6)
    local indicator = New("Frame", {Size=UDim2.new(0,3,0.55,0), Position=UDim2.new(0,0,0.225,0), BackgroundColor3=T.Accent, BorderSizePixel=0, Visible=false, Parent=btn})
    local page = New("ScrollingFrame", {Name=name.."Page", Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, ScrollBarThickness=3, ScrollBarImageColor3=T.Accent, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, Visible=false, Parent=PageContainer})
    Pad(page,8,0,10,10); List(page,nil,4)

    local Tab = {Button=btn, Page=page, Indicator=indicator}

    function Tab:AddSection(text)
        local f=New("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Parent=page})
        New("TextLabel",{Text=text:upper(),Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=9,TextColor3=T.Accent,TextXAlignment=Enum.TextXAlignment.Left,Parent=f})
    end

    function Tab:AddToggle(text, opts, cb)
        opts=opts or {}; local state=opts.Default or false
        local row=New("Frame",{Size=UDim2.new(1,0,0,T.RowH),BackgroundColor3=T.ElementBG,BorderSizePixel=0,Parent=page}); Corner(row)
        New("TextLabel",{Text=text,Size=UDim2.new(1,-56,1,0),Position=UDim2.new(0,11,0,0),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=12,TextColor3=T.TextPri,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
        local track=New("Frame",{Size=UDim2.new(0,38,0,20),Position=UDim2.new(1,-48,0.5,-10),BackgroundColor3=state and T.ToggleOn or T.ToggleOff,BorderSizePixel=0,Parent=row}); Corner(track,UDim.new(1,0))
        local thumb=New("Frame",{Size=UDim2.new(0,14,0,14),Position=state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),BackgroundColor3=T.Thumb,BorderSizePixel=0,Parent=track}); Corner(thumb,UDim.new(1,0))
        New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",Parent=row}).MouseButton1Click:Connect(function() state=not state; Tw(track,{BackgroundColor3=state and T.ToggleOn or T.ToggleOff}); Tw(thumb,{Position=state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)}); if cb then pcall(cb,state) end end)
    end

    function Tab:AddSlider(text, opts, cb)
        opts=opts or {}; local mn=opts.Min or 0; local mx=opts.Max or 100; local step=opts.Step or 1; local val=opts.Default or mn
        local row=New("Frame",{Size=UDim2.new(1,0,0,50),BackgroundColor3=T.ElementBG,BorderSizePixel=0,Parent=page}); Corner(row)
        local topRow=New("Frame",{Size=UDim2.new(1,-22,0,22),Position=UDim2.new(0,11,0,6),BackgroundTransparency=1,Parent=row})
        New("TextLabel",{Text=text,Size=UDim2.new(1,-46,1,0),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=12,TextColor3=T.TextPri,TextXAlignment=Enum.TextXAlignment.Left,Parent=topRow})
        local valLbl=New("TextLabel",{Text=tostring(val),Size=UDim2.new(0,44,1,0),Position=UDim2.new(1,-44,0,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=T.Accent,TextXAlignment=Enum.TextXAlignment.Right,Parent=topRow})
        local track=New("Frame",{Size=UDim2.new(1,-22,0,5),Position=UDim2.new(0,11,0,34),BackgroundColor3=T.SliderTrack,BorderSizePixel=0,Parent=row}); Corner(track,UDim.new(1,0))
        local p0=(val-mn)/(mx-mn); local fill=New("Frame",{Size=UDim2.new(p0,0,1,0),BackgroundColor3=T.Accent,BorderSizePixel=0,Parent=track}); Corner(fill,UDim.new(1,0))
        local knob=New("Frame",{Size=UDim2.new(0,13,0,13),Position=UDim2.new(p0,-6,0.5,-6),BackgroundColor3=T.Thumb,BorderSizePixel=0,Parent=track}); Corner(knob,UDim.new(1,0))
        local dragging=false
        local function SetVal(v) v=math.clamp(math.round((v-mn)/step)*step+mn,mn,mx); val=v; local p=(v-mn)/(mx-mn); Tw(fill,{Size=UDim2.new(p,0,1,0)}); Tw(knob,{Position=UDim2.new(p,-6,0.5,-6)}); valLbl.Text=tostring(v); if cb then pcall(cb,v) end end
        track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; SetVal(mn+math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)*(mx-mn)) end end)
        UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then SetVal(mn+math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)*(mx-mn)) end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    end

    function Tab:AddButton(text, cb)
        local btn2=New("TextButton",{Size=UDim2.new(1,0,0,T.RowH),BackgroundColor3=T.ElementBG,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=T.Accent,Text=text,BorderSizePixel=0,Parent=page}); Corner(btn2); Stroke(btn2,T.AccentDim,1)
        btn2.MouseButton1Click:Connect(function() Tw(btn2,{BackgroundColor3=T.AccentDim}); task.delay(0.14,function() Tw(btn2,{BackgroundColor3=T.ElementBG}) end); if cb then pcall(cb) end end); return btn2
    end

    function Tab:AddDropdown(text, opts, cb)
        opts=opts or {}; local options=opts.Options or {}; local current=opts.Default or options[1] or "Select..."; local open=false
        local wrapper=New("Frame",{Size=UDim2.new(1,0,0,T.RowH),BackgroundTransparency=1,ClipsDescendants=false,Parent=page})
        local header=New("TextButton",{Size=UDim2.new(1,0,0,T.RowH),BackgroundColor3=T.ElementBG,Font=Enum.Font.Gotham,TextSize=12,TextColor3=T.TextPri,Text="",BorderSizePixel=0,Parent=wrapper}); Corner(header)
        New("TextLabel",{Text=text,Size=UDim2.new(0.5,-8,1,0),Position=UDim2.new(0,11,0,0),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=12,TextColor3=T.TextPri,TextXAlignment=Enum.TextXAlignment.Left,Parent=header})
        local valLbl=New("TextLabel",{Text=current,Size=UDim2.new(0.5,-28,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=11,TextColor3=T.Accent,TextXAlignment=Enum.TextXAlignment.Right,Parent=header})
        local dd=New("Frame",{Size=UDim2.new(0,200,0,0),Position=UDim2.new(0,0,0,0),BackgroundColor3=T.ElementBG,BorderSizePixel=0,ClipsDescendants=false,Visible=false,ZIndex=50,Parent=ScreenGui}); Corner(dd); Stroke(dd,T.Accent,1)
        local ddScroll=New("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=T.Accent,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=51,Parent=dd})
        local itemFrame=New("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=51,Parent=ddScroll}); Pad(itemFrame,3,3,4,4); List(itemFrame,nil,2)
        local function closeDD() open=false; TwF(dd,{Size=UDim2.new(0,dd.AbsoluteSize.X,0,0)}); task.delay(0.22,function() dd.Visible=false end) end
        for _,opt in ipairs(options) do
            local ib=New("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=T.ElementBG,BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=11,TextColor3=T.TextSec,Text=opt,TextXAlignment=Enum.TextXAlignment.Left,BorderSizePixel=0,ZIndex=52,Parent=itemFrame}); Pad(ib,0,0,8,4); Corner(ib,T.SmallCorner)
            ib.MouseButton1Click:Connect(function() current=opt; valLbl.Text=opt; closeDD(); if cb then pcall(cb,opt) end end)
        end
        header.MouseButton1Click:Connect(function() open=not open; if open then local abs=header.AbsolutePosition; dd.Size=UDim2.new(0,header.AbsoluteSize.X,0,0); dd.Position=UDim2.new(0,abs.X,0,abs.Y+header.AbsoluteSize.Y+2); dd.Visible=true; TwF(dd,{Size=UDim2.new(0,header.AbsoluteSize.X,0,math.min(#options*30+8,148))}) else closeDD() end end)
        return {Get=function() return current end}
    end

    btn.MouseButton1Click:Connect(function() for _,t in pairs(Tabs) do t.Page.Visible=false; t.Indicator.Visible=false; Tw(t.Button,{BackgroundTransparency=1,TextColor3=T.TextSec}) end; page.Visible=true; indicator.Visible=true; Tw(btn,{BackgroundTransparency=0.82,TextColor3=T.TextPri}); ActiveTab=Tab end)
    Tabs[name]=Tab; return Tab
end

-- ─────────────────────────────────────────────────────────────────
-- POPULATE TABS (Fully Hooked to Ancestor Logic)
-- ─────────────────────────────────────────────────────────────────

-- CLIENT TAB
local ClientTab = CreateTab("Client", "👤")
ClientTab:AddSection("Humanoid Options")
ClientTab:AddSlider("Walk Speed", {Min=16, Max=400, Default=16}, function(v) GUISettings.WalkSpeed = v end)
ClientTab:AddSlider("Sprint Speed", {Min=20, Max=200, Default=20}, function(v) GUISettings.SprintSpeed = v end)
ClientTab:AddSlider("Jump Power", {Min=50, Max=400, Default=50}, function(v) GUISettings.JumpPower = v end)
ClientTab:AddToggle("Infinite Jump", {Default=false}, function(v) GUISettings.InfiniteJump = v end)
ClientTab:AddToggle("Noclip", {Default=false}, function(v) GUISettings.Noclip = v end)
ClientTab:AddSection("Flight")
ClientTab:AddSlider("Fly Speed", {Min=50, Max=800, Default=200}, function(v) GUISettings.FlySpeed = v end)
ClientTab:AddSection("Character Mods")
ClientTab:AddToggle("God Mode", {Default=false}, function(v) Ancestor.CharacterGodMode = v; Ancestor:GodMode() end)
ClientTab:AddToggle("Anti-AFK", {Default=GUISettings.AntiAFK}, function(v) GUISettings.AntiAFK = v end)
ClientTab:AddButton("Safe Suicide", function() Ancestor:SafeSuicide() end)

-- TELEPORT TAB
local TeleportTab = CreateTab("Teleports", "🌍")
TeleportTab:AddSection("Waypoints")
local locs = {'Spawn', 'Wood R Us', 'Land Store', 'Bridge', 'Dock', 'Palm', 'Cave', 'The Den', 'Volcano', 'Swamp', 'Fancy Furnishings', 'Boxed Cars', 'Links Logic', 'Bobs Shack', 'Fine Arts Store', 'Ice Mountain', 'Shrine Of Sight', 'Strange Man', 'Volcano Win', 'Ski Lodge', 'Fur Wood'}
local LocationsCFrames = {['Wood R Us'] = CFrame.new(270, 4, 60), ['Spawn'] = CFrame.new(174, 10.5, 66), ['Land Store'] = CFrame.new(270, 3, -98), ['Bridge'] = CFrame.new(112, 37, -892), ['Dock'] = CFrame.new(1136, 0, -206), ['Palm'] = CFrame.new(2614, -4, -34), ['Cave'] = CFrame.new(3590, -177, 415), ['Volcano'] = CFrame.new(-1588, 623, 1069), ['Swamp'] = CFrame.new(-1216, 131, -822), ['Fancy Furnishings'] = CFrame.new(486, 3, -1722), ['Boxed Cars'] = CFrame.new(509, 3, -1458), ['Ice Mountain'] = CFrame.new(1487, 415, 3259), ['Links Logic'] = CFrame.new(4615, 7, -794), ['Bobs Shack'] = CFrame.new(292, 8, -2544), ['Fine Arts Store'] = CFrame.new(5217, -166, 721), ['Shrine Of Sight'] = CFrame.new(-1608, 195, 928), ['Strange Man'] = CFrame.new(1071, 16, 1141), ['Volcano Win'] = CFrame.new(-1667, 349, 147), ['Ski Lodge'] = CFrame.new(1244, 59, 2290), ['Fur Wood'] = CFrame.new(-1080, -5, -942), ['The Den'] = CFrame.new(330, 45, 1943)}
local locDropdown = TeleportTab:AddDropdown("Location", {Options=locs, Default='Spawn'})
TeleportTab:AddButton("Teleport To Waypoint", function() Ancestor:Teleport(LocationsCFrames[locDropdown:Get()]) end)

local allP = {}
for _, p in ipairs(Players:GetPlayers()) do if p ~= Player then table.insert(allP, p.Name) end end
if #allP == 0 then allP = {"(no other players)"} end
TeleportTab:AddSection("Player Teleport")
local plrDrop = TeleportTab:AddDropdown("Player", {Options=allP, Default=allP[1]})
TeleportTab:AddButton("Teleport to Player", function()
    local t = Players:FindFirstChild(plrDrop:Get())
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then Ancestor:Teleport(CFrame.new(t.Character.HumanoidRootPart.Position + Vector3.new(0,5,0))) end
end)

-- PROPERTY TAB
local PropertyTab = CreateTab("Property", "🏠")
PropertyTab:AddSection("Land")
PropertyTab:AddButton("Free Land", function() Ancestor:FreeLand() end)
PropertyTab:AddButton("Max Land", function() Ancestor:MaxLand() end)
PropertyTab:AddButton("Sell Land Signs", function() Ancestor:SellSigns() end)
PropertyTab:AddSection("Build Tools")
PropertyTab:AddButton("Plank To Blueprint Tool", function() Ancestor:PlankToBlueprint() end)
PropertyTab:AddToggle("Click Delete Tool", {Default=false}, function(v) GUISettings.ClickDelete = v; Ancestor:ClickDelete() end)
PropertyTab:AddToggle("Click To Sell Tool", {Default=false}, function(v) GUISettings.ClickToSell = v; Ancestor:ClickToSell() end)
PropertyTab:AddToggle("Hard Dragger", {Default=false}, function(v) GUISettings.HardDragger = v; Ancestor:HardDragger(v) end)
PropertyTab:AddSlider("Fast Rotate X", {Min=1, Max=5, Default=1}, function(v) GUISettings.XRotate = v; Ancestor:FastRotate(GUISettings.FastRotate) end)
PropertyTab:AddSlider("Fast Rotate Y", {Min=1, Max=5, Default=1}, function(v) GUISettings.YRotate = v; Ancestor:FastRotate(GUISettings.FastRotate) end)
PropertyTab:AddToggle("Fast Rotate Active", {Default=false}, function(v) GUISettings.FastRotate = v; Ancestor:FastRotate(v) end)

-- SHOP / AUTOBUY TAB
local ShopTab = CreateTab("Shop", "💰")
ShopTab:AddSection("Autobuy Options")
local storeItemsFullList = Ancestor:GetStoreItems()
local itemDrop = ShopTab:AddDropdown("Select Item", {Options=storeItemsFullList, Default=storeItemsFullList[1]}, function(v) Ancestor.AutobuySelectedItem = v:gsub('%W- $%d+', '') end)
ShopTab:AddSlider("Quantity", {Min=1, Max=100, Default=1}, function(v) Ancestor.AutobuyAmount = v end)
ShopTab:AddButton("Purchase Items", function() Ancestor:AutobuyItem() end)

-- AXE TAB
local AxeTab = CreateTab("Axes", "⛏")
AxeTab:AddSection("Stat Modifications")
AxeTab:AddSlider("Axe Range", {Min=1, Max=400, Default=10}, function(v) GUISettings.AxeRange = v; if GUISettings.AxeRangeActive then Ancestor:SetAxeRange(true, v) end end)
AxeTab:AddToggle("Activate Axe Range", {Default=false}, function(v) GUISettings.AxeRangeActive = v; Ancestor:SetAxeRange(v, GUISettings.AxeRange) end)
AxeTab:AddToggle("No Cooldown", {Default=false}, function(v) GUISettings.AxeSwingActive = v; Ancestor:SetSwingCooldown(v) end)
AxeTab:AddSection("Drop Options")
AxeTab:AddToggle("Instant Drop (Respawn)", {Default=false}, function(v) GUISettings.InstantDropAxes = v end)
AxeTab:AddButton("Drop All Axes", function() Ancestor:DropTools() end)

-- WOOD TAB
local WoodTab = CreateTab("Trees", "🌲")
WoodTab:AddSection("Bring Trees")
local treeTypes = {'Generic','GoldSwampy','CaveCrawler','Cherry','Frost','Volcano','Oak','Walnut','Birch','SnowGlow','Fir','Pine','GreenSwampy','Koa','Palm','Spooky','SpookyNeon','LoneCave'}
WoodTab:AddDropdown("Tree Type", {Options=treeTypes, Default='Generic'}, function(v) Ancestor.SelectedTreeType = v end)
WoodTab:AddDropdown("Tree Size", {Options={'Largest','Smallest'}, Default='Largest'}, function(v) GUISettings.SelectedTreeTypeSize = v end)
WoodTab:AddSlider("Amount", {Min=1, Max=10, Default=1}, function(v) Ancestor.BringTreeAmount = v end)
WoodTab:AddButton("Bring Tree", function() Ancestor:BringTree() end)
WoodTab:AddSection("Automation")
WoodTab:AddToggle("Auto Chop", {Default=false}, function(v) GUISettings.AutoChopTrees = v end)

-- VEHICLE TAB
local VehicleTab = CreateTab("Vehicle", "🚗")
VehicleTab:AddSection("Modifications")
VehicleTab:AddSlider("Car Speed", {Min=1, Max=5, Default=1}, function(v) GUISettings.CarSpeed = v end)
VehicleTab:AddSlider("Car Pitch", {Min=1, Max=10, Default=1}, function(v) GUISettings.CarPitch = v end)
VehicleTab:AddToggle("Activate Vehicle Mods", {Default=true}, function(v) GUISettings.ActivateVehicleModifications = v end)

-- WORLD TAB
local WorldTab = CreateTab("World", "🌍")
WorldTab:AddSection("Lighting")
WorldTab:AddToggle("Always Day", {Default=false}, function(v) GUISettings.AlwaysDay = v end)
WorldTab:AddToggle("Always Night", {Default=false}, function(v) GUISettings.AlwaysNight = v end)
WorldTab:AddToggle("No Fog", {Default=false}, function(v) GUISettings.NoFog = v end)
WorldTab:AddToggle("Global Shadows", {Default=true}, function(v) GUISettings.GlobalShadows = v; Lighting.GlobalShadows = v end)
WorldTab:AddSection("Water")
WorldTab:AddToggle("Water Walk", {Default=false}, function(v) GUISettings.WaterWalk = v; for _, w in ipairs(workspace.Water:GetChildren()) do w.CanCollide = v end end)
WorldTab:AddToggle("Water Godmode", {Default=false}, function(v) GUISettings.WaterGodMode = v end)

-- ACTIVATE UI
task.defer(function()
    task.wait()
    for _, t in pairs(Tabs) do t.Page.Visible=false; t.Indicator.Visible=false; t.Button.BackgroundTransparency=1; t.Button.TextColor3=T.TextSec end
    if Tabs["Client"] then Tabs["Client"].Page.Visible=true; Tabs["Client"].Indicator.Visible=true; Tabs["Client"].Button.BackgroundTransparency=0.82; Tabs["Client"].Button.TextColor3=T.TextPri; ActiveTab=Tabs["Client"] end
end)
Main.Size=UDim2.new(0,0,0,0); Main.BackgroundTransparency=1
TwF(Main,{BackgroundTransparency=0}); TwS(Main,{Size=UDim2.new(0,T.WinW,0,T.WinH)})
Ancestor_Loaded = true
print("[JofferHub + Ancestor V2 FULL Logic] Loaded Successfully!")
