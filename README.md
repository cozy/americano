# Americano

[ExpressJS](http://expressjs.com/)
is an awesome tool to build small web application. But once you start
using it, you discover that writing the configuration and the routes
often leads to ugly code. To solve that, Americano acts as a
wrapper around Express and make it more opiniated about how to write routes
and configuration. See in the following how it make things cleaner.

## When to use Americano?

Americano is:

* a tool to quickstart small web applications or web modules.
* oriented to build single page-app and REST API.

Americano is not:

* a full-featured framework for making big web applications.

NB: Americano inherits all the [ExpressJS
features](http://expressjs.com/guide.html)

## Getting started

To write an Americano application you need to add it as dependecy of your
package.json file.

    npm install americano --save

Then you must to create your main file:

```coffeescript
# ./server.coffee
americano = require 'americano'
americano.start name: 'yourapp'
```


## Configuration

Americano requires a config file located at the
root of your project, let's add it:

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

Once configuration is done, Americano will ask for your routes to be described
in a single file following this syntax:


```coffeescript
# server/controllers/routes.coffee
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


## Final thoughts

You're done! Just run `coffee server.coffee` and you have your configured
Express web server up and running!

By the way this is how your single-page app looks like with Americano:


    your-blog/
        server.coffee
        config.coffee
        server/
            controllers/
                routes.coffee
                posts.coffee
                comments.coffee
            models/
                post.coffee
                comment.coffee
        client/
            ... front-end stuff ...

## Plugins

Americano allows to use plugins that shares its philosophy of making cleaner
and more straightforward things.

Actually there is only one plugin, feel free to add yours:

* [americano-cozy](https://github.com/frankrousseau/americano-cozy): a plugin 
to make [Cozy](http://cozy.io) application faster.

## What about contributions?

Here is what I would like to do next:

* write tests
* make a binary to add scaffolding to Americano (take advantage of 
  [scaffolt](https://github.com/paulmillr/scaffolt)?)
* make a plugin for mongoose and facilitate its integration.

I didn't start any development yet, so you're welcome to participate!
