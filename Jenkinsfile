Pipelie {
    agent any

    tools {
        jdk 'jdk-17'
        maven 'maven-3'
    }

    environment {
        SONAR_HOME= tool 'sonar-scanner'
    }

    stages {
        stage('Git Checkout') {
            steps {
                git branch 'main',
                url: 'https://github.com/pranavdaklepatil/CI-CD-Project.git'
            }
        }

        stage('Compile Code') {
            steps {
                sh 'mvn compile'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('File System Scan') {
            steps {
                sh 'trivy fs --format table -o trivy-fs-report.html .'
            }
        }

        stage('SonarQube Analysis') {
             steps {
                withSonarQubeEnv('sonar') {
                    sh '''$SONAR_HOME/bin/sonar-scanner --Dsonar.projectName=CI-CD-Project -Dsonar.projectKey=CI-CD-Project \
                    -Dsonar.java.binaries=.'''
                }
            }
            
        }

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar' 
                }
            }
        }

        stage('Build') {
            steps {
                sh 'mvn package'
            }
        }

        stage('Publish Artifacts to Nexus') {
            steps {
                withMaven(globalMavenSettingsConfig: 'maven-settings' , jdk: 'jdk-17', maven: 'maven3' , mavenSettingsConfig:" ,tracebility: true" ) {
                    sh 'mvn deploy'
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred' ,toolName: 'docker') {
                        sh "docker build -t pranavdaklepatil/ci-cd-project:latest ."
                    }
                
                }
            }
        }

        stage('Docker Image Scan') {
            steps {
                sh 'trivy image --format table -o trivy-fs-report.html pranavdaklepatil/ci-cd-project:latest'
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred' ,toolName: 'docker') {
                        sh "docker push pranavdaklepatil/ci-cd-project:latest"
                    }
                
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh 'kubectl apply -f deployment-service.yaml'
            }
        }
    }
}