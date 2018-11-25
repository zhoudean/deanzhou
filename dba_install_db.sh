#!/bin/bash

rand() {
    min=$1
    max=$(($2-$min+1))
    num=$(cat /dev/urandom | head -n 10 | cksum | awk -F ' ' '{print $1}')
    echo $(($num%$max+$min))
}


mariadb_install() {
mariadb_num=`ps -ef | grep mysqld | grep "cnicg" | wc -l`

if [ "${mariadb_num}" != 0 ]; then
     echo "mariadb have already installed!"
     exit 1
fi

if [ -d "/cnicg/data/mariadb" ]; then
     echo "mariadb have data!"
     exit 1
fi

port=$(rand 1111 9999)

mkdir -pv /cnicg/app/mariadb10.2.13/mariadbdata/${port}/{binlog,redo,relaylog,temp}
mkdir -p /cnicg/{data/mariadb,conf/mariadb,logs/mariadb,run/mariadb}

wget -P /cnicg/app/mariadb10.2.13/ http://jumper.maintain.cniotroot.cn/soft/mariadb10.2.13.tar.gz
tar -zxvf /cnicg/app/mariadb10.2.13/mariadb10.2.13.tar.gz -C /cnicg/app/mariadb10.2.13
cat >> /cnicg/conf/mariadb/my.cnf <<'MUL'
[client]
default-character-set=utf8mb4
port  = 3283
socket  = /cnicg/app/mariadb10.2.13/mariadbdata/3283/mariadb.sock

[mysqld]
bind-address = 0.0.0.0
character-set-server = utf8mb4
user    = maintain
port    = 3283
socket  = /cnicg/app/mariadb10.2.13/mariadbdata/3283/mariadb.sock
basedir = /cnicg/app/mariadb10.2.13/mariadb
datadir = /cnicg/data/mariadb
log-error = /cnicg/logs/mariadb/mariadb_error.log
pid-file = /cnicg/run/mariadb/mariadb.pid
tmpdir = /cnicg/app/mariadb10.2.13/mariadbdata/3283/temp
relay-log-index = /cnicg/app/mariadb10.2.13/mariadbdata/3283/relaylog/relaylog
relay-log-info-file = /cnicg/app/mariadb10.2.13/mariadbdata/3283/relaylog/relaylog
relay-log = /cnicg/app/mariadb10.2.13/mariadbdata/3283/relaylog/relaylog
log-bin = /cnicg/app/mariadb10.2.13/mariadbdata/3283/binlog/binlog
log_bin_trust_function_creators = 1
binlog_cache_size = 4M
binlog_format = ROW 
max_binlog_cache_size = 128M
max_binlog_size = 1G
expire_logs_days = 7
open_files_limit = 10240
back_log = 600
max_connections = 5000
max_connect_errors = 6000
external-locking = FALSE
max_allowed_packet = 128M
sort_buffer_size = 1M
join_buffer_size = 1M
thread_cache_size = 300
query_cache_size = 512M
query_cache_limit = 2M
query_cache_min_res_unit = 2k
default-storage-engine = innodb
thread_stack = 192K
transaction_isolation = READ-COMMITTED
tmp_table_size = 246M
max_heap_table_size = 246M
key_buffer_size = 256M
read_buffer_size = 1M
read_rnd_buffer_size = 16M
bulk_insert_buffer_size = 64M
myisam_sort_buffer_size = 128M
myisam_max_sort_file_size = 10G
myisam_repair_threads = 1
myisam_recover

skip-name-resolve

server-id = 493283

# innodb_used
#innodb_additional_mem_pool_size = 16M
innodb_buffer_pool_size = 5G
innodb_data_file_path = ibdata1:256M:autoextend
innodb_file_io_threads = 4
innodb_thread_concurrency = 8
innodb_flush_log_at_trx_commit = 2
innodb_log_buffer_size = 16M
innodb_log_file_size = 128M
innodb_log_files_in_group = 3
innodb_max_dirty_pages_pct = 90
innodb_lock_wait_timeout = 120
innodb_file_per_table = 1

##add by deanzhou for slow_log
slow_query_log = 1
slow_query_log_file = /cnicg/app/mariadb10.2.13/mariadbdata/3283/slow.log
log_queries_not_using_indexes = 1
log_slow_admin_statements = 1
log_slow_slave_statements = 1
#log_throttle_queries_not_using_indexes = 10
long_query_time = 1 
min_examined_row_limit = 10000

##mariadb add by deanzhou for slave
#wsrep_gtid_mode=ON
log_slave_updates
master-info-repository=TABLE
relay-log-info-repository=TABLE
sync-master-info=1
slave-parallel-threads=2
binlog-checksum=CRC32
master-verify-checksum=1
slave-sql-verify-checksum=1
binlog-rows-query-log_events=1

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash
# Remove the next comment character if you are not familiar with SQL
#safe-updates

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
MUL

ipadd=`/sbin/ifconfig | grep 172`
if [ ! -n "$ipadd" ];then
    serverid=`/sbin/ifconfig | grep 192 | awk '{print $2}' | awk -F "." '{print $4}'`
else
    serverid=`/sbin/ifconfig | grep 172 | awk '{print $2}' | awk -F "." '{print $4}'`
fi
sed -i "s/493283/${serverid}${port}/g" /cnicg/conf/mariadb/my.cnf
sed -i "s/3283/${port}/g" /cnicg/conf/mariadb/my.cnf

/cnicg/app/mariadb10.2.13/mariadb/scripts/mysql_install_db --defaults-file=/cnicg/conf/mariadb/my.cnf  --user=maintain --basedir=/cnicg/app/mariadb10.2.13/mariadb --datadir=/cnicg/data/mariadb
/cnicg/app/mariadb10.2.13/mariadb/bin/mysqld_safe  --defaults-file=/cnicg/conf/mariadb/my.cnf &

rm -rf /cnicg/app/mariadb10.2.13/mariadb10.2.13.tar.gz
sudo sh -c "echo 'export PATH=/cnicg/app/mariadb10.2.13/mariadb/bin:\$PATH' >> /etc/profile"
echo "mariadb install complete"
}

