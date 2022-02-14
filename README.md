
# 1.快速启动
```
docker run -d -p 80:80 oaooa/pichome
```
# 2.实现数据持久化——创建数据目录并在启动时挂载
```
mkdir /data
docker run -d -p 80:80 -v /data:/var/www/html oaooa/pichome
```
# 3.以https方式启动
 
-  使用已有ssl证书
    - 证书格式必须是 fullchain.pem  privkey.pem
        ```
        docker run -d -p 443:443  -v "你的证书目录":/etc/nginx/ssl --name pichome oaooa/pichome
        ```

# 4.[使用docker-compose同时部署数据库（推荐）](https://github.com/zyx0814/Pichome-docker)
```
git clone https://github.com/zyx0814/Pichome-docker.git
cd ./pichome-docker/compose/
修改docker-compose.yaml，设置数据库root密码（MYSQL_ROOT_PASSWORD=密码）
docker-compose up -d
```
- 把环境变量都写在TXT文件中

```
version: "3.5"

services:
  db:
    image: mariadb:10.7
    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
    volumes:
      - "./db:/var/lib/mysql"
    environment:
      - "TZ=Asia/Shanghai"
      - "MYSQL_ROOT_PASSWORD="
      - "MYSQL_DATABASE_FILE=/run/secrets/mysql_db"
      - "MYSQL_USER_FILE=/run/secrets/mysql_user"
      - "MYSQL_PASSWORD_FILE=/run/secrets/mysql_password"
    restart: always
    secrets:
      - mysql_db
      - mysql_password
      - mysql_user

  app:
    image: oaooa/pichome
    ports:
      - 80:80
    links:
      - db
    volumes:
      - "./data:/var/www/html"
    environment:
      - "MYSQL_SERVER=db"
      - "MYSQL_DATABASE_FILE=/run/secrets/mysql_db"
      - "MYSQL_USER_FILE=/run/secrets/mysql_user"
      - "MYSQL_PASSWORD_FILE=/run/secrets/mysql_password"
      - "SESSION_HOST=redis"
    restart: always
    secrets:
      - mysql_db
      - mysql_password
      - mysql_user

 

secrets:
  mysql_db:
    file: "./mysql_db.txt"
  mysql_password:
    file: "./mysql_password.txt"
  mysql_user:
    file: "./mysql_user.txt"

```
