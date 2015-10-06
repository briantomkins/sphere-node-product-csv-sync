_ = require 'underscore'
_.mixin require('underscore.string').exports()
Promise = require 'bluebird'
Csv = require 'csv'
{SphereClient} = require 'sphere-node-sdk'
CONS = require './constants'
GLOBALS = require './globals'
Mapping = require './mapping'
Header = require './header'

class Validator

  constructor: (options = {}) ->
    @types = options.types
    @customerGroups = options.customerGroups
    @categories = options.categories
    @taxes = options.taxes
    @channels = options.channels

    options.validator = @
    @map = new Mapping options
    # TODO:
    # - pass only correct options, not all classes
    # - avoid creating a new instance of the client, since it should be created from Import class
    @client = new SphereClient options if options.config
    @rawProducts = []
    @errors = []
    @suppressMissingHeaderWarning = false
    @csvOptions =
      delimiter: options.csvDelimiter or ','
      quote: options.csvQuote or '"'

  parse: (csvString) ->
    # TODO: use parser with streaming API
    # https://github.com/sphereio/sphere-node-product-csv-sync/issues/56
    new Promise (resolve, reject) =>
      Csv().from.string(csvString, @csvOptions)
      .on 'error', (error) -> reject error
      .to.array (data, count) =>
        @header = new Header(data[0])
        @map.header = @header
        resolve
          data: _.rest(data)
          count: count

  validate: (csvContent) ->
    @validateOffline csvContent
    @validateOnline()

  validateOffline: (csvContent) ->
    @header.validate()
    @checkDelimiters()

    variantHeader = CONS.HEADER_VARIANT_ID if @header.has(CONS.HEADER_VARIANT_ID)
    if @header.has(CONS.HEADER_SKU) and not variantHeader?
      variantHeader = CONS.HEADER_SKU
      @updateVariantsOnly = true
    @buildProducts csvContent, variantHeader

  checkDelimiters: ->
    allDelimiter =
      csvDelimiter: @csvOptions.delimiter
      csvQuote: @csvOptions.quote
      language: GLOBALS.DELIM_HEADER_LANGUAGE
      multiValue: GLOBALS.DELIM_MULTI_VALUE
      categoryChildren: GLOBALS.DELIM_CATEGORY_CHILD
    delims = _.map allDelimiter, (delim, _) -> delim
    if _.size(delims) isnt _.size(_.uniq(delims))
      @errors.push "Your selected delimiter clash with each other: #{JSON.stringify(allDelimiter)}"

  validateOnline: ->
    # TODO: too much parallel?
    # TODO: is it ok storing everything in memory?
    Promise.all([
      @types.getAll @client
      @customerGroups.getAll @client
      @categories.getAll @client
      @taxes.getAll @client
      @channels.getAll @client
    ])
    .then ([productTypes, customerGroups, categories, taxes, channels]) =>
      @productTypes = productTypes.body.results
      @types.buildMaps @productTypes
      @customerGroups.buildMaps customerGroups.body.results
      @categories.buildMaps categories.body.results
      @taxes.buildMaps taxes.body.results
      @channels.buildMaps channels.body.results

      @valProducts @rawProducts # TODO: ???
      if _.size(@errors) is 0
        @valProductTypes @productTypes # TODO: ???
        if _.size(@errors) is 0
          Promise.resolve @rawProducts
        else
          Promise.reject @errors
      else
        Promise.reject @errors


  # TODO: Allow to define a column that defines the variant relationship.
  # If the value is the same, they belong to the same product
  buildProducts: (content, variantColumn) ->
    if @updateVariantsOnly
      @productType2variantContainer = {}
    _.each content, (row, index) =>
      rowIndex = index + 2 # Excel et all start counting at 1 and we already popped the header
      if @updateVariantsOnly
        # we build one product per product type
        productType = row[@header.toIndex CONS.HEADER_PRODUCT_TYPE]
        if productType
          unless _.has @productType2variantContainer, productType
            @productType2variantContainer[productType] =
              master: _.deepClone row
              startRow: rowIndex
              variants: []
            @rawProducts.push @productType2variantContainer[productType]
          @productType2variantContainer[productType].variants.push
            variant: row
            rowIndex: rowIndex
        else
          @errors.push "[row #{rowIndex}] Please provide a product type!"
      else
        # we build the product on the fly when we identify a new one
        if @isProduct row, variantColumn
          product =
            master: row
            startRow: rowIndex
            variants: []
          @rawProducts.push product
        else if @isVariant row, variantColumn
          product = _.last @rawProducts
          if product
            product.variants.push
              variant: row
              rowIndex: rowIndex
          else
            @errors.push "[row #{rowIndex}] We need a product before starting with a variant!"
        else
          @errors.push "[row #{rowIndex}] Could not be identified as product or variant!"

  valProductTypes: (productTypes) ->
    return if @suppressMissingHeaderWarning
    _.each productTypes, (pt) =>
      attributes = @header.missingHeaderForProductType pt
      unless _.isEmpty(attributes)
        console.warn "For the product type '#{pt.name}' the following attributes don't have a matching header:"
        _.each attributes, (attr) ->
          console.warn "  #{attr.name}: type '#{attr.type.name} #{if attr.type.name is 'set' then 'of ' + attr.type.elementType.name  else ''}' - constraint '#{attr.attributeConstraint}' - #{if attr.isRequired then 'isRequired' else 'optional'}"

  valProducts: (products) ->
    _.each products, (product) => @valProduct product

  valProduct: (raw) ->
    rawMaster = raw.master
    ptInfo = rawMaster[@header.toIndex CONS.HEADER_PRODUCT_TYPE]

    @errors.push "[row #{raw.startRow}] The product type name '#{ptInfo}' is not unique. Please use the ID!" if _.contains(@types.duplicateNames, ptInfo)

    if _.has(@types.name2id, ptInfo)
      ptInfo = @types.name2id[ptInfo]
    if _.has(@types.id2index, ptInfo)
      index = @types.id2index[ptInfo]
      rawMaster[@header.toIndex CONS.HEADER_PRODUCT_TYPE] = @productTypes[index]
    else
      @errors.push "[row #{raw.startRow}] Can't find product type for '#{ptInfo}'"

  isVariant: (row, variantColumn) ->
    if variantColumn is CONS.HEADER_VARIANT_ID
      variantId = row[@header.toIndex(CONS.HEADER_VARIANT_ID)]
      parseInt(variantId) > 1
    else
      not @isProduct row

  isProduct: (row, variantColumn) ->
    hasProductTypeColumn = not _.isBlank(row[@header.toIndex(CONS.HEADER_PRODUCT_TYPE)])
    if variantColumn is CONS.HEADER_VARIANT_ID
      hasProductTypeColumn and row[@header.toIndex(CONS.HEADER_VARIANT_ID)] is '1'
    else
      hasProductTypeColumn

  _hasVariantCriteria: (row, variantColumn) ->
    critertia = row[@header.toIndex(variantColumn)]
    critertia?

module.exports = Validator
