SELECT 
    tra.id AS `id`,
    trd.tra_id AS `trd_tra_id`,
    tra.amount AS `amount`,
    sum(trd.amount) AS `amount`,
    (tra.amount - IFNULL(sum(trd.amount), 0.0)) AS `missing_delta`
FROM
    at_mjst_finbase.tra_transaction `tra`
LEFT JOIN
    at_mjst_finbase.trd_transactiondetail `trd` ON (tra.id = trd.tra_id)
GROUP BY 
	tra.id, trd.tra_id, tra.amount