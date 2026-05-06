# Use the official Maven image to grab the binaries
FROM maven:3.9.6-eclipse-temurin-17-alpine AS maven-source

# Use the official Jenkins agent image as a base
FROM jenkins/jenkins:lts

USER root

# 1. Copy Maven from the maven-source stage
COPY --from=maven-source /usr/share/maven /usr/share/maven
RUN ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

# 2. Install Docker CLI & kubectl (Static Binaries)
RUN curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-26.1.4.tgz | tar zxvf - --strip-components=1 -C /usr/local/bin docker/docker

# 3. Install kubectl (Static Binary)
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# 4. Install Node.js & NPM (Static Binary)
RUN curl -fsSL https://nodejs.org/dist/v20.11.1/node-v20.11.1-linux-x64.tar.gz | tar -xz -C /usr/local --strip-components=1

USER jenkins
