inRegie = inRegie or false
RegisterNetEvent('wiibleyde_camera_regie:setInRegie')
AddEventHandler('wiibleyde_camera_regie:setInRegie', function(state)
    inRegie = state
end)

local function DrawRegieMarker(position)
    local markerType = Config.MarkerType or 1
    local markerScale = Config.MarkerScale or {x = 2.0, y = 2.0, z = 1.0}
    local markerColor = Config.MarkerColor or {r = 255, g = 0, b = 0, a = 150}
    
    DrawMarker(markerType, position.x, position.y, position.z, 
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
        markerScale.x, markerScale.y, markerScale.z, 
        markerColor.r, markerColor.g, markerColor.b, markerColor.a, 
        false, true, 2, false, nil, nil, false)
end

Citizen.CreateThread(function()
    Citizen.Wait(2000)
    
    if not Config or not Config.StartPoint then
        Config = Config or {}
        Config.StartPoint = Config.StartPoint or vector3(0.0, 0.0, 70.0)
        Config.ShowMarkerDistance = Config.ShowMarkerDistance or 15.0
        Config.MarkerDistance = Config.MarkerDistance or 2.5
    end
    
    while true do
        local sleep = 1000
        
        if not inRegie then
            local playerPos = GetEntityCoords(PlayerPedId())
            local dist = #(playerPos - Config.StartPoint)
            
            if dist < Config.ShowMarkerDistance then
                sleep = 0
                DrawRegieMarker(Config.StartPoint)
                
                if dist < Config.MarkerDistance then
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to access the camera system.")
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        TriggerEvent(GetCurrentResourceName()..':goInRegie')
                    end
                end
            end
        end

        Citizen.Wait(sleep)
    end
end)