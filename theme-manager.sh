#!/bin/sh

# functions
printUsage() {
    echo "Usage:"
    echo "  theme-manager.sh [OPTIONS]"
    echo
    echo "Options:"
    echo "  -c  --create    <name> <imagePath>  Create theme"
    echo "  -d  --delete    <name>              Delete theme"
    echo "  -h  --help                          Show this help message"
    echo "  -l  --list                          List themes"
    echo "  -s  --set       <name>              Set theme"
    echo "  -u  --update    <name> <imagePath>  Update theme"
    #echo "  -p  --path      <path>              Theme directory. Default directory is $HOME/.config/themes/"
}

checkIfThemeExists() {
    themeExists=false
    for file in "$HOME/.config/themes/"*; do
        if [ "$(basename "$file")" = "$1" ]; then
            themeExists=true
        fi
    done
    if ! $themeExists; then
        echo "No theme with name '$1' exists, so it cannot be updated!"
        echo "Use the '--list' option to get all available themes." 
        exit 2
    fi
    return $themeExists
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

    mkdir -p "$HOME/.config/themes/$2/"
    sh "$HOME/.config/theme-generator/theme-generator.sh" "$2" -f pgh -o "$HOME/.config/themes/$1/"
}

updateTheme() {
    if ! [ -f "$2" ]; then
        echo "Specified image '$2' does not exist!"
        exit 2
    fi
    checkIfThemeExists "$1"

    sh "$HOME/.config/theme-generator/theme-generator.sh" "$2" -f pgh -o "$HOME/.config/themes/$1/"
}

deleteTheme() {
    if [ "$1" = "active" ]; then
        echo "The name 'active' is reserved! It cannot be deleted."
        exit 2
    fi

    checkIfThemeExists "$1"

    if [ -d "$HOME/.config/themes/$1/" ]; then
        rm -r "$HOME/.config/themes/$1/"
    fi
}

listThemes() {
    for theme in "$HOME/.config/themes/"*; do
        if ! [ "$theme" = "active" ]; then
            echo "$theme"
        fi
    done
}

setTheme() {
    if [ "$1" = "active" ]; then
        echo "The name 'active' is reserved! It cannot be deleted."
        exit 2
    fi

    checkIfThemeExists "$1"

    if [ -d "$HOME/.config/themes/active/" ]; then
        mkdir -p "$HOME/.config/themes/active/"
    fi
    rm -r "$HOME/.config/themes/active/"
    cp -r "$HOME/.config/themes/$1/" "$HOME/.config/themes/active/"
}

# check if usage has to be printed
if [ "$1" = "" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printUsage
    exit 0
fi

# check if theme-generator is installed
if ! [ -f "$HOME/.config/theme-generator/theme-generator.sh" ]; then
    echo "theme-generator is not installed!"
    exit 1
fi

# execute option
case "$1" in
-c | --create)
    if [ "$2" = "" ] || [ "$3" = "" ]; then
        echo too few arguments for option "$1"!
        echo
        printUsage
        exit 1
    fi
    createTheme "$2" "$3" ;;
-u | --update)
    if [ "$2" = "" ] || [ "$3" = "" ]; then
        echo too few arguments for option "$1"!
        echo
        printUsage
        exit 1
    fi
    updateTheme "$2" "$3" ;;
-d | --delete)
    if [ "$2" = "" ]; then
        echo "missing <name> argument for option $1"!
        echo
        printUsage
        exit 1
    fi
    deleteTheme "$2" ;;
-l | --list)
    listThemes ;;
-s | --set)
    if [ "$2" = "" ]; then
        echo "missing <name> argument for option $1"!
        echo
        printUsage
        exit 1
    fi
    setTheme "$2" ;;
*)
    echo "Unknown option: $1"
    echo
    printUsage
    exit 1 ;;
esac
