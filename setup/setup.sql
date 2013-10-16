CREATE DATABASE IF NOT EXISTS `modulePlusPlus`;
USE modulePlusPlus;

CREATE TABLE IF NOT EXISTS `users` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_hash`     VARCHAR(30)  BINARY NOT NULL,
    `user_name`     VARCHAR(20)  BINARY NOT NULL,
    `user_icon_url` VARCHAR(300) BINARY NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE (`user_hash`)
);

CREATE TABLE IF NOT EXISTS `modules` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `module_name` VARCHAR(100) BINARY NOT NULL,
    `dist_name` VARCHAR(100) BINARY NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE (`module_name`)
);
