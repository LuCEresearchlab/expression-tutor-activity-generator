# TODO: change this and use proper versioning
FROM herrdermails/expression-service:1.1.0

RUN apt-get update
RUN apt-get install -y jq

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
