SELECT count(*), audit_table, operation, op_user
FROM at_mjst_finbase.dat_data_audit
GROUP BY audit_table, operation, op_user;

-- SELECT * FROM at_mjst_finbase.dat_data_audit WHERE operation = 'd';
-- SELECT * FROM at_mjst_finbase.dat_data_audit WHERE operation = 'u';
