local apiPort = "invalid"
local apiToken = "invalid"
local serverCompatVersion = "invalid"
local txAdminClientVersion = GetResourceMetadata('Dream-City', 'version')
print("[Dream-City] Version "..txAdminClientVersion.." starting...")

Citizen.CreateThread(function()
    --Wait for environment variables
    local envAttempts = 0
    while apiPort == "invalid" or apiToken == "invalid" or serverCompatVersion == "invalid" do
        if envAttempts then
            Citizen.Wait(1000)
        end
        if envAttempts >= 5 then
            print("[Dream-City] LUA awaiting for environment setup...")
        end
        envAttempts = envAttempts + 1
        apiPort = GetConvar("txAdmin-apiPort", "invalid")
        apiToken = GetConvar("txAdmin-apiToken", "invalid")
        serverCompatVersion = GetConvar("txAdmin-clientCompatVersion", "invalid")
    end

    -- Detect version compatibility issues
    if serverCompatVersion ~= txAdminClientVersion then
        while true do
            print("[Dream-City] This resource version is not compatible with the current txAdmin version. Please update or remove this resource to prevent any issues.")
            Citizen.Wait(5000)
        end
    end

    -- Setup threads and commands
    print("[Dream-City] setting up threads and commands...")
    RegisterCommand("txaPing", txaPing, true)
    RegisterCommand("txaKickAll", txaKickAll, true)
    RegisterCommand("txaKickID", txaKickID, true)
    RegisterCommand("txaKickIdentifier", txaKickIdentifier, true)
    RegisterCommand("txaBroadcast", txaBroadcast, true)
    RegisterCommand("txaSendDM", txaSendDM, true)
    RegisterCommand("txaReportResources", txaReportResources, true)
    Citizen.CreateThread(function()
        while true do
            HeartBeat()
            Citizen.Wait(3000)
        end
    end)
    AddEventHandler('playerConnecting', handleConnections)
end)


-- HeartBeat function
function HeartBeat()
    local url = "http://localhost:"..apiPort.."/intercom/monitor"
    local exData = {
        txAdminToken = apiToken,
        alive = true
    }
    PerformHttpRequest(url, function(httpCode, data, resultHeaders)
        local resp = tostring(data)
        if httpCode ~= 200 then
            print("[Dream-City] HeartBeat failed with code "..httpCode.." and message: "..resp)
        end
    end, 'POST', json.encode(exData), {['Content-Type']='application/json'})
end

-- Ping!
function txaPing(source, args)
    print("[Dream-City] Pong!")
    CancelEvent()
end


-- Kick all players
function txaKickAll(source, args)
    if args[1] == nil then
        args[1] = 'no reason provided'
    end
    print("[Dream-City] Kicking all players with reason: "..args[1])
    for _, pid in pairs(GetPlayers()) do
        DropPlayer(pid, "Kicked for: " .. args[1])
    end
    CancelEvent()
end


-- Kick specific player via server ID
function txaKickID(source, args)
    if args[1] ~= nil then
        if args[2] == nil then
            args[2] = 'no reason provided'
        end
        print("[Dream-City] Kicking #"..args[1].." with reason: "..args[2])
        DropPlayer(args[1], "Du Wurdest Gekickt: " .. args[2])
    else
        print('[Dream-City] invalid arguments for txaKickID')
    end
    CancelEvent()
end


-- Kick specific player via identifier
function txaKickIdentifier(source, args)
    if args[1] ~= nil then
        if args[2] == nil then
            args[2] = 'no reason provided'
        end
        print("[Dream-City] Kicking "..args[1].." with reason: "..args[2])
        for _,player in ipairs(GetPlayers()) do
            local identifiers = GetPlayerIdentifiers(player)
            for _,id in ipairs(identifiers) do
                if id == args[1] then
                    print('[Dream-City] Player: ' .. GetPlayerName(player) .. ' (' .. id .. ') kicked')
                    DropPlayer(player, "Du Wurdest Gekickt: " .. args[2])
                end
            end
        end
    else
        print('[Dream-City] invalid arguments for txaKickIdentifier')
    end
    CancelEvent()
