USE `at_mjst_finbase`;
-- create first test-account
INSERT IGNORE INTO at_mjst_finbase.acc_account (id, name) values (1, 'my internal TestAccount');
-- create second test-account
INSERT IGNORE INTO at_mjst_finbase.acc_account (id, name) values (2, 'my TestAccount');

-- insert transactions 
DELIMITER $$
DROP PROCEDURE IF EXISTS `at_mjst_finbase`.`test_tra_fill`$$
CREATE PROCEDURE `at_mjst_finbase`.`test_tra_fill`(IN counter INT)
BEGIN
	DECLARE i INT DEFAULT 0;
	WHILE (i < counter) DO
		-- "INTERNAL" transactions with all the same values (should be possible)
		INSERT INTO at_mjst_finbase.tra_transaction 
			(acc_id, internal, transaction_text, value_date, amount, hash) 
		VALUES
			(1, 1, 'Internal Transaction', CURDATE(), 500, 0);
		-- "INTERNAL" transactions with all the same values (should be possible)
		INSERT INTO at_mjst_finbase.tra_transaction 
			(acc_id, internal, transaction_text, value_date, amount, hash) 
		VALUES
			(1, 1, 'Internal Transaction', CURDATE(), (CEIL(RAND() * -1000)), 0);
		-- "noninternal" transactions have to differ each row per account!
		-- since 2 random values are insterted, it will be extremely unlikely to generate a collision
		-- collisions can be tested in another script
		INSERT INTO at_mjst_finbase.tra_transaction 
			(acc_id, internal, 
			 transaction_text, 
			 value_date, 
			 amount, hash) 
		VALUES
			(2, 0, 
			 CONCAT('Text ', CAST(i AS CHAR)), 
			 CONCAT((FLOOR(2010 + (RAND() * (2014-2010)))), '-', (FLOOR(RAND() * 12) + 1), '-',(FLOOR(RAND() * 27) + 1)), 
			 (FLOOR(RAND() * -1000) + 500), 0);
		-- note: tra_hash has to be inserted due to a bug of mySQL checking constraints 
		-- BEFORE executing trigger!
		SET i = i + 1;
	END WHILE;
END$$
DELIMITER ;
-- execute insert
CALL at_mjst_finbase.test_tra_fill(100);

-- insert 3 details for each transaction that does not have an amount of 0.0
INSERT INTO trd_transactiondetail
	(tra_id, amount)
	SELECT 	trv.id, trv.missing_amount / 4
	FROM 	at_mjst_finbase.trv_trans_delta trv 
	WHERE 	trv.missing_amount <> 0.0;

INSERT INTO trd_transactiondetail
	(tra_id, amount)
	SELECT 	trv.id, trv.missing_amount / 2
	FROM 	at_mjst_finbase.trv_trans_delta trv 
	WHERE 	trv.missing_amount <> 0.0;

INSERT INTO trd_transactiondetail
	(tra_id, amount)
	SELECT 	trv.id, trv.missing_amount
	FROM 	at_mjst_finbase.trv_trans_delta trv 
	WHERE 	trv.missing_amount <> 0.0;