mysql_install() {
mysql_num=`ps -ef | grep mysqld | grep "cnicg" | wc -l`

if [ "${mysql_num}" != 0 ]; then
     echo "mysql have already installed!"
     exit 1
fi

if [ -d "/cnicg/data/mysql" ]; then
     echo "mysql have data!"
     exit 1
fi

port=$(rand 1111 9999)

mkdir -pv /cnicg/app/mysql5.7.21/mysqldata/${port}/{binlog,redo,relaylog,temp,undo}
mkdir -p /cnicg/{data/mysql,conf/mysql,logs/mysql,run/mysql}

wget -P /cnicg/app/mysql5.7.21 http://jumper.maintain.cniotroot.cn/soft/mysql5.7.21.tar.gz 
tar -zxvf /cnicg/app/mysql5.7.21/mysql5.7.21.tar.gz -C /cnicg/app/mysql5.7.21
cat >> /cnicg/conf/mysql/my.cnf <<'MUL'
[client]
default-character-set = utf8mb4	
port    = 7289
socket  = /cnicg/app/mysql5.7.21/mysqldata/7289/mysql.sock

[mysqld]
bind-address = 0.0.0.0
skip_name_resolve = 1
character-set-server = utf8mb4
explicit_defaults_for_timestamp = 1
user    = maintain
port    = 7289
socket  = /cnicg/app/mysql5.7.21/mysqldata/7289/mysql.sock
basedir = /cnicg/app/mysql5.7.21/mysql
datadir = /cnicg/data/mysql
log_error = /cnicg/logs/mysql/mysql_error.log
pid-file = /cnicg/run/mysql/mysql.pid
tmpdir = /cnicg/app/mysql5.7.21/mysqldata/7289/temp
open_files_limit    = 10240
back_log = 600
max_connections = 5000
max_connect_errors = 6000
table_open_cache = 614
external-locking = FALSE
max_allowed_packet = 128M
sort_buffer_size = 1M
join_buffer_size = 1M
thread_cache_size = 300
#thread_concurrency = 8
query_cache_type = 0
query_cache_size = 0
#query_cache_limit = 2M
#query_cache_min_res_unit = 2k
default-storage-engine = innodb
thread_stack = 192K
transaction_isolation = READ-COMMITTED
tmp_table_size = 246M
max_heap_table_size = 246M
log-slave-updates
log-bin = /cnicg/app/mysql5.7.21/mysqldata/7289/binlog/binlog
log_bin_trust_function_creators = 1
binlog_cache_size = 4M
binlog_format = ROW
max_binlog_cache_size = 128M
max_binlog_size = 1G
relay-log-index = /cnicg/app/mysql5.7.21/mysqldata/7289/relaylog/relaylog
relay-log-info-file = /cnicg/app/mysql5.7.21/mysqldata/7289/relaylog/relaylog
relay-log = /cnicg/app/mysql5.7.21/mysqldata/7289/relaylog/relaylog
expire_logs_days = 7
key_buffer_size = 256M
read_buffer_size = 1M
read_rnd_buffer_size = 16M
bulk_insert_buffer_size = 64M
myisam_sort_buffer_size = 128M
myisam_max_sort_file_size = 10G
myisam_repair_threads = 1
#myisam_recover
#interactive_timeout = 120
#wait_timeout = 120
skip-name-resolve
server-id = 497289
#ssl
#ssl-ca = /cnicg/app/mysql5.7.19/mysql_ssl/cacert.pem
#ssl-cert = /cnicg/app/mysql5.7.19/mysql_ssl/mysql.crt
#ssl-key = /cnicg/app/mysql5.7.19/mysql_ssl/mysql.key

# Added by deanzhou, MySQL 5.7,innodb
#innodb_additional_mem_pool_size = 16M
innodb_buffer_pool_size = 5G
innodb_buffer_pool_instances = 8
innodb_buffer_pool_load_at_startup = 1
innodb_buffer_pool_dump_at_shutdown = 1
innodb_lru_scan_depth = 2000
innodb_io_capacity = 2000
innodb_io_capacity_max = 4000
innodb_data_file_path = ibdata1:256M:autoextend
innodb_thread_concurrency = 16
innodb_print_all_deadlocks = 1
innodb_strict_mode = 1
innodb_flush_log_at_trx_commit = 2
innodb_log_buffer_size = 16M
innodb_purge_threads = 4
innodb_large_prefix = 1
innodb_log_file_size = 1G
innodb_log_files_in_group = 3
innodb_max_dirty_pages_pct = 80
innodb_lock_wait_timeout = 120
innodb_file_per_table = 1
innodb_log_group_home_dir = /cnicg/app/mysql5.7.21/mysqldata/7289/redo
innodb_undo_directory = /cnicg/app/mysql5.7.21/mysqldata/7289/undo
innodb_undo_logs = 128
#innodb_undo_tablespaces = 3
innodb_buffer_pool_dump_pct = 40
innodb_page_cleaners = 4
innodb_undo_log_truncate = 1
innodb_max_undo_log_size = 2G
innodb_purge_rseg_truncate_frequency = 128
log_timestamps=system
#transaction_write_set_extraction=MURMUR32
show_compatibility_56=on

# Added by deanzhou for slow_log
slow_query_log = 1
slow_query_log_file = /cnicg/app/mysql5.7.21/mysqldata/7289/slow.log
log_queries_not_using_indexes = 1
log_slow_admin_statements = 1
log_slow_slave_statements = 1
log_throttle_queries_not_using_indexes = 10
long_query_time = 1
min_examined_row_limit = 10000

# Added by deanzhou
master_info_repository = TABLE
relay_log_info_repository = TABLE
sync_binlog = 1
gtid_mode = on
enforce_gtid_consistency = 1
log_slave_updates
relay_log_recovery = 1
binlog_gtid_simple_recovery = 1
slave_skip_errors = ddl_exist_errors

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash
# Remove the next comment character if you are not familiar with SQL
#safe-updates
default-character-set = utf8mb4

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
MUL

ipadd=`/sbin/ifconfig | grep 172`
if [ ! -n "$ipadd" ];then
    serverid=`/sbin/ifconfig | grep 192 | awk '{print $2}' | awk -F "." '{print $4}'`
else
    serverid=`/sbin/ifconfig | grep 172 | awk '{print $2}' | awk -F "." '{print $4}'`
fi
sed -i "s/497289/${serverid}${port}/g" /cnicg/conf/mysql/my.cnf 
sed -i "s/7289/${port}/g" /cnicg/conf/mysql/my.cnf

/cnicg/app/mysql5.7.21/mysql/bin/mysqld --defaults-file=/cnicg/conf/mysql/my.cnf --initialize-insecure  --basedir=/cnicg/app/mysql5.7.21/mysql --user=maintain --datadir=/cnicg/data/mysql 
/cnicg/app/mysql5.7.21/mysql/bin/mysqld_safe  --defaults-file=/cnicg/conf/mysql/my.cnf &

rm -rf /cnicg/app/mysql5.7.21/mysql5.7.21.tar.gz
sudo sh -c "echo 'export PATH=/cnicg/app/mysql5.7.21/mysql/bin:\$PATH' >> /etc/profile"
echo "mysql install complete"
}

