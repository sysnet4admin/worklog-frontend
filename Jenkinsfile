pipeline {
    // 컨트롤러에는 docker가 없으므로 docker.sock을 가진 k8s 에이전트(JCasC kubernetes cloud)에서 실행.
    // agent any면 컨트롤러 실행기(numExecutors: 2)로 갈 수 있고 그때 'docker: not found'로 실패한다(run-38 7.9).
    agent { label 'jenkins-jenkins-agent' }

    environment {
        DOCKER_REPOSITORY = 'worklog-frontend'
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        GITHUB_CREDENTIALS = credentials('github-token')
    }

    stages {
        stage('Init') {
            steps {
                script {
                    env.SHORT_SHA = sh(script: 'git rev-parse --short=8 HEAD', returnStdout: true).trim()
                }
            }
        }

        stage('Build Image') {
            steps {
                sh """
                    echo ${DOCKERHUB_CREDENTIALS_PSW} | docker login --username ${DOCKERHUB_CREDENTIALS_USR} --password-stdin
                    # frontend(Node/yarn)는 --platform을 주지 않고 에이전트 노드의 아키텍처 하나로만 빌드한다.
                    # 다른 아키텍처를 QEMU로 함께 빌드하면 로컬 VM의 메모리가 모자라 에이전트가 끊긴다(run-15).
                    # 멀티 아키텍처 이미지는 7.8처럼 GitHub의 러너에서 만든다.
                    docker build -t ${DOCKERHUB_CREDENTIALS_USR}/${DOCKER_REPOSITORY}:${env.SHORT_SHA} .
                    docker push ${DOCKERHUB_CREDENTIALS_USR}/${DOCKER_REPOSITORY}:${env.SHORT_SHA}
                """
                echo "Built: ${env.SHORT_SHA}"
            }
        }

        stage('Update Manifest') {
            steps {
                sh """
                    sed -i "s|image: .*/worklog-frontend:.*|image: ${DOCKERHUB_CREDENTIALS_USR}/${DOCKER_REPOSITORY}:${env.SHORT_SHA}|" deploy_manifest/worklog-frontend.yaml
                    git config user.name "jenkins"
                    git config user.email "jenkins@myk8s.local"
                    git remote set-url origin https://${GITHUB_CREDENTIALS_USR}:${GITHUB_CREDENTIALS_PSW}@github.com/${GITHUB_CREDENTIALS_USR}/worklog-frontend.git
                    git add deploy_manifest/
                    git diff --staged --quiet || git commit -m "deploy: update frontend image to ${env.SHORT_SHA}"
                    git pull --rebase origin main || true
                    git push origin HEAD:main
                """
                echo "Deployed: ${env.SHORT_SHA}"
            }
        }
    }

    post {
        success { echo "Frontend pipeline succeeded: ${env.SHORT_SHA}" }
        failure { echo "Frontend pipeline failed" }
    }
}
