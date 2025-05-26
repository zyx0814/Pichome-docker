
# 1.快速启动
```
docker run -d -p 80:80 --restart=always oaooa/pichome
```
# 2.实现数据持久化——创建数据目录并在启动时挂载
```
mkdir /data
docker run -d -p 80:80 --restart=always -v /data:/var/www/html oaooa/pichome 
```
# 3.以https方式启动
 
-  使用已有ssl证书
    - 证书格式必须是 fullchain.pem  privkey.key
        ```
        docker run -d -p 443:443 --restart=always  -v "你的证书目录":/etc/nginx/ssl --name pichome oaooa/pichome
        ```

# 4.使用docker-compose同时部署数据库（推荐）
```
git clone https://github.com/zyx0814/Pichome-docker.git
cd ./Pichome-docker/compose/
修改docker-compose.yaml，设置数据库root密码（MYSQL_ROOT_PASSWORD=密码）
docker-compose up -d
```