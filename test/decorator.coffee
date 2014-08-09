chai = require("chai")
expect = chai.expect

Decorator = require('../index')

testData = 
  name: 'Oliver Brooks'
  dontShow: 'superSecret'
  sillyNameForDescription: 'Writing coffeescript at the moment!'
  createdAt: new Date()
  ohNoAFunction: () -> "Don't want functions in our output do we?"
  contactDetails: [
    {
      type: 'phone'
      value: 'myPhoneNumber'
    }
    {
      type: 'email'
      value: 'myEmailAddress'
    }
  ]


describe 'Decorator', ->

  describe 'global values', ->

    it 'should set the restrictedKeys', (done) ->
      Decorator.restrictedKeys = ['bob']
      decorator = new Decorator
      expect(decorator.restrictedKeys).to.include('bob')
      done()

    it 'should set the translations', (done) ->
      Decorator.translations = {'fish': 'face'}
      decorator = new Decorator
      expect(Object.keys(decorator.translations)).to.include('fish')
      done()


    it 'should set the valueTransforms', (done) ->
      Decorator.valueTransforms =
        transformKey: () -> 'new output'

      decorator = new Decorator
      expect(Object.keys(decorator.valueTransforms)).to.include('transformKey')
      done()

  describe 'decorate', ->

    context 'Default decorator', ->

      decorator = new Decorator

      it 'should strip out keys which have functions for values', (done) ->
        out = decorator.decorate(testData)
        expect(out.ohNoAFunction).to.equal(undefined)
        done()

      it 'should return undefined if no object is given', (done) ->
        out = decorator.decorate()
        expect(out).to.equal(undefined)
        done()

    context 'With restricted Keys', ->

      decorator = new Decorator(restrictedKeys: ['dontShow'])
      out = decorator.decorate(testData)

      it 'should not contain the dontshow key', (done) ->
        expect(out.dontShow).to.equal(undefined)
        done()

      it 'should not remove any other keys', (done) ->
        expect(out.name).to.equal(testData.name)
        done()

    context 'With Translations', ->

      decorator = new Decorator(translations: {sillyNameForDescription: 'description'})
      out = decorator.decorate(testData)

      it 'should not contain the dontshow key', (done) ->
        expect(out.description).to.equal(testData.sillyNameForDescription)
        done()

      it 'should not change other keys', (done) ->
        expect(out.name).to.equal(testData.name)
        done()

    context 'With value transforms', (done) ->

      decorator = new Decorator
        valueTransforms:
          createdAt: (v) -> v.getTime()

      out = decorator.decorate(testData)

      it 'should tranform the created at date to a time stamp', (done) ->
        expect(out.createdAt).to.equal(testData.createdAt.getTime())
        done()

      it 'should not change other values', (done) ->
        expect(out.name).to.equal(testData.name)
        done()

