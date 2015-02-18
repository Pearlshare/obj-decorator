# ps-decorator
Decorate an object for use with an API. Can set restricted keys to remove, translations of key names and apply transforms to values.

## Usage

    # Setup decorator globals
    var decorator = require("ps-decorator");

    var decorate = decorator({
      // These get removed
      restrictedKeys: ["__v"],
      // _id keys get replaced with uid
      translations: {_id: "uid"},
      keyValueTransforms: {
        createdAt: function(value) {
          return value.getTime();
        }
      },
      transforms: [
        function(obj, key, value) {
          if(key._bsontype) {
            out[key+"Id"] = value.toString();
            delete out[key]
          }
        }
      ]
    });

    var obj = {
      _id: "5332a1499c8fd2412ba94c90",
      name: "Fish",
      createdAt: "Tue Apr 29 2014 16:52:39 GMT+0000 (UTC)",
      __v: 3
    };

    decorate(obj) // => {uid: "5332a1499c8fd2412ba94c90", name: "Fish", createdAt: 12938712398987}


## Licence
MIT
