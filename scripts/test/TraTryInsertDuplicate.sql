-- inserting some "internal" values with all the same MUST NOT WORK!
INSERT INTO at_mjst_finbase.tra_transaction 
	(acc_id, internal, transaction_text, value_date, amount, hash) 
VALUES
	(2, 0, 'Invalidduplicate', '2014-08-01', 666, 0);

-- test: at least, THIS insert has to FAIL!
INSERT INTO at_mjst_finbase.tra_transaction 
	(acc_id, internal, transaction_text, value_date, amount, hash) 
VALUES
	(2, 0, 'Invalidduplicate', '2014-08-01', 666, 0);
