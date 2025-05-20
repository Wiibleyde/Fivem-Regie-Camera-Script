local resourceName = GetCurrentResourceName()
local inRegie = false
local currentCamera = 1
local travelling = false
local activeCam = nil
local cameraTypes = {}
local currentCameraType = nil

travellingProgress = travellingProgress or 0.0

Citizen.CreateThread(function()
    for k, v in pairs(Config.Cameras) do
        table.insert(cameraTypes, k)
    end
end)

RegisterKeyMapping(resourceName..'.next.camera', '[Wiibleyde] Camera suivante', 'keyboard', 'RIGHT')
RegisterKeyMapping(resourceName..'.previous.camera', '[Wiibleyde] Camera précédente', 'keyboard', 'LEFT')
RegisterKeyMapping(resourceName..'.travelling.camera', '[Wiibleyde] Activer/désactiver le travelling', 'keyboard', 'RETURN')
RegisterKeyMapping(resourceName..'.exit.regie', '[Wiibleyde] Quitter la régie', 'keyboard', 'BACK')

for _, cmd in pairs({
    {name = '.next.camera', event = ':nextCamera'},
    {name = '.previous.camera', event = ':previousCamera'},
    {name = '.travelling.camera', event = ':travellingCamera'},
    {name = '.exit.regie', event = ':exitRegie'}
}) do
    RegisterCommand(resourceName..cmd.name, function()
        if inRegie then TriggerEvent(resourceName..cmd.event) end
    end, false)
end

local function ActivateCamera(cameraType)
    if activeCam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(activeCam, false)
    end
    
    activeCam, currentCameraType = StartCam(activeCam, cameraType)
    RenderScriptCams(true, false, 0, true, true)
end


RegisterNetEvent(resourceName..':goInRegie')
AddEventHandler(resourceName..':goInRegie', function()
    inRegie = true
    TriggerEvent('wiibleyde_camera_regie:setInRegie', true)
    currentCamera = 1
    travelling = false
    ActivateCamera(cameraTypes[currentCamera])
    DisplayRadar(false)
    
    Citizen.CreateThread(function()
        while inRegie do
            DisableAllControlActions(0)
            EnableControlAction(0, 245, true)
            
            if activeCam and currentCameraType then
                local zoomValue = (1.0/(FOV_MAX-FOV_MIN))*(FOV-FOV_MIN)
                CheckInputRotation(activeCam, zoomValue, currentCameraType)
                CheckInputZoom(activeCam, currentCameraType)
                
                if travelling then
                    HandleTravelling(activeCam, cameraTypes[currentCamera], currentCameraType, travelling)
                    if currentCameraType == CameraType.RAIL and (travellingProgress or 0.0) >= 1.0 then
                        travelling = false
                    end
                end
            end
            
            Citizen.Wait(0)
        end
    end)
    
    Citizen.CreateThread(function()
        while inRegie do
            if activeCam then LoadMapAroundCamera(activeCam) end
            Citizen.Wait(1000)
        end
    end)
end)

RegisterNetEvent(resourceName..':nextCamera', resourceName..':previousCamera')
AddEventHandler(resourceName..':nextCamera', function()
    if not inRegie then return end
    if activeCam then SaveCameraState(activeCam, cameraTypes[currentCamera]) end
    currentCamera = currentCamera + 1
    if currentCamera > #cameraTypes then currentCamera = 1 end
    travelling = false
    ActivateCamera(cameraTypes[currentCamera])
end)

AddEventHandler(resourceName..':previousCamera', function()
    if not inRegie then return end
    if activeCam then SaveCameraState(activeCam, cameraTypes[currentCamera]) end
    currentCamera = currentCamera - 1
    if currentCamera < 1 then currentCamera = #cameraTypes end
    travelling = false
    ActivateCamera(cameraTypes[currentCamera])
end)

RegisterNetEvent(resourceName..':travellingCamera')
AddEventHandler(resourceName..':travellingCamera', function()
    if not inRegie then return end
    if currentCameraType == CameraType.PTZ then
        travelling = false
    elseif currentCameraType == CameraType.RAIL then
        ToggleTravellingDirection(cameraTypes[currentCamera])
        travelling = true
    end
end)

RegisterNetEvent(resourceName..':exitRegie')
AddEventHandler(resourceName..':exitRegie', function()
    if activeCam then SaveCameraState(activeCam, cameraTypes[currentCamera]) end
    
    inRegie = false
    TriggerEvent('wiibleyde_camera_regie:setInRegie', false)
    if activeCam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(activeCam, false)
        activeCam = nil
    end
    DisplayRadar(true)
    currentCameraType = nil
    travelling = false
    ClearFocus()
    
    if Config.ResetCamerasOnExit then ResetAllCameraStates() end
end)
