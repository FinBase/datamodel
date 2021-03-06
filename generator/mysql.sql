-- MySQL Script generated by MySQL Workbench
-- Wed Apr  5 00:40:01 2017
-- Model: FinBase EER    Version: 1.0
-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';

-- -----------------------------------------------------
-- Schema at_mjst_finbase
-- -----------------------------------------------------
-- Database scheme for the MJSt FinBase-project

-- -----------------------------------------------------
-- Schema at_mjst_finbase
--
-- Database scheme for the MJSt FinBase-project
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `at_mjst_finbase` DEFAULT CHARACTER SET utf8 ;
USE `at_mjst_finbase` ;

-- -----------------------------------------------------
-- Table `at_mjst_finbase`.`acc_account`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `at_mjst_finbase`.`acc_account` (
  `id` INT(5) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL,
  `description` VARCHAR(200) NULL,
  `flags` INT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  INDEX `acc_ix_flags` (`flags` ASC),
  UNIQUE INDEX `acc_ui_name` (`name` ASC))
ENGINE = InnoDB
COMMENT = 'Account information. Every account is owner of multiple transactions - the movements on this account (the current total amount is generated from these transactions respectively)';


-- -----------------------------------------------------
-- Table `at_mjst_finbase`.`tra_transaction`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `at_mjst_finbase`.`tra_transaction` (
  `id` INT(9) NOT NULL AUTO_INCREMENT COMMENT 'Transaction-Id (PK N9): one billion of transactions can be stored so far',
  `acc_id` INT(5) NOT NULL COMMENT 'Account, this transaction belongs to',
  `internal` TINYINT(1) NOT NULL COMMENT 'This field controls whether the field tra_hash is generated from columns of the current row or is filled with an \"unhexed\" uuid()',
  `transaction_text` VARCHAR(200) NULL COMMENT 'Transaction-text (this is relevant for imported transactions to have the hash-function generate an unique entry!)',
  `value_date` DATE NOT NULL COMMENT 'Original value-date, relevant date',
  `amount` DECIMAL(16,4) NOT NULL COMMENT 'Transaction amount',
  `hash` BINARY(32) NOT NULL COMMENT 'Hash-value generated by trigger from several columns using sha2-256 or UUID, in case of transactions generated by the software internally, therefor stored at least as BINARY(32)',
  `comment` VARCHAR(200) NULL COMMENT 'Additional information for this row',
  INDEX `tra_fk_acc_idx` (`acc_id` ASC),
  UNIQUE INDEX `tra_ui_hash` (`acc_id` ASC, `hash` ASC)  COMMENT 'This hash has to be unique at least for every account (in case there were same transactions in different accounts)',
  PRIMARY KEY (`id`),
  CONSTRAINT `tra_fk_acc`
    FOREIGN KEY (`acc_id`)
    REFERENCES `at_mjst_finbase`.`acc_account` (`id`)
    ON DELETE CASCADE
    ON UPDATE RESTRICT)
ENGINE = InnoDB
COMMENT = 'This table stores all accounts transactions - on insert or update, a trigger is executed, to (re)generate the tra_hash value to ensure uniqueness';


-- -----------------------------------------------------
-- Table `at_mjst_finbase`.`tig_identgroup`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `at_mjst_finbase`.`tig_identgroup` (
  `id` INT(5) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL,
  `description` VARCHAR(200) NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `tig_ui_name` (`name` ASC))
ENGINE = InnoDB
COMMENT = 'Groups transaction-identifiers (categories) together';


-- -----------------------------------------------------
-- Table `at_mjst_finbase`.`tri_transactident`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `at_mjst_finbase`.`tri_transactident` (
  `id` INT(5) NOT NULL AUTO_INCREMENT COMMENT 'TransactIdent-Id (PK N5)  allows nearly 100k of categories',
  `tig_id` INT(5) NULL COMMENT 'Specifies, which group this identifier belongs to',
  `identifier` VARCHAR(50) NOT NULL COMMENT 'Transaction identifier or category (what is this transaction for)',
  `description` VARCHAR(200) NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `tri_ui_name` (`identifier` ASC)  COMMENT 'At least this text should be unique, to avoid category-confusion',
  INDEX `tri_fk_tig_idx` (`tig_id` ASC),
  CONSTRAINT `tri_fk_tig`
    FOREIGN KEY (`tig_id`)
    REFERENCES `at_mjst_finbase`.`tig_identgroup` (`id`)
    ON DELETE SET NULL
    ON UPDATE RESTRICT)
ENGINE = InnoDB
COMMENT = 'Transaction Identifier: Used to describe, what a given transaction-detail has been used for. E.g.: \"salary\", \"insurance\", \"education\", ...';


