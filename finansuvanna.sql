-- 1) Фінансування
UPDATE `out`
    SET `N2` = (SELECT IFNULL(SUM(`N7`), 0) FROM `Z2MPZ`
    		WHERE `Z2MPZ`.`ID_KEY` = `out`.`ID_KEY`)
    WHERE `KOD` = 205200;
-- 3)
UPDATE `out`
    SET `N4` = (SELECT IFNULL(SUM(`N7`), 0) FROM `Z41MPS` WHERE `Z41MPS`.`ID_KEY` = `out`.`ID_KEY`)
                     +(SELECT IFNULL(SUM(`N6`), 0) FROM `Z42MPS` WHERE `Z42MPS`.`ID_KEY` = `out`.`ID_KEY`)
                     +(SELECT IFNULL(SUM(`N6`), 0) FROM `Z43MPS` WHERE `Z43MPS`.`ID_KEY` = `out`.`ID_KEY`)
    WHERE `KOD` = 205200;
-- 2а) ЗФ Код 208340
UPDATE `out`
    SET `N2` = 
          (SELECT IFNULL(SUM(`N2`), 0) FROM `WM_1`
        	WHERE `WM_1`.`ID_KEY` = `out`.`ID_KEY`
                AND `KOD` IN (41010600, 41020300, 41035600, 41035200, 41035000, 41010900))
        - (SELECT IFNULL(SUM(`N6`), 0) FROM `Z2MPZ`
        	WHERE `Z2MPZ`.`ID_KEY` = `out`.`ID_KEY`
                AND `KFK` IN (250302, 250311, 250353, 250352, 250380, 250309))
    WHERE `KOD` = "208340*";
-- 2б) СФ Код 208340
UPDATE `out`
    SET `N4` =
          (SELECT IFNULL(SUM(`N5`), 0) FROM `WM_1`
        	WHERE `WM_1`.`ID_KEY` = `out`.`ID_KEY`
                AND `KOD` IN (41010600, 41020300, 41035600, 41035200, 41035000, 41010900))
        - (SELECT IFNULL(SUM(`N5`), 0) FROM `Z43MPS`
        	WHERE `Z43MPS`.`ID_KEY` = `out`.`ID_KEY`
                AND `KFK` IN (250302, 250311, 250353, 250352, 250380, 250309))
    WHERE `KOD` = "208340*";
-- 4), 5) Залишкі бюджетів 3152, 3142
UPDATE `out`
    SET `N2` = (SELECT IFNULL(SUM(`3142`), 0) FROM `kod_keys`
            INNER JOIN `6325zf` ON `6325zf`.`KOD` = `kod_keys`.`KOD`
            WHERE `kod_keys`.`ID_KEY` = `out`.`ID_KEY`),
        `N4` = (SELECT IFNULL(SUM(`3152`), 0) FROM `kod_keys`
            INNER JOIN `6325sf` ON `6325sf`.`KOD` = `kod_keys`.`KOD`
            WHERE `kod_keys`.`ID_KEY` = `out`.`ID_KEY`)
    WHERE `KOD` = 208200;
-- Корегування "Банк Україна"
UPDATE `out`
	SET `N2` = `out`.`N2` + (SELECT `zf` FROM `bank_ukraina`),
	    `N4` = `out`.`N4` + (SELECT `sf` FROM `bank_ukraina`)
	WHERE `KOD` = 208200 AND `ID_KEY` = 429;
-- 6)
-- Создание временной таблицы для запроса
DROP TABLE IF EXISTS `out_view6`;
CREATE TEMPORARY TABLE `out_view6` (`ID_KEY` INT, `n1_1D` NUMBER(20,2), `n3_1D` NUMBER(20,2), `n1_208100` NUMBER(20,2), `n3_208100` NUMBER(20,2), `n1_208400` NUMBER(20,2), `n3_208400` NUMBER(20,2));
CREATE INDEX `idx_out_view6` ON `out_view6` (`ID_KEY`);
INSERT INTO `out_view6`
SELECT 
    `out1`.`ID_KEY`, 
    IFNULL(`n1_1D`, 0) AS `n1_1D`, IFNULL(`n3_1D`, 0) AS `n3_1D`,
    IFNULL(`n1_208100`, 0) AS `n1_208100`, IFNULL(`n3_208100`, 0) AS `n3_208100`,
    IFNULL(`n1_208400`, 0) AS `n1_208400`, IFNULL(`n3_208400`, 0) AS `n3_208400`
FROM
    (SELECT DISTINCT `ID_KEY` FROM `out`) as `out1`
    LEFT JOIN
    (SELECT `ID_KEY`, SUM(`N1`) AS `n1_1D`, SUM(`N3`) AS `n3_1D` FROM `out` WHERE `KOD` = "1D" GROUP BY `ID_KEY`) as `_1d` on (`_1d`.`id_key` = `out1`.`ID_KEY`)
    LEFT JOIN 
    (SELECT `ID_KEY`, SUM(`N1`) AS `n1_208100`, SUM(`N3`) AS `n3_208100` FROM `out` WHERE `KOD` = 208100 GROUP BY `ID_KEY`) as `_208100` on (`_208100`.`id_key` = `out1`.`ID_KEY`)
    LEFT JOIN 
    (SELECT `ID_KEY`, SUM(`N1`) AS `n1_208400`, SUM(`N3`) AS `n3_208400` FROM `out` WHERE `KOD` = 208400 GROUP BY `ID_KEY`) as `_208400` on (`_208400`.`id_key` = `out1`.`ID_KEY`);

-- Сам запрос
UPDATE `out`
    SET `N1` =    (SELECT `n1_1D` + `n1_208100` + `n1_208400` FROM `out_view6` WHERE `ID_KEY` = `out`.`ID_KEY`),
        `N3` =    (SELECT `n3_1D` +  `n3_208100` + `n3_208400` FROM `out_view6` WHERE `ID_KEY` = `out`.`ID_KEY`)
    WHERE `KOD` = 208200;

-- Запрос без VIEV:
-- UPDATE `out`                                                                                                   
--     SET `N1` =    (SELECT SUM(`N1`) FROM `out` as `out_i` WHERE `KOD` = 208100 AND `ID_KEY` = `out`.`ID_KEY`)  
--                 - (SELECT SUM(`N1`) FROM `out` as `out_i` WHERE `KOD` = 208400 AND `ID_KEY` = `out`.`ID_KEY`)  
--                 - (SELECT SUM(`N1`) FROM `out` as `out_i` WHERE `KOD` = "1D"   AND `ID_KEY` = `out`.`ID_KEY`), 
--         `N3` =    (SELECT SUM(`N3`) FROM `out` as `out_i` WHERE `KOD` = 208100 AND `ID_KEY` = `out`.`ID_KEY`)  
--                 - (SELECT SUM(`N3`) FROM `out` as `out_i` WHERE `KOD` = 208400 AND `ID_KEY` = `out`.`ID_KEY`)  
--                 - (SELECT SUM(`N3`) FROM `out` as `out_i` WHERE `KOD` = "1D"   AND `ID_KEY` = `out`.`ID_KEY`)  
--     WHERE `KOD` = 208200                                                                                       
--
