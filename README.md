# Blackboard Downloader Shell Script
## Description
Tis project is now obsolete. Use a GUI version instead: https://github.com/steveglowplunk/Blackboard-Downloader-GUI  
A Linux Bash script that downloads files from courses on CUHK's Blackboard platform.  
Only works for CUHK's Blackboard platform. Requires some knowledge about Bash scripts to use.  
Tested on Ubuntu 22.04 and Windows WSL2

## What it does
- Batch download all files in a course so that you don't need to manually click on each file to download them
- Alternatively, you can choose to download a single folder or file only

## ...Why?
Why does this project exist?  
CUHK's Blackboard platform does not offer bulk download on course websites for students. This script saves the hassle of having to manually click on each file to download them.

Why Bash?  
I was more familiar with Bash for this kind of task, and this was made with just my own use in mind.

## Setup
1. Login to your CUHK Blackboard account through a broswer, such as Firefox or Chrome

2. Use a browser extension to export a (Netscape format) cookies.txt
	- If you're using Firefox, use this extension:  
	"Export Cookies" by Rotem Dan  
	https://addons.mozilla.org/en-US/firefox/addon/export-cookies-txt/
	
	- If you're using Chrome, use this extension:  
	"Get cookies.txt LOCALLY" by kairi003  
	https://chrome.google.com/webstore/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc

3. Place the cookies txt in the same directory as BlackboardDownloader.sh

4. Copy the exported cookies txt's file name to the $cookiesLocation variable in the script
![Code_2023_03_25_22_33_53](https://user-images.githubusercontent.com/28670916/227725238-22e7bb2c-33fa-4434-8a30-9e8c131ceacc.png)


5. Remember to add execution permission via chmod, for example:
```
chmod +x BlackboardDownloader.sh
```

## Usage
Run the script with the URL of the course's page that has downloadable files on it. For example:
```
./BlackboardDownloader.sh "https://blackboard.cuhk.edu.hk/webapps/blackboard/content/listContent.jsp?course_id=_163790_1&content_id=_3726918_1&mode=reset"
```
where the website looks like this in the browser:
![firefox_2023_03_25_22_01_05](https://user-images.githubusercontent.com/28670916/227725198-66df3763-25dd-4bec-b3f8-ff8dec649c70.png)  
Select an option from the menu:  
![Console_2023_03_25_22_44_06 - Copy](https://user-images.githubusercontent.com/28670916/227726082-d1ddd86d-f38c-4a66-b54b-7f4eeda9aab0.png)

Then find the donwloaded files under the "downloads" folder in the same directory as BlackboardDownloader.sh



## Screenshots
Running on Windows 10 with WSL2  
Menu:
![Console_2023_03_25_22_43_41](https://user-images.githubusercontent.com/28670916/227725295-1875d78c-c443-4625-8ab5-983109566445.png)
Downloading files:  
![Console_2023_03_25_22_44_06](https://user-images.githubusercontent.com/28670916/227725315-04221111-4c93-4ee8-94d1-9bdcf2cb592d.png)
![Console_2023_03_25_22_58_59](https://user-images.githubusercontent.com/28670916/227725326-600a3097-aab3-4aa1-8bf9-4ebee505ca4a.png)



## Known issues
When there are more than one level of subfolders in the course website, the "recursive download" function cannot create the corresponding subfolder names in the local "download" folder.  
If I have the time maybe I'll fix it.
