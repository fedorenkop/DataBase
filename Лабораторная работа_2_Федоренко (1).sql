--Лабораторная 2. 
--Работайте с вашей БД CK_<ВашDLlogin>
-- Задание 1. Модификация данных в БД
--
--1.	Добавьте в таблицу "Location"."COUNTRY" (справочник стран) 3 страны. Приведите код
INSERT INTO "Location"."country" (country_name) VALUES 
('Россия'),
('Китай'),
('США');
--2.	Добавьте в таблицу "Location"."CITY" по 2 города для каждой страны.
--a.	Для ввода данных в столбец country_id используйте подзапрос к таблице "Location"."COUNTRY". Подзапрос должен возвращать country_id по названию страны
INSERT INTO "Location"."city" (city_name, country_id) VALUES
('Москва', (SELECT id FROM "Location"."country" WHERE country_name = 'Россия')),
('Ставрополь', (SELECT id FROM "Location"."country" WHERE country_name = 'Россия')),
('Вашингтон', (SELECT id FROM "Location"."country" WHERE country_name = 'США')),
('Чикаго', (SELECT id FROM "Location"."country" WHERE country_name = 'США')),
('Шанхай', (SELECT id FROM "Location"."country" WHERE country_name = 'Китай')),
('Пекин', (SELECT id FROM "Location"."country" WHERE country_name = 'Китай'));
--3.	Добавьте в таблицу "Persons"."EMPLOYEE" столбец phone позволяющий хранить массив телефонов. Приведите код
ALTER TABLE "Persons"."employee" ADD COLUMN phone VARCHAR(15)[];
--4.	Добавьте в таблицу "Persons"."EMPLOYEE" сведения об 1 сотруднике. Приведите код:
INSERT INTO "Persons"."employee" (
    first_name, 
    last_name, 
    gender, 
    birthdate, 
    email
) VALUES (
    'Полина', 
    'Федоренко', 
    'Ж', 
    '2000-02-17', 
    'polinavas526@gmail.ru'
);
--a.	Успешна ли ваша попытка?
--Нет, код выдает ошибку. SQL Error [23502]: ERROR: null value in column "job_id" violates not-null constraint
 -- Подробности: Failing row contains (1, Полина, Федоренко, Ж, 2000-02-17, polinavas526@gmail.ru, Россия, null, null, null, null, 2025-04-02, null).
