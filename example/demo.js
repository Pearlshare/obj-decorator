var assert    = require("assert");
var decorator = require("../");

var decorate = decorator({
  catchErrs: false,
  // These get removed
  restricted: ["__v"],
  // '_id' keys get replaced with 'uid'
  keyTransforms: {
    "_id": "uid"
  },
  // To transform the values
  valueTransforms: {
    createdAt: function(value) {
      return new Date(value).getTime();
    }
  },
  // Generic transform
  transforms: [
    function(obj, key, value) {
      if(key === "desc") {
        obj["description"] = "'"+value+"'";
        delete obj[key];
      }
    }
  ]
});

var obj = {
  _id: "5332a1499c8fd2412ba94c90",
  desc: "test desc",
  name: "Fish",
  createdAt: "Tue Apr 29 2014 16:52:39 GMT+0000 (UTC)",
  __v: 3
};

var out = decorate(obj);
assert.equal(out.uid, "5332a1499c8fd2412ba94c90");
assert.equal(out.description, "'test desc'");
assert.equal(out.name, "Fish");
assert.equal(out.createdAt, 1398790359000);
assert(!out.hasOwnProperty("__v"));

