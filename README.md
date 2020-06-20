# sesopenko/vfio-docker-builder

Deterministically builds the [tianocore edk2 vfio firmware](https://github.com/tianocore/edk2) for usage with [libvirt](https://libvirt.org/index.html) [qemu](https://www.qemu.org/)/[kvm](https://www.linux-kvm.org/page/Main_Page) on a linux environment using Docker.  It builds the vUDK2018 branch.

I needed a [EFI](https://en.wikipedia.org/wiki/Unified_Extensible_Firmware_Interface) compatible firmware for [VFIO](https://www.kernel.org/doc/Documentation/vfio.txt) passthrough of [IOMMU](https://en.wikipedia.org/wiki/Input%E2%80%93output_memory_management_unit) groups (for [gpu passthrough](https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF)) in a linux host environment and this was the easiest way to do it on any host system.



## Dependencies

### The following needs to be installed:

* [docker](https://docs.docker.com/get-docker/)
* [make](https://www.gnu.org/software/make/)

### Docker Images

The following docker images are utilized

* [3mdeb/edk2](https://hub.docker.com/r/3mdeb/edk2)


## Instructions

1. `make`
2. `cp edk2/build/*.fd your_target_dir/`

### Output

The build process produces two files, a read-only bios firmware (`OVMF_CODE.fd`) and a template variables file (`OVFM_VARS.fd`). Check your virtualization stack's documentation on how to use the two files split.

### Example libvirtd `xml` config

Here's an example configuration for libvirtd:

```xml
<os>
<!-- pcie passthrough needs the q35 machine. Your machine name may be different. -->
<type arch="x86_64" machine="pc-q35-4.2">hvm</type>
<!-- This is the firmware code which will be executed -->
<loader readonly="yes" type="pflash">change_to_your_location/OVMF_CODE.fd</loader>
<!-- This directive will result in libvirt copying the vars file to your destination and saves to the firmware will update the copied file, not the original -->
<nvram template="change_to_your_location/OVMF_VARS.fd">change_to_where_you_want_the_working_copy/MyVMName_VARS.fd</nvram>
<boot dev="cdrom"/>
</os>
```

### Example with `virt-install`

Here are example params for `virt-install` (the rest of the params are up to you). In this example I set up gpu, nvme and usb root hub passthrough for a win10 guest on my host bridge. (You need to use a `system` connection to libvirt for gpu passthrough to work!).

```bash
#!/bin/bash
NAME="WindowsTest"
ISO_LOC=/mnt/zpool/spinning1/isos
INSTALLER=$ISO_LOC/win10_64_2004.iso
RAM=8092
# Use `osinfo-query os` to get os variants
OS_VARIANT="win10"

# Get hardware ids with `virsh nodedev-list --tree`
# Compare with lspci -nnv and iommmu-groupings

NVIDIA_HW_ID=pci_0000_08_00_0
NVIDIA_HW_ID_SOUND=pci_0000_08_00_1
NVME1_HW_ID=pci_0000_07_00_0
NVME2_HW_ID=pci_0000_41_00_0
USB_HWID=pci_0000_44_00_3

FIRMWARE_DIR=$PWD/firmware
BIOS_CODE=$FIRMWARE_DIR/OVMF_CODE.fd
BIOS_VARS=$FIRMWARE_DIR/OVMF_VARS.fd

virt-install \
        --connect qemu:///system \
        --virt-type kvm \
        --name $NAME \
        --ram $RAM \
        --boot cdrom,loader=$BIOS_CODE,loader_ro=yes,loader_type=pflash,nvram_template=$BIOS_VARS \
        --cdrom $INSTALLER \
        --network network=host-bridge,mac=52:54:00:9c:94:3b \
        --nographics \
        --host-device=$NVIDIA_HW_ID \
        --host-device=$NVIDIA_HW_ID_SOUND \
        --host-device=$NVME1_HW_ID \
        --host-device=$NVME2_HW_ID \
        --host-device=$USB_HWID \
        --nodisks \
        --os-variant $OS_VARIANT


```

Note that your virtualization stack can have conflicting boot directives with the boot setup you store in your firmware (if you edit the boot order menu for instance). Check your virtualization stack's documentation to figure out how to get a working boot order after you install your OS (if you run into problems).

Some guest OS's handle this more gracefully than other (ie: Centos 8 does this better than Ubuntu 20.04 in my experience).

## License

This software is licensed under the Apache License which may be read in [LICENSE.txt](LICENSE.txt) or directly at [apache.org](https://www.apache.org/licenses/LICENSE-2.0.txt).

## No Warranty

No warranty is provided nor implied. This project depends on external dependencies I have no control over so run your VMs and docker images safely!