end


-- Broadcast admin message to all players
function txaBroadcast(source, args)
    if args[1] ~= nil and args[2] ~= nil then
        print("[Dream-City] Admin Broadcast - "..args[1]..": "..args[2])
        TriggerClientEvent("chat:addMessage", -1, {
            args = {
                "[Dream-City] "..args[1],
                args[2],
            },
            color = {255, 0, 0}
        })
        TriggerEvent('txaLogger:internalChatMessage', -1, "(Broadcast) "..args[1], args[2])
    else
        print('[Dream-City] invalid arguments for txaBroadcast')
    end
    CancelEvent()
end


-- Send admin direct message to specific player
function txaSendDM(source, args)
    if args[1] ~= nil and args[2] ~= nil and args[3] ~= nil then
        local pName = GetPlayerName(args[1])
        if pName ~= nil then
            print("[txAdminClient] Admin DM to "..pName.." from "..args[2]..": "..args[3])
            TriggerClientEvent("chat:addMessage", args[1], {
                args = {
                    "(DM) "..args[2],
                    args[3],
                },
                color = {255, 0, 0}
            })
            TriggerEvent('txaLogger:internalChatMessage', -1, "(DM) "..args[2], args[3])
        else
            print('[Dream-City] txaSendDM: player not found')
        end
    else
        print('[Dream-City] invalid arguments for txaSendDM')
    end
    CancelEvent()
end


-- Get all resources/statuses and report back to txAdmin
function txaReportResources(source, args)
    --Prepare resources list
    local resources = {}
    local max = GetNumResources() - 1
    for i = 0, max do
        local resName = GetResourceByFindIndex(i)
        local currentRes = {
            name = resName,
            status = GetResourceState(resName),
            author = GetResourceMetadata(resName, 'author'),
            version = GetResourceMetadata(resName, 'version'),
            description = GetResourceMetadata(resName, 'description'),
            path = GetResourcePath(resName)
        }
        table.insert(resources, currentRes)
    end

    --Send to txAdmin
    local url = "http://localhost:"..apiPort.."/intercom/resources"
    local exData = {
        txAdminToken = apiToken,
        resources = resources
    }
    print('[Dream-City] Sending resources list to txAdmin.')
    PerformHttpRequest(url, function(httpCode, data, resultHeaders)
        local resp = tostring(data)
        if httpCode ~= 200 then
            print("[Dream-City] ReportResources failed with code "..httpCode.." and message: "..resp)
        end
    end, 'POST', json.encode(exData), {['Content-Type']='application/json'})
end


-- Player connecting handler
function handleConnections(name, skr, d)
    local isEnabled = GetConvar("txAdmin-expBanEnabled", "invalid")
    if isEnabled == "true" then
        d.defer()
        local url = "http://localhost:"..apiPort.."/intercom/checkWhitelist"
        local exData = {
            txAdminToken = apiToken,
            identifiers  = GetPlayerIdentifiers(source)
        }

        --Attempt to validate the user
        Citizen.CreateThread(function()
            local attempts = 0
            local isDone = false;
            --Do 5 attempts
            while isDone == false and attempts < 5 do
                attempts = attempts + 1
                d.update("Checking whitelist... ("..attempts.."/5)")
                PerformHttpRequest(url, function(httpCode, data, resultHeaders)
                    local resp = tostring(data)
                    if httpCode ~= 200 then
                        print("[Dream-City] Checking whitelist failed with code "..httpCode.." and message: "..resp)
                    elseif data == 'whitelist-ok' then
                        if not isDone then
                            d.done()
                            isDone = true
                        end
                    elseif data == 'whitelist-block' then
                        if not isDone then
                            d.done('[Dream-City] Du wurdest aus Sicherheitsgründen gebannt bitte melde dich Im Support.')
                            isDone = true
                        end
                    end
                end, 'POST', json.encode(exData), {['Content-Type']='application/json'})
                Citizen.Wait(2000)
            end

            --Block client if failed
            if not isDone then
                d.done('[Dream-City] Failed to validate your whitelist status. Try again later.')
                isDone = true
            end
        end)

    end
end
