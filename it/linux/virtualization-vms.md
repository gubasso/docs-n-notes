# Virtualization / VMs


## Virtualization with KVM/QEMU

To instantiate an openSUSE Tumbleweed virtual machine (VM) locally using KVM from the command line, you can follow these steps. This guide assumes you're using a Linux host system that supports KVM virtualization.


2. **Install Necessary Packages:**
Ensure that KVM, QEMU, and related virtualization tools are installed on your host system.
**On openSUSE Host:**

```bash
sudo zypper refresh
sudo zypper install -t pattern kvm_server kvm_tools
```

3. **Add User to Required Groups:** Add your user to the `libvirt` and `kvm` groups to manage virtualization without root privileges.

```bash
sudo usermod -aG libvirt,kvm $USER
```
**Reload the group membership:**

```bash
newgrp libvirt
newgrp kvm
```

4. **Enable and Start libvirtd Service:**

```bash
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
```

**Step-by-Step Guide to Instantiate the VM**

**1. Download the openSUSE Tumbleweed ISO**
Navigate to the directory where you want to store the ISO and download it.

```bash
cd ~/Downloads
wget https://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso
```
Alternatively, you can visit the [openSUSE Tumbleweed download page]()  to get the latest ISO.

**2. Create a Virtual Disk Image** Create a virtual disk for your VM using `qemu-img`.

```bash
# Set the location and size of the disk image
DISK_PATH="/var/lib/libvirt/images/opensuse-tumbleweed.qcow2"
sudo mkdir -p $(dirname $DISK_PATH)
sudo chown $USER: $(dirname $DISK_PATH)

# Create a 20GB QCOW2 disk image
qemu-img create -f qcow2 $DISK_PATH 20G
```
**3. Install the VM Using virt-install** Use the `virt-install` command to set up and start the VM installation.

```bash
virt-install \
  --name opensuse-tumbleweed \
  --ram 2048 \
  --vcpus 2 \
  --disk path=$DISK_PATH,size=20,format=qcow2 \
  --os-type linux \
  --os-variant opensuse-tumbleweed \
  --network default \
  --graphics vnc \
  --cdrom ~/Downloads/openSUSE-Tumbleweed-DVD-x86_64-Current.iso
```
**Explanation of Options:**
- `--name`: Assigns a name to the VM.
- `--ram`: Allocates memory in MB.
- `--vcpus`: Sets the number of virtual CPUs.
- `--disk`: Specifies disk path, size, and format.
- `--os-type`: Defines the OS type.
- `--os-variant`: Specifies the OS variant for optimization.
- `--network`: Connects the VM to the default network.
- `--graphics`: Sets up the graphical display method.
- `--cdrom`: Points to the installation ISO file.

**Note:**  The `--graphics vnc` option configures the VM to use VNC for the display. Ensure that your firewall allows VNC connections, or use SSH tunneling.**4. Access the VM Installation Interface** **Option 1: Using VNC Viewer**

1. **Find the VNC Display Port:**

```bash
virsh vncdisplay opensuse-tumbleweed
```
This command outputs something like `:0` or `:1`, which corresponds to port `5900` or `5901`.

2. **Connect with a VNC Client:**

```bash
vncviewer localhost:5900
```

Use any VNC client to connect to the display.

**Option 2: Using SSH Tunneling (Recommended for Remote Hosts)**

1. **Create an SSH Tunnel:**

```bash
ssh -L 5900:localhost:5900 user@host_ip
```

2. **Connect the VNC Client to Localhost:**

```bash
vncviewer localhost:5900
```

**5. Complete the openSUSE Tumbleweed Installation**

...

**6. Manage the VM After Installation** Once the installation is complete, you can manage the VM using `virsh`.

- **List VMs:**

```bash
virsh list --all
```

- **Start the VM:**

```bash
virsh start opensuse-tumbleweed
```

- **Shut Down the VM:**

```bash
virsh shutdown opensuse-tumbleweed
```

- **Force Stop the VM (if unresponsive):**

```bash
virsh destroy opensuse-tumbleweed
```

- **Remove/Delete the VM:**

```bash
virsh undefine opensuse-tumbleweed
rm -f $DISK_PATH
```

---

**Additional Configuration and Tips** **Accessing the VM Console**
You can access the serial console if you have configured it during installation.

```bash
virsh console opensuse-tumbleweed
```

