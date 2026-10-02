pipeline {
    agent any

    triggers { githubPush() }

    environment {
        JAR     = 'cinema-booking-1.0.0-SNAPSHOT.jar'
        APP_DIR = '/home/shevua/DevOps-Demo1/target'
    }

    stages {
        stage('Build') {
            environment {
                DB_URL = credentials('db-url')
                DB_USERNAME = credentials('db-username')
                DB_PASSWORD = credentials('db-password')
            }
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Deploy to app1') {
            steps {
                sh '''
                    ssh shevua@app1.local "mkdir -p $APP_DIR"
                    scp target/$JAR shevua@app1.local:$APP_DIR/
                    ssh shevua@app1.local "sudo -n /opt/cinema/setup_app.sh"
                    timeout 120 bash -c 'until curl -s -o /dev/null http://app1.local:8080; do sleep 5; done'
                '''
            }
        }

        stage('Deploy to app2') {
            steps {
                sh '''
                    ssh shevua@app2.local "mkdir -p $APP_DIR"
                    scp target/$JAR shevua@app2.local:$APP_DIR/
                    ssh shevua@app2.local "sudo -n /opt/cinema/setup_app.sh"
                    timeout 120 bash -c 'until curl -s -o /dev/null http://app2.local:8080; do sleep 5; done'
                '''
            }
        }
    }
}