mongodb_install() {
mongo_num=`ps -ef | grep mongod | grep "/cnicg" | wc -l` 

if [ "${mongo_num}" != 0 ]; then
       echo "mongodb have already installed!"
       exit 1
fi

if [ -d "/cnicg/data/mongodb" ]; then
     echo "mongodb have data!"
     exit 1
fi

port=$(rand 21111 29999)

mkdir -p /cnicg/app/mongodb3.4.9
mkdir -p /cnicg/{data/mongodb,conf/mongodb,logs/mongodb,run/mongodb}
wget -P /cnicg/app/mongodb3.4.9/ http://jumper.maintain.cniotroot.cn/soft/mongodb3.4.9.tar.gz
tar -zxvf /cnicg/app/mongodb3.4.9/mongodb3.4.9.tar.gz -C /cnicg/app/mongodb3.4.9

cat >> /cnicg/conf/mongodb/mongodb.conf <<'MUL'
systemLog:  
    quiet: false  
    path: /cnicg/logs/mongodb/mongodb.log  
    logAppend: false  
    destination: file  
processManagement:  
    fork: true  
    pidFilePath: /cnicg/run/mongodb/mongodb.pid  
net:  
    bindIp: 127.0.0.1,192.192.49.49
    port: 27017  
    maxIncomingConnections: 65536  
    wireObjectCheck: true  
    ipv6: false   
storage:  
    dbPath: /cnicg/data/mongodb
    indexBuildRetry: true  
    journal:  
        enabled: true  
    directoryPerDB: false  
    engine: wiredTiger  
    syncPeriodSecs: 60   
    wiredTiger:  
        engineConfig:  
            cacheSizeGB: 8  
            journalCompressor: snappy  
            directoryForIndexes: false    
        collectionConfig:  
            blockCompressor: snappy  
        indexConfig:  
            prefixCompression: true  
operationProfiling:  
    slowOpThresholdMs: 100  
    mode: off  
MUL


ipadd=`/sbin/ifconfig | grep 172`
if [ ! -n "$ipadd" ];then
    localip=`/sbin/ifconfig | grep 192 | awk '{print $2}'`
else
    localip=`/sbin/ifconfig | grep "172.16" | awk '{print $2}'`
fi
sed -i "s/27017/${port}/g" /cnicg/conf/mongodb/mongodb.conf
sed -i "s/192.192.49.49/${localip}/g" /cnicg/conf/mongodb/mongodb.conf

/cnicg/app/mongodb3.4.9/mongodb/bin/mongod -f /cnicg/conf/mongodb/mongodb.conf
rm -rf /cnicg/app/mongodb3.4.9/mongodb3.4.9.tar.gz
sudo sh -c "echo 'export PATH=/cnicg/app/mongodb3.4.9/mongodb/bin:\$PATH' >> /etc/profile"
echo "mongodb install complete!"
}

