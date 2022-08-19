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
# VARIABLES
#=========================================================
GENERATE_PLUGIN_FILES="false"

DEFAULT_TYPE="extend"
DEFAULT_NAME="Foobar"
DEFAULT_DESC=""
DEFAULT_VER="1.0.0"
DEFAULT_ENV_SYSTEM="^8.0"
DEFAULT_URL="https://github.com/friends-of-sunlight-cms/"
DEFAULT_TPL_RESPONSIVE="n"
DEFAULT_TPL_DARK="n"

PLUGIN_TYPE=""
PLUGIN_NAMES=("" "" "") # plugin name, class name, dir name
PLUGIN_DESC=""
PLUGIN_VERSION=""
PLUGIN_ENV_SYSTEM=""
PLUGIN_URL=""
PLUGIN_TEMPLATE_RESPONSIVE=""
PLUGIN_TEMPLATE_RESPONSIVE_VAL=""
PLUGIN_TEMPLATE_DARK=""
PLUGIN_TEMPLATE_DARK_VAL=""

PLUGIN_EXTEND_JSON=""
PLUGIN_TEMPLATE_JSON=""

#=========================================================
# FUNCTIONS
#=========================================================
function printErr() {
  printf "${BGRED}$1${NC}"
}

function header() {
  echo ""
  printf "${LBLUE}##############################################${NC}"
  echo""
  printf "${LBLUE}#${NC}       Sunlight CMS 8 - Plugin Wizard       ${LBLUE}#${NC}"
  echo ""
  printf "${LBLUE}#${NC} https://github.com/friends-of-sunlight-cms ${LBLUE}#${NC}"
  echo ""
  printf "${LBLUE}####################################${NC} v${WIZVERSION} ${LBLUE}##${NC}"
  echo ""
  echo ""
  printf "${DGRAY}This wizard will guide you through creating your plugin.${NC}"
  echo ""
  echo ""
}

function runWizard() {
  createPluginByType
  exit 1
}

function createPluginByType() {
  inputPluginType

  inputPluginName
  inputPluginDesc
  inputPluginVersion
  inputEnvSystemVersion
  inputPluginUrl

  case "$PLUGIN_TYPE" in
  extend)
    generationExtendPreview

    createPluginFolders ${PLUGIN_TYPE} ${PLUGIN_NAMES[2]}
    createExtendJson
    createExtendClass
    createExtendResLang
    ;;
  template)
    inputTemplateReponsive
    inputTemplateDark

    generationTemplatePreview

    createPluginFolders "${PLUGIN_TYPE}s" ${PLUGIN_NAMES[2]} # folder must contain 's' at the end
    createTemplateJson
    createTemplateFile
    createTemplateLabels
    copyTemplate
    ;;
  *) ;;
  esac

  echo ""
  printf "${GREEN}DONE! The skeleton of the new plugin '${NC}${PLUGIN_NAMES[0]^}${GREEN}' is ready.${NC}"
  echo ""
  exit 1
}

#=========================================================
# EXTEND TYPE
#=========================================================

function inputPluginType() {

  read -i "$PLUGIN_TYPE" -ep $'Plugin type (extend|template) [\033[0;33mextend\033[0m]: ' TYPE
  PLUGIN_TYPE=${TYPE:-${DEFAULT_TYPE}}
  PLUGIN_TYPE=${PLUGIN_TYPE,,} # lowercase

  # validate plugin type
  case "$PLUGIN_TYPE" in
  extend | ext | e) PLUGIN_TYPE="extend" ;;
  template | tpl | t) PLUGIN_TYPE="template" ;;
  *)
    printErr "Invalid plugin type: '$PLUGIN_TYPE'!"
    PLUGIN_TYPE='' # reset
    echo ""
    inputPluginType # plugin type query again
    ;;
  esac
}

