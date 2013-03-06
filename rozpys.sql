DROP TABLE IF EXISTS `FRZ`;
CREATE TABLE IF NOT EXISTS `FRZ` (`kmb` int, `fcode` number(20), `ecode` number(20),`cf` int, `tf` int,`type_rozd` int,`M1_12` number(20,2));
CREATE INDEX `idx_FRZ` on `FRZ` (`kmb`, `ecode`, `fcode`, `cf`, `tf`, `type_rozd`);
INSERT INTO `FRZ` (`kmb`,`fcode`,`ecode`,`cf`, `tf`,`type_rozd`,`M1_12`)
SELECT `kmb`,`fcode`,`ecode`,`cf`,`tf`,`type_rozd`,`M1`+`M2`+`M3`+`M4`+`M5`+`M6`+`M7`+`M8`+`M9`+`M10`+`M11`+`M12` AS `M1_12`
FROM `FR325R4`
 UNION ALL
 SELECT `kmb`,`fcode`,`ecode`,`cf`,`tf`,`type_rozd`,`M1`+`M2`+`M3`+`M4`+`M5`+`M6`+`M7`+`M8`+`M9`+`M10`+`M11`+`M12` AS `M1_12` FROM `FZ325R4`;
;

DROP VIEW IF EXISTS `rozpys_zf`;
DROP VIEW IF EXISTS `rozpys_sf`;
CREATE VIEW `rozpys_zf` AS
SELECT `LMM`.`BUDGET`, `KPK`, `KEKV`, `LMM`.`ZAT` as `Kazna`, IFNULL(`M1_12`,0) AS `RFO`, `ZAT`-IFNULL(`M1_12`,0) AS `Kazna - RFO`
	FROM `LMM`
	LEFT JOIN `kod_keys` ON `KOD` = `LMM`.`BUDGET`
	LEFT JOIN (
		SELECT `kmb`, `fcode`, `ecode`, SUM(`M1_12`) AS `M1_12`
		FROM `FRZ` WHERE `cf` = 1 AND `type_rozd` = 1
		GROUP BY `kmb`, `fcode`, `ecode`
	) AS `FRZ` ON `RFV_KOD` = `kmb` AND `KPK` = `fcode` AND +`KEKV` = `ecode`
	WHERE IFNULL(`RFV_KOD`,0=1)  AND `ZAT`-IFNULL(`M1_12`,0) != 0;
CREATE VIEW `rozpys_sf` AS
SELECT `LMS`.`BUDGET`, `KPK`, `KEKV`, `LMS`.`ZAT` as `Kazna`, IFNULL(`M1_12`,0) AS `RFO`, `ZAT`-IFNULL(`M1_12`,0) AS `Kazna - RFO`
	FROM `LMS`
	LEFT JOIN `kod_keys` ON `KOD` = `LMS`.`BUDGET`
	LEFT JOIN (
		SELECT `kmb`, `fcode`, `ecode`, SUM(`M1_12`) AS `M1_12`
		FROM `FRZ` WHERE `cf` = 7 AND `type_rozd` = 1 AND `tf` IN (2)
		GROUP BY `kmb`, `fcode`, `ecode`
	) AS `FRZ` ON `RFV_KOD` = `kmb` AND `KPK` = `fcode` AND +`KEKV` = `ecode`
	WHERE IFNULL(`RFV_KOD`,0=1) AND `ZAT`-IFNULL(`M1_12`,0) != 0;
