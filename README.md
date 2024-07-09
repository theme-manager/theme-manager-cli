# theme-manager
The theme-manager is the frontend for the theme-generator. It is used to create, update and delete themes.  
With the theme-manager the active theme can be set.  
If connected to the change event of the wallpaper, the theme will be changed automatically. 

## Installation
The installation is easy. Just put the shell script in your ```$HOME/.config/theme-manager``` directory.  
Make sure that dependencies are installed.  

To use the theme-manager you will first have to install the theme-generator.  
Download the shell script and put it in your ```$HOME/.config/theme-manager``` directory.  
Do the same for the theme-applier.  
A QOL-Thing would be to add the line `alias TM='$HOME/.config/theme-manager/theme-manager.sh'` into your .bashrc file.  
Then you can just use it when writing TM in the terminal.  

## Usage
    theme-manager <OPTION> ...

    Options:
        -c  --create    <name> <imagePath>  Create theme
        -d  --delete    <name>              Delete theme
        -l  --list                          List themes
        -s  --set       <name> (<apply>)    Set theme, optionally apply wallpaper [1]
        -u  --update    <name> <imagePath>  Update theme

## Dependencies
theme-generator: [https://github.com/theme-manager/theme-generator](https://github.com/theme-manager/theme-generator)  
theme-applier: [https://github.com/theme-manager/theme-applier](https://github.com/theme-manager/theme-applier)
