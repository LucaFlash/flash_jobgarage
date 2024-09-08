-- Funzione per verificare il job del giocatore
function CanAccessGarage(jobName)
    local playerData = ESX.GetPlayerData()
    return playerData.job and playerData.job.name == jobName
end

function SpawnNpc(coords, heading, model)
    local hash = GetHashKey(model)

    -- Richiedi il modello del ped
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(15) -- Attendi finché il modello non è caricato
    end

    -- Crea il ped
    local ped = CreatePed(4, hash, coords.x, coords.y, coords.z - 1.0, heading, false, true)
    -- Configura il ped
    SetEntityHeading(ped, heading)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
end

Citizen.CreateThread(function()
    -- Attendere che la risorsa sia completamente avviata
    Citizen.Wait(5000) -- Modifica il tempo se necessario per garantire che la risorsa sia avviata
    PreloadVehicleModels()
    -- Aggiungi interazioni per i ped utilizzando addModel
    for job, data in pairs(Config.Garages) do
        -- Verifica che i dati del garage siano definiti
        if data.pedModel and data.coords and data.interactionRadius and data.spawnPoints and data.vehicleReturnCoords and data.vehicles then
            -- Usa SpawnNpc per spawnare il ped
            SpawnNpc(data.coords, data.coords.w, data.pedModel)

            -- Usa addModel per aggiungere un target al ped
            exports.ox_target:addModel(data.pedModel, {
                {
                    name = 'garage_menu_' .. job,
                    icon = 'fa-solid fa-warehouse',
                    label = data.interactionLabel,
                    canInteract = function(entity, distance, coords, name, bone)
                        -- Verifica se la distanza è inferiore o uguale al raggio di interazione
                        return distance <= data.interactionRadius and CanAccessGarage(job)
                    end,
                    onSelect = function(data)
                        -- Apri il garage del job
                        OpenGarageMenu(job)
                    end
                }
            })
        else
            print("Errore: Dati del garage incompleti per il job " .. job)
        end
    end
end)

-- Funzione per aprire il menu del garage
function OpenGarageMenu(job)
    local elements = {}

    -- Debug per controllare il job e i dati del garage
    local garageData = Config.Garages[job]
    if not garageData then
        print("Errore: Config.Garages[" .. job .. "] non trovato")
        return
    end

    -- Recupera i veicoli disponibili per il job dal Config
    local vehicles = garageData.vehicles

    if vehicles and #vehicles > 0 then
        for _, vehicle in ipairs(vehicles) do
            -- Debug per i dati dei veicoli
            table.insert(elements, {
                title = 'Modello: ' .. vehicle.label, -- Etichetta del veicolo
                description = 'Veicoli Disponibili: ' .. vehicle.stock, -- Stock come descrizione
                icon = 'car', -- Icona del veicolo (può essere personalizzata)
                onSelect = function()
                    -- Non serializzare la funzione in JSON
                    if vehicle.stock > 0 then
                        SpawnVehicle(vehicle, job)
                    else
                        ESX.ShowNotification('Stock esaurito per ' .. vehicle.label)
                    end
                end
            })
        end

        -- Debug per controllare gli elementi del menu (senza le funzioni)
        local debugElements = {}
        for _, element in ipairs(elements) do
            table.insert(debugElements, {
                title = element.title,
                description = element.description,
                icon = element.icon
            })
        end

        -- Registrazione del contesto del menu
        lib.registerContext({
            id = 'garage_menu_' .. job,
            title = garageData.label, -- Usa il label del Config per il titolo
            options = elements, -- Passa gli elementi al menu
            onSelect = function(selected)
                -- Funzione di selezione principale (se necessario)
            end
        })

        -- Mostra il contesto del menu
        lib.showContext('garage_menu_' .. job)
    else
    end
end

local loadedModels = {}

function PreloadVehicleModels()
    for job, data in pairs(Config.Garages) do
        for _, vehicle in ipairs(data.vehicles) do
            local model = vehicle.model
            if not loadedModels[model] then
                RequestModel(model)
                while not HasModelLoaded(model) do
                    Wait(0) -- Usa un breve delay per il caricamento
                end
                loadedModels[model] = true
            end
        end
    end
end

-- Esegui la pre-caricamento dei modelli all'inizio
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        PreloadVehicleModels()
    end
end)

function SpawnVehicle(vehicleData, job)
    local spawnPoints = Config.Garages[job].spawnPoints

    if spawnPoints then
        -- Trova un punto di spawn disponibile
        local isAvailable, spawnPoint = GetAvailableVehicleSpawnPoint(spawnPoints)

        if isAvailable and spawnPoint then
            local model = vehicleData.model

            -- Verifica se il modello è già caricato
            if not loadedModels[model] then
                print("Errore: Il modello del veicolo non è caricato")
                return
            end

            -- Crea il veicolo nel punto di spawn scelto
            local vehicle = CreateVehicle(model, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w, true, false)

            -- Imposta la livrea se specificata
            if vehicleData.livery then
                SetVehicleLivery(vehicle, vehicleData.livery)
            end

            -- Ottieni e salva la targa del veicolo
            local plate = GetVehicleNumberPlateText(vehicle)
            vehicleTags[plate] = { model = model, job = job }

            -- Decrementa lo stock del veicolo
            for _, v in ipairs(Config.Garages[job].vehicles) do
                if v.model == model then
                    v.stock = v.stock - 1
                    break
                end
            end
        else
            print("Errore: Nessun punto di spawn libero per il modello " .. vehicleData.model)
        end
    else
        print("Errore: Punti di spawn non definiti per il job " .. job)
    end
