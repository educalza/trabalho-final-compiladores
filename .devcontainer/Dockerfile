# Use a imagem oficial do Dart como base
FROM dart:latest

# Instala o Java (necessário para rodar o ANTLR)
RUN apt-get update && apt-get install -y \
    openjdk-21-jre-headless \
    && apt-get clean

# Baixa o ANTLR 4 complete JAR
ARG ANTLR_VERSION=4.13.1
WORKDIR /usr/local/lib
RUN apt-get update && apt-get install -y curl && \
    curl -O https://www.antlr.org/download/antlr-${ANTLR_VERSION}-complete.jar && \
    mv antlr-${ANTLR_VERSION}-complete.jar antlr-complete.jar

# Define o CLASSPATH para o ANTLR
ENV CLASSPATH=".:/usr/local/lib/antlr-complete.jar:${CLASSPATH:+:$CLASSPATH}"

# Define um alias para facilitar a execução do ANTLR
RUN echo 'alias antlr4="java -jar /usr/local/lib/antlr-complete.jar"' >> /root/.bashrc
RUN echo 'alias grun="java org.antlr.v4.gui.TestRig"' >> /root/.bashrc

# Retorna ao diretório de trabalho padrão
WORKDIR /workspace