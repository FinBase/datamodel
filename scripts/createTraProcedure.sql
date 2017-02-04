DROP FUNCTION IF EXISTS `at_mjst_finbase`.`tra_get_hash`;


DELIMITER $$
CREATE FUNCTION `at_mjst_finbase`.`tra_get_hash` (tra_text VARCHAR(200), tra_date DATE, tra_amount DECIMAL(16,4))
  RETURNS BINARY(32)
BEGIN
    RETURN UNHEX(SHA2(CONCAT(tra_text, tra_date, tra_amount), 256));
END$$


CREATE FUNCTION `at_mjst_finbase`.`tra_get_hash_row` (internal BOOL, 
	tra_text VARCHAR(200),	tra_date DATE,	tra_amount DECIMAL(16,4))
  RETURNS BINARY(32)
BEGIN
	IF (internal = FALSE) THEN
      RETURN tra_get_hash(tra_text, tra_date, tra_amount);
	ELSE
      RETURN uuid_binary();
	END IF;
END$$