To enable serial console access:

1. **Edit the VM's XML Configuration:**

```bash
virsh edit opensuse-tumbleweed
```

2. **Add Serial Console Configuration:** Add the following within the `<devices>` section:

```xml
<console type='pty'>
  <target type='serial' port='0'/>
</console>
```

3. **Configure Grub in the VM:**
  - Edit `/etc/default/grub` in the VM and add:

```bash
GRUB_CMDLINE_LINUX="console=tty0 console=ttyS0,115200n8"
```

  - Update Grub:


```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```
**Networking Options**
- **Default NAT Networking:**
The default network uses NAT, allowing the VM to access external networks but not be directly accessible from the host or external networks.

- **Bridged Networking:**
If you need the VM to be on the same network as the host, configure bridged networking.
**Configure a Bridge Interface:**

```bash
sudo nmcli connection add type bridge autoconnect yes con-name br0 ifname br0
sudo nmcli connection modify br0 ipv4.addresses "192.168.1.100/24" ipv4.gateway "192.168.1.1" ipv4.method manual
sudo nmcli connection modify br0 ipv4.dns "8.8.8.8,8.8.4.4"
```
**Attach VM to Bridge:** Modify the `virt-install` command:

```bash
--network bridge=br0
```
**Automating VM Installation with Kickstart or AutoYaST**
For unattended installations, use AutoYaST files to automate the installation process.

- **Create an AutoYaST File:**
Generate an AutoYaST XML configuration file based on your preferences.

- **Modify virt-install Command:**

```bash
virt-install \
  --name opensuse-tumbleweed \
  --ram 2048 \
  --vcpus 2 \
  --disk path=$DISK_PATH,size=20,format=qcow2 \
  --os-type linux \
  --os-variant opensuse-tumbleweed \
  --network default \
  --graphics none \
  --location 'http://download.opensuse.org/tumbleweed/repo/oss/' \
  --initrd-inject=/path/to/autoinst.xml \
  --extra-args 'autoyast=file:/autoinst.xml console=ttyS0,115200n8 serial'
```
**Using Cloud Images**
Alternatively, you can use pre-built openSUSE Tumbleweed cloud images.

1. **Download the Cloud Image:**

```bash
wget https://download.opensuse.org/repositories/Cloud:/Images:/Tumbleweed/images/openSUSE-Tumbleweed-JeOS.x86_64-kvm-and-xen.qcow2
```

2. **Resize the Image (if necessary):**

```bash
qemu-img resize openSUSE-Tumbleweed-JeOS.x86_64-kvm-and-xen.qcow2 +10G
```

3. **Create a Cloud-Init Config Drive (Optional):**
If you need to configure the VM using cloud-init.

4. **Define and Start the VM:**

```bash
virt-install \
  --name opensuse-tumbleweed \
  --ram 2048 \
  --vcpus 2 \
  --disk path=./openSUSE-Tumbleweed-JeOS.x86_64-kvm-and-xen.qcow2,format=qcow2 \
  --os-type linux \
  --os-variant opensuse-tumbleweed \
  --network default \
  --graphics none \
  --import
```


---

**Troubleshooting**
- **Permissions Issues:** Ensure your user is part of the `libvirt` and `kvm` groups.

```bash
sudo usermod -aG libvirt,kvm $USER
newgrp libvirt
newgrp kvm
```

- **SELinux/AppArmor Restrictions:**
If SELinux or AppArmor is enforcing, you might need to adjust policies or set them to permissive mode.

- **OS Variant Not Recognized:** If `opensuse-tumbleweed` is not recognized, use `opensuse-leap` or `generic` as the OS variant.

```bash
osinfo-query os | grep -i opensuse
```

- **VNC Connection Refused:**
  - Ensure the VM is running and listening on the expected VNC port.

  - Check firewall settings to allow VNC traffic.

  - Use SSH tunneling to securely connect to the VNC session.


---

**Managing VMs with virsh**
- **List All VMs:**

```bash
virsh list --all
```

- **Get VM Information:**

```bash
virsh dominfo opensuse-tumbleweed
```

- **Define or Undefine VMs:**

```bash
virsh define /path/to/opensuse-tumbleweed.xml
virsh undefine opensuse-tumbleweed
```

- **Clone a VM:**

