###
# Unique file describing all the configuration steps done by americano.
###

express = require 'express'
fs = require 'fs'
path = require 'path'
log = require('printit')
    date: true
    prefix: 'americano'
morgan  = require 'morgan'
logFormat = \ # We don't like the default logging.
    '[:date] - :method :url - :status - ' + \
    ':response-time ms -  :res[content-length]'
morgan.format 'short', logFormat


# americano wraps express
module.exports = americano = express


# Function to put some express modules by defaults.
_bundleMiddleware = (name, moduleName) ->
    Object.defineProperty americano, name, value: require moduleName

# Re-bundle middlewares. They are not included by default in Express but
# for building rest APIs they are very useful.
_bundleMiddleware 'bodyParser', 'body-parser'
_bundleMiddleware 'methodOverride', 'method-override'
_bundleMiddleware 'errorHandler', 'errorhandler'
_bundleMiddleware 'logger', 'morgan'


# Use to collect middlewares to apply after routes are set
afterMiddlewares = []

# Default configuration, used if no configuration file is found.
config =
    common:
        use: [
            americano.bodyParser()
            americano.methodOverride()
            americano.static __dirname + '/../../client/public',
                maxAge: 86400000
        ]
        useAfter: [
            americano.errorHandler
                dumpExceptions: true
                showStack: true
        ]
    development: [
        americano.logger 'dev'
    ]
    production: [
        americano.logger 'short'
    ]


# Load configuration file then load configuration for each environment.
americano._configure = (options, app) ->
    try
        config = require path.join options.root, "server", "config"
    catch err
        log.error err.stack or err
        log.warn "Can't load config file, use default one instead"

    for env, middlewares of config
        americano._configureEnv app, env, middlewares


# Load express/connect middlewares found in the configuration file.
# If set or engine properties are written they are applied too.
# beforeStart and afterStat method are also set on given application.
americano._configureEnv = (app, env, middlewares) ->

    if env is 'common' or env is app.get 'env'
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
                else if method is 'useAfter'
                    afterMiddlewares.push element for element in elements
                else
                    for key, value of elements
                        app[method].apply app, [key, value]
                        app.get key


# Apply middlewares to apply after routes are set.
americano._configureAfter = (app) ->
    app.use middleware for middleware in afterMiddlewares
    afterMiddlewares = []


# Load all routes found in the routes file.
americano._loadRoutes = (options, app) ->
    try
        rPath = path.join options.root, "server", "controllers", "routes"
        routes = require rPath
    catch err
        log.error err.stack or err
        log.warn "Route configuration file is missing, make " + \
                    "sure routes.(coffee|js) is located at the root of" + \
                    " the controllers folder."
        log.warn "No routes loaded"
    for reqpath, controllers of routes
        for verb, controller of controllers
            americano._loadRoute app, reqpath, verb, controller

    log.info "Routes loaded." unless options.silent


# Load given route in the Express app.
americano._loadRoute = (app, reqpath, verb, controller) ->
    try
        if verb is "param"
            app.param reqpath, controller
        else
            if controller instanceof Array
                app[verb].apply app, ["/#{reqpath}"].concat controller
            else
                app[verb] "/#{reqpath}", controller
    catch err
        log.error "Can't load controller for route #{verb}: #{reqpath}"
        log.raw err.stack or err
        process.exit 1


# Load given plugin by requiring it and running it as a function.
americano._loadPlugin = (options, app, plugin, callback) ->
    log.info "add plugin: #{plugin}" unless options.silent

    # Enable absolute path for plugins
    if plugin.indexOf('/') is -1
        # if the plugin's path isn't absolute, we let node looking for it.
        pluginPath = plugin
    else
        # otherwise it looks for the plugin from the root folder.
        pluginPath = path.join options.root, plugin

    try
        plugin = require pluginPath
        # merge plugin's properties into the americano instance.
        americano extends plugin

        # run the plugin initializer.
        americano.configure options, app, callback
    catch err
        callback err


# Load plugins one by one then call given callback.
americano._loadPlugins = (options, app, callback) ->
    pluginList = config.plugins

    _loadPluginList = (list) ->
        if list.length > 0
            plugin = list.pop()

            americano._loadPlugin options, app, plugin, (err) ->
                if err
                    log.error "#{plugin} failed to load."
                    log.raw err
                else
                    log.info "#{plugin} loaded." unless options.silent
                _loadPluginList list
        else
            callback()

    if pluginList?.length > 0
        _loadPluginList pluginList
    else
        callback()


# Listen for http (or https) connections
americano._listen = (app, options, callback) ->
    if options.tls
        server = require('https').createServer options.tls, app
        server.listen options.port, options.host, (err) ->
            callback err, server
    else if options.socket
        server = app.listen options.socket, (err) ->
            callback err, server
    else
        server = app.listen options.port, options.host, (err) ->
            callback err, server


# Set the express application: configure the app, load routes and plugins.
americano._new = (options, callback) ->
    app = americano()
    americano._configure options, app
    americano._loadPlugins options, app, (err) ->
        return callback err if err

        americano._loadRoutes options, app
        americano._configureAfter app
        callback null, app


# Clean options, configure the application then starts the server.
americano.start = (options, callback) ->
    process.env.NODE_ENV = 'development' unless process.env.NODE_ENV?
    options.port   ?= 3000
    options.name   ?= "Americano"
    options.host   ?= "127.0.0.1"
    options.root   ?= process.cwd()
    options.tls    ?= false
    options.socket ?= false

    americano._new options, (err, app) ->
        return callback? err if err

        app.beforeStart ?= (cb) -> cb()
        app.beforeStart (err) ->
            return callback? err if err

            americano._listen app, options, (err, server) ->
                return callback? err if err

                app.afterStart? app, server
                unless options.silent
                    log.info """
Configuration for #{process.env.NODE_ENV} loaded.
#{options.name} server is listening on port #{options.port}...
"""

                callback? null, app, server


# Clean options, configure the application then returns app via a callback.
# Useful to generate the express app for given module based on americano.
# In that gase
americano.newApp = (options, callback) ->
    americano._new options, (err, app) ->
        return callback? err if err

        unless options.silent
            log.info "Configuration for #{process.env.NODE_ENV} loaded."

        callback? null, app
