#!/bin/bash

WIZVERSION="1.0.0"

#=========================================================
# CLI COLORS
#=========================================================

BLACK='\033[0;30m'
DGRAY='\033[1;30m'
RED='\033[0;31m'
LRED='\033[1;31m'
GREEN='\033[0;32m'
LGREEN='\033[1;32m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LBLUE='\033[1;34m'
PURPLE='\033[0;35m'
LPURPLE='\033[1;35m'
CYAN='\033[0;36m'
LCYAN='\033[1;36m'
LGRAY='\033[0;37m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

BGRED='\033[0;41m'

#=========================================================
# FUNCTIONS
#=========================================================
function printErr() {
  printf "${BGRED}$1${NC}"
}

function header() {
  echo ""
  printf "${LBLUE}##############################################${NC}"; echo""
  printf "${LBLUE}#${NC}       Sunlight CMS 8 - Plugin Wizard       ${LBLUE}#${NC}"; echo ""
  printf "${LBLUE}#${NC} https://github.com/friends-of-sunlight-cms ${LBLUE}#${NC}"; echo ""
  printf "${LBLUE}####################################${NC} v${WIZVERSION} ${LBLUE}##${NC}"; echo ""
  echo ""
  printf "${DGRAY}This wizard will guide you through creating your plugin.${NC}"
  echo ""
  echo ""
}

function runWizard() {

  # query for the type of plugin required
  read -ep $'Plugin type (extend|template) [\033[0;33mextend\033[0m]: ' PLUGIN_TYPE
  PLUGIN_TYPE=${PLUGIN_TYPE:-extend}
  PLUGIN_TYPE=${PLUGIN_TYPE,,}

  # validate plugin type
  case "$PLUGIN_TYPE" in
    (extend|ext|e) PLUGIN_TYPE=extend ;;
    (template|tpl|t) PLUGIN_TYPE=template ;;
    (*)
      printErr "Invalid plugin type!"
      exit 1
    ;;
  esac

  # query for the name of plugin required
  read -ep $'Name [\033[0;33mFoobar\033[0m]: ' PLUGIN_NAME
  PLUGIN_NAME=${PLUGIN_NAME:-Foobar}
  PLUGIN_NAME=${PLUGIN_NAME,,} # lowercase
  PLUGIN_NAME=${PLUGIN_NAME// /} # remove spaces

  # creating plugin
  case "$PLUGIN_TYPE" in
        (extend)
          createPluginFolders ${PLUGIN_TYPE} ${PLUGIN_NAME}
          createExtend ${PLUGIN_NAME}
        ;;
        (template)
          createPluginFolders "${PLUGIN_TYPE}s" ${PLUGIN_NAME} # folder must contain 's' at the end
          createTemplate ${PLUGIN_NAME}
        ;;
        (*) ;;
  esac

  echo ""
  printf "${GREEN}DONE! The skeleton of the new plugin '${NC}${PLUGIN_NAME^}${GREEN}' is ready.${NC}"
  echo ""
  exit 1
}

function createPluginFolders() {
  local ARG1=$1
  local ARG2=$2
  local TYPE=${ARG1,,} # lowercase
  local NAME=${ARG2,,} # lowercase
  local PLUGIN_PATH="plugins/${TYPE}/${NAME}"

  if [ ! -d ${PLUGIN_PATH} ]; then
    mkdir -p ${PLUGIN_PATH}
    cd ${PLUGIN_PATH}
  else
    echo ""
    printf "${BGRED}Error: Destination folder '$PLUGIN_PATH' already exists!${NC}\n"
    read -ep $'Do you want to delete the existing folder (y|n) [\033[0;33mn\033[0m]?: ' PLUGIN_DELETE
    PLUGIN_DELETE=${PLUGIN_DELETE:-n}
    PLUGIN_DELETE=${PLUGIN_DELETE,,}
    case "$PLUGIN_DELETE" in
      (y|yes|1)
        rm -rf ${PLUGIN_PATH};
        printf "${GREEN}The${NC} '${PLUGIN_PATH}' ${GREEN}folder has been deleted!${NC}";
        echo ""
      ;;
      (*) ;;
    esac
    exit 1
  fi
}

#=========================================================
# EXTEND TYPE
#=========================================================

function createExtendResLang() {
  mkdir -p Resources/languages

  lng=( en cs )
  for i in "${lng[@]}"
  do
    cat >Resources/languages/$i.php <<EOF
<?php

return [
];
EOF
  done
}

function createExtendJson() {
  local ARG1=$1
  local NAME=${ARG1^} # capitalize

  read -ep 'Description []: ' EXTEND_DESC
  read -ep $'Version [\033[0;33m1.0.0\033[0m]: ' EXTEND_VERSION
  EXTEND_VERSION=${EXTEND_VERSION:-"1.0.0"}
  read -ep $'Url [\033[0;33mhttps://sunlight-cms.cz\033[0m]: ' EXTEND_URL
  EXTEND_URL=${EXTEND_URL:-"https://sunlight-cms.cz"}

  cat >plugin.json <<EOF
{
    "\$schema": "../../../system/schema/extend.json",
    "name": "${NAME}",
    "description": "${EXTEND_DESC}",
    "version": "${EXTEND_VERSION}",
    "api": "^8.0",
    "url": "${EXTEND_URL}",
    "class": "${NAME}Plugin",
    "langs": {
        "${NAME,,}": "Resources/languages/"
    },
    "events": [],
    "events.web": [],
    "events.admin": []
}
EOF
}

function createExtendClass() {
  local ARG1=$1
  local NAME=${ARG1^} # capitalize
  cat >${NAME}Plugin.php <<EOF
<?php

namespace SunlightExtend\\${NAME};

use Sunlight\Plugin\ExtendPlugin;

class ${NAME}Plugin extends ExtendPlugin
{

}
EOF
}

function createExtend() {
  # create plugin.json
  createExtendJson $1
  # create <Name>Plugin.php
  createExtendClass $1
  # create Resources/languages/(cs|en).php
  createExtendResLang
}

#=========================================================
# TEMPLATE TYPE
#=========================================================

function createTemplateJson() {
  local ARG1=$1
  local NAME=${ARG1^} # capitalize

  read -ep 'Description []: ' TEMPLATE_DESC

  read -ep $'Version [\033[0;33m1.0.0\033[0m]: ' TEMPLATE_VERSION
  TEMPLATE_VERSION=${TEMPLATE_VERSION:-"1.0.0"}

  read -ep $'Url [\033[0;33mhttps://sunlight-cms.cz\033[0m]: ' TEMPLATE_URL
  TEMPLATE_URL=${TEMPLATE_URL:-"https://sunlight-cms.cz"}

  read -ep $'Is RESPONSIVE (y|n) [\033[0;33mn\033[0m]?: ' TEMPLATE_RESPONSIVE
  TEMPLATE_RESPONSIVE=${TEMPLATE_RESPONSIVE:-n}
  TEMPLATE_RESPONSIVE=${TEMPLATE_RESPONSIVE,,}
  case "$TEMPLATE_RESPONSIVE" in
    (y|yes|1) TEMPLATE_RESPONSIVE=true ;;
    (*) TEMPLATE_RESPONSIVE=false ;;
  esac

  read -ep $'Is DARK (y|n) [\033[0;33mn\033[0m]?: ' TEMPLATE_DARK
  TEMPLATE_DARK=${TEMPLATE_DARK:-n}
  TEMPLATE_DARK=${TEMPLATE_DARK,,}
  case "$TEMPLATE_DARK" in
        (y|yes|1) TEMPLATE_DARK=true ;;
        (*) TEMPLATE_DARK=false ;;
  esac

  cat >plugin.json <<EOF
{
    "\$schema": "../../../system/schema/template.json",
    "name": "${NAME}",
    "description": "${TEMPLATE_DESC}",
    "version": "${TEMPLATE_VERSION}",
    "api": "^8.0",
    "url": "${TEMPLATE_URL}",
    "responsive": ${TEMPLATE_RESPONSIVE},
    "layouts": {
        "default": {
            "template": "template.php",
            "slots": ["right"]
        }
    },
    "dark": ${TEMPLATE_DARK},
    "bbcode.buttons": true,
    "box.parent": "ul",
    "box.item": "li",
    "box.title": "h2",
    "box.title.inside": true
}
EOF
}

function createTemplateFile() {
  cat >template.php <<EOF
<?php
use Sunlight\Template;
defined('SL_ROOT') or exit
?>

<div id="wrapper">
    <div id="header">
        <div id="logo">
            <a href="<?= Template::siteUrl() ?>"><?= Template::siteTitle() ?></a>
            <p><?= Template::siteDescription() ?></p>
        </div>

        <?= Template::userMenu() ?>
    </div>

    <div id="menu">
        <?= Template::menu() ?>
    </div>

    <div id="page">
        <div id="content">
            <?= Template::heading() ?>
            <?= Template::backlink() ?>
            <?= Template::content() ?>

            <div class="cleaner"></div>
        </div>
        <div id="sidebar">
            <?= Template::boxes('right') ?>
        </div>
        <div class="cleaner"></div>
    </div>
</div>
<div id="footer">
    <ul>
        <?= Template::links() ?>
    </ul>
</div>
EOF
}

function createTemplateLabels(){
  mkdir labels

  cat >labels/en.php <<EOF
<?php

return [
    'default.label' => 'default',
    'default.slot.right' => 'right column',
];
EOF

  cat >labels/cs.php <<EOF
<?php

return [
    'default.label' => 'výchozí',
    'default.slot.right' => 'pravý sloupec',
];
EOF
}

function createTemplate() {
  # create plugin.json
  createTemplateJson $1
  # create template.php
  createTemplateFile
  # create labels/(cs|en).php
  createTemplateLabels
  # copy images from Default
  if [ -d '../default/images' ]; then

    read -ep $'Copy images from default template [\033[0;33my\033[0m]?: ' COPY_IMAGES
    COPY_IMAGES=${COPY_IMAGES:-y}
    COPY_IMAGES=${COPY_IMAGES,,} # lowercase
    case "$COPY_IMAGES" in
      (y|yes|1)
        cp -r ../default/images ./images
      ;;
      (*) mkdir images ;;
    esac

  fi
  # create empty style.css
  touch style.css
}

#=========================================================
# PROCESS
#=========================================================

# print header
header
# run wizard
runWizard

