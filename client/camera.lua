local SPEED_LR = 8.0
local SPEED_UD = 8.0
FOV_MAX = 120.0
FOV_MIN = -2.0
FOV = (FOV_MAX + FOV_MIN) / 2
local ZOOM_SPEED = 2.0
local DRONE_SPEED = 0.2

local cameraNewZ = 0.0
local travellingStartPoint = nil
local travellingEndPoint = nil
local travellingProgress = 0.0
local travellingSpeed = (Config and Config.TravellingSpeed) or 0.001
local travellingDirection = 1
local travellingThreadActive = false
travelling = travelling or false

local savedCameraStates = {}

local function GetCamForwardVector(cam)
    local rot = GetCamRot(cam, 2)
    local pitch = math.rad(rot.x)
    local yaw = math.rad(rot.z)
    return vector3(
        -math.sin(yaw) * math.cos(pitch),
        math.cos(yaw) * math.cos(pitch),
        math.sin(pitch)
    )
end

local function LerpVector(a, b, t)
    return vector3(
        a.x + (b.x - a.x) * t,
        a.y + (b.y - a.y) * t,
        a.z + (b.z - a.z) * t
    )
end

function CheckInputRotation(cam, zoomValue, cameraType)
    if cameraType == CameraType.PTZ or cameraType == CameraType.RAIL then
        local rightAxisX = GetDisabledControlNormal(0, 220)
        local rightAxisY = GetDisabledControlNormal(0, 221)
        local camRot = GetCamRot(cam, 2)
        
        if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
            cameraNewZ = camRot.z + rightAxisX * -1.0 * SPEED_UD * (zoomValue + 0.1)
            local newX = math.max(math.min(90.0, camRot.x + rightAxisY * -1.0 * SPEED_LR * (zoomValue + 0.1)), -89.5)
            SetCamRot(cam, newX, camRot.y, cameraNewZ, 2)
        end
    elseif cameraType == CameraType.DRONE then
        local rightAxisX = GetDisabledControlNormal(0, 220)
        local rightAxisY = GetDisabledControlNormal(0, 221)
        local leftAxisX = GetDisabledControlNormal(0, 218)
        local leftAxisY = GetDisabledControlNormal(0, 219)

        if IsDisabledControlPressed(0, 32) then leftAxisY = 1.0
        elseif IsDisabledControlPressed(0, 33) then leftAxisY = -1.0 end
        
        local camRot = GetCamRot(cam, 2)
        if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
            cameraNewZ = camRot.z + rightAxisX * -1.0 * SPEED_UD * (zoomValue + 0.1)
            local newX = math.max(math.min(90.0, camRot.x + rightAxisY * -1.0 * SPEED_LR * (zoomValue + 0.1)), -89.5)
            SetCamRot(cam, newX, camRot.y, cameraNewZ, 2)
        end
        
        local camPos = GetCamCoord(cam)
        local forwardVector = GetCamForwardVector(cam)
        local rightVector = vector3(-forwardVector.y, forwardVector.x, 0.0)
        local dz = 0.0
        if IsDisabledControlPressed(0, 210) then dz = dz - DRONE_SPEED end
        if IsDisabledControlPressed(0, 209) then dz = dz + DRONE_SPEED end
        
        if leftAxisX ~= 0.0 or leftAxisY ~= 0.0 or dz ~= 0.0 then
            SetCamCoord(cam, 
                camPos.x + (leftAxisY * forwardVector.x * DRONE_SPEED) - (leftAxisX * rightVector.x * DRONE_SPEED),
                camPos.y + (leftAxisY * forwardVector.y * DRONE_SPEED) - (leftAxisX * rightVector.y * DRONE_SPEED),
                camPos.z + (leftAxisY * forwardVector.z * DRONE_SPEED) + dz
            )
        end
    end
end

function CheckInputZoom(cam, cameraType)
    if IsDisabledControlJustPressed(0, 241) or IsDisabledControlJustPressed(0, 316) then
        FOV = math.max(FOV - ZOOM_SPEED, FOV_MIN)
    end
    if IsDisabledControlJustPressed(0, 242) or IsDisabledControlJustPressed(0, 317) then
        FOV = math.min(FOV + ZOOM_SPEED, FOV_MAX)
    end
    
    local currentFov = GetCamFov(cam)
    if math.abs(FOV - currentFov) < 0.1 then FOV = currentFov end

    local interpolationFactor = (cameraType == CameraType.DRONE) and 0.03 or 0.05
    SetCamFov(cam, currentFov + (FOV - currentFov) * interpolationFactor)
