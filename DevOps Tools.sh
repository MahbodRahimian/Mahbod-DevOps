### Sample `setup.sh`  

```bash  
#!/bin/bash  
echo "This is a Bash script." 

# DevOps Setup Script by Mahbod Rahimian  
# This script installs and configures various DevOps tools and practices.  

set -e  # Exit immediately if a command exits with a non-zero status.  

# Function to install Docker  
install_docker() {  
    echo "=== Installing Docker ==="  
    # Update the package database  
    apt-get update -y  
    # Install dependencies  
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common  
    # Add Docker’s official GPG key  
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -  
    # Add the Docker repository  
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"  
    # Update package database again  
    apt-get update -y  
    # Install Docker  
    apt-get install -y docker-ce  
    # Add user to the Docker group  
    usermod -aG docker $USER  
    echo "Docker installed successfully."  
}  

# Function to work with package manager  
package_manager() {  
    echo "=== Working with Package Manager ==="  
    # Update the system  
    apt-get update -y  
    echo "System updated."  
    echo "Install a package example (vim):"  
    read -p "Do you want to install vim? (y/n): " install_vim  
    if [ "$install_vim" == "y" ]; then  
        apt-get install -y vim  
        echo "Vim installed."  
    else  
        echo "Vim installation skipped."  
    fi  
}  

# Function for disk partitioning  
disk_partitioning() {  
    echo "=== Disk Partitioning ==="  
    echo "This will create a new partition and set it up."  
    # Replace /dev/sdb with your disk  
    DISK="/dev/sdb"  
    echo "Creating a new partition on $DISK..."  
    (echo n; echo p; echo 1; echo ; echo +10G; echo w) | fdisk $DISK  
    mkfs.ext4 "${DISK}1"  # Format the new partition  
    echo "New partition created and formatted."  
}  

# Function to create LVM  
setup_lvm() {  
    echo "=== Setting up LVM ==="  
    # Replace with your volume group name  
    VG_NAME="vg01"  
    echo "Creating physical volume..."  
    pvcreate /dev/sdb1  # Use your newly created partition  
    echo "Creating volume group $VG_NAME..."  
    vgcreate $VG_NAME /dev/sdb1  
    echo "Creating logical volume..."  
    lvcreate -n lv01 -L 5G $VG_NAME  # Creating a 5GB logical volume  
    mkfs.ext4 /dev/$VG_NAME/lv01  # Format the logical volume  
    echo "LVM setup completed."  
}  

# Function to initialize SSHD service  
initialize_sshd() {  
    echo "=== Initializing SSHD Service ==="  
    systemctl enable ssh  
    systemctl start ssh  
    echo "SSHD service initialized and started."  
}  

# Function to set up iptables  
setup_iptables() {  
    echo "=== Setting up iptables ==="  
    # Basic firewall rules  
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT  # Allow SSH  
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT  # Allow established connections  
    iptables -A INPUT -j DROP  # Drop other inputs  
    iptables-save > /etc/iptables/rules.v4  
    echo "Iptables configured."  
}  

# Function for Linux hardening  
linux_hardening() {  
    echo "=== Hardening Linux ==="  
    # Disable root login via SSH  
    sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config  
    systemctl restart ssh  
    echo "Root login disabled via SSH."  
}  

# Function to install and configure Git  
install_git() {  
    echo "=== Installing Git ==="  
    apt-get install -y git  
    read -p "Enter your Git username: " git_user  
    read -p "Enter your Git email: " git_email  
    git config --global user.name "$git_user"  
    git config --global user.email "$git_email"  
    echo "Git installed and configured."  
}  

# Function to set up Ansible  
setup_ansible() {  
    echo "=== Setting up Ansible ==="  
    apt-get install -y software-properties-common  
    add-apt-repository --yes --update ppa:ansible/ansible  
    apt-get install -y ansible  
    echo "Ansible installed successfully."  
}  

# Execute functions  
install_docker  
package_manager  
disk_partitioning  
setup_lvm  
initialize_sshd  
setup_iptables  
linux_hardening  
install_git  
setup_ansible  



### Sample `setup_monitoring.sh`  

```bash  
#!/bin/bash  

# DevOps Monitoring Setup Script by Mahbod Rahimian  
# This script installs and configures Prometheus, Grafana, and the ELK stack.  

set -e  # Exit immediately if a command exits with a non-zero status.  

# Function to install Prometheus  
install_prometheus() {  
    echo "=== Installing Prometheus ==="  
    # Create user and directories for Prometheus  
    useradd -rs /bin/false prometheus  
    mkdir -p /etc/prometheus /var/lib/prometheus  

    # Download Prometheus  
    curl -LO https://github.com/prometheus/prometheus/releases/latest/download/prometheus-*.tar.gz  
    tar xvf prometheus-*.tar.gz  
    mv prometheus-*/prometheus /usr/local/bin/  
    mv prometheus-*/promtool /usr/local/bin/  
    
    # Move configuration files  
    mv prometheus-*/prometheus.yml /etc/prometheus/  
    
    # Set permissions  
    chown prometheus:prometheus /usr/local/bin/prometheus  
    chown prometheus:prometheus /usr/local/bin/promtool  
    chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus  

    # Create systemd service  
    cat <<EOF > /etc/systemd/system/prometheus.service  
[Unit]  
Description=Prometheus Monitoring  
Wants=network-online.target  
After=network-online.target  

[Service]  
User=prometheus  
Group=prometheus  
Type=simple  
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --web.listen-address=0.0.0.0:9090 \
  --web.external-url=http://your.domain:9090  

[Install]  
WantedBy=multi-user.target  
EOF  

    systemctl daemon-reload  
    systemctl start prometheus  
    systemctl enable prometheus  
    echo "Prometheus installed and running."  
}  

