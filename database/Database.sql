DROP DATABASE IF EXISTS `my_hydroponics_db`;

CREATE DATABASE `my_hydroponics_db`;

USE `my_hydroponics_db`;

CREATE TABLE `limit_values` (
    `limit_id` INT NOT NULL AUTO_INCREMENT,
    `is_active` BOOLEAN DEFAULT TRUE,
    `ph_min` FLOAT NOT NULL,
    `ph_max` FLOAT NOT NULL,
    `tds_min` FLOAT NOT NULL,
    `tds_max` FLOAT NOT NULL,
    PRIMARY KEY (`limit_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `records` (
    `record_id` INT NOT NULL AUTO_INCREMENT,
    `limit_id` INT NULL,
    `ph` FLOAT NOT NULL,
    `tds` FLOAT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`record_id`),
    CONSTRAINT `fk_records_limit_id`
        FOREIGN KEY (`limit_id`) REFERENCES `limit_values` (`limit_id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tank_levels` (
    `level_id` INT NOT NULL AUTO_INCREMENT,
    `record_id` INT NOT NULL,
    `tank` ENUM('NUTRITION_A', 'NUTRITION_B', 'PH_UP', 'PH_DOWN', 'MAIN_TANK') NOT NULL,
    `level` FLOAT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`level_id`),
    CONSTRAINT `fk_tank_levels_record_id`
        FOREIGN KEY (`record_id`) REFERENCES `records` (`record_id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `pump_histories` (
    `history_id` INT NOT NULL AUTO_INCREMENT,
    `record_id` INT NULL,
    `pump` ENUM('PUMP_NUTRITION', 'PUMP_PH_UP', 'PUMP_PH_DOWN') NOT NULL,
    `duration_on` FLOAT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`history_id`),
    CONSTRAINT `fk_pump_histories_record_id`
        FOREIGN KEY (`record_id`) REFERENCES `records` (`record_id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;