FROM canal/otter-osbase:v1

MAINTAINER agapple (jianghang115@gmail.com)
EXPOSE 8080 8081 2181 8018 2088 2089 2090
# install otter
COPY ./image/ /tmp/docker/
COPY ./otter_manager/app.sh /home/admin/app.sh
COPY ./otter_node/aria2c /bin/aria2c

RUN \
    /bin/cp -rf /tmp/docker/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo && \
    cp -R /tmp/docker/alidata /alidata && \
    chmod +x /alidata/bin/* && \
    mkdir -p /home/admin && \
    cp -R /tmp/docker/admin/* /home/admin/  && \
    /bin/cp -f alidata/bin/lark-wait /usr/bin/lark-wait && \
    mkdir -p /home/admin/manager && \
    tar -xzvf /tmp/docker/manager.deployer-*.tar.gz -C /home/admin/manager && \
    mkdir -p /home/admin/node && \
    tar -xzvf /tmp/docker/node.deployer-*.tar.gz -C /home/admin/node && \
    /bin/rm -f /tmp/docker/node.deployer-*.tar.gz && \
    /bin/rm -f /tmp/docker/node.deployer-*.tar.gz && \
    /bin/rm -f /tmp/docker/manager.deployer-*.tar.gz && \
    mkdir -p /home/admin/manager/logs  && \    
    mkdir -p /home/admin/node/logs  && \
    mkdir -p /home/admin/zkData  && \
    chmod +x /home/admin/*.sh  && \
    chmod +x /home/admin/bin/*.sh  && \    
    rm -rf /home/admin/zookeeper-3.4.13 && \
    tar -xzvf /tmp/docker/apache-zookeeper-*-bin.tar.gz -C /home/admin/ && \
    mv /home/admin/apache-zookeeper-3.7.0-bin /home/admin/zookeeper-3.7.0 && \
    chown admin: -R /home/admin && \ 
    echo "otter.zookeeper.cluster.default = 127.0.0.1:2181" >> "/home/admin/node/conf/otter.properties" && \
    yum clean all && \
    true

ENV DOCKER_DEPLOY_TYPE=VM PATH=$PATH:/usr/local/mysql/bin:/usr/local/mysql/scripts

WORKDIR /home/admin

ENTRYPOINT [ "/alidata/bin/main.sh" ]
CMD [ "/home/admin/app.sh" ]