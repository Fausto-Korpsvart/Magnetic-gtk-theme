#! /usr/bin/env bash

set -Eeo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
SRC_DIR="${REPO_DIR}/src"

source "${REPO_DIR}/gtkrc.sh"

ROOT_UID=0
DEST_DIR=

scheme=

# Destination directory
if [[ "$UID" -eq "$ROOT_UID" ]]; then
  DEST_DIR="/usr/share/themes"
elif [[ -n "$XDG_DATA_HOME" ]]; then
  DEST_DIR="$XDG_DATA_HOME/themes"
elif [[ -d "$HOME/.themes" ]]; then
  DEST_DIR="$HOME/.themes"
elif [[ -d "$HOME/.local/share/themes" ]]; then
  DEST_DIR="$HOME/.local/share/themes"
else
  DEST_DIR="$HOME/.themes"
fi

SASSC_OPT="-M -t expanded"

THEME_NAME=Magnetic
THEME_VARIANTS=('' '-Purple' '-Pink' '-Red' '-Orange' '-Yellow' '-Green' '-Teal' '-Grey')
COLOR_VARIANTS=('' '-Light' '-Dark')
SCHEME_VARIANTS=('' '-Nord' '-Dracula' '-Gruvbox')
SIZE_VARIANTS=('' '-Compact')

if [[ "$(command -v gnome-shell)" ]]; then
  gnome-shell --version
  SHELL_VERSION="$(gnome-shell --version | cut -d ' ' -f 3 | cut -d . -f -1)"
  if [[ "${SHELL_VERSION:-}" -ge "48" ]]; then
    GS_VERSION="48-0"
  elif [[ "${SHELL_VERSION:-}" -ge "47" ]]; then
    GS_VERSION="47-0"
  elif [[ "${SHELL_VERSION:-}" -ge "46" ]]; then
    GS_VERSION="46-0"
  elif [[ "${SHELL_VERSION:-}" -ge "44" ]]; then
    GS_VERSION="44-0"
  elif [[ "${SHELL_VERSION:-}" -ge "42" ]]; then
    GS_VERSION="42-0"
  elif [[ "${SHELL_VERSION:-}" -ge "40" ]]; then
    GS_VERSION="40-0"
  else
    GS_VERSION="3-28"
  fi
else
  echo "'gnome-shell' not found, using styles for last gnome-shell version available."
  GS_VERSION="48-0"
fi

usage() {
cat << EOF
Usage: $0 [OPTION]...

OPTIONS:
  -d, --dest DIR          Specify destination directory (Default: $DEST_DIR)

  -n, --name NAME         Specify theme name (Default: $THEME_NAME)

  -t, --theme VARIANT     Specify theme color variant(s) [default|purple|pink|red|orange|yellow|green|teal|grey|all] (Default: blue)

  -c, --color VARIANT     Specify color variant(s) [standard|light|dark] (Default: All variants))

  -s, --size VARIANT      Specify size variant [standard|compact] (Default: standard variant)

  -l, --libadwaita        Link installed gtk-4.0 theme to config folder for all libadwaita app use this theme

  -r, --remove,
  -u, --uninstall         Uninstall/Remove installed themes or links

  --tweaks                Specify versions for tweaks
                          1. [nord|dracula|gruvbox|all]   (Nord/Dracula/gruvbox/all) ColorSchemes version
                          2. black                        Blackness color version
                          3. float                        Floating gnome-shell panel style
                          4. outline                      Windows with 2px outline style
                          5. normal                       Normal sidebar style

  -h, --help              Show help
EOF
}

