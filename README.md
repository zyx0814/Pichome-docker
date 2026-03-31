# PHP 7.4 + Nginx 全功能多媒体 Web 服务容器

这是一个高度优化的 Docker 环境，专为处理图像、视频和专业媒体资产而设计。它集成了 PHP 7.4-FPM、Nginx、ImageMagick、FFmpeg，并支持多架构（AMD64/ARM64）。基于 Debian Bullseye 以获得更好的现代格式（如 HEIC/AVIF）支持。

## 核心特性

- **PHP 7.4-FPM**: 预装了所有必需的基础扩展以及 `mbstring`, `gd`, `zip`, `curl`, `tidy`, `xsl`, `imagick`, `redis`, `mysqli` 等。
- **Nginx**: 高性能 Web 服务器，支持 HTTP/HTTPS。
- **ImageMagick**: 支持各种专业图像格式，包括 RAW, CR2, DNG, PSD, WebP, TIFF, HEIC/HEIF 等。
- **FFmpeg**: 完整的视频处理支持，可用于转码、生成缩略图等。
- **多平台支持**: 兼容 `linux/amd64` 和 `linux/arm64` (Apple Silicon)。
- **动态 HTTPS**: 根据挂载目录是否存在证书文件，自动切换 HTTP 或 HTTPS 配置。
- **性能优化**: 预配置了优化的 PHP-FPM 进程管理和 PHP Opcache。
- **定时任务 (Cron)**: 内置 `cron` 服务，支持执行定时脚本。预设了一个通过 `curl` 访问外部 URL 的任务。
- **无日志模式**: 容器内默认不生成日志文件，防止存储空间被占满。

## 快速开始

### 1. 运行服务
确保您已安装 Docker 和 Docker Compose，然后在项目根目录下运行：

```bash
docker-compose up -d --build
```

启动后，您可以通过 `http://localhost:8080` 访问服务。

### 2. 启用 HTTPS (可选)
本环境支持动态切换到 HTTPS。只需在项目根目录执行以下操作：

1. 创建 `ssl` 文件夹。
2. 将证书文件命名为 `server.crt` 和 `server.key` 并存入 `ssl` 文件夹。
3. 运行 `docker-compose up -d`。

如果 `ssl` 目录下存在证书，容器启动时会自动切换到 HTTPS 配置并强制重定向 80 端口。

### 3. 配置定时任务 (Cron)

本环境内置了 `cron` 服务，可以执行定时任务。默认配置了一个每 5 分钟通过 `curl` 访问外部 URL 的任务。

1.  **创建 URL 文件**: 在您的项目本地（例如与 `docker-compose.yml` 同级）创建一个名为 `cron_url.txt` 的文件。
2.  **填写 URL**: 在 `cron_url.txt` 文件中输入您希望定时访问的完整 URL，例如 `https://example.com/api/cron`。
3.  **挂载文件**: 在 `docker-compose.yml` 中，将该文件挂载到容器的 `/var/www/html/cron_url.txt`。修改 `services.php.volumes` 部分如下：

    ```yaml
    volumes:
      - ./site:/var/www/html
      - ./ssl:/etc/nginx/ssl
      - ./cron_url.txt:/var/www/html/cron_url.txt # 添加这一行
    ```

4.  **启动服务**: 运行 `docker-compose up -d`。容器启动后，定时任务将自动运行。

- **日志**: 定时任务的执行日志会记录在容器内的 `/var/log/cron.log` 文件中。
- **频率**: 默认执行频率为每 5 分钟。如需修改，请编辑 `Dockerfile` 中 `cron-task` 的 cron 表达式并重新构建镜像。

## 目录结构

- `Dockerfile`: 容器构建定义。
- `docker-compose.yml`: 编排配置，定义端口映射和卷挂载。
- `config/`: 配置文件目录。
  - `entrypoint.sh`: 容器启动脚本，包含动态 SSL 切换逻辑。
  - `nginx-http.conf`: HTTP 模式下的 Nginx 配置模板。
  - `nginx-https.conf`: HTTPS 模式下的 Nginx 配置模板。
  - `custom-php.ini`: 优化的 PHP 配置文件。
  - `php-fpm-www.conf`: 优化的 PHP-FPM 进程池配置。
- `index.php`: 测试页面，显示 `phpinfo()`。


## 日志说明
为了保持容器精简，所有 Nginx 和 PHP 的日志均已重定向到 `/dev/null`。如需开启，请修改相应的配置文件（`nginx-http.conf`, `nginx-https.conf`, `custom-php.ini`）并重建容器。
