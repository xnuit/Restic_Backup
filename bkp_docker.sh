#!/bin/bash
export RESTIC_REPOSITORY=/etc/restic
export RESTIC_PASSWORD=
BACKUP_DIR=/etc/restic/backups
DATE=$(date +%F)

# Initialiser le dépôt Restic (à faire une seule fois)
if [ ! -d "$BACKUP_DIR/restic-repo" ]; then
 restic init
fi

# Créer le répertoire de sauvegarde si nécessaire
mkdir -p $BACKUP_DIR

# Sauvegarder les volumes Docker
volumes=$(docker volume ls --format '{{.Name}}')
for volume in $volumes; do
 docker run --rm -v ${volume}:/data -v $BACKUP_DIR:/backup alpine tar czvf /backup/${volume}_backup_${DATE}.tar.gz -C /data .
done

# Sauvegarder les configurations des conteneurs
containers=$(docker ps -a --format '{{.ID}} {{.Names}}')
for container in $containers; do
 container_id=$(echo $container | awk '{print $1}')
 container_name=$(echo $container | awk '{print $2}')
 docker inspect $container_id > $BACKUP_DIR/${container_name}_config_${DATE}.json
done

# Sauvegarder les images Docker
images=$(docker images --format '{{.Repository}}:{{.Tag}}')
for image in $images; do
 image_filename=$(echo $image | tr '/:' '_')
 docker save -o $BACKUP_DIR/${image_filename}_image_${DATE}.tar $image
done

# Ajouter les archives de sauvegarde à Restic
restic backup $BACKUP_DIR/*_backup_${DATE}.tar.gz
restic backup $BACKUP_DIR/*_config_${DATE}.json
restic backup $BACKUP_DIR/*_image_${DATE}.tar

# Nettoyer les fichiers de sauvegarde locaux si nécessaire
#              # rm $BACKUP_DIR/*_backup_${DATE}.tar.gz
#              # rm $BACKUP_DIR/*_config_${DATE}.json
#              # rm $BACKUP_DIR/*_image_${DATE}.tar
