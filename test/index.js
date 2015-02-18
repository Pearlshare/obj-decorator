var assert    = require('assert');
var _         = require('lodash');
var decorator = require('../index');


var origData = {
  name: 'Oliver Brooks',
  dontShow: 'superSecret',
  sillyNameForDescription: 'Writing coffeescript at the moment!',
  createdAt: new Date(),
  ohNoAFunction: function() {
    return "Don't want functions in our output do we?";
  },
  contactDetails: [
    {
      type: 'phone',
      value: 'myPhoneNumber'
    },
    {
      type: 'email',
      value: 'myEmailAddress'
    }
  ],
  otherArray: [
    'fish',
    1,
    function() {
      return 'function output'
    },
    {object: 'pig'}
  ]
};

describe('decorator', function() {
  var testData;

  beforeEach(function(done) {
    testData = _.clone(origData);
    done();
  });

  context('Default decorator', function() {

    it('should strip out keys which have functions for values', function(done) {
      var out = decorator()(testData);
      assert.equal(out.ohNoAFunction, undefined);
      done();
    });

    it('should return undefined if no object is given', function(done) {
      var out = decorator()();
      assert.equal(out, undefined);
      done();
    });
  });

  context('With restricted Keys', function() {
    var out;

    beforeEach(function(done) {
      out = decorator({
        restrictedKeys: ['dontShow']
      })(testData);

      done();
    });

    it('should not contain the dontshow key', function(done) {
      assert.equal(out.dontShow, undefined);
      done();
    });

    it('should not remove any other keys', function(done) {
      assert.equal(out.name, origData.name);
      done();
    });
  });

  context('With Translations', function() {
    var out;

    before(function(done) {
      out = decorator({
        translations: {sillyNameForDescription: 'description'}
      })(testData);
      done();
    });

    it('should not contain the dontshow key', function(done) {
      assert.equal(out.description, origData.sillyNameForDescription);
      done();
    })

    it('should not change other keys', function(done) {
      assert.equal(out.name, origData.name);
      done();
    });
  });

  context('With value transforms', function(done) {
    var out;

    before(function(done) {
      out = decorator({
        keyValueTransforms: {
          createdAt: function(v) {
            return v.getTime();
          }
        }
      })(testData);
      done();
    });

    it('should tranform the created at date to a time stamp', function(done) {
      assert.equal(out.createdAt, origData.createdAt.getTime());
      done();
    });

    it('should not change other values', function(done) {
      assert.equal(out.name, origData.name);
      done();
    });
  });

  context('nested arrays', function() {
    var decorate;

    before(function(done) {
      decorate = decorator({
        restrictedKeys: ['type']
      });
      done();
    });

    it('should remove type from the nested objects', function(done) {
      out = decorate(testData);
      assert(!out.contactDetails[0].hasOwnProperty('type'));
      done();
    });

    it('should remove functions', function(done) {
      out = decorate(testData);
      assert.equal(out.otherArray.length, 3);
      done();
    });

    it('should remove functions', function(done) {
      out = decorate(testData);
      assert.equal(out.otherArray.length, 3);
      done();
    });

  });
});


