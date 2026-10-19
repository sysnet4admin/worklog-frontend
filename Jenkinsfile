def shortSHA

pipeline {
    // 컨트롤러에는 docker가 없으므로 docker.sock을 가진 k8s 에이전트에서 실행한다.
    agent { label 'jenkins-jenkins-agent' }
    environment {
        IMAGE_NAME = 'worklog-frontend'
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        GITHUB_CREDENTIALS = credentials('github-token')
    }
    stages {
        stage('Init') {
            steps {
                script {
                    shortSHA = sh(script: "git rev-parse --short=8 HEAD", returnStdout: true).trim()
                    echo "Image tag: ${shortSHA}"
                }
            }
        }
        // frontend는 QEMU로 다른 아키텍처를 빌드하면 에이전트 메모리가 모자란다.
        // --platform 없이 에이전트 노드의 아키텍처 하나로 빌드한다.
        stage('Build Image') {
            steps {
                script {
                    sh """
                        echo "\$DOCKERHUB_CREDENTIALS_PSW" | docker login --username "\$DOCKERHUB_CREDENTIALS_USR" --password-stdin
                        docker build -t "\$DOCKERHUB_CREDENTIALS_USR/${IMAGE_NAME}:${shortSHA}" .
                        docker push "\$DOCKERHUB_CREDENTIALS_USR/${IMAGE_NAME}:${shortSHA}"
                    """
                }
            }
        }
        stage('Update Manifest') {
            steps {
                script {
                    sh """
                        sed -i "s|image: .*/worklog-frontend:.*|image: \$DOCKERHUB_CREDENTIALS_USR/${IMAGE_NAME}:${shortSHA}|" deploy_manifest/worklog-frontend.yaml
                        git config user.name "jenkins"
                        git config user.email "jenkins@myk8s.local"
                        git remote set-url origin "https://\$GITHUB_CREDENTIALS_USR:\$GITHUB_CREDENTIALS_PSW@github.com/\$GITHUB_CREDENTIALS_USR/worklog-frontend.git"
                        git add deploy_manifest/
                        git diff --staged --quiet || git commit -m "deploy: update frontend image to ${shortSHA}"
                        git pull --rebase -X theirs origin main
                        git push origin HEAD:main
                    """
                    echo "Manifest updated: ${shortSHA}"
                }
            }
        }
    }
}
