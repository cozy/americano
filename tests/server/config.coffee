module.exports =
    common:
        beforeStart: ->
            @set 'before', 'good'
        afterStart: ->
            @set 'after', 'still good'
