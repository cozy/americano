# Americano

[ExpressJS](http://expressjs.com/)
is an awesome tool to build small web application. But once you start
using it, you discover that writing the configuration and the routes
often leads to ugly code. To solve that, Americano acts as a
wrapper around Express and make it more opinionated about how to write routes
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


### Binary

There is a binary provided with Americano to start quickly your project:

#### Install

    npm install americano -g

#### Usage

    americano blog

#### Output

    create: blog
    create: blog/package.json
    create: blog/server.js
    create: blog/README.md
    create: blog/client/public
    create: blog/server/models
    create: blog/server/controllers
    create: blog/server/controllers/routes.js
    create: blog/server/controllers/index.js
    create: blog/server/config.js

    install dependencies:
    $ cd blog && npm install

    Run your application:
    $ npm start

#### Coffeescript Usage

    americano --coffee blog

### Handmade

To write an Americano application you need to add it as a dependency of your
package.json file.

    npm install americano --save

Then you must to create your main file:

```javascript
// ./server.js
var americano = require('americano');

var port = process.env.PORT || 3000;
americano.start({name: 'yourapp', port: port});
```


## Configuration

Americano requires a config file located at the
root of your project, let's add it:

```javascript
// ./server/config.js
var americano = require('americano');

module.exports = {
  common: [
    americano.bodyParser(),
    americano.methodOverride(),
    americano.errorHandler({
      dumpExceptions: true,
      showStack: true
    }),
    americano.static(__dirname + '/../client/public', {
      maxAge: 86400000
    })
  ],
  development: {
    use: [
      americano.logger('dev')
    ],
    set: {
      debug: 'on'
    }
  },
  production: [
    americano.logger('short')
  ]
};
```


## Routes

Once configuration is done, Americano will ask for your routes to be described
in a single file following this syntax:


```javascript
// ./server/controllers/routes.coffee
var posts = require('./posts');
var comments = require('./comments');

module.exports = {
  'posts': {
    get: posts.all,
    post: posts.create
  },
  'posts/:id': {
    get: posts.show,
    put: posts.modify,
    del: [posts.verifyToken, posts.destroy]
  },
  'posts/:id/comments': {
    get: comments.fromPost
  },
  'comments': {
    get: comments.all
  }
};
```

## Controllers

Your controllers can be written as usual, they are ExpressJS controlllers.

## Final thoughts

You're done! Just run `node server.js` and you have your configured
Express web server up and running!

By the way this is how your single-page app looks like with Americano:


    your-blog/
        server.js
        server/
            config.js
            controllers/
                routes.js
                posts.js
                comments.js
            models/
                post.js
                comment.js
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

* make a plugin for socket-io
* make a plugin for mongoose
* make a plugin for sqlite
* make a plugin for cozy-realtime-adapter

I didn't start any development yet, so you're welcome to participate!
