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
                sh 'trivy image --format table -o trivy-image-report.html pranavdaklepatil/ci-cd-project:latest'
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
                withKubeConfig(caCertificate: ", clusterName: 'kubernetes', contextName: ", credentialsId: 'k8s-cred', namespace: 'webapps', restrictKubeConfigAccess: false, serverUrl: 'https://kubernetes.docker.internal:6443') { 
                     sh 'kubectl apply -f deployment-service.yaml'
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                withKubeConfig(caCertificate: ", clusterName: 'kubernetes', contextName: ", credentialsId: 'k8s-cred', namespace: 'webapps', restrictKubeConfigAccess: false, serverUrl: 'https://kubernetes.docker.internal:6443') { 
                    sh 'kubectl get pods'
                    sh 'kubectl get svc '
                }
                
            }
        }
    }

    }
    post {
        always {
            script {
                def jobName = env.JOB_NAME
                def buildNumber = env.BUILD_NUMBER
                def pipelineStatus = currentBuild.result ?: 'UNKNOWN'
                def bannerColor = pipelineStatus.toUpperCase() == 'SUCCESS' ? 'green' : 'red'

                def body = """
                    <html>
                    <body>
                    <div style="border: 4px solid ${bannerColor}; padding: 10px;">
                    <h2>${jobName} - Build ${buildNumber}</h2>
                    <div style="background-color: ${bannerColor}; padding: 10px;">
                    <h3 style="color: white;">Pipeline Status: ${pipelineStatus.toUpperCase()}</h3>
                    </div>
                    <p>Check the <a href="\${BUILD_URL}">console output</a>.</p>
                    </div>
                    </body>
                    </html>
                """

                emailext (
                    subject: "${jobName} - Build ${buildNumber} - ${pipelineStatus.toUpperCase()}",
                    body: body,
                    to: 'pranavdakle445@gmail.com',
                    from: 'pranavdakle445@gmail.com',
                    replyTo: 'pranavdakle445@gmail.com',
                    mimeType: 'text/html',
                    attachmentsPattern: 'trivy-image-report.html'

                )
            }
        }
    }
}