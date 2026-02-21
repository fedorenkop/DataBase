--Лабораторная работа 4
--Задание 1
--1.	Создайте функцию, которая будет принимать массив символьных данных и шаблон адреса эл.почты. 
--a)	Функция должна возвращать False если значение хотя бы одного элемента массива не соответствует шаблону. 
--b)	Иначе функция должна вернуть – True.
--c)	Функция должна работать на произвольном количестве элементов массива с произвольным шаблоном.
CREATE OR REPLACE FUNCTION check_email_pattern(emails VARCHAR[], pattern TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    email_item VARCHAR;
BEGIN
    FOREACH email_item IN ARRAY emails LOOP
        IF email_item !~ pattern THEN
            RETURN FALSE;
        END IF;
    END LOOP;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
--Задание 2
--1.	Создайте процедуру. Процедура должна получать идентификатор сотрудника и адрес эл.почты. 
--a)	Если указанный адрес отличается от существующего адреса сотрудника – необходимо выполнить замену старого адреса на новый. 
--И вернуть сообщение о выполненной операции
--b)	Если адрес не отличается – выдать соответствующее информационное сообщение
--c)	Если сотрудник с указанным идентификатором отсутствует – процедура должна возвращать сообщение об ошибке
--2.	Протестируйте ваше решение. Предоставьте код
CREATE OR REPLACE PROCEDURE update_employee_email(
    emp_id INT, 
    new_email VARCHAR(100),
    INOUT result_status INT DEFAULT NULL
) AS $$
DECLARE
    current_email VARCHAR(100);
    email_pattern TEXT := '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
BEGIN
    IF new_email IS NULL OR new_email !~ email_pattern THEN
        RAISE NOTICE 'Ошибка: Указан невалидный email адрес';
        result_status := 0;
        RETURN;
    END IF;
    -- Проверяем существование сотрудника
    IF NOT EXISTS (SELECT 1 FROM "Persons"."EMPLOYEE" WHERE id = emp_id) THEN
        RAISE NOTICE 'Ошибка: Сотрудник с ID % не найден', emp_id;
        result_status := 0;
        RETURN;
    END IF;
    
    -- Получаем текущий email
    SELECT email INTO current_email FROM "Persons"."EMPLOYEE" WHERE id = emp_id;
    IF current_email = new_email THEN
        RAISE NOTICE 'Информация: Email не изменен, так как новый email совпадает с текущим';
        result_status := 1;
        RETURN;
    END IF;
    -- Проверяем уникальность нового email
    IF EXISTS (SELECT 1 FROM "Persons"."EMPLOYEE" WHERE email = new_email AND id != emp_id) THEN
        RAISE NOTICE 'Ошибка: Email % уже используется другим сотрудником', new_email;
        result_status := 0;
        RETURN;
    END IF;
    UPDATE "Persons"."EMPLOYEE" SET email = new_email WHERE id = emp_id;
    RAISE NOTICE 'Успех: Email сотрудника с ID % успешно обновлен', emp_id;
    result_status := 1;
END;
$$ LANGUAGE plpgsql;
--Задание 3
--1.	Добавьте в таблицу "Persons"."EMPLOYEE" 2 новых столбца:
--a)	login – для сохранения учетной записи сотрудника
--b)	password– для сохранения пароля сотрудника
--2.	Создайте триггер, который будет срабатывать при добавлении и изменении записей о сотрудниках:
--a)	Login и password не должны быть одинаковыми, при этом их длина должна быть больше или равна 8 символов. Поля не должны содержать NULL значения.
--b)	В случае нарушения данных условий должно генерироваться пользовательское исключение, предоставляющее информацию о нарушении
-- Добавляем новые столбцы
ALTER TABLE "Persons"."employee"
ADD COLUMN login VARCHAR(50) NOT NULL DEFAULT 'default_login',
ADD COLUMN password VARCHAR(50) NOT NULL DEFAULT 'default_password';

-- Создаем функцию для триггера
CREATE OR REPLACE FUNCTION validate_login_password()
RETURNS TRIGGER AS $$
BEGIN
    -- Проверка на NULL значения
    IF NEW.login IS NULL THEN
        RAISE EXCEPTION 'Логин не может быть NULL';
    END IF;
    
    IF NEW.password IS NULL THEN
        RAISE EXCEPTION 'Пароль не может быть NULL';
    END IF;
    
    -- Проверка минимальной длины (8 символов)
    IF length(trim(NEW.login)) < 8 THEN
        RAISE EXCEPTION 'Логин должен содержать минимум 8 символов';
    END IF;
    
    IF length(trim(NEW.password)) < 8 THEN
        RAISE EXCEPTION 'Пароль должен содержать минимум 8 символов';
    END IF;
    
    -- Проверка, что логин и пароль разные
    IF NEW.login = NEW.password THEN
        RAISE EXCEPTION 'Логин и пароль не могут быть одинаковыми';
    END IF;
    
    -- Проверка на допустимые символы
    IF NEW.login !~ '^[a-zA-Z0-9_]+$' THEN
        RAISE EXCEPTION 'Логин может содержать только буквы, цифры и подчеркивание';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Создаем триггер
