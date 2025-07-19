# connect to internet using `wpa_cli -i interface`

> Video reference to help: https://youtu.be/QGyHDIYlLFA?si=hCEJR7oWcJ-tR1Tk

Check wireless interface with `ip link`

## Summary

To connect to a Wi-Fi network in `wpa_cli`’s interactive mode, first run `wpa_cli -i <interface>` to start the client with your wireless interface selected ([sirlagz.net][1]). Then trigger a scan with `scan` and display nearby networks using `scan_results` ([mankier.com][2]). Once you have the SSID you want, use `add_network` to create a new profile and note its network ID ([rbftech.com][3]). Next, configure that profile with `set_network <id> ssid "<SSID>"` and `set_network <id> psk "<passphrase>"` ([cnblogs.com][4]). Finally, bring up the connection with `enable_network <id>` or `select_network <id>`, save your settings with `save_config`, and exit with `quit` ([cnblogs.com][4], [mankier.com][2]).

## 1. Launching `wpa_cli` in Interactive Mode

1. **Start the client**

   ```bash
   wpa_cli -i wlan0
   ```

   This command opens a prompt bound to `wlan0`, where you can enter commands interactively ([sirlagz.net][1]).

2. **Verify prompt**
   At the prompt, you should see something like:

   ```
   Selected interface 'wlan0'
   >
   ```

   This confirms you’re in interactive mode ([sirlagz.net][1]).

## 2. Scanning for Networks

1. **Initiate a scan**

   ```
   > scan
   ```

   This requests wpa\_supplicant to scan for nearby access points ([mankier.com][2]).

2. **List scan results**

   ```
   > scan_results
   ```

   You’ll see lines formatted as:

   ```
   bssid / frequency / signal level / flags / ssid
   ```

   This lists all detected networks with their identifiers and names ([mankier.com][2]).

## 3. Selecting and Connecting to a Network

1. **Create a new network profile**

   ```
   > add_network
   ```

   The client returns a network ID (e.g., `0`) that you’ll use for subsequent commands ([rbftech.com][3]).

2. **Set the SSID**

   ```
   > set_network 0 ssid "MyNetworkSSID"
   ```

   Wrap the SSID in quotes if it contains spaces or special characters ([cnblogs.com][4]).

3. **Set the passphrase**

   ```
   > set_network 0 psk "MySecretPass"
   ```

   This writes the pre-shared key for WPA/WPA2 networks ([cnblogs.com][4]).

4. **Enable or select the network**

   * **Enable** (allows multiple profiles):

     ```
     > enable_network 0
     ```
   * **Select** (exclusively use this one):

     ```
     > select_network 0
     ```

   Both commands trigger association with the chosen SSID ([cnblogs.com][4]).

5. **Verify connection status**

   ```
   > status
   ```

   Look for `wpa_state=COMPLETED` or `ip_address=...` to confirm success ([mankier.com][2]).

## 4. Saving and Exiting

1. **Persist configuration**

   ```
   > save_config
   ```

   This writes your network block into `/etc/wpa_supplicant.conf` for automatic reconnection on reboot ([cnblogs.com][4]).

2. **Exit interactive mode**

   ```
   > quit
   ```

   This closes `wpa_cli` and returns you to the shell ([mankier.com][2]).

---

By following these steps in interactive mode, you can scan, select, and connect to any WPA-protected Wi-Fi network using `wpa_cli` without editing configuration files by hand.

[1]: https://sirlagz.net/2012/08/27/how-to-use-wpa_cli-to-connect-to-a-wireless-network/ "How To : Use wpa_cli To Connect To A Wireless Network – The Rantings ..."
[2]: https://www.mankier.com/8/wpa_cli "wpa_cli: WPA command line client | wpa_supplicant System ... - ManKier"
[3]: https://www.rbftech.com/2016/05/how-to-use-wpacli-to-connect-to.html "How To : Use wpa_cli To Connect To A Wireless Network using terminal ..."
[4]: https://www.cnblogs.com/lifexy/p/10180653.html "49.Linux-wpa_cli使用之WIFI开启,扫描热点,连接热点,断开热点,WIFI关闭 (49)"
