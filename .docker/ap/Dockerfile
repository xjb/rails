FROM curlimages/curl AS downloader
WORKDIR /downloads
RUN curl -sL https://deb.nodesource.com/setup_lts.x -O
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg -O


FROM ruby:3.0.2 AS production
# FROM ruby:3.0.2-buster AS production

COPY --from=downloader /downloads/* /tmp

# for Rails
RUN \
    # for webpacker
    cat /tmp/setup_lts.x | bash - ;\
    cat /tmp/pubkey.gpg | apt-key add - ;\
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list ;\
    apt-get update ;\
    apt-get install -y --no-install-recommends nodejs yarn ;\
    apt-get install -y --no-install-recommends sudo ;\
    apt-get clean; rm -rf /var/lib/apt/lists/*

# add user
ARG USER=app
ARG UID=1000
ARG GROUP=${USER}
ARG GID=${UID}
RUN if [ "${USER:-root}" != "root" ]; then \
        groupadd --gid ${GID} ${GROUP} && \
        useradd --create-home --shell /bin/bash --gid ${GROUP} --uid ${UID} ${USER} ;\
        # Enable sudo without password
        echo "${USER} ALL=NOPASSWD: ALL" > "/etc/sudoers.d/99-developer" ;\
    fi

# switch user
USER ${USER:-root}

ARG APP_HOME=/workspace
WORKDIR ${APP_HOME}


# Setup Rails App
RUN bundle init ;\
    sed -i -r "s/^# gem \"rails\"/gem \"rails\"/" Gemfile ;\
    bundle install

# sqlite3 | mysql | postgresql | sqlserver
ARG DB
RUN bundle exec rails new . \
        # --minimal \
        # --api \
        ${DB:+"--database="}${DB}

# config database.yml
# https://github.com/rails/rails/tree/main/railties/lib/rails/generators/rails/app/templates/config/databases
RUN \
    # postgresql (only development)
    sed -i -r "s/#host:/host:/" config/database.yml ;\
    sed -i -r "s/#username: $(basename ${APP_HOME})/username: postgres/" config/database.yml ;\
    # postgresql, mysql, sqlserver
    sed -i -r "s/localhost/db/" config/database.yml

COPY entrypoint.sh /
ENTRYPOINT ["bash", "/entrypoint.sh"]

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]


FROM production AS development

# Development Tools
RUN \
    sudo -E apt-get update ;\
    DEBIAN_FRONTEND=noninteractive sudo -E apt-get install -y --no-install-recommends \
        curl \
        jq \
        less \
        vim \
        git \
        bash-completion \
    ;\
    sudo apt-get clean; sudo rm -rf /var/lib/apt/lists/*

# Rails Development Tools
RUN \
    # mssql-tools
    # FIXME: not work on bullseye
    curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add - ;\
    sudo -E bash -c "curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list" ;\
    # curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list ;\
    \
    sudo -E apt-get update ;\
    # for activerecord-sqlserver-adapter
    sudo -E apt-get install -y --no-install-recommends freetds-dev ;\
    # for dbconsole
    sudo -E apt-get install -y --no-install-recommends sqlite3 ;\
    sudo -E apt-get install -y --no-install-recommends default-mysql-client ;\
    sudo -E apt-get install -y --no-install-recommends postgresql-client ;\
    ACCEPT_EULA=Y sudo -E apt-get install -y --no-install-recommends mssql-tools msodbcsql17 ;\
    \
    sudo apt-get clean; sudo rm -rf /var/lib/apt/lists/*
ENV PATH ${PATH}:/opt/mssql-tools/bin

# for development gems
RUN sudo -E gem install ruby-debug-ide && \
    sudo -E gem install debase

# webpack-dev-server
RUN yarn remove webpack-dev-server ;\
    yarn add --dev webpack-dev-server@3.11.2 --exact ;\
    yarn install --check-files