end

function StartCam(cam, cameraKey)
    if cam ~= nil then DestroyCam(cam, false) end

    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local camConfig = Config.Cameras[cameraKey]
    local camPos = camConfig.Position
    local camHeading = camConfig.BaseHeading
    local cameraTypeValue = camConfig.Type or CameraType.PTZ
    
    local fovValue = (cameraTypeValue == CameraType.DRONE) and 60.0 or FOV
    local rotation = vector3(0.0, 0.0, camHeading)
    
    if savedCameraStates[cameraKey] then
        local savedState = savedCameraStates[cameraKey]
        camPos = savedState.position
        rotation = savedState.rotation
        fovValue = savedState.fov
    end
    
    SetCamCoord(cam, camPos.x, camPos.y, camPos.z)
    SetCamRot(cam, rotation.x, rotation.y, rotation.z, 2)
    SetCamFov(cam, fovValue)
    FOV = fovValue
    
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)
    LoadMapAroundCamera(cam)

    return cam, cameraTypeValue
end

function SaveCameraState(cam, cameraKey)
    if not cam or not cameraKey then return end
    savedCameraStates[cameraKey] = {
        position = GetCamCoord(cam),
        rotation = GetCamRot(cam, 2),
        fov = GetCamFov(cam)
    }
end

function ResetAllCameraStates()
    savedCameraStates = {}
    FOV = (FOV_MAX + FOV_MIN) / 2
    travellingStartPoint = nil
    travellingEndPoint = nil
    travellingProgress = 0.0
    travellingDirection = 1
end

function LoadMapAroundCamera(cam)
    if not cam then return end
    SetFocusPosAndVel(GetCamCoord(cam), 0.0, 0.0, 0.0)
end

local function SmoothStep(t)
    return t * t * (3 - 2 * t)
end

function HandleTravelling(cam, cameraKey, cameraType, travelling)
    if not travelling then
        travellingStartPoint = nil
        travellingEndPoint = nil
        travellingProgress = 0.0
        return
    end

    if cameraType == CameraType.RAIL then
        local camConfig = Config.Cameras[cameraKey]
        if not camConfig then return end

        if travellingStartPoint == nil or travellingEndPoint == nil then
            if travellingDirection == 1 then
                travellingStartPoint = camConfig.RailStartPoint or GetCamCoord(cam)
                travellingEndPoint = camConfig.RailEndPoint
            else
                travellingStartPoint = camConfig.RailEndPoint
                travellingEndPoint = camConfig.RailStartPoint or GetCamCoord(cam)
            end
            travellingProgress = 0.0
        end

        if travellingStartPoint ~= nil and travellingEndPoint ~= nil then
            travellingProgress = travellingProgress + travellingSpeed
            if travellingProgress >= 1.0 then
                travellingProgress = 1.0
                SetCamCoord(cam, travellingEndPoint.x, travellingEndPoint.y, travellingEndPoint.z)
            else
                local smoothT = SmoothStep(travellingProgress)
                local newPos = LerpVector(travellingStartPoint, travellingEndPoint, smoothT)
                SetCamCoord(cam, newPos.x, newPos.y, newPos.z)
            end
        end

        local zoomValue = (1.0/(FOV_MAX-FOV_MIN))*(FOV-FOV_MIN)
        CheckInputRotation(cam, zoomValue, CameraType.PTZ)
        CheckInputZoom(cam, CameraType.PTZ)
    end
end

function ToggleTravellingDirection(cameraKey)
    local camConfig = Config.Cameras[cameraKey]
    if not camConfig then return end
    if travellingStartPoint and travellingEndPoint then
        travellingDirection = -travellingDirection
    else
        local camPos = GetCamCoord(activeCam)
        local distToA = #(camPos - camConfig.RailStartPoint)
        local distToB = #(camPos - camConfig.RailEndPoint)
        travellingDirection = (distToA < distToB) and 1 or -1
    end
    travellingStartPoint = nil
    travellingEndPoint = nil
    travellingProgress = 0.0
end

