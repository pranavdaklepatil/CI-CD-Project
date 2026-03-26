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


# not foget to change the file permissions to "chmod +x sonar_nexus_setup.sh"

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo chmod 666 /var/run/docker.sock


# following commands are for installing sonar server ,keep commented if you are aetting up nexus server ---> defaullt username and password for sonar server is "admin" and "admin" respectively
   # docker run -d --name sonar -p 9000:9000 sonarqube:lts-community
   # docker ps 


# following commands are for installing nexus server, keep commented if you are setting up sonar server, default username is "admin" and password is is located in container which is inside the nexus server on path "sonatype-work/nexus3/admin.password" 

   # docker run -d --name Nexus -p 8081:8081 sonatype/nexus3
   # docker ps 