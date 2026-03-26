# first install prerequisites to setup jenkins server (java 17)
sudo apt update
sudo apt install openjdk-17-jre-headless -y

sudo wget -o /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt install jenkins -y
sudo systemctl start jenkins

 #------------------------------------------------------------------------#
 
 # Also install Docker 
 # Add Docker"s official GPG key :
 
 sudo apt-get update
 sudo apt-get install ca-certificates curl 
 sudo install -m 0775 -d /etc/apt/keyrings
 curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
 sudo chmod a+r /etc/apt/keyrings/docker.asc


 # Add the repository to Apt sources :
 echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
 sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
 sudo apt-get update

 sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
 sudo chmod 666 /var/run/docker.sock
 sudo systemctl status docker 


