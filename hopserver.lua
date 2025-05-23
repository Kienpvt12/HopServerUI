-- LocalScript trong StarterGui

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Tạo ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HopServerUI"
screenGui.Parent = playerGui

-- Tạo Frame chính
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 150)
frame.Position = UDim2.new(0.5, -150, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui
frame.AnchorPoint = Vector2.new(0.5, 0.5)

-- Tạo thanh title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 22
title.Text = "Hop Server UI"
title.Parent = frame

-- Label hiển thị JobId hiện tại
local jobIdLabel = Instance.new("TextLabel")
jobIdLabel.Size = UDim2.new(1, -20, 0, 40)
jobIdLabel.Position = UDim2.new(0, 10, 0, 40)
jobIdLabel.BackgroundTransparency = 1
jobIdLabel.TextColor3 = Color3.new(1, 1, 1)
jobIdLabel.Font = Enum.Font.SourceSans
jobIdLabel.TextSize = 18
jobIdLabel.TextWrapped = true
jobIdLabel.Text = "JobId hiện tại: " .. tostring(game.JobId)
jobIdLabel.Parent = frame

-- Nút bật/tắt hop server
local hopButton = Instance.new("TextButton")
hopButton.Size = UDim2.new(1, -20, 0, 40)
hopButton.Position = UDim2.new(0, 10, 0, 90)
hopButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
hopButton.TextColor3 = Color3.new(1, 1, 1)
hopButton.Font = Enum.Font.SourceSansBold
hopButton.TextSize = 20
hopButton.Parent = frame

-- Biến trạng thái hop
local hopEnabled = true
local hopCoroutine

-- Hàm tìm server khác và teleport sang server đó
local function hopToNewServer()
    local PLACE_ID = game.PlaceId
    local CURRENT_JOB_ID = tostring(game.JobId)

    local url = "https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Asc&limit=100"
    local success, response = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if success and response and response.data then
        for _, server in ipairs(response.data) do
            local serverId = tostring(server.id)
            if serverId ~= CURRENT_JOB_ID and server.playing < server.maxPlayers then
                local ok, err = pcall(function()
                    TeleportService:TeleportToPlaceInstance(PLACE_ID, serverId, player)
                end)
                if ok then
                    return true
                else
                    warn("Teleport thất bại: " .. tostring(err))
                    return false
                end
            end
        end
        warn("Không tìm được server khác phù hợp.")
        return false
    else
        warn("Lỗi lấy danh sách server.")
        return false
    end
end

-- Đồng bộ text nút với trạng thái hop
if hopEnabled then
    hopButton.Text = "Hop Server: ON"
    hopCoroutine = coroutine.create(function()
        while hopEnabled do
            hopToNewServer()
            wait(15)
        end
    end)
    coroutine.resume(hopCoroutine)
else
    hopButton.Text = "Hop Server: OFF"
end

-- Xử lý nhấn nút bật/tắt
hopButton.MouseButton1Click:Connect(function()
    hopEnabled = not hopEnabled
    hopButton.Text = hopEnabled and "Hop Server: ON" or "Hop Server: OFF"

    if hopEnabled then
        hopCoroutine = coroutine.create(function()
            wait(10)  -- Đợi 10 giây trước khi bắt đầu hop
            while hopEnabled do
                hopToNewServer()
                wait(3000)
            end
        end)
        coroutine.resume(hopCoroutine)
    else
        -- Tắt hop thì coroutine sẽ dừng do hopEnabled = false
    end
end)


-- Kéo thả Frame thủ công
local dragging = false
local dragInput, mousePos, framePos

local function update(input)
    local delta = input.Position - mousePos
    frame.Position = UDim2.new(
        0, framePos.X + delta.X,
        0, framePos.Y + delta.Y
    )
end

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        update(input)
    end
end)
