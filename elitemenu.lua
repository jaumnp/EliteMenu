-- ==========================================================
-- // 1. INICIALIZAÇÃO SEGURA E VARIÁVEIS NATIVAS (FANTASMA)
-- ==========================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local ScriptContext = game:GetService("ScriptContext")
local LogService = game:GetService("LogService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- ==========================================================
-- // 1.5. ANTI-TAMPER (BLINDAGEM CONTRA CÓPIAS E ESPIÕES)
-- ==========================================================
local function RunEnvironmentCheck()
    local ok, err = pcall(function()
        -- Checa a física nativa
        local fps = Workspace:GetRealPhysicsFPS()
        if type(fps) ~= "number" or fps <= 0 or fps > 300 then error("detected", 0) end
        
        -- Checa adulteração de Serviços
        local s1, s2 = pcall(function() return game:GetService("ChangeHistoryService") end)
        if s1 and s2 then
            if typeof(s2) ~= "Instance" or s2.ClassName ~= "ChangeHistoryService" then error("detected", 0) end
        end
        
        -- Checa adulteração do Gerador de GUID
        local guid1 = HttpService:GenerateGUID(false)
        local guid2 = HttpService:GenerateGUID(false)
        local padrao = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"
        if guid1 == guid2 or not string.match(guid1, padrao) or not string.match(guid2, padrao) or #guid1 ~= 36 then
            error("detected", 0)
        end
        
        -- Checa adulteração da Engine de Gráficos
        local qLevel = settings().Rendering.QualityLevel
        if typeof(qLevel) ~= "EnumItem" then error("detected", 0) end
        
        local valid = false
        for _, enumItem in ipairs(Enum.QualityLevel:GetEnumItems()) do
            if enumItem == qLevel then valid = true; break end
        end
        if not valid then error("detected", 0) end
    end)
    
    if not ok then error("Ambiente adulterado detectado! Execução abortada.", 0) end
    return true
end

-- Se falhar na checagem, ele mata o script instantaneamente aqui:
if not RunEnvironmentCheck() then return end

-- ==========================================================

local ItemSpawnLocation = nil 

-- Gerador de Hash para ocultar a UI de Anti-Cheats
local function GenerateHash()
    return string.gsub(HttpService:GenerateGUID(false), "-", "")
end

-- ==========================================================
-- // 2. TEMA E CONFIGURAÇÕES GLOBAIS (NO TOPO)
-- ==========================================================
local Theme = {
    Main = Color3.fromRGB(17, 18, 26),
    Sidebar = Color3.fromRGB(21, 23, 34),
    Box = Color3.fromRGB(21, 23, 34),
    Accent = Color3.fromRGB(130, 80, 255),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(136, 140, 158),
    Outline = Color3.fromRGB(34, 37, 50),
    Alert = Color3.fromRGB(255, 60, 60),
    OverlayBg = Color3.fromRGB(20, 20, 20)
}

local Settings = {
    Enabled = true,
    CombatEngine = "V1 (Default)",
    TeamCheckGlobal = false,
    IgnoreSpawnProtection = false,
    UI = {
        ShowWatermark = false,
        ShowRadar = false,
        ShowActiveMods = false,
        RadarZoom = 50,
        WatermarkText = "Elite Menu"
    },
    ESP = { 
        Box2D = false, Box3D = false, Skeleton = false, Lines = false, Distance = false, Name = false, Health = false, Weapon = false, MaxDistance = 2000,
        EnemyColor = Color3.fromRGB(255, 50, 50),
        AllyColor = Color3.fromRGB(50, 255, 100)
    },
    Aimbot = { Enabled = false, Method = "CFrame", WallCheck = true, Mode = "Hold", TargetPart = "Head", TriggerBot = false, PredictionEnabled = false, BulletSpeed = 1000, Gravity = 196.2 },
    FOV = { Visible = false, Radius = 100, Color = Theme.Accent },
    Misc = {
        SpeedEnabled = false, SpeedValue = 16, Fly = false, NoClip = false, InfiniteJump = false,
        Magnet = false, MagnetDistance = 10, Orbit = false, OrbitSpeed = 5, OrbitDistance = 5,
        TeleportAura = false, TeleportDistance = 5, TeleportHeight = 3, TeleportBehind = true,
        Wallbang = false, WallbangSize = 15, WallbangMode = "Giant Cube", ItemDropBringer = false,
        AntiFling = false, AntiAim = false,
        AntiFall = false,
        AntiRagdoll = false
    }
}
local SettingsV2 = { 
    Aimbot = { Enabled = false, TriggerBot = false }, 
    ESP = { Box2D = false, Lines = false, Distance = false } 
}

-- ==========================================================
-- // 2.5. FUNÇÕES DE FILTRO DE SPAWN
-- ==========================================================
local function HasSpawnProtection(char)
    if not Settings.IgnoreSpawnProtection then return false end
    if not char then return false end
    
    local ff = char:FindFirstChildOfClass("ForceField") or char:FindFirstChild("ForceField")
    if ff then return true end
    
    local sp = char:GetAttribute("SpawnProtection")
    local inv = char:GetAttribute("Invincible")
    local god = char:GetAttribute("GodMode")
    
    if sp == true or sp == 1 then return true end
    if inv == true or inv == 1 then return true end
    if god == true or god == 1 then return true end
    
    return false
end

-- ==========================================================
-- // 3. CEGUEIRA DE ANTI-CHEAT E HOOKS (MÁXIMA DEFESA)
-- ==========================================================
pcall(function()
    local getconnections = getconnections or get_signal_cons
    if getconnections then
        for _, v in pairs(getconnections(LocalPlayer.Idled)) do 
            if v.Disable then v:Disable() end 
        end
        for _, conn in pairs(getconnections(ScriptContext.Error)) do 
            if conn.Disable then conn:Disable() end 
        end
        for _, conn in pairs(getconnections(LogService.MessageOut)) do 
            if conn.Disable then conn:Disable() end 
        end
        
        local function silenceEvent(event)
            pcall(function() 
                for _, conn in pairs(getconnections(event)) do 
                    if conn.Disable then conn:Disable() end 
                end 
            end)
        end
        silenceEvent(CoreGui.ChildAdded)
        silenceEvent(CoreGui.DescendantAdded)
    end

    task.spawn(function()
        while task.wait(2) do
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and getconnections then
                pcall(function()
                    for _, conn in pairs(getconnections(LocalPlayer.Character.Humanoid:GetPropertyChangedSignal("WalkSpeed"))) do 
                        if conn.Disable then conn:Disable() end 
                    end
                    for _, conn in pairs(getconnections(LocalPlayer.Character.Humanoid:GetPropertyChangedSignal("JumpPower"))) do 
                        if conn.Disable then conn:Disable() end 
                    end
                end)
            end
        end
    end)

    local hookfunction = hookfunction or detour_function
    if hookfunction then
        pcall(function()
            local oldGcinfo; oldGcinfo = hookfunction(gcinfo, function(...) 
                return math.random(1500, 2500) 
            end)
            local oldCollect; oldCollect = hookfunction(collectgarbage, function(opt, ...)
                if opt == "count" then 
                    return math.random(1500, 2500) 
                end 
                return oldCollect(opt, ...)
            end)
        end)
    end

    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    local oldIndex = mt.__index
    local oldNewIndex = mt.__newindex
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        
        if not checkcaller() then
            if typeof(self) == "Instance" then
                if method == "Kick" or method == "kick" or method == "Ban" then return nil end
                if method == "Teleport" or method == "TeleportToPlaceInstance" then return nil end
                if method == "BreakJoints" and self == LocalPlayer.Character then return nil end
                if method == "GetTotalMemoryUsageMb" then return math.random(350, 400) + math.random() end
                if method == "GetRankInGroup" then return 255 end
                if method == "GetRoleInGroup" then return "Owner" end
            end
        end
        return oldNamecall(self, ...)
    end)

    mt.__index = newcclosure(function(self, key)
        if not checkcaller() then
            if typeof(self) == "Instance" and self:IsA("Humanoid") then
                if key == "WalkSpeed" or key == "walkSpeed" then return 16 end
                if key == "JumpPower" or key == "jumpPower" then return 50 end
            end
        end
        return oldIndex(self, key)
    end)

    mt.__newindex = newcclosure(function(self, key, value)
        if not checkcaller() then
            if typeof(self) == "Instance" and self:IsA("Humanoid") and (key == "WalkSpeed" or key == "walkSpeed" or key == "JumpPower" or key == "jumpPower") then 
                return 
            end
        end
        return oldNewIndex(self, key, value)
    end)
    setreadonly(mt, true)
end)

local gethui = gethui or function() 
    local success, core = pcall(function() return CoreGui end)
    return success and core or LocalPlayer:WaitForChild("PlayerGui") 
end

-- ==========================================================
-- // 3.5. ESP FALLBACK (SIMULAÇÃO MATEMÁTICA DE DESENHO)
-- ==========================================================
local DrawingAPI = {}
local HasNativeDrawing = false

pcall(function() 
    local test = Drawing.new("Line")
    test.Visible = false
    test:Remove()
    HasNativeDrawing = true 
end)

if HasNativeDrawing then
    DrawingAPI = Drawing
else
    local DrawContainer = Instance.new("ScreenGui")
    DrawContainer.Name = GenerateHash()
    DrawContainer.IgnoreGuiInset = true
    DrawContainer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() 
        if syn and syn.protect_gui then 
            syn.protect_gui(DrawContainer) 
        end 
    end)
    DrawContainer.Parent = gethui()

    DrawingAPI.new = function(classType)
        local obj = { 
            Visible = false, 
            Color = Color3.new(1,1,1), 
            Transparency = 1 
        }

        if classType == "Line" then
            obj.From = Vector2.new(0, 0)
            obj.To = Vector2.new(0, 0)
            obj.Thickness = 1
            
            local frame = Instance.new("Frame")
            frame.AnchorPoint = Vector2.new(0.5, 0.5)
            frame.BorderSizePixel = 0
            frame.Visible = false
            frame.Parent = DrawContainer
            obj.Instance = frame
            
            function obj:Update()
                if not self.Visible then 
                    self.Instance.Visible = false 
                    return 
                end
                self.Instance.Visible = true
                self.Instance.BackgroundColor3 = self.Color
                self.Instance.BackgroundTransparency = 1 - self.Transparency
                
                local pos = (self.From + self.To) / 2
                local len = (self.To - self.From).Magnitude
                local angle = math.deg(math.atan2(self.To.Y - self.From.Y, self.To.X - self.From.X))
                
                self.Instance.Position = UDim2.new(0, pos.X, 0, pos.Y)
                self.Instance.Size = UDim2.new(0, len, 0, self.Thickness)
                self.Instance.Rotation = angle
            end

        elseif classType == "Text" then
            obj.Text = ""
            obj.Position = Vector2.new(0,0)
            obj.Size = 14
            obj.Center = false
            obj.Outline = false
            
            local lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBold
            lbl.Visible = false
            lbl.Parent = DrawContainer
            obj.Instance = lbl
            
            function obj:Update()
                if not self.Visible then 
                    self.Instance.Visible = false 
                    return 
                end
                self.Instance.Visible = true
                self.Instance.TextColor3 = self.Color
                self.Instance.TextTransparency = 1 - self.Transparency
                self.Instance.Text = self.Text
                self.Instance.TextSize = self.Size
                self.Instance.Position = UDim2.new(0, self.Position.X, 0, self.Position.Y)
                self.Instance.AnchorPoint = self.Center and Vector2.new(0.5, 0) or Vector2.new(0, 0)
                self.Instance.TextStrokeTransparency = self.Outline and 0 or 1
            end

        elseif classType == "Circle" then
            obj.Radius = 0
            obj.Position = Vector2.new(0,0)
            obj.Thickness = 1
            
            local frame = Instance.new("Frame")
            frame.BackgroundTransparency = 1
            frame.AnchorPoint = Vector2.new(0.5, 0.5)
            frame.Visible = false
            
            local stroke = Instance.new("UIStroke", frame)
            local corner = Instance.new("UICorner", frame)
            corner.CornerRadius = UDim.new(1, 0)
            frame.Parent = DrawContainer
            obj.Instance = frame
            
            function obj:Update()
                if not self.Visible then 
                    self.Instance.Visible = false 
                    return 
                end
                self.Instance.Visible = true
                self.Instance.Position = UDim2.new(0, self.Position.X, 0, self.Position.Y)
                self.Instance.Size = UDim2.new(0, self.Radius * 2, 0, self.Radius * 2)
                stroke.Color = self.Color
                stroke.Thickness = self.Thickness
                stroke.Transparency = 1 - self.Transparency
            end

        elseif classType == "Square" then
            obj.Size = Vector2.new(0,0)
            obj.Position = Vector2.new(0,0)
            obj.Thickness = 1
            obj.Filled = false
            
            local frame = Instance.new("Frame")
            frame.BackgroundTransparency = 1
            frame.BorderSizePixel = 0
            frame.Visible = false
            
            local stroke = Instance.new("UIStroke", frame)
            stroke.LineJoinMode = Enum.LineJoinMode.Miter
            
            frame.Parent = DrawContainer
            obj.Instance = frame
            obj.Stroke = stroke
            
            function obj:Update()
                if not self.Visible then 
                    self.Instance.Visible = false 
                    return 
                end
                self.Instance.Visible = true
                self.Instance.Position = UDim2.new(0, self.Position.X, 0, self.Position.Y)
                self.Instance.Size = UDim2.new(0, self.Size.X, 0, self.Size.Y)
                
                if self.Filled then
                    self.Instance.BackgroundTransparency = 1 - self.Transparency
                    self.Instance.BackgroundColor3 = self.Color
                    self.Stroke.Thickness = 0
                else
                    self.Instance.BackgroundTransparency = 1
                    self.Stroke.Color = self.Color
                    self.Stroke.Thickness = self.Thickness
                    self.Stroke.Transparency = 1 - self.Transparency
                end
            end
        end

        function obj:Remove() 
            if self.Instance then 
                self.Instance:Destroy() 
            end 
        end
        
        local proxy = {}
        setmetatable(proxy, { 
            __index = function(_, k) 
                return obj[k] 
            end, 
            __newindex = function(_, k, v) 
                obj[k] = v
                if obj.Update and k ~= "Update" and k ~= "Remove" and k ~= "Instance" then 
                    obj:Update() 
                end 
            end 
        })
        return proxy
    end
end

-- ==========================================================
-- // FUNÇÃO DE OVERLAY
-- ==========================================================

local OverlayUI = Instance.new("ScreenGui")
OverlayUI.Name = GenerateHash(); OverlayUI.ResetOnSpawn = false; OverlayUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; OverlayUI.IgnoreGuiInset = true
pcall(function() if syn and syn.protect_gui then syn.protect_gui(OverlayUI) end end)
OverlayUI.Parent = gethui()

-- WATERMARK
local Watermark = Instance.new("Frame", OverlayUI)
Watermark.Visible = Settings.UI.ShowWatermark
Watermark.Size = UDim2.new(0, 350, 0, 30)
Watermark.AnchorPoint = Vector2.new(0.5, 0) -- Ponto de âncora no centro
Watermark.Position = UDim2.new(0.5, 0, 0, 15) -- Joga a UI exatamente pro meio da tela
Watermark.BackgroundColor3 = Theme.OverlayBg
Watermark.BackgroundTransparency = 0.3
Instance.new("UICorner", Watermark).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", Watermark).Color = Theme.Outline

