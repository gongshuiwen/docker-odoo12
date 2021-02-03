# 说明
此仓库为自定义的Odoo12镜像构建文件，是对官方的Odoo12镜像构建文件做出了一些的修改，相关的修改内容如下：

- 将 debian 软件源切换为阿里镜像源
- 改为从本地安装 odoo12 和 wkhtmltox 的 deb 包
- 添加 Windows 系统中的宋体和 TimesNewRoman 字体
- 安装 python3 的 paramiko 库