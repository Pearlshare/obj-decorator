_ = require 'lodash'

class Decorator

  # An array of keys to remove from the output
  @restrictedKeys = []
  # A dictionary of keys and what to rename them
  @translations = {}
  # A dictionary of keys and a function to perform on the corresponding values
  @keyValueTransforms = {}
  # An array of functions to test a value and apply a transform
  @transforms = []


  ###
    new - create a new decorator instance
    @param {Object} options
      @option {Array} restrictedKeys - keys to remove from the output document
      @option {Object} translations - key/value of object keys to rename from/to
      @option {Object} keyValueTransforms - key/function of value types to tranform and their function
  ###
  constructor: (options = {}) ->
    restrictedKeys = options.restrictedKeys || []
    @restrictedKeys = _.uniq restrictedKeys.concat(@constructor.restrictedKeys)

    translations = options.translations || {}
    @translations = _.merge @constructor.translations, translations

    keyValueTransforms = options.keyValueTransforms || {}
    @keyValueTransforms = _.merge @constructor.keyValueTransforms, keyValueTransforms

    transforms = options.transforms || []
    @transforms = @constructor.transforms.concat transforms


  ###
    decorate
    @param {Object} out - object/array/string/something else to process
  ###
  decorate: (out) ->
    @_decorateIt(out)


  ###
    _decorateIt
    @param {Object} out - thing to convert
  ###
  _decorateIt: (out) ->

    self = this

    switch Object.prototype.toString.call(out)
      when '[object Array]'
        out = out.map (item) -> self._decorateIt(item)
        out = _.compact(out)
      when '[object Object]'
        out = self._decorateObject(out)
      when '[object Function]'
        out = undefined
    out


  ###
    Decorate an object
    @param {Object} obj
  ###
  _decorateObject: (obj) ->

    # If the object has a toObject method then call it so we have simple objects to manipulate
    obj = obj.toObject() if typeof obj.toObject == 'function'

    # Remove restricted keys
    delete obj[restrictedKey] for restrictedKey in @restrictedKeys

    # Apply value transformations such as 
    for transformKey, valueTransform of @keyValueTransforms
      if obj[transformKey]
        try
          obj[transformKey] = valueTransform(obj[transformKey])
        catch
          console.error "value transform of key:#{transformKey}, value:#{obj[transformKey]} failed"

    # remame keys to the new key names from translations
    for badKey, goodKey of @translations
      if obj[badKey]
        obj[goodKey] = obj[badKey]
        delete obj[badKey]

    # Process through the object values
    for key, value of obj
      # # if bson objects go weird
      # return obj.toString() if obj._bsontype

      continue unless value
      
      # Apply the transform functions
      transform(obj, key, value) for transform in @transforms

      # Process values
      switch Object.prototype.toString.call(value)
        # # Don't objput functions
        when '[object Function]'
          delete obj[key]
        # Process objects
        when '[object Object]'
          # Output empty objects as null
          if Object.keys(value) and Object.keys(value).length == 0
            obj[key] = null
          # continue processing sub objects
          else
            obj[key] = @_decorateIt obj[key]
        # Decorate arrays of items
        when '[object Array]'
          obj[key] = @_decorateIt(obj[key])
        else
          obj[key] = @_decorateIt(obj[key])

    obj


module.exports = Decorator