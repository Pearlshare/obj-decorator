_ = require 'lodash'

class Decorator

  # An array of keys to remove from the output
  @restrictedKeys = []
  # A dictionary of keys and what to rename them
  @translations = {}
  # A dictionary of keys and a function to perform on the corresponding values
  @valueTransforms = {}

  ###
    new - create a new decorator instance
    @param {Object} options
      @option {Array} restrictedKeys - keys to remove from the output document
      @option {Object} translations - key/value of object keys to rename from/to
      @option {Object} valueTransforms - key/function of value types to tranform and their function
  ###
  constructor: (options = {}) ->
    restrictedKeys = options.restrictedKeys || []
    @restrictedKeys = restrictedKeys.concat(@constructor.restrictedKeys)

    translations = options.translations || {}
    @translations = _.merge @constructor.translations, translations

    valueTransforms = options.valueTransforms || {}
    @valueTransforms = _.merge @constructor.valueTransforms, valueTransforms


  decorate: (out) ->
    # if undefined return
    return out if out == undefined || out._bsontype

    out = _.clone(out)

    # If the object has a toObject method then call it so we have simple objects to manipulate
    if typeof out.toObject == 'function'
      out = out.toObject()

    for key, value of out

      if value

        valueType = Object.prototype.toString.call(value)

        # Remove restricted keys
        for restrictedKey in @restrictedKeys
          delete out[restrictedKey]

        # Don't output functions
        if valueType == '[object Function]'
          delete out[key]

        # Process objects
        if valueType == '[object Object]' 
          # Output empty objects as null
          if Object.keys(value) and Object.keys(value).length == 0
            out[key] = null
          # continue processing sub objects
          else
            out[key] = @decorate value

        # Pearlsharify arrays of items
        if valueType == '[object Array]' and value.length > 0
          out[key] = @_decorateArray(value)

        # Apply value transformations such as 
        for transformKey, valueTransform of @valueTransforms
          if key == transformKey
            try
              out[key] = valueTransform(value)
            catch
              console.error "value transform of key:#{key}, value:#{value} failed"

        # remame keys to the new key names from translations
        for badKey, goodKey of @translations
          if key == badKey
            out[goodKey] = out[key]
            delete out[key]

    out


  _decorateArray: (array) ->
    newArray = []

    for item in array
      if Object.prototype.toString.call( item ) == '[object String]'
        newArray.push item
      else if Object.prototype.toString.call( item ) == '[object Object]' and not item.__parentArray
        newArray.push @decorate(item)

    newArray


module.exports = Decorator