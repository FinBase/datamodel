-- SELECT count(DISTINCT hash, acc_id) from at_mjst_finbase.tra_transaction;
SELECT count(*), acc_id from at_mjst_finbase.tra_transaction group by acc_id;
SELECT * from at_mjst_finbase.tra_transaction;
