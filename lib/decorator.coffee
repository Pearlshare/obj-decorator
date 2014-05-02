Q = require("q")

class Decorator

  constructor: (model, options = {}) ->
    @deferred = Q.defer()
    @promise = @deferred.promise
    @model = model
    @restrictedKeys = options.restrictedKeys || []
    @idKey = options.idKey || 'uid'


  decorate: ->
    @deferred.resolve @pearlsharify(@model)


  pearlsharify: (out) ->
    # All hell breaks loose if looking up keys for the mongodb bson type
    return out if out._bsontype

    # If the object has a toObject method then call it so we have simple objects to manipulate
    if typeof out.toObject == 'function'
      out = out.toObject()

    for key, value of out

      if value

        # Remove restricted keys
        for restrictedKey in @restrictedKeys
          delete out[restrictedKey]

        # Pearlsharify arrays of items
        if Object.prototype.toString.call( value ) == '[object Array]' and value.length > 0
          out[key] = @_pearlsharifyArray(value)

        # If the value has an id key then pearlsharify the value as it's an object
        else if (value.id || value.hasOwnProperty('_id'))
          out[key] = @pearlsharify value

        # Output dates as milliseconds since epoch
        if value instanceof Date
          out[key] = value.getTime()

        # Turn all ids into uid for the ios client
        if key in ['_id', 'id']
          out[@idKey] = out['_id'] || out['id']
          delete out._id
          delete out.id

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