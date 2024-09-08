Config = {}

-- Configurazione dei garage per ogni job
Config.Garages = {
    ['police'] = {
        label = 'Garage LSPD',
        interactionLabel = 'Apri Garage LSPD',
        coords = vector4(-331.2792, -265.1316, 28.0674, 143.6001),
        interactionRadius = 1.5,
        pedModel = 's_m_y_cop_01',
        spawnPoints = {
            vector4(-321.2353, -268.0405, 28.0675, 143.0189),
            vector4(-317.3793, -271.0451, 28.0675, 149.9764),
            vector4(-323.6386, -279.7942, 27.9346, 326.4680),
            vector4(-327.9315, -277.3620, 27.9343, 323.8530)
        },
        vehicleReturnCoords = vector3(-345.4662, -263.3090, 27.8232),
        vehicles = {
            {
                model = 'lspdraiden',
                label = 'Raiden',
                livery = 0,
                stock = 5
            },
            {
                model = 'polscoutr',
                label = 'Scout',
                livery = 0,
                stock = 5
            }
        }
    },
    ['ambulance'] = {
        label = 'Garage EMS',
        interactionLabel = 'Apri Garage EMS',
        coords = vector4(-466.7937, -1021.8892, 24.2888, 1.6482),
        interactionRadius = 1.5,
        pedModel = 's_m_m_paramedic_01',
        spawnPoints = {
            vector4(-461.6950, -1017.3010, 24.0574, 336.0244),
            vector4(-458.2889, -1017.2373, 24.0577, 337.4067),
            vector4(-454.8242, -1017.2844, 24.0579, 335.3700)
        },
        vehicleReturnCoords = vector3(-451.7185, -1017.8964, 24.2888),
        vehicles = {
            {
                model = 'ambulance',
                label = 'Ambulanza',
                livery = 2,
                stock = 5
            }
        }
    }
}