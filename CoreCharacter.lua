local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local teleportService = game:GetService("TeleportService")
local events = game:GetService("ReplicatedStorage").Events
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local revive = events.ReviveEvent
local reset = events.ResetCharacter


--wait(1)

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

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local normalSwayEffect = 0.1 -- Regular sway effect
local adsSwayEffect = 0.02 -- Minimal sway effect when ADSing and walking
local idleSwayEffect = 0.05 -- Little sway when idle
local runSwayEffect = 0.2 -- Maximum sway effect when running

local firstunADS = true
local firstADS = false
local debounce = false
local lastCameraCFrame = workspace.CurrentCamera.CFrame
local currentGun = nil

local function createTween(object, goal, duration)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local tween = TweenService:Create(object.PrimaryPart, tweenInfo, {CFrame = goal})
	return tween
end

local function applySway(originalCFrame, swayFactor)
	local swayX = math.sin(tick() * 5) * swayFactor -- Adjust the multiplier to change the sway speed
	local swayY = math.sin(tick() * 3) * swayFactor -- Adjust the multiplier to change the sway speed
	return originalCFrame * CFrame.Angles(swayX, swayY, 0)
end

RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	if _G.Unequipping == true then
		local camera = workspace.CurrentCamera
		local rotation = camera.CFrame:ToObjectSpace(lastCameraCFrame)
		local x, y, z = rotation:ToOrientation()
		lastCameraCFrame = workspace.CurrentCamera.CFrame
		local cameraHeightAdjust = CFrame.new(0, -2.5, 0.5) -- This creates a CFrame offset that moves the camera up by 3 units
		local rotation = CFrame.Angles(0, 0, 0)
		local swayCframe = CFrame.Angles(x, y, z)
		joelArms.PrimaryPart = joelArms.HumanoidRootPart
		_G.Unequipping = false
		return
	end
	
	if _G.Equipping == true then
		debounce = true
		local goalCFrame = applySway(camera.CFrame * CFrame.new(0, -2.5, 0.5) * CFrame.Angles(0, 90, 90) * swayCframe * CFrame.new(0, -0.25, -1), idleSwayEffect)
		joelArms:SetPrimaryPartCFrame(goalCFrame)
		_G.Unequipping = false
		return
	end
	
	local rotation = camera.CFrame:ToObjectSpace(lastCameraCFrame)
	local x, y, z = rotation:ToOrientation()
	lastCameraCFrame = workspace.CurrentCamera.CFrame

	if _G.ADSing == false then
		local cameraHeightAdjust = CFrame.new(0, -2.5, 0.5) -- This creates a CFrame offset that moves the camera up by 3 units
		local rotation = CFrame.Angles(0, 0, 0)
		joelArms.PrimaryPart = joelArms.HumanoidRootPart

		if firstADS == true and debounce == false then
			debounce = true
			firstADS = false

			local goalCFrame = (camera.CFrame * cameraHeightAdjust * rotation * swayCframe * CFrame.new(0, -0.25, -1))
			local tween = createTween(joelArms, goalCFrame, 0.065) -- Adjust the duration as needed
			tween:Play()

			tween.Completed:Connect(function()
				joelArms:SetPrimaryPartCFrame((camera.CFrame * cameraHeightAdjust * rotation) * swayCframe * CFrame.new(0, -0.25, -1))
				debounce = false
				firstunADS = true
			end)
		elseif debounce == false then
			local goalCFrame
			if humanoid.MoveDirection.Magnitude > 0 then
				if humanoid.WalkSpeed > 17 then
					goalCFrame = applySway(camera.CFrame * cameraHeightAdjust * rotation * swayCframe * CFrame.new(0, -0.25, -1), runSwayEffect)
				else
					goalCFrame = applySway(camera.CFrame * cameraHeightAdjust * rotation * swayCframe * CFrame.new(0, -0.25, -1), normalSwayEffect)
				end
			else
				goalCFrame = applySway(camera.CFrame * cameraHeightAdjust * rotation * swayCframe * CFrame.new(0, -0.25, -1), idleSwayEffect)
			end
			joelArms:SetPrimaryPartCFrame(goalCFrame)
		end
	else
		local ADS = joelArms:FindFirstChildWhichIsA("Tool"):WaitForChild("ADS")
		joelArms.PrimaryPart = ADS

		if firstunADS == true and debounce == false then
			debounce = true
			firstunADS = false

			local goalCFrame = camera.CFrame * CFrame.Angles(0, 0, 0)
			local tween = createTween(joelArms, goalCFrame, 0.065) -- Adjust the duration as needed
			tween:Play()

			tween.Completed:Connect(function()
				joelArms:SetPrimaryPartCFrame(camera.CFrame * CFrame.Angles(0, 0, 0))
				firstADS = true
				debounce = false
			end)
		elseif debounce == false then
			local goalCFrame
			if humanoid.MoveDirection.Magnitude > 0 then
				goalCFrame = applySway(camera.CFrame * CFrame.Angles(0, 0, 0), adsSwayEffect)
			else
				goalCFrame = camera.CFrame * CFrame.Angles(0, 0, 0)
			end
			joelArms:SetPrimaryPartCFrame(goalCFrame)
		end
	end
end)