```bash
virt-clone --original opensuse-tumbleweed --name opensuse-tumbleweed-clone --file /var/lib/libvirt/images/opensuse-tumbleweed-clone.qcow2
```


---

**Alternative: Using virt-manager (GUI)**
If you prefer a graphical interface and have a desktop environment:

1. **Install virt-manager:**

```bash
sudo zypper install virt-manager
```

2. **Launch virt-manager:**

```bash
virt-manager
```

3. **Create a New VM:**
  - Click on **"Create a new virtual machine"** .

  - Follow the prompts to specify installation media, allocate resources, and configure storage and networking.


---

**Conclusion**
By following these steps, you can successfully instantiate an openSUSE Tumbleweed VM using KVM from the command line. This setup allows you to test, develop, or run applications in an isolated environment that closely mimics a physical machine.


---

**References and Further Reading**
- **openSUSE Documentation:**
  - [Virtualization Guide]()

- **Libvirt and KVM Resources:**
  - [Libvirt Documentation]()

  - [KVM Documentation]()

- **Useful Commands:**
  - List OS variants:


```bash
osinfo-query os
```

  - Check virtualization support:


```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```

A non-zero output indicates that your CPU supports virtualization.

## How do I access this VM with ssh? Find VM IP

**Step 1: Ensure the VM Is Running** 
First, verify that your VM is currently running.


```bash
virsh list --all
```
You should see your VM `opensuse-tumbleweed` listed with the state **running** . If it's not running, start it with:

```bash
virsh start opensuse-tumbleweed
```


---

**Step 2: Find the VM's IP Address** Since the VM is connected to the default virtual network (`default`), you can find its IP address using one of the following methods.Option A: Using `virsh domifaddr`** 

```bash
virsh domifaddr opensuse-tumbleweed
```
This command displays the IP addresses assigned to the VM. Look for an entry with the `ipv4` type.**Example Output:** 

```markdown
Name       MAC address          Protocol     Address
-------------------------------------------------------------------------------
vnet0      52:54:00:12:34:56    ipv4         192.168.122.100/24
```
Option B: Using `virsh net-dhcp-leases`** 

```bash
virsh net-dhcp-leases default
```
This command lists the DHCP leases for the `default` network. Find the lease associated with your VM's MAC address.**Example Output:** 

```css
Expiry Time          MAC address        Protocol  IP address        Hostname
--------------------------------------------------------------------------------
2023-10-05 12:34:56  52:54:00:12:34:56  ipv4      192.168.122.100/24  opensuse-tumbleweed
```
**Option C: Check Inside the VM via VNC** Since you installed the VM with VNC graphics (`--graphics vnc`), you can connect to the VM's console to find the IP address. 
1. **Find the VNC Display Port:** 

```bash
virsh vncdisplay opensuse-tumbleweed
```
This will output something like `:0`, `:1`, etc.
 
2. **Connect to the VM Using a VNC Client:**  
  - If the output is `:0`, the VNC port is `5900 + display number`, so port `5900`.
 
  - Use a VNC client to connect:


```bash
vncviewer localhost:5900
```
Or for display `:1`:

```bash
vncviewer localhost:5901
```
 
  - **Note:**  If you're connecting remotely, you may need to set up SSH tunneling to securely access the VNC session.
 
3. **Find the VM's IP Address Inside the VM:**  
  - Log in to the VM using your credentials.
 
  - Run the following command:


```bash
ip addr show
```
 
  - Look for the IP address under the network interface, typically named `eth0` or `ens3`.


---

**Step 3: Ensure SSH Is Enabled in the VM** 
Inside the VM, make sure that the SSH server is installed and running.
**1. Check if SSH Server Is Installed** 

```bash
sudo zypper install openssh
```

- If it's already installed, zypper will inform you.

- If not, it will proceed to install it.
**2. Enable and Start the SSH Service** 

```bash
sudo systemctl enable sshd
sudo systemctl start sshd
```
**3. Verify the SSH Service Status** 

```bash
sudo systemctl status sshd
```
 
- Ensure the service is **active (running)** .


---

**Step 4: Adjust Firewall Settings Inside the VM** 
To allow SSH connections, the firewall inside the VM must permit SSH traffic.
**1. Check Current Firewall Settings** 

```bash
sudo firewall-cmd --list-all
```
 
- Look under `services:` to see if `ssh` is listed.
**2. Add SSH Service to the Firewall** 
If SSH is not listed, add it:


