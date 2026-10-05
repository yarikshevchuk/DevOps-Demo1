pipeline {
    agent any

    triggers { githubPush() }

    options {
        disableConcurrentBuilds()
        timeout(time: 10, unit: 'MINUTES')
    }

    environment {
        DEPLOY_USER = 'shevua'
        JAR     = 'cinema-booking-1.0.0-SNAPSHOT.jar'
        APP_DIR = '/home/shevua/DevOps-Demo1/target'
    }

    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Deploy to app1') {
            steps {
                sh '''
                    ssh $DEPLOY_USER@app1.local "mkdir -p $APP_DIR"
                    scp target/$JAR $DEPLOY_USER@app1.local:$APP_DIR/
                    ssh $DEPLOY_USER@app1.local "sudo -n /opt/cinema/setup_app.sh"
                    timeout 120 bash -c 'until curl -sf -o /dev/null http://app1.local:8080; do sleep 5; done'
                '''
            }
        }

        stage('Deploy to app2') {
            steps {
                sh '''
                    ssh $DEPLOY_USER@app2.local "mkdir -p $APP_DIR"
                    scp target/$JAR $DEPLOY_USER@app2.local:$APP_DIR/
                    ssh $DEPLOY_USER@app2.local "sudo -n /opt/cinema/setup_app.sh"
                    timeout 120 bash -c 'until curl -sf -o /dev/null http://app2.local:8080; do sleep 5; done'
                '''
            }
        }
    }
}