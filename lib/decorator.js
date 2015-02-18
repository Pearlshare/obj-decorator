var _ = require('lodash');


/**
 * new - create a new decorator instance
 *	@param {Object} options
 *	@option {Array} restrictedKeys - keys to remove from the output document
 *	@option {Object} translations - key/value of object keys to rename from/to
 *	@option {Object} keyValueTransforms - key/function of value types to tranform and their function
 */
function Decorator(options) {
	options = options || {};

	restrictedKeys = options.restrictedKeys || [];
	this.restrictedKeys = _.uniq(
		restrictedKeys.concat(this.constructor.restrictedKeys)
	);

	translations = options.translations || {};
	this.translations = _.merge(
		this.constructor.translations, translations
	);

	keyValueTransforms = options.keyValueTransforms || {};
	this.keyValueTransforms = _.merge(
		this.constructor.keyValueTransforms, keyValueTransforms
	);

	transforms = options.transforms || [];
	this.transforms = this.constructor.transforms.concat(transforms);
}

// An array of keys to remove from the output
Decorator.restrictedKeys = [];

// A dictionary of keys and what to rename them
Decorator.translations = {};

// A dictionary of keys and a function to perform on the corresponding values
Decorator.keyValueTransforms = {};

// An array of functions to test a value and apply a transform
Decorator.transforms = [];


/**
 * decorate
 * @param {Object} out - object/array/string/something else to process
 */
Decorator.prototype.decorate = function(out) {
	var type = Object.prototype.toString.call(out);

	if(type === '[object Array]') {
		var out = out.map(function(item) {
			return this.decorate(item)
		}, this);
		return _.compact(out);
	} else if (type === '[object Object]') {
		return this._decorateObject(out);
	} else if (type === '[object Function]') {
		return undefined;
	} else {
		return out;
	}
};


/**
 * Decorate an object
 * @param {Object} obj
 */
Decorator.prototype._decorateObject = function(obj) {
	// If the object has a toObject method then call it so we have simple objects to manipulate
	if(typeof(obj.toObject) === 'function') {
		obj = obj.toObject();
	}

	// Remove restricted keys
	this.restrictedKeys.forEach(function(key) {
		delete obj[key];
	});


	// Apply value transformations such as
	for(transformKey in this.keyValueTransforms) {
		var valueTransform = this.keyValueTransforms[transformKey];

		if(obj[transformKey]) {
			try {
				obj[transformKey] = valueTransform(obj[transformKey]);
			} catch (err) {
				console.error("value transform of key://"+transformKey+", value://"+obj[transformKey]+" failed");
			}
		}
	}

	// remame keys to the new key names from translations
	for(badKey in this.translations) {
		var goodKey = this.translations[badKey];
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
		this.transforms.forEach(function(transform) {
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
				obj[key] = this.decorate(obj[key]);
			}
		} else if(type === '[object Array]') {
			obj[key] = this.decorate(obj[key]);
		} else {
			obj[key] = this.decorate(obj[key]);
		}
	}

	return obj;
};

module.exports = Decorator;
