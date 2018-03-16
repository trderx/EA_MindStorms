# MYSQL 
# timezone GMT
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

# <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
# mysql_query("SET character_set_results = 'utf8', character_set_client = 'utf8', character_set_connection = 'utf8', character_set_database = 'utf8', character_set_server = 'utf8'");
SET NAMES 'utf8' COLLATE 'utf8_general_ci';
SET CHARSET "utf8";
SET CHARACTER SET "utf8";

CREATE DATABASE IF NOT EXISTS `fxstareu` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

# use database
USE fxstareu;

# create localhost user for insert data
CREATE USER 'fx'@'localhost' IDENTIFIED BY 'pass';
GRANT ALL PRIVILEGES ON fxstareu.* TO 'fx'@'localhost';
FLUSH PRIVILEGES;


# create localhost user for select data
CREATE USER 'user'@'localhost' IDENTIFIED BY 'pass';
GRANT SELECT ON fxstareu.* TO 'user'@'localhost';
FLUSH PRIVILEGES;

# revoke
# REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'USER'@'%';

# table account
create table TABLE IF NOT EXISTS account(time datetime, accountid int, balance float(10,2),equity float(10,2),margin float(10,2),freemargin float(10,2), currency varchar(20), leverage int, UNIQUE KEY `time` (`time`));

# table open and close signals
CREATE TABLE IF NOT EXISTS `OpenSignal` (
  `id` varchar(250) DEFAULT NULL,
  `symbol` varchar(250) DEFAULT '0',
  `volume` float DEFAULT '0',
  `type` varchar(250) DEFAULT '0',
  `opent` datetime,
  `openp` float(25,6) DEFAULT '0',
  `sl` float(25,6) DEFAULT '0',
  `tp` float(25,6) DEFAULT '0',
  `profit` float(55,2) DEFAULT '0',  
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `account` varchar(250) DEFAULT '0',
  `comment` text,
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `CloseSignal` (
  `id` varchar(250) DEFAULT NULL,
  `closet` datetime,
  `closep` float(25,6) DEFAULT '0',
  `profit` float(55,2) DEFAULT '0',
  `pips` float(25,2) DEFAULT '0',
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `account` varchar(250) DEFAULT '0',
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


# symbol M1 candles data + regression
CREATE TABLE IF NOT EXISTS `GBPJPY` (
  `time` datetime,
  `open` float(10,6) DEFAULT '0',
  `close` float(10,6) DEFAULT '0',
  `low` float(10,6) DEFAULT '0',
  `high` float(10,6) DEFAULT '0',
  `reg` float(10,6) DEFAULT '0',
  `reghigh` float(10,6) DEFAULT '0',  
  `reglow` float(10,6) DEFAULT '0',
  UNIQUE KEY `time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
