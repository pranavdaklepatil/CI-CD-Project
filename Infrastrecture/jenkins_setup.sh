# first install prerequisites to setup jenkins server (java 17)
sudo apt update
sudo apt install openjdk-17-jre-headless -y

sudo wget -o /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt install jenkins -y
sudo systemctl start jenkins

 