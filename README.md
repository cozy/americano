# Americano

Express is an awesome tool to build small web application. But once you start
using it, you discover that writing the configuration and the routes
often leads to ugly code. To solve that, Americano acts as a
wrapper around Express and make it more opiniated about how to write routes
and configuration. See in the following how it make things cleaner.

Americano is:

* a tool to quickstart small web application or web module.
* oriented to build single page-app and REST API.

Americano is not:

* a full featured framework for making big web applications.

## Usage

    npm install americano


```coffeescript
# server.coffee
americano = require 'americano'
americano.start name: 'yourapp'
```


## Configuration

Americano requires a config file located at the root of the project:

```coffeescript
# ./config.coffee
americano = require 'americano'

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
    plugins: [
        'americano-cozy'
    ]

module.exports = config
```


## Routes

Put all your routes in a single file and read them in a clean way:


```coffeescript
# controllers/routes.coffee
blogs = require './blogs'
comments = require './comments'

module.exports =
    'posts':
        get: posts.all
        post: posts.create
    'posts/:id':
        get: posts.show
        put: posts.modify
        delete: posts.delete
    'posts/:id/comments':
        get: comments.fromPost
    'comments':
        get: comments.all
```

## Directory structure

This is how your single-page app look like with Americano:


    your-blog/
        server.coffee
        config.coffee
        controllers/
            routes.coffee
            posts.coffee
            comments.coffee
        mdoels/
            post.coffee
            comment.coffee
        client/
            ... front-end stuff ...

## Plugins

*work in progress...*

## What about contributions?

Here is what I would like to do next:

* write tests
* make a binary to add scaffolding to Americano (take advantage of 
  [scaffolt](https://github.com/paulmillr/scaffolt)?)
* make a plugin for mongoose and facilitate its integration.

I didn't start any development yet, so you're welcome to participate!
