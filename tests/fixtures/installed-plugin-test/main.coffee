plugin = {}

plugin.configure = (options, app, callback) ->
    app.data = options.data
    callback() if callback?

plugin.getModel = ->
    return 42

module.exports = plugin
