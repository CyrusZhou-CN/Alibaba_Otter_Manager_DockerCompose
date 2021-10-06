#!/bin/bash
#set -e

source /etc/profile
export JAVA_HOME=/usr/java/latest
export PATH=$JAVA_HOME/bin:$PATH
touch /tmp/start.log
chown admin: /tmp/start.log
chown admin: /home/admin/node
chown admin: /home/admin/zkData
host=`hostname -i`

# default config
if [ -z "${RUN_MODE}" ]; then
    RUN_MODE="ALL"
fi

if [ -z "${MYSQL_USER_PASSWORD}" ]; then
    MYSQL_USER_PASSWORD="otter"
fi
if [ -z "${OTTER_MANAGER_MYSQL}" ]; then
    OTTER_MANAGER_MYSQL="127.0.0.1:3306"
fi
if [ -z "${MYSQL_ROOT_PASSWORD}" ]; then
    MYSQL_ROOT_PASSWORD="otter"
fi
if [ -z "${MYSQL_USER}" ]; then
    MYSQL_USER="otter"
fi
if [ -z "${MYSQL_DATABASE}" ]; then
    MYSQL_DATABASE="otter"
fi

# default zookeeper config
ZOO_DIR=/home/admin/zookeeper-3.7.0
ZOO_CONF_DIR=$ZOO_DIR/conf
ZOO_DATA_DIR=/home/admin/zkData 
ZOO_DATA_LOG_DIR=$ZOO_DATA_DIR/datalog 
ZOO_LOG_DIR=$ZOO_DIR/logs 
ZOO_TICK_TIME=10000 
ZOO_INIT_LIMIT=10 
ZOO_SYNC_LIMIT=5
ZOO_AUTOPURGE_PURGEINTERVAL=0 
ZOO_AUTOPURGE_SNAPRETAINCOUNT=3 
ZOO_MAX_CLIENT_CNXNS=60 
ZOO_STANDALONE_ENABLED=true 
ZOO_ADMINSERVER_ENABLED=false

# waitterm
#   wait TERM/INT signal.
#   see: http://veithen.github.io/2014/11/16/sigterm-propagation.html
waitterm() {
        local PID
        # any process to block
        tail -f /dev/null &
        PID="$!"
        # setup trap, could do nothing, or just kill the blocker
        trap "kill -TERM ${PID}" TERM INT
        # wait for signal, ignore wait exit code
        wait "${PID}" || true
        # clear trap
        trap - TERM INT
        # wait blocker, ignore blocker exit code
        wait "${PID}" 2>/dev/null || true
}

# waittermpid "${PIDFILE}".
#   monitor process by pidfile && wait TERM/INT signal.
#   if the process disappeared, return 1, means exit with ERROR.
#   if TERM or INT signal received, return 0, means OK to exit.
waittermpid() {
        local PIDFILE PID do_run error
        PIDFILE="${1?}"
        do_run=true
        error=0
        trap "do_run=false" TERM INT
        while "${do_run}" ; do
                PID="$(cat "${PIDFILE}")"
                if ! ps -p "${PID}" >/dev/null 2>&1 ; then
                        do_run=false
                        error=1
                else
                        sleep 1
                fi
        done
        trap - TERM INT
        return "${error}"
}

function checkStart() {
    local name=$1
    local cmd=$2
    local timeout=$3
    #隐藏光标
    printf "\e[?25l" 
    i=0
    str=""
    bgcolor=43
    space48="                       "
    echo "$name check ... [$cmd]"
    isrun=0
    while [ $timeout -gt 0 ]
    do
        ST=`eval $cmd`
        if [ "$ST" -gt 0 ]; then
            isrun=1
            break
        else
            percentstr=$(printf "%3s" $i)
            totalstr="${space48}${percentstr}${space48}"
            leadingstr="${totalstr:0:$i+1}"
            trailingstr="${totalstr:$i+1}"
            #打印进度,#docker中进度条不刷新
            stdbuf -oL printf "\r\e[30;47m${leadingstr}\e[37;40m${trailingstr}\e[0m"
            let i=$i+1
            str="${str}="
            sleep 1
            let timeout=$timeout-1
        fi
    done
    echo ""
    if [ $isrun == 1 ]; then
        echo -e "\033[32m $name start successful \033[0m" 
    else
        echo -e "\033[31m $name start timeout \033[0m"
    fi
    
    #显示光标
    printf "\e[?25h""\n"
}


