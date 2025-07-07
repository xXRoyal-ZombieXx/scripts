local OrionLib = loadstring(game:HttpGet("https://twix.cyou/Orion.txt", true))()
local Threads = {}
local PlayerThreads = {}
local LocalPlayer = game.Players.LocalPlayer
local Character = LocalPlayer.Character
local ActiveTarget = nil
local AutoLock = false
local Range = 100
local UIS = game:GetService("UserInputService")
local DBR = 20
local TargetSelectInput = Enum.KeyCode.R
local Mouse = LocalPlayer:GetMouse()

--//Functions\\--
function playerIsPlayer(Name)
    for i,v in pairs(game.Players:GetPlayers()) do
        if v.Name == Name then
            return true
        end
    end
    return false
end

function checkPlayersInRange(range)
    local pInRange = {}
    for _, Player in pairs(game.Workspace.Live:GetChildren()) do
        if LocalPlayer:DistanceFromCharacter(Player.HumanoidRootPart.Position) <= Range and Player.Name ~= LocalPlayer.Name and playerIsPlayer(Player.Name) then
            pInRange[#pInRange+1] = {
                ["Player"] = Player,
                Magnitude = LocalPlayer:DistanceFromCharacter(Player.HumanoidRootPart.Position),
            }
        end
    end
    if next(pInRange) and #pInRange >1 then
        table.sort(pInRange, function(a, b) return a.Magnitude < b.Magnitude end)
    end
    return pInRange
end

function block()
    workspace.Live.Qxackxs.Main.RemoteEvent:FireServer("Blocking", true)
end
function unblock()
    workspace.Live.Qxackxs.Main.RemoteEvent:FireServer("DestroyBlock")
end
function Look(Player)
        local Position = Vector3.new(Player.HumanoidRootPart.Position.X, Character.HumanoidRootPart.Position.Y, Player.HumanoidRootPart.Position.Z)
        Character.HumanoidRootPart.CFrame = CFrame.lookAt(Character.HumanoidRootPart.Position,Position, Vector3.new(0,2,0))
end
function getPlayerWithID(id)
    for i,v in pairs(game.Players:GetPlayers()) do
        if v.UserId == id then 
            return v
        end
    end
end

function fakeLagDownslamMove()

end

--//Task Scheduling\\--

Threads["CameraThingy"] = task.spawn(function()
    while game:GetService('RunService').RenderStepped:Wait() do
        UserSettings():GetService('UserGameSettings').RotationType =
            Enum.RotationType.MovementRelative
    end
end)

Threads["Active Target"] = task.spawn(function()
    Character.ChildAdded:Connect(function(child)
        if string.sub(child.Name,1,3) == "hit" then
            local id = tonumber(string.sub(child.Name,3))
            local attacker = getPlayerWithID(id)
            ActiveTarget = attacker
        end
    end)
end)

-- DefenseBubble --
for _,Player in pairs(game.Workspace.Live:GetChildren()) do
    if Player.Name ~= LocalPlayer.Name then
        if playerIsPlayer(Player.Name) then
            Threads["DB"..Player.Name] = task.spawn(function()
                Player.ChildAdded:Connect(function(child)
                    if child.Name == "Dashing" then
                        repeat
                            Look(Player)
                            block()
                            task.wait()
                        until Character:FindFirstChild("hit"..game.Players[Player.Name].UserId) or not Player:FindFirstChild("Dashing")
                        unblock()
                    end
                end)
            end)
        end
    end
end
Threads["BubblePlayerJoin"] = task.spawn(function()
    game.Players.PlayerAdded:Connect(function(Player)
        Threads["DB"..Player.Name] = task.spawn(function()
            repeat wait() until game.Workspace.Live:FindFirstChild(Player.Name)
            Player.Character.ChildAdded:Connect(function(child)
                if child.Name == "Dashing" then
                    repeat
                        Look(Player.Character)
                        block()
                        task.wait()
                    until Character:FindFirstChild("hit"..Player.UserId) or not Player.CharacterLFindFirstChild("Dashing")
                    unblock()
                end
            end)
        end)
    end)
end)
Threads["BubblePlayerLeave"] = task.spawn(function()
    game.Players.PlayerRemoving:Connect(function(Player)
        task.cancel(Threads["DB"..Player.Name])
    end)
end)
-------------------

Threads["SideDashLock"] = task.spawn(function()
    UIS.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Q then
            if ActiveTarget then
                repeat
                    game.Workspace.Camera.CFrame = CFrame.lookAt(game.Players.LocalPlayer.Character.Head.Position,ActiveTarget.HumanoidRootPart.Position,Vector3.new(0, 1, 0))
                until not game.Players.LocalPlayer.Character:FindFirstChild("Dashing")
            end
        end
    end)
end)

Threads["Lock"] = task.spawn(function()
    while task.wait() do
        if AutoLock == true or ActiveTarget ~= nil then
            if ActiveTarget == nil then
                local pInRange = checkPlayersInRange(Range)
                if next(pInRange) then
                    local closest = pInRange[1]
                    Look(closest.Player)
                end
            end
        end
    end
end)

--AutoBlock

--//Ui Init\\--
local MainGUI = OrionLib:MakeWindow({Name = "Shitty HBG Scripts", TestMode = true, SaveConfig = true, ConfigFolder = "HBGAntiExploitBad"})
local LockSettings = MainGUI:MakeTab({
	Name = "Lock Settings",
	Icon = "rbxassetid://4483345998",
	TestersOnly = false
})
LockSettings:AddToggle({
	Name = "Auto Lock",
	Default = false,
	Callback = function(Value)
		AutoLock = Value
	end    
})
LockSettings:AddSlider({
	Name = "Lock Range",
	Min = 1,
	Max = 500,
	Default = 100,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	ValueName = "LOCK_RANGE",
	Callback = function(Value)
		Range = tonumber(Value)
	end    
})

LockSettings:AddSlider({
	Name = "Defense Bubble Range",
	Min = 1,
	Max = 50,
	Default = 20,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	ValueName = "DB_RANGE",
	Callback = function(Value)
		DBR = tonumber(Value)
	end    
})
local TargetLabel = LockSettings:AddLabel("Target: None")
LockSettings:AddBind({
	Name = "Target Select Keybind",
	Default = Enum.KeyCode.R,
	Hold = false,
	Callback = function()
		if Mouse.Target.Parent:FindFirstChild("HumanoidRootPart") then
            if playerIsPlayer(Mouse.Target.Parent) then
                ActiveTarget = Mouse.Target.Parent
                TargetLabel:Set("Target: "..Mouse.Target.Parent.Name)
            end
        end
	end    
})
LockSettings:AddBind({
	Name = "Clear Target",
	Default = Enum.KeyCode.T,
	Hold = false,
	Callback = function()
		ActiveTarget = nil
        TargetLabel:Set("Target: None")
	end    
})


local Settings = MainGUI:MakeTab({
	Name = "Settings",
	TestersOnly = false
})
Settings:AddButton({
	Name = "Kill Script",
	Callback = function()
      		if next(Threads) then
                for i,v in pairs(Threads) do
                    task.cancel(v)
                end
            end
            OrionLib:Destroy()
  	end    
})

OrionLib:Init()
