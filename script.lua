--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local guiParent = player:WaitForChild("PlayerGui")
local RS = game:GetService("ReplicatedStorage")

--// CORES
local COR_BG         = Color3.fromRGB(15, 15, 25)
local COR_BG_ATIVO   = Color3.fromRGB(30, 40, 60)
local COR_FUNDO      = Color3.fromRGB(10, 10, 20)
local COR_TITULO     = Color3.fromRGB(200, 220, 255)
local COR_KILL       = Color3.fromRGB(255, 80, 80)
local COR_WATER      = Color3.fromRGB(80, 180, 255)

--// STATE
local killAtivo = false
local killRodando = false
local waterAtivo = false
local entity = nil
local t2 = nil
local fluidos = {8, 9, 10, 11}
local IDInfo = require(RS:WaitForChild("IDInfo"))

-- ⭐ Debounce (trava)
local killProcessando = false
local waterProcessando = false

-- ⭐ Guarda os valores originais
local backupIDInfo = {}
for _, id in ipairs(fluidos) do
    if IDInfo[id] then
        backupIDInfo[id] = {
            fluid = IDInfo[id].fluid,
            nonsolid = IDInfo[id].nonsolid
        }
    end
end

-- ⭐ Guarda as tabelas modificadas (pra restaurar)
local tabelasBackup = {}

--// FUNCTIONS
local function findLocalEntity(retries)
    retries = retries or 400
    for tentativa = 1, retries do
        for _, func in ipairs(getgc()) do
            if type(func) == "function" then
                local info = debug.getinfo(func)
                if info and info.source and info.source:find("LocalEntity") then
                    local upvalues = debug.getupvalues(func)
                    for _, v in ipairs(upvalues) do
                        if type(v) == "table" and v.Size ~= nil and v.Pos ~= nil then
                            return v
                        end
                    end
                end
            end
        end
        task.wait(0.50)
    end
    return nil
end

local function findT2(retries)
    retries = retries or 400
    for tentativa = 1, retries do
        for _, func in ipairs(getgc()) do
            if type(func) == "function" then
                local info = debug.getinfo(func)
                if info and info.source and info.source:find("ClientScript") then
                    local upvalues = debug.getupvalues(func)
                    for i, v in ipairs(upvalues) do
                        if type(v) == "table" then
                            local count = 0
                            for uuid, ent in pairs(v) do
                                if type(ent) == "table" and ent.UUID and ent.id then
                                    count = count + 1
                                end
                            end
                            if count > 0 then
                                return v
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.50)
    end
    return nil
end

local function iniciarKillAura()
    killRodando = true
    task.spawn(function()
        while killRodando do
            task.wait(0.5)
            if not killRodando then break end
            if not entity then entity = findLocalEntity(10) end
            if not t2 then t2 = findT2(10) end
            
            if entity and t2 then
                local myPos = entity.Pos
                local nearestUUID = nil
                local nearestEnt = nil
                local nearestDist = 10
                
                for uuid, ent in pairs(t2) do
                    if ent.UUID and ent.Pos and ent.Health and ent.Health > 0 then
                        local entPos
                        if type(ent.Pos) == "table" then
                            entPos = Vector3.new(ent.Pos[1], ent.Pos[2], ent.Pos[3])
                        else
                            entPos = ent.Pos
                        end
                        local dist = (entPos - myPos).Magnitude
                        if dist < nearestDist then
                            nearestDist = dist
                            nearestEnt = ent
                            nearestUUID = uuid
                        end
                    end
                end
                
                if nearestEnt then
                    print("⚔️ Atacando:", nearestEnt.id, "| Dist:", math.floor(nearestDist))
                    game.ReplicatedStorage.SendState:InvokeServer({
                        iattack = true,
                        targetEntity = nearestUUID,
                        pos = myPos,
                        targetBlock = Vector3.new(0, 0, 0),
                        targetBlockNor = Vector3.new(0, 1, 0),
                        rotation = Vector2.new(0, 0),
                        motion = Vector3.new(0, -0.0784, 0),
                        onGround = 22,
                        ibreak = false, iplace = false, iuse = false, iinteract = false,
                        ieat = false, ieaten = false, iswing = false, isit = false,
                        ijump = false, icraft = false, ibroken = false, Fell = 0, Sneak = false,
                    })
                else
                    print("❌ Nenhum mob a 10 studs")
                end
            end
        end
    end)
end

local function pararKillAura()
    killRodando = false
end

