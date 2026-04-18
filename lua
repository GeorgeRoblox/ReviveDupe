--// 
--// Revive Dupe Script by upio. Edited by FearGe0rge
--// Method found by lolcat
--// Modified to use local player communication instead of RemoteEvents
--// 

--// Services
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local VirtualInputManager = Instance.new("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Remotes
local RemotesFolder = ReplicatedStorage:WaitForChild("RemotesFolder")
local ReviveFriendEvent = RemotesFolder:WaitForChild("ReviveFriend")
local ObtainReviveEvent = RemotesFolder:WaitForChild("ObtainGiftedRevive")

--// Player Variables
local LocalPlayer = Players.LocalPlayer
local OtherPlayer

--// Game Data
local LatestRoom = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom")
local Revives = LocalPlayer.PlayerGui:WaitForChild("TopbarUI"):WaitForChild("Topbar"):WaitForChild("StatsTopbarHandler"):WaitForChild("StatModules"):WaitForChild("Revives"):WaitForChild("RevivesVal")

--// Constants
-- IMPORTANT: Set the account name you want to duplicate to here
local AccountToDuplicateTo = "YOUR_MAIN_ACCOUNT_NAME_HERE" 
local DuplicationAmount = 1000

local IsMainAccount = LocalPlayer.Name == AccountToDuplicateTo
local DuplicationCount = DuplicationAmount or 1000
local Title = IsMainAccount and "Revive Dupe Helper (Main)" or "Revive Dupe Helper (Alt)"

--// Dupe State stuff
local IsOtherAccountInitialized = false
local IsGiftingRevive = false

--// Communication (Using Attributes on Players for Local Communication)
-- This replaces the DupeCommunicationEvent RemoteEvent
local function SendPacket(PacketName)
    LocalPlayer:SetAttribute("DupePacket", PacketName)
    -- Reset packet after a short delay to allow re-sending same packet if needed
    task.delay(0.1, function()
        if LocalPlayer:GetAttribute("DupePacket") == PacketName then
            LocalPlayer:SetAttribute("DupePacket", nil)
        end
    end)
    return PacketName
end

local function HandlePacket(sender, PacketName)
    if not sender or sender == LocalPlayer or not PacketName then
        return
    end
    
    if PacketName == "Init" then
        if IsOtherAccountInitialized then
            return
        end

        IsOtherAccountInitialized = true
        OtherPlayer = sender
        
        -- Replicate back that this account is ready
        SendPacket("Init")

        StarterGui:SetCore("SendNotification", {
            Title = Title,
            Text = `{sender.Name} initialized, starting dupe process...`,
            Duration = 5
        }) 
    end
    
    if not IsOtherAccountInitialized then
        return
    end

    if PacketName == "SendReviveStandardToMe" then
        IsGiftingRevive = true

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
end

-- Listen for packets from other players
local function SetupPlayer(player)
    if player == LocalPlayer then return end
    
    player:GetAttributeChangedSignal("DupePacket"):Connect(function()
        local packet = player:GetAttribute("DupePacket")
        if packet then
            HandlePacket(player, packet)
        end
    end)
    
    -- Check if they already have a packet set
    local existingPacket = player:GetAttribute("DupePacket")
    if existingPacket then
        HandlePacket(player, existingPacket)
    end
end

Players.PlayerAdded:Connect(SetupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
    SetupPlayer(player)
end

--// Send a message to the other account to initialize
SendPacket("Init")

StarterGui:SetCore("SendNotification", {
    Title = Title,
    Text = "Waiting for other account to initialize...",
    Duration = 5
})

repeat task.wait() until IsOtherAccountInitialized

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

    -- Use a safer method if replicatesignal isn't available
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        if replicatesignal then
            replicatesignal(LocalPlayer.Kill)
        else
            StarterGui:SetCore("SendNotification", {
                Title = "Revive Dupe Helper",
                Text = "No replicatesignal support. Please die manually (e.g., reset or monster).",
                Duration = 5
            })
            character.Humanoid.Died:Wait()
        end
    end

    StarterGui:SetCore("SendNotification", {
        Title = "Revive Dupe Helper",
        Text = "Make your alt account try and revive you.",
        Duration = 5
    })
end

--// Main Logic

--// Gifting 1 revive to alt account process
if Revives.Value == 0 and not IsMainAccount then
    SendPacket("SendReviveStandardToMe")
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

-- Wait for communication stabilization
StarterGui:SetCore("SendNotification", {
    Title = Title,
    Text = "Waiting 5 seconds for communication sync...",
    Duration = 5
})
task.wait(5)

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

    -- Hooking the remote to prevent it from closing the UI too early
    if hookmetamethod then
        local mtHook; mtHook = hookmetamethod(game, "__newindex", function(...)
            local self, key = ...
            if rawequal(self, ObtainReviveEvent) and key == "OnClientInvoke" then
                if not checkcaller() then return end
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
    if OtherPlayer:GetAttribute("Alive") then
        StarterGui:SetCore("SendNotification", {
            Title = Title,
            Text = "Waiting for the main account to die...",
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