```bash
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload
```
**3. Verify the Firewall Configuration** 

```bash
sudo firewall-cmd --list-all
```
 
- Confirm that `ssh` now appears under `services:`.


---

**Step 5: SSH into the VM from the Host Machine** 
Now that you have the VM's IP address and SSH is configured, you can connect to it from your host machine.
**1. Test Connectivity** 
First, ensure that your host can reach the VM.


```bash
ping -c 4 <vm_ip_address>
```
 
- Replace `<vm_ip_address>` with the IP address you obtained earlier.

- If the ping is successful, proceed to SSH.
**2. Connect via SSH** 

```bash
ssh username@<vm_ip_address>
```
 
- Replace `username` with your user account in the VM.
 
- Replace `<vm_ip_address>` with the VM's IP address.
**Example:** 

```bash
ssh john@192.168.122.100
```
**3. Accept the SSH Host Key** 
On first connection, you'll be prompted to accept the SSH host key:


```vbnet
The authenticity of host '192.168.122.100 (192.168.122.100)' can't be established.
ECDSA key fingerprint is SHA256:...
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```
 
- Type `yes` and press **Enter** .
**4. Enter Your Password** 

```css
john@192.168.122.100's password:
```

- Enter the password you set for the user during installation.


---

**Step 6: Optional - Set Up SSH Key Authentication** 
For convenience and enhanced security, you can set up SSH key-based authentication.
**1. Generate an SSH Key Pair on the Host** 
If you don't already have an SSH key pair:


```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```
 
- Press **Enter**  to accept the default file location.

- Set a passphrase if desired.
**2. Copy Your Public Key to the VM** 

```bash
ssh-copy-id username@<vm_ip_address>
```

- Enter your password when prompted.
**3. Test SSH Key Authentication** 

```bash
ssh username@<vm_ip_address>
```

- You should now connect without needing to enter your password.


---

**Additional Information** **Understanding the Default Network**  
- The `--network default` option connects the VM to the default libvirt network.
 
- The default network is typically a NAT network with the subnet `192.168.122.0/24`.

- The host machine can communicate with the VM using this network.
Using `virt-manager` (Optional GUI Tool)** 
If you prefer a graphical interface to manage your VMs:
 
1. **Install virt-manager:** 

```bash
sudo zypper install virt-manager
```
 
2. **Launch virt-manager:** 

```bash
virt-manager
```
 
3. **Use virt-manager to View VM Details:** 
  - You can view the VM's IP address, console, and other settings.
**Connecting to the VM Console via VNC**  
- **Find the VNC Port:** 

```bash
virsh vncdisplay opensuse-tumbleweed
```
 
- **Connect Using a VNC Client:** 

```bash
vncviewer localhost:5900  # Replace 5900 with the correct port
```
**Troubleshooting SSH Connection Issues**  
- **Cannot Ping VM:** 
  - Check if the VM's firewall is blocking ICMP (ping) requests.

  - Ensure that the network is correctly configured.
 
- **SSH Connection Refused:** 
  - Verify that the SSH service is running inside the VM.

  - Ensure that SSH is allowed through the VM's firewall.
 
- **Host Cannot Reach VM's IP Address:**  
  - Confirm that the default network is active:


```bash
virsh net-list --all
```
 
  - If the `default` network is inactive, start it:

```bash
virsh net-start default
```
 
- **SSH Times Out or Hangs:** 
  - Check for network issues between the host and VM.

  - Verify that the VM's IP address hasn't changed.


---

**Alternative: Using Port Forwarding** 
If you prefer to use port forwarding instead of connecting via the VM's IP address:
**1. Modify the VM's Network Configuration** 
You can add port forwarding rules to the default network by editing its XML configuration. However, this method is more complex and not generally recommended for beginners.
**2. Use User-Mode Networking with Port Forwarding** 
Alternatively, you can create a new network configuration or modify your VM to use user-mode networking with port forwarding. This would involve more advanced steps and is not necessary if you can connect via the default network.


---

**Conclusion** 
By following these steps, you should be able to access your openSUSE Tumbleweed VM via SSH from your host machine. Remember to ensure that the SSH service is running and that the firewall settings inside the VM allow SSH connections.


---

If you encounter any issues or have further questions, feel free to ask for additional assistance!

