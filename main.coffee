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
        americano.static __dirname + '/../../client/public',
            maxAge: 86400000
    ]
    development: [
        americano.logger 'dev'
    ]
    production: [
        americano.logger 'short'
    ]


# Load configuration file then load configuration for each environment.
americano._configure = (app) ->
    try
        config = require "#{root}/server/config"
    catch err
        console.log err
        console.log "[WARN] Can't load config file, use default one instead"

    for env, middlewares of config
        americano._configureEnv app, env, middlewares


# Load express/connect middlewares found in the configuration file.
# If set or engine properties are written they are applied too.
# beforeStart and afterStat method are also set on given application.
americano._configureEnv = (app, env, middlewares) ->
    applyMiddlewares = ->
        if middlewares instanceof Array
            app.use middleware for middleware in middlewares
        else
            for method, elements of middlewares
                if method in ['beforeStart', 'afterStart']
                    app[method] = elements
                else if method is 'use'
                    app[method] element for element in elements
                else
                    for key, value of elements
                        app[method].apply app, [key, value]
                        app.get key

    applyMiddlewares() if env is 'common' or env is app.get 'env'


# Load all routes found in the routes file.
americano._loadRoutes = (app) ->
    try
        routes = require "#{root}/server/controllers/routes"
    catch err
        console.log err
        console.log "[WARN] Route configuration file is missing, make " + \
                    "sure routes.(coffee|js) is located at the root of" + \
                    " the controlllers folder."
        console.log "[WARN] No routes loaded"

    for path, controllers of routes
        for verb, controller of controllers
            americano._loadRoute app, path, verb, controller

    console.log "[INFO] Routes loaded."


# Load given route in the Express app.
americano._loadRoute = (app, path, verb, controller) ->
    try
        if verb is "param"
            app.param path, controller
        else
            app[verb] "/#{path}", controller
    catch err
        console.log "[ERROR] Can't load controller for " + \
                    "route #{verb} #{path} #{action}"
        console.log err
        process.exit 1


# Load given plugin by requiring it and running it as a function.
americano._loadPlugin = (app, plugin, callback) ->
    console.log "[INFO] add plugin: #{plugin}"

    # Enable absolute path for plugins
    if plugin.indexOf('/') is -1
        pluginPath = "#{root}/node_modules/#{plugin}"
    else
        pluginPath = "#{root}/#{plugin}"

    try
        plugin = require pluginPath
        # merge plugin's properties into the americano instance
        americano extends plugin

        # run the plugin initializer
        americano.configure root, app, callback
    catch err
        callback err


# Load plugins one by one then call given callback.
americano._loadPlugins = (app, callback) ->
    pluginList = config.plugins

    _loadPluginList = (list) ->
        if list.length > 0
            plugin = list.pop()

            americano._loadPlugin app, plugin, (err) ->
                if err
                    console.log "[ERROR] #{plugin} failed to load."
                    console.log err
                else
                    console.log "[INFO] #{plugin} loaded."
                _loadPluginList list
        else
            callback()

    if pluginList?.length > 0
        _loadPluginList pluginList
    else
        callback()


# Set the express application: configure the app, load routes and plugins.
americano._new = (callback) ->
    app = americano()
    americano._configure app
    americano._loadPlugins app, ->
        americano._loadRoutes app
        callback app


# Clean options, configure the application then starts the server.
americano.start = (options, callback) ->
    process.env.NODE_ENV = 'development' unless process.env.NODE_ENV?
    port = options.port || 3000
    host = options.host || "127.0.0.1"
    root = options.root if options.root?
    name = options.name || "Americano"

    americano._new (app) ->
        if app.beforeStart?
            app.beforeStart()
        server = app.listen port, host, ->
            app.afterStart() if app.afterStart?
            console.info "[INFO] Configuration for #{process.env.NODE_ENV} loaded."
            console.info "[INFO] #{name} server is listening on " + \
                      "port #{port}..."

            callback app, server if callback?