function start_zookeeper() {
    echo "start zookeeper ..."
    # start zookeeper

    # Generate the config
    rm -f $ZOO_DATA_DIR/myid
    rm -f $ZOO_CONF_DIR/zoo.cfg
    if [[ ! -f "$ZOO_CONF_DIR/zoo.cfg" ]]; then
        CONFIG="$ZOO_CONF_DIR/zoo.cfg"
        {
            echo "dataDir=$ZOO_DATA_DIR" 
            echo "dataLogDir=$ZOO_DATA_LOG_DIR"

            echo "tickTime=$ZOO_TICK_TIME"
            echo "initLimit=$ZOO_INIT_LIMIT"
            echo "syncLimit=$ZOO_SYNC_LIMIT"
            echo "clientPortAddress=0.0.0.0"
            echo "clientPort=2181"
            echo "quorumListenOnAllIPs=true"
            echo "autopurge.snapRetainCount=$ZOO_AUTOPURGE_SNAPRETAINCOUNT"
            echo "autopurge.purgeInterval=$ZOO_AUTOPURGE_PURGEINTERVAL"
            echo "maxClientCnxns=$ZOO_MAX_CLIENT_CNXNS"
            echo "standaloneEnabled=$ZOO_STANDALONE_ENABLED"
            echo "admin.enableServer=$ZOO_ADMINSERVER_ENABLED"
            echo "admin.serverAddress=0.0.0.0"
            echo "admin.serverPort=8018"
            echo "4lw.commands.whitelist=*"
        } >> "$CONFIG"
        if [[ -z $ZOO_SERVERS ]]; then
            ZOO_SERVERS="server.1=localhost:2888:3888"
        fi

        for server in $ZOO_SERVERS; do
            echo "$server" >> "$CONFIG"
        done

        if [[ -n $ZOO_4LW_COMMANDS_WHITELIST ]]; then
            echo "4lw.commands.whitelist=$ZOO_4LW_COMMANDS_WHITELIST" >> "$CONFIG"
        fi

        for cfg_extra_entry in $ZOO_CFG_EXTRA; do
            echo "$cfg_extra_entry" >> "$CONFIG"
        done
    fi

    # Write myid only if it doesn't exist
    if [[ ! -f "$ZOO_DATA_DIR/myid" ]]; then
        echo "${ZOO_MY_ID:-1}" > "$ZOO_DATA_DIR/myid"
    fi
    cmd="su admin -c 'mkdir -p $ZOO_DATA_DIR;mkdir -p $ZOO_LOG_DIR; cd $ZOO_DATA_DIR; $ZOO_DIR/bin/zkServer.sh start >> $ZOO_DATA_DIR/zookeeper.log 2>&1'"
    eval $cmd
    sleep 1
    #check start
    checkStart "zookeeper" "echo stat | nc 127.0.0.1 2181 | grep -c Outstanding" 120
}

function stop_zookeeper() {
    # stop zookeeper
    echo "stop zookeeper"
    cmd="su admin -c 'mkdir -p $ZOO_DATA_DIR; cd $ZOO_DATA_DIR; $ZOO_DIR/bin/zkServer.sh stop >> $ZOO_DATA_DIR/zookeeper.log 2>&1'"
    eval $cmd
    echo "stop zookeeper successful ..."
}

function start_node() {
    echo "start node ..."
    # start node
    
    cmd="sed -i -e 's/^otter.manager.address.*$/otter.manager.address = 10.21.0.10:8081/' /home/admin/node/conf/otter.properties"
    eval $cmd
    cmd="sed -i -e 's/^otter.zookeeper.cluster.default.*$/otter.zookeeper.cluster.default = ${ZOO_CLUSTER}/' /home/admin/node/conf/otter.properties"
    eval $cmd    
    cmd="su admin -c 'cd /home/admin/node/bin/ && echo ${ZOO_MY_ID:-1} > /home/admin/node/conf/nid && sh startup.sh ${ZOO_MY_ID:-1}>>/tmp/start_node.log 2>&1'"
    eval $cmd
    #check start
    checkStart "node" "nc 127.0.0.1 2088 -w 1 -z | wc -l" 120
}

