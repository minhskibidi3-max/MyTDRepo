local replicatedstorage = game:GetService("ReplicatedStorage")

local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/ovoch228/depthsoimgui/refs/heads/main/library'))()

local bytenet = require(replicatedstorage:WaitForChild("Teawork"):WaitForChild("Shared"):WaitForChild("Services"):WaitForChild("ByteNetworking"))

local api = {}

function api:Loadout(towers: table)
	if game.PlaceId ~= 98936097545088 then return end

	for i = 1, #towers do
		bytenet.Inventory.EquipTower.invoke({["TowerID"] = towers[i], ["Slot"] = i})
		task.wait(0.5)
	end
end

function api:Map(map: string, modifiers: table)
	if game.PlaceId ~= 98936097545088 then return end
	
	bytenet.MatchmakingNew.CreateSingleplayer.invoke({["Gamemode"] = "Standard", ["MapID"] = map, ["Modifiers"] = modifiers})
end

if game.PlaceId ~= 124069847780670 then return api end

local towers = bytenet.Towers
local mapinfo = replicatedstorage.RoundInfo

local roundresultui = game:GetService("Players").LocalPlayer.PlayerGui.GameUI.RoundResult

local ostime = os.time
local taskwait = task.wait
local env = getgenv()

env.StratName = "Strat"

env.timer = 0 -- seconds
env.lasttime = ostime()
env.waveinfo = 1
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