install() {
  local dest="${1}"
  local name="${2}"
  local theme="${3}"
  local color="${4}"
  local size="${5}"
  local scheme="${6}"

  [[ "${color}" == '-Light' ]] && local ELSE_LIGHT="${color}"
  [[ "${color}" == '-Dark' ]] && local ELSE_DARK="${color}"

  local THEME_DIR="${1}/${2}${3}${4}${5}${6}"

  [[ -d "${THEME_DIR}" ]] && rm -rf "${THEME_DIR}"

  echo "Installing '${THEME_DIR}'..."

  theme_tweaks

  mkdir -p                                                                                   "${THEME_DIR}"

  echo "[Desktop Entry]" >>                                                                  "${THEME_DIR}/index.theme"
  echo "Type=X-GNOME-Metatheme" >>                                                           "${THEME_DIR}/index.theme"
  echo "Name=${2}${3}${4}${5}${6}" >>                                                        "${THEME_DIR}/index.theme"
  echo "Comment=An Flat Gtk+ theme based on Elegant Design" >>                               "${THEME_DIR}/index.theme"
  echo "Encoding=UTF-8" >>                                                                   "${THEME_DIR}/index.theme"
  echo "" >>                                                                                 "${THEME_DIR}/index.theme"
  echo "[X-GNOME-Metatheme]" >>                                                              "${THEME_DIR}/index.theme"
  echo "GtkTheme=${2}${3}${4}${5}${6}" >>                                                    "${THEME_DIR}/index.theme"
  echo "MetacityTheme=${2}${3}${4}${5}${6}" >>                                               "${THEME_DIR}/index.theme"
  echo "IconTheme=Tela-circle${ELSE_DARK:-}" >>                                              "${THEME_DIR}/index.theme"
  echo "CursorTheme=${2}-cursors" >>                                                         "${THEME_DIR}/index.theme"
  echo "ButtonLayout=close,minimize,maximize:menu" >>                                        "${THEME_DIR}/index.theme"

  mkdir -p                                                                                   "${THEME_DIR}/gnome-shell"
  cp -r "${SRC_DIR}/main/gnome-shell/pad-osd.css"                                            "${THEME_DIR}/gnome-shell"
  sassc $SASSC_OPT "${SRC_DIR}/main/gnome-shell/gnome-shell${color}.scss"                    "${THEME_DIR}/gnome-shell/gnome-shell.css"

  cp -r "${SRC_DIR}/assets/gnome-shell/common-assets"                                        "${THEME_DIR}/gnome-shell/assets"
  cp -r "${SRC_DIR}/assets/gnome-shell/assets${ELSE_DARK:-}/"*.svg                           "${THEME_DIR}/gnome-shell/assets"
  cp -r "${SRC_DIR}/assets/gnome-shell/theme${theme}${scheme}/"*.svg                         "${THEME_DIR}/gnome-shell/assets"

  cd "${THEME_DIR}/gnome-shell"
  ln -s assets/no-events.svg no-events.svg
  ln -s assets/process-working.svg process-working.svg
  ln -s assets/no-notifications.svg no-notifications.svg

  mkdir -p                                                                                   "${THEME_DIR}/gtk-2.0"
  # cp -r "${SRC_DIR}/main/gtk-2.0/gtkrc${theme}${ELSE_DARK:-}${scheme}"                        "${THEME_DIR}/gtk-2.0/gtkrc"
  cp -r "${SRC_DIR}/main/gtk-2.0/common/"*'.rc'                                              "${THEME_DIR}/gtk-2.0"
  cp -r "${SRC_DIR}/assets/gtk-2.0/assets-common${ELSE_DARK:-}"                              "${THEME_DIR}/gtk-2.0/assets"
  cp -r "${SRC_DIR}/assets/gtk-2.0/assets${theme}${ELSE_DARK:-}${scheme}/"*"png"              "${THEME_DIR}/gtk-2.0/assets"

  mkdir -p                                                                                   "${THEME_DIR}/gtk-3.0"
  cp -r "${SRC_DIR}/assets/gtk/scalable"                                                     "${THEME_DIR}/gtk-3.0/assets"
  cp -r "${SRC_DIR}/assets/gtk/thumbnails/thumbnail${theme}${scheme}${ELSE_DARK:-}.png"      "${THEME_DIR}/gtk-3.0/thumbnail.png"
  sassc $SASSC_OPT "${SRC_DIR}/main/gtk-3.0/gtk${color}.scss"                                "${THEME_DIR}/gtk-3.0/gtk.css"
  sassc $SASSC_OPT "${SRC_DIR}/main/gtk-3.0/gtk-Dark.scss"                                   "${THEME_DIR}/gtk-3.0/gtk-dark.css"

  mkdir -p                                                                                   "${THEME_DIR}/gtk-4.0"
  cp -r "${SRC_DIR}/assets/gtk/scalable"                                                     "${THEME_DIR}/gtk-4.0/assets"
  cp -r "${SRC_DIR}/assets/gtk/thumbnails/thumbnail${theme}${scheme}${ELSE_DARK:-}.png"      "${THEME_DIR}/gtk-4.0/thumbnail.png"
  sassc $SASSC_OPT "${SRC_DIR}/main/gtk-4.0/gtk${color}.scss"                                "${THEME_DIR}/gtk-4.0/gtk.css"
  sassc $SASSC_OPT "${SRC_DIR}/main/gtk-4.0/gtk-Dark.scss"                                   "${THEME_DIR}/gtk-4.0/gtk-dark.css"

  mkdir -p                                                                                   "${THEME_DIR}/cinnamon"
  cp -r "${SRC_DIR}/assets/cinnamon/common-assets"                                           "${THEME_DIR}/cinnamon/assets"
  cp -r "${SRC_DIR}/assets/cinnamon/assets${ELSE_DARK:-}/"*'.svg'                            "${THEME_DIR}/cinnamon/assets"
  cp -r "${SRC_DIR}/assets/cinnamon/theme${theme}${scheme}/"*'.svg'                          "${THEME_DIR}/cinnamon/assets"
  sassc $SASSC_OPT "${SRC_DIR}/main/cinnamon/cinnamon${color}.scss"                          "${THEME_DIR}/cinnamon/cinnamon.css"
  cp -r "${SRC_DIR}/assets/cinnamon/thumbnails/thumbnail${theme}${scheme}${color}.png"        "${THEME_DIR}/cinnamon/thumbnail.png"

  mkdir -p                                                                                   "${THEME_DIR}/metacity-1"
  cp -r "${SRC_DIR}/main/metacity-1/metacity-theme-3.xml"                                    "${THEME_DIR}/metacity-1/metacity-theme-3.xml"
  cp -r "${SRC_DIR}/assets/metacity-1/assets"                                                "${THEME_DIR}/metacity-1/assets"
  cp -r "${SRC_DIR}/assets/metacity-1/thumbnail${ELSE_DARK:-}.png"                           "${THEME_DIR}/metacity-1/thumbnail.png"
  cd "${THEME_DIR}/metacity-1" && ln -s metacity-theme-3.xml metacity-theme-1.xml && ln -s metacity-theme-3.xml metacity-theme-2.xml

  mkdir -p                                                                                   "${THEME_DIR}/xfwm4"
  cp -r "${SRC_DIR}/assets/xfwm4/png/assets${ELSE_DARK:-}/"*.png                             "${THEME_DIR}/xfwm4"
  cp -r "${SRC_DIR}/assets/xfwm4/xpm/assets/"*.xpm                                           "${THEME_DIR}/xfwm4"
  cp -r "${SRC_DIR}/main/xfwm4/themerc"                                                      "${THEME_DIR}/xfwm4/themerc"
  mkdir -p                                                                                   "${THEME_DIR}-hdpi/xfwm4"
  cp -r "${SRC_DIR}/assets/xfwm4/png/assets${ELSE_DARK:-}-hdpi/"*.png                        "${THEME_DIR}-hdpi/xfwm4"
  cp -r "${SRC_DIR}/assets/xfwm4/xpm/assets-hdpi/"*.xpm                                      "${THEME_DIR}-hdpi/xfwm4"
  cp -r "${SRC_DIR}/main/xfwm4/themerc"                                                      "${THEME_DIR}-hdpi/xfwm4/themerc"
  sed -i "s/button_offset=10/button_offset=15/"                                              "${THEME_DIR}-hdpi/xfwm4/themerc"
  mkdir -p                                                                                   "${THEME_DIR}-xhdpi/xfwm4"
  cp -r "${SRC_DIR}/assets/xfwm4/png/assets${ELSE_DARK:-}-xhdpi/"*.png                       "${THEME_DIR}-xhdpi/xfwm4"
  cp -r "${SRC_DIR}/assets/xfwm4/xpm/assets-xhdpi/"*.xpm                                     "${THEME_DIR}-xhdpi/xfwm4"
  cp -r "${SRC_DIR}/main/xfwm4/themerc"                                                      "${THEME_DIR}-xhdpi/xfwm4/themerc"
  sed -i "s/button_offset=10/button_offset=20/"                                              "${THEME_DIR}-xhdpi/xfwm4/themerc"
}

