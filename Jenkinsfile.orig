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
        stage('Build image') {
            agent any
            steps {
                script {
                    sh 'docker build --no-cache -t ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG .'
                }
            }
        }
        /*push in dockerhub*/
        stage('Push Image on local docker repository') {
            agent any
            steps {
                script {
                    sh '''
            # echo $DOCKERHUB_PASSWORD | docker login -u $ID_DOCKER --password-stdin
            docker push ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG
        '''
                }
            }
        }

        /*deploy minikube_staging*/
        stage('Run container based on builded image staging') {
            agent any
            steps {
                script {
                    sh '''
					ssh jenkins@staging \
					"if docker ps -a | grep $CONTAINER_NAME; then docker rm -f $CONTAINER_NAME; fi"
					ssh jenkins@staging \
					"if docker images | grep ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG; then docker image rm -f ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG; fi"
                    ssh jenkins@staging \
                    "docker run --name $CONTAINER_NAME -d -p 3000:3000 -e PORT=3000 ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG"
                    sleep 5
                 '''
                }
            }
        }
         /*tests untaires installation Jest*/
        stage('tests fonctions js') {
            agent any
            steps {
                script {
                    sh '''
                    ssh jenkins@staging \
                    "docker exec $CONTAINER_NAME bash -c 'cd /var/local/node/projet-fil-rouge-groupe1 && npm test'"
         '''
                }
            }
        }
        /*test fonctionnel*/
        stage('Test image') {
            agent any
            steps {
                script {
                    sh '''
                    curl http://staging:3000 | grep -i "contact@eazytraining.fr"
                '''
                }
            }
        }
        /*clean*/
        stage('Clean Container') {
            agent any
            steps {
                script {
                    sh '''
                 ssh jenkins@staging \
                 "docker rm -f $CONTAINER_NAME"
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
					ssh jenkins@production \
					"if docker ps -a | grep $CONTAINER_NAME; then docker rm -f $CONTAINER_NAME; fi"
					ssh jenkins@production \
					"if docker images | grep ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG; then docker image rm -f ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG; fi"
                    ssh jenkins@production \
                    "docker run --name $CONTAINER_NAME -d -p 3000:3000 -e PORT=3000 ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG"
                    sleep 5
                 '''
                }
            }
        }
    }
}
