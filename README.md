# docker-backup
A backup solution for containers. It covers data backups via Duplicity (duply) and Mysql/Mariadb Backups via mysqldump. Scheduling is provided via crond.

Features:

- Duplicity Backups via duply
- Mysql/Mariadb Backup [Work in Progress]
- Scheduling via crond

## Get latest image
     docker pull alinmear/docker-backitup:latest

## Create a 'docker-compose.yml'
```yaml
version: '2'

services:
  backup:
    image: alinmear/docker-backitup:latest
    volumes:
      - /tmp/backup_src:/backup_root:ro
      - /tmp/backup:/backup
      - /tmp/duply_export:/duply_export
    links:
      - mariadb:mysql
    environment:
        MYSQL_USER: root
        MYSQL_PASS: root

  mariadb:
    image: mariadb
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: test
```

## Export duply profiles 
This will export the duply profile folder to the `/duply_export' target.

*NOTE*: Copy this to a save place, because within the duply folder the keys are stored as well as the password within the config file of duply.

```bash
docker run -it --rm --volumes-from <main-container> alinmear/docker-backup:latest export
```

## Env Variables

### ENABLE_CRON
      - **yes** => Cron is enabled
      - no 	=> disabled

#### GPG_GEN_KEY_TYPE
     - **RSA**	=> default type

#### GPG_GEN_KEY_LENGTH
     - **2048**	=> default complexity

#### GPG_GEN_SUBKEY_TYPE
     - **RSA**

#### GPG_GEN_SUBKEY_LENGTH
     - **2048**	=> default complexity

#### GPG_GEN_NAME
     - **Docker Backup**

#### GPG_GEN_EMAIL
     - **backup@localhost**

#### GPG_GEN_PASS
     - **generated via pwgen**

#### MYSQL_HOST
     - **mysql**

#### MYSQL_PORT

#### MYSQL_USER

#### MYSQL_PASS

#### MYSQL_DBS

#### MYSQL_MAX_BACKUPS

#### MYSQL_PARAMS

#### DUPLY_SOURCE
     - **`/backup_source/`**

#### DUPLY_TARGET
     - **`file:///backup/data/`**

#### DUPLY_INCLIST

#### DUPLY_EXCLIST

#### DUPLY_ENCRYPTION
     - **yes**

#### DUPLY_GPG_PW

#### DUPLY_VOLSIZE
     - **100**

#### DUPLY_MAX_AGE
     - **2M**

#### DUPLY_MAX_FULL_BACKUPS
     - **2**

#### DUPLY_MAX_FULLS_WITH_INCRS
     - **1**

#### DUPLY_MAX_FULLBKP_AGE
     - **1M**

#### DUPLY_CRON
     - `'*/1 * * * *'`

#### MYSQL_CRON
     - `'*/1 * * * *'`
