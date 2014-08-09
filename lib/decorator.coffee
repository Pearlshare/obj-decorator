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
    @restrictedKeys = _.uniq restrictedKeys.concat(@constructor.restrictedKeys)

    translations = options.translations || {}
    @translations = _.merge @constructor.translations, translations

    valueTransforms = options.valueTransforms || {}
    @valueTransforms = _.merge @constructor.valueTransforms, valueTransforms


  ###
    decorate
    @param {Object} out - object/array/string/something else to process
  ###
  decorate: (out) ->
    copy = _.clone(out)
    @_decorateIt(copy)


  ###
    _decorateIt
    @param {Object} out - thing to convert
  ###
  _decorateIt: (out) ->

    switch Object.prototype.toString.call(out)
      when '[object Array]'
        out = out.map (item) => @_decorateIt(item)
        out = _.compact(out)
      when '[object Object]'
        out = @_decorateObject(out)
      when '[object Function]'
        out = undefined

    out


  ###
    Decorate an object
    @param {Object} out
  ###
  _decorateObject: (out) ->
    # if bson objects go weird
    return out.toString() if out._bsontype

    # If the object has a toObject method then call it so we have simple objects to manipulate
    out = out.toObject() if typeof out.toObject == 'function'

    # Apply value transformations such as 
    for transformKey, valueTransform of @valueTransforms
      if out[transformKey]
        try
          out[transformKey] = valueTransform(out[transformKey])
        catch
          console.error "value transform of key:#{key}, value:#{value} failed"

    # remame keys to the new key names from translations
    for badKey, goodKey of @translations
      if out[badKey]
        out[goodKey] = out[badKey]
        delete out[badKey]

    # Remove restricted keys
    delete out[restrictedKey] for restrictedKey in @restrictedKeys

    # Process through the object values
    for key, value of out

      continue unless value

      # Process values
      switch Object.prototype.toString.call(value)
        # Don't output functions
        when '[object Function]'
          delete out[key]
        # Process objects
        when '[object Object]'
          # Output empty objects as null
          if Object.keys(value) and Object.keys(value).length == 0
            out[key] = null
          # continue processing sub objects
          else
            out[key] = @_decorateIt value
        # Decorate arrays of items
        when '[object Array]'
          out[key] = @_decorateIt(value)

    out


module.exports = Decorator