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
    -s  --set       <name> (apply)      Set theme, optionally apply wallpaper [1|0]
    -u  --update    <name> <imagePath>  Update theme"
}

# error codes
# 0 - success
# 1 - missing argument(s)
# 2 - wrong argument(s)
# 3 - missing dependecy
# 4 - wrong configuration file
# 5 - internal error

managerPath="$HOME/.config/theme-manager"

if ! [ -d "$managerPath/themes" ]; then
    mkdir -p "$managerPath/themes"
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
    for file in "$managerPath/themes/"*; do
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
    if [ "$1" = "active" ] || [ "$1" = "auto" ]; then
        echo "The name '$1' is reserved!"
        exit 2
    fi

    if [ "$(checkIfThemeExists "$1")" = "0" ]; then
        echo "Theme with name '$1' already exists!"
        echo "Please choose a other name."
        echo "Use the '--list' option to get all available themes."
        exit 2 
    fi

    mkdir -p "$managerPath/themes/$1/colors/"
    "$managerPath/theme-generator.sh" "$2" -o "$managerPath/themes/$1/" -f pghtr
    success=$?
    if [ "$success" = "0" ]; then
        createDefaultCss "$managerPath/themes/$1/"
        echo "Successfully created theme '$1'"
    else 
        rm -r "$managerPath/themes/$1/"
        echo "Failed to create theme '$1'"
    fi
}

updateTheme() {
    if [ "$1" = "active" ] || [ "$1" = "auto" ]; then
        echo "The name '$1' is reserved! It cannot be updated."
        exit 2
    fi
    if ! [ -f "$2" ]; then
        echo "Specified image '$2' does not exist!"
        exit 2
    fi

    if [ "$(checkIfThemeExists "$1")" = "1" ]; then
        printNoThemeFoundError "$1"
    fi

    printf "Are you sure you want to update the theme '%s'? [y/N]: " "$1"
    read -r sure
    case "$sure" in
        [yY][eE][sS]|[yY])  ;;
        *) echo Aborting... && exit 0 ;;
    esac

    "$managerPath/theme-generator.sh" "$2" -o "$managerPath/themes/$1/" -f pghtr
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
    if [ "$1" = "active" ]; then
        echo "The name 'active' is reserved! It cannot be set to."
        exit 2
    fi

    if [ "$(checkIfThemeExists "$1")" = "1" ]; then
        printNoThemeFoundError "$1"
    fi

    if [ -d "$managerPath/thems/active/" ]; then
        mkdir -p "$managerPath/themes/active/"
    fi
    rm -r "$managerPath/themes/active/"
    cp -r "$managerPath/themes/$1/" "$managerPath/themes/active/"

    if [ "$2" = "1" ]; then
        hyprState="$("$managerPath/theme-applier.sh -g hyprpaper")"
        "$managerPath/theme-applier.sh -s hyprpaper off"
        "$managerPath/theme-applier.sh"
        "$managerPath/theme-applier.sh -s hyprpaper $hyprState"
    else 
        "$managerPath"/theme-applier.sh
    fi
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
if ! [ -f "$managerPath/theme-generator.sh" ]; then
    echo "theme-generator is not installed"
    exit 3
fi

# check if theme-applier is installed
if ! [ -f "$managerPath/theme-applier.sh" ]; then
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
        setTheme "$2" "$3"
        shift 2 ;;
    *)
        echo "Unknown option: $1"
        echo
        printUsage
        exit 2 ;;
    esac
done