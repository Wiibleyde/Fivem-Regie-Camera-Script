CameraType = {
	PTZ = "PTZ", -- Pan-Tilt-Zoom camera
	DRONE = "DRONE", -- Drone camera
	RAIL = "RAIL", -- Rail camera
}

Config = {}

-- Marker configuration
Config.MarkerType = 27 -- Marker type (27 is a cylinder)
Config.MarkerScale = {x = 2.0, y = 2.0, z = 1.0} -- Scale of the marker
Config.MarkerColor = {r = 0, g = 128, b = 255, a = 150} -- Color of the marker (RGBA)
Config.MarkerDistance = 5 -- Distance to render marker (default is 5.0)
Config.ShowMarkerDistance = 15.0 -- Distance to show the marker (default is 15.0)

-- Interaction point for accessing the camera system (use a position near spawn)
Config.StartPoint = vector3(626.76, 465.24, 144.65 - 1) -- Position of the interaction point

-- Camera definitions
Config.Cameras = {
    ["Main"] = {
        Position = vector3(673.13, 541.34, 133.16),
        BaseHeading = 339.98,
        Description = "Main Camera",
        Type = CameraType.PTZ
    },
    ["Drone"] = {
        Position = vector3(680.47, 561.53, 135.95),
        BaseHeading = 340.58,
        Description = "Drone Camera",
        Type = CameraType.DRONE,
    },
    ["Rail"] = {
        Position = vector3(659.22, 569.26, 135.95),
        BaseHeading = 273.65,
        Description = "Rail Camera",
        Type = CameraType.RAIL,
        RailStartPoint = vector3(659.22, 569.26, 135.95),
        RailEndPoint = vector3(695.7, 558.77, 135.95),
    },
}

-- Vitesse du travelling (plus petit = plus lent)
Config.TravellingSpeed = 0.0006

-- Print confirmation that config was loaded
print("wiibleyde_camera_regie: Config loaded successfully")

-- Ajout d'option pour réinitialiser les caméras à la sortie
Config.ResetCamerasOnExit = true -- Mettre à false pour garder les positions sauvegardées