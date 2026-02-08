local replicatedstorage = game:GetService("ReplicatedStorage")
local player = game:GetService("Players").LocalPlayer
local teamwork = replicatedstorage:WaitForChild("Teawork")
local bytenet = require(teamwork.Shared.Services.ByteNetworking)

-- Load the UI Library you like
local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/ovoch228/depthsoimgui/refs/heads/main/library'))()

local api = {}

-- 1. Create the API Window
local window = library:CreateWindow({
    Title = "MY PRIVATE API",
    Size = UDim2.new(0, 350, 0, 370),
    Position = UDim2.new(0.5, 0, 0, 70),
    NoResize = false
})
window:Center()

local logtab = window:CreateTab({ Name = "Status", Visible = true })
local loglabel = logtab:Label({ Text = "Current Task: Waiting..." })

local function updatelog(text)
    loglabel:SetText("Current Task: " .. text)
    print("API LOG: " .. text)
end

-- 2. API Functions
function api:Start()
    bytenet.Timescale.SetTimescale.send(2)
    updatelog("Match Started - Timescale Set")
end

function api:Place(towerID, position, time, wave)
    updatelog("Placing: " .. towerID)
    bytenet.Towers.PlaceTower.invoke({
        ["Position"] = position, 
        ["Rotation"] = 0, 
        ["TowerID"] = towerID
    })
end

function api:Upgrade(index, time, wave)
    updatelog("Upgrading Tower Index: " .. index)
    bytenet.Towers.UpgradeTower.invoke(index)
end

function api:Loop(func)
    task.spawn(function()
        while task.wait(0.1) do
            pcall(func)
        end
    end)
end

function api:PlayAgain()
    updatelog("Match Over - Voting Restart")
    task.wait(2)
    bytenet.RoundResult.VoteForRestart.send(true)
end

-- Add any other functions you want (Loadout, Map, etc.) here

return api