themes=()
colors=()
sizes=()
lcolors=()
schemes=()

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -d|--dest)
      dest="${2}"
      if [[ ! -d "${dest}" ]]; then
        echo "Destination directory does not exist. Let's make a new one..."
        mkdir -p ${dest}
      fi
      shift 2
      ;;
    -n|--name)
      name="${2}"
      shift 2
      ;;
    -r|--remove|-u|--uninstall)
      uninstall="true"
      shift
      ;;
    -l|--libadwaita)
      libadwaita="true"
      shift
      ;;
    -c|--color)
      shift
      for color in "${@}"; do
        case "${color}" in
          standard)
            colors+=("${COLOR_VARIANTS[0]}")
            lcolors+=("${COLOR_VARIANTS[0]}")
            shift
            ;;
          light)
            colors+=("${COLOR_VARIANTS[1]}")
            lcolors+=("${COLOR_VARIANTS[1]}")
            shift
            ;;
          dark)
            colors+=("${COLOR_VARIANTS[2]}")
            lcolors+=("${COLOR_VARIANTS[2]}")
            shift
            ;;
          -*|--*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized color variant '$1'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -t|--theme)
      accent='true'
      shift
      for variant in "$@"; do
        case "$variant" in
          default)
            themes+=("${THEME_VARIANTS[0]}")
            shift
            ;;
          purple)
            themes+=("${THEME_VARIANTS[1]}")
            shift
            ;;
          pink)
            themes+=("${THEME_VARIANTS[2]}")
            shift
            ;;
          red)
            themes+=("${THEME_VARIANTS[3]}")
            shift
            ;;
          orange)
            themes+=("${THEME_VARIANTS[4]}")
            shift
            ;;
          yellow)
            themes+=("${THEME_VARIANTS[5]}")
            shift
            ;;
          green)
            themes+=("${THEME_VARIANTS[6]}")
            shift
            ;;
          teal)
            themes+=("${THEME_VARIANTS[7]}")
            shift
            ;;
          grey)
            themes+=("${THEME_VARIANTS[8]}")
            shift
            ;;
          all)
            themes+=("${THEME_VARIANTS[@]}")
            shift
            ;;
          -*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized theme variant '$1'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -s|--size)
      shift
      for variant in "$@"; do
        case "$variant" in
          standard)
            sizes+=("${SIZE_VARIANTS[0]}")
            shift
            ;;
          compact)
            sizes+=("${SIZE_VARIANTS[1]}")
            compact='true'
            shift
            ;;
          -*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized size variant '${1:-}'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    --tweaks)
      shift
      for variant in $@; do
        case "$variant" in
          nord)
            colorscheme='true'
            schemes+=("${SCHEME_VARIANTS[1]}")
            echo -e "\nNord ColorScheme version! ...\n"
            shift
            ;;
          dracula)
            colorscheme='true'
            schemes+=("${SCHEME_VARIANTS[2]}")
            echo -e "\nDracula ColorScheme version! ...\n"
            shift
            ;;
          gruvbox)
            colorscheme='true'
            schemes+=("${SCHEME_VARIANTS[3]}")
            echo -e "\nGruvbox ColorScheme version! ...\n"
            shift
            ;;
          all)
            colorscheme='true'
            schemes+=("${SCHEME_VARIANTS[@]}")
            echo -e "\nInstall all ColorSchemes version! ...\n"
            shift
            ;;
          black)
            blackness="true"
            echo -e "\nBlackness version! ..."
            shift
            ;;
          float)
            float="true"
            echo -e "\nInstall Floating Gnome-Shell Panel version! ..."
            shift
            ;;
          outline)
            outline="true"
            echo -e "\nInstall 2px windows outline version! ..."
            shift
            ;;
          -*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized tweaks variant '$1'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unrecognized installation option '$1'."
      echo "Try '$0 --help' for more information."
      exit 1
      ;;
  esac
