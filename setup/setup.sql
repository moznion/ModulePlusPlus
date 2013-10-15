CREATE DATABASE IF NOT EXISTS `modulePlusPlus`;
USE modulePlusPlus;

CREATE TABLE IF NOT EXISTS `users` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_hash` VARCHAR(30) NOT NULL,
    `user_name` VARCHAR(20) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE (`user_hash`)
);

CREATE TABLE IF NOT EXISTS `distributions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE (`name`)
);
