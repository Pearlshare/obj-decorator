var compact = require('lodash.compact');
var assign  = require('lodash.assign');


/**
 * Returns a decorator function
 *
 *	@param {Object} opts
 *	@param {Array}  opts.restricted - keys to remove from the output document
 *	@param {Object} opts.keyTransforms - key/value of object keys to rename from/to
 *	@param {Object} opts.valueTransforms - key/function of value types to tranform and their function
 */
function decorator(opts) {
	opts = assign({
    restricted: [],
    keyTransforms: {},
    valueTransforms: {},
    transforms: []
  }, opts);

  return function(obj) {
    return decorate(obj, opts);
  }
}

/**
 * Decorate an mixed type
 * @param {Mixed} out
 * @param {Object} obj @see decorator
 */
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
  opts.restricted.forEach(function(key) {
		delete obj[key];
	});


	// Apply value transformations such as
	for(transformKey in opts.valueTransforms) {
		var valueTransform = opts.valueTransforms[transformKey];

		if(obj[transformKey]) {
      obj[transformKey] = valueTransform(obj[transformKey]);
		}
	}

	// remame keys to the new key names from keyTransforms
	for(badKey in opts.keyTransforms) {
		var goodKey = opts.keyTransforms[badKey];
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
