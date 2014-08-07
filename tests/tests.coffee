expect = require('chai').expect
request = require 'request-json'
exec = require('child_process').exec

americano = require '../main'


if process.env.NODE_ENV isnt 'test'
    console.log "Tests should be run with NODE_ENV=test"
    process.exit 1

# Configuration
describe '_configureEnv', ->
    it 'should add given middlewares to given app and environment', (done) ->
        middlewares = [americano.bodyParser()]
        americano.start root: __dirname, (app, server) ->
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
                data = name: 'name_test'
                client.post 'test-2/', data, (err, res, body) ->
                    expect(err).to.be.null
                    server.close()
                    done()
                , false

describe '_configurEnv with object', ->
    it 'should add given middlewares apply set properties', (done) ->
        client = request.newClient 'http://localhost:3000/'
        middlewares =
            use: [americano.bodyParser()]
            set:
                mydata: 'ok'

        americano.start root: __dirname, (app, server) ->
            americano._configureEnv app, 'common', middlewares
            expect(app.get 'mydata').to.equal 'ok'
            app.post '/test-1/', (req, res) ->
                expect(req.body.name).to.be.equal 'name_test'
                res.send ok: true, 200

            client.post 'test-1/', name: 'name_test', (err, res, body) ->
                expect(err).to.be.null
                expect(body.ok).to.be.true
                server.close()
                done()


describe '_configureEnv with beforeStart and afterStart', ->
    it 'should run given methods before and after application starts', (done) ->
        americano.start root: __dirname, (app, server) ->
            expect(app.get 'before').to.be.equal 'good'
            expect(app.get 'after').to.be.equal 'still good'
            server.close()
            done()

# Routes
describe '_loadRoute', ->
    it 'should add route to given app', (done) ->
        americano.start root: __dirname, (app, server) ->
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

    it 'should add several controllers for given route to app', (done) ->
        americano.start root: __dirname, (app, server) ->
            client = request.newClient 'http://localhost:3000/'

            client.get 'test/', (err, res, body) ->
                expect(err).not.to.be.null

                msg = 'test ok'
                msg2 = 'test array ok'
                americano._loadRoute app, 'test/', 'get', [
                    (req, res, next) ->
                        req.mytest = msg2
                        next()
                    (req, res) -> res.send msg: msg, msg2: req.mytest
                ]
                client.get 'test/', (err, res, body) ->
                    expect(err).to.be.null
                    expect(body.msg).to.equal msg
                    expect(body.msg2).to.equal msg2
                    server.close()
                    done()

    it 'should support param routes', (done) ->
        americano.start root: __dirname, (app, server) ->
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
describe '_loadPlugin', ->
    before (done) ->
        command = "cp -R ./fixtures/installed-plugin-test ../node_modules"
        exec command, done

    it 'should add plugin to given app when path is absolute', (done) ->
        americano.start root: __dirname, (app, server) ->
            pluginPath = '../node_modules/installed-plugin-test/main'
            americano._loadPlugin root: './tests', app, pluginPath, (err) ->
                expect(err).not.to.exist
                expect(americano.getModel()).to.equal 42
                server.close done

    it 'should add plugin to given app when path is relative', (done) ->
        americano.start root: __dirname, (app, server) ->
            americano._loadPlugin root: './tests', app, 'installed-plugin-test', (err) ->
                expect(err).not.to.exist
                expect(americano.getModel()).to.equal 42
                server.close done

# Create new server
