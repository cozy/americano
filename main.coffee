###
# Unique file describing all the configuration steps done by americano.
###

express = require 'express'
fs = require 'fs'


# americano wraps express
module.exports = americano = express

# root folder, required to find the configuration files
root = process.cwd()

# Default configuration, used if no configuration file is found.
config =
    common: [
        americano.bodyParser()
        americano.methodOverride()
        americano.errorHandler
            dumpExceptions: true
            showStack: true
        americano.static __dirname + '/client/public',
            maxAge: 86400000
    ]
    development: [
        americano.logger 'dev'
    ]
    production: [
        americano.logger 'short'
    ]


# Load configuration file then load configuration for each environment.
_configure = (app) ->
    try
        config = require "#{root}/server/config"
    catch err
        console.log err
        console.log "[WARN] Can't load config file, use default one instead"

    _configureEnv app, env, middlewares for env, middlewares of config


# Load express/connect middlewares found in the configuration file.
_configureEnv = (app, env, middlewares) ->
    if env is 'common'
        app.use middleware for middleware in middlewares
    else
        app.configure env, =>
            app.use middleware for middleware in middlewares


# Load all routes found in the routes file.
_loadRoutes = (app) ->
    try
        routes = require "#{root}/controllers/routes"
    catch err
        console.log err
        console.log "[WARN] Route confiiguration file is missing, make " + \
                    "sure routes.(coffee|js) is located at the root of" + \
                    " the controlllers folder."
        process.exit 1

    for path, controllers of routes
        for verb, controller of controllers
            _loadRoute app, path, verb, controller

    console.log "[INFO] Routes loaded."


# Load given route in the Express app.
_loadRoute = (app, path, verb, controller) ->
    try
        app[verb] "/#{path}", controller

    catch e
        console.log "[ERROR] Can't load controller for " + \
                    "route #{verb} #{path} #{action}"
        process.exit 1


# Load given plugin by requiring it and running it as a function.
_loadPlugin = (app, plugin, callback) ->
    console.log "[INFO] add plugin: #{plugin}"
    try
        require("#{root}/node_modules/#{plugin}").configure root, app, callback
    catch err
        callback err


# Load plugins one by one then call given callback.
_loadPlugins = (app, callback) ->
    pluginList = config.plugins

    _loadPluginList = (list) ->
        if list.length > 0
            plugin = list.pop()
            _loadPlugin app, plugin, (err) ->
                if err
                    console.log err
                    console.log "[ERROR] #{plugin} failed to load."
                    process.exit 1
                else
                    console.log "[INFO] #{plugin} loaded."
                _loadPluginList list
        else
            callback()

    _loadPluginList pluginList


# Set the express application: configure the app, load routes and plugins.
_new = (callback) ->
    app = americano()
    _configure app
    _loadRoutes app
    _loadPlugins app, ->
        callback app


# Clean options, configure the application then starts the server.
americano.start = (options, callback) ->
    process.env.NODE_ENV = 'development' unless process.env.NODE_ENV?
    port = options.port || 3000
    root = options.root if options.root?
    name = options.name || "Americano"

    _new (app) ->
        app.listen port
        console.info "[INFO] Configuration for #{process.env.NODE_ENV} loaded."
        console.info "[INFO] #{name} server is listening on " + \
                    "port #{port}..."

        callback app if callback?