-- -----------------------------------------------------
-- Table `at_mjst_finbase`.`trd_transactiondetail`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `at_mjst_finbase`.`trd_transactiondetail` (
  `id` INT(12) NOT NULL AUTO_INCREMENT COMMENT 'PK, by using N12, we can add 999 details per transaction on average',
  `tra_id` INT(9) NOT NULL COMMENT 'Foreign Transaction-Id',
  `value_date` DATE NULL COMMENT 'Date, this detail should be posted (used for statistics, etc.) - should default to tra_date, if null',
  `amount` DECIMAL(16,4) NOT NULL COMMENT 'Important: The total of all detail-amounts has to be equal to the original transactions amount!',
  `tri_id` INT(5) NULL COMMENT 'FK to transaction-identifier/category',
  `comment` VARCHAR(200) NULL COMMENT 'Additional information for this row',
  PRIMARY KEY (`id`),
  INDEX `trd_fk_tra_idx` (`tra_id` ASC),
  INDEX `trd_fk_tri_idx` (`tri_id` ASC),
  CONSTRAINT `trd_fk_tra`
    FOREIGN KEY (`tra_id`)
    REFERENCES `at_mjst_finbase`.`tra_transaction` (`id`)
    ON DELETE CASCADE
    ON UPDATE RESTRICT,
  CONSTRAINT `trd_fk_tri`
    FOREIGN KEY (`tri_id`)
    REFERENCES `at_mjst_finbase`.`tri_transactident` (`id`)
    ON DELETE SET NULL
    ON UPDATE RESTRICT)
ENGINE = InnoDB
COMMENT = 'Stores detail/assigns categories for any tra_transaction-row. E.g.: the transaction-amount can be splitted to assign categories to partial amounts (Important: SUM(trd_amount) WHERE tra_id == tra_amount!)';


