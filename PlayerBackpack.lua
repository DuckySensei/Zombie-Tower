local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local debounce = true

local WeaponEquipped = false

-- Animations
local equipPrimary = script:WaitForChild("PrimaryEquipped")
local unEquipPrimary = script:WaitForChild("PrimaryUnEquipped")
local equipSecondary = script:WaitForChild("SecondaryEquipped")
local unEquipSecondary = script:WaitForChild("SecondaryUnEquipped")

-- Get RemoteEvents
local equipPrimaryEvent = ReplicatedStorage.Events:WaitForChild("EquipPrimary")
local equipSecondaryEvent = ReplicatedStorage.Events:WaitForChild("EquipSecondary")

local function animation(animation, weaponState)
	local playerarms = game.Workspace:FindFirstChild(Player.Character.Name .. "Arms")
	local humanoid = Player.Character:FindFirstChild("Humanoid")
	local animator = humanoid:FindFirstChild("Animator")
	local armsanimator = playerarms:FindFirstChild("Humanoid"):FindFirstChild("Animator")
	
	for _, track in pairs(armsanimator:GetPlayingAnimationTracks()) do
		track:Stop()
	end

	local armsanimatorTrack = armsanimator:LoadAnimation(animation)
	local AR16EquippedTrack = animator:LoadAnimation(animation)
	armsanimatorTrack.Looped = false
	AR16EquippedTrack.Looped = false
	AR16EquippedTrack.Priority = Enum.AnimationPriority.Action3
	armsanimatorTrack.Priority = Enum.AnimationPriority.Action3
	AR16EquippedTrack:Play()
	armsanimatorTrack:Play()
	
	AR16EquippedTrack.Stopped:Connect(function()
		WeaponEquipped = weaponState
		debounce = true
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if not gameProcessedEvent and debounce then
		local playerarms = game.Workspace:FindFirstChild(Player.Character.Name .. "Arms")
		if input.KeyCode == Enum.KeyCode.One then
			if WeaponEquipped then
				
				
				
				else if WeaponEquipped == false then
					debounce = false
					WeaponEquipped = true
					local clonedtool4Arms = Player.Character.Backpack:FindFirstChildWhichIsA("Model"):Clone()
					clonedtool4Arms.Parent = playerarms
					playerarms.Arms.RightHand.Motor6D.Part1 = clonedtool4Arms.BodyAttach
					
					animation(equipPrimary, true)
					equipPrimaryEvent:FireServer(true)
				end
			end
			else if input.KeyCode == Enum.KeyCode.Two then
				if WeaponEquipped then
					debounce = false
					
					local weaponInHands = Player.Character.Backpack:FindFirstChildWhichIsA("Model")
					
					animation(unEquipPrimary, false)
					equipSecondaryEvent:FireServer(false)
				end
				
				if WeaponEquipped == false then
					debounce = false
				end
			end
		end
	end
end)
