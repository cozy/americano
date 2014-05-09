module.exports =
    common:
        beforeStart: (callback) ->
            @set 'before', 'good'
            callback()
        afterStart: ->
            @set 'after', 'still good'
