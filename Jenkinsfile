pipeline {
  agent any

  environment {
    REGISTRY        = "192.168.1.149:8082"
    IMAGE_NAME      = "hello-web"
    IMAGE_TAG       = "1.0.0"
    NEXUS_CREDS_ID  = "nexus-docker"
    KUBECONFIG      = '/home/jenkins/.kube/config'
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build JAR') {
      steps {
        sh 'mvn clean package -DskipTests -B'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh """
          docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
        """
      }
    }

    stage('Push to Nexus') {
      steps {
        withCredentials([usernamePassword(credentialsId: env.NEXUS_CREDS_ID, usernameVariable: 'NUSER', passwordVariable: 'NPASS')]) {
          sh """
            echo "${NPASS}" | docker login ${REGISTRY} -u "${NUSER}" --password-stdin
            docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
            docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
          """
        }
      }
    }

    stage('Create imagePullSecret') {
      steps {
        withCredentials([usernamePassword(credentialsId: env.NEXUS_CREDS_ID, usernameVariable: 'NUSER', passwordVariable: 'NPASS')]) {
          sh """
            kubectl delete secret regcred --ignore-not-found
            kubectl create secret docker-registry regcred \
              --docker-server=${REGISTRY} \
              --docker-username="${NUSER}" \
              --docker-password="${NPASS}"
          """
        }
      }
    }

    stage('Deploy to Minikube') {
      steps {
        sh """
          sed "s|REPLACE_REGISTRY|${REGISTRY}|g" k8s/deployment.yaml | kubectl apply -f -
          kubectl apply -f k8s/service.yaml
          kubectl rollout status deploy/${IMAGE_NAME} --timeout=120s
        """
      }
    }
  }

  post {
    always {
      sh 'kubectl get pods,svc -o wide || true'
    }
  }
}
