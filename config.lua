Config = {}

Config.Debug = true -- ? Set to false in production


Config.LicenseIssuers = {
    police = {
        rank = 0,  -- minimum grade to issue
        licenses = { 'weapon', 'hgv', 'driver', 'taxi', 'boat', 'hunting' }
    },
    pilot = {
        rank = 2,
        licenses = { 'pilot', 'pilotheli' }
    },
    staff = {
        rank = 1,
        licenses = { 'pilot', 'pilotheli', 'taxi', 'hgv', 'boat', 'weapon', 'id', 'driver' }
    }

}
