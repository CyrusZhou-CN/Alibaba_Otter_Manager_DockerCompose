FROM lsqtzj/otter-osbase:v1.0

EXPOSE 8080 8081 2181 8018 2088 2089 2090 3306
# install otter
COPY ./image/ /tmp/docker/
COPY ./otter_manager/app.sh /home/admin/app.sh
COPY ./otter_manager/my.cnf /etc/my.cnf

RUN \
    cp -R /tmp/docker/alidata /alidata && \
    chmod +x /alidata/bin/* && \
    mkdir -p /home/admin && \
    cp -R /tmp/docker/admin/* /home/admin/  && \
    /bin/cp -f alidata/bin/lark-wait /usr/bin/lark-wait && \
    mkdir -p /home/admin/manager && \
    tar -xzvf /tmp/docker/manager.deployer-*.tar.gz -C /home/admin/manager && \
    /bin/rm -f /tmp/docker/node.deployer-*.tar.gz && \
    /bin/rm -f /tmp/docker/manager.deployer-*.tar.gz && \
    mkdir -p /home/admin/manager/logs  && \
    mkdir -p /home/admin/zkData  && \
    chmod +x /home/admin/*.sh  && \
    chmod +x /home/admin/bin/*.sh  && \
    chown admin: -R /home/admin && \ 
    yum clean all && \
    true

ENV DOCKER_DEPLOY_TYPE=VM PATH=$PATH:/usr/local/mysql/bin:/usr/local/mysql/scripts

WORKDIR /home/admin

ENTRYPOINT [ "/alidata/bin/main.sh" ]
CMD [ "/home/admin/app.sh" ]