# Function to install Grafana  
install_grafana() {  
  echo "=== Installing Grafana ==="  
    wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -  
    echo "deb https://packages.grafana.com/oss/deb stable main" >> /etc/apt/sources.list.d/grafana.list  
    apt-get update  
    apt-get install -y grafana  

    # Start and enable Grafana  
    systemctl start grafana-server  
    systemctl enable grafana-server  
    echo "Grafana installed and running."  
}  

# Function to secure Grafana with HTTPS and basic auth  
secure_grafana() {  
    echo "=== Securing Grafana with HTTPS and Basic Auth ==="  
    # Create self-signed SSL certificate (for demo purposes)  
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 -keyout /etc/grafana/server.key \
        -out /etc/grafana/server.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=your.domain"  

    # Configure Grafana to use HTTPS  
    cat <<EOF >> /etc/grafana/grafana.ini  
[server]  
protocol = https  
http_port = 3000  
cert_file = /etc/grafana/server.crt  
cert_key = /etc/grafana/server.key  
EOF  

    # Enable basic authentication  
    sed -i 's/^;allow_sign_up = true/allow_sign_up = false/' /etc/grafana/grafana.ini  
    sed -i 's/^;admin_user = admin/admin_user = your_admin_username/' /etc/grafana/grafana.ini  
    sed -i 's/^;admin_password = admin/admin_password = your_admin_password/' /etc/grafana/grafana.ini  

    systemctl restart grafana-server  
    echo "Grafana secured."  
}  

# Function to install the ELK stack  
install_elk() {  
    echo "=== Installing the ELK Stack ==="  
    # Install OpenJDK (required for Elasticsearch)  
    apt-get install -y openjdk-11-jdk  

    # Import the Elasticsearch GPG key and add the repository  
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -  
    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" >> /etc/apt/sources.list.d/elastic-7.x.list  
    apt-get update  
    apt-get install -y elasticsearch logstash kibana  

    # Start and enable Elasticsearch  
    systemctl start elasticsearch  
    systemctl enable elasticsearch  

    # Configure Logstash  
    cat <<EOF > /etc/logstash/conf.d/logstash.conf  
input {  
  beats {  
    port => 5044  
  }  
}  

filter {  
  # Define your filters here  
}  

output {  
  elasticsearch {  
    hosts => ["localhost:9200"]  
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"  
  }  
}  
EOF  

    # Start and enable Logstash  
    systemctl start logstash  
    systemctl enable logstash  

    # Start and enable Kibana  
    systemctl start kibana  
    systemctl enable kibana  

    echo "ELK Stack installed and running."  
}  

# Function to harden the installation  
harden_system() {  
    echo "=== Hardening the Monitoring Setup ==="  
    # Configure firewall rules (ufw)  
    ufw allow 22  # Allow SSH  
    ufw allow 9090  # Allow Prometheus  
    ufw allow 3000  # Allow Grafana  
    ufw allow 5601  # Allow Kibana  
    ufw enable  

    # Secure Elasticsearch by setting username and password  
    es_username="elastic_admin"  
    es_password=$(openssl rand -base64 12)  
    echo "Elasticsearch admin credentials:\nUsername: $es_username\nPassword: $es_password" > /tmp/es_credentials.txt  

    curl -X PUT "localhost:9200/_security/user/$es_username" -H 'Content-Type: application/json' -d "{  
      \"password\": \"$es_password\",  
      \"roles\": [\"superuser\"]  
    }"  

    echo "Monitoring setup hardened."  
}  

# Execute functions  
install_prometheus  
install_grafana  
secure_grafana  
install_elk  
harden_system  


### Sample `setup_web_servers.sh`  

```bash  
#!/bin/bash  

# Web Server Setup Script by Mahbod Rahimian  
# This script installs and configures Nginx and Apache web servers with various security configurations.  

set -e  # Exit immediately if a command exits with a non-zero status.  

# Function to install Nginx  
install_nginx() {  
    echo "=== Installing Nginx ==="  
    apt-get update -y  
    apt-get install -y nginx  

    # Start and enable Nginx  
    systemctl start nginx  
    systemctl enable nginx  
    
    echo "Nginx installed and running."  
}  

# Function to install Apache  
install_apache() {  
    echo "=== Installing Apache ==="  
    apt-get install -y apache2  

    # Start and enable Apache  
    systemctl start apache2  
    systemctl enable apache2  
    
    echo "Apache installed and running."  
}  

# Function to configure Nginx  
configure_nginx() {  
    echo "=== Configuring Nginx ==="  
    cat <<EOF > /etc/nginx/sites-available/example.com  
server {  
    listen 80;  
    server_name example.com www.example.com;  

    root /var/www/example.com;  
    index index.html;  

    location / {  
        try_files \$uri \$uri/ =404;  
    }  

    location ~ .php$ {  
        include snippets/fastcgi-php.conf;  
        fastcgi_pass unix:/run/php/php7.4-fpm.sock; # Adjust for PHP version used  
    }  

    location ~ /\.ht {  
        deny all;  
    }  
}  
EOF  

    # Enable the Nginx configuration  
    ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/  
    mkdir -p /var/www/example.com  
    echo "<h1>Hello from Nginx!</h1>" > /var/www/example.com/index.html  

    # Test Nginx configuration  
    nginx -t  

    # Restart Nginx to apply changes  
    systemctl restart nginx  

    echo "Nginx configured for example.com."  
}  

# Function to configure Apache  
configure_apache() {  
    echo "=== Configuring Apache ==="  
    cat <<EOF > /etc/apache2/sites-available/example.com.conf  
<VirtualHost *:80>  
    ServerName example.com  
    ServerAlias www.example.com

