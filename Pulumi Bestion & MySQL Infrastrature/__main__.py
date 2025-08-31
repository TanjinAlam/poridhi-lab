import pulumi
import pulumi_aws as aws
import os

config = pulumi.Config()
allowed_ip = config.get("allowedIp") or "0.0.0.0/0"
ssh_public_key = config.get("sshPublicKey")

# APPROACH 1: Using your own public key (recommended)
# When you provide a public_key, AWS just stores it - no private key is generated
if ssh_public_key:
    bastion_key_pair = aws.ec2.KeyPair(
        "bastion-host",
        key_name="bastion-host",
        public_key=ssh_public_key,
        tags={"Name": "bastion-host"},
    )
    
    private_key_pair = aws.ec2.KeyPair(
        "private-host", 
        key_name="private-host",
        public_key=ssh_public_key,  # Same public key for both
        tags={"Name": "private-host"},
    )
    
    # Export the key names for reference
    pulumi.export("bastion_key_name", bastion_key_pair.key_name)
    pulumi.export("private_key_name", private_key_pair.key_name)
    pulumi.export("ssh_instruction", "Use your existing private key that corresponds to the provided public key")


# Create a VPC
vpc = aws.ec2.Vpc(
    "nodejs-db-vpc",
    cidr_block="10.0.0.0/16",
    enable_dns_support=True,
    enable_dns_hostnames=True,
    tags={"Name": "nodejs-db-vpc"},
)

# Create public and private subnets
public_subnet = aws.ec2.Subnet(
    "nodejs-public-subnet",
    vpc_id=vpc.id,
    cidr_block="10.0.1.0/24",
    map_public_ip_on_launch=True,
    availability_zone="ap-southeast-1a",
    tags={"Name": "nodejs-public-subnet"},
)

private_subnet = aws.ec2.Subnet(
    "db-private-subnet",
    vpc_id=vpc.id,
    cidr_block="10.0.2.0/24",
    map_public_ip_on_launch=False,
    availability_zone="ap-southeast-1a",
    tags={"Name": "db-private-subnet"},
)

# Create an Internet Gateway
internet_gateway = aws.ec2.InternetGateway(
    "nodejs-db-internet-gateway",
    vpc_id=vpc.id,
    tags={"Name": "nodejs-db-internet-gateway"},
)

# Create NAT Gateway for private subnet
elastic_ip = aws.ec2.Eip("nat-eip")

nat_gateway = aws.ec2.NatGateway(
    "nat-gateway",
    allocation_id=elastic_ip.id,
    subnet_id=public_subnet.id,
    tags={"Name": "nodejs-db-nat-gateway"},
)

# Create public Route Table
public_route_table = aws.ec2.RouteTable(
    "public-route-table",
    vpc_id=vpc.id,
    routes=[
        aws.ec2.RouteTableRouteArgs(
            cidr_block="0.0.0.0/0",
            gateway_id=internet_gateway.id,
        )
    ],
    tags={"Name": "nodejs-public-route-table"},
)

# Create private Route Table
private_route_table = aws.ec2.RouteTable(
    "private-route-table",
    vpc_id=vpc.id,
    routes=[
        aws.ec2.RouteTableRouteArgs(
            cidr_block="0.0.0.0/0",
            nat_gateway_id=nat_gateway.id,
        )
    ],
    tags={"Name": "db-private-route-table"},
)

# Associate route tables with subnets
public_route_table_association = aws.ec2.RouteTableAssociation(
    "public-route-table-association",
    subnet_id=public_subnet.id,
    route_table_id=public_route_table.id,
)

private_route_table_association = aws.ec2.RouteTableAssociation(
    "private-route-table-association",
    subnet_id=private_subnet.id,
    route_table_id=private_route_table.id,
)

# Create security group for bastion host in public subnet
bastion_sg = aws.ec2.SecurityGroup(
    "bastion-sg",
    vpc_id=vpc.id,
    description="Security group for bastion host",
    ingress=[
        # SSH access from allowed IP
        aws.ec2.SecurityGroupIngressArgs(
            protocol="tcp",
            from_port=22,
            to_port=22,
            cidr_blocks=[allowed_ip],
        ),
    ],
    egress=[
        aws.ec2.SecurityGroupEgressArgs(
            protocol="-1",
            from_port=0,
            to_port=0,
            cidr_blocks=["0.0.0.0/0"],
        )
    ],
    tags={"Name": "bastion-sg"},
)

