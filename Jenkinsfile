pipeline{
 agent any
 tools{
    jdk 'jdk17'
 }
 environment {
    SCANNER_HOME=tool 'sonar-scanner'
 }
 stages {
    stage('Checkout from Git'){
        steps{
            git branch: 'main', url: 'https://github.com/Sachin20010517/two-tier-flask-k8s-ops.git'
        }
    }
    stage("Sonarqube Analysis "){
        steps{
            withSonarQubeEnv('sonar-server') {
                sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=flask \
                -Dsonar.projectKey=flask '''
            }
        }
    }
    stage("quality gate"){
       steps {
            script {
                waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
            }
        }
    }
    stage('TRIVY FS SCAN') {
        steps {
            sh "trivy fs . > trivyfs.json"
        }
    }
    stage('snyk test') {
        steps {
                withCredentials([string(credentialsId: 'snyk', variable: 'snyk')]) {
                   sh 'snyk auth $snyk'
                   sh 'snyk test --all-projects --report || true'
                   sh 'snyk code test --json-file-output=vuln1.json || true'
                }
        }
    }
    stage("Docker Build & Push"){
        steps{
            script{
               withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                   sh "docker build -t two-tier-flask-k8s-ops ."
                   sh "docker tag two-tier-flask-k8s-ops sachinayeshmantha/two-tier-flask-k8s-ops:latest "
                   sh "docker push sachinayeshmantha/two-tier-flask-k8s-ops:latest "
                }
            }
        }
    }
    stage('snyk image scan') {
        steps {
                withCredentials([string(credentialsId: 'snyk', variable: 'snyk')]) {
                   sh 'snyk auth $snyk'
                   sh 'snyk container test sachinayeshmantha/two-tier-flask-k8s-ops:latest --report || true'
                }
        }
    }
    stage('Deploy to kubernets'){
        steps{
            script{
                dir('eks-manifests') {
                    withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'k8s', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') {
                      sh 'kubectl apply -f mysql-secrets.yml -f mysql-configmap.yml -f mysql-deployment.yml -f mysql-svc.yml'
                      sh 'sleep 30'
                      sh 'kubectl apply -f two-tier-app-deployment.yml -f two-tier-app-svc.yml'
                    }
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
        // Adjust bannerColor logic to include handling for the "ABORTED" status
        def bannerColor
        if (pipelineStatus.toUpperCase() == 'SUCCESS') {
            bannerColor = 'green'
        } else if (pipelineStatus.toUpperCase() == 'ABORTED') {
            bannerColor = 'orange'
        } else {
            bannerColor = 'red'
        }
        def body = """<html> <body>
<div style="border: 4px solid ${bannerColor}; padding: 10px;">
 <h2>${jobName} - Build ${buildNumber}</h2>
 <div style="background-color: ${bannerColor}; padding: 10px;">
    <h3 style="color: white;">Pipeline Status: ${pipelineStatus.toUpperCase()}</h3>
 </div>
 <p>Check the <a href="${BUILD_URL}">console output</a>.</p>
</div>
</body> </html>"""
        emailext (
            subject: "${jobName} - Build ${buildNumber} - ${pipelineStatus.toUpperCase()}",
            body: body,
            to: 'sachinayeshmantha@gmail.com',
            from: 'jenkins@example.com',
            replyTo: 'jenkins@example.com',
            mimeType: 'text/html',
            attachmentsPattern: 'trivy-report.html'
        )
    }
 }
}
}