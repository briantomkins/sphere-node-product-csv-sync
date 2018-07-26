_ = require 'underscore'
_.mixin require('underscore-mixins')
CONS = require '../lib/constants'
{Header, Validator} = require '../lib/main'

describe 'Header', ->
  beforeEach ->
    @validator = new Validator()

  describe '#constructor', ->
    it 'should initialize', ->
      expect(-> new Header()).toBeDefined()

    it 'should initialize rawHeader', ->
      header = new Header ['name']
      expect(header.rawHeader).toEqual ['name']

  describe '#validate', ->
    it 'should return error for each missing header', (done) ->
      csv =
        """
        foo,sku
        1,2
        """
      @validator.parse csv
      .then =>
        errors = @validator.header.validate()
        expect(errors.length).toBe 1
        expect(errors[0]).toBe "Can't find necessary base header 'productType'!"
        done()
      .catch (err) -> done.fail _.prettify(err)

    it 'should return error when no sku and not variantId header', (done) ->
      csv =
        """
        foo,productType
        1,2
        """
      @validator.parse csv
      .then =>
        errors = @validator.header.validate()
        expect(errors.length).toBe 1
        expect(errors[0]).toBe "You need either the column 'variantId' or 'sku' to identify your variants!"
        done()
      .catch (err) -> done.fail _.prettify(err)

    it 'should return error on duplicate header', (done) ->
      csv =
        """
        productType,name,variantId,name
        1,2,3,4
        """
      @validator.parse csv
      .then =>
        errors = @validator.header.validate()
        expect(errors.length).toBe 1
        expect(errors[0]).toBe "There are duplicate header entries!"
        done()
      .catch (err) -> done.fail _.prettify(err)

  describe '#toIndex', ->
    it 'should create mapping', (done) ->
      csv =
        """
        productType,foo,variantId
        1,2,3
        """
      @validator.parse csv
      .then =>
        h2i = @validator.header.toIndex()
        expect(_.size h2i).toBe 3
        expect(h2i['productType']).toBe 0
        expect(h2i['foo']).toBe 1
        expect(h2i['variantId']).toBe 2
        done()
      .catch (err) -> done.fail _.prettify(err)

  describe '#_productTypeLanguageIndexes', ->
    beforeEach ->
      @productType =
        id: '213'
        attributes: [
          name: 'foo'
          type:
            name: 'ltext'
        ]
      @csv =
        """
        someHeader,foo.en,foo.de
        """
    it 'should create language header index for ltext attributes', (done) ->
      @validator.parse @csv
      .then =>
        langH2i = @validator.header._productTypeLanguageIndexes @productType
        expect(_.size langH2i).toBe 1
        expect(_.size langH2i['foo']).toBe 2
        expect(langH2i['foo']['de']).toBe 2
        expect(langH2i['foo']['en']).toBe 1
        done()
      .catch (err) -> done.fail _.prettify(err)

    it 'should provide access via productType', (done) ->
      @validator.parse @csv
      .then =>
        expected =
          de: 2
          en: 1
        expect(@validator.header.productTypeAttributeToIndex(@productType, @productType.attributes[0])).toEqual expected
        done()
      .catch (err) -> done.fail _.prettify(err)

  describe '#_languageToIndex', ->
    it 'should create mapping for language attributes', (done) ->
      csv =
        """
        foo,a1.de,bar,a1.it
        """
      @validator.parse csv
      .then =>
        langH2i = @validator.header._languageToIndex(['a1'])
        expect(_.size langH2i).toBe 1
        expect(_.size langH2i['a1']).toBe 2
        expect(langH2i['a1']['de']).toBe 1
        expect(langH2i['a1']['it']).toBe 3
        done()
      .catch (err) -> done.fail _.prettify(err)

  describe '#missingHeaderForProductType', ->
    it 'should give list of attributes that are not covered by headers', (done) ->
      csv =
        """
        foo,a1.de,bar,a1.it
        """
      productType =
        id: 'whatAtype'
        attributes: [
          { name: 'foo', type: { name: 'text' } }
          { name: 'bar', type: { name: 'enum' } }
          { name: 'a1', type: { name: 'ltext' } }
          { name: 'a2', type: { name: 'set' } }
        ]
      @validator.parse csv
      .then =>
        header = @validator.header
        header.toIndex()
        header.toLanguageIndex()
        missingHeaders = header.missingHeaderForProductType(productType)
        expect(_.size missingHeaders).toBe 1
        expect(missingHeaders[0]).toEqual { name: 'a2', type: { name: 'set' } }
        done()
      .catch (err) -> done.fail _.prettify(err)
