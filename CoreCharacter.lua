local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local teleportService = game:GetService("TeleportService")
local events = game:GetService("ReplicatedStorage").Events
local revive = events.ReviveEvent
local reset = events.ResetCharacter


wait(1)

local hand = game:WaitForChild("ReplicatedStorage").CharacterArms

local joelArms = hand.ClancyArms:Clone()
joelArms.Parent = game.Workspace
joelArms.Name = game.Players.LocalPlayer.Character.Name .. "Arms"

local char = game.Players.LocalPlayer.Character

--game.Players.LocalPlayer.CameraMaxZoomDistance = .5

local plr = game.Players.LocalPlayer
local mouse = plr:GetMouse()

local lastCameraCFrame = CFrame.new()
local swayCframe = CFrame.new()
local swayEffect = 0.75

local humanoid = game.Workspace:FindFirstChild(game.Players.LocalPlayer.Name)
humanoid.Humanoid.CameraOffset = Vector3.new(0, 1.5, 0)

local firstunADS = false
local firstADS = true
local debounce = false

local player = game.Players.LocalPlayer
local activatePromptEvent = game:GetService("ReplicatedStorage").Events:WaitForChild("DownedEvent")
local reviveEvent = game:GetService("ReplicatedStorage").Events:WaitForChild("ReviveEvent")

local function fireEvent(character)
	reviveEvent:FireServer(character)
end

-- Table to keep track of prompt connections
local promptConnections = {}

local function enableProximityPrompt(player)
	local character = player.Character
	if not character then
		return -- Exit if the character is nil
	end

	local character = player.Character 
	if game.Players.LocalPlayer.Character.Humanoid.HP.Value <= 0 then
		local peeps = game:GetService("Players")

		for i, peeps in ipairs(peeps:GetPlayers()) do
			local health = peeps.Character.Humanoid.HP.Value
			if health < 0 then
				local prompt = peeps.Character.Head:FindFirstChild("ProximityPrompt")
				if prompt then
					prompt.Enabled = false
				end
			end
		end
		return
	end
	-- Ensure the character's head and prompt exist
	local head = character:FindFirstChild("Head")
	local prompt = head and head:FindFirstChild("ProximityPrompt")
	if prompt then
		prompt.Enabled = true
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.ActionText = "REVIVE"
		prompt.ObjectText = character.Name
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false

		-- Disconnect existing connection if there is one
		if promptConnections[prompt] then
			promptConnections[prompt]:Disconnect()
		end

		-- Connect a new Triggered event and store the connection
		promptConnections[prompt] = prompt.Triggered:Connect(function(playerWhoTriggered)
			fireEvent(character)
		end)
	end
end

activatePromptEvent.OnClientEvent:Connect(enableProximityPrompt)


reset.OnClientEvent:Connect(function(player)
	if player == game.Players.LocalPlayer then
		local peeps = game:GetService("Players")

		for i, peeps in ipairs(peeps:GetPlayers()) do
			local health = peeps.Character.Humanoid.HP.Value
			if health < 0 and peeps ~= game.Players.LocalPlayer then
				local prompt = peeps.Character.Head:FindFirstChild("ProximityPrompt")
				if prompt then
					prompt.Enabled = true
				end
			end
		end
		return
	end
	game.Workspace:WaitForChild(player.Name).Head.ProximityPrompt.Enabled = false
end)

RunService.RenderStepped:Connect(function()

	local camera = workspace.CurrentCamera
	local rotation = camera.CFrame:ToObjectSpace(lastCameraCFrame)
	local x, y, z = rotation:ToOrientation()
	--swayCframe = swayCframe:Lerp(CFrame.Angles(math.sin(x) * swayEffect, math.sin(y) * swayEffect, 0), 0.1)
	lastCameraCFrame = workspace.CurrentCamera.CFrame

	if _G.ADSing == false then

		local cameraHeightAdjust = CFrame.new(0, -2.5, 0.5)  -- This creates a CFrame offset that moves the camera up by 3 units
		local rotation = CFrame.Angles(0, 0, 0)
		joelArms.PrimaryPart = joelArms.HumanoidRootPart

		if firstADS == true and debounce == false then
			debounce = true
			firstADS = false
			--short loop that plays first time around
			for i = 1, 3 do
				if _G.ADSing == false then
					-- Move the arms towards the default position
					local goalCFrame = (camera.CFrame * cameraHeightAdjust * rotation * swayCframe * CFrame.new(0, -0.25, -1))
					local currentCFrame = joelArms:GetPrimaryPartCFrame()
					local newCFrame = currentCFrame:Lerp(goalCFrame, i / 10)
					joelArms:SetPrimaryPartCFrame(newCFrame)
					wait() -- Adjust the wait time as needed
				end
			end
			joelArms:SetPrimaryPartCFrame((camera.CFrame * cameraHeightAdjust * rotation) * swayCframe * CFrame.new(0, -0.25, -1))
			debounce = false
			firstunADS = true
		else if debounce == false then 
				joelArms:SetPrimaryPartCFrame((camera.CFrame * cameraHeightAdjust * rotation) * swayCframe * CFrame.new(0, -0.25, -1))
			end
		end
		-- Apply the adjusted camera CFrame to the joelArms
		--joelArms:SetPrimaryPartCFrame((camera.CFrame * cameraHeightAdjust * rotation) * swayCframe * CFrame.new(0, -0.25, -1))
	else
		local ADS = joelArms:FindFirstChildWhichIsA("Tool"):WaitForChild("ADS")
		joelArms.PrimaryPart = ADS

		if firstunADS == true and debounce == false then
			debounce = true
			firstunADS = false
			--short loop that plays first time around
			for i = 1, 3 do
				if _G.ADSing == true then
					-- Move the arms to the ADS part to right in front of the camera
					local goalCFrame = camera.CFrame * CFrame.Angles(0, 0, math.rad(180))
					local currentCFrame = joelArms:GetPrimaryPartCFrame()
					local newCFrame = currentCFrame:Lerp(goalCFrame, i / 10)
					joelArms:SetPrimaryPartCFrame(newCFrame)
					wait() -- Adjust the wait time as needed
				end
			end
			local rotation = CFrame.Angles(0, 0, math.rad(180))
			joelArms:SetPrimaryPartCFrame(camera.CFrame * rotation)
			firstADS = true
			debounce = false
		else if debounce == false then
				local rotation = CFrame.Angles(0, 0, math.rad(180))
				joelArms:SetPrimaryPartCFrame(camera.CFrame * rotation)
			end
		end
	end
end)
