USE `notes`;

DROP TABLE IF EXISTS `user`;

CREATE TABLE `user` (
  `username` CHAR(255) NOT NULL,
  `password` CHAR(255) NOT NULL,
  `salt` CHAR(255) NOT NULL,
  PRIMARY KEY (`username`)
);

DROP TABLE IF EXISTS `record`;

CREATE TABLE `record` (
  `author` CHAR(255) NOT NULL,
  `title` CHAR(255) NOT NULL,
  `file` CHAR(255) NOT NULL,
  PRIMARY KEY (`file`)
);

DROP TABLE IF EXISTS `record_spectator`;

CREATE TABLE `record_spectator` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `spectator` CHAR(255) NOT NULL,
  `record` CHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
);
