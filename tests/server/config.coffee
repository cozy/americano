module.exports =
    common:
        useAfter: [
            (err, req, res, next) ->
                res.status(500).send message: err.message
        ]
        beforeStart: (callback) ->
            @set 'before', 'good'
            callback()
        afterStart: (app, server) ->
            @set 'after', 'still good'
