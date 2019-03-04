
#!/bin/sh
#
# Generate a full package xml using the Salesforce CLI

# Requirements :
#   * Salesforce CLI
#   * jq


# Mapping metadata type folder for the inFolder=true metadata types
declare -A inFolderMetdataMapping
inFolderMetdataMapping["Report"]="ReportFolder";
inFolderMetdataMapping["Dashboard"]="DashboardFolder"
inFolderMetdataMapping["Document"]="DocumentFolder"
inFolderMetdataMapping["EmailTemplate"]="EmailFolder"


#######################################
# Generate XML for a metadata type name
# Arguments:
#   metadata type name
# Returns:
#   xml
#######################################
function generateNameXML(){
    local name=$1
    echo "<name>${name}</name>"
}

#######################################
# Generate XML for a metadata name
# Arguments:
#   metadata name
# Returns:
#   xml
#######################################
function generateMemberXML(){
    local member=$1
    echo "<members>${member}</members>"
}

#######################################
# Convert JSON list metadata to a list
# Arguments:
#   list metadata names in JSON format
# Returns:
#   list of metadata names
#######################################
function convertListMetadata(){
    local listMetadataJSON=$1

    if [ "${listMetadataJSON}" != "null" ]; then

        isArray=$(echo ${listMetadataJSON} | jq 'if type=="array" then 1 else 0 end')

        if [ "$isArray" == "1" ]; then
            listMetadataNames="$(echo ${listMetadataJSON} | jq -r '.[] | .fullName' | tr -d '\n' | tr '\r' ':')"
        else 
            listMetadataNames="$(echo ${listMetadataJSON} | jq -r '.fullName' | tr -d '\n' | tr '\r' ':')"
        fi

        echo ${listMetadataNames}
    fi

}

#######################################
# List metadata names for a metadata type
# Arguments:
#   api version
#   metadata type name
#   metadata type in folder flag
# Returns:
#   list of metadata names
#######################################
function listMetadataNames(){
    local apiVersion=$1
    local metadataTypeName=$2
    local metadataTypeInFolder=$3

    ## metadata type in folder
    if [ "${metadataTypeInFolder}" == "true" ]; then
        # list folders
        local listMetadataFolderResult=$(echo $(sfdx force:mdapi:listmetadata -a ${apiVersion} -m ${inFolderMetdataMapping[${metadataTypeName}]} --json) | jq '.result')
        local listMetadataFolders=$(convertListMetadata "${listMetadataFolderResult}")
        local listMetadataAllFolderItems=""
        # loop through folders
        IFS=":" read -ra listMetadataFoldersArray <<< "${listMetadataFolders}"
        for folder in ${listMetadataFoldersArray[@]}; do 
            # list folder items
            local listMetadataFolderItemResult=$(echo $(sfdx force:mdapi:listmetadata -a ${apiVersion} -m ${metadataTypeName} --folder ${folder} --json) | jq '.result')
            local listMetadataFolderItems="$(convertListMetadata "${listMetadataFolderItemResult}")"
            if [ "${listMetadataFolderItems}" != "" ]; then
                listMetadataAllFolderItems="${listMetadataAllFolderItems}${listMetadataFolderItems}"
            fi
        done
        local listMetadata="${listMetadataFolders}${listMetadataAllFolderItems}"
        echo "${listMetadata::-1}"
    else 
        local listMetadataResult=$(echo $(sfdx force:mdapi:listmetadata -a ${apiVersion} -m ${metadataTypeName} --json) | jq '.result')
        echo "$(convertListMetadata "${listMetadataResult}")"
    fi
    
}

#######################################
# Generate XML for a metadata type
# Arguments:
#   api version
#   metadata type name
#   metadata type in folder flag
# Returns:
#   xml
#######################################
function generateTypeXML(){
    local apiVersion=$1
    local metadataTypeName=$2
    local metadataTypeInFolder=$3

    local listMetadataNames="$(listMetadataNames ${apiVersion} ${metadataTypeName} ${metadataTypeInFolder})"

    if [ "${listMetadataNames}" != "" ]; then
        echo "  <types>"
        IFS=":"
        for metadataName in ${listMetadataNames}; do 
            echo "      $(generateMemberXML ${metadataName})"
        done
        echo "      $(generateNameXML ${metadataTypeName})"
        echo "  </types>"
    fi

}


#######################################
# Generate Package.xml
# Arguments:
#   api version
# Returns:
#   xml
#######################################
function generatePackageXML(){
    local apiVersion=$1

    local describeMetadata=$(sfdx force:mdapi:describemetadata -a ${apiVersion} --json | jq -r '.result.metadataObjects | .[] | "\(.xmlName) \(.inFolder)"' | tr '\r' ' ')
    
    echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    echo '<Package xmlns="http://soap.sforce.com/2006/04/metadata">'
    IFS=' '
    while read -r metadataType inFolder; do
        local typeXML="$(generateTypeXML ${apiVersion} ${metadataType} ${inFolder})"
        if [ "${typeXML}" != "" ]; then
            echo "${typeXML}"
        fi
    done <<< "$describeMetadata"
    echo "  <version>${apiVersion}</version>"
    echo '</Package>'

}


#######################################
# Main function
# Arguments:
#   api version
#   path to the package xml to output
# Returns:
#   package.xml file
#######################################
main() {
    local apiVersion=${1:-'45.0'}
    local outputFile=${2:-'package.xml'}
    generatePackageXML ${apiVersion} > ${outputFile}
}
 
main "$@"
