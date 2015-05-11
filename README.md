![SPHERE.IO icon](https://admin.sphere.io/assets/images/sphere_logo_rgb_long.png)

# Node.js Product CSV sync

[![NPM](https://nodei.co/npm/sphere-node-product-csv-sync.png?downloads=true)](https://www.npmjs.org/package/sphere-node-product-csv-sync)

[![Build Status](https://travis-ci.org/sphereio/sphere-node-product-csv-sync.png?branch=master)](https://travis-ci.org/sphereio/sphere-node-product-csv-sync) [![NPM version](https://badge.fury.io/js/sphere-node-product-csv-sync.png)](http://badge.fury.io/js/sphere-node-product-csv-sync) [![Coverage Status](https://coveralls.io/repos/sphereio/sphere-node-product-csv-sync/badge.png)](https://coveralls.io/r/sphereio/sphere-node-product-csv-sync) [![Dependency Status](https://david-dm.org/sphereio/sphere-node-product-csv-sync.png?theme=shields.io)](https://david-dm.org/sphereio/sphere-node-product-csv-sync) [![devDependency Status](https://david-dm.org/sphereio/sphere-node-product-csv-sync/dev-status.png?theme=shields.io)](https://david-dm.org/sphereio/sphere-node-product-csv-sync#info=devDependencies)

This component allows you to import, update and export SPHERE.IO Products via CSV.
Further you can change the publish state of products.

# Setup

* install [NodeJS](http://support.sphere.io/knowledgebase/articles/307722-install-nodejs-and-get-a-component-running) (platform for running application)

### From scratch

* install [npm](http://gruntjs.com/getting-started) (NodeJS package manager, bundled with node since version 0.6.3!)
* install [grunt-cli](http://gruntjs.com/getting-started) (automation tool)
*  resolve dependencies using `npm`
```bash
$ npm install
```
* build javascript sources
```bash
$ grunt build
```

### From ZIP

* Just download the ready to use application as [ZIP](https://github.com/sphereio/sphere-node-product-csv-sync/archive/latest.zip)
* Extract the latest.zip with `unzip sphere-node-product-csv-sync-latest.zip`
* Change into the directory `cd sphere-node-product-csv-sync-latest`

## General Usage

This tool uses sub commands for the various task. Please refer to the usage of the concrete action:
- [import](#import)
- [export](#export)
- [template](#template)
- [state](#product-state)

General command line options can be seen by simply executing the command `node lib/run`.
```
./bin/product-csv-sync

  Usage: run [globals] [sub-command] [options]

  Commands:

    import [options]       Import your products from CSV into your SPHERE.IO project.
    state [options]        Allows to publish, unpublish or delete (all) products of your SPHERE.IO project.
    export [options]       Export your products from your SPHERE.IO project to CSV using.
    template [options]     Create a template for a product type of your SPHERE.IO project.

  Options:

    -h, --help                   output usage information
    -V, --version                output the version number
    -p, --projectKey <key>       your SPHERE.IO project-key
    -i, --clientId <id>          your OAuth client id for the SPHERE.IO API
    -s, --clientSecret <secret>  your OAuth client secret for the SPHERE.IO API
    --sphereHost <host>          SPHERE.IO API host to connecto to
    --timeout [millis]           Set timeout for requests
    --verbose                    give more feedback during action
    --debug                      give as many feedback as possible
```

For all sub command specific options please call `./bin/product-csv-sync <sub command> --help`.


## Import

The import command allows to create new products with their variants as well to update existing products and their variants.
During update it is possible to concentrate only on those attributes that should be updated.
This means that the CSV may contain only those columns that contain changed values.

### Usage

```
./bin/product-csv-sync import --help

  Usage: import --projectKey <project-key> --clientId <client-id> --clientSecret <client-secret> --csv <file>

  Options:

    -h, --help                                 output usage information
    -c, --csv <file>                           CSV file containing products to import
    -l, --language [lang]                      Default language to using during import (for slug generation, category linking etc. - default is en)
    --csvDelimiter                             CSV Delimiter that separates the cells (default is comma - ",")
    --multiValueDelimiter                      Delimiter to separate values inside of a cell (default is semicolon - ";")
    --customAttributesForCreationOnly <items>  List of comma-separated attributes to use when creating products (ignore when updating)
    --continueOnProblems                       When a product does not validate on the server side (400er response), ignore it and continue with the next products
    --suppressMissingHeaderWarning             Do not show which headers are missing per produt type.
    --allowRemovalOfVariants                   If given variants will be removed if there is no corresponding row in the CSV. Otherwise they are not touched.
    --ignoreSeoAttributes                      If true all meta* attrbutes are kept untouched.
    --publish                                  When given, all changes will be published immediately
    --updatesOnly                              Won't create any new products, only updates existing
    --dryRun                                   Will list all action that would be triggered, but will not POST them to SPHERE.IO
```

### CSV Format

#### Base attributes

To create or update products you need 2 columns.
You always need the `productType`. Further you need either `variantId` or `sku` to identify the specific variant

You can define the `productType` via id or name (as long as it is unique).

#### Variants

Variants are defined by leaving the `productType` cell empty:
```
productType,name,variantId,myAttribute
typeName,myProduct,1,value
,,2,other value
,,3,val
otherType,nextProduct,1,foo
,,2,bar
```
The CSV above contains:
```
row 0: header
row 1: product with master variant
row 2: 2nd variant of product in row 1
row 3: 3rd variant of product in row 1
row 4: product with master variant
row 5: 2nd variant of product in row 4
```

Non required product attributes
- slug
- metaTitle
- metaDescription
- metaKeywords

> The slug is actually required by SPHERE.IO, but will be generated for the given default language out of the `name` column, when no slug information given.

Non required variant attributes
- sku

#### Localized attributes

The following product attributes can be localized:
- name
- description
- slug
- metaTitle
- metaDescriptions
- metaKeywords

> Further any custom attribute of type `ltext` can be filled with several language values.

Using the command line option `--language`, you can define in which language the values should be imported.

> Using the `--language` option you can define only a single language

Multiple languages can be imported by defining for each language an own column with the following schema:
```
productType,name.en,name.de,description.en,description.de,slug.en,slug.de
myType,my Product,mein Produkt,foo bar,bla bal,my-product,mein-product
```

The pattern for the language header is:
`<attribute name>.<language>`

##### Update of localized attributes

When you want to update a localized attribute, you have to provide all languages of that particular attribute in the CSV file.
Otherwise the language that isn't provided will be removed.

#### Set attributes

If you have an attribute of type `set`, you can define multiple values within the same cell separating them with `;`:
```
productType,...,colors
myType,...,green;red;black
```
The example above will set the value of the `colors` attribute to `[ 'green', 'red', 'black' ]`

#### SameForAll constrainted attributes

To not DRY (don't repeat yourself) when working with attributes that are constrained with `SameForAll`,
you simply have to define the value for all variants on the masterVariant.
```
productType,sku,mySameForAllAttribute
myType,123,thisIsTheValueForAllVariants
,234,
,345,thisDifferentValueWillBeIgnored
```

> Please note, that values for those attributes on the variant rows are completely ignored

#### Tax Category

Just provide the name of the tax category in the `tax` column.

#### Categories

In the `categories` column you can define a list of categories the product should be categorized in separated by `;`:
```
Root>Category>SameSubCategory;Root2;Root>Category2>SameSubCategory
```
This example contains 3 categories defined by their full path. The path segments are thereby separated with `>`
to ensure you can link to leaf categories with same names but different bread crumb.

> You can also just use the category name as long as it is unqiue within the whole category tree. In addtion, the category ID (UUID) can also be used.

#### Prices

In the `prices` column you can define a list of prices for each variant separated by `;`:
```
CH-EUR 999 B2B;EUR 899;USD 19900 #retailerA;DE-EUR 1000 B2C#wareHouse1
```
The pattern for one price is:
`<country>-<currenyCode> <centAmount> <customerGroupName>#<channelKey>`

>For the geeks: Have [a look at the regular expression](https://github.com/sphereio/sphere-node-product-csv-sync/blob/e8329dc6a74a560c57a8ab1842decceb42583c0d/src/coffee/constants.coffee#L33) that parses the prices.

mandatory:
- currenyCode
- centAmount

optional:
- country
- customerGroupName
- channel

#### Numbers

Natural numbers are supported. Negative numbers are prepended with a minus (e.g. `-7`).

> Please note that the there is no space allowed between the minus symbol and the digit

#### Images

In the `images` column you can define a list of urls for each variant separated by `;`:
```
https://example.com/image.jpg;http://www.example.com/picture.bmp
```

> In general we recommend to import images without the protocol like `//example.com/image.png`

#### SEO Attributes

The current implementation allows the set the SEO attributes only if all three SEO attributes are present.
- metaTitle
- metaDescriptions
- metaKeywords


## Product State

This sub command allows you to publish/unpublish or delete as set of (or all) products with a single call.

### Usage

```
./bin/product-csv-sync state --help

  Usage: state --projectKey <project-key> --clientId <client-id> --clientSecret <client-secret> --changeTo <state>

  Options:

    -h, --help                             output usage information
    --changeTo <publish,unpublish,delete>  publish unpublished products / unpublish published products / delete unpublished products
    --csv <file>                           processes products defined in a CSV file by either "sku" or "id". Otherwise all products are processed.
    --continueOnProblems                   When a there is a problem on changing a product's state (400er response), ignore it and continue with the next products
```

#### CSV format

To change the state of only a subset of products you have to provide a list to identify them via a CSV file.

There are currently two ways to identify products:
- id
- sku

An example for sku may look like this:
```
sku
W1234
M2345
M3456
```

> Please note that you always delete products not variants!


## Template

Using this sub command, you can generate a CSV template (does only contain the header row)
for product types. With `--all` a combined template for all product types will be generated.
If you leave this options out, you will be ask for which product type to generate the template.

### Usage

```
./bin/product-csv-sync template --help

  Usage: template --projectKey <project-key> --clientId <client-id> --clientSecret <client-secret> --out <file>

  Options:

    -h, --help                   output usage information
    -o, --out <file>             Path to the file the exporter will write the resulting CSV in
    -l, --languages [lang,lang]  List of languages to use for template (default is [en])
    --all                        Generates one template for all product types - if not given you will be ask which product type to use
```


## Export

The export action dumps products to a CSV file. The CSV file may then later be used as input for the import action.

### CSV Export Template

An export template defines the content of the resulting export CSV file, by listing wanted product attribute names as header row. The header column values will be parsed and the resulting export CSV file will contain corresponding attribute values of the exported products.

```
# only productType.name, the variant id and localized name (english) will be exported
productType,name.en,variantId
```

> Please see section [template]() on how to generate a template.

### Usage

```
./bin/product-csv-sync export --help

  Usage: export --projectKey <project-key> --clientId <client-id> --clientSecret <client-secret> --template <file> --out <file>

  Options:

    -h, --help                 output usage information
    -t, --template <file>      CSV file containing your header that defines what you want to export
    -o, --out <file>           Path to the file the exporter will write the resulting CSV in
    -j, --json <file>          Path to the JSON file the exporter will write the resulting products
    -q, --queryString <query>  Query string to specify the sub-set of products to export
    -l, --language [lang]      Language used on export for category names (default is en)
    --queryType <type>         Whether to do a query or a search request
    --queryEncoded             Whether the given query string is already encoded or not
```

#### Export as JSON

You can export all products as JSON by passing a `--json` flag.

##### Example

```
node lib/run.js export --projectKey <project_key> --clientId <client_id> --clientSecret <client_secret> -j out.json
```

#### Export certain products only

You can define the subset of products to export via the `queryString` parameter, which corresponds of the `where` predicate of the HTTP API.

> Please refer to the [API documentation of SPHERE.IO](http://dev.sphere.io/http-api.html#predicates) for further information regarding the predicates.


##### Example

Query first 10 products of a specific product type
```
limit=10&where=productType(id%3D%2224da8abf-7be6-4b27-9ce6-69ee4b026513%22)
# decoded: limit=0&where=productType(id="24da8abf-7be6-4b27-9ce6-69ee4b026513")
```

## General CSV notes

Please make sure to read the following lines use valid CSV format.

### Multi line text cells
Make sure you enclose multiline cell values properly in quotes

wrong:
```csv
header1,header2,header3
value 1,value 2,this is a
multiline value
```
right:
```csv
header1,header2,header3
value1,value2,"this is a
multiline value"
```

### Text cells with quotes
If your cell value contains a quote, make sure to escape the quote with a two quotes (change `"` to `""`). Also the whole cell value should be enclosed in quotes in this case.

wrong:
```csv
header1,header2,header3
value 1,value 2,this is "value 3"
```

right:
```csv
header1,header2,header3
value 1,value 2,"this is ""value 3"""
```
