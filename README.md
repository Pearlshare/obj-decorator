# Decorator

Decorate an object for use with an API. Can set restricted keys to remove, translations of key names and apply transforms to values.

## Usage

```coffee
    # Setup decorator globals
    Decorator = require("ps-decorator")
    Decorator.restrictedKeys = ["__v"] # These get removed
    Decorator.translations = {_id: "uid"} # _id keys get replaced with uid
    Decorator.keyValueTransforms =
      createdAt: (value) -> value.getTime()
    Decorator.transforms.push (obj, key, value) ->
      out["#{key}Id"] =  value.toString() if key._bsontype?
      delete out[key]

    user = new User(_id: '2974392742', __v: 2, name: 'Fish', createdAt: new Date())

    console.log(user) #=> {_id: "5332a1499c8fd2412ba94c90", name: "Fish", createdAt: "Tue Apr 29 2014 16:52:39 GMT+0000 (UTC)", __v: 3}

    decorator = new Decorator()
    decorated = decorator.decorate(user)
    console.log(decorated) #=> {uid: "5332a1499c8fd2412ba94c90", name: "Fish", createdAt: 12938712398987}

    # Set instance configurations
    decorator = new Decorator(restrictedKeys: ['createdAt'], translations: {name: "shortName"})

    decorated = decorator.decorate(user)
    console.log(decorated) #=> {uid: "5332a1499c8fd2412ba94c90", shortName: "Fish"}

```

## Extending

The decorator class can be extended and the decorate method overridden.

```coffee
    Decorator = require("ps-decorator")

    class UserDecorator extends Decorator

      # Override decorate to add a type switch
      decorate: (obj, type) ->
        obj = super
        switch type
          when 'large'
            obj.extraProperty = "fishing"
          else
            obj

```
