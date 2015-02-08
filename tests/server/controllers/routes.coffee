module.exports =
    # routes must not be empty, otherwise Express crashes
    # see https://github.com/visionmedia/express/issues/2159
    'fakeroute': get: (req, res) ->

    'test-error':
        post: (req, res, next) ->
            next new Error 'test_error'
