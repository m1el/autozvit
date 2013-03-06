-- 7)
DROP TABLE IF EXISTS `FRZ`;
CREATE TABLE IF NOT EXISTS `FRZ` (`kmb` int,`fcode` char(20),`cf` int,`tf` int,`type_rozd` int,`M1_12` number(20,2));
CREATE INDEX `idx_FRZ` on `FRZ` (`kmb`, `fcode`, `cf`,`tf`, `type_rozd`);
INSERT INTO `FRZ` (`kmb`,`fcode`,`cf`,`tf`,`type_rozd`,`M1_12`)
SELECT `kmb`,`fcode`,`cf`,`tf`,`type_rozd`,`M1`+`M2`+`M3`+`M4`+`M5`+`M6`+`M7`+`M8`+`M9`+`M10`+`M11`+`M12` AS `M1_12`
FROM `FR325R4`
 UNION ALL
 SELECT `kmb`,`fcode`,`cf`,`tf`,`type_rozd`,`M1`+`M2`+`M3`+`M4`+`M5`+`M6`+`M7`+`M8`+`M9`+`M10`+`M11`+`M12` AS `M1_12` FROM `FZ325R4`;
;


UPDATE `out`
    SET
	-- загальний фонд
    `N1` = (SELECT IFNULL(SUM(`M1_12`),0)
        FROM `kod_keys`
        LEFT JOIN `FRZ` ON `kmb` = `RFV_KOD`
        WHERE
          `cf` = 1 AND `type_rozd` = 2 AND `tf` = 1
           AND `kod_keys`.`ID_KEY` = `out`.`ID_KEY`
           AND `out`.`KOD` = `FRZ`.`fcode`),
	-- спеціальний фонд
    `N3` = (SELECT IFNULL(SUM(`M1_12`),0)
        FROM `kod_keys`
        LEFT JOIN `FRZ` ON `kmb` = `RFV_KOD`
        WHERE
          `cf` = 7 AND `type_rozd` = 2 AND `tf` = 2
           AND `kod_keys`.`ID_KEY` = `out`.`ID_KEY`
           AND `out`.`KOD` = `FRZ`.`fcode`);

UPDATE `FRZ`
	SET `fcode` = CASE
		WHEN `fcode`=25010100 THEN 25010000
		WHEN `fcode`=25020100 THEN 25020000
		WHEN `fcode`=25020200 THEN 25020000
		ELSE NULL END
	WHERE `fcode` IN (25010100, 25020100, 25020200);

UPDATE `out`
	SET 
		`N3` = (SELECT IFNULL(SUM(M1_12),0)
			FROM `kod_keys`
			LEFT JOIN `FRZ` ON `kmb` = `RFV_KOD`
			WHERE
				`cf` = 2 AND `type_rozd` = 2 AND `tf` = 2
				AND `kod_keys`.`id_key` = `out`.`ID_KEY`
				AND `out`.`KOD` = `FRZ`.`fcode`)
	WHERE `KOD` IN (25010000, 25020000);

DROP VIEW IF EXISTS `dohody_miss`;

CREATE VIEW `dohody_miss` AS
SELECT "ZF" AS `SZ`, `ID_KEY`, `fcode` as `kod`, IFNULL(SUM(`M1_12`),0) as `SUM`
	FROM `FRZ` 
	LEFT JOIN `kod_keys` ON `kmb` = `RFV_KOD`
	WHERE 
		(`cf` = 1 AND `type_rozd` = 2 AND `tf`=1)
		AND	(SELECT COUNT(*) FROM `out` WHERE `out`.`ID_KEY` = `kod_keys`.`ID_KEY` AND `out`.`KOD` = `FRZ`.`fcode`) = 0
	GROUP BY `ID_KEY`, `fcode`
UNION ALL 
SELECT "SF" AS `SZ`, `ID_KEY`, `fcode` as `kod`, IFNULL(SUM(`M1_12`),0) as `SUM`
	FROM `FRZ` 
	LEFT JOIN `kod_keys` ON `kmb` = `RFV_KOD`
	WHERE 
		(`cf` = 7 AND `type_rozd` = 2 AND `tf` = 2)
		AND	(SELECT COUNT(*) FROM `out` WHERE `out`.`ID_KEY` = `kod_keys`.`ID_KEY` AND `out`.`KOD` = `FRZ`.`fcode`) = 0
	GROUP BY `ID_KEY`, `fcode`
;
