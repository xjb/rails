FROM node:18.0.0-alpine AS node
RUN cd / && find usr/local/bin -type l | xargs tar cf node.tar.gz -C /

FROM ruby:3.1.1-alpine AS production

COPY --from=node /usr/local/bin/node /usr/local/bin
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /opt /opt
WORKDIR /tmp
COPY --from=node node.tar.gz .
RUN tar xf node.tar.gz -C / ;\
    rm -f node.tar.gz

ARG USER=app
ARG UID=1000
ARG GROUP=${USER}
ARG GID=${UID}
RUN if [ "${USER:-root}" != "root" ]; then \
        addgroup -g ${GID} ${GROUP} && \
        adduser -D -G ${GROUP} -u ${UID} ${USER} && \
        apk add --update-cache --no-cache sudo && \
        echo "${USER} ALL=NOPASSWD: ALL" > "/etc/sudoers.d/99-developer" ;\
    fi

# Required to start rails server
RUN apk add --update-cache --no-cache \
        tzdata \
    ;
RUN apk add --update-cache --no-cache sqlite-dev
RUN apk add --update-cache --no-cache mysql-dev

# Required to bundle install
RUN apk add --update-cache --no-cache --virtual .rails-install-deps \
        # bundle install rails
        make gcc libc-dev \
        # bundle install in rails new
        g++ \
        postgresql-dev \
        freetds-dev \
        # libxml2-dev curl-dev imagemagick6-dev \
    ;
    # apk del --purge .rails-install-deps

USER ${USER:-root}
ARG APP_HOME=/workspace
WORKDIR ${APP_HOME}

RUN bundle init && \
    sed -i -r "s/^# gem \"rails\"/gem \"rails\"/" Gemfile && \
    bundle install

# sqlite3 | mysql | postgresql | sqlserver
ARG DB
RUN bundle exec rails new . \
        ${DB:+"--database="}${DB} \
        --force

# config database.yml
# https://github.com/rails/rails/tree/main/railties/lib/rails/generators/rails/app/templates/config/databases
RUN \
    # postgresql
    sed -i -r "s/adapter: postgresql/adapter: postgresql\n  username: postgres\n  host: db/" config/database.yml ;\
    # mysql, sqlserver
    sed -i -r "s/localhost/db/" config/database.yml

COPY entrypoint.sh /
ENTRYPOINT ["sh", "/entrypoint.sh"]

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]


FROM production AS development

USER root
# Development Tools
RUN apk add --update-cache --no-cache --virtual .dev-tools \
        curl \
        jq \
        # less \
        vim \
        git \
        # bash-completion \
    ;

# Rails Development Tools
RUN apk add --update-cache --no-cache sqlite;
RUN apk add --update-cache --no-cache mysql-client;
RUN apk add --update-cache --no-cache postgresql-client;

ARG MSSQL_VERSION=17.5.2.1-1
WORKDIR /tmp
# Installing system utilities
RUN apk add --no-cache curl gnupg --virtual .build-dependencies -- && \
    # Adding custom MS repository for mssql-tools and msodbcsql
    curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_${MSSQL_VERSION}_amd64.apk && \
    curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_${MSSQL_VERSION}_amd64.apk && \
    # Verifying signature
    curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_${MSSQL_VERSION}_amd64.sig && \
    curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_${MSSQL_VERSION}_amd64.sig && \
    # Importing gpg key
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --import - && \
    gpg --verify msodbcsql17_${MSSQL_VERSION}_amd64.sig msodbcsql17_${MSSQL_VERSION}_amd64.apk && \
    gpg --verify mssql-tools_${MSSQL_VERSION}_amd64.sig mssql-tools_${MSSQL_VERSION}_amd64.apk && \
    # Installing packages
    echo y | apk add --allow-untrusted msodbcsql17_${MSSQL_VERSION}_amd64.apk mssql-tools_${MSSQL_VERSION}_amd64.apk && \
    # Deleting packages
    apk del .build-dependencies && rm -f msodbcsql*.sig mssql-tools*.apk
ENV PATH ${PATH}:/opt/mssql-tools/bin

# for development gems
RUN gem install ruby-debug-ide --pre && \
    gem uninstall debase --all && \
    gem install debase --pre

USER ${USER:-root}
WORKDIR ${APP_HOME}

# webpack-dev-server
RUN yarn remove webpack-dev-server ;\
    yarn add --dev webpack-dev-server@3.11.2 --exact ;\
    yarn install --check-files
