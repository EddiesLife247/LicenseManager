RegisterNetEvent('license:showContext', function(data)
    lib.registerContext({
        id = 'license_menu',
        title = data.title,
        options = data.options
    })
    lib.showContext('license_menu')
end)
