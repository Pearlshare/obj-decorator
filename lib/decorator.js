var compact = require('lodash.compact');
var assign  = require('lodash.assign');


/**
 * new - create a new decorator instance
 *	@param {Object} opts
 *	@param {Array}  opts.restrictedKeys - keys to remove from the output document
 *	@param {Object} opts.translations - key/value of object keys to rename from/to
 *	@param {Object} opts.keyValueTransforms - key/function of value types to tranform and their function
 */
function decorator(opts) {
	opts = assign({
    restrictedKeys: [],
    translations: {},
    keyValueTransforms: {},
    transforms: []
  }, opts);

  return function(obj) {
    return decorate(obj, opts);
  }
}

function decorate(out, opts) {
  var type = Object.prototype.toString.call(out);
  if(type === '[object Array]') {
    var out = out.map(function(item) {
      return decorate(item, opts)
    });
    return compact(out);
  } else if (type === '[object Object]') {
    return _decorateObject(out, opts);
  } else if (type === '[object Function]') {
    return undefined;
  } else {
    return out;
  }
}


/**
 * Decorate an object
 * @param {Object} obj
 */
function _decorateObject(obj, opts) {
	// If the object has a toObject method then call it so we have simple objects to manipulate
	if(typeof(obj.toObject) === 'function') {
		obj = obj.toObject();
	}

	// Remove restricted keys
  opts.restrictedKeys.forEach(function(key) {
		delete obj[key];
	});


	// Apply value transformations such as
	for(transformKey in opts.keyValueTransforms) {
		var valueTransform = opts.keyValueTransforms[transformKey];

		if(obj[transformKey]) {
			try {
				obj[transformKey] = valueTransform(obj[transformKey]);
			} catch (err) {
				console.error("value transform of key://"+transformKey+", value://"+obj[transformKey]+" failed");
			}
		}
	}

	// remame keys to the new key names from translations
	for(badKey in opts.translations) {
		var goodKey = opts.translations[badKey];
		if(obj[badKey]) {
			obj[goodKey] = obj[badKey];
			delete obj[badKey]
		}
	}

	// Process through the object values
	for(key in obj) {
		var value = obj[key];

		if(value === undefined) {
			continue;
		}

		// Apply the transform functions
		opts.transforms.forEach(function(transform) {
			transform(obj, key, value);
		});

		// Process values
		var type = Object.prototype.toString.call(value);

		if(type === '[object Function]') {
			// // Don't objput functions
				delete obj[key]
		} else if(type === '[object Object]') {
			// Output empty objects as null
			if(Object.keys(value) && Object.keys(value).length == 0) {
				delete obj[key];
			// continue processing sub objects
			} else {
				obj[key] = decorate(obj[key], opts);
			}
		} else if(type === '[object Array]') {
			obj[key] = decorate(obj[key], opts);
		} else {
			obj[key] = decorate(obj[key], opts);
		}
	}

	return obj;
};

module.exports = decorator;
