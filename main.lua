local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local GetPlayers = Players.GetPlayers
local WorldToScreen = Camera.WorldToScreenPoint
local WorldToViewportPoint = Camera.WorldToViewportPoint
local FindFirstChild = game.FindFirstChild
local RenderStepped = RunService.RenderStepped
local GetMouseLocation = UserInputService.GetMouseLocation

local mouse_box = Drawing.new("Square")
mouse_box.Visible = true 
mouse_box.ZIndex = 999 
mouse_box.Color = Color3.fromRGB(54, 57, 241)
mouse_box.Thickness = 20 
mouse_box.Size = Vector2.new(20, 20)
mouse_box.Filled = true 

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = 180
fov_circle.Filled = false
fov_circle.Visible = false
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(54, 57, 241)

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function getMousePosition()
    return GetMouseLocation(UserInputService)
end

local function getClosestPlayer()
    local Closest
    local DistanceToMouse = math.huge
    for _, Player in next, GetPlayers(Players) do
        if Player == LocalPlayer then continue end
        if Player.Team == LocalPlayer.Team then continue end

        local Character = Player.Character
        if not Character then continue end

        local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid and Humanoid.Health <= 0 then continue end

        local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position)
        if not OnScreen then continue end

        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if Distance <= DistanceToMouse then
            Closest = Character:FindFirstChild("Head")
            DistanceToMouse = Distance
        end
    end
    return Closest
end

RenderStepped:Connect(function()
    if getClosestPlayer() then 
        local Root = getClosestPlayer().Parent.PrimaryPart or getClosestPlayer()
        local RootToViewportPoint, IsOnScreen = WorldToViewportPoint(Camera, Root.Position);  
        mouse_box.Visible = IsOnScreen
        mouse_box.Position = Vector2.new(RootToViewportPoint.X, RootToViewportPoint.Y)
    else 
        mouse_box.Visible = false 
        mouse_box.Position = Vector2.new()
    end

    fov_circle.Visible = true
    fov_circle.Color = Color3.new(1, 0, 0)
    fov_circle.Position = getMousePosition()
end)

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]
    if self == workspace and not checkcaller() then
        if Method == "Raycast" then
            local A_Origin = Arguments[2]

            local HitPart = getClosestPlayer()
            if HitPart then
                local targetPosition = HitPart.Position

                raycastParams.FilterDescendantsInstances = { HitPart.Parent }

                Arguments[4] = raycastParams
                Arguments[2] = targetPosition + (targetPosition - A_Origin).Unit
                Arguments[3] = (targetPosition - Arguments[2]).Unit
                setnamecallmethod(Method)
                return oldNamecall(unpack(Arguments))
            end
        end
    end
    setnamecallmethod(Method)
    return oldNamecall(...)
end))
