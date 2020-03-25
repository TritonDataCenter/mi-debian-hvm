@Library('jenkins-joylib@v1.0.1') _

pipeline {
    agent {
        label 'nested-virt:qemu-kvm'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '30'))
        timestamps()
    }

    stages {
        stage('debian-8') {
            steps {
                sh('./create-image -r 8')
                sh('./create-image -r 8 upload')
            }
        }

        stage('debian-9') {
            steps {
                sh('./create-image -r 9')
                sh('./create-image -r 9 upload')
            }
        }

        stage('debian-10') {
            steps {
                sh('./create-image -r 10')
                sh('./create-image -r 10 upload')
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '*.artifacts-in-manta'
            joyMattermostNotification()
        }
    }
}