CREATE TRIGGER check_login_password
BEFORE INSERT OR UPDATE ON "Persons"."employee"
FOR EACH ROW EXECUTE FUNCTION validate_login_password();
--Задание 4
--1.	Реализуйте следующее решение:
--a)	Создайте триггерную функцию check_salary, которая вызывает исключение, если новая зарплата сотрудника больше старой на 100%.
--b)	Создайте триггер BEFORE UPDATE - before_update_salary, который вызывает функцию check_salary перед обновлением значения в столбце salary для каждой записи.
--c)	Обновите зарплату сотрудника с идентификатором 1 и убедитесь, что триггер сработал и вернул соответствующее сообщение
--d)	Переименуйте before_update_salary триггер в salary_before_update
--e)	Отключите триггер salary_before_update.  Обновите зарплату сотрудника с идентификатором 2 и убедитесь, что триггер не сработал. 
--f)	Измените имя функции check_salary на validate_salary.
--g)	Измените «привязку» триггера к триггерной функции validate_salary
--2.	Выполните проверку. Предоставьте код
CREATE OR REPLACE FUNCTION check_salary()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.salary > OLD.salary * 2 THEN
        RAISE EXCEPTION 'Зарплата не может быть увеличена более чем на 100%% (было: %, стало: %)', 
                        OLD.salary, NEW.salary;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Создаем триггер
CREATE TRIGGER before_update_salary
BEFORE UPDATE OF salary ON "Persons"."job"
FOR EACH ROW EXECUTE FUNCTION check_salary();
-- Тестирование
-- Это вызовет ошибку (увеличение более чем на 100%)
UPDATE "Persons"."job" SET salary = 50000 WHERE id = 1;
ALTER TRIGGER before_update_salary ON "Persons"."job" RENAME TO salary_before_update;

ALTER TABLE "Persons"."job" DISABLE TRIGGER salary_before_update;
UPDATE "Persons"."job" SET salary = 50000 WHERE id = 2;

ALTER FUNCTION check_salary() RENAME TO validate_salary;

-- Изменяем привязку триггера
DROP TRIGGER IF EXISTS salary_before_update ON "Persons"."job";
CREATE TRIGGER salary_before_update
BEFORE UPDATE OF salary ON "Persons"."job"
FOR EACH ROW EXECUTE FUNCTION validate_salary();
--Задание 5
--1.	Необходимо реализовать процедурную поддержку процесса карьерных перемещений сотрудников. 
--a)	Таблица "Persons"."EMPLOYEE" должна содержать только актуальную информацию об активных сотрудниках
--b)	Создайте таблицу job_history в схеме "Persons". Данная таблица должна содержать информацию обо всех «изменениях» сотрудника: прием (добавление сотрудника), увольнение (удаление сотрудника), изменение должности, изменение отдела
--i.	Таблица должна содержать все столбцы, которые имеются в таблице "Persons"."EMPLOYEE" 
--ii.	Дата события должна сохраняться в столбце date_event в таблице job_history
--iii.	Тип изменения должен сохранятся в столбце type_operation в таблице job_history
CREATE TABLE "Persons".job_history (
    LIKE "Persons"."employee" INCLUDING ALL,
    date_event TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    type_operation VARCHAR(20) NOT NULL
);
--(прием на работу)
CREATE OR REPLACE FUNCTION employee_insert_trigger()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO "Persons".job_history 
    SELECT NEW.*, CURRENT_TIMESTAMP, 'INSERT';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_employee_insert
AFTER INSERT ON "Persons"."employee"
FOR EACH ROW EXECUTE FUNCTION employee_insert_trigger();

CREATE OR REPLACE FUNCTION employee_update_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.job_id IS DISTINCT FROM NEW.job_id OR OLD.dep_id IS DISTINCT FROM NEW.dep_id THEN
        INSERT INTO "Persons".job_history 
        SELECT NEW.*, CURRENT_TIMESTAMP, 'UPDATE';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_employee_update
AFTER UPDATE ON "Persons"."employee"
FOR EACH ROW EXECUTE FUNCTION employee_update_trigger();

CREATE OR REPLACE FUNCTION employee_delete_trigger()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO "Persons".job_history 
    SELECT OLD.*, CURRENT_TIMESTAMP, 'DELETE';
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
-- Триггер при удалении
CREATE TRIGGER after_employee_delete
AFTER DELETE ON "Persons"."employee"
FOR EACH ROW EXECUTE FUNCTION employee_delete_trigger();
