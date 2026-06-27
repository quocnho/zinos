# Disable Fedora's flatpak repo in favor of Flathub
%post --nochroot --erroronfail --log=/tmp/flatpak_disable_fedora.log
rm -f /run/installation/root_tree/usr/share/flatpak/remotes.d/fedora* 2>/dev/null || true
rm -rf /run/installation/root_tree/etc/flatpak/remotes.d/ 2>/dev/null || true
%end