local WText = Instance.new("TextLabel", Watermark)
WText.Size = UDim2.new(1, 0, 1, 0)
WText.BackgroundTransparency = 1
WText.Text = "Loading..."
WText.TextColor3 = Theme.Text
WText.Font = Enum.Font.GothamMedium
WText.TextSize = 12
WText.TextXAlignment = Enum.TextXAlignment.Center -- Deixa o texto no meio

-- RADAR
local RadarBg = Instance.new("Frame", OverlayUI)
RadarBg.Visible = Settings.UI.ShowRadar
RadarBg.Size = UDim2.new(0, 180, 0, 180); RadarBg.Position = UDim2.new(1, -195, 0, 15); RadarBg.BackgroundColor3 = Theme.OverlayBg; RadarBg.BackgroundTransparency = 0.2; RadarBg.ClipsDescendants = true
Instance.new("UICorner", RadarBg).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", RadarBg).Color = Theme.Outline

local RadarLinesX = Instance.new("Frame", RadarBg); RadarLinesX.Size = UDim2.new(1, 0, 0, 1); RadarLinesX.Position = UDim2.new(0, 0, 0.5, 0); RadarLinesX.BackgroundColor3 = Color3.fromRGB(50, 50, 50); RadarLinesX.BorderSizePixel = 0
local RadarLinesY = Instance.new("Frame", RadarBg); RadarLinesY.Size = UDim2.new(0, 1, 1, 0); RadarLinesY.Position = UDim2.new(0.5, 0, 0, 0); RadarLinesY.BackgroundColor3 = Color3.fromRGB(50, 50, 50); RadarLinesY.BorderSizePixel = 0
local RadarCenter = Instance.new("Frame", RadarBg); RadarCenter.Size = UDim2.new(0, 4, 0, 4); RadarCenter.Position = UDim2.new(0.5, -2, 0.5, -2); RadarCenter.BackgroundColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", RadarCenter).CornerRadius = UDim.new(1, 0)

-- ACTIVE MODS
local ActiveModsList = Instance.new("Frame", OverlayUI)
ActiveModsList.Visible = Settings.UI.ShowActiveMods
ActiveModsList.Size = UDim2.new(0, 150, 0.5, 0); ActiveModsList.Position = UDim2.new(1, -165, 0, 210); ActiveModsList.BackgroundTransparency = 1
local ActiveLayout = Instance.new("UIListLayout", ActiveModsList); ActiveLayout.SortOrder = Enum.SortOrder.LayoutOrder; ActiveLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right; ActiveLayout.Padding = UDim.new(0, 5)

-- ==========================================================
-- // 4. INTERFACE CUSTOMIZADA PREMIUM (TEMA QUAIL) E MODAL
-- ==========================================================

local EliteUI = Instance.new("ScreenGui")
EliteUI.Name = GenerateHash()
EliteUI.ResetOnSpawn = false
EliteUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
EliteUI.IgnoreGuiInset = true
pcall(function() 
    if syn and syn.protect_gui then 
        syn.protect_gui(EliteUI) 
    elseif protect_gui then 
        protect_gui(EliteUI) 
    end 
end)
EliteUI.Parent = gethui()

local MainFrame = Instance.new("Frame", EliteUI)
MainFrame.Name = GenerateHash()
MainFrame.Size = UDim2.new(0, 600, 0, 420)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -210)
MainFrame.BackgroundColor3 = Theme.Main
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Theme.Outline

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundTransparency = 1

local TitleLbl = Instance.new("TextLabel", TopBar)
TitleLbl.Size = UDim2.new(0, 300, 1, 0)
TitleLbl.Position = UDim2.new(0, 15, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "ELITE UNIVERSAL | Hide: RightControl"
TitleLbl.TextColor3 = Theme.Text
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 14
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Theme.Main
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Theme.SubText
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
local CloseStroke = Instance.new("UIStroke", CloseBtn)
CloseStroke.Color = Theme.Outline

local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    TweenService:Create(MainFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
end

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function() 
            if input.UserInputState == Enum.UserInputState.End then 
                dragging = false 
            end 
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then 
        dragInput = input 
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then 
        updateDrag(input) 
    end
end)

local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 85, 1, -50)
Sidebar.Position = UDim2.new(0, 10, 0, 40)
Sidebar.BackgroundColor3 = Theme.Sidebar
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)

local SidebarLayout = Instance.new("UIListLayout", Sidebar)
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarLayout.Padding = UDim.new(0, 10)

local SidebarPad = Instance.new("UIPadding", Sidebar)
SidebarPad.PaddingTop = UDim.new(0, 10)

local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Size = UDim2.new(1, -110, 1, -50)
ContentArea.Position = UDim2.new(0, 100, 0, 40)
ContentArea.BackgroundTransparency = 1

local Tabs = {}
local function CreateTabButton(icon, isFirst)
    local TabBtn = Instance.new("TextButton", Sidebar)
    TabBtn.Size = UDim2.new(1, -10, 0, 35)
    TabBtn.BackgroundColor3 = isFirst and Theme.Accent or Theme.Sidebar
    TabBtn.Text = icon
    TabBtn.TextColor3 = Theme.Text
    TabBtn.TextSize = 14
    TabBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)

    local TabContainer = Instance.new("ScrollingFrame", ContentArea)
    TabContainer.Size = UDim2.new(1, 0, 1, 0)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 2
    TabContainer.Visible = isFirst
    TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y 
    
    local UIList = Instance.new("UIListLayout", TabContainer)
    UIList.Padding = UDim.new(0, 10)
    UIList.SortOrder = Enum.SortOrder.LayoutOrder

    local UIPad = Instance.new("UIPadding", TabContainer)
    UIPad.PaddingRight = UDim.new(0, 5)
    
    TabBtn.MouseButton1Click:Connect(function()
        for _, btn in pairs(Sidebar:GetChildren()) do 
            if btn:IsA("TextButton") then 
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Sidebar}):Play() 
            end 
        end
        for _, container in pairs(ContentArea:GetChildren()) do 
            if container:IsA("ScrollingFrame") then 
                container.Visible = false 
            end 
        end
        TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
        TabContainer.Visible = true
    end)
    return TabContainer
end

local function CreateSection(parent, titleText)
    local SectionBox = Instance.new("Frame", parent)
    SectionBox.Size = UDim2.new(1, 0, 0, 0)
    SectionBox.AutomaticSize = Enum.AutomaticSize.Y
    SectionBox.BackgroundColor3 = Theme.Box
    Instance.new("UICorner", SectionBox).CornerRadius = UDim.new(0, 8)
    
    local Stroke = Instance.new("UIStroke", SectionBox)
    Stroke.Color = Theme.Outline

    local SectionLayout = Instance.new("UIListLayout", SectionBox)
    SectionLayout.Padding = UDim.new(0, 5)
    SectionLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local SectionPad = Instance.new("UIPadding", SectionBox)
    SectionPad.PaddingTop = UDim.new(0, 10)
    SectionPad.PaddingBottom = UDim.new(0, 10)
    SectionPad.PaddingLeft = UDim.new(0, 15)
    SectionPad.PaddingRight = UDim.new(0, 15)

    local TitleCont = Instance.new("Frame", SectionBox)
    TitleCont.Size = UDim2.new(1, 0, 0, 20)
    TitleCont.BackgroundTransparency = 1
    
    local BlueLine = Instance.new("Frame", TitleCont)
    BlueLine.Size = UDim2.new(0, 3, 1, -4)
    BlueLine.Position = UDim2.new(0, 0, 0, 2)
    BlueLine.BackgroundColor3 = Theme.Accent
    Instance.new("UICorner", BlueLine).CornerRadius = UDim.new(1, 0)

    local TitleLbl = Instance.new("TextLabel", TitleCont)
    TitleLbl.Size = UDim2.new(1, -10, 1, 0)
    TitleLbl.Position = UDim2.new(0, 10, 0, 0)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Text = string.upper(titleText)
    TitleLbl.TextColor3 = Theme.SubText
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.TextSize = 11
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

    return SectionBox
end

local function CreateToggle(parent, text, defaultState, callback)
    local state = defaultState
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, 30)
    Frame.BackgroundTransparency = 1

    local Lbl = Instance.new("TextLabel", Frame)
    Lbl.Size = UDim2.new(1, -50, 1, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = text
    Lbl.TextColor3 = Theme.Text
    Lbl.Font = Enum.Font.GothamMedium
    Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local SwitchBack = Instance.new("Frame", Frame)
    SwitchBack.Size = UDim2.new(0, 36, 0, 20)
    SwitchBack.Position = UDim2.new(1, -36, 0.5, -10)
    SwitchBack.BackgroundColor3 = state and Theme.Accent or Theme.Main
    Instance.new("UICorner", SwitchBack).CornerRadius = UDim.new(1, 0)
    
    local Stroke = Instance.new("UIStroke", SwitchBack)
    Stroke.Color = Theme.Outline

    local SwitchDot = Instance.new("Frame", SwitchBack)
    SwitchDot.Size = UDim2.new(0, 14, 0, 14)
    SwitchDot.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    SwitchDot.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", SwitchDot).CornerRadius = UDim.new(1, 0)

    local Btn = Instance.new("TextButton", SwitchBack)
    Btn.Size = UDim2.new(1,0,1,0)
    Btn.BackgroundTransparency = 1
    Btn.Text = ""

    Btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(SwitchBack, TweenInfo.new(0.2), {BackgroundColor3 = state and Theme.Accent or Theme.Main}):Play()
        TweenService:Create(SwitchDot, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)}):Play()
        callback(state)
    end)
end

local function CreateButton(parent, text, callback)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, 36)
    Frame.BackgroundTransparency = 1
    
    local Btn = Instance.new("TextButton", Frame)
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundColor3 = Theme.Main
    Btn.Text = text
    Btn.TextColor3 = Theme.Text
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 13
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    
    local Stroke = Instance.new("UIStroke", Btn)
    Stroke.Color = Theme.Outline
    
    Btn.MouseButton1Click:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Accent}):Play()
        task.wait(0.1)
        TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Main}):Play()
        callback()
    end)
end

local function CreateCycle(parent, text, options, callback)
    local index = 1
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, 36)
    Frame.BackgroundTransparency = 1

    local Lbl = Instance.new("TextLabel", Frame)
    Lbl.Size = UDim2.new(1, -130, 1, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = text
    Lbl.TextColor3 = Theme.Text
    Lbl.Font = Enum.Font.GothamMedium
    Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local Btn = Instance.new("TextButton", Frame)
    Btn.Size = UDim2.new(0, 120, 0, 26)
    Btn.Position = UDim2.new(1, -120, 0.5, -13)
    Btn.BackgroundColor3 = Theme.Main
    Btn.Text = options[index]
    Btn.TextColor3 = Theme.Accent
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    
    local Stroke = Instance.new("UIStroke", Btn)
    Stroke.Color = Theme.Outline

    Btn.MouseButton1Click:Connect(function()
        index = index + 1
        if index > #options then index = 1 end
        Btn.Text = options[index]
        callback(options[index])
    end)
end

local function CreateSlider(parent, text, min, max, default, callback)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, 45)
    Frame.BackgroundTransparency = 1

    local Lbl = Instance.new("TextLabel", Frame)
    Lbl.Size = UDim2.new(1, -50, 0, 20)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = text
    Lbl.TextColor3 = Theme.Text
    Lbl.Font = Enum.Font.GothamMedium
    Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ValLbl = Instance.new("TextLabel", Frame)
    ValLbl.Size = UDim2.new(0, 50, 0, 20)
    ValLbl.Position = UDim2.new(1, -50, 0, 0)
    ValLbl.BackgroundTransparency = 1
    ValLbl.Text = tostring(default)
    ValLbl.TextColor3 = Theme.Accent
    ValLbl.Font = Enum.Font.GothamBold
    ValLbl.TextSize = 13
    ValLbl.TextXAlignment = Enum.TextXAlignment.Right

    local SliderBack = Instance.new("Frame", Frame)
    SliderBack.Size = UDim2.new(1, 0, 0, 6)
    SliderBack.Position = UDim2.new(0, 0, 0, 28)
    SliderBack.BackgroundColor3 = Theme.Main
    Instance.new("UICorner", SliderBack).CornerRadius = UDim.new(1, 0)
    
    local Stroke = Instance.new("UIStroke", SliderBack)
    Stroke.Color = Theme.Outline

    local fillPct = (default - min) / (max - min)
    local SliderFill = Instance.new("Frame", SliderBack)
    SliderFill.Size = UDim2.new(fillPct, 0, 1, 0)
    SliderFill.BackgroundColor3 = Theme.Accent
    Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

    local SliderThumb = Instance.new("Frame", SliderFill)
    SliderThumb.Size = UDim2.new(0, 14, 0, 14)
    SliderThumb.Position = UDim2.new(1, -7, 0.5, -7)
    SliderThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", SliderThumb).CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    local function update(input)
        local pos = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + ((max - min) * pos))
        TweenService:Create(SliderFill, TweenInfo.new(0.05), {Size = UDim2.new(pos, 0, 1, 0)}):Play()
        ValLbl.Text = tostring(value)
        callback(value)
    end

    local Hitbox = Instance.new("TextButton", SliderBack)
    Hitbox.Size = UDim2.new(1, 0, 0, 20)
    Hitbox.Position = UDim2.new(0, 0, 0.5, -10)
    Hitbox.BackgroundTransparency = 1
    Hitbox.Text = ""

    Hitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            dragging = true
            update(input) 
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            dragging = false 
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
            update(input) 
        end
    end)
end

local function clamp(n, min, max)
	return math.max(min, math.min(max, n))
end

local function colorToHex(color)
	return string.format(
		"#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

local function hexToColor(hex)
	hex = hex:gsub("#", "")
	if #hex ~= 6 then
		return nil
	end

	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)

	if not r or not g or not b then
		return nil
	end

	return Color3.fromRGB(r, g, b)
end

