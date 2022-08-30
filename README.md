# README
此仓库为自定义的Odoo12镜像构建文件，是对官方的Odoo12镜像构建文件做出了一些的修改，相关的修改内容如下：

- 将 debian 软件源切换为阿里镜像源
- 改为从本地安装 odoo12 和 wkhtmltox 的 deb 包
- 添加 Windows 系统中的宋体和 TimesNewRoman 字体
- 安装 python3 的 paramiko 库
- 安装 celery 并可直接运行 celery worker
- 添加等待 RabbitMQ Server 的启动脚本

## 运行 celery worker
使用如下命令行参数使镜像容器以 celery worker 运行，不用添加 -A app worker，其余参数可直接追加在后面：
```sh
docker run 
-v /host/path/addons/:/mnt/extra-addons/ \
-v /host/path/data/:/var/lib/odoo/ \
-v /host/path/odoo.conf:/etc/odoo/odoo.conf \
-d image_name celery -l INFO [celery args]
```
注意：以 celery worker 运行容器时，命令行中只能添加 celery worker 的命令行参数，
odoo 参数只能填写在 odoo.conf 配置文件中，且必须挂载至 /etc/odoo/ 目录下。

容器启动时会等待 RabbitMQ Server 启动并接受连接, 其连接信息应在 odoo.conf 文件中配置, 配置项为
rabbit_host, rabbit_port, rabbit_user 和 rabbit_password, 缺省情况下将使用默认配置，连接超时后容器将自动退出。
