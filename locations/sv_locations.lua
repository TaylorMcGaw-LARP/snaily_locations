--[[
    Sonaran CAD Plugins

    Plugin Name: locations
    Creator: SonoranCAD
    Description: Implements location updating for players
]]
local pluginConfig = Config.GetPluginConfig("locations")

if pluginConfig.enabled then
    -- Pending location updates array
    LocationCache = {}
    local LastSend = 0

    -- Main api POST function
    local function SendLocations()
        while true do
            local cache = {}
            for k, v in pairs(LocationCache) do
                if v.isUpdated ~= nil then
                    v.isUpdated = nil
                    table.insert(cache, v)
                end
            end
            Wait(Config.postTime+500)
        end
    end

    function findPlayerLocation(playerSrc)
        if LocationCache[playerSrc] ~= nil then
            return LocationCache[playerSrc].location
        end
        return nil
    end

    -- Main update thread sending api location update POST requests per the postTime interval
    Citizen.CreateThread(function()
        Wait(1)
        SendLocations()
    end)

    -- Event from client when location changes occur
    RegisterServerEvent('SonoranCAD::locations:SendLocation')
    AddEventHandler('SonoranCAD::locations:SendLocation', function(currentLocation)
        local source = source
        local identifier = GetIdentifiers(source)[Config.primaryIdentifier]
        if identifier == nil then
            debugLog(("user %s has no identifier for %s, skipped."):format(source, Config.primaryIdentifier))
            return
        end
        LocationCache[source] = {['apiId'] = identifier, ['location'] = currentLocation, ['isUpdated'] = true}
    end)

    AddEventHandler("playerDropped", function()
        local source = source
        LocationCache[source] = nil
    end)

    RegisterNetEvent("SonoranCAD::locations:ErrorDetection")
    AddEventHandler("SonoranCAD::locations:ErrorDetection", function(isInitial)
        if isInitial then
            errorLog(("Player %s reported an error sending initial location data. Check client logs for errors. Did you set up the postals plugin correctly?"):format(source))
        else
            warnLog(("Player %s reported an error sending location data. Check client logs for errors."):format(source))
        end
    end)

end