function stop_node() {
    # stop node
    echo "stop node"
    su admin -c 'cd /home/admin/node/bin/ && sh stop.sh'
    echo "stop node successful ..."
}

function start_mysql() {
    echo "start mysql ..."
    # start mysql

    if [ -z "$(ls -A /var/lib/mysql)" ]; then
        cmd="sed -i -e  '1a log-bin=mysql-bin\nbinlog-format=ROW\ndefault-character-set=utf8\nserver-id=${ZOO_MY_ID:-1}' /etc/my.cnf"        
        eval $cmd   
        mysql_install_db --user=mysql --datadir=/var/lib/mysql 1>>/tmp/start.log 2>&1
        # These statements _must_ be on individual lines, and _must_ end with
        # semicolons (no line breaks or comments are permitted).
        # TODO proper SQL escaping on ALL the things D:
        TEMP_FILE='/tmp/init.sql'
        echo "grant all privileges on *.* to 'root'@'%' WITH GRANT OPTION ;" >> $TEMP_FILE
        echo "create database if not exists $MYSQL_DATABASE ;" >> $TEMP_FILE
        echo "create user $MYSQL_USER identified by '$MYSQL_USER_PASSWORD' ;" >> $TEMP_FILE
        echo "grant all privileges on $MYSQL_DATABASE.* to '$MYSQL_USER'@'%' identified by '$MYSQL_USER_PASSWORD' ;" >> $TEMP_FILE
        echo "grant all privileges on $MYSQL_DATABASE.* to '$MYSQL_USER'@'localhost' identified by '$MYSQL_USER_PASSWORD' ;" >> $TEMP_FILE        
        echo "update mysql.user set password=password('${MYSQL_ROOT_PASSWORD}') where user='root';" >> $TEMP_FILE
        echo "flush privileges;" >> $TEMP_FILE
        service mysqld start
        mysql -h127.0.0.1 -uroot -e "source $TEMP_FILE" 1>>/tmp/start.log 2>&1
        service mysqld restart

        checkStart "mysql" "echo 'show status' | mysql -s -P3306 -uroot -p$MYSQL_ROOT_PASSWORD | grep -c Uptime" 120

        # cmd="sed -i -e 's/#OTTER_MY_ZK#/127.0.0.1:2181/' /home/admin/bin/ddl.sql"
        # eval $cmd
        # cmd="sed -i -e 's/#OTTER_NODE_HOST#/127.0.0.1/' /home/admin/bin/ddl.sql"
        # eval $cmd
        cmd="mysql -h127.0.0.1 -u$MYSQL_USER -p$MYSQL_USER_PASSWORD $MYSQL_DATABASE -e 'source /home/admin/bin/ddl.sql' 1>>/tmp/start.log 2>&1"
        eval $cmd
        /bin/rm -f /home/admin/bin/ddl.sql
    else
        chown -R mysql:mysql /var/lib/mysql
        service mysqld start
        #check start
        checkStart "mysql" "echo 'show status' | mysql -b -s -P3306 -uroot -p$MYSQL_ROOT_PASSWORD | grep -c Uptime" 120
    fi
}

function stop_mysql() {
    echo "stop mysql ..."
    # stop mysql
    service mysqld stop
    echo "stop mysql successful ..."
}

echo "==> START ..."
start_mysql
start_zookeeper
start_node

echo -e "\033[32m ==> START SUCCESSFUL ... \033[0m"

netstat -tunlp

tail -f /dev/null &
# wait TERM signal
waitterm

echo "==> STOP"

stop_node
stop_zookeeper
stop_zookeeper
stop_mysql

echo "==> STOP SUCCESSFUL ..."
