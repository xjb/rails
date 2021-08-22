# rails

## Requirements

- Rails開発用イメージ
- Railsアプリを新規作成するために使用する
- コンテナ単体でRailsが動作する
- rootでないユーザで動作する(rootでも動作する)
- `sudo` が利用可能
- productionステージにはRailsの動作に必要のないリソースを含めない
- entrypoint.sh を通さずに起動可能
- developmentステージでVS Codeのデバッグが使用可能
- developmentステージで `rails dbconsole` が使用可能

## Build Args

| Key      | Defaults    | Description                                                         |
| -------- | ----------- | ------------------------------------------------------------------- |
| USER     | app         | コンテナのLinuxユーザ名                                             |
| UID      | 1000        | コンテナのLinuxユーザのUID                                          |
| GROUP    | $USER       | コンテナのLinuxユーザのグループ名                                   |
| GID      | $UID        | コンテナのLinuxユーザのGID                                          |
| APP_HOME | /workspace  | Railsルート                                                         |
| DB       | - (sqlite3) | Railsで使用するデータベース。 sqlite3, mysql, postgresql, sqlserver |


## Environments

| Key              | Defaults | Description                   |
| ---------------- | -------- | ----------------------------- |
| TZ               | -        | タイムゾーン                  |
| RAILS_MASTER_KEY | -        | Railsのmaster.key             |
| SA_PASSWORD      | -        | Sql Server の SA のパスワード |


## Getting Startd

### 最小限の構成で起動する

1. docker-compose.yml を作成

    ```yml
    version: "3.9"
    services:
      ap:
        build:
          context: .docker/ap
        ports:
          - "3000:3000"
    ```

2. コンテナを起動

    ```bash
    docker-compose up
    ```

### Railsアプリを新しく作成する

1. docker-compose.yml を作成

    ローカルのカレントディレクトリを
    コンテナのWORKDIR(/workspace)にマウントして起動する。
    (※ローカルに存在しないディレクトリをマウントすると所有者がrootになるので注意)

    `command: bash` により Rails server ではなくbashを起動するようにし、
    `tty: true` によりコンテナを起動させ続け、
    `stdin_open: true` により attach 可能にする。

    ```yml
    version: "3.9"
    services:
      ap:
        build:
          context: .docker/ap
        command: bash
        stdin_open: true
        tty: true
        ports:
          - "3000:3000"
        volumes:
          - .:/workspace
    ```

2. コンテナを起動

    ```bash
    docker-compose up
    ```

3. Railsアプリを作成

    ローカルのカレントディレクトリをマウントしているため
    生成されたファイルがローカルに反映される。

    1. Gemfileを生成

        ```bash
        docker-compose exec ap bundle init
        ```

    2. Gemfileを編集してrailsをインストール

        Gemfile
        ```
        gem "rails"

        ```

        ```bash
        docker-compose exec ap bundle install
        ```

    3. Railsアプリを作成

        ```bash
        docker-compose exec ap bundle exec rails new .
        ```

### コンテナ内で作成したファイルが権限エラーになる

コンテナのユーザのUID,GIDをローカルユーザ一致させることで回避できる。

1. ローカルユーザのIDを確認

    ```bash
    $ id
    uid=1000(localuser) gid=1000(localuser) groups=1000(localuser)
    ```

2. コンテナビルド時に作成されるユーザのUID,GIDを指定

    ```yml
        ap:
          build:
            context: .docker/ap
            args:
              USER: localuser
              UID: 1000
              GROUP: localuser
              GID: 1000
    ```

3. コンテナをビルドし直して起動

    ```bash
    docker-compose up --build
    ```
