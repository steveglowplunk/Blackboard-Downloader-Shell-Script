#!/bin/bash

# Do not change these
scriptPath=$(realpath "$0")
scriptPath=$(dirname "$scriptPath")

# MANUALLY change the cookie file name HERE if necessary
cookiesLocation="$scriptPath/cookies-blackboard-cuhk-edu-hk.txt"

# Constants
courseContentPageURL="$1"
domainBase="https://blackboard.cuhk.edu.hk"
courseContentPageName="CourseContents.html"
shortDivider="--------------------"
longDivider="----------------------------------------"

downloadFolder() {
    # download "course content" page, using cookies for login
    local webpageName="$1"
    local webpageURL="$2"
    wget --load-cookies="$cookiesLocation" --no-verbose --show-progress "$webpageURL" -O "$scriptPath/temp/$webpageName"
}

browseWebpage () {
    local webpageName="$scriptPath/temp/$1"
    local bDisplay=$2

    # Extract webpage title, replace "&ndash;" with an en dash character
    webpageTitle=$(grep -oP "(?<=<title>).*(?=</title>)" "$webpageName" | sed 's/&ndash;/–/')

    if $bDisplay; then
        echo
        echo "Listing content of $webpageTitle:"
        echo $longDivider
    fi

    # extract lines with folder URLs and names, except the one surrounded by the <div> tag, which should be Panopto Video
    # folders' URLs must contain "listContent.jsp?course_id="
    folderLines=$(grep "listContent.jsp?course_id=" "$webpageName" | grep -v "<div" | grep -v "&mode=reset")

    # from result of $folderLines, extract pure URLs, except the one that ends with "&mode=reset", which should be the "course content" page's URL
    folderHalfURL=$(echo $folderLines | grep -Eo "/webapps/blackboard/content/listContent.jsp\?course_id=[a-zA-Z0-9./&?=_%:-]*" | grep -v "&mode=reset")
    folderFullURL=""
    folderNames=""

    # files' URLs must contain "bbcswebdav"
    fileLines=$(grep "href=.*bbcswebdav" "$webpageName")
    fileHalfURL=$(echo $fileLines | grep -Eo "/bbcswebdav[a-zA-Z0-9./&?=_%:-]*")
    fileFullURL=""
    fileNames=""

    local IFS=$'\n' # to make for loops separate items based on new line char, instead of space

    # folders part:

    # append "https://blackboard.cuhk.edu.hk" to the beginning of each extracted $folderHalfURL
    for i in $folderHalfURL; do
        folderFullURL=$folderFullURL$domainBase$i$'\n'
    done
    folderFullURL=($folderFullURL) # split the $folderFullURL string into an array by the same name

    # extract pure folder names from $folderLines, which should be surrounded by <span> tags
    for i in $folderLines; do
        folderNames=$folderNames$(echo $i | sed 's/.*<span.*">//' | sed 's/<\/span>.*//')$'\n'
    done
    folderNames=($folderNames) # split the $folderNames string into an array by the same name

    if [ ${#folderFullURL[@]} != ${#folderNames[@]} ]; then
        echo "Number of folder URLs and folder names mismatch. Problems may have occured during string extraction. Exiting."
        exit 1
    fi

    if $bDisplay; then
        if [ ${#folderFullURL[@]} != 0 ]; then
            echo "Folder URLs:"
            for (( i=0; i<${#folderFullURL[@]}; i++ )); do
                echo "$((i+1)): ${folderFullURL[$i]}"
            done
            echo $shortDivider

            echo "Folder names:"
            for (( i=0; i<${#folderNames[@]}; i++ )); do
                echo "$((i+1)): ${folderNames[$i]}"
            done
            echo $shortDivider
        fi
    fi

    # files part:

    # append "https://blackboard.cuhk.edu.hk" to the beginning of each extracted $fileHalfURL
    for i in $fileHalfURL; do
        fileFullURL=$fileFullURL$domainBase$i$'\n'
    done
    fileFullURL=($fileFullURL) # split the $fileFullURL string into an array by the same name

    # extract pure file names, which should be surrounded by "&nbsp;" and "</a>"
    # in case the file hyperlink looks like a folder title, the name should be surrounded by <span> and </a>
    for i in $fileLines; do
        if grep -q "span" <<< "$i"; then
            fileNames=$fileNames$(echo $i | sed 's/.*<span.*">//' | sed 's/<.*\/a>.*//')$'\n'
        else
            fileNames=$fileNames$(echo $i | sed 's/.*&nbsp;//' | sed 's/<\/a>.*//')$'\n'
        fi
    done
    fileNames=($fileNames) # split the $fileNames string into an array by the same name

    if [ ${#fileFullURL[@]} != ${#fileNames[@]} ]; then
        echo "Number of file URLs and file names mismatch. Problems may have occured during string extraction. Exiting."
        exit 1
    fi

    if $bDisplay; then
        if [ ${#fileFullURL[@]} != 0 ]; then
            echo "File URLs:"
            for (( i=0; i<${#fileFullURL[@]}; i++ )); do
                echo "$((i+1)): ${fileFullURL[$i]}"
            done
            echo $shortDivider

            echo "File names:"
            for (( i=0; i<${#fileNames[@]}; i++ )); do
                echo "$((i+1)): ${fileNames[$i]}"
            done
            echo $shortDivider
        fi
    fi
}

downloadAllFiles () {
    local resultDirName="$1"
    for (( i=0; i<${#fileFullURL[@]}; i++ )); do
        downloadNumberedFiles $(($i + 1)) "$resultDirName"
    done
}

downloadNumberedFiles () {
    local option=$(($1-1))
    local resultDir="$scriptPath/downloads/$2/"
    if (( ${#fileFullURL[@]} == 0 )); then
        echo "Invalid option: there is no file on this page"
        menu
    fi
    if (( $1 <= 0 || $1 > ${#fileFullURL[@]} )); then
        echo "Invalid option: file index out of range"
        menu
    fi
    wget --load-cookies="$cookiesLocation" --trust-server-names --no-verbose --show-progress ${fileFullURL[$option]} -P "$resultDir"

    # debug
    # echo "\${fileFullURL[$option]}: ${fileFullURL[$option]}"
    # echo "\$resultDir: $resultDir"
    # echo "\${fileNames[\$option]}: ${fileNames[$option]}"
    
    echo
}

menu () {
    echo
    echo $longDivider

    echo "(A) for downloading all files on this page"
    echo "(Any number) for choosing a file on this page to download, separate multiple numbers by a space"
    echo "(F) for browsing folder"
    echo "(R) for recursive download in all folders"
    echo "(Q) for quitting"
    read -p "Enter option: " option

    re='^[0-9]+$'
    case $option in
        a|A)
            echo $longDivider 
            downloadAllFiles
            echo $longDivider
            echo "Downloaded all files on this page"
            echo "Find downloaded files in $scriptPath/downloads/"
            menu
        ;;
        f|F) 
            read -p "Choose folder, 0 for \"Course Contents\" folder: " folderNumber
            echo $longDivider
            if [ "$folderNumber" = "" ]; then
                echo "Invalid option: empty input"
                menu
            fi
            if [[ $folderNumber =~ (b|B) ]] ||  [[ $folderNumber =~ $re ]]; then # check if $folderNumber is number
                browseFolder $folderNumber
            else
                echo "Invalid option: not a number"
                menu
            fi
        ;;
        r|R)
            echo $longDivider
            recursiveDownload
            echo $longDivider
            echo "Downloaded all files recursively"
            echo "Find downloaded files in $scriptPath/downloads/"
            menu
        ;;
        q|Q)
            echo $longDivider
            echo "Clearing temp folder and quitting."
            rm -r "$scriptPath/temp"
            exit 0
        ;;
        *) # possibly number for downloading individual files
            echo $longDivider
            if [ "$option" = "" ]; then
                echo "Invalid option: empty input"
                menu
            fi
            for i in $option; do
                if [[ $i =~ $re ]]; then # check if $option is number
                    downloadNumberedFiles $i ""
                else
                    echo "Invalid option: not a number"
                    menu
                fi
            done
            echo $longDivider
            echo "Downloaded specified files"
            echo "Find downloaded files in $scriptPath/downloads/"
            menu
        ;;
    esac
}

currentFolderPrefix="folder"
folderLevel=1
browseFolder () {
    if [[ $1 =~ (b|B) ]]; then
        if (( $(($folderLevel - 1)) > 1 )); then
            currentFolderPrefix=$(echo "$currentFolderPrefix" | rev | sed 's/[0-9]*-//' | rev)
            folderLevel=$(($folderLevel-1))
            echo "Browsing "$currentFolderPrefix.html""
            browseWebpage "$currentFolderPrefix.html" true
            menu
        elif (( $(($folderLevel - 1)) == 1 )); then # $(($folderLevel - 1)) will never go below 1
            currentFolderPrefix="folder"
            echo "Browsing "$courseContentPageName""
            browseWebpage "$courseContentPageName" true
            folderLevel=1
            menu
        fi
    fi

    local folderNumber=$(($1-1))
    local currentFolderPostfix="-$folderNumber"
    if (( $1 < 0 || $1 > ${#folderFullURL[@]} )); then
        echo "Invalid option: folder index out of range"
        menu
    fi
    if [[ $folderNumber = -1 ]]; then
        currentFolderPrefix="folder"
        echo "Browsing "$courseContentPageName""
        browseWebpage "$courseContentPageName" true
        folderLevel=1
    else
        currentFolderPrefix=$currentFolderPrefix$currentFolderPostfix
        echo "Browsing "$currentFolderPrefix.html""
        browseWebpage "$currentFolderPrefix.html" true
        folderLevel=$(($folderLevel+1))
    fi
    menu
}

recursiveDownload () {
    browseWebpage "$courseContentPageName" false
    downloadAllFiles "Root Folder"
    local rootFolderFullURL=("${folderFullURL[@]}")
    local rootFolderNames=("${folderNames[@]}")
    local j
    for (( j=0; j<${#rootFolderFullURL[@]}; j++ )); do
        inner_downloadPath="${rootFolderNames[$j]}/"
        recursiveFolder $j "-$j" true "${rootFolderFullURL[@]}"
    done
}

inner_downloadPath="" # download path for function's use
recursiveFolder () {
    local folderNum=$1 # which folder to browse under the current folder webpage
    local folderPostfix=$2 # append to folder webpage's filename to specify which webpage to browse
    local bDownloadFiles=$3 # true to download files, false to download folder webpage
    shift 3;
    local outer_folderFullURL=("$@") # folderFullURL array passed from the function caller

        # "download folder" mode
        if ! $bDownloadFiles; then
            downloadFolder "folder$folderPostfix.html" "${outer_folderFullURL[$folderNum]}"
        fi
        browseWebpage "folder$folderPostfix.html" false # browse folder webpage to update various global variables

        # "download files" mode
        if $bDownloadFiles; then
            old_inner_downloadPath="$inner_downloadPath" # store current $inner_downloadPath before appending folder name to $inner_downloadPath,
                                                         # for moving $inner_downloadPath up one folder level later after finishing downloading files
            if (( ${#fileFullURL[@]} != 0 )); then # append folder name to $inner_downloadPath only if there are files under current folder webpage
                inner_downloadPath="$inner_downloadPath${outer_folderNames[$folderNum]}/"
                downloadAllFiles "$inner_downloadPath" # download all files in current webpage to $inner_downloadPath
            fi

            if (( ${#folderFullURL[@]} != 0 )); then # if there are more folders under current folder, do not move $inner_downloadPath up one folder level
                old_inner_downloadPath="$inner_downloadPath"
            else # otherwise move $inner_downloadPath up one folder level to prepare switching to another folder
                inner_downloadPath="$old_inner_downloadPath"
            fi
        fi

        local temp_folderFullURL=("${folderFullURL[@]}") # copy $folderFullURL array to prevent next call of recursiveFolder() intefering the number of folders
        if (( ${#temp_folderFullURL[@]} != 0 )); then # if there are more folders under current folder, then recursively browse those folders under current folder webpage
            local k
            for (( k=0; k<${#temp_folderFullURL[@]}; k++ )); do
                if $bDownloadFiles; then
                    # "download files" mode
                    recursiveFolder  $k "$folderPostfix-$k" true "${temp_folderFullURL[@]}"
                else
                    # "download folder" mode
                    recursiveFolder  $k "$folderPostfix-$k" false "${temp_folderFullURL[@]}"
                fi
            done
        fi
}

# main programme starts
if [ ! -d "$scriptPath/temp" ]; then
    mkdir -p "$scriptPath/temp"
fi

echo "Downloading all subfolders' webpages into temp folder"
echo $longDivider

downloadFolder "$courseContentPageName" "$courseContentPageURL"
browseWebpage "$courseContentPageName" false

rootFolderFullURL=("${folderFullURL[@]}")
rootFolderNames=("${folderNames[@]}")

for (( j=0; j<${#rootFolderFullURL[@]}; j++ )); do
    recursiveFolder  $j "-$j" false "${rootFolderFullURL[@]}"
done

browseWebpage "$courseContentPageName" true

menu
