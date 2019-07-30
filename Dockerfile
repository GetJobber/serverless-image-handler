FROM amazonlinux:latest

RUN yum install -y zip gzip tar && \
curl -sL https://rpm.nodesource.com/setup_8.x | bash - && \
yum install -y nodejs

WORKDIR /tmp
ENV WORKDIR /tmp
ENV TEMPLATE_OUTPUT_BUCKET jobber-development-harriswong-lambda
ENV DIST_OUTPUT_BUCKET jobber-development-harriswong-lambda
ENV VERSION v4.0.0

COPY . .