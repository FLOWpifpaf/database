-- 1. Добавить внешние ключи.
ALTER TABLE `student` 
ADD CONSTRAINT `FK_student_group`
  FOREIGN KEY (`id_group`)
  REFERENCES `group` (`id_group`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE `lesson` 
ADD CONSTRAINT `FK_lesson_teacher`
  FOREIGN KEY (`id_teacher`)
  REFERENCES `teacher` (`id_teacher`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;
  
ALTER TABLE `lesson` 
ADD CONSTRAINT `FK_lesson_subject`
  FOREIGN KEY (`id_subject`)
  REFERENCES `subject` (`id_subject`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;
    
ALTER TABLE `lesson` 
ADD CONSTRAINT `FK_lesson_group`
  FOREIGN KEY (`id_group`)
  REFERENCES `group` (`id_group`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;
  
ALTER TABLE `mark` 
ADD CONSTRAINT `FK_mark_lesson`
  FOREIGN KEY (`id_lesson`)
  REFERENCES `lesson` (`id_lesson`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;
  
ALTER TABLE `mark` 
ADD CONSTRAINT `FK_mark_student`
  FOREIGN KEY (`id_student`)
  REFERENCES `student` (`id_student`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

-- 2. Выдать оценки студентов по информатике если они обучаются данному предмету. Оформить выдачу данных с использованием view.
CREATE VIEW `computer_science_marks` AS
SELECT 
	`student`.`name`,
    `student`.`id_student`,
    `mark`.`mark`
FROM
	`student`
		JOIN
	`mark` ON `student`.`id_student` = `mark`.`id_student`
		JOIN
	`lesson` ON `lesson`.`id_lesson` = `mark`.`id_lesson`
		JOIN
	`subject` ON `lesson`.`id_subject` = `subject`.`id_subject`
WHERE
	`subject`.`name` = 'Информатика';
    
SELECT * FROM `computer_science_marks`;

-- 3. Дать информацию о должниках с указанием фамилии студента и названия предмета.
-- Должниками считаются студенты, не имеющие оценки по предмету, который ведется в группе.
-- Оформить в виде процедуры, на входе идентификатор группы.
DROP PROCEDURE get_student_debtor;

CREATE PROCEDURE get_student_debtor(`searchable_id_group` INT)
	SELECT DISTINCT
		`student`.`name` AS `student_name`,
        `subject`.`name` AS `subject_name`
	FROM
		`student`
			LEFT JOIN
		`group` ON `student`.`id_group` = `group`.`id_group`
			LEFT JOIN
		`lesson` ON `group`.`id_group` = `lesson`.`id_group`
			LEFT JOIN
		`subject` ON `lesson`.`id_subject` = `subject`.`id_subject`
			LEFT JOIN
		`mark` ON `student`.`id_student` = `mark`.`id_student` AND `lesson`.`id_lesson` = `mark`.`id_lesson`
	WHERE
        `group`.`id_group` = `searchable_id_group`
        AND `mark`.`id_mark` IS NULL;

CALL get_student_debtor(2);

-- 4. Дать среднюю оценку студентов по каждому предмету для тех предметов, по которым занимается не менее 35 студентов.
SELECT
	`subject`.`name`,
    AVG(mark.mark)
FROM
	`subject`
		JOIN
    `lesson` ON `subject`.`id_subject` = `lesson`.`id_subject`
		JOIN
    `mark` ON  `lesson`.`id_lesson` = `mark`.`id_lesson`
		JOIN
    `group` ON `lesson`.`id_group` = `group`.`id_group`
		JOIN
    `student` ON `group`.`id_group` = `student`.`id_group`
GROUP BY
    `subject`.`name`
HAVING
    COUNT(`student`.`id_student`) >= 35;

-- 5. Дать оценки студентов специальности ВМ по всем проводимым предметам с указанием группы, фамилии, предмета, даты. При отсутствии оценки заполнить значениями NULL поля оценки.
SELECT
	`group`.`name`,
	`student`.`name`,
    `subject`.`name`,
    `lesson`.`date`,
    `mark`.`mark`
FROM
	`student`
		LEFT JOIN
	`group` ON `student`.`id_group` = `group`.`id_group`
		LEFT JOIN
	`lesson` ON `group`.`id_group` = `lesson`.`id_group`
		LEFT JOIN
	`subject` ON `lesson`.`id_subject` = `subject`.`id_subject`
		LEFT JOIN
	`mark` ON `student`.`id_student` = `mark`.`id_student` AND `lesson`.`id_lesson` = `mark`.`id_lesson`
WHERE
	`group`.`name` = 'ВМ';
    
-- 6. Всем студентам специальности ПС, получившим оценки меньшие 5 по предмету БД до 12.05, повысить эти оценки на 1 балл.
UPDATE `mark`
SET 
	`mark` = `mark` + 1
WHERE
	`mark` < 5
	AND `id_lesson` IN (
		SELECT
			`id_lesson`
		FROM
			`group`
				JOIN
			`lesson` ON `group`.`id_group` = `lesson`.`id_group`
				JOIN
			`subject` ON `lesson`.`id_subject` = `subject`.`id_subject`
		WHERE
			`group`.`name` = 'ПС'
			AND `subject`.`name` = 'БД'
			AND	`lesson`.`date` <  '2019-05-12'
	);
    
-- 7. Добавить необходимые индексы.
CREATE INDEX `IX_subject_name` ON `subject` (`name`);

CREATE INDEX `IX_group_name` ON `group` (`name`);

CREATE INDEX `IX_lesson_date` ON `lesson` (`date`);
    
CREATE INDEX `IX_mark_mark` ON `mark` (`mark`);
    



