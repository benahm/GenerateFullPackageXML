# GenerateFullPackageXML

Generate a full Package.xml using the Salesforce CLI new mdapi commands 

* [mdapi:describemetadata](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_force_mdapi.htm)
* [mdapi:listmetadata](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_force_mdapi.htm)



### Requirements 

* [Bash shell](https://fr.wikipedia.org/wiki/Bourne-Again_shell)
* [jq](https://stedolan.github.io/jq/)
* [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli) 


## Usage 

    $ GenerateFullPackageXML.sh <APIVERSION>  <OUTPUTFILE> <ORGALIAS>
  
  
    Example 
 
    $ GenerateFullPackageXML.sh 45.0 ./Package.xml OrgAlias
