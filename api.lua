local replicatedstorage = game:GetService("ReplicatedStorage")
local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/ovoch228/depthsoimgui/refs/heads/main/library'))()
local bytenet = require(replicatedstorage:WaitForChild("Teawork"):WaitForChild("Shared"):WaitForChild("Services"):WaitForChild("ByteNetworking"))

local api = {}

--// Removed PlaceId check so this can run in the Lobby/Matchmaking
function api:Loadout(towers: table)
	for i = 1, #towers do
		bytenet.Inventory.EquipTower.invoke({["TowerID"] = towers[i], ["Slot"] = i})
		task.wait(0.5)
	end
end

--// Removed PlaceId check
function api:Map(map: string, modifiers: table)
	bytenet.MatchmakingNew.CreateSingleplayer.invoke({["Gamemode"] = "Standard", ["MapID"] = map, ["Modifiers"] = modifiers})
end

--// Logic variables
local towers = bytenet.Towers
local mapinfo = replicatedstorage:WaitForChild("RoundInfo")
local player = game:GetService("Players").LocalPlayer
local roundresultui = player.PlayerGui:WaitForChild("GameUI").RoundResult

local ostime = os.time
local taskwait = task.wait
local env = getgenv()

-- Initialize environment
env.StratName = env.StratName or "Strat"
env.timer = 0 
env.lasttime = ostime()
env.waveinfo = 1
env.isroundover = false
env.totalplacedtowers = 0
env.firsttower = 1

--// UI SETUP
local window = library:CreateWindow({
    Title = "MINH CUSTOM API",
    Size = UDim2.new(0, 350, 0, 370),
    Position = UDim2.new(0.5, 0, 0, 70),
    NoResize = false
})
window:Center()

local logtab = window:CreateTab({ Name = "Macro Player", Visible = true })
local filename = logtab:Label({ Text = "StratName: " .. env.StratName })
local loglabel = logtab:Label({ Label = "Last Log: Voting" })

local logstab = window:CreateTab({ Name = "Logs", Visible = true })
logstab:Separator({ Text = "Logs:" })
local logs = logstab:Console({
	Text = "",
	ReadOnly = true,
	AutoScroll = true,
	RichText = true,
	MaxLines = 200
})

function updatelog(text: string)
	logs:AppendText(DateTime.now():FormatLocalTime("HH:mm:ss", "en-us") .. ":", text)
	loglabel:SetText("Last Log: " .. text)
end

--// TIMING LOGIC
-- To make this "instant", this function now returns true immediately
function waitTime(time, wave)
	return not env.isroundover
end

function api:Loop(func)
	while taskwait(0.03) do				
		if not env.isroundover then
            pcall(func)
        end
	end
end

function api:Start()
	bytenet.Timescale.SetTimescale.send(2)
	env.waveinfo = mapinfo:GetAttribute("Wave") or 1
	env.timer = 0
	
	mapinfo:GetAttributeChangedSignal("Wave"):Connect(function()
		env.waveinfo = mapinfo:GetAttribute("Wave")
	end)

	roundresultui:GetPropertyChangedSignal("Visible"):Connect(function()
		env.isroundover = roundresultui.Visible
	end)
	
	updatelog("Game Started")
		
	task.spawn(function()
		env.lasttime = ostime()
		while env.lasttime do
			env.timer = (ostime() - env.lasttime) * 2
			taskwait(0.25)
		end
	end)
end

function api:Difficulty(diff: string)
	updatelog(`Voted difficulty {diff}`)
	bytenet.DifficultyVote.Vote.send(diff)
	while #mapinfo:GetAttribute("Difficulty") == 0 do taskwait(0.05) end 
	env.lasttime = ostime()
	env.timer = 0
	env.waveinfo = 1
	taskwait(0.1)
end

--// ACTIONS (Fixed headers to accept time/wave arguments)
function api:Ready(time, wave)
	if waitTime(time, wave) then updatelog("Sent ready vote") bytenet.ReadyVote.Vote.send(true) end
end

function api:Skip(time, wave)
	if waitTime(time, wave) then updatelog(`Skipping Wave {wave}`) replicatedstorage:WaitForChild("ByteNetReliable"):FireServer(buffer.fromstring("\148\001")) end
end

function api:AutoSkip(enable, time, wave)
	if waitTime(time, wave) then updatelog(`AutoSkip set to {tostring(enable)}`) bytenet.SkipWave.ToggleAutoSkip.send(enable) end
end

function api:Place(tower, position, time, wave)
	if waitTime(time, wave) then	
		env.totalplacedtowers = env.totalplacedtowers + 1
		updatelog(`Placed Tower {tower}`)
		towers.PlaceTower.invoke({["Position"] = position, ["Rotation"] = 0, ["TowerID"] = tower})
	end
end

function api:Upgrade(tower, time, wave)
	if waitTime(time, wave) then
		updatelog(`Upgraded Tower {tower}`)
		local realindex = env.firsttower + (tower - 1)
		towers.UpgradeTower.invoke(realindex)
	end
end

function api:SetTarget(tower, target, time, wave)
	if waitTime(time, wave) then
		updatelog(`Changed Tower {tower} Target to {target} `)
		local realindex = env.firsttower + (tower - 1)
		towers.SetTargetMode.send({["UID"] = (realindex), ["TargetMode"] = target})
	end
end

function api:Sell(tower, time, wave)
	if waitTime(time, wave) then
		updatelog(`Sold Tower {tower}`) 
		local realindex = env.firsttower + (tower - 1)
		towers.SellTower.invoke(realindex)
	end
end

function api:PlayAgain()
	while not env.isroundover do taskwait(0.1) end
	env.firsttower = env.totalplacedtowers + 1
	env.lasttime = ostime()
	env.timer = 0
	env.waveinfo = 1
	taskwait(1)
	bytenet.RoundResult.VoteForRestart.send(true)
	updatelog("Voted for restart")
end

return api