done

if [[ "${#themes[@]}" -eq 0 ]] ; then
  themes=("${THEME_VARIANTS[0]}")
fi

if [[ "${#colors[@]}" -eq 0 ]] ; then
  colors=("${COLOR_VARIANTS[@]}")
fi

if [[ "${#lcolors[@]}" -eq 0 ]] ; then
  lcolors=("${COLOR_VARIANTS[1]}")
fi

if [[ "${#sizes[@]}" -eq 0 ]] ; then
  sizes=("${SIZE_VARIANTS[0]}")
fi

if [[ "${#schemes[@]}" -eq 0 ]] ; then
  schemes=("${SCHEME_VARIANTS[0]}")
fi

#  Check command avalibility
function has_command() {
  command -v $1 > /dev/null
}

#  Install needed packages
install_package() {
  if ! has_command sassc; then
    echo sassc needs to be installed to generate the css.
    if has_command zypper; then
      sudo zypper in sassc
    elif has_command apt-get; then
      sudo apt-get install sassc
    elif has_command dnf; then
      sudo dnf install sassc
    elif has_command dnf; then
      sudo dnf install sassc
    elif has_command pacman; then
      sudo pacman -S --noconfirm sassc
    fi
  fi
}

tweaks_temp() {
  cp -rf "${SRC_DIR}/sass/_tweaks.scss" "${SRC_DIR}/sass/_tweaks-temp.scss"
}