redis_install() {
redis_num=`ps -ef | grep redis | grep "/cnicg" | wc -l`

if [ "${redis_num}" != 0 ]; then
       echo "redis have already installed!"
	   exit 1
fi

if [ -d "/cnicg/data/redis" ]; then
     echo "redis have data!"
     exit 1
fi

port=$(rand 1111 9999)

mkdir -p /cnicg/app/redis4.0.9
mkdir -p /cnicg/{data/redis,conf/redis,logs/redis,run/redis}

wget -P /cnicg/app/redis4.0.9/ http://jumper.maintain.cniotroot.cn/soft/redis4.0.9.tar.gz
tar -zxvf /cnicg/app/redis4.0.9/redis4.0.9.tar.gz -C /cnicg/app/redis4.0.9
cat >> /cnicg/conf/redis/redis.conf <<EOF
daemonize yes

pidfile "/cnicg/run/redis/redis.pid"

port 6218

bind 127.0.0.1 192.192.49.49

timeout 300

tcp-keepalive 0

loglevel notice

logfile "/cnicg/logs/redis/redis.log"

databases 16

save 3600 1
save 900 60
save 300 1000
#save 120 5000

maxmemory 2gb
maxmemory-policy allkeys-lru
stop-writes-on-bgsave-error yes

requirepass "zHJkke3yks"

rdbcompression yes

rdbchecksum yes

dbfilename "dump.rdb"

dir "/cnicg/data/redis"

slave-serve-stale-data yes

slave-read-only yes

repl-disable-tcp-nodelay no

slave-priority 100

appendonly no

appendfsync everysec

no-appendfsync-on-rewrite no

auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

lua-time-limit 5000

slowlog-log-slower-than 10000

slowlog-max-len 128

hash-max-ziplist-entries 512
hash-max-ziplist-value 64

list-max-ziplist-entries 512
list-max-ziplist-value 64

set-max-intset-entries 512

zset-max-ziplist-entries 128
zset-max-ziplist-value 64

activerehashing yes

client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60

hz 10
EOF

ipadd=`/sbin/ifconfig | grep 172`
if [ ! -n "$ipadd" ];then
    localip=`/sbin/ifconfig | grep 192 | awk '{print $2}'`
else
    localip=`/sbin/ifconfig | grep "172.16" | awk '{print $2}'`
fi
sed -i "s/6218/${port}/g" /cnicg/conf/redis/redis.conf
sed -i "s/192.192.49.49/${localip}/g" /cnicg/conf/redis/redis.conf

/cnicg/app/redis4.0.9/bin/redis-server /cnicg/conf/redis/redis.conf
rm -rf /cnicg/app/redis4.0.9/redis4.0.9.tar.gz
sudo sh -c "echo 'export PATH=/cnicg/app/redis4.0.9/bin:\$PATH' >> /etc/profile"
echo "redis install complete!"
}

