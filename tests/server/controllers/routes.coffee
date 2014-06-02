module.exports =
    # routes must not be empty, otherwise Express crashes
    # see https://github.com/visionmedia/express/issues/2159
    'fakeroute': get: (req, res) ->