compact_size() {
  sed -i "/\$compact:/s/false/true/" "${SRC_DIR}/sass/_tweaks-temp.scss"
}

blackness_color() {
  sed -i "/\$blackness:/s/false/true/" "${SRC_DIR}/sass/_tweaks-temp.scss"
}

float_panel() {
  sed -i "/\$float:/s/false/true/" "${SRC_DIR}/sass/_tweaks-temp.scss"
}

outline_style() {
  sed -i "/\$outline:/s/false/true/" "${SRC_DIR}/sass/_tweaks-temp.scss"
}

gnome_shell_version() {
  cp -rf "${SRC_DIR}/sass/gnome-shell/_common.scss" "${SRC_DIR}/sass/gnome-shell/_common-temp.scss"

  sed -i "/\widgets/s/40-0/${GS_VERSION}/" "${SRC_DIR}/sass/gnome-shell/_common-temp.scss"

  if [[ "${GS_VERSION}" == '3-28' ]]; then
    sed -i "/\extensions/s/40-0/3-28/" ${SRC_DIR}/sass/gnome-shell/_common-temp.scss
  elif [[ "${GS_VERSION}" -ge '46-0' ]]; then
    sed -i "/\extensions/s/40-0/46-0/" ${SRC_DIR}/sass/gnome-shell/_common-temp.scss
  fi
}

color_schemes() {
  if [[ "$scheme" != '' ]]; then
    case "$scheme" in
      -Nord)
        scheme_color='nord'
        ;;
      -Dracula)
        scheme_color='dracula'
        ;;
      -Gruvbox)
        scheme_color='gruvbox'
        ;;
    esac
    sed -i "/\@import/s/color-palette-default/color-palette-${scheme_color}/" "${SRC_DIR}/sass/_tweaks-temp.scss"
    sed -i "/\$colorscheme:/s/default/${scheme_color}/" "${SRC_DIR}/sass/_tweaks-temp.scss"
  fi
}

theme_color() {
  if [[ "$theme" != '' ]]; then
    case "$theme" in
      -Purple)
        theme_color='purple'
        ;;
      -Pink)
        theme_color='pink'
        ;;
      -Red)
        theme_color='red'
        ;;
      -Orange)
        theme_color='orange'
        ;;
      -Yellow)
        theme_color='yellow'
        ;;
      -Green)
        theme_color='green'
        ;;
      -Teal)
        theme_color='teal'
        ;;
      -Grey)
        theme_color='grey'
        ;;
    esac
    tweaks_temp
    sed -i "/\$theme:/s/default/${theme_color}/" "${SRC_DIR}/sass/_tweaks-temp.scss"
  fi
}

theme_tweaks() {
  if [[ "$accent" = "true" ]] ; then
    theme_color
  fi

  if [[ "$compact" = "true" ]] ; then
    compact_size
  fi

  if [[ "$colorscheme" = "true" ]] ; then
    color_schemes
  fi

  if [[ "$blackness" = "true" ]] ; then
    blackness_color
  fi

  if [[ "$float" = "true" ]] ; then
    float_panel
  fi

  if [[ "$outline" = "true" ]] ; then
    outline_style
  fi
}

