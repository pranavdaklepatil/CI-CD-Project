1. Anlyse the application and identify the processes that need to be automated.
2. Create a detailed Architectural Design 
    - Define the components and their interactions.
    - Choose the appropriate technologies and tools for automation.
4. Verify and validate the architectural design.
5. Start applying the automation process based on the architectural design.
    -Install required tools and set up the environment.


Implimentation Steps:
Go to AWS and create the following resources:
1.Here we are using default private VPC
2.EC2 
    -Create common security group for all EC2 instances with necessary inbound and outbound rules.
          -Inbound: Allow SSH (port 22) from trusted IPs, 
                Allow HTTP (port 80) from anywhere,
                Allow HTTPS (port 443) from anywhere
                Allow application-specific ports (custom tcp ports 3000-10000) from anywhere
                Allow SMTPS (port 465) from anywhere
                Allow SMTP (port 25) from anywhere
                Allow range 30000-32767 for Kubernetes node communication
                Allow 6443 for Kubernetes API server access
            -Outbound: Allow all outbound traffic
    -Create three EC2 instances named as master, slave1 and slave2 with the following specifications:
          -AMI: Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
          -Instance Type: t2.medium (2 vCPUs, 4 GB RAM)
          -Key Pair: Create a new key pair for SSH access
          -Security Group: Attach the common security group created earlier
       -Configure and install kubernetes on the EC2 instances:
          - for all nodes " k8s_installation.sh 
          -Master Node (master):
                -master.sh ------------> get the command from here and run it on worker nodes to join the cluster
    
    cratate VMs 2 for sonarqube and nexus servers with the following specifications:
          -AMI: Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
          -Instance Type: t2.medium (2 vCPUs, 4 GB RAM)
          -Key Pair: use the same key pair created for EC2 instances
          -Security Group: Attach the common security group created earlier
      -suetup sonarqube and nexus servers on the respective VMs using docker and run them as containers.
        - installing docker on both VMs and running sonarqube and nexus as docker containers using the respective docker images.
        - use the the script "sonar_nexus_setup.sh".


    create a vm for jenkins server with the following specifications:
          -AMI: Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
          -Instance Type: t2.large (2 vCPUs, 8 GB RAM, 30 GB Storage)
          -Key Pair: use the same key pair created for EC2 instances
          -Security Group: Attach the common security group created earlier
      -setup jenkins server on the VM using "jenkins_setup.sh" script which will install jenkins and docker on jenkens server.
