#!/bin/bash

# ===================================================================================
# KONAČNA INSTALACIJSKA SKRIPTA v3.0
#
# Autor: Gemini (uz pomoć korisnika)
# Datum: 17. lipnja 2025.
#
# Svrha: Potpuna automatizacija postavljanja razvojnog okruženja za Linux Mint 21.2
# (Ubuntu 22.04 "jammy") unutar VirtualBox-a.
#
# Skripta uključuje:
# - Ispravak rezolucije ekrana (VirtualBox Guest Additions)
# - Instalaciju Visual Studio Code-a
# - Postavljanje C/C++ okruženja (gcc, g++, gdb)
# - Postavljanje Python 3.9 i SPADE 3.3.2 okruženja putem Conda-e
# - Instalaciju svih alata iz originalnih skripti s potrebnim ispravcima.
#
# UPUTA: Skriptu je potrebno pokrenuti DVA puta.
# 1. Prvi put: Instaliraju se preduvjeti i daje se uputa za restart.
# 2. Drugi put (nakon restarta): Instalira se sav preostali softver.
# ===================================================================================

# --- PROVJERA VIRTUALBOX GUEST ADDITIONS ---
# Ovaj dio se izvršava samo ako Guest Additions NISU instalirani.
if ! lsmod | grep -q "vboxguest"; then
  echo "--- KORAK 1: INSTALACIJA VIRTUALBOX GUEST ADDITIONS ---"
  echo "Čini se da VirtualBox Guest Additions nisu instalirani. Skripta će sada instalirati potrebne preduvjete."
  
  sudo apt-get update
  sudo apt-get install -y build-essential dkms linux-headers-$(uname -r)
  
  echo
  echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo "VAŽNO: SADA SLIJEDITE OVE KORAKE RUČNO"
  echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo "1. U izborniku VirtualBox prozora (na vrhu) odaberite: Devices > Insert Guest Additions CD image..."
  echo "2. Ako se u Mintu pojavi prozor s pitanjem za pokretanje, kliknite 'Run' i unesite svoju lozinku."
  echo "3. Ako se prozor ne pojavi, otvorite File Manager, nađite CD ikonu, desni klik > Open in Terminal i tamo pokrenite: sudo ./VBoxLinuxAdditions.run"
  echo "4. Nakon što instalacija završi, OBAVEZNO RESTARTAJTE virtualnu mašinu."
  echo ""
  echo ">>> Nakon restarta, PONOVO POKRENITE OVU ISTU SKRIPTU da nastavite s instalacijom. <<<"
  echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  
  # Prekini izvršavanje skripte i pričekaj da korisnik odradi ručne korake i restart.
  exit 0
fi

# Ako je skripta ponovno pokrenuta nakon instalacije Guest Additions, nastavlja odavde.
echo "--- VirtualBox Guest Additions su prisutni. Nastavljam s glavnom instalacijom... ---"

# --- GLAVNA INSTALACIJA ---

cd ~

# 1. OSNOVNI ALATI, C/C++ I VISUAL STUDIO CODE
echo "--- 1. Instaliram osnovne alate, C/C++ kompajlere i VS Code ---"
sudo apt-get update
# Ovdje su svi osnovni paketi zajedno, uključujući C/C++ alate (build-essential, gdb)
sudo apt-get install -y wget curl git blender gimp default-jre default-jre-headless java-common \
                        libsqliteodbc unixodbc-dev unixodbc odbc-postgresql libffi-dev \
                        python3 python3-pip gnupg gnupg2 software-properties-common apt-transport-https \
                        ca-certificates lsb-release build-essential gdb

# Instalacija VS Code-a
echo "--> Instaliram Visual Studio Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
rm -f packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
sudo apt-get update
sudo apt-get install -y code

# Instalacija Emacsa
echo "--> Instaliram Emacs..."
sudo snap install emacs --classic

# 2. BAZE PODATAKA (S ISPRAVCIMA)
echo "--- 2. Instaliram baze podataka (PostgreSQL, MongoDB, Neo4j) ---"

# PostgreSQL (s ispravnim verzijama dodataka)
echo "--> Instaliram PostgreSQL v14 i dodatke..."
sudo apt-get install -y postgresql postgresql-all postgresql-client postgresql-server-dev-all postgis postgresql-postgis qgis postgresql-postgis-scripts
sudo apt-get install -y postgresql-plpython3-14 postgresql-pltcl-14

