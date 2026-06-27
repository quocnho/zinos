# Restore SELinux labels after flatpak installation
%post --erroronfail --log=/tmp/flatpak_selinux.log
restorecon -R /var/lib/flatpak 2>/dev/null || true
%end
