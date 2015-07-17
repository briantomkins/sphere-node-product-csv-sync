Feature: Publish and unpublish products

  Scenario: Import publish, unplublish and remove a product
    When I run `../../bin/product-csv-sync state --projectKey nicola --changeTo delete` interactively
    And I type "yes"

    Given a file named "i.csv" with:
    """
    productType,variantId,name,sku
    ImpEx with all types,1,myPublishedProduct,123456789
    """
    When I run `../../bin/product-csv-sync import --projectKey nicola --csv i.csv`
    Then the exit status should be 0
    And the output should contain:
    """
    [ '[row 2] New product created.' ]
    """

    When I run `../../bin/product-csv-sync state --projectKey nicola --changeTo publish`
    Then the exit status should be 0
    And the output should contain:
    """
    [ '[row 0] Product published.' ]
    """

    When I run `../../bin/product-csv-sync state --projectKey nicola --changeTo unpublish`
    Then the exit status should be 0
    And the output should contain:
    """
    [ '[row 0] Product unpublished.' ]
    """

    When I run `../../bin/product-csv-sync state --projectKey nicola --changeTo delete` interactively
    And I type "yes"
    Then the exit status should be 0
    And the output should contain:
    """
    [ '[row 0] Product deleted.' ]
    """