uninstall_link() {
  rm -rf "${HOME}/.config/gtk-4.0/"{assets,windows-assets,gtk.css,gtk-dark.css}
}

link_libadwaita() {
  local dest="${1}"
  local name="${2}"
  local theme="${3}"
  local color="${4}"
  local size="${5}"
  local scheme="${6}"

  local THEME_DIR="${1}/${2}${3}${4}${5}${6}"

  rm -rf "${HOME}/.config/gtk-4.0/"{assets,gtk.css,gtk-dark.css}

  echo -e "\nLink '$THEME_DIR/gtk-4.0' to '${HOME}/.config/gtk-4.0' for libadwaita..."

  mkdir -p                                                                      "${HOME}/.config/gtk-4.0"
  ln -sf "${THEME_DIR}/gtk-4.0/assets"                                          "${HOME}/.config/gtk-4.0/assets"
  ln -sf "${THEME_DIR}/gtk-4.0/gtk.css"                                         "${HOME}/.config/gtk-4.0/gtk.css"
  ln -sf "${THEME_DIR}/gtk-4.0/gtk-dark.css"                                    "${HOME}/.config/gtk-4.0/gtk-dark.css"
}

link_theme() {
  for theme in "${themes[@]}"; do
    for color in "${lcolors[@]}"; do
      for size in "${sizes[@]}"; do
        for scheme in "${schemes[@]}"; do
          link_libadwaita "${dest:-$DEST_DIR}" "${name:-$THEME_NAME}" "$theme" "$color" "$size" "$scheme"
        done
      done
    done
  done
}

install_theme() {
  for theme in "${themes[@]}"; do
    for color in "${colors[@]}"; do
      for size in "${sizes[@]}"; do
        for scheme in "${schemes[@]}"; do
          install "${dest:-$DEST_DIR}" "${name:-$THEME_NAME}" "$theme" "$color" "$size" "$scheme"
          make_gtkrc "${dest:-$DEST_DIR}" "${name:-$THEME_NAME}" "$theme" "$color" "$size" "$scheme"
        done
      done
    done
  done

  if has_command xfce4-popup-whiskermen; then
    sed -i "s|.*menu-opacity=.*|menu-opacity=0|" "$HOME/.config/xfce4/panel/whiskermenu"*".rc"
  fi

  if (pgrep xfce4-session &> /dev/null); then
    xfce4-panel -r
  fi
}

uninstall() {
  local dest="${1}"
  local name="${2}"
  local theme="${3}"
  local color="${4}"
  local size="${5}"
  local scheme="${6}"

  local THEME_DIR="${1}/${2}${3}${4}${5}${6}"

  if [[ -d "${THEME_DIR}" ]]; then
    echo -e "Uninstall ${THEME_DIR}... "
    rm -rf "${THEME_DIR}"{'','-hdpi','-xhdpi'}
  fi
}

uninstall_theme() {
  for theme in "${THEME_VARIANTS[@]}"; do
    for color in "${COLOR_VARIANTS[@]}"; do
      for size in "${SIZE_VARIANTS[@]}"; do
        for scheme in "${SCHEME_VARIANTS[@]}"; do
          uninstall "${dest:-$DEST_DIR}" "${name:-$THEME_NAME}" "$theme" "$color" "$size" "$scheme"
        done
      done
    done
  done
}

clean_theme() {
  if [[ "$UID" -eq "$ROOT_UID" ]]; then
    uninstall_theme
  else
    if [[ "$DEST_DIR" == "$HOME/.themes" ]]; then
      local DEST_DIR="$HOME/.local/share/themes"
      uninstall_theme
    fi
  fi
}

if [[ "$uninstall" == 'true' ]]; then
  if [[ "$libadwaita" == 'true' ]]; then
    echo -e "\nUninstall ${HOME}/.config/gtk-4.0 links ..."
    uninstall_link
  else
    echo && uninstall_theme && uninstall_link
  fi
else
  install_package && tweaks_temp && gnome_shell_version && clean_theme && install_theme
  if [[ "$libadwaita" == 'true' ]]; then
    uninstall_link && link_theme
  fi
fi

echo
echo Done.
