#!/bin/bash

# ===================================================================================
# JEDINSTVENA INSTALACIJSKA SKRIPTA
#
# Ova skripta objedinjuje softver iz 'VAS_instalacije.sh' i 'TBP_instalacije.sh',
# koristeći najnovije verzije i preporučene metode instalacije.
# ===================================================================================

# Prebaci se u 'home' mapu
cd ~

# -------------------------------------------------
# 1. OSNOVNE POSTAVKE SUSTAVA I ALATI
# -------------------------------------------------
echo "--- 1. Ažuriranje sustava i instalacija osnovnih alata ---"
sudo apt-get update

# Omogući snapd
sudo rm -f /etc/apt/preferences.d/nosnap.pref
sudo apt-get install -y snapd
snap --version

# Instalacija osnovnih paketa, GIMP-a, Blendera, Jave, i Emacsa putem snap-a
sudo apt-get install -y wget curl git blender gimp default-jre default-jre-headless java-common
sudo apt-get install -y libsqliteodbc unixodbc-dev unixodbc odbc-postgresql libffi-dev 
sudo apt-get install -y python3 python3-pip python3-apt gnupg gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release
sudo snap install emacs --classic

# -------------------------------------------------
# 2. INSTALACIJA BAZA PODATAKA
# -------------------------------------------------
echo "--- 2. Instalacija baza podataka (PostgreSQL, MongoDB, Neo4j) ---"

# Instaliraj PostgreSQL (v16), PostGIS i QGIS
echo "Instaliram PostgreSQL, PostGIS i QGIS..."
sudo apt-get install -y postgresql postgresql-all postgresql-client postgresql-server-dev-all postgresql-plpython3-16 postgresql-pltcl-16
sudo apt-get install -y postgis postgresql-postgis qgis postgresql-postgis-scripts

# Instaliraj i postavi MongoDB (v8.0)
echo "Instaliram MongoDB..."
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo systemctl daemon-reload
sudo systemctl start mongod
sudo systemctl enable mongod

# Preuzmi i instaliraj Neo4J
echo "Instaliram Neo4J..."
curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/neo4j.gpg
echo "deb [signed-by=/usr/share/keyrings/neo4j.gpg] https://debian.neo4j.com stable latest" | sudo tee -a /etc/apt/sources.list.d/neo4j.list
sudo apt-get update
sudo apt-get install -y neo4j
sudo systemctl enable --now neo4j

# -------------------------------------------------
# 3. INSTALACIJA RAZVOJNIH ALATA I OKRUŽENJA
# -------------------------------------------------
echo "--- 3. Instalacija razvojnih alata (eXist-db, SWI-Prolog, Godot, DES) ---"

# Stvori mapu 'software' i uđi u nju
mkdir -p software
cd software

# Preuzmi i instaliraj eXist-db (v6.2.0)
echo "Instaliram eXist-db..."
wget -O exist.tar.bz2 https://github.com/eXist-db/exist/releases/download/eXist-6.2.0/exist-distribution-6.2.0-unix.tar.bz2
tar xjf exist.tar.bz2
mv exist-distribution* exist-db
rm exist.tar.bz2

# Instaliraj SWI Prolog, NodeJS, Elixir i ostale pakete
echo "Instaliram SWI Prolog, NodeJS i Elixir..."
sudo apt-get install -y gambas3 gambas3-gb-qt5-webkit gambas3-gb-qt5 swi-prolog swi-prolog-odbc odbcinst r-base r-cran-jsonlite nodejs elixir

# Preuzmi i instaliraj FLORA-2 (v2.1)
echo "Instaliram FLORA-2..."
wget -O flora2.run "https://downloads.sourceforge.net/project/flora/FLORA-2/2.1%20%28Punica%20granatum%29/flora2-2.1-RC1.run?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fflora%2Ffiles%2FLatest%2Fdownload"
chmod +x flora2.run
./flora2.run
rm flora2.run

# Preuzmi i instaliraj Datalog Educational System (DES)
echo "Instaliram DES..."
wget "https://sourceforge.net/projects/des/files/des/des6.7/DES6.7ACIDE0.18Linux64SICStus.zip" -O DES.zip
unzip -oq DES.zip
rm DES.zip
cd des
chmod +x des des_start
echo "PATH=${PWD/#$HOME/'~'}:$PATH" >> ~/.bashrc
cd ..

# Instaliraj Godot Engine putem snap-a
echo "Instaliram Godot Engine..."
sudo snap install gd-godot-engine-snapcraft

cd ~ # Vrati se u home direktorij

# -------------------------------------------------
# 4. POSTAVKA CONDA I PYTHON OKRUŽENJA
# -------------------------------------------------
echo "--- 4. Postavljanje Conda okruženja s Pythonom 3.10 ---"

wget https://repo.anaconda.com/miniconda/Miniconda3-py310_24.7.1-0-Linux-x86_64.sh -O Miniconda.sh
chmod +x Miniconda.sh
./Miniconda.sh -b
rm Miniconda.sh

cat <<\EOT > env.yml
name: foi
dependencies:
  - python=3.10
  - pip
  - pip:
    - zodb3
    - spade
    - flask
    - pexpect
    - pandas
    - spacy
    - ChatterBot2
    - chatterbot_corpus
    - nltk
    - pyyaml
    - ZODB
    - jsonpickle
    - sqlalchemy
    - neo4j
    - pymongo
    - networkx
    - geopandas
    - psycopg2-binary
    - git+https://github.com/AILab-FOI/pyxf