--b.	Что необходимо для заполнения таблицы "Persons"."EMPLOYEE" данными?
--Для заполнения таблицы employee необходимо сначала заполнить: таблицы job (для job_id), city (для city_id) и department (для dep_id)
--5.	Добавьте в таблицу "Persons"."JOB" 1 запись с учетом заданных в таблице ограничений целостности. Используйте конструктор VALUES. Приведите код.
INSERT INTO "Persons"."job" (job_title, salary) 
VALUES ('Менеджер', 50000.00);
--6.	Напишите ОДИН оператор Insert, для добавления в таблицу "Persons"."JOB" 2 записей. Приведите код:
--a.	одна запись должна соответствовать ограничениям целостности 
--b.	одна запись должна нарушать одно или несколько ограничений целостности. 
--c.	Каков результат?
INSERT INTO "Persons"."job" (job_title, salary) VALUES
('Разработчик', 100000.00),  -- Корректная запись
('Директор', 300000.00);    -- Нарушает ограничение CHECK (salary <= 100000)
-- Результат: (ошибка SQL Error [23514]: new row for relation "job" violates check constraint "job_salary_check". Новое значение для строки нарушает ограничение CHECK.
--7.	Добавьте в таблицу "Persons"."EMPLOYEE" сведения о 3 сотрудниках. Приведите код:
--a.	У каждого сотрудника должно быть определено не менее 2 номеров телефонов. 
--b.	Сотрудники должны занимать разные должности
--c.	Значение департамента (dep_id) не указывайте
--d.	Успешна ли ваша попытка?
-- Сначала добавим необходимые должности (если еще не добавлены)
INSERT INTO "Persons"."job" (job_title, salary) VALUES
('Разработчик', 80000.00),
('Аналитик', 70000.00),
('Тестировщик', 50000.00)
ON CONFLICT DO NOTHING;

-- Добавим сотрудников с телефонами (массивом)
INSERT INTO "Persons"."employee" (
    first_name, last_name, gender, birthdate, email, 
    city_id, job_id, hiredate, phone
) VALUES
('Иван', 'Иванов', 'М', '1990-05-15', 'ivanov@mail.com',
 (SELECT id FROM "Location"."city" WHERE city_name = 'Москва'),
 (SELECT id FROM "Persons"."job" WHERE job_title = 'Разработчик'),
 '2020-01-10', ARRAY['+79161234567', '+74951234567']),
 
('Петр', 'Петров', 'М', '1985-08-20', 'petrov@mail.com',
 (SELECT id FROM "Location"."city" WHERE city_name = 'Вашингтон'),
 (SELECT id FROM "Persons"."job" WHERE job_title = 'Аналитик'),
 '2019-03-15', ARRAY['+78121234567', '+79211234567']),
 
('Мария', 'Сидорова', 'Ж', '1992-11-30', 'sidorova@mail.com',
 (SELECT id FROM "Location"."city" WHERE city_name = 'Пекин'),
 (SELECT id FROM "Persons"."job" WHERE job_title = 'Тестировщик'),
 '2021-05-20', ARRAY['+79371234567', '+78431234567']);

--8.	Удалите из таблицы "Location"."COUNTRY"1 запись. Приведите код. Объясните полученный результат.
DELETE FROM "Location"."country" WHERE country_name = 'Китай';
-- Результат: ошибка "нарушение ограничения внешнего ключа"
-- Нельзя удалить страну, потому что на нее ссылаются города в таблице city, сначала нужно удалить связанные города или изменить их country_id
--9.	Добавьте первому сотруднику дополнительный номер телефона. 
UPDATE "Persons"."employee" 
SET phone = array_append(phone, '+79031234567')
WHERE id = 1;
--10.	Измените у второго сотрудника номер 2 телефона (используйте указатель на соответствующий элемент массива)
UPDATE "Persons"."employee" 
SET phone[2] = '+79219876543'
WHERE id = 2;
--11.	У третьего сотрудника удалите 2-ой телефон из списка телефонов.
UPDATE "Persons"."employee" 
SET phone = array_remove(phone, phone[2])
WHERE id = 3;
--12.	Добавьте по 2 записи в таблицы "Organization"."COMPANY" и "Organization"."DEPARTMENT"
INSERT INTO "Organization"."company" (id, name, addres, avg_salary) VALUES
(1, 'ООО Политех', 'ул. Политехническая, 10', 75000.00),
(2, 'АО Додо', 'ул. Проспект Науки, 25', 80000.00)
ON CONFLICT (id) DO NOTHING;

-- Добавляем департаменты (с указанием ID и company_id)
INSERT INTO "Organization"."department" (id, name, company_id) VALUES
(1, 'Отдел разработки', 1),
(2, 'Отдел тестирования', 1),
(3, 'Отдел аналитики', 2),
(4, 'Отдел маркетинга', 2)
ON CONFLICT (id) DO NOTHING;
--13.	«Примите» имеющихся сотрудников организации в соответствующие департаменты. Приведите код:
--a.	Первый сотрудник должен быть зачислен в первый департамент
--b.	Второй и третий сотрудники должны быть зачислены во второй департамент
UPDATE "Persons"."employee" 
SET dep_id = 1 
WHERE id = 1;

UPDATE "Persons"."employee" 
SET dep_id = 2 
WHERE id IN (2, 3);
--14.	Измените код ("ID") второго департамента. Что произошло со значением в столбце dep_id в таблице "Persons"."EMPLOYEE" для второго и третьего сотрудников?
UPDATE "Organization"."department" 
SET ID = 20 
WHERE ID = 2;
--Значение dep_id в таблице EMPLOYEE для 2 и 3 сотрудников изменится на 20
--15.	Удалите из таблицы "Organization"."DEPARTMENT" первый департамент. Что произошло? Как изменилось значение в столбце dep_id в таблице "Persons"."EMPLOYEE" для первого сотрудника?
DELETE FROM "Organization"."department" 
WHERE ID = 1;
-- Значение dep_id в таблице EMPLOYEE для 1 сотрудника установится в NULL значение
--Задание 2. Управление конкурентным доступом (REPEATABLE READ)
--1-я сессия:
--1.	Выполните проверку уровня изоляции, используемого в текущей сессии.
--2.	Откройте явную транзакцию с уровнем изоляции REPEATABLE READ.
--3.	Выполните изменение эл.почты первого сотрудника. 
--4.	Транзакцию не закрывайте!!!
SHOW transaction_isolation;

BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

UPDATE "Persons"."employee" 
SET email = 'new_email1@mail.ru'
WHERE id = 1;

-- Транзакция не закрывается
--2-я сессия:
--5.	Откройте второе соединение к вашей БД. 
--6.	Откройте явную транзакцию с уровнем изоляции REPEATABLE READ. 
--7.	Выполните запрос к таблице "Persons"."EMPLOYEE". Убедитесь, что изменения, сделанные в параллельной транзакции не видны
--8.	Измените эл.почту первого сотрудника: к текущему содержимому столбца добавьте еще один адрес через запятую (значение должно отличаться от введенного в первой транзакции) 
--9.	Зафиксируйте транзакцию. 
--10.	Каков результат?
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT email FROM "Persons"."employee" WHERE id = 1; --(изменения из первой транзакции не видны)

UPDATE "Persons"."employee" 
SET email = email || ',new_email2@mail.ru'
WHERE id = 1;

-- 9. Фиксация транзакции
COMMIT;
-- Результат: транзакция заблокирована, пока первая транзакция не завершится (there is already a transaction in progress). 
--1-я сессия:
--11.	Зафиксируйте транзакцию 
--12.	Проверьте адрес эл.почты у первого сотрудника. Объясните результат.
-- 11. Фиксация транзакции
COMMIT;

SELECT email FROM "Persons"."employee" WHERE id = 1;
-- Результат зависит от того, какая транзакция завершилась первой:
-- Если вторая транзакция была заблокирована и выполнилась после первой, то будет значение 'new_email1@mail.ru, new_email2@mail.ru', если вторая транзакция не смогла выполниться из-за конфликта, то будет только 'new_email1@mail.ru'









