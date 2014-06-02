###
# Unique file describing all the configuration steps done by americano.
###

express = require 'express'
fs = require 'fs'
log = require('printit')
    date: true
    prefix: 'americano'


# americano wraps express
module.exports = americano = express

# root folder, required to find the configuration files
root = process.cwd()

# Re-bundle middlewares
Object.defineProperty americano, 'bodyParser', value: require 'body-parser'
Object.defineProperty americano, 'methodOverride',
                                               value: require 'method-override'
Object.defineProperty americano, 'errorHandler', value: require 'errorhandler'
Object.defineProperty americano, 'logger', value: require 'morgan'

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
        log.warn "Can't load config file, use default one instead"

    for env, middlewares of config
        americano._configureEnv app, env, middlewares


# Load express/connect middlewares found in the configuration file.
# If set or engine properties are written they are applied too.
# beforeStart and afterStat method are also set on given application.
americano._configureEnv = (app, env, middlewares) ->
    applyMiddlewares = ->
        if middlewares instanceof Array
            for middleware in middlewares
                middleware = [middleware] unless middleware instanceof Array
                app.use.apply app, middleware
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
        log.warn "Route configuration file is missing, make " + \
                    "sure routes.(coffee|js) is located at the root of" + \
                    " the controllers folder."
        log.warn "No routes loaded"
    for path, controllers of routes
        for verb, controller of controllers
            americano._loadRoute app, path, verb, controller

    log.info "Routes loaded."


# Load given route in the Express app.
americano._loadRoute = (app, path, verb, controller) ->
    try
        if verb is "param"
            app.param path, controller
        else
            if controller instanceof Array
                app[verb].apply app, ["/#{path}"].concat controller
            else
                app[verb] "/#{path}", controller
    catch err
        log.error "Can't load controller for " + \
                    "route #{verb} #{path} #{action}"
        console.log err
        process.exit 1


# Load given plugin by requiring it and running it as a function.
americano._loadPlugin = (app, plugin, callback) ->
    log.info "add plugin: #{plugin}"

    # Enable absolute path for plugins
    if plugin.indexOf('/') is -1
        # if the plugin's path isn't absolute, we let node looking for it
        pluginPath = plugin
    else
        # otherwise it looks for the plugin from the root folder
        pluginPath = require('path').join __dirname, root, plugin

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
                    log.error "#{plugin} failed to load."
                    console.log err
                else
                    log.info "#{plugin} loaded."
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
        unless app.beforeStart? then app.beforeStart = (cb) -> cb()
        app.beforeStart ->
            server = app.listen port, host, ->
                app.afterStart app, server if app.afterStart?
                log.info "Configuration for #{process.env.NODE_ENV} loaded."
                log.info "#{name} server is listening on " + \
                          "port #{port}..."

                callback app, server if callback?
