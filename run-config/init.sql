create database if not exists moodle character set utf8mb4 collate utf8mb4_bin;
GRANT ALL PRIVILEGES ON moodle.* TO 'dev'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
