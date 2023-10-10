# README

## Docker 镜像
此仓库自定义了 Odoo12 镜像，相较于官方的 Odoo12 镜像做出了如下的一些修改：

- 基础镜像使用 python:3.7-slim-bullseye
- 将 debian 软件源切换为阿里镜像源
- 改为从本地安装 odoo12 和 wkhtmltox
- 添加 Windows 系统中的宋体和 TimesNewRoman 字体
- 镜像中默认安装 celery redis minio 模块，并支持作为 celery worker 运行
- 额外的第三方模块可在 requirements.txt 中添加，例如 paramiko, dingtalk-sdk 等
- 添加等待 RabbitMQ Server 和 Redis Server 启动的脚本，因此 RabbitMQ, Redis 和 PostgreSQL都是必须依赖且要优先启动的服务

### 镜像构建
```sh
docker build -t odoo12:latest ./build
```

### 运行 celery worker
使用如下命令行参数将镜像容器作为 celery worker 运行，不用添加 `-A app worker`，其余参数可直接追加在后面：
```sh
docker run -d \
-v /host/path/data/:/var/lib/odoo/ \
-v /host/path/odoo.conf:/etc/odoo/odoo.conf \
odoo12 celery -l INFO [celery args]
```
> 注意：作为 celery worker 运行容器时，命令行中只能添加 celery worker 相关的命令行参数，
odoo 参数只能填写在 `odoo.conf` 配置文件中，且必须挂载至 `/etc/odoo/` 目录下。

### 启动等待
Odoo12 镜像运行的容器启动时会等待 RabbitMQ Server 和 Redis Server启动成功, RabbitMQ 和 Redis 连接信息需按如下方式在 `odoo.conf` 文件中配置：
```conf
; Celery broker
rabbit_host = mq
rabbit_port = 5672
rabbit_user = guest
rabbit_password = guest

; Redis
redis_host = redis
redis_port = 6379
redis_password = redis
redis_db = 0
redis_maxconn = 32
```

> 注意：缺省情况下将使用默认配置，连接超时后容器会自动退出

## Docker Compose

Compose 启动如下方式：
```sh
cp build/odoo.sample.conf compose/odoo.conf
cd ./compose
docker compose up -d
```

docker compose 中的默认服务及镜像如下：
- nginx
- web(odoo12)
- chat(odoo12)
- cron(odoo12)
- celery(odoo12)
- db(postgres:13)
- mq(rabbitmq:3-management)
- redis
- minio

## TODO
本镜像是供项目使用的，该镜像只是为项目提供基础环境，后续可以考虑将如下已实现的功能加入到该镜像中：

- Redis Session 功能
- 使用 Redis 作为 ormcache 缓存实现
- 使用 Minio 对象存储替代附件的本地存储
- Celery 实现异步邮件发送