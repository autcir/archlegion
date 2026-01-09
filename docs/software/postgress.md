# 🗄️ PostgreSQL Installation and Setup on Arch Linux

> Complete PostgreSQL setup with remote access configuration

This guide will walk you through the process of installing PostgreSQL, setting it up on your Arch Linux system, and configuring it for remote access. Additionally, it covers how to manage PostgreSQL databases and connect to them remotely using tools like DBeaver.

---

## 📋 Prerequisites

- An Arch Linux system
- Root (sudo) privileges
- Internet connection

---

## 📚 Table of Contents

- [1. Install PostgreSQL](#1-install-postgresql)
- [2. Initialize PostgreSQL](#2-initialize-postgresql)
- [3. Start and Enable PostgreSQL Service](#3-start-and-enable-postgresql-service)
- [4. Basic PostgreSQL Usage](#4-basic-postgresql-usage)
- [5. Configure PostgreSQL for Remote Access](#5-configure-postgresql-for-remote-access)
- [6. Install DBeaver](#6-install-dbeaver)
- [7. Security Best Practices](#7-security-best-practices)
- [8. Troubleshooting](#8-troubleshooting)

---

## 1. Install PostgreSQL

To install PostgreSQL on Arch Linux, first update your system and install the required packages.

```bash
sudo pacman -Syu
sudo pacman -S postgresql
```

Check the PostgreSQL version to ensure that it has been installed correctly:

```bash
postgres --version
```

---

## 2. Initialize PostgreSQL

Next, initialize the PostgreSQL database. You need to set the locale to `it_IT.UTF-8` for correct character encoding.

```bash
sudo -u postgres initdb --locale it_IT.UTF-8 -D /var/lib/postgres/data
```

---

## 3. Start and Enable PostgreSQL Service

Start the PostgreSQL service and enable it to run at startup.

```bash
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

Check the status of the service to ensure it's running:

```bash
sudo systemctl status postgresql
```

---

## 4. Basic PostgreSQL Usage

To interact with PostgreSQL, switch to the `postgres` user and run `psql` (PostgreSQL shell):

```bash
su - postgres
sudo psql
```

### Change Password for the `postgres` User

To change the password for the default `postgres` user:

```sql
alter user postgres with password 'your-new-password';
```

### Create a New Database

To create a new database:

```sql
CREATE DATABASE mydb;
```

### List All Databases

To list all databases:

```sql
\l
```

### Create a New User and Set a Password

To create a new user with a password:

```sql
CREATE USER user1 WITH ENCRYPTED PASSWORD 'password';
```

### Grant Privileges to the New User

To grant all privileges on the newly created database to `user1`:

```sql
GRANT ALL PRIVILEGES ON DATABASE mydb to user1;
```

### Switch Database

To switch to the newly created database:

```sql
\c mydb
```

### Exit PostgreSQL Shell

To exit the PostgreSQL shell:

```sql
\q
```

---

## 5. Configure PostgreSQL for Remote Access

To allow remote connections to PostgreSQL, follow these steps:

### Edit PostgreSQL Configuration

Open the `postgresql.conf` file and modify the `listen_addresses` setting:

```bash
sudo nano /var/lib/postgres/data/postgresql.conf
```

Find the line that defines `listen_addresses` and set it to your server's IP address (or `'*'` for all interfaces):

```plaintext
listen_addresses = 'your-server-ip'
```

### Modify `pg_hba.conf` for Remote Access

Next, open the `pg_hba.conf` file to configure client authentication.

```bash
sudo nano /var/lib/postgres/data/pg_hba.conf
```

Find the following line:

```plaintext
host    all             all             127.0.0.1/32            trust
```

Replace it with:

```plaintext
host    all             all             all            trust
```

This change allows all IPs to connect without a password. You may want to configure more secure authentication methods later.

### Restart PostgreSQL Service

To apply the changes, restart PostgreSQL:

```bash
sudo systemctl restart postgresql
```

---

## 6. Install DBeaver

DBeaver is a popular database management tool that supports PostgreSQL. You can install it from the official Arch repositories:

```bash
sudo pacman -S dbeaver
```

Once installed, you can open DBeaver and connect to your PostgreSQL database using the server's IP address, the database name, and the user credentials.

---

## 7. Security Best Practices

### Change Default Password

Always change the default `postgres` user password:

```sql
ALTER USER postgres WITH PASSWORD 'strong-password';
```

### Use Strong Authentication

In `pg_hba.conf`, prefer `md5` or `scram-sha-256` over `trust`:

```plaintext
host    all             all             192.168.1.0/24          md5
```

### Limit Remote Access

Only allow connections from specific IP ranges, not all IPs (`*`).

### Regular Backups

```bash
sudo -u postgres pg_dump mydb > backup.sql
```

---

## 8. Troubleshooting

### Service Not Starting

If PostgreSQL doesn't start, check the logs:

```bash
sudo journalctl -u postgresql
```

### Remote Connection Issues

Ensure that your firewall allows traffic on port `5432`:

```bash
sudo ufw allow 5432/tcp
```

### Authentication Errors

Ensure that the `pg_hba.conf` file is correctly configured and that the user has the necessary privileges.

---

## 📖 Related Documentation

- [PostgreSQL Management Tips](postgress_tips.md) - User and database management
- [GNOME Keyring](gnome_keyring.md) - Secure credential storage
- [README](../README.md) - Main installation guide

---

## 📄 License

MIT License - See [LICENSE](../../LICENSE) for details.
