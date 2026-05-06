local QBCore = exports['qb-core']:GetCoreObject()
local DISCORD_WEBHOOK = 'https://discord.com/api/webhooks/1372336056346742884/2iYhYKWNdh1wd3TNYKyS4UGbghDLAFeuqSVv7dzOKLOgh4XgJgNWRVOoICcRI6xEOn6b'


local function debugPrint(...)
    if Config.Debug then
        print('[LicenseManager DEBUG]', ...)
    end
end

local function sendToDiscord(title, message, color)
    PerformHttpRequest(DISCORD_WEBHOOK, function() end, 'POST', json.encode({
        username = 'License Logs',
        embeds = {{
            title = title,
            description = message,
            color = color,
            footer = { text = os.date('%Y-%m-%d %H:%M:%S') }
        }}
    }), { ['Content-Type'] = 'application/json' })
end


local function canIssueLicense(sourcePlayer, license)
    local job = sourcePlayer.PlayerData.job.name
    local grade = sourcePlayer.PlayerData.job.grade.level
    local jobConfig = Config.LicenseIssuers[job]
    if not jobConfig then return false end
    if grade < jobConfig.rank then return false end

    for _, allowedLicense in ipairs(jobConfig.licenses) do
        if allowedLicense == license then return true end
    end

    return false
end

local function canToggleLicense(issuer, license)
    if QBCore.Functions.HasPermission(issuer.PlayerData.source, 'admin') then
        return true
    end
    return canIssueLicense(issuer, license)
end

local DefaultLicenses = {
    id = true,
    driver = false,
    weapon = false,
    pilotheli = false,
    pilot = false,
    hgv = false,
    boat = false,
    taxi = false,
}

local function updateLicense(targetPlayer, licenseName, value)
    local metadata = targetPlayer.PlayerData.metadata or {}
    local currentLicenses = metadata.licences or {}

    for k, v in pairs(DefaultLicenses) do
        if currentLicenses[k] == nil then
            currentLicenses[k] = v
        end
    end

    currentLicenses[licenseName] = value
    targetPlayer.Functions.SetMetaData('licences', currentLicenses)
    debugPrint(('Updated license "%s" to %s for %s'):format(licenseName, tostring(value), targetPlayer.PlayerData.charinfo.firstname))
end

-- /grantlicense
lib.addCommand('grantlicense', {
    help = 'Grant a license to a player',
    params = {
        { name = 'id', help = 'Player ID', type = 'number' },
        { name = 'license', help = 'License name', type = 'string' },
    }
}, function(source, args)
    local issuer = QBCore.Functions.GetPlayer(source)
    local target = QBCore.Functions.GetPlayer(args.id)
    local license = args.license:lower()

    if not issuer or not target then
        debugPrint('Grant failed: Invalid issuer or target')
        return TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'Invalid source or target player',
            type = 'error'
        })
    end

    if not canIssueLicense(issuer, license) then
        debugPrint(('Unauthorized license grant attempt: %s tried to grant %s'):format(issuer.PlayerData.charinfo.firstname, license))
sendToDiscord('Unauthorized License Grant Attempt',
    ('**%s %s** tried to grant **%s** license but was denied'):format(
        issuer.PlayerData.charinfo.firstname,
        issuer.PlayerData.charinfo.lastname,
        license
    ),
    16711680 -- red
)

        return TriggerClientEvent('ox_lib:notify', source, {
            title = 'Unauthorized',
            description = 'You are not authorized to grant this license',
            type = 'error'
        })
    end

    updateLicense(target, license, true)
-- after updateLicense(...)
sendToDiscord('License Granted',
    ('**%s %s** granted **%s** license to **%s %s**'):format(
        issuer.PlayerData.charinfo.firstname,
        issuer.PlayerData.charinfo.lastname,
        license,
        target.PlayerData.charinfo.firstname,
        target.PlayerData.charinfo.lastname
    ),
    65280 -- green
)

    TriggerClientEvent('ox_lib:notify', source, {
        title = 'License Granted',
        description = ('Granted %s license to %s'):format(license, target.PlayerData.charinfo.firstname),
        type = 'success'
    })

    TriggerClientEvent('ox_lib:notify', args.id, {
        title = 'License Granted',
        description = ('You have been granted the %s license'):format(license),
        type = 'info'
    })

end)

-- /revokelicense
lib.addCommand('revokelicense', {
    help = 'Revoke a license from a player',
    params = {
        { name = 'id', help = 'Player ID', type = 'number' },
        { name = 'license', help = 'License name', type = 'string' },
    }
}, function(source, args)
    local issuer = QBCore.Functions.GetPlayer(source)
    local target = QBCore.Functions.GetPlayer(args.id)
    local license = args.license:lower()

    if not issuer or not target then
        debugPrint('Revoke failed: Invalid issuer or target')
        return TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'Invalid source or target player',
            type = 'error'
        })
    end

    if not canIssueLicense(issuer, license) then
        debugPrint(('Unauthorized revoke attempt: %s tried to revoke %s'):format(issuer.PlayerData.charinfo.firstname, license))
