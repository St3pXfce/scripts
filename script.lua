local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local flying = false
local speed = 50

local bodyVelocity
local bodyGyro
local flyConnection
local noclipConnection
local healthConnection

------------------------------------------------
-- INVINCIBILITY (REAL FIX)
------------------------------------------------
local function startInvincible()
	local character = player.Character
	if not character then return end

	local humanoid = character:WaitForChild("Humanoid")

	humanoid.BreakJointsOnDeath = false

	-- ForceField (basic protection)
	local oldFF = character:FindFirstChildOfClass("ForceField")
	if oldFF then oldFF:Destroy() end

	local ff = Instance.new("ForceField")
	ff.Visible = false
	ff.Parent = character

	-- HARD health lock (prevents custom damage systems)
	if healthConnection then
		healthConnection:Disconnect()
		healthConnection = nil
	end

	healthConnection = humanoid.HealthChanged:Connect(function()
		if flying and humanoid.Health < humanoid.MaxHealth then
			humanoid.Health = humanoid.MaxHealth
		end
	end)
end

local function stopInvincible()
	local character = player.Character
	if not character then return end

	local ff = character:FindFirstChildOfClass("ForceField")
	if ff then ff:Destroy() end

	if healthConnection then
		healthConnection:Disconnect()
		healthConnection = nil
	end
end

------------------------------------------------
-- NOCLIP
------------------------------------------------
local function startNoclip()
	noclipConnection = RunService.Stepped:Connect(function()
		local char = player.Character
		if not char then return end

		for _, obj in ipairs(char:GetDescendants()) do
			if obj:IsA("BasePart") then
				obj.CanCollide = false
			end
		end
	end)
end

local function stopNoclip()
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end

	local char = player.Character
	if not char then return end

	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.CanCollide = true
		end
	end
end

------------------------------------------------
-- FLY
------------------------------------------------
local function startFlying()
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart")
	local humanoid = character:WaitForChild("Humanoid")

	humanoid.PlatformStand = true

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Parent = hrp

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bodyGyro.Parent = hrp

	startNoclip()
	startInvincible()

	flyConnection = RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera

		bodyGyro.CFrame = camera.CFrame

		local moveDirection = Vector3.zero

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveDirection += camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveDirection -= camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveDirection -= camera.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveDirection += camera.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			moveDirection += Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			moveDirection -= Vector3.new(0, 1, 0)
		end

		if moveDirection.Magnitude > 0 then
			bodyVelocity.Velocity = moveDirection.Unit * speed
		else
			bodyVelocity.Velocity = Vector3.zero
		end
	end)
end

local function stopFlying()
	flying = false

	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end

	stopNoclip()
	stopInvincible()

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
		end
	end

	if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
	if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
end

------------------------------------------------
-- TOGGLE (E)
------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.E then
		flying = not flying

		if flying then
			startFlying()
		else
			stopFlying()
		end
	end
end)

------------------------------------------------
-- RESPAWN HANDLING
------------------------------------------------
player.CharacterAdded:Connect(function()
	task.wait(0.5)

	if flying then
		startFlying()
		startInvincible()
	end
end)
