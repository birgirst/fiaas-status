FROM alpine:latest

RUN apk add py-pip curl jq && \
    pip install awscli && \
    curl -o /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator && \
    chmod +x /usr/local/bin/aws-iam-authenticator

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]