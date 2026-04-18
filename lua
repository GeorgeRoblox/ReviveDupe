--// 
--// Revive Dupe Script by FearGe0rge Modified (without textservice)
--// Original Revive Dupe Script by upio
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

--// Game Data
local LatestRoom = ReplicatedStorage.GameData.LatestRoom
local Revives = LocalPlayer.PlayerGui.TopbarUI.Topbar.StatsTopbarHandler.StatModules.Revives.RevivesVal

--// Constants
local IsMainAccount = LocalPlayer.Name == AccountToDuplicateTo
local DuplicationCount = DuplicationAmount or 1000
local Title = IsMainAccount and "Revive Dupe Helper (Main Account)" or "Revive Dupe Helper (Alt Account)"
local PacketPrefix = "ReviveDupe_"

--// Dupe State stuff
local IsGiftingRevive = false

--// Helper function to find the other player
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
            StarterGui:SetCore("SendNotification", {
                Title = Title,
                Text = "Waiting for the other account to die...",
                Duration = 5
            })

            OtherPlayer:GetAttributeChangedSignal("Alive"):Wait()
        end

        task.wait(2.5)
        ReviveFriendEvent:FireServer(OtherPlayer.Name)

        StarterGui:SetCore("SendNotification", {
            Title = Title,
            Text = "Revive sent to alt account. Now rejoin a new game with your alt account.",
            Duration = 5
        })
    end
end)

--// We no longer wait for initialization packets. 
--// We try to find the other player immediately or wait until they join.
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
        StarterGui:SetCore("SendNotification", {
            Title = "Revive Dupe Helper",
            Text = "Please open a door",
            Duration = 5
        })

        LatestRoom:GetPropertyChangedSignal("Value"):Wait()
    end

    if replicatesignal then
        replicatesignal(LocalPlayer.Kill)
    else
        StarterGui:SetCore("SendNotification", {
            Title = "Revive Dupe Helper",
            Text = "Your executor does not support replicatesignal, please die manually",
            Duration = 5
        })
        LocalPlayer.Character.Humanoid.Died:Wait()
    end

    StarterGui:SetCore("SendNotification", {
        Title = "Revive Dupe Helper",
        Text = "Make your alt account try and revive you. (Click more than once)",
        Duration = 5
    })
end

--// Main Logic

--// Gifting 1 revive to alt account process
if Revives.Value == 0 and not IsMainAccount then
    IsGiftingRevive = true

    AttemptToKillLocalPlayer()
    
    StarterGui:SetCore("SendNotification", {
        Title = Title,
        Text = "Waiting for the other account to gift you a revive...",
        Duration = 5
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

--// Wait a bit for communication setup
task.wait(2)

--// If its gifting, we don't want to interrupt the gifting process
if IsGiftingRevive then
    return
end

--// Main account logic
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
    -- Alt account logic
    -- Wait for OtherPlayer to be found if not already
    while not OtherPlayer do task.wait() end

    if OtherPlayer:GetAttribute("Alive") then
        StarterGui:SetCore("SendNotification", {
            Title = Title,
            Text = "Waiting for the other account to die...",
            Duration = 5
        })

        OtherPlayer:GetAttributeChangedSignal("Alive"):Wait()
    end

    for i = 1, 5 do
        StarterGui:SetCore("SendNotification", {
            Title = Title,
            Text = `Duping in {6 - i} seconds...`,
            Duration = 1
        })
        task.wait(1)
    end

    for i = 1, DuplicationCount do
        ReviveFriendEvent:FireServer(OtherPlayer.Name)
    end

    StarterGui:SetCore("SendNotification", {
        Title = Title,
        Text = "Duping completed!",
        Duration = 5
    })
end
