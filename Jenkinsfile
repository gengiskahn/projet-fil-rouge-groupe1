pipeline {
    environment {
		ID_DOCKER = "192.168.100.10:5000"
        IMAGE_NAME = 'projet-fil-rouge-groupe1'
        IMAGE_TAG = 'v1'
        CONTAINER_NAME = 'fil-rouge-groupe1'
    }
    agent none
     /*Build image*/
    stages {
        stage('Build staging image') {
            agent any
            steps {
                script {
                    sh 'docker build --no-cache -t ${ID_DOCKER}/$IMAGE_NAME:${IMAGE_TAG}_staging .'
                }
            }
        }
        /*push in dockerhub*/
        stage('Push staging Image on local docker repository') {
            agent any
            steps {
                script {
                    sh '''
            docker push ${ID_DOCKER}/$IMAGE_NAME:${IMAGE_TAG}_staging
        '''
                }
            }
        }

        /*deploy minikube_staging*/
        stage('Run container on K8S based on builded staging image') {
            agent any
            steps {
                script {
                    sh '''
					sed 's/___PLATFORMTAG___/_staging/g' eazytraining-deployment.yml > eazytraining-deployment-staging.yml
					scp eazytraining-deployment-staging.yml jenkins@staging:.
					ssh jenkins@staging \
					"if docker images | grep ${ID_DOCKER}/$IMAGE_NAME:${IMAGE_TAG}_staging; then docker image rm -f ${ID_DOCKER}/$IMAGE_NAME:${IMAGE_TAG}_staging; fi"
                    ssh jenkins@staging \
                    "kubectl apply -f eazytraining-deployment-staging.yml"
                    sleep 5
                 '''
                }
            }
        }
         /*Unit test with Jest on staging*/
        stage('tests fonctions js') {
            agent any
            steps {
                script {
                    sh '''
                    ssh jenkins@staging \
                    "kubectl exec eazytraining -- bash -c 'cd /var/local/node/projet-fil-rouge-groupe1 && npm test'"
         '''
                }
            }
        }
        /*Fontional test on staging*/
        stage('Test image') {
            agent any
            steps {
                script {
                    sh '''
                    curl http://staging:31000 | grep -i "contact@eazytraining.fr"
                '''
                }
            }
        }
		/*push in dockerhub*/
        stage('Push production Image on local docker repository') {
            agent any
            steps {
                script {
                    sh '''
            docker tag ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}_staging ${ID_DOCKER}/$IMAGE_NAME:${IMAGE_TAG}_prod
			docker push ${ID_DOCKER}/$IMAGE_NAME:${IMAGE_TAG}_prod
        '''
                }
            }
        }
        /*clean*/
        stage('Clean Staging deployment') {
            agent any
            steps {
                script {
                    sh '''
                 ssh jenkins@staging \
                 "kubectl delete -f eazytraining-deployment-staging.yml"
               '''
                }
            }
        }
        /*deploy prod*/
        stage('Run container based on builded image prod') {
            agent any
            steps {
                script {
                    sh '''
					sed 's/___PLATFORMTAG___/_prod/g' eazytraining-deployment.yml > eazytraining-deployment-production.yml
					scp jenkins@production eazytraining-deployment-production.yml jenkins@staging:.
					ssh jenkins@production \
					"if docker images | grep ${ID_DOCKER}/$IMAGE_NAME:${IMAGE_TAG}_prod; then docker image rm -f ${ID_DOCKER}/$IMAGE_NAME:${IMAGE_TAG}_prod; fi"
                    ssh jenkins@production \
                    "kubectl apply -f eazytraining-deployment-production.yml"
                 '''
                }
            }
        }
    }
}
