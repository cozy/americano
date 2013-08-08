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


    # server.coffee
    americano = require 'americano'
    americano.start name: 'yourapp'


## Configuration

*work in progress...*

## Routes

*work in progress...*

## Directory structure

*work in progress...*

## Plugins

*work in progress...*

## What about contributions?

Here is what I would like to do next:

* write tests
* make a binary to add scaffolding to Americano (take advantage of 
  [scaffolt](https://github.com/paulmillr/scaffolt)?)
* make a plugin for mongoose and facilitate its integration.

I didn't start any development yet, so you're welcome to participate!
