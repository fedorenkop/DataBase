--Лабораторная 3. Дополнительные возможности создания таблиц.
--Работа с представлениями
--Работайте с вашей БД CK_<ВашDLlogin>.. 
--
--Задание 1 Наследование таблиц
--Необходимо реализовать возможность хранения информации об устройствах организации, с разделением по типу устройств. 
-- 1. Создаем схему equipment
CREATE SCHEMA equipment;
-- 2. Создаем родительскую таблицу devices
CREATE TABLE "equipment".devices (
    id SERIAL PRIMARY KEY,
    inventory_number VARCHAR(10) NOT NULL UNIQUE 
        CHECK (inventory_number ~ '^[a-z]{3}-\d{6}$'),
    device_name VARCHAR(30) NOT NULL,
    device_type VARCHAR(20) NOT NULL,
    room INT,
    inventory_date DATE NOT NULL DEFAULT CURRENT_DATE
);
-- 3. Создаем дочернюю таблицу computers
CREATE TABLE equipment.computers (
    cpu_type VARCHAR(50),
    ram INT CHECK (ram > 0),
    storage_volume INT CHECK (storage_volume > 0),
    CHECK (device_type = 'computer')
) INHERITS (equipment.devices);
-- 4. Вносим данные в таблицу computers
INSERT INTO equipment.computers 
    (inventory_number, device_name, device_type, room, cpu_type, ram, storage_volume)
VALUES 
    ('abc-123456', 'Office PC 1', 'computer', 101, 'Intel Core i5', 16, 512),
    ('def-654321', 'Server 1', 'computer', 201, 'Intel Xeon', 64, 2048);
-- Проверяем данные
SELECT * FROM equipment.computers;
-- 5. Создаем дочернюю таблицу printers
CREATE TABLE "equipment".printers (
    brand VARCHAR(30),
    color BOOLEAN,
    printer_type BOOLEAN,
    CHECK (device_type = 'printer')
) INHERITS (equipment.devices);
-- 6. Вносим данные в таблицу printers
INSERT INTO equipment.printers 
    (inventory_number, device_name, device_type, room, brand, color, printer_type)
VALUES 
    ('xyz-987654', 'Color Printer', 'printer', 102, 'HP', TRUE, FALSE),
    ('qwe-456789', 'Laser Printer', 'printer', 103, 'Canon', FALSE, TRUE);
-- Проверяем данные
SELECT * FROM equipment.printers;
-- 7. Проверяем получение данных через родительскую таблицу
SELECT * FROM equipment.devices;
-- 8. Изменяем расположение принтеров через родительскую таблицу
UPDATE "equipment".devices SET room = room + 100 
WHERE device_type = 'printer';
-- Проверяем изменения
SELECT * FROM equipment.printers;
-- 9. Удаляем все устройства через родительскую таблицу
DELETE FROM equipment.devices;

SELECT * FROM equipment.devices;
SELECT * FROM equipment.computers;
SELECT * FROM equipment.printers;

--Задание 2. Секционирование таблиц
-- 1. Создаем схему и основную таблицу
CREATE SCHEMA partitions;
CREATE TABLE partitions.projects (
    project_id SERIAL,
    project_name VARCHAR(100) NOT NULL,
    theme VARCHAR(50) NOT NULL CHECK (theme IN ('Python', 'Data Base')),
    date DATE NOT NULL,
    PRIMARY KEY (project_id, date)
) PARTITION BY RANGE (date);
-- 2. Создаем секции для каждого месяца
CREATE TABLE partitions.projects_jan25 PARTITION OF partitions.projects
    FOR VALUES FROM ('2025-01-01') TO ('2025-01-31');

CREATE TABLE partitions.projects_feb25 PARTITION OF partitions.projects
    FOR VALUES FROM ('2025-02-01') TO ('2025-02-28');

CREATE TABLE partitions.projects_mar25 PARTITION OF partitions.projects
    FOR VALUES FROM ('2025-03-01') TO ('2025-03-31');

CREATE TABLE partitions.projects_apr25 PARTITION OF partitions.projects
    FOR VALUES FROM ('2025-04-01') TO ('2025-04-30');
-- 3. Добавляем тестовые данные
INSERT INTO partitions.projects (project_name, theme, date) VALUES
    ('Project A', 'Python', '2025-01-15'),
    ('Project B', 'Data Base', '2025-01-20'),
    ('Project C', 'Python', '2025-02-10'),
    ('Project D', 'Data Base', '2025-02-25'),
    ('Project E', 'Python', '2025-03-05'),
    ('Project F', 'Data Base', '2025-03-30'),
    ('Project G', 'Python', '2025-04-12'),
    ('Project H', 'Data Base', '2025-04-18');
-- 4. Проверочные запросы
SELECT * FROM partitions.projects ORDER BY date;
SELECT * FROM partitions.projects WHERE date BETWEEN '2025-01-01' AND '2025-01-31';
-- 5. Перенос январской секции в архив
CREATE TABLE partitions.projects_archive (LIKE partitions.projects);
INSERT INTO partitions.projects_archive
SELECT * FROM partitions.projects WHERE date BETWEEN '2025-01-01' AND '2025-01-31';
DELETE FROM partitions.projects WHERE date BETWEEN '2025-01-01' AND '2025-01-31';
-- Проверка архива
SELECT * FROM partitions.projects_archive;
--Задание 3. Работа с представлениями
  -- 5. Создаем представление для таблицы DEPARTMENT
CREATE VIEW department_view AS
    SELECT * FROM "Organization"."department";
-- 6. Проверяем представление
SELECT * FROM department_view;
-- 7. Добавляем столбец department_phone
ALTER TABLE "Organization"."department" 
    ADD COLUMN department_phone VARCHAR(15);
-- 8. Проверяем представление (не будет включать новый столбец)
SELECT * FROM department_view;
-- Чтобы обновить представление:
CREATE OR REPLACE VIEW department_view AS
    SELECT * FROM "Organization"."department";
-- 9. Создаем изменяемое представление для сотрудников 1-го департамента
CREATE VIEW first_department_employees AS
    SELECT * FROM "Persons"."employee"
    WHERE dep_id = 1;
-- 10. Проверяем представление
SELECT * FROM first_department_employees;
-- 11. Пробуем добавить сотрудника во 2-й департамент через представление
-- Это вызовет ошибку, так как представление ограничено dep_id = 1
INSERT INTO first_department_employees 
    (first_name, last_name, gender, dep_id)
VALUES 
    ('New', 'Employee', 'М', 2);
-- 12. Создаем представление с проверкой для вставки/обновления
CREATE OR REPLACE VIEW first_department_employees AS
    SELECT * FROM "Persons"."employee"
    WHERE dep_id = 1
    WITH CHECK OPTION;
   
INSERT INTO first_department_employees 
    (first_name, last_name, gender, dep_id)
VALUES 
    ('New', 'Employee', 'М', 1); -- Работает
INSERT INTO first_department_employees 
    (first_name, last_name, gender, dep_id)
VALUES 
    ('New', 'Employee', 'М', 2); -- Ошибка
