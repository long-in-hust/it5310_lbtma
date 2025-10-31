# it5310_lbtma
---

This is just a reconstructed compilation.

### Original Repositories:
[P4-STM](https://github.com/Ameer-91/Source-Code-Implementation-for-the-P4-STM-Module)
[P4-DLBS](https://github.com/Ameer-91/Source-Code-Implementation-for-the-P4-DLBS-Module)
[P4-DPADS](https://github.com/Ameer-91/Source-Code-Implementation-for-the-P4-DPADS-Module)

# Pre-requisites

### Enable port forwarding

Edit /etc/sysctl.conf and search for the following lines:
```
# Uncomment the next line to enable packet forwarding for IPv4
#net.ipv4.ip_forward=1
```
Uncomment net.ipv4.ip_forward=1:

```
# Uncomment the next line to enable packet forwarding for IPv4
net.ipv4.ip_forward=1
```

Or in one line command :
```
sudo sysctl -w net.ipv4.ip_forward=1
```

### Create virtual eth

- **For the P4-STM module:**

Since the switch uses two ports, we creates two virtual ethernet interfaces `veth0` and `veth1`:

```
sudo ip link add veth0 type veth peer name veth1
```

Turn the interfaces on:

```
sudo ip link set dev veth0 up
sudo ip link set dev veth1 up
```