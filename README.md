# theme-manager
The theme-manager is the frontend for the theme-generator. It is used to create, update and delete themes.  
With the theme-manager the active theme can be set.  
If connected to the change event of the wallpaper, the theme will be changed automatically. 

## Usage
    theme-manager.sh [OPTIONS]

    Options:
        -c  --create    <name> <imagePath>  Create theme
        -d  --delete    <name>              Delete theme
        -l  --list                          List themes
        -s  --set       <name>              Set theme
        -u  --update    <name> <imagePath>  Update theme

## Installation
To use the theme-manager you will first have to install the theme-generator.  
Download the shell script and put it in your ```$HOME/.config/theme-manager``` directory.  
Do the same for the theme-generator.  

## Dependencies
theme-generator: [https://github.com/zweiler1/theme-generator](https://github.com/zweiler1/theme-generator)
