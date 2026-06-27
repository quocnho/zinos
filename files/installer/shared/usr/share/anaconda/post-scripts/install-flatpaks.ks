# Install flatpaks from the ISO's flatpak list
%post --erroronfail --log=/tmp/flatpak_install.log
FLATPAK_LIST="/run/install/repo/installer/flatpaks"

if [[ -f "$FLATPAK_LIST" ]]; then
    echo "Installing Flatpaks from $FLATPAK_LIST..."
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        app="${line#app/}"
        flatpak install --system --noninteractive flathub "$app" 2>/dev/null || true
    done < "$FLATPAK_LIST"
    echo "Flatpak installation complete."
else
    echo "No flatpak list found at $FLATPAK_LIST, skipping."
fi
%end
