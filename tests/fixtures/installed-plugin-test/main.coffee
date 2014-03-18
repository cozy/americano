plugin = {}

plugin.configure = (root, app, callback) -> callback() if callback?

plugin.getModel = ->
    return 42

module.exports = plugin