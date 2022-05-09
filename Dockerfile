FROM node:14.16
LABEL maintainer="Fil Rouge Groupe 1"
RUN npm install -g npm && \
        npm install -g nodemon
RUN	npm install jest --global
RUN mkdir -p /var/local/node && \
        cd /var/local/node && \
        git clone https://github.com/cjoly69/fil-rouge-groupe1.git
EXPOSE 3000
CMD cd /var/local/node/projet-fil-rouge-groupe1 && npm start