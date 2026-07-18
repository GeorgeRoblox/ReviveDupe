--//  Revive dupe
--// Original Revive Dupe code by upio
--// Method found by lolcat
--// 

--// Services
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local VirtualInputManager = Instance.new("VirtualInputManager")

--// Remotes
local RemotesFolder = ReplicatedStorage.RemotesFolder
local ReviveFriendEvent = RemotesFolder.ReviveFriend
local ObtainReviveEvent = RemotesFolder.ObtainGiftedRevive

--// Player Variables
local LocalPlayer = Players.LocalPlayer
local OtherPlayer
local notify = loadstring(game:HttpGet("https://raw.githubusercontent.com/GeorgeRoblox/Rhyans-notification/refs/heads/main/Notification20%25yes.lua"))()
Upio = "https://raw.githubusercontent.com/GeorgeRoblox/Notification/refs/heads/main/Images/Upio.png"

local LatestRoom = ReplicatedStorage.GameData.LatestRoom
local Revives = LocalPlayer.PlayerGui.TopbarUI.Topbar.StatsTopbarHandler.StatModules.Revives.RevivesVal

local IsMainAccount = LocalPlayer.Name == AccountToDuplicateTo
local DuplicationCount = DuplicationAmount or 1000
local Title = IsMainAccount and "Revive Dupe Helper (Main Account)" or "Revive Dupe Helper (Alt Account)"
local PacketPrefix = "ReviveDupe_"

local IsGiftingRevive = false

local function GetOtherPlayer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            return player
        end
    end
    return nil
end

TextChatService.MessageReceived:Connect(function(message: TextChatMessage)
    local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
    local packetData = message.Text

    if packetData == PacketPrefix .. "SendReviveStandardToMe" then
        IsGiftingRevive = true
        OtherPlayer = sender

        if OtherPlayer:GetAttribute("Alive") == true then
notify("BlackKing", {
	Title = "Upio",
	Description = "Waiting for the other account to die...",
	Image = Upio,
	Color = Color3.fromRGB(255, 222, 189),
	Time = 5
})
            OtherPlayer:GetAttributeChangedSignal("Alive"):Wait()
        end

        task.wait(2.5)
        ReviveFriendEvent:FireServer(OtherPlayer.Name)

        notify("BlackKing", {
            Title = "Upio",
            Description = "Revive sent to alt account. Now rejoin a new game with your alt account.",
            Image = Upio,
            Color = Color3.fromRGB(255, 222, 189),
            Time = 5
        })
    end
end)

task.spawn(function()
    while not OtherPlayer do
        OtherPlayer = GetOtherPlayer()
        if not OtherPlayer then
            task.wait(1)
        end
    end
end)

--// Functions
local function AttemptToKillLocalPlayer()
    if LatestRoom.Value == 0 then
        notify("BlackKing", {
            Title = "Revive Dupe Helper",
            Description = "Please open a door",
            Image = Upio,
            Color = Color3.fromRGB(255, 222, 189),
            Time = 5
        })

        LatestRoom:GetPropertyChangedSignal("Value"):Wait()
    end

    if replicatesignal then
        replicatesignal(LocalPlayer.Kill)
    else
        notify("BlackKing", {
            Title = "Revive Dupe Helper",
            Description = "Your executor does not support replicatesignal, please die manually",
            Image = Upio,
            Color = Color3.fromRGB(255, 222, 189),
            Time = 5
        })
        LocalPlayer.Character.Humanoid.Died:Wait()
    end

    notify("BlackKing", {
        Title = "Revive Dupe Helper",
        Description = "Make your alt account try and revive you. (Click more than once)",
        Image = Upio,
        Color = Color3.fromRGB(255, 222, 189),
        Time = 5
    })
end

--// Gifting 1 revive to alt account process
if Revives.Value == 0 and not IsMainAccount then
    IsGiftingRevive = true

    AttemptToKillLocalPlayer()
    
    notify("BlackKing", {
        Title = "Upio",
        Description = "Waiting for the other account to gift you a revive...",
        Image = Upio,
        Color = Color3.fromRGB(255, 222, 189),
        Time = 5
    })
    
    local AcceptReviveThread = task.spawn(function()
        while task.wait() do
            VirtualInputManager:SendKeyEvent(
                true,
                Enum.KeyCode.Return,
                false,
                game
            )
        end
    end)

    Revives:GetPropertyChangedSignal("Value"):Wait()
    coroutine.close(AcceptReviveThread)
    task.wait(0.05)
    game:Shutdown()
    return
end

task.wait(2)

if IsGiftingRevive then
    return
end

if IsMainAccount then
    local ReviveObtainedAmount = 0
    local function OnObtainRevive(...)
        ReviveObtainedAmount += 1

        if ReviveObtainedAmount > (DuplicationCount * 0.85) then
            return true
        end

        task.wait(9e9)

        return true
    end

    if hookmetamethod then
        local mtHook; mtHook = hookmetamethod(game, "__newindex", function(...)
            local self, key = ...
    
            if rawequal(self, ObtainReviveEvent) and key == "OnClientInvoke" then
                if not checkcaller() then
                    return
                end
            end
    
            return mtHook(...)
        end)
    else
        task.defer(function()
            while task.wait() do
                ObtainReviveEvent.OnClientInvoke = OnObtainRevive
            end
        end)
    end

    ObtainReviveEvent.OnClientInvoke = OnObtainRevive

    AttemptToKillLocalPlayer()
else
    while not OtherPlayer do task.wait() end

    if OtherPlayer:GetAttribute("Alive") then
        notify("BlackKing", {
            Title = "Upio",
            Description = "Waiting for the other account to die...",
            Image = Upio,
            Color = Color3.fromRGB(255, 222, 189),
            Time = 5
        })

        OtherPlayer:GetAttributeChangedSignal("Alive"):Wait()
    end

    for i = 1, 5 do
        notify("BlackKing", {
            Title = "Upio",
            Description = `Duping in {6 - i} seconds...`,
            Image = Upio,
            Color = Color3.fromRGB(255, 222, 189),
            Time = 1
        })
        task.wait(1)
    end

    for i = 1, DuplicationCount do
        ReviveFriendEvent:FireServer(OtherPlayer.Name)
    end

    notify("BlackKing", {
        Title = "Upio",
        Description = "Duping completed!",
        Image = Upio,
        Color = Color3.fromRGB(255, 222, 189),
        Time = 5
    })
end
