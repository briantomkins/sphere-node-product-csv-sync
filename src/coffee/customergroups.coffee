_ = require('underscore')._
Q = require 'q'


class CustomerGroups
  constructor: ->
    @name2id = {}

  getAllCustomerGroups: (rest) ->
    deferred = Q.defer()
    rest.GET "/customer-groups?limit=0", (error, response, body) ->
      if error
        deferred.reject 'Error on getting customer groups: ' + error
      else if response.statusCode is 200
        customerGroups = JSON.parse(body).results
        deferred.resolve customerGroups
      else if response.statusCode is 400
        parsed = JSON.parse body
        humanReadable = JSON.stringify parsed, null, '  '
        deferred.resolve "Problem on getting customer groups:\n" + humanReadable
      else
        deferred.reject "Problem on getting customer groups:\n" +
        "status #{response.statusCode})\n" +
        "body " + response.body
    deferred.promise

  buildMaps: (customerGroups) ->
    for group in customerGroups
      name = group.name
      id = group.id
      @name2id[name] = id


module.exports = CustomerGroups
