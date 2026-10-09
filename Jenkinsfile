pipeline {
    // 컨트롤러에는 docker가 없으므로 docker.sock을 가진 k8s 에이전트에서 실행한다.
    agent { label 'jenkins-jenkins-agent' }

    environment {
        DOCKER_REPOSITORY = 'worklog-frontend'
        // credentials()가 _USR, _PSW 환경 변수를 함께 만든다.
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        GITHUB_CREDENTIALS = credentials('github-token')
    }

    stages {
        stage('Init') {
            steps {
                script {
                    env.SHORT_SHA = sh(script: 'git rev-parse --short=8 HEAD', returnStdout: true).trim()
                }
                echo "Image tag: ${env.SHORT_SHA}"
            }
        }

        stage('Build Image') {
            steps {
                // 작은따옴표 sh: 비밀값을 Groovy가 아니라 셸이 환경 변수로 읽는다.
                // --platform을 주지 않아 에이전트 노드의 아키텍처 하나로만 빌드한다.
                sh '''
                    IMAGE="${DOCKERHUB_CREDENTIALS_USR}/${DOCKER_REPOSITORY}:${SHORT_SHA}"
                    echo "${DOCKERHUB_CREDENTIALS_PSW}" | docker login --username "${DOCKERHUB_CREDENTIALS_USR}" --password-stdin
                    docker build -t "${IMAGE}" .
                    docker push "${IMAGE}"
                '''
            }
        }

        stage('Update Manifest') {
            steps {
                sh '''
                    IMAGE="${DOCKERHUB_CREDENTIALS_USR}/${DOCKER_REPOSITORY}:${SHORT_SHA}"
                    sed -i "s|image: .*/worklog-frontend:.*|image: ${IMAGE}|" deploy_manifest/worklog-frontend.yaml
                    git config user.name "jenkins"
                    git config user.email "jenkins@myk8s.local"
                    git remote set-url origin "https://${GITHUB_CREDENTIALS_USR}:${GITHUB_CREDENTIALS_PSW}@github.com/${GITHUB_CREDENTIALS_USR}/worklog-frontend.git"
                    git add deploy_manifest/worklog-frontend.yaml
                    git diff --staged --quiet || git commit -m "deploy: update frontend image to ${SHORT_SHA}"
                    git pull --rebase origin main
                    git push origin HEAD:main
                '''
            }
        }
    }

    post {
        success { echo "Frontend pipeline succeeded: ${env.SHORT_SHA}" }
        failure { echo "Frontend pipeline failed" }
    }
}
