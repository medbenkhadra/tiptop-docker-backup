export BORG_PASSPHRASE='F2i2024@grp7'
/usr/bin/borg create /backup::sauvegarde__$(date +%Y-%m-%d_%H-%M-%S) ~/docker



#methods
backup_mysql_databases() {
    local container_name="$1"
    local backup_directory="$2"

    mkdir -p "$backup_directory/mysql"

    current_date=$(date +%Y-%m-%d)

    databases=$(docker exec "$container_name" sh -c 'mysql -sN -e "show databases;"')

    for db_name in $databases; do
        docker exec "$container_name" sh -c "mysqldump -u root $db_name > /var/lib/mysql/$db_name-$current_date.sql"
        docker cp "$container_name":/var/lib/mysql/$db_name-$current_date.sql "$backup_directory/mysql/"
    done

    echo "Backup for all MySQL databases in container $container_name completed."
}



backup_container() {
    local container_name="$1"
    local backup_directory="$2"
    local backup_name="$container_name" # Assuming backup name is the same as container name

    mkdir -p "$backup_directory/$container_name"

    docker exec --volumes "$container_name" sh -c "tar -czf - /" > "$backup_directory/$container_name/$container_name_backup.tar.gz"

    /usr/bin/borg create /backup::$backup_name "$backup_directory/$container_name"

    echo "Backup for container $container_name completed."
}



delete_old_backups() {
    local backup_directory="$1"
    local weeks_to_keep="$2"

    echo "Deleting backups older than $weeks_to_keep weeks in $backup_directory"

    find "$backup_directory" -type f -name "*.sql" -mtime +$((7 * $weeks_to_keep)) -delete

    echo "Old backups deletion completed."
}


#delete old backups 
delete_old_backups "/backup" 2


# docker folder backup
backup_docker_folder "/backup/docker" "docker"


# databases backups
backup_mysql_databases "docker-db-1" "/backup/databases/prod/"
backup_mysql_databases "docker-db_test-1" "/backup/databases/test/"
backup_mysql_databases "docker-db_preprod-1" "/backup/databases/preprod/"
backup_mysql_databases "docker-db_dev-1" "/backup/databases/dev/"




# Backup Docker containers ( 
#backup_container "docker-frontend-1" "/backup/containers"
#backup_container "docker-frontend-dev-1" "/backup/containers"
#backup_container "docker-backend-dev-1" "/backup/containers"
#backup_container "docker-backend-1" "/backup/containers"
#backup_container "docker-backend-preprod-1" "/backup/containers"
#backup_container "docker-frontend-staging-1" "/backup/containers"
#backup_container "docker-backend-staging-1" "/backup/containers"
#backup_container "docker-frontend-preprod-1" "/backup/containers"
#backup_container "docker-gateway-1" "/backup/containers"
#backup_container "docker-sonarqube-1" "/backup/containers"
#backup_container "docker-sonarqube-db-1" "/backup/containers"
#backup_container "docker-prometheus-1" "/backup/containers"
#backup_container "docker-grafana-1" "/backup/containers"
#backup_container "docker-portainer-1" "/backup/containers"
#backup_container "docker-alertmanager-1" "/backup/containers"

