# NetworkManager: Install and Configure on Void


`nmtui` is just a front-end; it needs the **NetworkManager daemon** to be up first.
On a fresh Void install that usually just means you haven’t enabled the runit service yet.

---

### 1. Make sure the service is installed

```sh
xbps-query -Rs NetworkManager      # should list network-manager package
sudo xbps-install -Su network-manager network-manager-applet
```

(You don’t strictly need the *applet* for `nmtui`, but it confirms the right meta-package is there.)

---

### 2. Enable and start NetworkManager (runit)

```sh
sudo ln -s /etc/sv/NetworkManager /var/service      # enable
sudo sv up NetworkManager                           # start immediately
```

You can check it with:

```sh
sv status NetworkManager
```

You should see something like `run: NetworkManager: (pid 1234) ...`.

---

### 3. Make sure its dependencies are running

NetworkManager talks over **D-Bus** and often needs **polkit** (for permission prompts):

```sh
sudo ln -s /etc/sv/dbus     /var/service
sudo ln -s /etc/sv/polkitd  /var/service
sudo sv up dbus polkitd
```

If you use Wi-Fi, also enable `wpa_supplicant` (NetworkManager will start its own instance, but the service provides the binary):

```sh
sudo ln -s /etc/sv/wpa_supplicant /var/service
```

---

### 4. Disable any old network service that might conflict

```sh
sudo sv down dhcpcd
sudo rm /var/service/dhcpcd         # if you plan to let NM handle DHCP
```

---

### 5. Try again

```sh
nmtui
```

You should now get the menu instead of “could not contact NetworkManager”.

---

### 6. (Optional) make the change stick after reboot

Because you created the symlinks under `/var/service`, runit will auto-start them on every boot, so you’re all set.

---

#### If it still fails…

* **Check logs** – `sudo tail -f /var/log/NetworkManager`
* **Confirm D-Bus is alive** – `busctl` should return without error.
* **Wayland session** won’t affect `nmtui`, but if you later want a systray applet on Wayland you’ll need a notification/indicator host (e.g. Waybar’s tray module).

Give those steps a whirl and let me know where it gets stuck—happy to dig further if something still misbehaves.