local function CreateColorPicker(parent, text, defaultColor, callback)
	defaultColor = defaultColor or Color3.fromRGB(0, 255, 100)
	callback = callback or function() end

	local themeText = Theme and Theme.Text or Color3.fromRGB(255, 255, 255)
	local themeOutline = Theme and Theme.Outline or Color3.fromRGB(60, 60, 70)
	local themeDark = Theme and (Theme.Secondary or Theme.Background) or Color3.fromRGB(14, 14, 18)
	local themePanel = Color3.fromRGB(16, 18, 28)

	local h, s, v = defaultColor:ToHSV()
	local opened = false
	local rainbow = false
	local rainbowConn = nil
	local draggingSV = false
	local draggingHue = false

	local Frame = Instance.new("Frame")
	Frame.Name = text .. "_ColorPickerHeader"
	Frame.Parent = parent
	Frame.Size = UDim2.new(1, 0, 0, 30)
	Frame.BackgroundTransparency = 1

	local Lbl = Instance.new("TextLabel")
	Lbl.Parent = Frame
	Lbl.Size = UDim2.new(1, -50, 1, 0)
	Lbl.BackgroundTransparency = 1
	Lbl.Text = text
	Lbl.TextColor3 = themeText
	Lbl.Font = Enum.Font.GothamMedium
	Lbl.TextSize = 13
	Lbl.TextXAlignment = Enum.TextXAlignment.Left

	local ColorBtn = Instance.new("TextButton")
	ColorBtn.Parent = Frame
	ColorBtn.Size = UDim2.new(0, 40, 0, 20)
	ColorBtn.Position = UDim2.new(1, -40, 0.5, -10)
	ColorBtn.BackgroundColor3 = defaultColor
	ColorBtn.Text = ""
	ColorBtn.AutoButtonColor = false
	Instance.new("UICorner", ColorBtn).CornerRadius = UDim.new(0, 5)

	local ColorBtnStroke = Instance.new("UIStroke")
	ColorBtnStroke.Parent = ColorBtn
	ColorBtnStroke.Color = themeOutline

	local PickerFrame = Instance.new("Frame")
	PickerFrame.Name = text .. "_ColorPickerBody"
	PickerFrame.Parent = parent
	PickerFrame.Size = UDim2.new(1, 0, 0, 0)
	PickerFrame.BackgroundTransparency = 1
	PickerFrame.ClipsDescendants = true

	local Panel = Instance.new("Frame")
	Panel.Parent = PickerFrame
	Panel.Size = UDim2.new(1, 0, 0, 112)
	Panel.BackgroundColor3 = themePanel
	Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 8)

	local PanelStroke = Instance.new("UIStroke")
	PanelStroke.Parent = Panel
	PanelStroke.Color = themeOutline

	local SV = Instance.new("Frame")
	SV.Parent = Panel
	SV.Position = UDim2.new(0, 8, 0, 8)
	SV.Size = UDim2.new(1, -110, 0, 92)
	SV.BackgroundColor3 = Color3.new(1, 1, 1)
	SV.BorderSizePixel = 0
	SV.ClipsDescendants = true
	Instance.new("UICorner", SV).CornerRadius = UDim.new(0, 6)

	local SatLayer = Instance.new("Frame")
	SatLayer.Parent = SV
	SatLayer.Size = UDim2.new(1, 0, 1, 0)
	SatLayer.BorderSizePixel = 0
	SatLayer.BackgroundColor3 = Color3.fromHSV(h, 1, 1)

	local SatGradient = Instance.new("UIGradient")
	SatGradient.Parent = SatLayer
	SatGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})

	local ValLayer = Instance.new("Frame")
	ValLayer.Parent = SV
	ValLayer.Size = UDim2.new(1, 0, 1, 0)
	ValLayer.BorderSizePixel = 0
	ValLayer.BackgroundColor3 = Color3.new(0, 0, 0)

	local ValGradient = Instance.new("UIGradient")
	ValGradient.Parent = ValLayer
	ValGradient.Rotation = 90
	ValGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})

	local SVCursor = Instance.new("Frame")
	SVCursor.Parent = SV
	SVCursor.Size = UDim2.new(0, 10, 0, 10)
	SVCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	SVCursor.BackgroundTransparency = 1

	local SVCursorCorner = Instance.new("UICorner")
	SVCursorCorner.Parent = SVCursor
	SVCursorCorner.CornerRadius = UDim.new(1, 0)

	local SVCursorStroke = Instance.new("UIStroke")
	SVCursorStroke.Parent = SVCursor
	SVCursorStroke.Color = Color3.new(1, 1, 1)
	SVCursorStroke.Thickness = 2

	local Hue = Instance.new("Frame")
	Hue.Parent = Panel
	Hue.Position = UDim2.new(1, -96, 0, 8)
	Hue.Size = UDim2.new(0, 14, 0, 92)
	Hue.BorderSizePixel = 0
	Hue.ClipsDescendants = true
	Instance.new("UICorner", Hue).CornerRadius = UDim.new(0, 6)

	local HueGradient = Instance.new("UIGradient")
	HueGradient.Parent = Hue
	HueGradient.Rotation = 90
	HueGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
	})

	local HueCursor = Instance.new("Frame")
	HueCursor.Parent = Hue
	HueCursor.Size = UDim2.new(1, 4, 0, 3)
	HueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	HueCursor.Position = UDim2.new(0.5, 0, 0, 0)
	HueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
	HueCursor.BorderSizePixel = 0

	local HueCursorStroke = Instance.new("UIStroke")
	HueCursorStroke.Parent = HueCursor
	HueCursorStroke.Color = Color3.new(0, 0, 0)
	HueCursorStroke.Thickness = 1

	local Side = Instance.new("Frame")
	Side.Parent = Panel
	Side.Position = UDim2.new(1, -76, 0, 8)
	Side.Size = UDim2.new(0, 68, 0, 92)
	Side.BackgroundTransparency = 1

	local HexBox = Instance.new("TextBox")
	HexBox.Parent = Side
	HexBox.Size = UDim2.new(1, 0, 0, 22)
	HexBox.BackgroundTransparency = 1
	HexBox.Text = colorToHex(defaultColor)
	HexBox.TextColor3 = themeText
	HexBox.Font = Enum.Font.Code
	HexBox.TextSize = 12
	HexBox.ClearTextOnFocus = false
	HexBox.TextXAlignment = Enum.TextXAlignment.Left

	local Preview = Instance.new("Frame")
	Preview.Parent = Side
	Preview.Position = UDim2.new(0, 0, 0, 26)
	Preview.Size = UDim2.new(1, 0, 0, 22)
	Preview.BackgroundColor3 = defaultColor
	Preview.BorderSizePixel = 0
	Instance.new("UICorner", Preview).CornerRadius = UDim.new(0, 5)

	local PreviewStroke = Instance.new("UIStroke")
	PreviewStroke.Parent = Preview
	PreviewStroke.Color = themeOutline

	local RainbowBtn = Instance.new("TextButton")
	RainbowBtn.Parent = Side
	RainbowBtn.Position = UDim2.new(0, 0, 0, 54)
	RainbowBtn.Size = UDim2.new(1, 0, 0, 22)
	RainbowBtn.Text = "Rainbow"
	RainbowBtn.Font = Enum.Font.GothamMedium
	RainbowBtn.TextSize = 11
	RainbowBtn.TextColor3 = themeText
	RainbowBtn.BackgroundColor3 = themeDark
	RainbowBtn.AutoButtonColor = false
	RainbowBtn.BorderSizePixel = 0
	Instance.new("UICorner", RainbowBtn).CornerRadius = UDim.new(0, 5)

	local RainbowStroke = Instance.new("UIStroke")
	RainbowStroke.Parent = RainbowBtn
	RainbowStroke.Color = themeOutline

	local function stopRainbow()
		rainbow = false
		if rainbowConn then
			rainbowConn:Disconnect()
			rainbowConn = nil
		end
		RainbowBtn.BackgroundColor3 = themeDark
	end

	local function updateVisuals(fireCallback)
		local currentColor = Color3.fromHSV(h, s, v)

		SatLayer.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		SVCursor.Position = UDim2.new(s, 0, 1 - v, 0)
		HueCursor.Position = UDim2.new(0.5, 0, h, 0)

		ColorBtn.BackgroundColor3 = currentColor
		Preview.BackgroundColor3 = currentColor
		HexBox.Text = colorToHex(currentColor)

		if fireCallback then
			callback(currentColor)
		end
	end

	local function setFromSV(input)
		local x = clamp((input.Position.X - SV.AbsolutePosition.X) / SV.AbsoluteSize.X, 0, 1)
		local y = clamp((input.Position.Y - SV.AbsolutePosition.Y) / SV.AbsoluteSize.Y, 0, 1)

		s = x
		v = 1 - y
		updateVisuals(true)
	end

	local function setFromHue(input)
		local y = clamp((input.Position.Y - Hue.AbsolutePosition.Y) / Hue.AbsoluteSize.Y, 0, 1)
		h = y
		updateVisuals(true)
	end

	local function setRainbow(state)
		if state then
			rainbow = true
			RainbowBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 100)

			if rainbowConn then
				rainbowConn:Disconnect()
			end

			rainbowConn = RunService.RenderStepped:Connect(function()
				h = (tick() * 0.15) % 1
				updateVisuals(true)
			end)
		else
			stopRainbow()
		end
	end

	ColorBtn.MouseButton1Click:Connect(function()
		opened = not opened
		PickerFrame.Size = opened and UDim2.new(1, 0, 0, 112) or UDim2.new(1, 0, 0, 0)
	end)

	RainbowBtn.MouseButton1Click:Connect(function()
		setRainbow(not rainbow)
	end)

	HexBox.FocusLost:Connect(function()
		local newColor = hexToColor(HexBox.Text)
		if newColor then
			stopRainbow()
			h, s, v = newColor:ToHSV()
			updateVisuals(true)
		else
			updateVisuals(false)
		end
	end)

	SV.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			stopRainbow()
			draggingSV = true
			setFromSV(input)
		end
	end)

	Hue.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			stopRainbow()
			draggingHue = true
			setFromHue(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if draggingSV and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromSV(input)
		end

		if draggingHue and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromHue(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSV = false
			draggingHue = false
		end
	end)

	updateVisuals(true)

	return {
		SetColor = function(_, color)
			stopRainbow()
			h, s, v = color:ToHSV()
			updateVisuals(true)
		end,
		GetColor = function()
			return Color3.fromHSV(h, s, v)
		end,
		SetRainbow = function(_, state)
			setRainbow(state)
		end
	}
end

-- ==========================================================
-- // MODAL DE CONFIRMAÇÃO DE SAÍDA
-- ==========================================================
local ModalContainer = Instance.new("Frame", EliteUI)
ModalContainer.Size = UDim2.new(1, 0, 1, 0)
ModalContainer.BackgroundColor3 = Color3.new(0, 0, 0)
ModalContainer.BackgroundTransparency = 1
ModalContainer.Visible = false
ModalContainer.ZIndex = 10

local ModalAlert = Instance.new("Frame", ModalContainer)
ModalAlert.Size = UDim2.new(0, 300, 0, 150)
ModalAlert.Position = UDim2.new(0.5, -150, 0.5, -75)
ModalAlert.BackgroundColor3 = Theme.Box
Instance.new("UICorner", ModalAlert).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", ModalAlert).Color = Theme.Outline

local MTitle = Instance.new("TextLabel", ModalAlert)
MTitle.Size = UDim2.new(1, 0, 0, 40)
MTitle.BackgroundTransparency = 1
MTitle.Text = "DESTROY MENU?"
MTitle.TextColor3 = Theme.Alert
MTitle.Font = Enum.Font.GothamBold
MTitle.TextSize = 16

local MText = Instance.new("TextLabel", ModalAlert)
MText.Size = UDim2.new(1, -20, 0, 50)
MText.Position = UDim2.new(0, 10, 0, 40)
MText.BackgroundTransparency = 1
MText.Text = "This will permanently close the panel and disable ALL functions.\n\nIf you only want to hide the menu, press [RightControl]."
MText.TextColor3 = Theme.SubText
MText.TextWrapped = true
MText.Font = Enum.Font.Gotham
MText.TextSize = 12

local MBtnYes = Instance.new("TextButton", ModalAlert)
MBtnYes.Size = UDim2.new(0, 100, 0, 30)
MBtnYes.Position = UDim2.new(0.5, -110, 1, -40)
MBtnYes.BackgroundColor3 = Theme.Alert
MBtnYes.Text = "Disable All"
MBtnYes.TextColor3 = Color3.new(1,1,1)
MBtnYes.Font = Enum.Font.GothamBold
MBtnYes.TextSize = 12
Instance.new("UICorner", MBtnYes).CornerRadius = UDim.new(0, 6)

local MBtnNo = Instance.new("TextButton", ModalAlert)
MBtnNo.Size = UDim2.new(0, 100, 0, 30)
MBtnNo.Position = UDim2.new(0.5, 10, 1, -40)
MBtnNo.BackgroundColor3 = Theme.Sidebar
MBtnNo.Text = "Cancel"
MBtnNo.TextColor3 = Theme.Text
MBtnNo.Font = Enum.Font.GothamBold
MBtnNo.TextSize = 12
Instance.new("UICorner", MBtnNo).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", MBtnNo).Color = Theme.Outline

CloseBtn.MouseButton1Click:Connect(function()
    ModalContainer.Visible = true
    TweenService:Create(ModalContainer, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play()
end)

MBtnNo.MouseButton1Click:Connect(function()
    TweenService:Create(ModalContainer, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    task.wait(0.2)
    ModalContainer.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightControl then 
        EliteUI.Enabled = not EliteUI.Enabled 
    end
end)

local FlyActive, FlyConnection, OrbitAngle = false, nil, 0
local RealVelocity = Vector3.zero
local ESPPlayers, ESPPlayersV2 = {}, {}
local V2GlobalPlayers = {}
local GlobalHeads = {}

local Box3DConnections = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
local GlobalRayParams = RaycastParams.new()
GlobalRayParams.FilterType = Enum.RaycastFilterType.Exclude

local FOVCircle = DrawingAPI.new("Circle")
FOVCircle.Thickness = 2

local function HideESP(esp)
    if esp.Box2D then for i = 1, 4 do esp.Box2D[i].Visible = false end end
    if esp.Box3D then for i = 1, 12 do esp.Box3D[i].Visible = false end end
    if esp.Skeleton then for i = 1, 5 do esp.Skeleton[i].Visible = false end end
    if esp.HealthBar then for i = 1, 6 do esp.HealthBar[i].Visible = false end end
    if esp.Snapline then esp.Snapline.Visible = false end
    if esp.DistanceText then esp.DistanceText.Visible = false end
    if esp.NameText then esp.NameText.Visible = false end
    if esp.WeaponText then esp.WeaponText.Visible = false end
end

local function HideESPV2(esp)
    if esp.Box then esp.Box.Visible = false end
    if esp.Snapline then esp.Snapline.Visible = false end
    if esp.DistanceText then esp.DistanceText.Visible = false end
end

local function CleanPlayerESP(player)
    if ESPPlayers[player] then
        local esp = ESPPlayers[player]
        HideESP(esp)

        if esp.Box2D then for i = 1, 4 do esp.Box2D[i]:Remove() end end
        if esp.Box3D then for i = 1, 12 do esp.Box3D[i]:Remove() end end
        if esp.Skeleton then for i = 1, 5 do esp.Skeleton[i]:Remove() end end
        if esp.HealthBar then for i = 1, 6 do esp.HealthBar[i]:Remove() end end
        if esp.Snapline then esp.Snapline:Remove() end
        if esp.DistanceText then esp.DistanceText:Remove() end
        if esp.NameText then esp.NameText:Remove() end
        if esp.WeaponText then esp.WeaponText:Remove() end

        ESPPlayers[player] = nil
    end
end

local function CleanPlayerESPV2(key) 
    if ESPPlayersV2[key] then 
        HideESPV2(ESPPlayersV2[key])
        if ESPPlayersV2[key].Box then ESPPlayersV2[key].Box:Remove() end
        if ESPPlayersV2[key].Snapline then ESPPlayersV2[key].Snapline:Remove() end
        if ESPPlayersV2[key].DistanceText then ESPPlayersV2[key].DistanceText:Remove() end
        if ESPPlayersV2[key].Box2D then for i = 1, 4 do ESPPlayersV2[key].Box2D[i]:Remove() end end
        ESPPlayersV2[key] = nil 
    end 
end

local function EnableFly()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    FlyActive = true
    local HRP = LocalPlayer.Character.HumanoidRootPart
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    for _, v in ipairs(HRP:GetChildren()) do 
        if v.Name == "EliteFlyBV" or v.Name == "EliteFlyBG" then 
            v:Destroy() 
        end 
    end
    
    local BV = Instance.new("BodyVelocity")
    BV.Name = "EliteFlyBV"
    BV.P = 10000
    BV.MaxForce = Vector3.new(100000, 100000, 100000)
    BV.Velocity = Vector3.new(0, 0, 0)
    BV.Parent = HRP
    
    local BG = Instance.new("BodyGyro")
    BG.Name = "EliteFlyBG"
    BG.P = 10000
    BG.MaxTorque = Vector3.new(100000, 100000, 100000)
    BG.CFrame = HRP.CFrame
    BG.Parent = HRP
    
    if Hum then Hum.PlatformStand = true end
    
    FlyConnection = RunService.RenderStepped:Connect(function()
        if not FlyActive or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            if FlyConnection then 
                FlyConnection:Disconnect()
                FlyConnection = nil 
            end 
            return
        end
        local HRP = LocalPlayer.Character.HumanoidRootPart
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if Hum then Hum.PlatformStand = true end
        
        local flyDirection = Vector3.new(0, 0, 0)
        local speed = Settings.Misc.SpeedEnabled and (Settings.Misc.SpeedValue * 2) or 50
        local camCFrame = Workspace.CurrentCamera.CFrame
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then flyDirection = flyDirection + camCFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then flyDirection = flyDirection - camCFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then flyDirection = flyDirection - camCFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then flyDirection = flyDirection + camCFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then flyDirection = flyDirection + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then flyDirection = flyDirection - Vector3.new(0, 1, 0) end
        if flyDirection.Magnitude > 0 then flyDirection = flyDirection.Unit * speed end
        
        local flyBV = HRP:FindFirstChild("EliteFlyBV")
        local flyBG = HRP:FindFirstChild("EliteFlyBG")
        if flyBV then flyBV.Velocity = flyDirection end
        if flyBG then flyBG.CFrame = camCFrame end
    end)
end

local function DisableFly()
    FlyActive = false
    if FlyConnection then 
        FlyConnection:Disconnect()
        FlyConnection = nil 
    end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local HRP = LocalPlayer.Character.HumanoidRootPart
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        for _, v in ipairs(HRP:GetChildren()) do 
            if v.Name == "EliteFlyBV" or v.Name == "EliteFlyBG" then v:Destroy() end 
        end
        if Hum then 
            Hum.PlatformStand = false
            Hum:ChangeState(Enum.HumanoidStateType.GettingUp) 
        end
        HRP.Velocity = Vector3.new(0,0,0)
    end
end

-- ==========================================================
-- // DESTRUIR MENU E LIMPAR MEMÓRIA (FIM DO SCRIPT)
-- ==========================================================
MBtnYes.MouseButton1Click:Connect(function()
    Settings.Enabled = false
    DisableFly()
    
    -- 1. Limpa o Motor V1 (Isolado linha por linha para não travar)
    for player, esp in pairs(ESPPlayers) do
        if esp.Box2D then for i = 1, 4 do pcall(function() esp.Box2D[i].Visible = false; esp.Box2D[i]:Remove() end) end end
        if esp.Box3D then for i = 1, 12 do pcall(function() esp.Box3D[i].Visible = false; esp.Box3D[i]:Remove() end) end end
        if esp.Skeleton then for i = 1, 5 do pcall(function() esp.Skeleton[i].Visible = false; esp.Skeleton[i]:Remove() end) end end
        if esp.HealthBar then for i = 1, 6 do pcall(function() esp.HealthBar[i].Visible = false; esp.HealthBar[i]:Remove() end) end end
        if esp.Snapline then pcall(function() esp.Snapline.Visible = false; esp.Snapline:Remove() end) end
        if esp.DistanceText then pcall(function() esp.DistanceText.Visible = false; esp.DistanceText:Remove() end) end
        if esp.NameText then pcall(function() esp.NameText.Visible = false; esp.NameText:Remove() end) end
        if esp.WeaponText then pcall(function() esp.WeaponText.Visible = false; esp.WeaponText:Remove() end) end
    end
    ESPPlayers = {}
    
    -- 2. Limpa o Motor V2 Antigo (Garantia de limpeza profunda)
    if ESPPlayersV2 then
        for key, esp in pairs(ESPPlayersV2) do 
            if esp.Box then pcall(function() esp.Box.Visible = false; esp.Box:Remove() end) end
            if esp.Snapline then pcall(function() esp.Snapline.Visible = false; esp.Snapline:Remove() end) end
            if esp.DistanceText then pcall(function() esp.DistanceText.Visible = false; esp.DistanceText:Remove() end) end
            if esp.Box2D then for i=1,4 do pcall(function() esp.Box2D[i].Visible = false; esp.Box2D[i]:Remove() end) end end
        end
        ESPPlayersV2 = {}
    end
    
    -- 3. Limpa o Pool Extremo do V2 (Agora totalmente blindado)
    if ESPPoolV2 then
        for _, esp in pairs(ESPPoolV2) do
            if esp.Box then pcall(function() esp.Box.Visible = false; esp.Box:Remove() end) end
            if esp.Snapline then pcall(function() esp.Snapline.Visible = false; esp.Snapline:Remove() end) end
            if esp.DistanceText then pcall(function() esp.DistanceText.Visible = false; esp.DistanceText:Remove() end) end
            if esp.Box2D then for i=1,4 do pcall(function() esp.Box2D[i].Visible = false; esp.Box2D[i]:Remove() end) end end
        end
        ESPPoolV2 = {}
    end

    -- 4. Limpa os Pools da HUD (Badges e Radar)
    if ActiveBadgePool then
        for _, badge in pairs(ActiveBadgePool) do pcall(function() badge:Destroy() end) end
    end
    if RadarDotPool then
        for _, dot in pairs(RadarDotPool) do pcall(function() dot:Destroy() end) end
    end

    -- 5. Restaura o Hitbox e Física Original dos Players
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                p.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                p.Character.HumanoidRootPart.Transparency = 1
                p.Character.HumanoidRootPart.CanCollide = true
                if p.Character:FindFirstChild("Humanoid") then p.Character.Humanoid.PlatformStand = false end
                
                local head = p.Character:FindFirstChild("Head")
                if head then
                    head.Size = Vector3.new(1.2, 1.2, 1.2)
                    head.Transparency = 0
                    head.CanCollide = true
                end
            end)
        end
    end
    
    -- 6. Mata o círculo de FOV
    if typeof(FOVCircle) == "table" or typeof(FOVCircle) == "userdata" then 
        pcall(function() FOVCircle.Visible = false; FOVCircle:Remove() end) 
    end
    
    -- 7. TIRO DE MISERICÓRDIA: Força a limpeza nativa de alguns executores
    pcall(function() if cleardrawcache then cleardrawcache() end end)

    -- 8. Limpa a tela de desenho falsa (se o executor não tiver função nativa de Draw)
    if not HasNativeDrawing and DrawingAPI then
        for _, obj in pairs(gethui():GetChildren()) do 
            if obj:IsA("ScreenGui") and obj.Name ~= EliteUI.Name and obj.Name ~= OverlayUI.Name then 
                pcall(function() obj:Destroy() end) 
            end 
        end
    end
    
    -- 9. Desliga as amarras do sistema de mira
    pcall(function() RunService:UnbindFromRenderStep("EliteCombatLock") end)
    
    EliteUI:Destroy()
    if OverlayUI then OverlayUI:Destroy() end
end)

-- ==========================================================
-- // 5. POPULANDO A NOVA INTERFACE
-- ==========================================================
local engineTab = CreateTabButton("Engine", false)
local engineSec    = CreateSection(engineTab, "Engine Functions")
CreateCycle(engineSec, "Engine", {"V1 (Default)", "V2 (Universal)"}, function(v) 
    Settings.CombatEngine = v
    for k, _ in pairs(ESPPlayersV2) do CleanPlayerESPV2(k) end
    for _, p in ipairs(Players:GetPlayers()) do CleanPlayerESP(p) end 
end)

local engineSec = CreateSection(engineTab, "Check Functions")
CreateToggle(engineSec, "Team Check", Settings.TeamCheckGlobal, function(v) 
    Settings.TeamCheckGlobal = v 
    for k, _ in pairs(ESPPlayersV2) do CleanPlayerESPV2(k) end
    for _, p in ipairs(Players:GetPlayers()) do CleanPlayerESP(p) end
end)

local espTab    = CreateTabButton("Visuals", true)
local espSec    = CreateSection(espTab, "ESP Functions")
local colorsSec = CreateSection(espSec, "Colors")
CreateColorPicker(colorsSec, "Enemy Color", Settings.ESP.EnemyColor, function(c) Settings.ESP.EnemyColor = c end)
CreateColorPicker(colorsSec, "Ally Color", Settings.ESP.AllyColor, function(c) Settings.ESP.AllyColor = c end)
CreateToggle(espSec, "ESP Box 2D", Settings.ESP.Box2D, function(v) Settings.ESP.Box2D = v; SettingsV2.ESP.Box2D = v end)
CreateToggle(espSec, "ESP Snaplines", Settings.ESP.Lines, function(v) Settings.ESP.Lines = v; SettingsV2.ESP.Lines = v end)
CreateToggle(espSec, "Name/Distance", Settings.ESP.Distance, function(v) Settings.ESP.Distance = v; SettingsV2.ESP.Distance = v; Settings.ESP.Name = v end)
CreateToggle(espSec, "ESP Box 3D (V1)", Settings.ESP.Box3D, function(v) Settings.ESP.Box3D = v end)
CreateToggle(espSec, "ESP Skeleton (V1)", Settings.ESP.Skeleton, function(v) Settings.ESP.Skeleton = v end)
CreateToggle(espSec, "Health/Weapon (V1)", Settings.ESP.Health, function(v) Settings.ESP.Health = v; Settings.ESP.Weapon = v end)

local combatTab = CreateTabButton("Combat", false)
local aimSec    = CreateSection(combatTab, "Aimbot Funcitons")
local secFov = CreateSection(combatTab, "Fov Functions")
local secExtra = CreateSection(combatTab, "Extra Functions")
CreateToggle(aimSec, "Aimbot", Settings.Aimbot.Enabled, function(v) Settings.Aimbot.Enabled = v; SettingsV2.Aimbot.Enabled = v end)
CreateCycle(aimSec, "Aim Method", {"CFrame", "Mouse"}, function(v) Settings.Aimbot.Method = v end)
CreateCycle(aimSec, "Activation Mode", {"Hold", "Always"}, function(v) Settings.Aimbot.Mode = v end)
CreateCycle(aimSec, "Target Part", {"Head", "HumanoidRootPart"}, function(v) Settings.Aimbot.TargetPart = v end)
CreateToggle(aimSec, "Wall Check", Settings.Aimbot.WallCheck, function(v) Settings.Aimbot.WallCheck = v end)
CreateToggle(aimSec, "Bullet Prediction", Settings.Aimbot.PredictionEnabled, function(v) Settings.Aimbot.PredictionEnabled = v end)
CreateSlider(aimSec, "Bullet Speed", 100, 5000, 1000, function(v) Settings.Aimbot.BulletSpeed = v end)
CreateSlider(aimSec, "Game Gravity", 0, 500, 196, function(v) Settings.Aimbot.Gravity = v end)

CreateToggle(secExtra, "Ignore Spawn Protection", Settings.IgnoreSpawnProtection, function(v) Settings.IgnoreSpawnProtection = v end)
CreateToggle(secExtra, "Trigger Bot (Auto-Fire)", Settings.Aimbot.TriggerBot, function(v) Settings.Aimbot.TriggerBot = v; SettingsV2.Aimbot.TriggerBot = v end)

CreateToggle(secFov, "Show FOV Circle", Settings.FOV.Visible, function(v) Settings.FOV.Visible = v end)
CreateSlider(secFov, "FOV Size", 30, 800, 100, function(v) Settings.FOV.Radius = v end)

local rageTab       = CreateTabButton("Rage", false)
local hvhSec        = CreateSection(rageTab, "HvH Protections")
local opSec         = CreateSection(rageTab, "OP Functions")
local killauraSec   = CreateSection(opSec, "Kill Aura")
local orbitSec      = CreateSection(opSec, "Orbit (like a bee)")
local magnetSec     = CreateSection(opSec, "Magnet")
local hitboxSec     = CreateSection(tabTroll, "Hitbox Expander")
CreateToggle(hvhSec, "Anti-Fling / Anti-Magnet", Settings.Misc.AntiFling, function(v) Settings.Misc.AntiFling = v end)
CreateToggle(hvhSec, "Anti-Aim (Spoofer)", Settings.Misc.AntiAim, function(v) Settings.Misc.AntiAim = v end)
CreateToggle(killauraSec, "Teleport Aura", Settings.Misc.TeleportAura, function(v) Settings.Misc.TeleportAura = v end)
CreateToggle(orbitSec, "Enemy Orbit", Settings.Misc.Orbit, function(v) Settings.Misc.Orbit = v end)
CreateSlider(orbitSec, "Orbit Speed", 1, 20, 5, function(v) Settings.Misc.OrbitSpeed = v end)
CreateSlider(orbitSec, "Orbit Radius", 2, 15, 5, function(v) Settings.Misc.OrbitDistance = v end)
CreateToggle(magnetSec, "Magnet Pull", Settings.Misc.Magnet, function(v) Settings.Misc.Magnet = v end)
CreateSlider(magnetSec, "Magnet Distance", 2, 50, 10, function(v) Settings.Misc.MagnetDistance = v end)
CreateToggle(hitboxSec, "Enable Expander", Settings.Misc.Wallbang, function(v) Settings.Misc.Wallbang = v end)
CreateCycle(hitboxSec, "Hitbox Mode", {"Giant Cube", "Sky Tower"}, function(v) Settings.Misc.WallbangMode = v end)
CreateSlider(hitboxSec, "Hitbox Width", 2, 50, 15, function(v) Settings.Misc.WallbangSize = v end)

local movTab = CreateTabButton("Movment", false)
local speedSec = CreateSection(movTab, "Speed Functions")
local flySec = CreateSection(movTab, "Fly Functions")
local noClipSec = CreateSection(movTab, "Fly Functions")
CreateToggle(speedSec, "Speed", Settings.Misc.SpeedEnabled, function(v) Settings.Misc.SpeedEnabled = v end)
CreateSlider(speedSec, "Speed Value", 16, 200, 16, function(v) Settings.Misc.SpeedValue = v end)
CreateToggle(flySec, "Fly", Settings.Misc.Fly, function(v) Settings.Misc.Fly = v; if v then EnableFly() else DisableFly() end end)
CreateToggle(flySec, "Infinite Jump", Settings.Misc.InfiniteJump, function(v) Settings.Misc.InfiniteJump = v end)
CreateToggle(noClipSec, "No Clip", Settings.Misc.NoClip, function(v) Settings.Misc.NoClip = v end)

local safeTab = CreateTabButton("Safe", false)
local antiSec = CreateSection(safeTab, "Anti Functions")

CreateToggle(antiSec, "Anti-Ragdoll (No Tripping/Falling)", Settings.Misc.AntiRagdoll, function(v) Settings.Misc.AntiRagdoll = v end)
CreateToggle(antiSec, "Anti-Fall (No Fall Damage)", Settings.Misc.AntiFall, function(v) Settings.Misc.AntiFall = v end)

local AntiAFKConnection = nil
CreateToggle(antiSec, "Anti-AFK (No Disconnect)", false, function(v) 
    if v then
        local VirtualUser = game:GetService("VirtualUser")
        AntiAFKConnection = LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    else
        if AntiAFKConnection then
            AntiAFKConnection:Disconnect()
            AntiAFKConnection = nil
        end
    end
end)

local farmTab = CreateTabButton("Farm", false)
local tycoonSec = CreateSection(farmTab, "Tycoon Functions")
CreateToggle(tycoonSec, "Tycoon Item Bringer", Settings.Misc.ItemDropBringer, function(v) Settings.Misc.ItemDropBringer = v end)
CreateButton(tycoonSec, "Set Item Spawn", function() 
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
        ItemSpawnLocation = LocalPlayer.Character.HumanoidRootPart.CFrame 
    end 
end)
CreateButton(tycoonSec, "Reset Spawn", function() ItemSpawnLocation = nil end)
CreateButton(tycoonSec, "Ghost Walker (Delete Doors)", function() 
    for _, v in ipairs(Workspace:GetDescendants()) do 
        if v:IsA("BasePart") then 
            local n = string.lower(v.Name) 
            if n:match("laser") or n:match("door") or n:match("owner") or n:match("gate") then 
                v:Destroy() 
            end 
        end 
    end 
end)
CreateButton(tycoonSec, "Steal Ground Tools", function() 
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") 
    if not myHRP then return end 
    for _, v in ipairs(Workspace:GetDescendants()) do 
        if v:IsA("Tool") and v:FindFirstChild("Handle") then 
            if firetouchinterest then 
                firetouchinterest(myHRP, v.Handle, 0)
                task.wait()
                firetouchinterest(myHRP, v.Handle, 1) 
            else 
                v.Handle.CFrame = myHRP.CFrame 
            end 
        end 
    end 
end)

local hudTab = CreateTabButton("Hud", false)
local uiSec = CreateSection(hudTab, "HUD & Overlays")
CreateToggle(uiSec, "Watermark", Settings.UI.ShowWatermark, function(v) Settings.UI.ShowWatermark = v; Watermark.Visible = v end)
CreateToggle(uiSec, "Radar", Settings.UI.ShowRadar, function(v) Settings.UI.ShowRadar = v; RadarBg.Visible = v end)
CreateToggle(uiSec, "Active Features", Settings.UI.ShowActiveMods, function(v) Settings.UI.ShowActiveMods = v; ActiveModsList.Visible = v end)
CreateSlider(uiSec, "Radar Zoom", 10, 200, 50, function(v) Settings.UI.RadarZoom = v end)

-- ==========================================================
-- // 6. RADAR UNIVERSAL DE INIMIGOS E TEAM CHECK (V1 E V2)
-- ==========================================================
local function IsAllyUniversal(enemyPlayer, enemyChar)
    if not Settings.TeamCheckGlobal then return false end
    if not enemyChar then return false end
    
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    if enemyPlayer and enemyPlayer == LocalPlayer then return true end

    local function isNeutral(val)
        if not val then return true end
        local s = tostring(val):lower()
        return s == "" or s == "none" or s == "neutral" or s == "ffa" or s == "0" or s == "independent" or s == "choosing" or s == "white"
    end

    if enemyPlayer then
        if LocalPlayer.Team ~= nil and enemyPlayer.Team ~= nil then
            if LocalPlayer.Team == enemyPlayer.Team then return true end
            return false
        end
        
        if LocalPlayer.TeamColor and enemyPlayer.TeamColor then
            if not isNeutral(LocalPlayer.TeamColor.Name) and not isNeutral(enemyPlayer.TeamColor.Name) then
                if LocalPlayer.TeamColor == enemyPlayer.TeamColor then return true end
                return false
            end
        end
    end

    local function checkMatch(obj1, obj2)
        if not obj1 or not obj2 then return nil end
        for k, v in pairs(obj1:GetAttributes()) do
            local lk = k:lower()
            if lk:match("team") or lk:match("faction") or lk:match("squad") or lk:match("group") then
                if not isNeutral(v) then
                    local v2 = obj2:GetAttribute(k)
                    if v2 ~= nil then
                        if v == v2 then return true else return false end 
                    end
                end
            end
        end
        for _, child in ipairs(obj1:GetChildren()) do
            if child:IsA("ValueBase") and child.Value ~= nil then
                local ln = child.Name:lower()
                if ln:match("team") or ln:match("faction") or ln:match("squad") or ln:match("group") then
                    if not isNeutral(child.Value) then
                        local enemyChild = obj2:FindFirstChild(child.Name)
                        if enemyChild and enemyChild.Value ~= nil then
                            if enemyChild.Value == child.Value then return true else return false end
                        end
                    end
                end
            end
        end
        return nil
    end

    if enemyPlayer then
        local pMatch = checkMatch(LocalPlayer, enemyPlayer)
        if pMatch ~= nil then return pMatch end
        
        local myLS = LocalPlayer:FindFirstChild("leaderstats")
        local eLS = enemyPlayer:FindFirstChild("leaderstats")
        if myLS and eLS then
            local lsMatch = checkMatch(myLS, eLS)
            if lsMatch ~= nil then return lsMatch end
        end
    end

    local cMatch = checkMatch(myChar, enemyChar)
    if cMatch ~= nil then return cMatch end

    if myChar.Parent and enemyChar.Parent and myChar.Parent == enemyChar.Parent then
        local pName = myChar.Parent.Name:lower()
        if pName:match("team") or pName:match("blue") or pName:match("red") or pName:match("ghost") or pName:match("phantom") or pName:match("guard") or pName:match("prisoner") then
            return true
        end
    end

    local myHigh = myChar:FindFirstChildOfClass("Highlight")
    local eHigh = enemyChar:FindFirstChildOfClass("Highlight")
    if myHigh and eHigh and myHigh.FillColor == eHigh.FillColor then return true end

    if not enemyPlayer then
        local eName = enemyChar.Name:lower()
        if eName:match("ally") or eName:match("friend") or eName:match("guard") or eName:match("pet") then return true end
        local ownerTag = enemyChar:FindFirstChild("Owner") or enemyChar:FindFirstChild("Creator")
        if ownerTag and ownerTag:IsA("ObjectValue") and ownerTag.Value == LocalPlayer then return true end
        if ownerTag and ownerTag:IsA("StringValue") and ownerTag.Value == LocalPlayer.Name then return true end
    end

    return false
end

local function IsAlly(player)
    return IsAllyUniversal(player, player and player.Character)
end

local function IsAllyV2(headPart)
    local enemyChar = headPart.Parent
    if not enemyChar then return false end
    local player = Players:GetPlayerFromCharacter(enemyChar)
    return IsAllyUniversal(player, enemyChar)
end

local function IsAliveAndValidV2(headPart, cam)
    if not headPart or not headPart.Parent or not headPart:IsDescendantOf(Workspace) then return false end
    if headPart:IsDescendantOf(cam) then return false end
    if (headPart.Position - cam.CFrame.Position).Magnitude < 4.5 then return false end
    
    local parentModel = headPart.Parent
    if not parentModel:IsA("Model") then return false end
    
    local currentAncestor = headPart.Parent
    while currentAncestor and currentAncestor ~= Workspace do
        local name = currentAncestor.Name:lower()
        if name:match("dead") or name:match("ragdoll") or name:match("corpse") or name:match("debris") then 
            return false 
        end
        currentAncestor = currentAncestor.Parent
    end
    
    local hum = parentModel:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end
    return true
end

-- ==========================================================
-- // 7. MOTOR V2 (MÉTODO DO HUMANOID VIRTUAL PROPORCIONAL)
-- ==========================================================
local function ProcessV2Players()
    local wsPlayers = Workspace:FindFirstChild("Players")
    if not wsPlayers then return false end
    
    local folders = wsPlayers:GetChildren()
    if #folders ~= 2 then return false end
    if wsPlayers:FindFirstChildOfClass("Model") then return false end

    local myTeamColorName = LocalPlayer.TeamColor and LocalPlayer.TeamColor.Name or ""
    local isPasta1MeuTime = (myTeamColorName == "Bright orange")

    local processedFolders = {}

    for teamIdx, teamFolder in ipairs(folders) do
        local isAlly = false
        if Settings.TeamCheckGlobal then
            if teamIdx == 1 and isPasta1MeuTime then isAlly = true end
            if teamIdx == 2 and not isPasta1MeuTime then isAlly = true end
        end

        for _, playerFolder in ipairs(teamFolder:GetChildren()) do
            processedFolders[playerFolder] = true
            local highestY = -math.huge
            local headPart = nil
            local partsPos = {}
            local partsList = {}

            for _, part in ipairs(playerFolder:GetChildren()) do
                if part:IsA("BasePart") then
                    table.insert(partsPos, part.Position)
                    table.insert(partsList, part)
                    if part.Position.Y > highestY then
                        highestY = part.Position.Y
                        headPart = part
                    end
                end
            end

            local torsoPos = Vector3.zero
            if #partsPos > 0 then
                for _, p in ipairs(partsPos) do torsoPos = torsoPos + p end
                torsoPos = torsoPos / #partsPos
            end

            if headPart then
                V2GlobalPlayers[playerFolder] = {
                    Head = headPart,
                    TorsoPos = torsoPos,
                    IsAlly = isAlly,
                    PartsList = partsList,
                    Folder = playerFolder
                }
            else
                V2GlobalPlayers[playerFolder] = nil
            end
        end
    end
    
    for f, _ in pairs(V2GlobalPlayers) do
        if not processedFolders[f] then V2GlobalPlayers[f] = nil end
    end
    
    return true
end

-- ==========================================================
-- // LÓGICA DE ALVO E WALLCHECK ORIGINAL (CORRIGIDA PRO V2)
-- ==========================================================
local function IsVisible(Part, cam)
    if not Settings.Aimbot.WallCheck then return true end
    local camPos = cam.CFrame.Position
    local dir = Part.Position - camPos
    
    local ignoreList = {LocalPlayer.Character, cam}
    local pfIgnore = Workspace:FindFirstChild("Ignore")
    if pfIgnore then table.insert(ignoreList, pfIgnore) end
    local pfRayIgnore = Workspace:FindFirstChild("RaycastIgnore")
    if pfRayIgnore then table.insert(ignoreList, pfRayIgnore) end

    GlobalRayParams.FilterDescendantsInstances = ignoreList
    local Result = Workspace:Raycast(camPos, dir, GlobalRayParams)
    if Result then
        if Result.Instance and Result.Instance:IsDescendantOf(Part.Parent) then
            return true
        end
        return false
    end
    return true
end

local function IsVisiblePF(targetPos, targetFolder, cam)
    if not Settings.Aimbot.WallCheck then return true end
    local origin = cam.CFrame.Position
    local dir = targetPos - origin
    
    local ignoreList = {LocalPlayer.Character, cam}
    if targetFolder then table.insert(ignoreList, targetFolder) end
    local pfIgnore = Workspace:FindFirstChild("Ignore")
    if pfIgnore then table.insert(ignoreList, pfIgnore) end
    local pfRayIgnore = Workspace:FindFirstChild("RaycastIgnore")
    if pfRayIgnore then table.insert(ignoreList, pfRayIgnore) end

    GlobalRayParams.FilterDescendantsInstances = ignoreList
    local Result = Workspace:Raycast(origin, dir, GlobalRayParams)
    return Result == nil
end

local function PredictBulletDrop(targetPos, targetVelocity, bulletSpeed, gravity, cam)
    if not targetPos then return Vector3.zero end
    local originPos = cam.CFrame.Position
    local distance = (targetPos - originPos).Magnitude
    local timeToTarget = distance / bulletSpeed
    
    local predictedPos = targetPos + (targetVelocity * timeToTarget)
    local bulletDrop = 0.5 * gravity * (timeToTarget ^ 2)
    return predictedPos + Vector3.new(0, bulletDrop, 0)
end

local function GetClosestEnemyPart()
    local closestPart, minDist = nil, Settings.ESP.MaxDistance
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position

    if Settings.CombatEngine == "V1 (Default)" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then
                local tPart = p.Character:FindFirstChild(Settings.Aimbot.TargetPart)
                if tPart and p.Character.Humanoid.Health > 0 and not IsAlly(p) and not HasSpawnProtection(p.Character) then
                    local dist = (tPart.Position - myPos).Magnitude
                    if dist < minDist then minDist = dist; closestPart = tPart end
                end
            end
        end
    else
        if ProcessV2Players() then
            for folder, data in pairs(V2GlobalPlayers) do
                if not data.IsAlly and data.Head then
                    local tPart = (Settings.Aimbot.TargetPart == "HumanoidRootPart") and (folder:FindFirstChild("HumanoidRootPart") or folder:FindFirstChild("Torso") or data.Head) or data.Head
                    local dist = (tPart.Position - myPos).Magnitude
                    if dist < minDist then minDist = dist; closestPart = tPart end
                end
            end
        else
            for headPart, _ in pairs(GlobalHeads) do
                -- TRAVA: Impede de focar na sua própria cabeça e bugar o script
                if LocalPlayer.Character and headPart:IsDescendantOf(LocalPlayer.Character) then continue end
                
                if IsAliveAndValidV2(headPart, Workspace.CurrentCamera) and not IsAllyV2(headPart) then
                    local tPart = headPart
                    if Settings.Aimbot.TargetPart == "HumanoidRootPart" then
                        tPart = headPart.Parent:FindFirstChild("HumanoidRootPart") or headPart.Parent:FindFirstChild("Torso") or headPart.Parent:FindFirstChild("LowerTorso") or headPart
                    end
                    local dist = (tPart.Position - myPos).Magnitude
                    if dist < minDist then minDist = dist; closestPart = tPart end
                end
            end
        end
    end
    return closestPart
end

local function GetAimbotTarget(cam)
    local Target, ShortestDist = nil, Settings.FOV.Radius
    local MousePos = UserInputService:GetMouseLocation()
    
    if Settings.CombatEngine == "V1 (Default)" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(Settings.Aimbot.TargetPart) and p.Character:FindFirstChild("Humanoid") then
                if p.Character.Humanoid.Health > 0 and not IsAlly(p) and not HasSpawnProtection(p.Character) then
                    local Part = p.Character[Settings.Aimbot.TargetPart]
                    if (Part.Position - cam.CFrame.Position).Magnitude > Settings.ESP.MaxDistance then continue end
                    
                    local ScreenPos, OnScreen = cam:WorldToViewportPoint(Part.Position)
                    if OnScreen then
                        local Magnitude = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                        if Magnitude < ShortestDist and IsVisible(Part, cam) then
                            if Settings.Aimbot.PredictionEnabled then
                                local predictedPos = PredictBulletDrop(Part.Position, Part.Velocity or Vector3.zero, Settings.Aimbot.BulletSpeed, Settings.Aimbot.Gravity, cam)
                                local predictedScreenPos, _ = cam:WorldToViewportPoint(predictedPos)
                                if predictedScreenPos then Target = predictedPos; ShortestDist = Magnitude end
                            else
                                Target = Part; ShortestDist = Magnitude
                            end
                        end
                    end
                end
            end
        end
    else
        local isPF = ProcessV2Players()
        
        if isPF then
            for folder, data in pairs(V2GlobalPlayers) do
                if not data.IsAlly and data.Head then
                    local targetPos = (Settings.Aimbot.TargetPart == "HumanoidRootPart") and data.TorsoPos or data.Head.Position
                    if (targetPos - cam.CFrame.Position).Magnitude > Settings.ESP.MaxDistance then continue end
                    
                    if Settings.Aimbot.PredictionEnabled then
                        local targetVel = data.Head.Velocity or Vector3.zero
                        targetPos = PredictBulletDrop(targetPos, targetVel, Settings.Aimbot.BulletSpeed, Settings.Aimbot.Gravity, cam)
                    end
                    local ScreenPos, OnScreen = cam:WorldToViewportPoint(targetPos)
                    if OnScreen then
                        local dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                        if dist < ShortestDist and IsVisiblePF(targetPos, folder, cam) then
                            Target = targetPos
                            ShortestDist = dist 
                        end
                    end
                end
            end
        else
            for headPart, _ in pairs(GlobalHeads) do
                if IsAliveAndValidV2(headPart, cam) and not IsAllyV2(headPart) then
                    if (headPart.Position - cam.CFrame.Position).Magnitude > Settings.ESP.MaxDistance then continue end
                    if LocalPlayer.Character and headPart:IsDescendantOf(LocalPlayer.Character) then continue end
                    
                    local tPart = headPart
                    if Settings.Aimbot.TargetPart == "HumanoidRootPart" then
                        tPart = headPart.Parent:FindFirstChild("HumanoidRootPart") or headPart.Parent:FindFirstChild("Torso") or headPart.Parent:FindFirstChild("LowerTorso") or headPart
                    end

                    local tPos = tPart.Position
                    if Settings.Aimbot.PredictionEnabled then
                        tPos = PredictBulletDrop(tPart.Position, tPart.Velocity or Vector3.zero, Settings.Aimbot.BulletSpeed, Settings.Aimbot.Gravity, cam)
                    end

                    local ScreenPos, OnScreen = cam:WorldToViewportPoint(tPos)
                    if OnScreen then
                        local dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                        if dist < ShortestDist then
                            if IsVisible(tPart, cam) then 
                                Target = Settings.Aimbot.PredictionEnabled and tPos or tPart
                                ShortestDist = dist 
                            end
                        end
                    end
                end
            end
        end
    end
    return Target
end

-- ==========================================================
-- // 8. FUNÇÕES DE DESENHO DE ESP (V1 E V2)
-- ==========================================================
local function GetCharacterBounds(char)
    local minX, maxX, minY, maxY, minZ, maxZ
    local parts = {}
    for _, part in ipairs(char:GetChildren()) do 
        if part:IsA("BasePart") then table.insert(parts, part) end
        if part:IsA("Accessory") and part:FindFirstChild("Handle") then table.insert(parts, part.Handle) end 
    end
    if #parts == 0 then return nil end
    local firstPos = parts[1].Position
    minX, maxX, minY, maxY, minZ, maxZ = firstPos.X, firstPos.X, firstPos.Y, firstPos.Y, firstPos.Z, firstPos.Z
    for _, part in ipairs(parts) do
        local pos, size = part.Position, part.Size
        local halfSize = size / 2
        minX = math.min(minX, pos.X - halfSize.X)
        maxX = math.max(maxX, pos.X + halfSize.X)
        minY = math.min(minY, pos.Y - halfSize.Y)
        maxY = math.max(maxY, pos.Y + halfSize.Y)
        minZ = math.min(minZ, pos.Z - halfSize.Z)
        maxZ = math.max(maxZ, pos.Z + halfSize.Z)
    end
    return { 
        Min = Vector3.new(minX, minY, minZ), 
        Max = Vector3.new(maxX, maxY, maxZ), 
        Center = Vector3.new((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2) 
    }
end

local function GetBoxCorners(bounds, cam)
    local corners = {}
    local points = { 
        Vector3.new(bounds.Min.X, bounds.Min.Y, bounds.Min.Z), Vector3.new(bounds.Max.X, bounds.Min.Y, bounds.Min.Z), 
        Vector3.new(bounds.Max.X, bounds.Min.Y, bounds.Max.Z), Vector3.new(bounds.Min.X, bounds.Min.Y, bounds.Max.Z), 
        Vector3.new(bounds.Min.X, bounds.Max.Y, bounds.Min.Z), Vector3.new(bounds.Max.X, bounds.Max.Y, bounds.Min.Z), 
        Vector3.new(bounds.Max.X, bounds.Max.Y, bounds.Max.Z), Vector3.new(bounds.Min.X, bounds.Max.Y, bounds.Max.Z) 
    }
    for i, point in ipairs(points) do 
        local screenPos, onScreen = cam:WorldToViewportPoint(point)
        corners[i] = onScreen and Vector2.new(screenPos.X, screenPos.Y) or Vector2.new(0, 0) 
    end
    return corners
end

local function UpdateESP(cam)
    local viewport = cam.ViewportSize
    if viewport.X <= 1 or viewport.Y <= 1 then
        return
    end

    for player, esp in pairs(ESPPlayers) do
        if not player or not player.Parent then
            CleanPlayerESP(player)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            if ESPPlayers[player] then
                HideESP(ESPPlayers[player])
            end
            continue
        end

        local char = player.Character
        local hrp = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
        local humanoid = char and char:FindFirstChild("Humanoid")

        if not char or not humanoid or not hrp or humanoid.Health <= 0 or hrp.Position.X ~= hrp.Position.X or HasSpawnProtection(char) then
            if ESPPlayers[player] then
                HideESP(ESPPlayers[player])
            end
            continue
        end

        local anchorPos = hrp.Position
        local distRaw = (anchorPos - cam.CFrame.Position).Magnitude
        if distRaw > Settings.ESP.MaxDistance then
            if ESPPlayers[player] then
                HideESP(ESPPlayers[player])
            end
            continue
        end

        local espColor = IsAlly(player) and Settings.ESP.AllyColor or Settings.ESP.EnemyColor

        if not ESPPlayers[player] then
            ESPPlayers[player] = {
                Box2D = {},
                Box3D = {},
                Skeleton = {},
                HealthBar = {}
            }

            for i = 1, 4 do
                ESPPlayers[player].Box2D[i] = DrawingAPI.new("Line")
                ESPPlayers[player].Box2D[i].Thickness = 1.5
                ESPPlayers[player].Box2D[i].Visible = false
            end

            for i = 1, 12 do
                ESPPlayers[player].Box3D[i] = DrawingAPI.new("Line")
                ESPPlayers[player].Box3D[i].Thickness = 1
                ESPPlayers[player].Box3D[i].Visible = false
            end

            for i = 1, 5 do
                ESPPlayers[player].Skeleton[i] = DrawingAPI.new("Line")
                ESPPlayers[player].Skeleton[i].Thickness = 1.5
                ESPPlayers[player].Skeleton[i].Visible = false
            end

            -- HealthBar (1-4 = outline, 5 = fundo, 6 = preenchimento)
            for i = 1, 6 do
                ESPPlayers[player].HealthBar[i] = DrawingAPI.new("Line")
                ESPPlayers[player].HealthBar[i].Visible = false
            end

            ESPPlayers[player].HealthBar[1].Thickness = 4
            ESPPlayers[player].HealthBar[2].Thickness = 4
            ESPPlayers[player].HealthBar[3].Thickness = 4
            ESPPlayers[player].HealthBar[4].Thickness = 4
            ESPPlayers[player].HealthBar[5].Thickness = 2
            ESPPlayers[player].HealthBar[6].Thickness = 2

            ESPPlayers[player].Snapline = DrawingAPI.new("Line")
            ESPPlayers[player].Snapline.Thickness = 1
            ESPPlayers[player].Snapline.Visible = false

            ESPPlayers[player].DistanceText = DrawingAPI.new("Text")
            ESPPlayers[player].DistanceText.Size = 14
            ESPPlayers[player].DistanceText.Center = true
            ESPPlayers[player].DistanceText.Outline = true
            ESPPlayers[player].DistanceText.Visible = false

            ESPPlayers[player].NameText = DrawingAPI.new("Text")
            ESPPlayers[player].NameText.Size = 14
            ESPPlayers[player].NameText.Center = true
            ESPPlayers[player].NameText.Outline = true
            ESPPlayers[player].NameText.Visible = false

            ESPPlayers[player].WeaponText = DrawingAPI.new("Text")
            ESPPlayers[player].WeaponText.Size = 14
            ESPPlayers[player].WeaponText.Center = true
            ESPPlayers[player].WeaponText.Outline = true
            ESPPlayers[player].WeaponText.Visible = false
        end

        local esp = ESPPlayers[player]

        if not Settings.ESP.Box2D
            and not Settings.ESP.Box3D
            and not Settings.ESP.Skeleton
            and not Settings.ESP.Lines
            and not Settings.ESP.Name
            and not Settings.ESP.Distance
            and not Settings.ESP.Health
            and not Settings.ESP.Weapon then
            HideESP(esp)
            continue
        end

        local top3D = anchorPos + Vector3.new(0, 2.5, 0)
        local bot3D = anchorPos - Vector3.new(0, 3, 0)

        local top2D, topOn = cam:WorldToViewportPoint(top3D)
        local bot2D, botOn = cam:WorldToViewportPoint(bot3D)
        local center2D, centerOn = cam:WorldToViewportPoint(anchorPos)

        if top2D.Z < 0 or bot2D.Z < 0 or center2D.Z < 0 then
            HideESP(esp)
            continue
        end

        if not topOn and not botOn and not centerOn then
            HideESP(esp)
            continue
        end

        local height = math.abs(top2D.Y - bot2D.Y)
        local width = height * 0.55
        local x = top2D.X

        local tl = Vector2.new(x - width / 2, top2D.Y)
        local tr = Vector2.new(x + width / 2, top2D.Y)
        local bl = Vector2.new(x - width / 2, bot2D.Y)
        local br = Vector2.new(x + width / 2, bot2D.Y)

        -- BOX 2D
        if Settings.ESP.Box2D and (topOn or botOn) then
            esp.Box2D[1].From = tl; esp.Box2D[1].To = tr
            esp.Box2D[2].From = tr; esp.Box2D[2].To = br
            esp.Box2D[3].From = br; esp.Box2D[3].To = bl
            esp.Box2D[4].From = bl; esp.Box2D[4].To = tl

            for _, line in ipairs(esp.Box2D) do
                line.Color = espColor
                line.Visible = true
            end
        else
            for _, line in ipairs(esp.Box2D) do
                line.Visible = false
            end
        end

        -- HEALTH BAR NA ESQUERDA
        if Settings.ESP.Health and (topOn or botOn) then
            -- TRAVA DE SEGURANÇA CONTRA BUG DE DIVISÃO POR ZERO (NaN)
            local maxHp = humanoid.MaxHealth
            if maxHp <= 0 then maxHp = 100 end 
            
            local hp = math.clamp(humanoid.Health / maxHp, 0, 1)
            if hp ~= hp then hp = 0 end -- Trava final contra Not-a-Number

            local barX = tl.X - 6
            local barTop = tl.Y
            local barBottom = bl.Y
            local fillHeight = (barBottom - barTop) * hp
            local fillTopY = barBottom - fillHeight

            local hpColor = Color3.fromRGB(
                math.floor(255 * (1 - hp)),
                math.floor(255 * hp),
                0
            )

            -- outline
            esp.HealthBar[1].From = Vector2.new(barX, barTop)
            esp.HealthBar[1].To = Vector2.new(barX, barBottom)
            esp.HealthBar[2].From = Vector2.new(barX + 2, barTop)
            esp.HealthBar[2].To = Vector2.new(barX + 2, barBottom)
            esp.HealthBar[3].From = Vector2.new(barX - 1, barTop)
            esp.HealthBar[3].To = Vector2.new(barX + 3, barTop)
            esp.HealthBar[4].From = Vector2.new(barX - 1, barBottom)
            esp.HealthBar[4].To = Vector2.new(barX + 3, barBottom)

            esp.HealthBar[1].Color = Color3.new(0, 0, 0)
            esp.HealthBar[2].Color = Color3.new(0, 0, 0)
            esp.HealthBar[3].Color = Color3.new(0, 0, 0)
            esp.HealthBar[4].Color = Color3.new(0, 0, 0)

            esp.HealthBar[1].Visible = true
            esp.HealthBar[2].Visible = true
            esp.HealthBar[3].Visible = true
            esp.HealthBar[4].Visible = true

            -- fundo
            esp.HealthBar[5].From = Vector2.new(barX + 1, barTop)
            esp.HealthBar[5].To = Vector2.new(barX + 1, barBottom)
            esp.HealthBar[5].Color = Color3.fromRGB(35, 35, 35)
            esp.HealthBar[5].Visible = true

            -- preenchimento
            esp.HealthBar[6].From = Vector2.new(barX + 1, fillTopY)
            esp.HealthBar[6].To = Vector2.new(barX + 1, barBottom)
            esp.HealthBar[6].Color = hpColor
            esp.HealthBar[6].Visible = true
        else
            for _, line in ipairs(esp.HealthBar) do
                line.Visible = false
            end
        end

        -- BOX 3D
        if Settings.ESP.Box3D then
            local bounds = GetCharacterBounds(char)
            if bounds then
                local corners = GetBoxCorners(bounds, cam)
                for i, conn in ipairs(Box3DConnections) do
                    if esp.Box3D[i] and corners[conn[1]] and corners[conn[2]] then
                        esp.Box3D[i].From = corners[conn[1]]
                        esp.Box3D[i].To = corners[conn[2]]
                        esp.Box3D[i].Color = espColor
                        esp.Box3D[i].Visible = true
                    end
                end
            else
                for _, line in ipairs(esp.Box3D) do
                    line.Visible = false
                end
            end
        else
            for _, line in ipairs(esp.Box3D) do
                line.Visible = false
            end
        end

        -- SKELETON
        if Settings.ESP.Skeleton then
            local head = char:FindFirstChild("Head")
            local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
            local leftArm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
            local rightArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
            local leftLeg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
            local rightLeg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")

            local function drawBone(p1, p2, idx)
                if p1 and p2 then
                    local pos1, os1 = cam:WorldToViewportPoint(p1.Position)
                    local pos2, os2 = cam:WorldToViewportPoint(p2.Position)

                    if (os1 or os2) and esp.Skeleton[idx] then
                        esp.Skeleton[idx].From = Vector2.new(pos1.X, pos1.Y)
                        esp.Skeleton[idx].To = Vector2.new(pos2.X, pos2.Y)
                        esp.Skeleton[idx].Color = espColor
                        esp.Skeleton[idx].Visible = true
                    elseif esp.Skeleton[idx] then
                        esp.Skeleton[idx].Visible = false
                    end
                elseif esp.Skeleton[idx] then
                    esp.Skeleton[idx].Visible = false
                end
            end

            drawBone(head, torso, 1)
            drawBone(torso, leftArm, 2)
            drawBone(torso, rightArm, 3)
            drawBone(torso, leftLeg, 4)
            drawBone(torso, rightLeg, 5)
        else
            for _, line in ipairs(esp.Skeleton) do
                line.Visible = false
            end
        end

        -- SNAPLINE
        if Settings.ESP.Lines then
            esp.Snapline.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
            esp.Snapline.To = Vector2.new(center2D.X, center2D.Y)
            esp.Snapline.Color = espColor
            esp.Snapline.Visible = true
        else
            esp.Snapline.Visible = false
        end

        -- TEXTOS (Nome, Distância, Arma)
        local textY = bot2D.Y + 5

        if Settings.ESP.Distance then
            esp.DistanceText.Text = "[ " .. math.floor(distRaw) .. "m ]"
            esp.DistanceText.Position = Vector2.new(center2D.X, textY)
            esp.DistanceText.Color = Color3.new(1, 1, 1)
            esp.DistanceText.Visible = true
            textY = textY + 14
        else
            esp.DistanceText.Visible = false
        end

        if Settings.ESP.Name then
            esp.NameText.Text = player.Name
            esp.NameText.Position = Vector2.new(center2D.X, textY)
            esp.NameText.Color = espColor
            esp.NameText.Visible = true
            textY = textY + 14
        else
            esp.NameText.Visible = false
        end

        if Settings.ESP.Weapon then
            local tool = char:FindFirstChildOfClass("Tool")
            local weaponName = tool and tool.Name or "No Gun"

            esp.WeaponText.Text = "[ " .. weaponName .. " ]"
            esp.WeaponText.Position = Vector2.new(center2D.X, textY)
            esp.WeaponText.Color = Color3.fromRGB(200, 200, 200)
            esp.WeaponText.Visible = true
        else
            esp.WeaponText.Visible = false
        end
    end
end

-- ==========================================================
-- // ESP POOLING V2 (Otimização Extrema de Memória)
-- ==========================================================
local ESPPoolV2 = {}

local function GetPooledESP(index)
    if ESPPoolV2[index] then return ESPPoolV2[index] end
    
    local esp = {
        Box = DrawingAPI.new("Square"),
        Snapline = DrawingAPI.new("Line"),
        DistanceText = DrawingAPI.new("Text"),
        Box2D = {}
    }
    esp.Box.Thickness = 1
    esp.Box.Filled = false
    esp.Snapline.Thickness = 1
    esp.DistanceText.Size = 14
    esp.DistanceText.Center = true
    esp.DistanceText.Outline = true
    
    for i = 1, 4 do
        esp.Box2D[i] = DrawingAPI.new("Line")
        esp.Box2D[i].Thickness = 1.5
        esp.Box2D[i].Visible = false
    end
    
    ESPPoolV2[index] = esp
    return esp
end

local function HidePooledESP(esp)
    if esp.Box.Visible then esp.Box.Visible = false end
    if esp.Snapline.Visible then esp.Snapline.Visible = false end
    if esp.DistanceText.Visible then esp.DistanceText.Visible = false end
    for i = 1, 4 do
        if esp.Box2D[i].Visible then esp.Box2D[i].Visible = false end
    end
end

local function UpdateESPV2(cam)
    local viewport = cam.ViewportSize
    if viewport.X <= 1 or viewport.Y <= 1 then return end
    
    local isPF = ProcessV2Players()
    local poolIndex = 1 -- Controla qual ESP do "estoque" vamos usar
    
    if isPF then
        for folder, data in pairs(V2GlobalPlayers) do
            local headPart = data.Head
            local distRaw = (headPart.Position - cam.CFrame.Position).Magnitude
            if distRaw > Settings.ESP.MaxDistance then continue end
            
            local isAlly = data.IsAlly
            local espColor = isAlly and Settings.ESP.AllyColor or Settings.ESP.EnemyColor
            local esp = GetPooledESP(poolIndex)
            poolIndex = poolIndex + 1

            if not Settings.ESP.Box2D and not Settings.ESP.Lines and not Settings.ESP.Distance then 
                HidePooledESP(esp) continue 
            end
            
            local minX, minY = math.huge, math.huge
            local maxX, maxY = -math.huge, -math.huge
            local onScreenCount = 0

            for _, part in ipairs(data.PartsList) do
                local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                if onScreen and screenPos.Z > 0 then
                    onScreenCount = onScreenCount + 1
                    if screenPos.X < minX then minX = screenPos.X end
                    if screenPos.X > maxX then maxX = screenPos.X end
                    if screenPos.Y < minY then minY = screenPos.Y end
                    if screenPos.Y > maxY then maxY = screenPos.Y end
                end
            end

            if onScreenCount > 0 then
                local rawHeight = maxY - minY
                local padding = rawHeight * 0.3
                local finalMinY = minY - padding
                local finalHeight = rawHeight + (padding * 2)
                local finalWidth = finalHeight * 0.55 
                local centerX = minX + ((maxX - minX) / 2)
                local finalMinX = centerX - (finalWidth / 2)

                if Settings.ESP.Box2D then
                    esp.Box.Size = Vector2.new(finalWidth, finalHeight)
                    esp.Box.Position = Vector2.new(finalMinX, finalMinY)
                    esp.Box.Color = espColor
                    esp.Box.Visible = true
                else
                    esp.Box.Visible = false
                end

                if Settings.ESP.Lines then 
                    esp.Snapline.From = Vector2.new(viewport.X/2, viewport.Y)
                    esp.Snapline.To = Vector2.new(centerX, maxY)
                    esp.Snapline.Color = espColor
                    esp.Snapline.Visible = true 
                else 
                    esp.Snapline.Visible = false 
                end
                
                if Settings.ESP.Distance then
                    esp.DistanceText.Text = "["..math.floor(distRaw).."m]"
                    esp.DistanceText.Position = Vector2.new(centerX, maxY + 5)
                    esp.DistanceText.Color = espColor
                    esp.DistanceText.Visible = true
                else 
                    esp.DistanceText.Visible = false 
                end
            else
                HidePooledESP(esp)
            end
        end
    else
        -- Jogos genéricos rodando no motor V2
        for headPart, _ in pairs(GlobalHeads) do
            if not IsAliveAndValidV2(headPart, cam) or headPart.Position.X ~= headPart.Position.X then 
                GlobalHeads[headPart] = nil
                continue 
            end
            
            local distRaw = (headPart.Position - cam.CFrame.Position).Magnitude
            if distRaw > Settings.ESP.MaxDistance then continue end
            if LocalPlayer.Character and headPart:IsDescendantOf(LocalPlayer.Character) then continue end
            
            local espColor = IsAllyV2(headPart) and Settings.ESP.AllyColor or Settings.ESP.EnemyColor
            local esp = GetPooledESP(poolIndex)
            poolIndex = poolIndex + 1

            if not Settings.ESP.Box2D and not Settings.ESP.Lines and not Settings.ESP.Distance then 
                HidePooledESP(esp) continue 
            end
            
            local anchorPart = headPart.Parent:FindFirstChild("HumanoidRootPart") or headPart.Parent:FindFirstChild("LowerTorso") or headPart.Parent:FindFirstChild("Torso") or headPart
            local anchorPos = anchorPart.Position
            local topPos = anchorPos + Vector3.new(0, 2.8, 0)
            local bottomPos = anchorPos - Vector3.new(0, 2.8, 0)

            local topScreen, topOn = cam:WorldToViewportPoint(topPos)
            local botScreen, botOn = cam:WorldToViewportPoint(bottomPos)
            local headScreen, headOn = cam:WorldToViewportPoint(headPart.Position)

            if not topOn and not botOn and not headOn then
                HidePooledESP(esp)
                continue
            end

            if Settings.ESP.Box2D and (topOn or botOn) then
                local height = math.abs(topScreen.Y - botScreen.Y)
                local width = height * 0.55
                local x = topScreen.X

                local tl = Vector2.new(x - width/2, topScreen.Y)
                local tr = Vector2.new(x + width/2, topScreen.Y)
                local bl = Vector2.new(x - width/2, botScreen.Y)
                local br = Vector2.new(x + width/2, botScreen.Y)
                
                esp.Box2D[1].From = tl; esp.Box2D[1].To = tr
                esp.Box2D[2].From = tr; esp.Box2D[2].To = br
                esp.Box2D[3].From = br; esp.Box2D[3].To = bl
                esp.Box2D[4].From = bl; esp.Box2D[4].To = tl
                
                for _, line in ipairs(esp.Box2D) do 
                    line.Color = espColor
                    line.Visible = true 
                end
            else 
                for _, line in ipairs(esp.Box2D) do line.Visible = false end 
            end

            if Settings.ESP.Lines and headOn then 
                esp.Snapline.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                esp.Snapline.To = Vector2.new(headScreen.X, headScreen.Y)
                esp.Snapline.Color = espColor
                esp.Snapline.Visible = true 
            else 
                esp.Snapline.Visible = false 
            end
            
            if Settings.ESP.Distance then
                esp.DistanceText.Text = "["..math.floor(distRaw).."m]"
                esp.DistanceText.Position = Vector2.new(headScreen.X, botScreen.Y + 5)
                esp.DistanceText.Color = espColor
                esp.DistanceText.Visible = true
            else 
                esp.DistanceText.Visible = false 
            end
        end
    end
    
    -- Desliga qualquer ESP que não foi usado nesse frame
    for i = poolIndex, #ESPPoolV2 do
        HidePooledESP(ESPPoolV2[i])
    end
end


-- ==========================================================
-- // 9. LOOPS PRINCIPAIS UNIFICADOS E FÍSICA
-- ==========================================================
local function IsValidHead(part)
    if not part:IsA("BasePart") then return false end
    local n = part.Name:lower()
    if n == "head" or n == "fakehead" or n == "hitboxhead" then return true end
    return false
end

pcall(function() 
    for _, v in ipairs(Workspace:GetDescendants()) do 
        if IsValidHead(v) then GlobalHeads[v] = v end 
    end 
end)

Workspace.DescendantAdded:Connect(function(v) 
    if IsValidHead(v) then GlobalHeads[v] = v end 
end)

task.spawn(function()
    while task.wait(0.2) do
        if not Settings.Enabled then continue end
        
        if Settings.Misc.Wallbang or Settings.Misc.Wallbang == false then
            local targetSize = Settings.Misc.WallbangMode == "Sky Tower" and Vector3.new(Settings.Misc.WallbangSize, 500, Settings.Misc.WallbangSize) or Vector3.new(Settings.Misc.WallbangSize, Settings.Misc.WallbangSize, Settings.Misc.WallbangSize)
            
            if Settings.CombatEngine == "V1 (Default)" then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local head = p.Character:FindFirstChild("Head")
                        local hum = p.Character:FindFirstChild("Humanoid")
                        if head and hum and hum.Health > 0 and not IsAlly(p) and not HasSpawnProtection(p.Character) then
                            if Settings.Misc.Wallbang then
                                if head.Size ~= targetSize then
                                    head.Size = targetSize
                                    head.Transparency = 0.7
                                    head.Massless = true
                                end
                                head.CanCollide = false
                            elseif head.Size.X > 2 or head.Size.Y > 5 then
                                head.Size = Vector3.new(1.2, 1.2, 1.2)
                                head.Transparency = 0
                                head.CanCollide = true
                                head.Massless = false
                            end
                        end
                    end
                end
            else
                local cam = Workspace.CurrentCamera
                for headPart, _ in pairs(GlobalHeads) do
                    if IsAliveAndValidV2(headPart, cam) and not IsAllyV2(headPart) then
                        if not (LocalPlayer.Character and headPart:IsDescendantOf(LocalPlayer.Character)) then
                            if Settings.Misc.Wallbang then
                                if headPart.Size ~= targetSize then
                                    headPart.Size = targetSize
                                    headPart.Transparency = 0.7
                                    headPart.Massless = true
                                end
                                headPart.CanCollide = false
                            elseif headPart.Size.X > 2 or headPart.Size.Y > 5 then
                                headPart.Size = Vector3.new(1.2, 1.2, 1.2)
                                headPart.Transparency = 0
                                headPart.CanCollide = true
                                headPart.Massless = false
                            end
                        end
                    end
                end
            end
        end

        if Settings.Misc.ItemDropBringer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myHRP = LocalPlayer.Character.HumanoidRootPart
            local dest = ItemSpawnLocation or myHRP.CFrame
            pcall(function() 
                for _, v in ipairs(Workspace:GetChildren()) do 
                    if v:IsA("BasePart") and not v.Anchored and not v.Locked and not v.Parent:FindFirstChild("Humanoid") then 
                        if (v.Position - dest.Position).Magnitude > 20 then 
                            v.CFrame = dest 
                        end 
                    end 
                end 
            end)
        end
    end
end)

-- ANTI-RAGDOLL E ANTI-FALL LOOP
task.spawn(function()
    while task.wait(0.5) do
        if not Settings.Enabled then continue end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            local hum = LocalPlayer.Character.Humanoid
            pcall(function()
                if Settings.Misc.AntiFall then
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
                else
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
                end
                
                if Settings.Misc.AntiRagdoll then
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                else
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                end
            end)
        end
    end
end)

local toggleDormancy = false
task.spawn(function()
    while task.wait(1) do
        if Settings.Enabled then
            toggleDormancy = not toggleDormancy
            local offset = toggleDormancy and 0.001 or -0.001
            pcall(function() 
                for _, player in ipairs(Players:GetPlayers()) do 
                    if player ~= LocalPlayer and player.Character then 
                        for _, part in ipairs(player.Character:GetChildren()) do 
                            if part:IsA("BasePart") then 
                                part.LocalTransparencyModifier = part.LocalTransparencyModifier + offset 
                            end 
                        end 
                    end 
                end 
            end)
        end
    end
end)

local LastEngine = Settings.CombatEngine

RunService.Heartbeat:Connect(function(dt)
    if not Settings.Enabled then return end
    local cam = Workspace.CurrentCamera

    if Settings.Misc.AntiFling and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myHRP = LocalPlayer.Character.HumanoidRootPart
        if myHRP.Velocity.Magnitude > 250 and not Settings.Misc.Fly and not Settings.Misc.SpeedEnabled then
            myHRP.Velocity = Vector3.zero
            myHRP.RotVelocity = Vector3.zero
        end
        for _, p in ipairs(Players:GetPlayers()) do 
            if p ~= LocalPlayer and p.Character then 
                for _, part in ipairs(p.Character:GetChildren()) do 
                    if part:IsA("BasePart") then 
                        part.CanCollide = false 
                    end 
                end 
            end 
        end
    end

    if Settings.Misc.AntiAim and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myHRP = LocalPlayer.Character.HumanoidRootPart
        RealVelocity = myHRP.Velocity
        myHRP.Velocity = Vector3.new(math.random(-2000, 2000), math.random(-2000, 2000), math.random(-2000, 2000))
    end

	-- ==========================================================
    -- DETECTOR DE TROCA DE MOTOR (MATA OS FANTASMAS)
    -- ==========================================================
    if LastEngine ~= Settings.CombatEngine then
        if Settings.CombatEngine == "V1 (Default)" then
            -- Se trocou pro V1, limpa todos os desenhos órfãos do V2
            for _, esp in ipairs(ESPPoolV2) do HidePooledESP(esp) end
        else
            -- Se trocou pro V2, limpa todos os desenhos órfãos do V1
            for _, esp in pairs(ESPPlayers) do HideESP(esp) end
        end
        LastEngine = Settings.CombatEngine -- Atualiza a memória
    end

    -- REMOVIDO PCALL AQUI PARA GANHO MASSIVO DE FPS
    if Settings.CombatEngine == "V1 (Default)" then 
        UpdateESP(cam) 
    else 
        UpdateESPV2(cam) 
    end
    
    if Settings.Misc.Magnet and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myHRP = LocalPlayer.Character.HumanoidRootPart
        local lookVector = cam.CFrame.LookVector
        local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
        if flatLook.Magnitude ~= flatLook.Magnitude then flatLook = Vector3.new(0,0,1) end
        
        local targetPos = myHRP.Position + (flatLook * Settings.Misc.MagnetDistance)
        
        if Settings.CombatEngine == "V1 (Default)" then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local eHRP = p.Character:FindFirstChild("HumanoidRootPart")
                    local eHum = p.Character:FindFirstChild("Humanoid")
                    if eHRP and eHum and eHum.Health > 0 and not IsAlly(p) and not HasSpawnProtection(p.Character) then 
                        eHum.PlatformStand = true
                        eHRP.Velocity = Vector3.zero
                        eHRP.RotVelocity = Vector3.zero
                        eHRP.CFrame = CFrame.new(targetPos)
                    elseif eHum and eHum.Health <= 0 then 
                        eHum.PlatformStand = false 
                    end
                end
            end
        else
            if ProcessV2Players() then
                for folder, data in pairs(V2GlobalPlayers) do
                    if not data.IsAlly and data.Head then
                        for _, part in ipairs(data.PartsList) do
                            if part:IsA("BasePart") then part.Velocity = Vector3.zero; part.RotVelocity = Vector3.zero; part.CFrame = CFrame.new(targetPos) end
                        end
                    end
                end
            else
                -- NOVO: Puxa NPCs pelo GlobalHeads no Motor V2
                for headPart, _ in pairs(GlobalHeads) do
                    if LocalPlayer.Character and headPart:IsDescendantOf(LocalPlayer.Character) then continue end
                    
                    if IsAliveAndValidV2(headPart, cam) and not IsAllyV2(headPart) then
                        local enemyChar = headPart.Parent
                        if enemyChar then
                            local eHRP = enemyChar:FindFirstChild("HumanoidRootPart") or enemyChar:FindFirstChild("Torso") or enemyChar:FindFirstChild("LowerTorso") or headPart
                            local eHum = enemyChar:FindFirstChildOfClass("Humanoid")
                            
                            if eHum then eHum.PlatformStand = true end
                            if eHRP and eHRP:IsA("BasePart") then
                                eHRP.Velocity = Vector3.zero
                                eHRP.RotVelocity = Vector3.zero
                                eHRP.CFrame = CFrame.new(targetPos)
                            end
                        end
                    end
                end
            end
        end
    else
        -- Desativa o Magnet e restaura a física dos jogadores/NPCs pra eles caírem
        if Settings.CombatEngine == "V1 (Default)" then
            for _, p in ipairs(Players:GetPlayers()) do 
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then 
                    p.Character.Humanoid.PlatformStand = false 
                end 
            end
        else
            for headPart, _ in pairs(GlobalHeads) do
                local enemyChar = headPart.Parent
                if enemyChar then
                    local eHum = enemyChar:FindFirstChildOfClass("Humanoid")
                    if eHum then eHum.PlatformStand = false end
                end
            end
        end
    end

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local HRP = LocalPlayer.Character.HumanoidRootPart
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        pcall(function()
            if Settings.Misc.SpeedEnabled and Hum and Hum.MoveDirection.Magnitude > 0 and not FlyActive then 
                HRP.CFrame = HRP.CFrame + (Hum.MoveDirection * (Settings.Misc.SpeedValue / 50)) 
            end
            if Settings.Misc.NoClip then 
                for _, v in ipairs(LocalPlayer.Character:GetChildren()) do 
                    if v:IsA("BasePart") then v.CanCollide = false end 
                end 
            end
        end)
    end
end)

-- // RENDER STEP OTIMIZADO PARA FOV, HUD E RADAR
local LastTick = tick()
local FrameCount = 0
local ActiveModsTimer = 0
local RadarTimer = 0
local WatermarkTimer = 0

local ActiveBadgePool = {}
local ActiveModsDirty = true

local RadarDotPool = {}

local StatsService = game:GetService("Stats")

local function GetActiveBadge(index)
    local badge = ActiveBadgePool[index]
    if badge then
        return badge
    end

    badge = Instance.new("Frame")
    badge.Size = UDim2.new(0, 0, 0, 22)
    badge.AutomaticSize = Enum.AutomaticSize.X
    badge.BackgroundColor3 = Theme.OverlayBg
    badge.BackgroundTransparency = 0.2
    badge.Visible = false
    badge.Parent = ActiveModsList

    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", badge).Color = Theme.Accent

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = badge

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.Parent = badge

    ActiveBadgePool[index] = badge
    return badge
end

local function BuildActiveModsList()
    local activeList = {}

    table.insert(activeList, "Motor: " .. (Settings.CombatEngine == "V1 (Default)" and "V1" or "V2"))
    if Settings.TeamCheckGlobal then table.insert(activeList, "Team Check") end
    if Settings.IgnoreSpawnProtection then table.insert(activeList, "Spawn Ignore") end
    if Settings.Aimbot.Enabled then table.insert(activeList, "Aimbot [" .. Settings.Aimbot.Method .. "]") end
    if Settings.Aimbot.TriggerBot then table.insert(activeList, "Trigger Bot") end
    if Settings.Aimbot.WallCheck then table.insert(activeList, "Wall Check") end
    if Settings.Aimbot.PredictionEnabled then table.insert(activeList, "Bullet Prediction") end
    if Settings.FOV.Visible then table.insert(activeList, "FOV Circle") end
    if Settings.ESP.Box2D then table.insert(activeList, "ESP Box 2D") end
    if Settings.ESP.Box3D then table.insert(activeList, "ESP Box 3D") end
    if Settings.ESP.Lines then table.insert(activeList, "ESP Snaplines") end
    if Settings.ESP.Skeleton then table.insert(activeList, "ESP Skeleton") end
    if Settings.ESP.Distance or Settings.ESP.Name then table.insert(activeList, "ESP Name/Dist") end
    if Settings.ESP.Health or Settings.ESP.Weapon then table.insert(activeList, "ESP Gun/Life") end
    if Settings.UI.ShowRadar then table.insert(activeList, "Radar") end
    if Settings.Misc.AntiFling then table.insert(activeList, "Anti-Fling/Magnet") end
    if Settings.Misc.AntiAim then table.insert(activeList, "Anti-Aim") end
    if Settings.Misc.AntiRagdoll then table.insert(activeList, "Anti-Ragdoll") end
    if Settings.Misc.AntiFall then table.insert(activeList, "Anti-Fall") end
    if Settings.Misc.Orbit then table.insert(activeList, "Orbit Aura") end
    if Settings.Misc.TeleportAura then table.insert(activeList, "TP Aura") end
    if Settings.Misc.Magnet then table.insert(activeList, "Magnet Pull") end
    if Settings.Misc.ItemDropBringer then table.insert(activeList, "Item Bringer") end
    if Settings.Misc.Wallbang then table.insert(activeList, "Hitbox Expander") end
    if Settings.Misc.SpeedEnabled then table.insert(activeList, "Speed: " .. tostring(Settings.Misc.SpeedValue)) end
    if Settings.Misc.Fly then table.insert(activeList, "Fly Mode") end
    if Settings.Misc.NoClip then table.insert(activeList, "No Clip") end
    if Settings.Misc.InfiniteJump then table.insert(activeList, "Infinite Jump") end

    return activeList
end

local function RefreshActiveMods()
    if not Settings.UI.ShowActiveMods then
        for _, badge in ipairs(ActiveBadgePool) do
            badge.Visible = false
        end
        return
    end

    local activeList = BuildActiveModsList()

    for i, text in ipairs(activeList) do
        local badge = GetActiveBadge(i)
        badge.Label.Text = text
        badge.Visible = true
    end

    for i = #activeList + 1, #ActiveBadgePool do
        ActiveBadgePool[i].Visible = false
    end
end

local function GetRadarDot(index)
    local dot = RadarDotPool[index]
    if dot then
        return dot
    end

    dot = Instance.new("Frame")
    dot.Name = "RadarDot"
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.BorderSizePixel = 0
    dot.Visible = false
    dot.Parent = RadarBg

    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    RadarDotPool[index] = dot
    return dot
end

local function RefreshRadar(cam)
    if not Settings.UI.ShowRadar then
        for _, dot in ipairs(RadarDotPool) do
            dot.Visible = false
        end
        return
    end

    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then
        for _, dot in ipairs(RadarDotPool) do
            dot.Visible = false
        end
        return
    end

    local dotIndex = 1
    local radarHalfX = RadarBg.AbsoluteSize.X * 0.5
    local radarHalfY = RadarBg.AbsoluteSize.Y * 0.5

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer
            and p.Character
            and p.Character:FindFirstChild("HumanoidRootPart")
            and p.Character:FindFirstChild("Humanoid")
            and p.Character.Humanoid.Health > 0 then

            local dist = (p.Character.HumanoidRootPart.Position - cam.CFrame.Position).Magnitude
            if dist < Settings.ESP.MaxDistance then
                local relPos = cam.CFrame:PointToObjectSpace(p.Character.HumanoidRootPart.Position)
                local mappedX = (relPos.X / Settings.UI.RadarZoom) * radarHalfX
                local mappedY = (relPos.Z / Settings.UI.RadarZoom) * radarHalfY

                if math.abs(mappedX) < radarHalfX and math.abs(mappedY) < radarHalfY then
                    local dot = GetRadarDot(dotIndex)
                    dot.Position = UDim2.new(0.5, mappedX - 2, 0.5, mappedY - 2)
                    dot.BackgroundColor3 = IsAlly(p) and Settings.ESP.AllyColor or Settings.ESP.EnemyColor
                    dot.Visible = true
                    dotIndex += 1
                end
            end
        end
    end

    for i = dotIndex, #RadarDotPool do
        RadarDotPool[i].Visible = false
    end
end

RunService.RenderStepped:Connect(function(dt)
    if not Settings.Enabled then
        FOVCircle.Visible = false

        for _, badge in ipairs(ActiveBadgePool) do
            badge.Visible = false
        end

        for _, dot in ipairs(RadarDotPool) do
            dot.Visible = false
        end

        return
    end

    local cam = Workspace.CurrentCamera

    if not cam then
        FOVCircle.Visible = false
        return
    end

    -- 1. WATERMARK
    if Settings.UI.ShowWatermark then
        FrameCount += 1
        WatermarkTimer += dt

        if WatermarkTimer >= 1 then
            WatermarkTimer = 0

            local fps = FrameCount
            FrameCount = 0

            local ping = 0
            pcall(function()
                ping = StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
            end)

            local alive = 0
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                    alive += 1
                end
            end

            WText.Text = string.format(
                "%s | FPS: %d | Ping: %dms | Alive: %d",
                Settings.UI.WatermarkText,
                fps,
                ping,
                alive
            )
        end
    end

    -- 2. ACTIVE MODS
    ActiveModsTimer += dt
    if ActiveModsDirty or ActiveModsTimer >= 0.20 then
        ActiveModsTimer = 0
        ActiveModsDirty = false
        RefreshActiveMods()
    end

    -- 3. RADAR
    RadarTimer += dt
    if RadarTimer >= 0.05 then
        RadarTimer = 0
        RefreshRadar(cam)
    end

    -- 4. FOV CIRCLE E TRIGGERBOT
    FOVCircle.Visible = Settings.FOV.Visible
    if Settings.FOV.Visible then 
        FOVCircle.Radius = Settings.FOV.Radius
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Color = Settings.FOV.Color 
    end

    if Settings.Aimbot.TriggerBot and not TriggerBotCooldown then
        local shouldShoot = false
        local triggerTarget = GetAimbotTarget(cam)
        if triggerTarget then
            local tPos = typeof(triggerTarget) == "Vector3" and triggerTarget or triggerTarget.Position
            local screenPos, onScreen = cam:WorldToViewportPoint(tPos)
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist <= 20 then shouldShoot = true end
            end
        end

        if shouldShoot then
            TriggerBotCooldown = true
            task.spawn(function() 
                if mouse1press then 
                    pcall(function() mouse1press(); task.wait(0.01); mouse1release() end) 
                elseif mouse1click then 
                    pcall(function() mouse1click() end) 
                end
                task.wait(0.05)
                TriggerBotCooldown = false 
            end)
        end
    end
end)

-- // BINDTORENDERSTEP (PRIORIDADE MÁXIMA PARA O AIMBOT)
RunService:BindToRenderStep("EliteCombatLock", 2000, function(dt)
    if not Settings.Enabled then return end
    local cam = Workspace.CurrentCamera

    -- 1. Orbit e Teleport Aura
    if Settings.Misc.Orbit or Settings.Misc.TeleportAura then
        local targetPart = GetClosestEnemyPart()
        if targetPart and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myHRP = LocalPlayer.Character.HumanoidRootPart
            
            local aimPos = typeof(targetPart) == "Vector3" and targetPart or targetPart.Position
            
            if Settings.Misc.Orbit then
                OrbitAngle = OrbitAngle + (dt * Settings.Misc.OrbitSpeed)
                local offset = Vector3.new(math.cos(OrbitAngle), 0, math.sin(OrbitAngle)) * Settings.Misc.OrbitDistance
                myHRP.CFrame = CFrame.lookAt(aimPos + offset + Vector3.new(0, Settings.Misc.TeleportHeight, 0), aimPos)
            else
                local targetCFrame = typeof(targetPart) == "CFrame" and targetPart or (targetPart.CFrame or CFrame.new(aimPos))
                local offsetZ = Settings.Misc.TeleportBehind and -Settings.Misc.TeleportDistance or Settings.Misc.TeleportDistance
                myHRP.CFrame = CFrame.lookAt(aimPos + (targetCFrame.LookVector * offsetZ) + Vector3.new(0, Settings.Misc.TeleportHeight, 0), aimPos)
            end
            myHRP.Velocity = Vector3.zero
            
            cam.CFrame = CFrame.lookAt(cam.CFrame.Position, aimPos)
            return 
        end
    end

    -- 2. Aimbot Manual (HARD LOCK)
    if Settings.Aimbot.Enabled then
        local IsActive = Settings.Aimbot.Mode == "Always" or (Settings.Aimbot.Mode == "Hold" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
        if IsActive then
            local aimTarget = GetAimbotTarget(cam)
            
            if aimTarget then
                local pos = typeof(aimTarget) == "Vector3" and aimTarget or aimTarget.Position
                
                if Settings.Aimbot.Method == "CFrame" then
                    pcall(function() 
                        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, pos) 
                    end)
                elseif Settings.Aimbot.Method == "Mouse" then
                    local sPos, on = cam:WorldToViewportPoint(pos)
                    if on and mousemoverel then
                        local viewport = cam.ViewportSize
                        local centerX = viewport.X * 0.5
                        local centerY = viewport.Y * 0.5

                        local dx = sPos.X - centerX
                        local dy = sPos.Y - centerY
                        
                        pcall(function() mousemoverel(dx, dy) end)
                    end
                end
            end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if UserInputService:GetFocusedTextBox() then return end
    
    if input.KeyCode == Enum.KeyCode.T and Settings.Enabled then 
        local tHRP = GetClosestEnemyPart()
        if tHRP and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            task.spawn(function()
                for i = 1, 3 do
                    local myHRP = LocalPlayer.Character.HumanoidRootPart
                    local tCFrame = Settings.Misc.TeleportBehind and (tHRP.CFrame + (tHRP.CFrame.LookVector * -Settings.Misc.TeleportDistance)) or (tHRP.CFrame + (tHRP.CFrame.LookVector * Settings.Misc.TeleportDistance))
                    
                    LocalPlayer.Character:PivotTo(CFrame.lookAt(tCFrame.Position + Vector3.new(0, Settings.Misc.TeleportHeight, 0), tHRP.Position))
                    myHRP.Velocity = Vector3.new(0,0,0)
                    myHRP.RotVelocity = Vector3.new(0,0,0)
                    task.wait()
                end
            end)
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Settings.Enabled and Settings.Misc.InfiniteJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        pcall(function() 
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping") 
        end)
    end
end)
