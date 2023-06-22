#!/bin/bash

# Define colors

RESET="\e[0m"
RED="$RESET\e[31m"
GREEN="$RESET\e[32m"
AQUA="$RESET\e[94m"
MMC_PREFIX="MMC: "

function info(){ echo -e "${AQUA}$1${RESET}"; }
function warn(){ echo -e "${RED}$1${RESET}"; }
function succ(){ echo -e "${GREEN}$1${RESET}"; }

succ "PKMC v0.0.1"
echo "Project Home: https://github.com/iceBear67/pkmc"
echo ""
info "[..] Scanning for Minecraft Folders"

options=()

# Arg: folder isMMC
function add_option(){
  if $2; then
    options+=("$MMC_PREFIX$1")
  else
    options+=("$1")
  fi
}

# Arg: beginFolder
function scanSimple(){
#  echo "[!] Scanning folder: $1"
  shopt -s dotglob # Since they are named `.minecraft`
  for dotMC in $1/* ; do
    if [ -d "$dotMC" ]; then
      if [[ -d "$dotMC/versions" ]] && [[ -d "$dotMC/mods" ]] && [[ $(ls $dotMC/mods) ]]; then
#        succ "[!!] Found Instance: $dotMC"
        add_option "$dotMC" false
      fi
    fi
  done
  shopt -u dotglob
}

#Arg: Folder of all Instances
function scanMMC(){
#  echo "[!] Scanning for MMC Instances: $1"
  for instanceFolder in $1/* ; do
    if [[ -d "$instanceFolder" ]] && [[ -f $instanceFolder/mmc-pack.json ]]; then
#      succ "[!!] Found MMC Instance: $instanceFolder"
      add_option "$instanceFolder" true
    fi
  done
}

# Arg: MMCInstFolder
function processMMC(){
  echo $1
}

# Arg: .minecraft Folder
function processNormal(){
  tmpDir="/tmp"
  while [[ -d $tmpDir ]]; do
    tmpDir="/tmp/pkmc-$RANDOM"
  done
  mkdir $tmpDir
  mkdir "$tmpDir/.minecraft"
  info "[..] Copying Mods"
  cp -r "$1/mods" "$tmpDir/.minecraft/" # Copy mods...
  info "[..] Copying Mod Configurations"
  cp -r "$1/config" "$tmpDir/.minecraft/" # Copy mod configurations...
  cp -r "$1/scripts" "$tmpDir/.minecraft/"
  cp -r "$1/resources" "$tmpDir/.minecraft/"
  info "[..] Copying Libraries"
  cp -r "$1/libraries" "$tmpDir/.minecraft/" # Copy Libraries...
  info "[..] Copying Assets"
  cp -r "$1/assets" "$tmpDir/.minecraft/" # Assets...

  copyServersDat=""
  while [[ $copyServersDat == ""]]; do
    info "[?] Should we copy server settings? (Y/N)"
    read copyServersDat
    copyServersDat=${copyServersDat@L}
  done
  if beginswith y copyServersDat; then
    succ "[...] Copying server list"
    cp -r "$1/servers.dat" "$tmpDir/.minecraft/"
  fi

  copyVidSetting=""
  while [[ $copyVidSetting == "" ]]; do
    succ "[?] Should we copy Video Settings? (Y/N)"
    read copyVidSetting
    copyVidSetting=${copyVidSetting@L}
  done

  if beginswith y $copyVidSetting; then
    succ "[...] Copying video settings"
    cp -r "$1/options*.txt" "$tmpDir/.minecraft/"
  fi
  
  copyResourcePack=""
  while [[ $copyResourcePack == "" ]]; do
    info "[?] Should we copy resource packs? (Y/N)"
    read copyResourcePack
    copyResourcePack=${copyResourcePack@L}
  done
  
  if beginswith y $copyResourcePack; then
    succ "[...] Copying Resource Packs"
    cp -r "$1/resourcepacks" "$tmpDir/.minecraft/"
  fi
  
  info "[!] Almost Done"
  installMinecraftGuide "$tmpDir"
}

scanSimple .
scanMMC ~/.local/share/PrismLauncher/instances
scanMMC ~/.local/share/MultiMC/instances
scanSimple ~/.config/hmcl/.minecraft

if [[ $1 ]]; then
  if [[ -d "$1/.minecraft/mods" ]]; then
    scanSimple "$1"
  else
    scanMMC "$1"
  fi
fi

function beginswith() { case $2 in "$1"*) true;; *) false;; esac; }
function awaitUserInput(){
  if [[ ${#options[@]} == 0 ]]; then
    warn "[!] We didn't found any available instances."
    warn " --- Please provide a path to instance. --"
  else
    printInstances
    info "Please select one, by typing their index."
    info "Type another path to scan again."
  fi

  read userInput
  if [[ $userInput =~ ^[0-9]+$ ]]; then
    if [[ $userInput -ge ${#options[@]} ]]; then
      warn "[!!] Please provide a valid index!"
      return
    fi
    # Selected an instance
    succ "[+] Your selection: $userInput: ${options[$userInput]}"

    if beginswith "MMC" ${options[$userInput]}; then
      info "[..] Processing MMC Instance"
      processMMC ${options[$userInput]#$MMC_PREFIX}
    else
      info "[..] Processing Instance"
      processNormal ${options[$userInput]}
    fi
    return
  else
    if ! [[ -d "$userInput" ]]; then
      warn "[!!] Not a valid path or index number."
      return
    fi
    # Probably a path.
    isMMCFolder=""
    while [[ $isMMCFolder == "" ]]; do
      info "[?] Is it a MMC instance[s] folder? (Y/N)"
      read isMMCFolder
     isMMCFolder=${isMMCFolder@L}
    done
    if beginswith y $isMMCFolder; then
      info "[..] Scanning for MMC instances"
      scanMMC "$userInput"
    else
      info "[..] Scanning for mods"
      scanSimple "$userInput"
    fi
    succ "[+] Scan completed!"
    echo ""
    return
  fi
}

function printInstances(){
  index=0
  for entry in "${options[@]}" ; do
    if beginswith "$MMC_PREFIX" "$entry"; then
      echo -e "${AQUA}$index${RESET}: ${entry#$MMC_PREFIX}"
    else
      echo -e "${AQUA}$index${RESET}: $entry"
    fi
    ((++index))
  done
}

while [[ true ]]; do
  awaitUserInput
done