# Create security group for private instance (app-sg as per requirements)
app_sg = aws.ec2.SecurityGroup(
    "app-sg",
    vpc_id=vpc.id,
    description="Security group for private app instance",
    ingress=[
        # SSH access only from bastion security group
        aws.ec2.SecurityGroupIngressArgs(
            protocol="tcp",
            from_port=22,
            to_port=22,
            security_groups=[bastion_sg.id],
        ),
        # MySQL access from bastion for testing
        aws.ec2.SecurityGroupIngressArgs(
            protocol="tcp",
            from_port=3306,
            to_port=3306,
            security_groups=[bastion_sg.id],
        ),
    ],
    egress=[
        aws.ec2.SecurityGroupEgressArgs(
            protocol="-1",
            from_port=0,
            to_port=0,
            cidr_blocks=["0.0.0.0/0"],
        )
    ],
    tags={"Name": "app-sg"},
)

def bastion_server_config():
    return f"""#!/bin/bash
exec > >(tee /var/log/user-data.log) 2>&1

# Update system
apt-get update
apt-get upgrade -y

# Install MySQL client for testing
apt-get install -y mysql-client

# Create ops user (REQUIRED BY TASK 2)
useradd -m -s /bin/bash ops
usermod -aG sudo ops
mkdir -p /home/ops/.ssh

# Add SSH public key from Pulumi config to ops user (REQUIRED)
if [ -n "{ssh_public_key}" ]; then
    echo "{ssh_public_key}" >> /home/ops/.ssh/authorized_keys
    chown -R ops:ops /home/ops/.ssh
    chmod 700 /home/ops/.ssh
    chmod 600 /home/ops/.ssh/authorized_keys
    echo "SSH key added for ops user"
else
    echo "WARNING: No SSH public key provided in config!"
fi

# Disable root SSH login and password authentication (REQUIRED)
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh

# Create completion marker
touch /var/log/bastion-setup-complete
echo "Bastion hardening completed"
"""

# MySQL setup script content (embedded for reliability)
mysql_setup_script = """#!/bin/bash
exec > >(tee /var/log/mysql-setup.log) 2>&1

# Update system
apt-get update
apt-get upgrade -y

# Install MySQL Server
DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

# ========== SYSTEMD SERVICE MANAGEMENT ==========
# Start MySQL service immediately
systemctl start mysql

# Enable MySQL service for auto-start on boot
systemctl enable mysql

# Verify service is running and enabled
systemctl is-active mysql
systemctl is-enabled mysql

# Wait for service to be fully ready
sleep 10

# Verify MySQL is listening
netstat -tlnp | grep 3306 || ss -tlnp | grep 3306
# ================================================

# Get the private IP address (with IMDSv2 token support)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
if [ -n "$TOKEN" ]; then
    PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null)
else
    # Fallback to getting IP from network interface
    PRIVATE_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1 2>/dev/null)
    if [ -z "$PRIVATE_IP" ]; then
        PRIVATE_IP=$(ip addr show enX0 | grep "inet " | awk '{print $2}' | cut -d/ -f1 2>/dev/null)
    fi
    if [ -z "$PRIVATE_IP" ]; then
        PRIVATE_IP=$(hostname -I | awk '{print $1}')
    fi
fi

echo "Detected private IP: $PRIVATE_IP"

# Generate a random password for appuser
APP_PASSWORD=$(openssl rand -base64 12)

# Secure MySQL installation and setup
mysql -e "
    ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'RootPassword123!';
    DELETE FROM mysql.user WHERE User='';
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
    
    CREATE DATABASE appdb;
    CREATE USER 'appuser'@'localhost' IDENTIFIED BY '$APP_PASSWORD';
    CREATE USER 'appuser'@'$PRIVATE_IP' IDENTIFIED BY '$APP_PASSWORD';
    CREATE USER 'appuser'@'%' IDENTIFIED BY '$APP_PASSWORD';
    
    GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'localhost';
    GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'$PRIVATE_IP';
    GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'%';
    
    FLUSH PRIVILEGES;
"

# Configure MySQL to listen on all interfaces (for bastion access)
sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Also check for alternative config locations
if [ -f /etc/mysql/mariadb.conf.d/50-server.cnf ]; then
    sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
fi

# Restart MySQL service
systemctl restart mysql

# Save password for reference
echo "MySQL appuser password: $APP_PASSWORD" > /home/ubuntu/mysql-credentials.txt
chown ubuntu:ubuntu /home/ubuntu/mysql-credentials.txt
chmod 600 /home/ubuntu/mysql-credentials.txt

# Create completion marker
touch /var/log/mysql-setup-complete

echo "MySQL setup completed successfully!"
"""

