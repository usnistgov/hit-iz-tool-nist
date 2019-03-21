# Reference URL: https://runnable.com/docker/java/dockerize-your-java-application
# Reference URL: https://www.howtoforge.com/tutorial/how-to-create-docker-images-with-dockerfile/
# Reference URL: https://hub.docker.com/r/mcpayment/ubuntu1404-java8/~/dockerfile/
# Reference URL: https://github.com/TexaiCognitiveArchitecture/docker-java8-jenkins-maven-git-nano
# Reference URL: https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#apt-get
# Reference Command: docker search ubuntu/java

# Download base image ubuntu 18.04
FROM ubuntu:18.04

MAINTAINER  Desire Banse

# Prepare installation of Oracle Java 8
ENV JAVA_VER 8
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

RUN apt-get update
RUN apt-get -y install curl gnupg

# Install git, wget, Oracle Java8
RUN echo 'deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main' >> /etc/apt/sources.list && \
    echo 'deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main' >> /etc/apt/sources.list && \
    echo 'deb http://archive.ubuntu.com/ubuntu trusty main universe' >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C2518248EEA14886 && \
    apt-get update && \
    apt-get install -y git wget && \
    echo oracle-java${JAVA_VER}-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y --force-yes --no-install-recommends oracle-java${JAVA_VER}-installer oracle-java${JAVA_VER}-set-default && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm -rf /var/cache/oracle-jdk${JAVA_VER}-installer

# Set Oracle Java as the default Java
RUN update-java-alternatives -s java-8-oracle
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> ~/.bashrc

# Install maven 3.3.9
RUN wget --no-verbose -O /tmp/apache-maven-3.3.9-bin.tar.gz http://www-eu.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz && \
    tar xzf /tmp/apache-maven-3.3.9-bin.tar.gz -C /opt/ && \
    ln -s /opt/apache-maven-3.3.9 /opt/maven && \
    ln -s /opt/maven/bin/mvn /usr/local/bin  && \
    rm -f /tmp/apache-maven-3.3.9-bin.tar.gz

ENV MAVEN_HOME /opt/maven

COPY hit-dev.nist.gov.keystore /root/
# COPY settings.xml /root/

RUN cd /root/ && git clone https://github.com/usnistgov/hit-core-xml

# RUN cd /root/hit-core-xml/ && git checkout legacy
RUN cd /root/hit-core-xml/ && mvn clean

COPY settings.xml /root/.m2/

RUN cd /root/ && git clone https://github.com/usnistgov/hit-core.git
RUN cd /root/hit-core/ && mvn -U install -Djavax.net.ssl.trustStore=/root/hit-dev.nist.gov.keystore

RUN cd /root/ && git clone https://github.com/usnistgov/hl7-profile-validation
RUN cd /root/hl7-profile-validation && mvn -U install -Djavax.net.ssl.trustStore=/root/hit-dev.nist.gov.keystore

RUN cd /root/ && git clone https://github.com/usnistgov/hit-xml-validation.git
RUN cd /root/hit-xml-validation && mvn -U clean install -Djavax.net.ssl.trustStore=/root/hit-dev.nist.gov.keystore

RUN cd /root/ && git clone https://github.com/usnistgov/schematronValidation.git
RUN cd /root/schematronValidation && mvn -U clean install -Djavax.net.ssl.trustStore=/root/hit-dev.nist.gov.keystore

RUN cd /root/hit-core-xml/hit-core-xml-domain && mvn -U clean install -Djavax.net.ssl.trustStore=/root/hit-dev.nist.gov.keystore

RUN cd /root/hit-core-xml/ && git checkout legacy
#RUN cd /root/hit-core-xml && mvn -U install -Djavax.net.ssl.trustStore=/root/hit-dev.nist.gov.keystore
RUN cd /root/hit-core-xml/hit-core-xml-domain && mvn -U install -Djavax.net.ssl.trustStore=/root/hit-dev.nist.gov.keystore

RUN cd /root/ && git clone https://github.com/usnistgov/hit-core-hl7v2.git
RUN cd /root/hit-core-hl7v2 && git checkout master
RUN cd /root/hit-core-hl7v2 && mvn -U clean install -Djavax.net.ssl.trustStore=/root/hit-dev.nist.gov.keystore

# tools for the server side and client side
# RUN cd /root/ && wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash

RUN curl -sL https://deb.nodesource.com/setup_8.x  | bash -
RUN apt-get -y install nodejs

RUN npm cache clean -f
RUN npm install -g n
RUN n 8.14.1

RUN apt-get install -y build-essential
RUN apt-get install -y ruby2.5
RUN apt-get install -y ruby2.5-dev
RUN apt-get install -y ruby-ffi
RUN gem update --system
RUN gem install sass
RUN gem install compass

RUN cd /root/ && npm install -g bower

# build the IZ tool
RUN cd /root/ && git clone https://github.com/usnistgov/hit-iz-tool
RUN cd /root/hit-iz-tool && git checkout apps/cni-new
RUN cd /root/hit-iz-tool/hit-iz-web/client && npm install

RUN cd /root/hit-iz-tool/hit-iz-web/client && bower install --allow-root

RUN cd /root/ && npm install -g grunt
RUN cd /root/hit-iz-tool/hit-iz-web/client && grunt build

RUN cd /root/hit-iz-tool/ && mvn -U clean install -Djavax.net.ssl.trustStore=/root/hit-dev.nist.gov.keystore -Dmaven.test.skip

EXPOSE 80 443