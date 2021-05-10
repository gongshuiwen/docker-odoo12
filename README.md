# 说明
此仓库为自定义的Odoo12镜像构建文件，是对官方的Odoo12镜像构建文件做出了一些的修改，相关的修改内容如下：

- 将 debian 软件源切换为阿里镜像源
- 改为从本地安装 odoo12 和 wkhtmltox 的 deb 包
- 添加 Windows 系统中的宋体和 TimesNewRoman 字体
- 安装 python3 的 paramiko 库
- 安装 celery 并可直接运行 celery worker

## 运行 celery worker
运行 celery 需要保证 hg_base 模块被正确挂载，然后使用如下命令行参数使镜像容器以 celery worker 运行，不用显式的添加 -A app worker，其余参数可直接追加在后面：
```bash
docker run -v /host/path/addons_my/:/mnt/addons_my/ \
-v /host/path/config/:/etc/odoo/ -d image_name celery -l INFO [celery args]
```
注意：命令行中只能添加 celery worker 可用的参数，odoo 参数只能填写在 odoo 配置文件中，且必须挂载至 /etc/odoo/ 目录下。

以下参数可以直接在 odoo 配置文件中配置：
- broker: 对应 odoo 配置文件中的 celery_broker

## TODO
- 内置自动备份模块
- 内置 celery 功能模块
