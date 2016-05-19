path = require 'path'
fs = require 'fs'
pug = require 'pug'
url = require 'url'
assert = require 'assert'
mkdirp = require 'mkdirp'

helpers = require './helpers'

defaults =
  pug: {}
  useIndex: true
  listenExt: ['.pug', '.htm', '.html']
  templateExt: ['.pug']
  outputExt: '.html'
  maxAge: 0
  force: false
  saveOutput: true
  prefix: ''

getTemplatePath = (name, config) ->
  for ext in config.templateExt
    templatePath = path.join config.src, name + ext
    if fs.existsSync templatePath
      return templatePath

  return false

module.exports = (config) ->
  config = helpers.extend defaults, config

  assert config.src, 'src should be set'
  assert config.dest, 'dest should be set'
  assert config.maxAge >= 0, 'maxAge cannot be negative'
  assert config.templateExt, 'templateExt should be set'
  assert Array.isArray(config.templateExt), 'templateExt should be an array'

  (req, res, next) ->
    parsed = url.parse req.originalUrl
    fullname = parsed.pathname.replace config.prefix, ''
    extension = path.extname fullname
    name = fullname.substr 0, fullname.length - extension.length

    if config.useIndex and not extension
      name = path.join name, 'index'
      extension = config.templateExt[0]

    if extension not in config.listenExt
      return next()

    templatePath = getTemplatePath name, config

    if not templatePath
      return next()

    if not (templatePath.indexOf config.src) == 0
      return res.sendStatus 403

    res.setHeader 'Content-Type', 'text/html; charset=utf-8'
    res.setHeader 'Cache-Control', "max-age=#{config.maxAge}"
    res.setHeader 'Expires', (new Date +(new Date) + config.maxAge).toGMTString()

    fs.stat templatePath, (err, stat) ->
      if err
        return next err

      if not stat.isFile()
        return next()

      target = path.join config.dest, name + config.outputExt

      fs.stat target, (err, stat) ->
        if not err and stat.isFile() and not config.force
          fs.readFile target, 'utf8', (err, html) ->
            if err
              return next(err)

            res.setHeader 'Content-Length', Buffer.byteLength html
            res.end html
        else
          pug.renderFile templatePath, config.pug, (err, html) ->
            if err
              return next(err)

            if config.saveOutput
              mkdirp (path.dirname target), (err) ->
                if err
                  return next(err)
                  
                fs.writeFile target, html

            res.setHeader 'Content-Length', Buffer.byteLength html
            res.end html
