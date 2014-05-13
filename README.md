# Decorator

Decorate a mongoose model for use with an API.

## Actions

When run the decorator recursively changes:

* _id keys into uid
* date fields into unix timecode (milliseconds since epoch)

## Usage

```coffee
    Decorator = require("decorator")

    Decorator.restrictedKeys = ["__V"] # These get removed

    Decorator.translations = {_id: "uid"} # _id keys get replaced with uid

    user = new User(name: 'Fish', createdAt: new Date())

    console.log(user) #=> {_id: "5332a1499c8fd2412ba94c90", name: "Fish", createdAt: "Tue Apr 29 2014 16:52:39 GMT+0000 (UTC)", __v: 3}

    decorator = new Decorator(user)

    decorator.decorate().then (decorated) ->
      console.log(decorated) #=> {uid: "5332a1499c8fd2412ba94c90", name: "Fish", createdAt: 12938712398987}


    decorator = new Decorator(user, restrictedKeys: ['createdAt'], translations: {name: "shortName"})

    decorator.decorate (err, decorated) ->
      console.log(decorated) #=> {uid: "5332a1499c8fd2412ba94c90", shortName: "Fish"}

```

## Extending

The decorator class can be extended and the decorate method overridden.

```coffee
    Decorator = require("decorator")

    class UserDecorator extends Decorator

      # Override decorate to add a type switch
      decorate: (type) ->
        switch type
          when 'large'
            @model.populate("images")
              .then (user) =>
                @pearlsharify(user)
                  .then (decoratedUser) =>
                    @deferred.resolve(user)
              .catch @deferred.reject
          else
            @deferred.resolve @pearlsharify(@model)

```
