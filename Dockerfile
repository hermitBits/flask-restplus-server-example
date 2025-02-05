FROM python:3.7.3-alpine

ENV API_SERVER_HOME=/opt/www
WORKDIR "$API_SERVER_HOME"
ENV PYTHONPATH "${PYTHONPATH}:."
COPY "./requirements.txt" "./"
COPY "./application/requirements.txt" "./application/"
COPY "./config.py" "./"
COPY "./tasks" "./tasks"

ARG INCLUDE_POSTGRESQL=false
ARG INCLUDE_UWSGI=false
RUN apk add --no-cache --virtual=.build_dependencies musl-dev gcc g++ python3-dev libffi-dev linux-headers && \
    cd /opt/www && \
    pip install -r tasks/requirements.txt && \
    pip install markupsafe==2.0.1 --force-reinstall && \
    pip install SQLAlchemy==1.3.24 && \
    invoke app.dependencies.install && \
    ( \
        if [ "$INCLUDE_POSTGRESQL" = 'true' ]; then \
            apk add --no-cache libpq && \
            apk add --no-cache --virtual=.build_dependencies postgresql-dev && \
            pip install psycopg2 ; \
        fi \
    ) && \
    ( if [ "$INCLUDE_UWSGI" = 'true' ]; then pip install uwsgi ; fi ) && \
    rm -rf ~/.cache/pip && \
    apk del .build_dependencies

COPY "./" "./"

RUN chown -R nobody "." && \
    if [ ! -e "./local_config.py" ]; then \
        cp "./local_config.py.template" "./local_config.py" ; \
    fi

USER nobody
CMD [ "invoke", "app.run", "--no-install-dependencies", "--host", "0.0.0.0" ]