def generate_mysql_user_data():
    return f'''#!/bin/bash
exec > >(tee /var/log/user-data.log) 2>&1

# Update system
apt-get update
apt-get upgrade -y

# Create script directory
mkdir -p /usr/local/bin

# Create MySQL setup script
cat > /usr/local/bin/mysql-setup.sh << 'EOL'
{mysql_setup_script}
EOL

chmod +x /usr/local/bin/mysql-setup.sh

# Execute the setup script
/usr/local/bin/mysql-setup.sh

# Create completion marker
touch /var/log/user-data-complete
'''

# Create EC2 Instance in public subnet (bastion)
bastion_ec2_instance = aws.ec2.Instance(
    "bastion-server",
    instance_type="t2.small",
    ami="ami-01811d4912b4ccb26",  # Ubuntu 22.04 LTS
    subnet_id=public_subnet.id,
    key_name=bastion_key_pair.key_name,
    vpc_security_group_ids=[bastion_sg.id],
    user_data=bastion_server_config(),
    user_data_replace_on_change=True,
    tags={"Name": "bastion-server"},
    opts=pulumi.ResourceOptions(
        depends_on=[public_route_table_association, bastion_key_pair]
    ),
)

# Create EC2 Instance in private subnet (database server)
private_ec2_instance = aws.ec2.Instance(
    "db-server",
    instance_type="t2.small",
    ami="ami-01811d4912b4ccb26",  # Ubuntu 22.04 LTS
    subnet_id=private_subnet.id,
    key_name=private_key_pair.key_name,
    vpc_security_group_ids=[app_sg.id],
    associate_public_ip_address=False,
    user_data=generate_mysql_user_data(),
    user_data_replace_on_change=True,
    tags={"Name": "db-server"},
    opts=pulumi.ResourceOptions(
        depends_on=[nat_gateway, private_route_table_association, private_key_pair]
    ),
)

# Export required values
pulumi.export("vpc_id", vpc.id)
pulumi.export("public_subnet_id", public_subnet.id)
pulumi.export("private_subnet_id", private_subnet.id)
pulumi.export("internet_gateway_id", internet_gateway.id)
pulumi.export("nat_gateway_id", nat_gateway.id)
pulumi.export("elastic_ip_id", elastic_ip.id)
pulumi.export("bastion_public_ip", bastion_ec2_instance.public_ip)
pulumi.export("db_server_private_ip", private_ec2_instance.private_ip)
pulumi.export("bastion_sg_id", bastion_sg.id)
pulumi.export("app_sg_id", app_sg.id)
pulumi.export("bastion_key_pair_name", bastion_key_pair.key_name)
pulumi.export("private_key_pair_name", private_key_pair.key_name)

# Create SSH config file for easy access
def create_ssh_config(ips):
    bastion_ip, private_ip = ips
    config_content = f"""# Bastion host configuration
Host bastion
    HostName {bastion_ip}
    User ops
    IdentityFile ~/.ssh/beston-host.pem
    StrictHostKeyChecking no

# Private instance via bastion
Host db-server
    HostName {private_ip}
    User ubuntu
    IdentityFile ~/.ssh/private-host.pem
    ProxyJump bastion
    StrictHostKeyChecking no
"""
    
    # Ensure .ssh directory exists
    ssh_dir = os.path.expanduser("~/.ssh")
    os.makedirs(ssh_dir, exist_ok=True)
    
    # Write config file
    config_path = os.path.join(ssh_dir, "config")
    with open(config_path, "w") as config_file:
        config_file.write(config_content)
    
    print(f"SSH config created at {config_path}")
    print("You can now use:")
    print("  ssh bastion")
    print("  ssh db-server")

# Apply the SSH config creation when IPs are ready
pulumi.Output.all(bastion_ec2_instance.public_ip, private_ec2_instance.private_ip).apply(create_ssh_config)