rabbitmq_install() {
wget -P /cnicg/app/ http://jumper.maintain.cniotroot.cn/soft/erlang19.3.tar.gz
wget -P /cnicg/app/ http://jumper.maintain.cniotroot.cn/soft/rabbitmq3.6.15.tar.gz

tar -zxvf /cnicg/app/erlang19.3.tar.gz
tar -zxvf /cnicg/app/rabbitmq3.6.15.tar.gz

sudo sh -c "echo 'export PATH=/cnicg/app/erlang/bin:\$PATH' >> /etc/profile"
sudo sh -c "echo 'export PATH=/cnicg/app/rabbitmq-3.6.15/sbin:\$PATH' >> /etc/profile"

source /etc/profile

rm -rf /cnicg/app/rabbitmq-3.6.15/var/lib/rabbitmq/mnesia/*

/cnicg/app/rabbitmq-3.6.15/sbin/rabbitmq-server &
 
rm -rf /cnicg/app/erlang19.3.tar.gz
rm -rf /cnicg/app/rabbitmq3.6.15.tar.gz

echo "rabbitmq install complete!"
}


case "$1" in
    mariadb_install)
           $1;;
    mysql_install)
           $1;;
    mongodb_install)
           $1;;
    redis_install)
           $1;;
    rabbitmq_install)
	       $1;;
    *)
       echo $"Usage: $0 {mariadb_install|mysql_install|mongodb_install|redis_install|rabbitmq_install|...}"
       exit 2
esac
