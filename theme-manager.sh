#!/bin/sh

# functions
printUsage() {
    echo "Usage:
    theme-manager <OPTION> ...
Options:
    -c  --create    <name> <imagePath>  Create theme
    -d  --delete    <name>              Delete theme
    -h  --help                          Show this help message
    -l  --list                          List themes
    -s  --set       <name> (<apply>)    Set theme, optionally apply wallpaper [1]
    -u  --update    <name> <imagePath>  Update theme"
}

# error codes
# 0 - success
# 1 - missing argument(s)
# 2 - wrong argument(s)
# 3 - missing dependecy
# 4 - wrong configuration file
# 5 - internal error

# Prints an given error message and returns with the given exit code
# $1 - exit code
# $2 - error message
printErr() {
    echo "Error: $2" >&2
    echo "Use -h or --help to display help" >&2
    exit "$1"
}

printNoThemeFoundError() {
    printErr 3 "No theme with name '$1' exists!
Use the '--list' option to get all available themes." 
}

printTooFewArgumentsError() {
    echo "too few arguments for option '$1'" >&2
    echo >&2
    printUsage >&2
    exit 1
}

# Prints an given warning message and returns with the given exit code
# $1 - warning message
# [$2 - exit code]
printWarning() {
    echo "$1" >&3
    [ -n "$2" ] && exit "$2"
}

managerPath="$HOME/.config/theme-manager"
[ -d "$managerPath/themes" ] || mkdir -p "$managerPath/themes"

createDefaultCss() {
    [ -d "$1" ] || printErr 5 "Failed to create default css file, which internally uses the themes colors!"

    echo "Creating default css..."
    {   echo "@import './colors/colors-gtk.css';"
        echo ""
        echo "@define-color backgroundColor @color0;"
        echo "@define-color detailColor @color1;"
        echo "@define-color hoverColor @color2;"
        echo "@define-color borderColor @color3;"
        echo "@define-color textColor @color4;"
        echo "@define-color transparent rgba(0, 0, 0, 0);"
    } > "$1/colors.css"
}

# Checks if a theme exists or not. Returns 0 if it does, 1 if it doesn't
checkIfThemeExists() {
    themeExists=false
    for file in "$managerPath/themes/"*; do
        if [ "$(basename "$file")" = "$1" ]; then
            themeExists=true
        fi
    done
    return $themeExists
}

createTheme() {
    [ -r "$2" ] || printErr 1 "Specified image '$2' does not exist or is not readable!"
    if [ "$1" = "active" ] || [ "$1" = "auto" ]; then
        printErr 2 "The name '$1' is reserved!"
    fi

    if checkIfThemeExists "$1"; then
        printErr 3 "Theme with name '$1' already exists!
Please choose a other name.
Use the '--list' option to get all available themes."
    fi

    mkdir -p "$managerPath/themes/$1/colors/"
    "$managerPath/theme-generator" "$2" -o "$managerPath/themes/$1/" -f pghtr
    success=$?
    if [ "$success" = "0" ]; then
        createDefaultCss "$managerPath/themes/$1/"
        echo "Successfully created theme '$1'"
    else 
        rm -r "$managerPath/themes/$1/"
        printWarning "Failed to create theme '$1'"
    fi
}

updateTheme() {
    [ -r "$2" ] || printErr 1 "Specified image '$2' does not exist or is not readable!"
    if [ "$1" = "active" ] || [ "$1" = "auto" ]; then
        printErr 2 "The name '$1' is reserved! It cannot be updated."
    fi
    checkIfThemeExists "$1" || printNoThemeFoundError "$1"

    printf "Are you sure you want to update the theme '%s'? [y/N]: " "$1"
    read -r sure
    case "$sure" in
        [yY][eE][sS]|[yY])  ;;
        *) printWarning "Aborting..." 0 ;;
    esac

    "$managerPath/theme-generator" "$2" -o "$managerPath/themes/$1/" -f pghtr
    success=$?
    if [ "$success" = "0" ]; then
        echo "Successfully updated theme '$1'"
    fi
}

deleteTheme() {
    [ "$1" = "active" ] && printErr 2 "The name 'active' is reserved! It cannot be deleted."
    checkIfThemeExists "$1" || printNoThemeFoundError "$1"

    if [ -d "$managerPath/themes/$1/" ]; then
        rm -r "${managerPath:?}/themes/$1/"
    fi

    echo "Successfully deleted theme '$1'"
}

listThemes() {
    for theme in "$managerPath/themes/"*; do
        if [ -d "$theme/" ]; then
            themeName=$(basename "$theme")
            if ! [ "$themeName" = "active" ] && ! [ "$themeName" = "auto" ]; then
                echo " - $themeName"
            fi
        fi
    done
}

setTheme() {
    [ "$1" = "active" ] && printErr 2 "The name 'active' is reserved! It cannot be set to."
    checkIfThemeExists "$1" || printNoThemeFoundError "$1"

    if [ -d "$managerPath/thems/active/" ]; then
        mkdir -p "$managerPath/themes/active/"
    fi
    rm -r "$managerPath/themes/active/"
    cp -r "$managerPath/themes/$1/" "$managerPath/themes/active/"

    if [ "$2" = "1" ]; then
        echo applying wallpaper...
        "$managerPath/theme-applier"
    else 
        echo not applying wallpaper...
        hyprState="$("$managerPath/theme-applier" -g hyprpaper)"
        "$managerPath/theme-applier" -s hyprpaper off
        "$managerPath/theme-applier"
        "$managerPath/theme-applier" -s hyprpaper "$hyprState"
    fi
}

# check if usage has to be printed
if [ "$1" = "" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printUsage
    exit 0
fi

# check if theme-generator is installed
[ -f "$managerPath/theme-generator" ] || printErr 4 "theme-generator is not installed!"
[ -x "$managerPath/theme-generator" ] || printErr 4 "theme-generator is not marked as executable!"

# check if theme-applier is installed
[ -f "$managerPath/theme-applier" ] || printErr 4 "theme-applier is not installed!"
[ -x "$managerPath/theme-applier" ] || printErr 4 "theme-applier is not marked as executable!"

# execute option
while [ $# -gt 0 ]; do
    case "$1" in
    -h | --help) 
        printUsage && exit0 ;;
    -c | --create)
        [ $# -lt 3 ] && printTooFewArgumentsError "$1"
        createTheme "$2" "$3"
        shift 3 ;;
    -u | --update)
        [ $# -lt 3 ] && printTooFewArgumentsError "$1"
        updateTheme "$2" "$3" 
        shift 3 ;;
    -d | --delete)
        [ $# -lt 2 ] && printTooFewArgumentsError "$1"
        deleteTheme "$2"
        shift 2 ;;
    -l | --list)
        listThemes 
        shift ;;
    -s | --set)
        [ $# -lt 2 ] && printTooFewArgumentsError "$1"
        if [ "$3" != "" ]; then
            setTheme "$2" "$3"
            shift
        else
            setTheme "$2"
        fi
        shift 2 ;;
    *) printErr 2 "Unknown option: '$1'" ;;
    esac
done