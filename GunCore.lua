local tool = script.Parent
local Clonedtool -- this will hold the clone part data
local PlayerArms = game.Workspace:WaitForChild(game.Players.LocalPlayer.Name .. "Arms")
local UserInputService = game:GetService("UserInputService")
local animations = script.Parent.Animations
local config = script.Parent:WaitForChild("Config")

local idleAnimationId = animations.Idle.AnimationId -- you can also replace these lines with your animation id if you feel so inclined
--local adsAnimationId = animations.ads.AnimationId
local runAnimationId = animations.run.AnimationId
local reloadAnimationId = animations.reload.AnimationId

local idleAnimation = Instance.new("Animation")
idleAnimation.AnimationId = idleAnimationId

--local adsAnimation = Instance.new("Animation")
--adsAnimation.AnimationId = adsAnimationId

local runAnimation = Instance.new("Animation")
runAnimation.AnimationId = runAnimationId

local reloadAnimation = Instance.new("Animation")
reloadAnimation.AnimationId = reloadAnimationId

local humanoid
local idleAnimationTrack, adsAnimationTrack, runAnimationTrack, reloadAnimationTrack
local idleAnimationTrackArm, adsAnimationTrackArm, runAnimationTrackArm, reloadAnimationTrackArm
local equipped = false
local running = false
local reloading = false
local ADS = false

--GUN INFO--
local MaxbulletCount = config.MaxBullets.Value

local function stopAnimation(track, armTrack)
	if track and track.IsPlaying then
		track:Stop(0.1)
	end
	if armTrack and armTrack.IsPlaying then
		armTrack:Stop(0.1)
	end
end

-- Function to play an animation
local function playAnimation(anim, priority)
	if humanoid and PlayerArms and PlayerArms:FindFirstChildOfClass("Humanoid") then
		stopAnimation(idleAnimationTrack, idleAnimationTrackArm)
		stopAnimation(runAnimationTrack, runAnimationTrackArm)
		--stopAnimation(adsAnimationTrack, adsAnimationTrackArm)
		stopAnimation(reloadAnimationTrack, reloadAnimationTrackArm)
		
		local track = humanoid:LoadAnimation(anim)
		local armtrack = PlayerArms:FindFirstChildOfClass("Humanoid"):LoadAnimation(anim)
		
		if track and armtrack then
			armtrack.Priority = priority
			track.Priority = priority
			armtrack:Play()
			track:Play()
			return track, armtrack
		else
			warn("failed to load animation properly")
		end
	end
end

-- Ensure idle animation is always playing in the background
local function ensureIdleAnimation()
	if not idleAnimationTrack or not idleAnimationTrack.IsPlaying then
		idleAnimationTrack, idleAnimationTrackArm = playAnimation(idleAnimation, Enum.AnimationPriority.Movement)
	end
end

function setTransparencyForModel(model, trans)
	for _, item in pairs(model:GetDescendants()) do
		if item:IsA("BasePart") or item:IsA("MeshPart") or item:IsA("UnionOperation") then
			item.Transparency = trans
		end
	end
end

-- Equip and unequip handlers
local function onEquipped()
	Clonedtool = tool:Clone()
	Clonedtool.Parent = PlayerArms
	PlayerArms.RightHand.Motor6D.Part1 = Clonedtool.BodyAttach
	
	setTransparencyForModel(tool, 1)
	humanoid = tool.Parent:FindFirstChildWhichIsA("Humanoid")
	equipped = true
	bulletCount = config.Bullets.Value
	ensureIdleAnimation()
	humanoid.Running:Connect(function(speed)
		if speed > 17 and not running and equipped then
			if runAnimationTrack then
				runAnimationTrack:Stop()
			end
			runAnimationTrack, runAnimationTrackArm = playAnimation(runAnimation, Enum.AnimationPriority.Action)
			running = true
		elseif speed <= 17 and running and equipped then
			if runAnimationTrack then
				runAnimationTrack:Stop()
			end
			ensureIdleAnimation()
			running = false
		end
	end)
end

local function onUnequipped()
	config.Bullets.Value = bulletCount
	equipped = false
	running = false
	if idleAnimationTrack then
		idleAnimationTrack:Stop()
		idleAnimationTrackArm:Stop()
	end
	if runAnimationTrack then
		runAnimationTrack:Stop()
		runAnimationTrackArm:Stop()
	end
	--if adsAnimationTrack then
	--	adsAnimationTrack:Stop()
	--	adsAnimationTrackArm:Stop()
	--end
	if reloadAnimationTrack then
		reloadAnimationTrack:Stop()
		reloadAnimationTrackArm:Stop()
	end
	Clonedtool:Destroy()
	Clonedtool = nil
	setTransparencyForModel(tool, 0)
end

-- Input handlers
local function onInputBegan(input, gameProcessed)
	if equipped and not gameProcessed then
		if input.UserInputType == Enum.UserInputType.MouseButton2 and not running then
			
			--- Add ADS logic here
			
			ADS = true
		elseif input.KeyCode == Enum.KeyCode.R and config.Bullets.Value < 31 and not running then
			if reloadAnimationTrack then
				reloadAnimationTrack:Stop()
			end
			reloading = true
			reloadAnimationTrack, reloadAnimationTrackArm = playAnimation(reloadAnimation, Enum.AnimationPriority.Action)
			reloadAnimationTrack.Stopped:Connect(ensureIdleAnimation)
			local reloadevent = game:GetService("ReplicatedStorage"):WaitForChild("Events").ReloadEvent
			reloadAnimationTrack.Stopped:Connect(function()
				reloadevent:FireServer()
				reloading = false
			end)
		end
	end
end

local function onInputEnded(input, gameProcessed)
	if equipped and not gameProcessed then
		if input.UserInputType == Enum.UserInputType.MouseButton2 and not running then
			
			--Add ADS logic here
			
			ensureIdleAnimation()
			ADS = false
		end
	end
end

tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)
UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)


------------------------------------------------
--
--GUN MECHANICS
--
------------------------------------------------

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local shootEvent = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("ShootEvent")

mouse.Button1Down:Connect(function()
	if running or reloading or not equipped then
		return
	end

	local camera = game.Workspace.CurrentCamera
	local direction = camera.CFrame.LookVector
	local startPosition = camera.CFrame.Position + (direction * 2) -- Start a bit in front of the camera to avoid self-collision

	-- Adjust bullet spread based on ADS
	if not ADS then
		-- Randomize direction when not ADS
		local spread = math.rad(5) -- 5 degrees spread
		local randomX = math.random() * 2 - 1 -- Random number between -1 and 1
		local randomY = math.random() * 2 - 1
		direction = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), randomX * spread) * direction
		direction = CFrame.fromAxisAngle(Vector3.new(1, 0, 0), randomY * spread) * direction
	end

	shootEvent:FireServer(startPosition, direction)
end)
