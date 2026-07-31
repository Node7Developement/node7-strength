local UiOpen = false

local function postClose()
    UiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNetEvent('node7-strength:client:notify', function(message, kind)
    if GetResourceState('node7-core') == 'started' then
        pcall(function()
            TriggerEvent('node7-core:client:Notify', message, kind or 'info')
        end)
    end

    if Config.Debug then
        print(('[node7-strength] %s'):format(message))
    end
end)

RegisterNetEvent('node7-strength:client:openUI', function(stats)
    UiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        config = Config.UI,
        data = stats
    })
end)

RegisterNetEvent('node7-strength:client:xpPopup', function(payload)
    SendNUIMessage({
        action = 'xp',
        data = payload,
        timeout = Config.Effects.UIPopupTime
    })
end)

RegisterNetEvent('node7-strength:client:trainingStarted', function(label, duration)
    SendNUIMessage({
        action = 'training',
        data = {
            label = label,
            duration = duration
        }
    })
end)

RegisterNUICallback('close', function(_, cb)
    postClose()
    cb({ ok = true })
end)

CreateThread(function()
    while true do
        if UiOpen then
            if IsControlJustReleased(0, 0x4AF4D473) or IsControlJustReleased(0, 0xC1989F95) then
                postClose()
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)
