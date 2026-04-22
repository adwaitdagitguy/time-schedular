pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        BACKEND_IMAGE = 'scheduler-backend:v1'
        FRONTEND_IMAGE = 'scheduler-frontend:v1'
    }

    stages {
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
                withSonarQubeEnv('SonarQube') {
                    script {
                        if (isUnix()) {
                            sh 'mvn -B -f backend/pom.xml sonar:sonar -Dsonar.projectKey=meeting-scheduler-backend'
                        } else {
                            bat 'mvn -B -f backend/pom.xml sonar:sonar -Dsonar.projectKey=meeting-scheduler-backend'
                        }
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    if (isUnix()) {
                        sh "docker build -t ${BACKEND_IMAGE} ./backend"
                        sh "docker build -t ${FRONTEND_IMAGE} ."
                    } else {
                        bat "docker build -t %BACKEND_IMAGE% ./backend"
                        bat "docker build -t %FRONTEND_IMAGE% ."
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
