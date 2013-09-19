expect = require('chai').expect
americano = require('../main')

request = require('request-json')

if process.env.NODE_ENV isnt 'test'
    console.log "Tests should be run with NODE_ENV=test"
    process.exit 1

# Configuration
describe '_configureEnv', ->
    it 'should add given middlewares to given app and environment', (done) ->
        middlewares = [americano.bodyParser()]
        americano.start {}, (app, server) ->
            client = request.newClient 'http://localhost:3000/'

            americano._configureEnv app, 'development', middlewares
            app.post '/test-1/', (req, res) ->
                expect(req.body).to.be.undefined
                res.send ok: true, 200
            client.post 'test-1/', name: 'name_test', (err, res, body) ->
                expect(err).to.be.null

                americano._configureEnv app, 'test', middlewares
                app.post '/test-2/', (req, res) ->
                    expect(req.body.name).to.be.equal 'name_test'
                    res.send 200
                client.post 'test-2/', name: 'name_test', (err, res, body) ->
                    expect(err).to.be.null
                    server.close()
                    done()
                , false

# Routes
describe '_loadRoute', ->
    it 'should add route to given app', (done) ->
        americano.start {}, (app, server) ->
            client = request.newClient 'http://localhost:3000/'
            client.get 'test/', (err, res, body) ->
                expect(err).not.to.be.null
                msg = 'test ok'
                americano._loadRoute app, 'test/', 'get', (req, res) ->
                    res.send msg: msg
                client.get 'test/', (err, res, body) ->
                    expect(body.msg).to.equal msg
                    server.close()
                    done()

    it 'should support param routes', (done) ->
        americano.start {}, (app, server) ->
            client = request.newClient 'http://localhost:3000/'

            americano._loadRoute app, 'testid', 'param', (req, res, next, id) ->
                req.doubledid = id * 2
                next()

            americano._loadRoute app, 'test/:testid', 'get', (req, res) ->
                res.send doubled: req.doubledid

            client.get 'test/12', (err, res, body) ->
                expect(body.doubled).to.equal 24
                server.close()
                done()

# Plugins

# Create new server
