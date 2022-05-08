pipeline {
    environment {
        /* ID_DOCKER = 'gengiskahn' */
		ID_DOCKER = "jenkins:5000"
        IMAGE_NAME = 'fil-rouge-groupe1'
        IMAGE_TAG = 'v1'
        CONTAINER_NAME = 'fil-rouge-groupe1'
        DOCKERHUB_PASSWORD = credentials('dockerhubpassword')
    }
    agent none
     /*Build image*/
    stages {
        stage('Build image') {
            agent any
            steps {
                script {
                    sh 'docker build -t ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG .'
                }
            }
        }
        /*push in dockerhub*/
        stage('Login and Push Image on docker hub') {
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
                    "docker exec -it $CONTAINER_NAME bash -c 'cd /var/local/node/projet-fil-rouge-groupe1 && npm test'"
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
                    "docker run --name $CONTAINER_NAME -d -p 3000:3000 -e PORT=3000 ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG"
                    sleep 5
                 '''
                }
            }
        }
    }
}
