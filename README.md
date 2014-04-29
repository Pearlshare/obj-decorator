# Decorator

Decorate a mongoose model for use with an API.

## Actions

When run the decorator recursively changes:

* _id keys into uid
* date fields into unix timecode (milliseconds since epoch)

## Usage

```coffee
    Decorator = require("decorator")

    user = new User(name: 'Fish', createdAt: new Date())

    console.log(user) #=> {_uid: "5332a1499c8fd2412ba94c90", name: "Fish", createdAt: "Tue Apr 29 2014 16:52:39 GMT+0000 (UTC)"}

    decorator = new Decorator(user)

    decorator.decorate()

    decorator.then (decorated) ->
      console.log(decorated) #=> {uid: "5332a1499c8fd2412ba94c90", name: "Fish", createdAt: 12938712398987}

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
