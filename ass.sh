#!/bin/sh

PROJECT_ROOT="${PWD}"
SCRIPT_NAME=$(basename "$0")
LTS_SUPPORT="" #-lts
USER_NAME=$(whoami)

declare -a PACKAGES=(
	"archlinux-keyring"
	"base-devel"
	"bat"
	"blueman"
	"bluez"
	"bluez-libs"
	"caja"
	"conky"
	"curl"
	"dnsmasq"
	"dunst"
	"engrampa"
	"eom"
	"ffmpegthumbnailer"
	"fzf"
	"fluxbox"
	"git"
	"glow"
	"gnome-keyring"
	"gnupg"
	"gsimplecal"
	"gufw"
	"htop"
	"hsetroot"
	"jq"
	"linux$LTS_SUPPORT"
	"linux$LTS_SUPPORT-headers"
	"lib32-gnutls"
	"lib32-vulkan-icd-loader"
	"lib32-vkd3d"
	"lib32-gst-plugins-good"
	"lib32-libjpeg-turbo"
	"lib32-libpng"
	"lib32-mpg123"
	"lib32-nvidia-utils"
	"lib32-openal"
	"lib32-sdl2"
	"libjpeg6-turbo"
	"mate-polkit"
	"mc"
	"micro"
	"most"
	"mpg123"
	"mpv"
	"ncdu"
	"network-manager-applet"
	"ntfs-3g"
	"nvidia$LTS_SUPPORT"
	"nvidia-settings"
	"nvidia-utils"
	"openal"
	"openssh"
	"openssl"
	"opusfile"
	"p7zip"
#	"pass"
	"pavucontrol"
#	"picom"
	"pluma"
	"projectm"
	"projectm-pulseaudio"
	"pulseaudio"
	"pulseaudio-alsa"
	"pulseaudio-bluetooth"
	"qemu"
	"qemu-arch-extra"
	"qt5ct"
	"qtcurve-qt5"
	"redshift"
#	"ripgrep"
	"rofi"
	"solaar"
	"steam"
	"tmux"
	"tree"
	"thunderbird"
	"unrar"
	"unzip"
	"unclutter"
	"virt-manager"
	"vulkan-icd-loader"
	"vulkan-tools"
	"vkd3d"
	"vnstat"
	"volumeicon"
#	"wmctrl"
	"xbindkeys"
	"xclip"
	"xcursor-vanilla-dmz-aa"
	"xorg-server"
	"xorg-setxkbmap"
	"xorg-xbacklight"
	"xorg-xdm"
	"xsel"
	"xterm"
	"youtube-dl"
	"yad"
)

declare -a ABS=(
    "aic94xx-firmware"
    "brave-bin"
#	"pass-coffin"
	"visual-studio-code-bin"
    "wd719x-firmware"
)

function check_previleges () {
    printf "\nValidating run previleges... user $USER_NAME ("$EUID")\n"
    if [ "$EUID" -eq 0 ]
      then printf "Please run as a regular user to continue...\n\n"
      exit
    fi
}

function update_system () {
    printf "\nUpdating system...\n"
    sudo pacman -Suyq --color=always --noconfirm
}

function process_pacman () {
    printf "\nInstalling Pacman packages...\n"
    for PACKAGE in "${PACKAGES[@]}"; do
        printf "$PACKAGE\n"
        sudo pacman -S --color=always --noconfirm "$PACKAGE"
    done
}

function install_yay () {
    printf "\nInstalling yay...\n"
    cd "${PROJECT_ROOT}"
    git clone https://aur.archlinux.org/yay 
    cd yay
    makepkg -sirc --noconfirm
    cd "${PROJECT_ROOT}"
}

function process_abs () {
    printf "\nInstalling ABS (yay) packages...\n"
    for PACKAGE in "${ABS[@]}"; do
        printf "$PACKAGE\n"
        yay -S --noconfirm "$PACKAGE"
    done
}

# --- TROUBLE AHEAD ---------------------------------------------------------------------------
#
#

function configure_system () {
    printf "\nConfiguring system...\n"
    sudo cp -r -v "${PROJECT_ROOT}"/etc/* /etc/
    sudo cp -r -v "${PROJECT_ROOT}"/usr/* /usr/
	sudo cp -r -v "${PROJECT_ROOT}"/boot/* /boot/
    sudo systemctl enable xdm
    sudo systemctl enable bluetooth
    sudo systemctl enable ufw
    sudo systemctl enable libvirtd
    sudo systemctl enable NetworkManager
    sudo vnstat --add -i $(ip -o link show | awk '{print $2,$9}' | grep UP | awk '{print $1}' | sed 's/://')
    sudo systemctl enable vnstat
    sudo systemctl restart vnstat
    sudo mkinitcpio -p linux$LTS_SUPPORT
}

function configure_user () {
    printf "\nConfiguring user accounts...\n"
    systemctl --user enable pulseaudio
    systemctl --user start pulseaudio
    pactl set-sink-mute @DEFAULT_SINK@ toggle
    pactl -- set-sink-volume @DEFAULT_SINK@ 80%
    eval $(ssh-agent)
	systemctl --user enable gpg-agent.socket
	mkdir -p ~/.gnupg && chmod 700 ~/.gnupg
	gpg --import /backup/.keys/privkey.asc
	gpg --import /backup/.keys/public.key
	mkdir -p ~/.ssh && touch ~/.ssh/known_hosts && ssh-keyscan -t Ed25519 github.com > ~/.ssh/known_hosts
    ssh-add /backup/.keys/qwertzy-antonio-godinho-github.com
}

function cleanup () {
    printf "\nCleaning up the system...\n"
    sudo pacman -Rus --color=always --noconfirm vim
    rm -rf "${PROJECT_ROOT}"/yay
    yay -Yc --noconfirm
}

printf "\n${SCRIPT_NAME} - Automated System Setup\n"
check_previleges
update_system
process_pacman
install_yay
process_abs
configure_system
configure_user
cleanup
printf "\n /// FINISHED ${SCRIPT_NAME} ///\n\n"
while true; do
    read -p "Do you wish to reboot the system? " yn
    case $yn in
        [Yy]* ) reboot; break;;
        [Nn]* ) exit;;
        * ) echo "Please type [Y/y] yes or [N/n] no.";;
    esac
done
