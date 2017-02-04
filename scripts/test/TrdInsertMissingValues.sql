USE `at_mjst_finbase`;
-- insert detail for each transaction that does not have an amount of 0.0
INSERT INTO trd_transactiondetail
	(tra_id, amount)
	SELECT trv.id, trv.missing_amount
	FROM   trv_trans_delta trv 
	WHERE  trv.missing_amount <> 0.0;
