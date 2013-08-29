#!/usr/bin/env node

var exec = require('child_process').exec
  , program = require('commander')
  , mkdirp = require('mkdirp')
  , pkg = require('../package.json')
  , version = pkg.version
  , os = require('os')
  , fs = require('fs');

// CLI

program
  .version(version)
  .usage('[options] [dir]')
  .parse(process.argv);

// Path

var path = program.args.shift() || '.';

// end-of-line code

var eol = os.EOL

/**
* Routes index template.
*/
var routes = [
  "coffeecups = require './coffeecups'",
  "module.exports =",
  "    'index':",
  "        get: index.index"
].join(eol);


/**
* App template.
*/

var app = [
  "americano = require 'americano'",
  "",
  "port = process.env.PORT || 3000",
  "americano.start name: '', port: port"
].join(eol);

var index = [
  "module.exports.index = (req, res, next) ->",
  "    res.send 'Hello'"
].join(eol);




// Generate application

(function createApplication(path) {
  createApplicationAt(path);
})(path);

/**
* Create application at the given directory `path`.
*
* @param {String} path
*/

function createApplicationAt(path) {
  console.log();
  process.on('exit', function(){
    console.log();
    console.log(' install dependencies:');
    console.log(' $ cd %s && npm install', path);
    console.log();
    console.log(' Run your application:');
    console.log(' $ coffee server');
    console.log();
  });

  mkdir(path, function(){
    mkdir(path + '/client/public');
    mkdir(path + '/server/models');
    mkdir(path + '/server/controllers', function() {
      write(path + '/server/controllers/route.coffee', routes);
      write(path + '/server/controllers/index.coffee', index);
    });

    var pkg = {
        name: 'application-name',
        version: '0.0.1',
        scripts: { start: 'coffee server' },
        dependencies: { americano: "0.2.0" }
    }
    write(path + '/package.json', JSON.stringify(pkg, null, 2));
    write(path + '/server.coffee', app);
  });
}

/**
* Check if the given directory `path` is empty.
*
* @param {String} path
* @param {Function} fn
*/

function emptyDirectory(path, fn) {
  fs.readdir(path, function(err, files){
    if (err && 'ENOENT' != err.code) throw err;
    fn(!files || !files.length);
  });
}

/**
* echo str > path.
*
* @param {String} path
* @param {String} str
*/

function write(path, str) {
  fs.writeFile(path, str);
  console.log(' \x1b[36mcreate\x1b[0m : ' + path);
}

/**
* Mkdir -p.
*
* @param {String} path
* @param {Function} fn
*/

function mkdir(path, fn) {
  mkdirp(path, 0755, function(err){
    if (err) throw err;
    console.log(' \033[36mcreate\033[0m : ' + path);
    fn && fn();
  });
}

/**
* Exit with the given `str`.
*
* @param {String} str
*/

function abort(str) {
  console.error(str);
  process.exit(1);
}
