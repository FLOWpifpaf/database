ALTER TABLE `booking` 
ADD CONSTRAINT `FK_booking_client`
  FOREIGN KEY (`id_client`)
  REFERENCES `client` (`id_client`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE `room` 
ADD CONSTRAINT `FK_room_hotel`
  FOREIGN KEY (`id_hotel`)
  REFERENCES `hotel` (`id_hotel`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;
  
ALTER TABLE `room` 
ADD CONSTRAINT `FK_room_room_category`
  FOREIGN KEY (`id_room_category`)
  REFERENCES `room_category` (`id_room_category`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;
  
ALTER TABLE `room_in_booking` 
ADD CONSTRAINT `FK_room_in_booking_booking`
  FOREIGN KEY (`id_booking`)
  REFERENCES `booking` (`id_booking`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE `room_in_booking`
ADD CONSTRAINT `FK_room_in_booking_room`
  FOREIGN KEY (`id_room`)
  REFERENCES `room` (`id_room`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- 2. Выдать информацию о клиентах гостиницы “Космос”, проживающих в номерах категории “Люкс” на 1 апреля 2019г
SELECT
	`client`.`name`
FROM
	`client`
        LEFT JOIN
    `booking` ON `client`.`id_client` = `booking`.`id_client`
		LEFT JOIN
    `room_in_booking` ON `booking`.`id_booking` = `room_in_booking`.`id_booking`
		LEFT JOIN
    `room` ON `room_in_booking`.`id_room` = `room`.`id_room`
		LEFT JOIN
    `hotel` ON `room`.`id_hotel` = `hotel`.`id_hotel`
		LEFT JOIN
    `room_category` ON `room`.`id_room_category` = `room_category`.`id_room_category`
WHERE
	`hotel`.`name` = 'Космос'
	AND `room_category`.`name` = 'Люкс'
	AND `room_in_booking`.`checkin_date` <= '2019-04-01'
	AND `room_in_booking`.`checkout_date` > '2019-04-01';

-- 3. Дать список свободных номеров всех гостиниц на 22 апреля
SELECT
	`id_room`,
    `number`
FROM
	`room`
WHERE
	`id_room` NOT IN (
		SELECT DISTINCT
			`id_room`
		FROM
			`room_in_booking`
		WHERE
			'2019-04-22' BETWEEN `checkin_date` AND DATE_ADD(`checkout_date`, INTERVAL -1 DAY)
    );

-- 4. Дать количество проживающих в гостинице “Космос” на 23 марта по каждой категории номеров
SELECT
	`room_category`.`name`,
	COUNT(*) AS `count_client`
FROM
	`booking`
        LEFT JOIN
    `room_in_booking` ON `booking`.`id_booking` = `room_in_booking`.`id_booking`
		LEFT JOIN
    `room` ON `room_in_booking`.`id_room` = `room`.`id_room`
		LEFT JOIN
    `hotel` ON `room`.`id_hotel` = `hotel`.`id_hotel`
		LEFT JOIN
    `room_category` ON `room`.`id_room_category` = `room_category`.`id_room_category`
WHERE
	`hotel`.`name` = 'Космос'
	AND `checkin_date` <= '2019-03-23'
	AND `checkout_date` > '2019-03-23'
GROUP BY `room_category`.`name`;

-- 5. Дать список последних проживавших клиентов по всем комнатам гостиницы “Космос”, выехавшим в апреле с указанием даты выезда
SELECT
	`booking`.`id_booking`,
    `client`.`name`,
	`room`.`id_room`,
	`room`.`number`,
    `hotel`.`name`,
    `P_room_in_booking`.`checkin_date`,
    `P_room_in_booking`.`checkout_date`
FROM
	`room_in_booking` AS `P_room_in_booking`
		LEFT JOIN
    `room` ON `P_room_in_booking`.`id_room` = `room`.`id_room`
		LEFT JOIN
    `hotel` ON `room`.`id_hotel` = `hotel`.`id_hotel`
		LEFT JOIN
    `booking` ON `P_room_in_booking`.`id_booking` = `booking`.`id_booking`
		LEFT JOIN
    `client` ON `booking`.`id_client` = `client`.`id_client`
WHERE
	`hotel`.`name` = 'Космос'
    AND `P_room_in_booking`.`id_room_in_booking` = (
		SELECT
			`S_room_in_booking`.`id_room_in_booking`
		FROM
			`room_in_booking` AS `S_room_in_booking`
		WHERE
			`S_room_in_booking`.`id_room` = `P_room_in_booking`.`id_room`
            AND `checkout_date` BETWEEN '2019-04-01' AND '2019-04-30'
		ORDER BY `S_room_in_booking`.`id_room`, `S_room_in_booking`.`checkout_date` DESC
		LIMIT 1
    );

-- 6. Продлить на 2 дня дату проживания в гостинице “Космос”
-- всем клиентам комнат категории “Бизнес”, которые заселились 10 мая
UPDATE `room_in_booking` 
SET 
    `checkout_date` = DATE_ADD(`checkout_date`, INTERVAL 2 DAY)
WHERE
	`checkin_date` = '2019-05-10'
		AND
	`id_room` IN (
		SELECT
			`room`.`id_room`
		FROM
			`room`
				LEFT JOIN
			`hotel` ON `room`.`id_hotel` = `hotel`.`id_hotel`
				LEFT JOIN
			`room_category` ON `room`.`id_room_category` = `room_category`.`id_room_category`
		WHERE
			`hotel`.`name` = 'Космос' AND `room_category`.`name` = 'Бизнес'
	);
            
-- 7. Найти все "пересекающиеся" варианты проживания. Правильное состояние:
-- не может быть забронирован один номер на одну дату несколько раз,
-- т.к. нельзя заселиться нескольким клиентам в один номер.
-- Записи в таблице room_in_booking с id_room_in_booking = 5 и 2154 являются
-- примером неправильного состояния, которые необходимо найти. Результирующий
-- кортеж выборки должен содержать информацию о двух конфликтующих номерах.
SELECT
	*
FROM
	`room_in_booking` AS `primary`
		JOIN
	`room_in_booking` AS `secondary` ON `primary`.`id_room_in_booking` != `secondary`.`id_room_in_booking`
		AND `primary`.`id_room` = `secondary`.`id_room`
    WHERE
		`primary`.`checkin_date` BETWEEN `secondary`.`checkin_date` AND DATE_ADD(`secondary`.`checkout_date`, INTERVAL -1 DAY)
	OR
		`secondary`.`checkin_date` BETWEEN `primary`.`checkin_date` AND DATE_ADD(`primary`.`checkout_date`, INTERVAL -1 DAY);

-- 8. Создать бронирование в транзакции
BEGIN;
	INSERT INTO `booking`
		(`id_client`, `booking_date`)
	VALUES
		(72, '2022-02-05');
        
	INSERT INTO `room_in_booking`
		(`id_booking`, `id_room`, `checkin_date`, `checkout_date`)
	VALUES
		(LAST_INSERT_ID(), 30, '2022-03-10', '2022-03-20');
COMMIT;

-- 9. Добавить необходимые индексы для всех таблиц
CREATE INDEX `IX_hotel_name` ON `hotel` (`name`);

CREATE INDEX `IX_room_category_name` ON `room_category` (`name`);

CREATE INDEX `IX_room_in_booking_checkout_date` ON `room_in_booking` (`checkout_date`);

CREATE INDEX `IX_room_in_booking_id_room` ON `room_in_booking` (`id_room`);

CREATE INDEX `IX_room_in_booking_checkin_date-checkout_date` ON `room_in_booking` (
	`checkin_date`,
    `checkout_date`
);