end






-- Funzione per verificare se un punto di spawn è libero
function GetAvailableVehicleSpawnPoint(spawnPoints)
    local found, foundSpawnPoint = false, nil

    for i=1, #spawnPoints, 1 do
        local spawnPoint = spawnPoints[i]
        -- Usa ESX.Game.IsSpawnPointClear per verificare se il punto è libero
        if ESX.Game.IsSpawnPointClear(vector3(spawnPoint.x, spawnPoint.y, spawnPoint.z), 2.0) then
            found, foundSpawnPoint = true, spawnPoint
            break
        end
    end

    if found then
        return true, foundSpawnPoint
    else
        TriggerEvent('flash_garage:notify', 'error', 'Nessun punto di spawn libero.')
        return false
    end
end
---------------------------------------------------------------------------------------------------------------------------------------

-- Definizione globale della tabella per tracciare le targhe dei veicoli
vehicleTags = {}

-- Funzione per restituire e eliminare il veicolo
function ReturnVehicle(vehicle)
    local job = ESX.GetPlayerData().job.name
    local vehicleReturnCoords = Config.Garages[job].vehicleReturnCoords

    -- Ottieni la targa del veicolo
    local plate = GetVehicleNumberPlateText(vehicle)
    if plate and plate ~= "" then
        -- Verifica se la targa è registrata
        if vehicleTags[plate] then
            -- Rimuovi il veicolo dal mondo di gioco
            DeleteVehicle(vehicle)
            ESX.ShowNotification('Veicolo restituito con successo!')
            -- Rimuovi la targa dalla tabella vehicleTags
            local vehicleData = vehicleTags[plate]
            vehicleTags[plate] = nil -- Rimuovi la targa dalla tabella

            -- Trova e aggiorna lo stock del veicolo
            local found = false
            for _, v in ipairs(Config.Garages[job].vehicles) do
                if v.model == vehicleData.model then
                    v.stock = v.stock + 1
                    found = true
                    break
                end
            end

            if not found then
                print("Modello veicolo non trovato nel Config:", vehicleData.model)
            end
        else
            ESX.ShowNotification('Non puoi parcheggiare questo veicolo qui.')
        end
    else
        ESX.ShowNotification('Targa del veicolo non valida.')
    end
end

-- Funzione per disegnare il marker
function DrawVehicleReturnMarker(coords)
    local markerType = 36
    local markerSize = 0.6
    local markerHeight = 0.6
    local markerColor = {r = 255, g = 0, b = 0, a = 100}
    
    DrawMarker(markerType, coords.x, coords.y, coords.z+0.5 - markerHeight, 0, 0, 0, 0, 0, 0, markerSize, markerSize, markerHeight, markerColor.r, markerColor.g, markerColor.b, markerColor.a, false, true, 2, false, false, false, false)
end

local playerData = nil

-- Ascolta l'evento per ottenere i dati del giocatore
AddEventHandler('esx:playerLoaded', function(data)
    playerData = data
end)

Citizen.CreateThread(function()
    local markerVisible = false

    while true do
        Citizen.Wait(markerVisible and 0 or 500) -- Riduci il polling se il marker non è visibile

        local playerPed = PlayerPedId()

        if playerData then
            local job = playerData.job.name
            local vehicleReturnCoords = Config.Garages[job] and Config.Garages[job].vehicleReturnCoords or vector3(0, 0, 0)

            -- Controlla se il giocatore è in un veicolo
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - vehicleReturnCoords)

            if vehicle and vehicle ~= 0 then
                -- Se il giocatore è in un veicolo, controlla la distanza
                if distance < 5.0 then
                    markerVisible = true
                    -- Disegna il marker al punto di ritorno se entro 10 metri
                    DrawVehicleReturnMarker(vehicleReturnCoords)

                    if distance < 2.0 then
                        -- Mostra la UI testuale con le opzioni specificate
                        lib.showTextUI('[E] - Restituisci veicolo', {
                            position = "right-center",
                            icon = 'hand'
                        })

                        if IsControlJustReleased(0, 38) then -- "E" key
                            ReturnVehicle(vehicle)
                            lib.hideTextUI()
                            --ESX.ShowNotification('Veicolo restituito con successo!')
                        end
                    else
                        -- Nascondi la UI testuale se il giocatore non è vicino al marker
                        lib.hideTextUI()
                    end
                else
                    markerVisible = false
                    -- Nascondi il marker e la UI testuale se il giocatore è lontano dal marker
                    lib.hideTextUI()
                end
            else
                markerVisible = false
                -- Nascondi il marker e la UI testuale se il giocatore non è in un veicolo
                lib.hideTextUI()
            end
        else
            -- Attendi che i dati del giocatore siano disponibili
            Citizen.Wait(500)
        end
    end
end)

