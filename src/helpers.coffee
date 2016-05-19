module.exports =
  extend: exports.extend = (object, properties) ->
    for key, val of properties
      object[key] = val
    object

  merge: (base, extensions...) ->
    object = extend base, {}
    for extension in extensions
      object = module.exports.extend object, extension
    object

  copy: (base) ->
    module.exports.extend base, {}

  trim: (string, characters) ->
    characters = (characters + '').replace /[.?*+^$[\]\\(){}|-]/g, '\\$&'
    string = string.replace /^\s\s*/, ''
    pattern = new RegExp "[#{characters}]"
    index = string.length
    while pattern.test str.charAt --index
      continue
    string.slice 0, index + 1