# MongoDB (s ispravnim 'jammy' repozitorijem)
echo "--> Instaliram MongoDB..."
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo systemctl daemon-reload
sudo systemctl start mongod
sudo systemctl enable mongod

# Neo4j
echo "--> Instaliram Neo4j..."
curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/neo4j.gpg
echo "deb [signed-by=/usr/share/keyrings/neo4j.gpg] https://debian.neo4j.com stable latest" | sudo tee /etc/apt/sources.list.d/neo4j.list
sudo apt-get update
sudo apt-get install -y neo4j
sudo systemctl enable --now neo4j

# 3. PYTHON, CONDA I SPADE OKRUŽENJE (S ISPRAVCIMA)
echo "--- 3. Postavljam Conda okruženje s Pythonom 3.9 i SPADE 3.3.2 ---"
mkdir -p software
cd software

# Instalacija Miniconda
echo "--> Instaliram Miniconda..."
wget https://repo.anaconda.com/miniconda/Miniconda3-py39_23.10.0-1-Linux-x86_64.sh -O Miniconda.sh
chmod +x Miniconda.sh
./Miniconda.sh -b -p ~/miniconda3
rm Miniconda.sh

# Kreiranje `env.yml` datoteke za Python 3.9, bez pyxf
cat <<\EOT > env.yml
name: foi
dependencies:
  - python=3.9
  - pip
  - pip:
    - spade==3.3.2
    - requests
    - zodb3
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
EOT

echo "--> Kreiram Conda okruženje 'foi' s Pythonom 3.9..."
~/miniconda3/bin/conda env create -f env.yml

echo "--> Instaliram dodatne Python pakete (pyxf) i spacy model unutar 'foi' okruženja..."
~/miniconda3/bin/conda run -n foi pip install git+https://github.com/AILab-FOI/pyxf
~/miniconda3/bin/conda run -n foi python -m spacy download en_core_web_sm

rm env.yml

# Inicijalizacija Conda-e za shell
~/miniconda3/bin/conda init bash
~/miniconda3/bin/conda config --set auto_activate_base false
echo 'conda activate foi' >> ~/.bashrc

# 4. OSTALI RAZVOJNI ALATI
echo "--- 4. Instaliram ostale alate (eXist-db, FLORA-2, itd.) ---"
# Ostatak alata iz originalne skripte
# ...
cd ~/software # Osiguraj da smo u ispravnoj mapi

echo "--> Instaliram eXist-db..."
wget -O exist.tar.bz2 https://github.com/eXist-db/exist/releases/download/eXist-6.2.0/exist-distribution-6.2.0-unix.tar.bz2
tar xjf exist.tar.bz2
mv exist-distribution* exist-db
rm exist.tar.bz2

echo "--> Instaliram SWI Prolog, Elixir..."
sudo apt-get install -y swi-prolog swi-prolog-odbc r-base r-cran-jsonlite nodejs elixir

echo "--> Instaliram FLORA-2..."
wget -O flora2.run "https://downloads.sourceforge.net/project/flora/FLORA-2/2.1%20%28Punica%20granatum%29/flora2-2.1-RC1.run?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fflora%2Ffiles%2FLatest%2Fdownload"
chmod +x flora2.run
./flora2.run
rm flora2.run

echo "--> Instaliram DES..."
wget "https://sourceforge.net/projects/des/files/des/des6.7/DES6.7ACIDE0.18Linux64SICStus.zip" -O DES.zip
unzip -oq DES.zip
rm DES.zip
cd des
chmod +x des des_start
echo "PATH=${PWD/#$HOME/'~'}:$PATH" >> ~/.bashrc
cd ..

cd ~

# 5. DOCKER I ZAVRŠNE POSTAVKE
echo "--- 5. Instaliram Docker i dovršavam konfiguraciju ---"

# Docker (s ispravnim 'jammy' repozitorijem)
echo "--> Instaliram Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Priprema za Kafku
echo "--> Pripremam Kafka docker-compose datoteku..."
# ... (ostatak kafka-ksqldb.yml datoteke ostaje isti)
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

# Završno čišćenje
sudo apt autoremove -y

echo ""
echo "======================================================================="
echo " SVI ZADACI SKRIPTE SU ZAVRŠENI! "
echo ""
echo "Molim vas, ZATVORITE i PONOVNO OTVORITE terminal kako bi sve"
echo "promjene (posebno PATH i Conda) postale aktivne."
echo "======================================================================="
