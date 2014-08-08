Q = require("q")

class Decorator

  # A dictionary of keys to remove from the output and what to replace them with
  @translations = {}
  @restrictedKeys = []

  ###
    new - create a new decorator instance
    @param {Object} source - source object to decorate
    @param {Object} options
      @option {Array} restrictedKeys - keys to remove from the output document
      @option {String} idKey - turn any _id or id keys into this key (defaults to 'uid')
  ###
  constructor: (source, options = {}) ->
    @deferred = Q.defer()
    @promise = @deferred.promise
    @source = source
    @restrictedKeys = options.restrictedKeys || []
    @translations = options.translations || {}


  ###
    decorate - decorates the provided object
    @param {Function} callback with node signature
    @returns {Promise}
  ###
  decorate: (callback) =>
    try
      @deferred.resolve @pearlsharify(@source)
    catch err
      @deferred.reject err
    
    @promise.nodeify(callback)


  pearlsharify: (out) =>
    # All hell breaks loose if looking up keys for the mongodb bson type
    return out if out._bsontype

    # If the object has a toObject method then call it so we have simple objects to manipulate
    if typeof out.toObject == 'function'
      out = out.toObject()

    for key, value of out

      if value

        valueType = Object.prototype.toString.call(value)

        # Remove restricted keys
        for restrictedKey in @restrictedKeys
          delete out[restrictedKey]

        # Remove global restricted keys
        for restrictedKey in @constructor.restrictedKeys
          delete out[restrictedKey]

        if valueType == '[object Object]' and Object.keys(value) and Object.keys(value).length == 0
          out[key] = null

        # Pearlsharify arrays of items
        if valueType == '[object Array]' and value.length > 0
          out[key] = @_pearlsharifyArray(value)

        # If the value has an id key then pearlsharify the value as it's an object
        else if (value.id || value.hasOwnProperty('_id'))
          out[key] = @pearlsharify value

        # Output dates as milliseconds since epoch
        if value instanceof Date
          out[key] = value.getTime()

        # remame bad keys to the good keys from global translations
        for badKey, goodKey of @constructor.translations
          if key == badKey
            out[goodKey] = out[key]
            delete out[key]

        # remame bad keys to the good keys from translations
        for badKey, goodKey of @translations
          if key == badKey
            out[goodKey] = out[key]
            delete out[key]

    delete out.__v

    out


  _pearlsharifyArray: (array) ->
    newArray = []

    for item in array
      if Object.prototype.toString.call( item ) == '[object String]'
        newArray.push item
      else if Object.prototype.toString.call( item ) == '[object Object]' and not item.__parentArray
        newArray.push @pearlsharify(item)

    newArray


module.exports = Decorator