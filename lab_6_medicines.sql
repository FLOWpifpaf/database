-- 1. Добавить внешние ключи
ALTER TABLE `production` 
ADD CONSTRAINT `FK_production_company`
  FOREIGN KEY (`id_company`)
  REFERENCES `company` (`id_company`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;
  
ALTER TABLE `production` 
ADD CONSTRAINT `FK_production_medicine`
  FOREIGN KEY (`id_medicine`)
  REFERENCES `medicine` (`id_medicine`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;
  
ALTER TABLE `dealer` 
ADD CONSTRAINT `FK_dealer_company`
  FOREIGN KEY (`id_company`)
  REFERENCES `company` (`id_company`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;
  
ALTER TABLE `order` 
ADD CONSTRAINT `FK_order_production`
  FOREIGN KEY (`id_production`)
  REFERENCES `production` (`id_production`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;
    
ALTER TABLE `order` 
ADD CONSTRAINT `FK_order_dealer`
  FOREIGN KEY (`id_dealer`)
  REFERENCES `dealer` (`id_dealer`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE `order` 
ADD CONSTRAINT `FK_order_pharmacy`
  FOREIGN KEY (`id_pharmacy`)
  REFERENCES `pharmacy` (`id_pharmacy`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;
  
-- 2. Выдать информацию по всем заказам лекарства “Кордерон” компании “Аргус” с указанием названий аптек, дат, объема заказов
SELECT
	`company`.`name` AS `company_name`,
    `medicine`.`name` AS `medicine_name`,
    `pharmacy`.`name` AS `pharmacy_name`,
    `order`.`date` AS `order_date`,
	`order`.`quantity` AS `order_quantity`
FROM
	`order`
		LEFT JOIN
	`pharmacy` ON `order`.`id_pharmacy` = `pharmacy`.`id_pharmacy`
		LEFT JOIN
	`production` ON `order`.`id_production` = `production`.`id_production`
		LEFT JOIN
	`company` ON `production`.`id_company` = `company`.`id_company`
		LEFT JOIN
	`medicine` ON `production`.`id_medicine` = `medicine`.`id_medicine`
WHERE
	`medicine`.`name` = 'Кордеон'
    AND `company`.`name` = 'Аргус';

-- 3. Дать список лекарств компании “Фарма”, на которые не были сделаны заказы до 25 января
SELECT
    `medicine`.`name`
FROM
	`order`
		RIGHT JOIN
	`production` ON `order`.`id_production` = `production`.`id_production`
		LEFT JOIN
	`company` ON `production`.`id_company` = `company`.`id_company`
		LEFT JOIN
	`medicine` ON `production`.`id_medicine` = `medicine`.`id_medicine`
WHERE
    `company`.`name` = 'Фарма'
    AND `production`.`id_production` NOT IN (
		SELECT
			`id_production`
		FROM
			`order`
		WHERE
			`date` < '2019-01-25'
    )
GROUP BY `medicine`.`name`;

-- 4. Дать минимальный и максимальный баллы лекарств каждой фирмы, которая оформила не менее 120 заказов
SELECT
	`company`.`name`,
    MIN(`rating`) AS `min`,
    MAX(`rating`) AS `max`
FROM
	`production`
		LEFT JOIN
	`company` ON `production`.`id_company` = `company`.`id_company`
WHERE
	`company`.`id_company` IN (
		SELECT
			`company`.`id_company`
		FROM
			`order`
				LEFT JOIN
			`production` ON `order`.`id_production` = `production`.`id_production`
				LEFT JOIN
			`company` ON `production`.`id_company` = `company`.`id_company`
				LEFT JOIN
			`medicine` ON `production`.`id_medicine` = `medicine`.`id_medicine`
		GROUP BY `company`.`name`
		HAVING COUNT(*) >= 120
    )
GROUP BY `company`.`id_company`;

-- +5. Дать списки сделавших заказы аптек по всем дилерам компании “AstraZeneca”
-- Если у дилера нет заказов, в названии аптеки проставить NULL
SELECT 
	`company_name`,
    `dealer_name`,
    `pharmacy`.`name` AS `pharmacy_name`
FROM
	`order`
		RIGHT JOIN (
		SELECT
			`company`.`name` AS `company_name`,
			`dealer`.`name` AS `dealer_name`,
			`dealer`.`id_dealer`
		FROM
			`dealer`
				LEFT JOIN
			`company` ON `dealer`.`id_company` = `company`.`id_company`
		WHERE
			`company`.`name` = 'AstraZeneca'
	) AS `dealer_company` ON `order`.`id_dealer` = `dealer_company`.`id_dealer`
		LEFT JOIN
	`pharmacy` ON `order`.`id_pharmacy` = `pharmacy`.`id_pharmacy`
    GROUP BY `dealer_name`, `pharmacy`.`name`;
    
-- 6. Уменьшить на 20% стоимость всех лекарств, если она превышает 3000, а длительность лечения не более 7 дней.
UPDATE `production` 
SET 
    `price` = 20 * (1/100) * `price`
WHERE
	`price` > 3000
	AND `id_medicine` IN (
		SELECT
			`id_medicine`
		FROM
			`medicine`
		WHERE
			`cure_duration` <= 7
	);
   
-- 7. Добавить необходимые индексы
CREATE INDEX `IX_medicine_name` ON `medicine` (`name`);

CREATE INDEX `IX_medicine_cure_duration` ON `medicine` (`cure_duration`);

CREATE INDEX `IX_company_name` ON `company` (`name`);

CREATE INDEX `IX_order_date` ON `order` (`date`);

CREATE INDEX `IX_production_price` ON `production` (`price`);    