-- ⭐ ATIVAR WATER (guarda backup)
local function ativarWater()
    -- Guarda o IDInfo original
    for _, id in ipairs(fluidos) do
        if IDInfo[id] then
            backupIDInfo[id] = {
                fluid = IDInfo[id].fluid,
                nonsolid = IDInfo[id].nonsolid
            }
            IDInfo[id].fluid = false
            IDInfo[id].nonsolid = false
        end
    end
    
    -- Guarda as tabelas e modifica
    tabelasBackup = {}
    for _, func in ipairs(getgc()) do
        if type(func) == "function" then
            local ok, upvalues = pcall(debug.getupvalues, func)
            if ok and upvalues then
                for i, v in ipairs(upvalues) do
                    if type(v) == "table" then
                        local modificou = false
                        for _, id in ipairs(fluidos) do
                            if v[id] == true then
                                v[id] = nil
                                modificou = true
                            end
                        end
                        if modificou then
                            table.insert(tabelasBackup, { tabela = v, id = i })
                        end
                    end
                end
            end
        end
    end
    print("🌊 Walk On Water ATIVADO!")
end

-- ⭐ DESATIVAR WATER (restaura backup)
local function desativarWater()
    -- Restaura o IDInfo
    for _, id in ipairs(fluidos) do
        if IDInfo[id] and backupIDInfo[id] then
            IDInfo[id].fluid = backupIDInfo[id].fluid
            IDInfo[id].nonsolid = backupIDInfo[id].nonsolid
        end
    end
    
    -- Restaura as tabelas
    for _, backup in ipairs(tabelasBackup) do
        for _, id in ipairs(fluidos) do
            if backup.tabela[id] == nil then
                backup.tabela[id] = true
            end
        end
    end
    tabelasBackup = {}
    print("🌊 Walk On Water DESATIVADO (água/lava restauradas)")
end

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "KillAuraGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = guiParent

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 220, 0, 150)
main.Position = UDim2.new(0.5, -110, 0.4, -125)
main.BackgroundColor3 = COR_FUNDO
main.Parent = gui
main.Active = true
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Extra++"
title.TextColor3 = COR_TITULO
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextStrokeTransparency = 0
title.TextStrokeColor3 = Color3.new(0, 0, 0)

local container = Instance.new("Frame", main)
container.Size = UDim2.new(1, -20, 1, -40)
container.Position = UDim2.new(0, 10, 0, 35)
container.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 8)

local function createButton(text, cor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Text = text
    btn.BackgroundColor3 = COR_BG
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = cor
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.TextStrokeTransparency = 0
    btn.TextStrokeColor3 = Color3.new(0, 0, 0)
    btn.Parent = container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

-- ⚔️ KILL AURA
local btnKill = createButton("⚔️ KILL AURA: OFF", COR_KILL)
btnKill.Activated:Connect(function()
    -- ⭐ Se já tá processando, ignora
    if killProcessando then return end
    killProcessando = true
    
    if killAtivo then
        killAtivo = false
        btnKill.Text = "⏳ DISABLING..."
        btnKill.BackgroundColor3 = COR_BG
        task.wait(1)
        pararKillAura()
        btnKill.Text = "⚔️ KILL AURA: OFF"
        print("⚔️ Kill Aura DESATIVADO")
    else
        killAtivo = true
        btnKill.Text = "⏳  ENABLING..."
        btnKill.BackgroundColor3 = COR_BG_ATIVO
        task.wait(1)
        iniciarKillAura()
        btnKill.Text = "⚔️ KILL AURA: ON"
        btnKill.BackgroundColor3 = Color3.fromRGB(60, 25, 25)
        print("⚔️ Kill Aura ATIVADO")
    end
    
    -- ⭐ Libera o clique
    killProcessando = false
end)

-- 🌊 WALK ON WATER
local btnWater = createButton("🌊 WALK ON WATER: OFF", COR_WATER)
btnWater.Activated:Connect(function()
    -- ⭐ Se já tá processando, ignora
    if waterProcessando then return end
    waterProcessando = true
    
    if waterAtivo then
        waterAtivo = false
        btnWater.Text = "⏳ DISABLING..."
        btnWater.BackgroundColor3 = COR_BG
        task.wait(1)
        desativarWater()
        btnWater.Text = "🌊 WALK ON WATER: OFF"
        print("🌊 Walk On Water DESATIVADO")
    else
        waterAtivo = true
        btnWater.Text = "⏳ ENABLING..."
        btnWater.BackgroundColor3 = COR_BG_ATIVO
        task.wait(1)
        ativarWater()
        btnWater.Text = "🌊 WALK ON WATER: ON"
        btnWater.BackgroundColor3 = Color3.fromRGB(25, 40, 70)
        print("🌊 Walk On Water ATIVADO")
    end
    
    -- ⭐ Libera o clique
    waterProcessando = false
end)

-- DRAG
local dragging, dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

print("✅ GUI carregada!")