sendToDiscord('Unauthorized License Revoke Attempt',
    ('**%s %s** tried to revoke **%s** license but was denied'):format(
        issuer.PlayerData.charinfo.firstname,
        issuer.PlayerData.charinfo.lastname,
        license
    ),
    16711680
)

        return TriggerClientEvent('ox_lib:notify', source, {
            title = 'Unauthorized',
            description = 'You are not authorized to revoke this license',
            type = 'error'
        })
    end

    updateLicense(target, license, false)
-- after updateLicense(...)
sendToDiscord('License Revoked',
    ('**%s %s** revoked **%s** license from **%s %s**'):format(
        issuer.PlayerData.charinfo.firstname,
        issuer.PlayerData.charinfo.lastname,
        license,
        target.PlayerData.charinfo.firstname,
        target.PlayerData.charinfo.lastname
    ),
    16753920 -- orange
)


    TriggerClientEvent('ox_lib:notify', source, {
        title = 'License Revoked',
        description = ('Revoked %s license from %s'):format(license, target.PlayerData.charinfo.firstname),
        type = 'warning'
    })

    TriggerClientEvent('ox_lib:notify', args.id, {
        title = 'License Revoked',
        description = ('Your %s license has been revoked'):format(license),
        type = 'error'
    })
end)

-- /resetlicenses
lib.addCommand('resetlicenses', {
    help = 'Reset and restore all licenses for a player',
    restricted = true,
    params = {
        { name = 'id', help = 'Player ID', type = 'number' }
    }
}, function(source, args)
    local issuer = QBCore.Functions.GetPlayer(source)
    if not issuer then return end

    if not QBCore.Functions.HasPermission(source, 'admin') then
        debugPrint('Reset denied: not an admin')
        return TriggerClientEvent('ox_lib:notify', source, {
            title = 'Access Denied',
            description = 'You must be an admin to use this command.',
            type = 'error'
        })
    end

    local target = QBCore.Functions.GetPlayer(args.id)
    if not target then
        debugPrint('Reset failed: player not found')
        return TriggerClientEvent('ox_lib:notify', source, {
            title = 'Player Not Found',
            description = 'No player with that ID.',
            type = 'error'
        })
    end

    local metadata = target.PlayerData.metadata or {}
    local currentLicenses = metadata.licences or {}

    for k, v in pairs(DefaultLicenses) do
        if currentLicenses[k] == nil then
            currentLicenses[k] = v
        end
    end

    target.Functions.SetMetaData('licences', currentLicenses)

    debugPrint(('Reset all licenses for %s'):format(target.PlayerData.charinfo.firstname))

    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Licenses Reset',
        description = ('%s %s now has a full license set.'):format(
            target.PlayerData.charinfo.firstname,
            target.PlayerData.charinfo.lastname
        ),
        type = 'success'
    })

    TriggerClientEvent('ox_lib:notify', args.id, {
        title = 'Your Licenses Were Reset',
        description = 'A full set of licenses has been initialized for your character.',
        type = 'info'
    })
end)

-- Toggle Event
RegisterNetEvent('license:toggle', function(data)
    local src = source
    local issuer = QBCore.Functions.GetPlayer(src)
    local target = QBCore.Functions.GetPlayer(data.targetId)
    if not issuer or not target then return end

    if src == data.targetId then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Denied',
            description = 'You cannot edit your own licenses',
            type = 'error'
        })
    end

    if not canToggleLicense(issuer, data.license) then
        debugPrint(('Unauthorized toggle attempt: %s tried to toggle %s'):format(issuer.PlayerData.charinfo.firstname, data.license))
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Permission Denied',
            description = 'You are not allowed to toggle this license.',
            type = 'error'
        })
    end

    updateLicense(target, data.license, data.newState)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'License Updated',
        description = ('Set %s to %s'):format(data.license, data.newState and "?" or "?"),
        type = 'success'
    })
end)

-- /showlicenses
lib.addCommand('showlicenses', {
    help = 'View and toggle a player\'s licenses',
    restricted = true,
    params = {
        { name = 'id', help = 'Player ID', type = 'number' }
    }
}, function(source, args)
    local target = QBCore.Functions.GetPlayer(args.id)
    if not target then
        debugPrint('Show failed: player not found')
        return TriggerClientEvent('ox_lib:notify', source, {
            title = 'Player Not Found',
            description = 'Invalid player ID',
            type = 'error'
        })
    end

    local metadata = target.PlayerData.metadata or {}
    local licenses = metadata.licences or {}

    for k, v in pairs(DefaultLicenses) do
        if licenses[k] == nil then
            licenses[k] = v
        end
    end

    debugPrint(('Opening license menu for ID %s (%s)'):format(args.id, target.PlayerData.charinfo.firstname))
    debugPrint('Fetched licenses:', json.encode(licenses))

    local options = {}
    for license, value in pairs(licenses) do
        table.insert(options, {
            title = ("%s %s"):format(value and "?" or "?", license),
            icon = value and "check" or "x",
            description = "Click to toggle",
            event = "license:toggle",
            args = {
                targetId = target.PlayerData.source,
                license = license,
                newState = not value
            }
        })
    end

TriggerClientEvent('license:showContext', source, {
    title = ("Licenses for %s %s"):format(
        target.PlayerData.charinfo.firstname,
        target.PlayerData.charinfo.lastname
    ),
    options = options
})
end)