EOT

~/miniconda3/bin/conda env create -f env.yml
~/miniconda3/bin/conda run -n foi python3 -m spacy download en_core_web_sm
rm env.yml

~/miniconda3/bin/conda init bash
~/miniconda3/bin/conda config --set auto_activate_base false
echo 'conda activate foi' >> ~/.bashrc

# -------------------------------------------------
# 5. KONFIGURACIJA ALATA (EMACS, ODBC)
# -------------------------------------------------
echo "--- 5. Konfiguracija Emacsa i ODBC-a ---"

# Postavi Emacs za FLORA-2 i XSB Prolog
(
cat <<\EOT > .emacs
;; ===================================
;; XSB Prolog Setup
;; ===================================
(load "~/software/Flora-2/XSB/etc/prolog.el")
(add-to-list 'auto-mode-alist '("\\.P$" . prolog-mode))
(setq prolog-program-name "~/software/Flora-2/XSB/bin/xsb")

;; ===================================
;; Flora-2 Setup
;; ===================================
(load "~/software/Flora-2/flora2/emacs/flora.el")
(setq auto-mode-alist (cons '("\\.flr$" . flora-mode) auto-mode-alist))
(autoload 'flora-mode "flora" "Major mode for editing Flora programs." t)
(setq flora-program-path "~/software/Flora-2/flora2/runflora")

;; ===================================
;; MELPA Package Support
;; ===================================
(require 'package)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)
(package-initialize)
(when (not package-archive-contents)
  (package-refresh-contents))

(defvar myPackages
  '(better-defaults elpy flycheck py-autopep8 blacken ein material-theme))

(mapc #'(lambda (package)
          (unless (package-installed-p package)
            (package-install package)))
      myPackages)

;; ===================================
;; Basic Customization
;; ===================================
(setq inhibit-startup-message t)
(load-theme 'material t)
(global-linum-mode t)

;; ====================================
;; Development Setup
;; ====================================
(elpy-enable)
(when (require 'flycheck nil t)
  (setq elpy-modules (delq 'elpy-module-flymake elpy-modules))
  (add-hook 'elpy-mode-hook 'flycheck-mode))
(require 'py-autopep8)
(add-hook 'elpy-mode-hook 'py-autopep8-mode)
EOT
)

# Postavi ODBC postavke
(
cat <<EOF >.odbc.ini
[sqllitedb]
Description=My SQLite
Driver=SQLite3
Database=/tmp/sqldb.db
Username = vjezbe
Password = vjezbe

[baza]
Driver = PostgreSQL Unicode
Description = PostgreSQL Data Source
Servername = localhost
Port = 5432
Protocol = 16
UserName = vjezbe
Password = vjezbe
Database = vjezbe
EOF
)

# Dodaj sve potrebne staze u .bashrc
echo 'export PATH=~/software/exist-db/bin:~/software/Flora-2/flora2:~/software/Flora-2/XSB/bin:~/software/godot:$PATH' >> ~/.bashrc

# -------------------------------------------------
# 6. INSTALACIJA SERVISA (PROSODY, DOCKER, KAFKA)
# -------------------------------------------------
echo "--- 6. Instalacija servisa (Prosody, Docker, Kafka) ---"

# Instaliraj XMPP server Prosody
echo "Instaliram Prosody XMPP server..."
sudo apt-get install -y prosody
wget -O prosody.cfg.lua https://pastebin.com/raw/j1CLcSLH
sudo mv prosody.cfg.lua /etc/prosody/prosody.cfg.lua
sudo systemctl restart prosody

# Instaliraj Docker i docker-compose
echo "Instaliram Docker i Docker Compose..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Pripremi docker-compose datoteku za Kafku
echo "Pripremam Kafka docker-compose datoteku..."
(
cat <<EOF >kafka-ksqldb.yml
version: '2'

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:6.0.1
    hostname: zookeeper
    container_name: zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000

  broker:
    image: confluentinc/cp-enterprise-kafka:6.0.1
    hostname: broker
    container_name: broker
    depends_on:
      - zookeeper
    ports:
      - "29092:29092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://broker:9092,PLAINTEXT_HOST://localhost:29092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1

  ksqldb-server:
    image: confluentinc/ksqldb-server:0.14.0
    hostname: ksqldb-server
    container_name: ksqldb-server
    depends_on:
      - broker
    ports:
      - "8088:8088"
    environment:
      KSQL_LISTENERS: http://0.0.0.0:8088
      KSQL_BOOTSTRAP_SERVERS: broker:9092
      KSQL_KSQL_LOGGING_PROCESSING_STREAM_AUTO_CREATE: "true"
      KSQL_KSQL_LOGGING_PROCESSING_TOPIC_AUTO_CREATE: "true"

  ksqldb-cli:
    image: confluentinc/ksqldb-cli:0.14.0
    container_name: ksqldb-cli
    depends_on:
      - broker
      - ksqldb-server
    entrypoint: /bin/sh
    tty: true
EOF
)

# -------------------------------------------------
# 7. ZAVRŠETAK
# -------------------------------------------------
# Instaliraj Jupyter Notebook
sudo apt-get install -y jupyter jupyter-notebook

# Ukloni nepotrebne pakete
sudo apt autoremove -y

echo ""
echo "============================================================"
echo "SVE INSTALACIJE SU ZAVRŠENE!"
echo "Molim vas ponovno pokrenite terminal ili se odjavite i prijavite"
echo "kako bi sve promjene (posebno PATH i Conda) postale aktivne."
echo "============================================================"