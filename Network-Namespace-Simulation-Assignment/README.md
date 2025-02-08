
# Prerequisites

* Linux system with kernel version 5.x or later
* Root privileges
* Required packages:
    * iproute2
    * bridge-utils
    * iptables



# Installation

1. Clone the repository:

```
clone https://github.com/yourusername/network-namespace-script.git
cd network-namespace-script
```

2. Make the script executable:
```
chmod +x script.sh
```

# Usage
The script supports the following commands:

1. Setup the network:

```
sudo  ./script.sh setup
```

2. Test network connectivity:

```
sudo  ./script.sh ping
```

3. View current network status:

```
sudo  ./script.sh status
```

4. Clean up the network configuration:
```
sudo  ./script.sh cleanup
```

## Command Overview

| Command  | Description |
|----------|------------|
| `setup`  | Creates and configures network namespaces, bridges, and routing |
| `ping`   | Tests connectivity between namespaces |
| `status` | Shows current network configuration and routing tables |
| `cleanup` | Removes all created network configurations |

# Diagram

```mermaid
graph TD
    subgraph Network Topology
        br0[Bridge br0<br/>10.11.0.1/24]
        br1[Bridge br1<br/>10.12.0.1/24]
        
        subgraph Namespace ns1
            ns1[ns1<br/>10.11.0.2/24]
        end
        
        subgraph Namespace ns2
            ns2[ns2<br/>10.12.0.2/24]
        end
        
        subgraph Router Namespace
            router[router-ns<br/>eth1: 10.11.0.3/24<br/>eth2: 10.12.0.3/24]
        end
        
        ns1 ---|v-red-ns/v-red| br0
        ns2 ---|v-blue-ns/v-blue| br1
        br0 ---|v1-bridge/v1-router| router
        br1 ---|v2-bridge/v2-router| router
    end
```
