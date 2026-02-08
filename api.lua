local replicatedstorage = game:GetService("ReplicatedStorage")
local player = game:GetService("Players").LocalPlayer
local teamwork = replicatedstorage:WaitForChild("Teawork")
local bytenet = require(teamwork.Shared.Services.ByteNetworking)

local api = {}

-- Original environment variables for state tracking
local env = getgenv()
env.totalplacedtowers = 0
env.firsttower = 1
env.isroundover = false

-- MODIFIED: Removed the loops that check for wave and timer.
-- It now returns true instantly so actions trigger immediately.
function waitTime(time, wave)
    return not env.isroundover
end

function api:Start()
    bytenet.Timescale.SetTimescale.send(2)
    
    local mapinfo = replicatedstorage.RoundInfo
    local roundresultui = player.PlayerGui.GameUI.RoundResult

    -- Listen for round end to stop actions
    roundresultui:GetPropertyChangedSignal("Visible"):Connect(function()
        env.isroundover = roundresultui.Visible
    end)
    
    print("API Started: Time and Wave checks disabled.")
end

function api:Loadout(towers)
    for i = 1, #towers do
        bytenet.Inventory.EquipTower.invoke({["TowerID"] = towers[i], ["Slot"] = i})
        task.wait(0.5)
    end
end

function api:Map(map, modifiers)
    bytenet.MatchmakingNew.CreateSingleplayer.invoke({
        ["Gamemode"] = "Standard", 
        ["MapID"] = map, 
        ["Modifiers"] = modifiers
    })
end

function api:Loop(func)
    while task.wait(0.03) do
        if not env.isroundover then
            func()
        end
    end
end

-- ACTIONS: These now ignore the 'time' and 'wave' arguments passed to them.
function api:Place(tower, position, time, wave)
    if waitTime(time, wave) then	
        env.totalplacedtowers = env.totalplacedtowers + 1
        bytenet.Towers.PlaceTower.invoke({
            ["Position"] = position, 
            ["Rotation"] = 0, 
            ["TowerID"] = tower
        })
    end
end

function api:Upgrade(tower, time, wave)
    if waitTime(time, wave) then
        local realindex = env.firsttower + (tower - 1)
        bytenet.Towers.UpgradeTower.invoke(realindex)
    end
end

function api:Sell(tower, time, wave)
    if waitTime(time, wave) then
        local realindex = env.firsttower + (tower - 1)
        bytenet.Towers.SellTower.invoke(realindex)
    end
end

function api:SetTarget(tower, target, time, wave)
    if waitTime(time, wave) then
        local realindex = env.firsttower + (tower - 1)
        bytenet.Towers.SetTargetMode.send({
            ["UID"] = realindex, 
            ["TargetMode"] = target
        })
    end
end

function api:PlayAgain()
    while not env.isroundover do task.wait(0.1) end
    env.firsttower = env.totalplacedtowers + 1
    task.wait(1)
    bytenet.RoundResult.VoteForRestart.send(true)
end

return api
