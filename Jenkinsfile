pipeline {
    agent any

    options {
        disableConcurrentBuilds()
    }

    environment {
        // Defaults - can be overridden by pipeline.properties
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_REPO = 'adwaitpatkhedkar'
        SONAR_PROJECT_KEY = 'meeting-scheduler-backend'
    }
    
    stages {
        stage('Setup Environment') {
            steps {
                script {
                    if (fileExists('pipeline.properties')) {
                        def props = readProperties file: 'pipeline.properties'
                        env.DOCKER_REGISTRY = props.DOCKER_REGISTRY ?: env.DOCKER_REGISTRY
                        env.DOCKER_REPO = props.DOCKER_REPO ?: env.DOCKER_REPO
                        env.SONAR_PROJECT_KEY = props.SONAR_PROJECT_KEY ?: env.SONAR_PROJECT_KEY
                    }
                    
                    env.IMAGE_TAG = "v${BUILD_NUMBER}"
                    env.BACKEND_IMAGE = "${env.DOCKER_REPO}/scheduler-backend:${env.IMAGE_TAG}"
                    env.FRONTEND_IMAGE = "${env.DOCKER_REPO}/scheduler-frontend:${env.IMAGE_TAG}"
                }
            }
        }

        stage('Clone Repo') {
            steps {
                checkout scm
            }
        }

        stage('Build Backend') {
            steps {
                dir('backend') {
                    script {
                        if (isUnix()) {
                            sh 'mvn -B clean package -DskipTests'
                        } else {
                            bat 'mvn -B clean package -DskipTests'
                        }
                    }
                }
            }
        }

        stage('Build Frontend') {
            steps {
                script {
                    if (isUnix()) {
                        sh 'npm ci'
                        sh 'npm run build'
                    } else {
                        bat 'npm ci'
                        bat 'npm run build'
                    }
                }
            }
        }

        stage('Run Tests') {
            steps {
                dir('backend') {
                    script {
                        if (isUnix()) {
                            sh 'mvn -B test'
                        } else {
                            bat 'mvn -B test'
                        }
                    }
                }
            }
            post {
                always {
                    junit testResults: 'backend/target/surefire-reports/*.xml', allowEmptyResults: true
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "Skipping SonarQube for local demo to save RAM"
            }
        }

        stage('Quality Gate') {
            steps {
                echo "Skipping Quality Gate"
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    if (isUnix()) {
                        sh "docker build -t ${BACKEND_IMAGE} ./backend"
                        sh "docker build --build-arg VITE_API_BASE_URL=/api -t ${FRONTEND_IMAGE} ."
                    } else {
                        bat "docker build -t %BACKEND_IMAGE% ./backend"
                        bat "docker build --build-arg VITE_API_BASE_URL=/api -t %FRONTEND_IMAGE% ."
                    }
                }
            }
        }

        stage('Push Docker Images') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    script {
                        if (isUnix()) {
                            sh 'echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin'
                            sh "docker push ${BACKEND_IMAGE}"
                            sh "docker push ${FRONTEND_IMAGE}"
                        } else {
                            bat '@echo %DOCKER_PASSWORD%| docker login -u %DOCKER_USERNAME% --password-stdin'
                            bat "docker push %BACKEND_IMAGE%"
                            bat "docker push %FRONTEND_IMAGE%"
                        }
                    }
                }
            }
        }

        stage('Deploy to K8s') {
            steps {
                script {
                    // Connect directly to the internal Minikube API server via Docker network
                    def deployBase = "kubectl --server=https://minikube:8443 --insecure-skip-tls-verify"
                    
                    echo "Deploying directly to Minikube cluster with images: ${BACKEND_IMAGE} and ${FRONTEND_IMAGE}"
                    
                    if (isUnix()) {
                        sh "${deployBase} set image deployment/backend backend=${BACKEND_IMAGE}"
                        sh "${deployBase} set image deployment/frontend frontend=${FRONTEND_IMAGE}"
                        sh "${deployBase} rollout status deployment/backend"
                        sh "${deployBase} rollout status deployment/frontend"
                    } else {
                        bat "${deployBase} set image deployment/backend backend=%BACKEND_IMAGE%"
                        bat "${deployBase} set image deployment/frontend frontend=%FRONTEND_IMAGE%"
                        bat "${deployBase} rollout status deployment/backend"
                        bat "${deployBase} rollout status deployment/frontend"
                    }
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'backend/target/*.jar', allowEmptyArchive: true
        }
        success {
            echo 'Pipeline completed successfully. Docker images are ready for deployment.'
            echo "Built images: ${BACKEND_IMAGE}, ${FRONTEND_IMAGE}"
        }
    }
}