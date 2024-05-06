# Webserver Setup

Docker driven apache webserver setup for apple computers providing PHP, MYSQL, phpMyAdmin and Mailhog. The repo contains helpful scripts to handle things like **virtual hosts configuration**, **certificate creation**, and **project management**.

---

## Docker Services

* [php](https://hub.docker.com/_/php)
* [mysql](https://hub.docker.com/_/mysql)
* [phpmyadmin](https://hub.docker.com/_/phpmyadmin)
* [jcalonso/mailhog](https://hub.docker.com/r/jcalonso/mailhog)

---

## Setup

### 💻 Webserver

1. Clone the repository somewhere on your local machine
2. Update variables to fit your setup in: [.profile](./.profile), [add-project.sh](./apache/add-project.sh)
3. Install [Docker](https://docs.docker.com/desktop/install/mac-install/)
4. Build webserver image if not already done so. Don’t forget to name (`-t`) the image  `webserver-phpx.x` because some bash scripts are setup to search for this pattern: `docker build -t webserver-php8.1 -f /path/to/images/webserver-php8.1 .`
5. Create volumes
    * Webserver root volume `docker volume create webserver-root --opt type=none --opt device=/path/to/webserver-root --opt o=bind`
    * MySql volume `docker volume create webserver-mysql-data --opt type=none --opt device=/path/to/webserver-mysql-data --opt o=bind`
6. Add an entry to your `/etc/hosts` file: `127.0.0.1 mysql`. By doing so, your system will resolve the hostname `mysql` to localhost.
7. Initialize a Docker swarm `docker swarm init`
8. Run the webserver swarm `docker stack deploy -c /path/to/docker-compose.yml webserver`
9. Granting the dbuser access in the MySQL container `GRANT ALL PRIVILEGES ON *.* TO 'dbuser'@'%';`. Since the MySQL data directory is configured to persist, this only needs to be run once per initial setup.

### 🎨 Project

To add a new project you can try to use the [add-project.sh](./apache/add-project.sh) script from the [apache](./apache) directory (or call `spadd` in the terminal if you are using the repositories [.profile](./.profile)).

If you want to do all of it manually, be sure to follow those necessary steps:

1. Create a new project directory inside your [webserver-root](./apache/webserver-root)
2. Configure your virtual host for this project in [vhosts.conf](./apache/vhosts.conf)
3. Resolve the project url to localhost by adding an entry to your `/etc/hosts` file e.g.: `127.0.0.1 project.local`
4. Start/Restart the docker webserver

---

## Files & Folders

...............................................................

### 📁 Apache

* [apache](./apache)

Folder for all stuff related to the PHP webserver.

* ↳ [webserver-root](./apache/webserver-root)

The default webserver root directory. You will find an example project in it. The `.gitignore` is set to ignore changes in this folder.

* ↳ [add-project.sh](./apache/add-project.sh)

Script to setup a new web project. This script will try to do all the necessary steps. By specifying a project name, it will start the webserver if it is not already running, create project directory in your webroot, create default virtual host configuration file, update hosts entries, create default nix file, create apache log files, ask to setup wordpress, create a self signed certificate…)

* ↳ [certificate-add.sh](./apache/certificate-add.sh)
* ↳ [certificate-remove.sh](./apache/certificate-remove.sh)

Scripts to add/remove a valid self signed certificate. The certificate will be valid for 20 years.

* ↳ [hosts-add.sh](./apache/hosts-add.sh)
* ↳ [hosts-remove.sh](./apache/hosts-remove.sh)

Scripts to add/remove entries from the `/etc/hosts` file.

* ↳ [shell.nix](./apache/shell.nix)

Nix shell configuration file to have everything needed to run the scripts inside this folder. You can start a nix shell from this file without the need to install any dependencies to your own system.

* ↳ [vhosts.conf](./apache/vhosts.conf)

Virtual hosts configuration which will be loaded into the webserver on start.

* ↳ [vhosts.sh](./apache/vhosts.sh)

Concatenates all apache virtual hosts config files from the project folders from within the webroot to [vhosts.conf](./apache/vhosts.conf).

...............................................................

### 📁 Images

* [images](./images)

Folder for all docker images.

* ↳ [webserver-php7.4](./images/webserver-php7.4)
* ↳ [webserver-php8.1](./images/webserver-php8.1)

Webserver images are ready for PHP v7.4 and v8.1. Just change the PHP version `FROM php:X.X-apache` to run your desired PHP version. The image will install required dev tools, composer, WP-CLI, Oh My Zsh and setup Mailhog.

...............................................................

### 📁 MySQL

* [mysql](./mysql)

Folder for all stuff related to the MySQL service.

* ↳ [webserver-mysql-data](./mysql/webserver-mysql-data)

The default MySQL data directory. The `.gitignore` is set to ignore changes in this folder.

* ↳ [root-password.txt](./mysql/root-password.txt)

MySQL root password file. Default user creds for MySQL and phpMyAdmin: `dbuser` & `dbpass`

...............................................................

### 📁 PHP

* [php](./php)

Folder for all stuff related to the PHP service.

* ↳ [local.ini](./php/local.ini)

Default PHP ini configuration. Sets `sendmail_path` to make Mailhog available.

...............................................................

### 📁 sSMTP

* [ssmtp](./ssmtp)

Folder for all stuff related to the sSMTP configuration.

* ↳ [ssmtp.conf](./ssmtp/ssmtp.conf)

Default sSMTP configuration to make Mailhog available.

...............................................................

### 📁 Others

* [.profile](./.profile)

Bash profile with helpful `aliases` and `functions` for webserver handling. JLoad this file in your own profile: `source /path/to/repository/.profile`

* [docker-compose.yml](./docker-compose.yml)

Docker Compose file. As for now, you only need to change this file if you would like to run another PHP version. If so change the PHP service image to your custom image.

* [readme.md](./readme.md)

Hey it's me!

...............................................................
