pipeline {
    // 컨트롤러에는 docker가 없으므로 docker.sock을 가진 에이전트에서 실행한다(4.5, 5.5와 같은 라벨).
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
                echo "Image tag: ${env.SHORT_SHA}"
            }
        }

        stage('Build Image') {
            // --platform을 주지 않고 에이전트 노드의 아키텍처 하나로만 빌드한다.
            // 로컬 에이전트에서 멀티 아키텍처로 빌드하면 메모리가 모자란다.
            steps {
                sh '''
                    echo "$DOCKERHUB_CREDENTIALS_PSW" | docker login --username "$DOCKERHUB_CREDENTIALS_USR" --password-stdin
                    docker build -t "$DOCKERHUB_CREDENTIALS_USR/$DOCKER_REPOSITORY:$SHORT_SHA" .
                    docker push "$DOCKERHUB_CREDENTIALS_USR/$DOCKER_REPOSITORY:$SHORT_SHA"
                '''
            }
        }

        stage('Update Manifest') {
            steps {
                sh '''
                    sed -i "s|image: .*/worklog-frontend:.*|image: $DOCKERHUB_CREDENTIALS_USR/$DOCKER_REPOSITORY:$SHORT_SHA|" deploy_manifest/worklog-frontend.yaml
                    git config user.name "jenkins"
                    git config user.email "jenkins@myk8s.local"
                    git remote set-url origin "https://$GITHUB_CREDENTIALS_USR:$GITHUB_CREDENTIALS_PSW@github.com/$GITHUB_CREDENTIALS_USR/worklog-frontend.git"
                    git add deploy_manifest/worklog-frontend.yaml
                    git diff --staged --quiet || git commit -m "deploy: update frontend image to $SHORT_SHA"
                    git pull --rebase origin main
                    git push origin HEAD:main
                '''
            }
        }
    }

    post {
        success { echo "Frontend pipeline succeeded: ${env.SHORT_SHA}" }
        failure { echo 'Frontend pipeline failed' }
    }
}
