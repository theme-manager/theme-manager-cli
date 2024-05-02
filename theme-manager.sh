#!/bin/sh

# functions
printUsage() {
    echo "Usage:
    theme-manager.sh [OPTIONS]
Options:
    -c  --create    <name> <imagePath>  Create theme
    -d  --delete    <name>              Delete theme
    -h  --help                          Show this help message
    -l  --list                          List themes
    -s  --set       <name> (apply)      Set theme, optionally apply [1|0]
    -u  --update    <name> <imagePath>  Update theme"
}

# error codes
# 0 - success
# 1 - missing argument(s)
# 2 - wrong argument(s)
# 3 - missing dependecy
# 4 - wrong configuration file
# 5 - internal error

themesPath="$HOME/.config/themes"
generatorPath="$HOME/gitclones/theme-manager/theme-generator"
applierPath="$HOME/gitclones/theme-manager/theme-applier"

if [ "$themesPath" = "" ]; then
    echo "Theme directory not set!"
    exit 4
fi

createDefaultCss() {
    if ! [ -d "$1" ]; then
        echo "Failed to create default css file, which internally uses the themes colors!"
        exit 5
    fi
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

checkIfThemeExists() {
    themeExists=false
    for file in "$themesPath/"*; do
        if [ "$(basename "$file")" = "$1" ]; then
            themeExists=true
        fi
    done
    if $themeExists; then
        echo 0
    else 
        echo 1
    fi
}

printNoThemeFoundError() {
    echo "No theme with name '$1' exists!"
    echo "Use the '--list' option to get all available themes." 
    exit 2
}

createTheme() {
    if ! [ -f "$2" ]; then
        echo "Specified image '$2' does not exist!"
        exit 2
    fi
    if [ "$1" = "active" ]; then
        echo "The name 'active' is reserved!"
        exit 2
    fi

    if [ "$(checkIfThemeExists "$1")" = "0" ]; then
        echo "Theme with name '$1' already exists!"
        echo "Please choose a other name."
        echo "Use the '--list' option to get all available themes."
        exit 2 
    fi

    mkdir -p "$themesPath/$1/colors/"
    "$generatorPath/theme-generator.sh" "$2" -o "$themesPath/$1/colors/" -f pghtr
    success=$?
    if [ "$success" = "0" ]; then
        createDefaultCss "$themesPath/$1/"
        echo "Successfully created theme '$1'"
    fi
}

updateTheme() {
    if [ "$1" = "active" ]; then
        echo "The name 'active' is reserved! It cannot be updated."
        exit 2
    fi
    if ! [ -f "$2" ]; then
        echo "Specified image '$2' does not exist!"
        exit 2
    fi

    if [ "$(checkIfThemeExists "$1")" = "1" ]; then
        printNoThemeFoundError "$1"
    fi

    "$generatorPath/theme-generator.sh" "$2" -o "$themesPath/$1/colors/" -f pghtr
    success=$?
    if [ "$success" = "0" ]; then
        echo "Successfully updated theme '$1'"
    fi
}

deleteTheme() {
    if [ "$1" = "active" ]; then
        echo "The name 'active' is reserved! It cannot be deleted."
        exit 2
    fi

    if [ "$(checkIfThemeExists "$1")" = "1" ]; then
        printNoThemeFoundError "$1"
    fi

    if [ -d "$themesPath/$1/" ]; then
        rm -r "${themesPath:?}/$1/"
    fi

    echo "Successfully deleted theme '$1'"
}

listThemes() {
    for theme in "$themesPath/"*; do
        if [ -d "$theme/" ]; then
            themeName=$(basename "$theme")
            if ! [ "$themeName" = "active" ]; then
                echo "$themeName"
            fi
        fi
    done
}

setTheme() {
    if [ "$1" = "active" ]; then
        echo "The name 'active' is reserved! It cannot be set to."
        exit 2
    fi

    if [ "$(checkIfThemeExists "$1")" = "1" ]; then
        printNoThemeFoundError "$1"
    fi

    if [ -d "$themesPath/active/" ]; then
        mkdir -p "$themesPath/active/"
    fi
    rm -r "$themesPath/active/"
    cp -r "$themesPath/$1/" "$themesPath/active/"

    if [ "$2" = "1" ]; then
        "$applierPath/theme-applier.sh"
    fi
    "$applierPath"/theme-applier.sh
    #killall waybar 
    #waybar &
}

printTooFewArguments() {
    echo "too few arguments for option '$1'"
    echo
    printUsage
    exit 1
}

# check if usage has to be printed
if [ "$1" = "" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printUsage
    exit 0
fi

# check if theme-generator is installed
if ! [ -f "$generatorPath/theme-generator.sh" ]; then
    echo "theme-generator is not installed"
    exit 3
fi

# check if theme-applier is installed
if ! [ -f "$applierPath/theme-applier.sh" ]; then
    echo "theme-applier is not installed"
    exit 3
fi

# execute option
while [ $# -gt 0 ]; do
    case "$1" in
    -h | --help) 
        printUsage && exit0 ;;
    -c | --create)
        { [ "$2" = "" ] || [ "$3" = "" ]; } && printTooFewArguments "$1"
        createTheme "$2" "$3"
        shift 3 ;;
    -u | --update)
        { [ "$2" = "" ] && [ "$3" = "" ]; } && printTooFewArguments "$1"
        updateTheme "$2" "$3" 
        shift 3 ;;
    -d | --delete)
        [ "$2" = "" ] && printTooFewArguments "$1"
        deleteTheme "$2"
        shift 2 ;;
    -l | --list)
        listThemes 
        shift ;;
    -s | --set)
        [ "$2" = "" ] && printTooFewArguments "$1"
        setTheme "$2" 
        shift 2 ;;
    *)
        echo "Unknown option: $1"
        echo
        printUsage
        exit 2 ;;
    esac
done