-- -----------------------------------------------------
-- Table `at_mjst_finbase`.`dat_data_audit`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `at_mjst_finbase`.`dat_data_audit` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT 'PK',
  `audit_table` VARCHAR(64) NOT NULL COMMENT 'Logged table, VA(64) as of mysql-specification',
  `audit_table_id` BIGINT(20) NOT NULL COMMENT 'References the key (part 1) of the table to be logged - at least, this field must not be null!',
  `operation` SET('c', 'r', 'u', 'd', 'x') NOT NULL COMMENT 'Create, Read, Update, Delete, \'x\' is for keyXchange\n(DO NOT log \'read\' unless really, really necessary)\n',
  `op_user` VARCHAR(81) NOT NULL COMMENT 'Modification-User: Fetch by calling USER()-function. VA(81), because UN is provided as [\'username\'@\'host\'] (where user=16, host=60)',
  `op_timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Modification TimeStamp: Fetch by calling CURRENT_TIMESTAMP()-Function',
  PRIMARY KEY (`id`))
ENGINE = InnoDB
COMMENT = 'Logs CRUD-Operations on keys for (nearly) every table, the triggers are executed';


-- -----------------------------------------------------
-- Table `at_mjst_finbase`.`aul_auditlog`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `at_mjst_finbase`.`aul_auditlog` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `user` VARCHAR(81) NOT NULL COMMENT 'Logon-User: Fetch by calling USER()-function. VA(81), because UN is provided as [\'username\'@\'host\'] (where user=16, host=60)',
  `timestamp_on` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `timestamp_off` TIMESTAMP NULL,
  `application` VARCHAR(45) NOT NULL COMMENT 'Application executing the logon',
  PRIMARY KEY (`id`))
ENGINE = InnoDB
COMMENT = 'Records logon/logoff activity for the applications';

USE `at_mjst_finbase` ;

-- -----------------------------------------------------
-- Placeholder table for view `at_mjst_finbase`.`trv_trans_delta`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `at_mjst_finbase`.`trv_trans_delta` (`id` INT);

-- -----------------------------------------------------
-- Placeholder table for view `at_mjst_finbase`.`dav_audit_aggregated`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `at_mjst_finbase`.`dav_audit_aggregated` (`id` INT);

-- -----------------------------------------------------
-- Placeholder table for view `at_mjst_finbase`.`tav_tra_aggregated`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `at_mjst_finbase`.`tav_tra_aggregated` (`id` INT, `balance` INT, `balance_pos` INT, `balance_neg` INT, `value_date_from` INT, `value_date_to` INT, `transaction_count` INT);

-- -----------------------------------------------------
-- function uuid_binary
-- -----------------------------------------------------

DELIMITER $$
USE `at_mjst_finbase`$$
CREATE FUNCTION `at_mjst_finbase`.`uuid_binary` ()
  RETURNS BINARY(16)
BEGIN
  RETURN uuid_convert(UUID());
END$$

DELIMITER ;

-- -----------------------------------------------------
-- function uuid_convert
-- -----------------------------------------------------

DELIMITER $$
USE `at_mjst_finbase`$$
CREATE FUNCTION `at_mjst_finbase`.`uuid_convert` (uuid CHAR(36))
  RETURNS BINARY(16)
BEGIN
  RETURN UNHEX(REPLACE(uuid,'-',''));
END$$

DELIMITER ;

-- -----------------------------------------------------
-- function tra_get_hash_binary
-- -----------------------------------------------------

DELIMITER $$
USE `at_mjst_finbase`$$
CREATE FUNCTION `at_mjst_finbase`.`tra_get_hash_binary` (tra_text VARCHAR(200), tra_date DATE, tra_amount DECIMAL(16,4))
  RETURNS BINARY(32)
BEGIN
    RETURN UNHEX(SHA2(CONCAT(tra_text, tra_date, tra_amount), 256));
END$$

DELIMITER ;

-- -----------------------------------------------------
-- function tra_get_hash_row
-- -----------------------------------------------------

DELIMITER $$
USE `at_mjst_finbase`$$
CREATE FUNCTION `at_mjst_finbase`.`tra_get_hash_row` (internal BOOL, 
	tra_text VARCHAR(200),	tra_date DATE,	tra_amount DECIMAL(16,4))
  RETURNS BINARY(32)
BEGIN
	IF (internal = FALSE) THEN
      RETURN tra_get_hash_binary(tra_text, tra_date, tra_amount);
	ELSE
      RETURN uuid_binary();
	END IF;
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure dat_log
-- -----------------------------------------------------

DELIMITER $$
USE `at_mjst_finbase`$$
CREATE PROCEDURE `dat_log` (IN tablename VARCHAR(64), IN id BIGINT(20), IN op CHAR(1))
BEGIN
	INSERT INTO dat_data_audit 
		(audit_table, audit_table_id, operation, op_user, op_timestamp)
	VALUES
		(tablename, id, op, USER(), CURRENT_TIMESTAMP);
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure dat_log_insert
-- -----------------------------------------------------

DELIMITER $$
USE `at_mjst_finbase`$$
CREATE PROCEDURE `dat_log_insert` (IN tablename VARCHAR(64), IN new_id BIGINT(20))
BEGIN
	CALL dat_log(tablename, new_id, 'c');
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure dat_log_update
-- -----------------------------------------------------

DELIMITER $$
USE `at_mjst_finbase`$$
CREATE PROCEDURE `dat_log_update` (IN tablename VARCHAR(64), IN old_id BIGINT(20), IN new_id BIGINT(20))
BEGIN
	IF (old_id != new_id) THEN
		CALL dat_log(tablename, old_id, 'x');
		CALL dat_log(tablename, new_id, 'x');
	ELSE
		CALL dat_log(tablename, new_id, 'u');
	END IF;
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure dat_log_delete
-- -----------------------------------------------------

DELIMITER $$
USE `at_mjst_finbase`$$
CREATE PROCEDURE `dat_log_delete` (IN tablename VARCHAR(64), IN old_id BIGINT(20))
BEGIN
	CALL dat_log(tablename, old_id, 'd');
END$$

DELIMITER ;

-- -----------------------------------------------------
-- View `at_mjst_finbase`.`trv_trans_delta`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `at_mjst_finbase`.`trv_trans_delta`;
USE `at_mjst_finbase`;
CREATE  OR REPLACE VIEW at_mjst_finbase.trv_trans_delta AS
(
SELECT 
    tra.id,
    trd.tra_id AS `trd_tra_id`,
    tra.amount AS `tra_amount`,
    sum(trd.amount) AS `trd_amount`,
    (tra.amount - ifnull(sum(trd.amount), 0.0)) AS `missing_amount`
FROM
    at_mjst_finbase.tra_transaction `tra`
LEFT JOIN
    at_mjst_finbase.trd_transactiondetail `trd` ON (tra.id = trd.tra_id)
GROUP BY 
	tra.id, trd.tra_id, tra.amount
);

-- -----------------------------------------------------
-- View `at_mjst_finbase`.`dav_audit_aggregated`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `at_mjst_finbase`.`dav_audit_aggregated`;
USE `at_mjst_finbase`;
CREATE  OR REPLACE VIEW `dav_audit_aggregated` AS
(
	SELECT 
		COUNT(*) AS `changecount`, 
		dat.audit_table,
        dat.operation, 
		dat.op_user
	FROM 
		at_mjst_finbase.dat_data_audit dat
	GROUP BY 
		dat.audit_table, dat.operation, dat.op_user
);

-- -----------------------------------------------------
-- View `at_mjst_finbase`.`tav_tra_aggregated`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `at_mjst_finbase`.`tav_tra_aggregated`;
USE `at_mjst_finbase`;
CREATE  OR REPLACE VIEW `tav_tra_aggregated` AS
    SELECT  
        acc.id AS `id`,
        SUM(IFNULL(tra.amount, 0.0)) AS `balance`,
        SUM(CASE WHEN (tra.amount > 0.0) THEN tra.amount ELSE 0.0 END) AS `balance_pos`,
        SUM(CASE WHEN (tra.amount < 0.0) THEN tra.amount ELSE 0.0 END) AS `balance_neg`,
        MIN(tra.value_date) AS `value_date_from`,
        MAX(tra.value_date) AS `value_date_to`,
        COUNT(tra.amount) AS `transaction_count`
    FROM
        acc_account acc left join 
        tra_transaction tra on (acc.id = tra.acc_id)
    GROUP BY acc.id;
USE `at_mjst_finbase`;

DELIMITER $$
USE `at_mjst_finbase`$$
CREATE TRIGGER `acc_ains` AFTER INSERT ON `acc_account` FOR EACH ROW
BEGIN
	CALL dat_log_insert('acc', NEW.id);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `acc_aupd` AFTER UPDATE ON `acc_account` FOR EACH ROW
BEGIN
	CALL dat_log_update('acc', OLD.id, NEW.id);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `acc_adel` AFTER DELETE ON `acc_account` FOR EACH ROW
BEGIN
	CALL dat_log_delete('acc', OLD.id);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `tra_bins` BEFORE INSERT ON `tra_transaction` FOR EACH ROW
BEGIN
	SET NEW.hash = tra_get_hash_row(NEW.internal, NEW.transaction_text, NEW.value_date, NEW.amount);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `tra_ains` AFTER INSERT ON `tra_transaction` FOR EACH ROW
BEGIN
	CALL dat_log_insert('tra', NEW.id);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `tra_bupd` BEFORE UPDATE ON `tra_transaction` FOR EACH ROW
BEGIN
	SET NEW.hash = tra_get_hash_row(NEW.internal, NEW.transaction_text, NEW.value_date, NEW.amount);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `tra_aupd` AFTER UPDATE ON `tra_transaction` FOR EACH ROW
BEGIN
	CALL dat_log_update('tra', OLD.id, NEW.id);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `tra_adel` AFTER DELETE ON `tra_transaction` FOR EACH ROW
BEGIN
	CALL dat_log_delete('tra', OLD.id);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `tig_ains` AFTER INSERT ON `tig_identgroup` FOR EACH ROW
BEGIN
	CALL dat_log_insert('tig', NEW.id);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `tig_aupd` AFTER UPDATE ON `tig_identgroup` FOR EACH ROW
BEGIN
	CALL dat_log_update('tig', OLD.id, NEW.id);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `tig_adel` AFTER DELETE ON `tig_identgroup` FOR EACH ROW
BEGIN
	CALL dat_log_delete('tig', OLD.id);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `tri_ains` AFTER INSERT ON `tri_transactident` FOR EACH ROW
BEGIN
	CALL dat_log_insert('tri', NEW.id);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `tri_aupd` AFTER UPDATE ON `tri_transactident` FOR EACH ROW
BEGIN
	CALL dat_log_update('tri', OLD.id, NEW.id);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `tri_adel` AFTER DELETE ON `tri_transactident` FOR EACH ROW
BEGIN
	CALL dat_log_delete('tri', OLD.id);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `trd_ains` AFTER INSERT ON `trd_transactiondetail` FOR EACH ROW
BEGIN
	CALL dat_log_insert('trd', NEW.id);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `trd_aupd` AFTER UPDATE ON `trd_transactiondetail` FOR EACH ROW
BEGIN
	CALL dat_log_update('trd', OLD.id, NEW.id);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `trd_adel` AFTER DELETE ON `trd_transactiondetail` FOR EACH ROW
BEGIN
	CALL dat_log_delete('trd', OLD.id);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `aul_ains` AFTER INSERT ON `aul_auditlog` FOR EACH ROW
BEGIN
	CALL dat_log_insert('aul', NEW.id);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `aul_aupd` AFTER UPDATE ON `aul_auditlog` FOR EACH ROW
BEGIN
	CALL dat_log_update('aul', OLD.id, NEW.id);
END$$

USE `at_mjst_finbase`$$
CREATE TRIGGER `aul_adel` AFTER DELETE ON `aul_auditlog` FOR EACH ROW
BEGIN
	CALL dat_log_delete('aul', OLD.id);
END$$


DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