function inputPluginName() {
  read -i "$PLUGIN_NAME" -ep $'Name [\033[0;33mFoobar\033[0m]: ' NAME
  PLUGIN_NAME=${NAME:-${DEFAULT_NAME}}
  PLUGIN_NAMES[0]=${PLUGIN_NAME}
  PLUGIN_NAMES[1]=${PLUGIN_NAMES[0]// /} # remove spaces
  PLUGIN_NAMES[2]=${PLUGIN_NAMES[1],,}   # lowercase
}

function inputPluginDesc() {
  read -i "$PLUGIN_DESC" -ep 'Description []: ' DESC
  PLUGIN_DESC=${DESC:-${DEFAULT_DESC}}
}

function inputPluginVersion() {
  read -i "$PLUGIN_VERSION" -ep $'Version [\033[0;33m1.0.0\033[0m]: ' VERSION
  PLUGIN_VERSION=${VERSION:-${DEFAULT_VER}}
}

function inputEnvSystemVersion() {
  read -i "$PLUGIN_ENV_SYSTEM" -ep $'Env - System Version [\033[0;33m^8.0\033[0m]: ' SYSTEMVER
  PLUGIN_ENV_SYSTEM=${SYSTEMVER:-${DEFAULT_ENV_SYSTEM}}
}

function inputPluginUrl() {
  read -i "$PLUGIN_URL" -ep $'Url [\033[0;33mhttps://github.com/friends-of-sunlight-cms/\033[0m]: ' URL
  PLUGIN_URL=${URL:-${DEFAULT_URL}}
}

function inputTemplateReponsive() {
  read -i "$PLUGIN_TEMPLATE_RESPONSIVE" -ep $'Is RESPONSIVE (y|n) [\033[0;33mn\033[0m]?: ' RESP
  PLUGIN_TEMPLATE_RESPONSIVE=${RESP:-${DEFAULT_TPL_RESPONSIVE}}
  PLUGIN_TEMPLATE_RESPONSIVE=${PLUGIN_TEMPLATE_RESPONSIVE,,}

  case "$PLUGIN_TEMPLATE_RESPONSIVE" in
    y | yes | 1) PLUGIN_TEMPLATE_RESPONSIVE_VAL=true ;;
    *) PLUGIN_TEMPLATE_RESPONSIVE_VAL=false ;;
  esac
}

function inputTemplateDark() {
  read -i "$PLUGIN_TEMPLATE_DARK" -ep $'Is DARK (y|n) [\033[0;33mn\033[0m]?: ' DARK
  PLUGIN_TEMPLATE_DARK=${DARK:-${DEFAULT_TPL_DARK}}
  PLUGIN_TEMPLATE_DARK=${PLUGIN_TEMPLATE_DARK,,}

  case "$PLUGIN_TEMPLATE_DARK" in
    y | yes | 1) PLUGIN_TEMPLATE_DARK_VAL=true ;;
    *) PLUGIN_TEMPLATE_DARK_VAL=false ;;
  esac
}

#=========================================================
# COMMON WIZARD FUNCTIONS
#=========================================================

function generationConfirm() {
  read -ep $'Do you confirm generation (y|n) [\033[0;33my\033[0m, f to fix]?: ' GEN
  GEN=${GEN:-y}
  GEN=${GEN,,}
  case "$GEN" in
  y | yes | 1)
    GENERATE_PLUGIN_FILES="true" # enable file generation
    echo ""
    printf "${GREEN}Generating plugin files...${NC}"
    echo ""
    ;;
  f | fix)
    read -ep $'Do you want to correct the entered values? (y|n) [\033[0;33my\033[0m]?: ' COR
    COR=${COR:-y}
    COR=${COR,,}
    case "$COR" in
    y | yes | 1)
      echo ""
      createPluginByType
      ;;
    *)
      printErr "Command aborted"
      exit 1
      ;;
    esac
    ;;
  *)
    printErr "Command aborted"
    exit 1
    ;;
  esac
}

