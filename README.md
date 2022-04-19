# Alibaba_Otter_Manager_DockerCompose
Alibaba Otter Managerdocker-compose.yml 测试环境</br>
# 编译运行
``docker-compose -f "docker-compose.yml" up -d --build``
# 管理地址
http://localhost:8080/</br>
管理员/密码：admin/admin</br>
zookeeper ui</br>
http://localhost:8018/commands</br>
mysql</br>
管理员/密码：root / otter </br>
普通用户/密码：otter  /  otter
![image](https://user-images.githubusercontent.com/4635861/135860250-97afd12c-ebe3-43e6-a86f-dce63385617e.png)</br>
![image](https://user-images.githubusercontent.com/4635861/135860273-b628b7a0-ab5d-406d-abb2-01dab42314e1.png)</br>

2021年10月7日 </br>
osbase 基础镜像，系统软件更新 </br>
zookeeper -> 3.7.0</br>
mysql -> 5.7.35 #  Ver 14.14 Distrib 5.7.35, for Linux (x86_64) using  EditLine wrapper</br>
修复宿主机无法访问镜像mysql问题</br>
# 2022年4月19日更新
mysql 初始化数据库功能修复

```
...
volumes:
      - ./test.sql:/docker-entrypoint-initdb.d/test.sql
...
```
用ZOO_CLUSTER参数自动生成otter默认配置