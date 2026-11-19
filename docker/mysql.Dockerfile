FROM mysql:8.4

# No test-database init scripts or demo data are included in this image.
COPY scripts/mysql_backup.sh /usr/local/bin/secury-mysql-backup
RUN chmod 0755 /usr/local/bin/secury-mysql-backup

CMD ["mysqld", "--character-set-server=utf8mb4", "--collation-server=utf8mb4_0900_ai_ci", "--default-time-zone=+00:00"]