function createPluginFolders() {
  local PLUGIN_PATH="plugins/$1/$2"

  if [ "$GENERATE_PLUGIN_FILES" = "false" ]; then
    echo ""
    printErr "The plugin structure was not generated!"
    exit 1
  fi

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
    y | yes | 1)
      rm -rf ${PLUGIN_PATH}
      printf "${GREEN}The${NC} '${PLUGIN_PATH}' ${GREEN}folder has been deleted!${NC}"
      echo ""
      ;;
    *) ;;
    esac
    exit 1
  fi
}

#=========================================================
# EXTEND TYPE
#=========================================================

function generationExtendPreview() {
  PLUGIN_EXTEND_JSON=$(
    cat <<-EOF
{
    "\$schema": "../../../system/schema/extend.json",
    "name": "${PLUGIN_NAMES[0]}",
    "description": "${PLUGIN_DESC}",
    "version": "${PLUGIN_VERSION}",
    "environment": {
        "system": "${PLUGIN_ENV_SYSTEM}"
    },
    "url": "${PLUGIN_URL}",
    "class": "${PLUGIN_NAMES[1]}Plugin",
    "langs": {
        "${PLUGIN_NAMES[2],,}": "Resources/languages/"
    },
    "events": [],
    "events.web": [],
    "events.admin": []
}
EOF
)

  echo ""
  echo "${PLUGIN_EXTEND_JSON}"
  echo ""

  generationConfirm
}

function createExtendJson() {
  cat >plugin.json <<EOF
${PLUGIN_EXTEND_JSON}
EOF
}

function createExtendResLang() {
  mkdir -p Resources/languages

  lng=(en cs)
  for i in "${lng[@]}"; do
    cat >Resources/languages/$i.php <<EOF
<?php

return [
];
EOF
  done
}

function createExtendClass() {
  local NAMESPACE=${PLUGIN_NAMES[2]^} # capitalize

  cat >${PLUGIN_NAMES[1]}Plugin.php <<EOF
<?php

namespace SunlightExtend\\${NAMESPACE};

use Sunlight\Plugin\ExtendPlugin;

class ${PLUGIN_NAMES[1]}Plugin extends ExtendPlugin
{

}
EOF
}

#=========================================================
# TEMPLATE TYPE
#=========================================================

function generationTemplatePreview() {
  PLUGIN_TEMPLATE_JSON=$(
    cat <<-EOF
{
    "\$schema": "../../../system/schema/template.json",
    "name": "${PLUGIN_NAMES[0]}",
    "description": "${PLUGIN_DESC}",
    "version": "${PLUGIN_VERSION}",
    "environment": {
        "system": "${PLUGIN_ENV_SYSTEM}"
    },
    "url": "${PLUGIN_URL}",
    "responsive": ${PLUGIN_TEMPLATE_RESPONSIVE_VAL},
    "layouts": {
        "default": {
            "template": "template.php",
            "slots": ["right"]
        }
    },
    "dark": ${PLUGIN_TEMPLATE_DARK_VAL},
    "bbcode.buttons": true,
    "box.parent": "ul",
    "box.item": "li",
    "box.title": "h2",
    "box.title.inside": true
}
EOF
)

  echo ""
  echo "${PLUGIN_TEMPLATE_JSON}"
  echo ""

  generationConfirm
}

function createTemplateJson() {
  cat >plugin.json <<EOF
${PLUGIN_TEMPLATE_JSON}
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

function createTemplateLabels() {
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

function copyTemplate() {
  # copy images from Default
  if [ -d '../default/images' ]; then

    read -ep $'Copy images from default template [\033[0;33my\033[0m]?: ' COPY_IMAGES
    COPY_IMAGES=${COPY_IMAGES:-y}
    COPY_IMAGES=${COPY_IMAGES,,} # lowercase
    case "$COPY_IMAGES" in
    y | yes | 1)
      cp -r ../default/images ./images
      ;;
    *) mkdir images ;;
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
