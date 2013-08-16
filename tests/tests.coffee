expect = require('chai').expect
americano = require('../main')

{JsonClient} = require('request-json')

# Configuration
describe '_configureEnv', ->
    it 'should add given middlewares to given app and environment', (done) ->
        middlewares = [americano.bodyParser()]
        americano.start {}, (app) ->
            client = new JsonClient 'http://localhost:3000/'

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
                    done()
                , false

# Routes
# Plugins
# Create new server
