Лабораторный практикум по базам данных (PostgreSQL)
Комплекс из 4 лабораторных работ по проектированию, манипуляции данными и серверному программированию в PostgreSQL. Реализована полноценная база данных для управления персоналом с системой аудита, валидацией и конкурентным доступом.

Лабораторная работа №1 — Проектирование структуры БД
Стек технологий

PostgreSQL 15+

Business Studio (моделирование)

DDL (Data Definition Language)

ER-диаграммы

Основной функционал

Возможность	Объекты
Создание схем (Persons, Organization, Location)	CREATE SCHEMA
Таблица сотрудников с валидацией	EMPLOYEE (CHECK, FOREIGN KEY)
Справочники (должности, компании, отделы)	JOB, COMPANY, DEPARTMENT
Географические справочники	CITY, COUNTRY
Ограничения целостности	CHECK, UNIQUE, FOREIGN KEY
Вычисляемые столбцы	Short_DEPT (LEFT(DEPT, 2))
Структура БД

Schemas/
├── Persons/
│   ├── EMPLOYEE (id, first_name, last_name, gender, birthdate, email, ...)
│   └── JOB (id, job_title, salary)
├── Organization/
│   ├── COMPANY (id, name, addres, avg_salary)
│   └── DEPARTMENT (id, name, company_id, short_dept)
└── Location/
    ├── COUNTRY (id, country_name)
    └── CITY (id, city_name, country_id)
Лабораторная работа №2 — Манипуляция данными и транзакции
Стек технологий

PostgreSQL

DML (Data Manipulation Language)

Массивы PostgreSQL

Уровни изоляции транзакций

Основной функционал

Возможность	Реализация
Заполнение справочников	INSERT с подзапросами
Хранение нескольких телефонов	Массив VARCHAR(15)[]
Работа с массивами	array_append, array_remove, обращение по индексу
Конкурентный доступ	REPEATABLE READ, параллельные транзакции
Каскадные операции	ON UPDATE CASCADE, ON DELETE SET NULL
Примеры операций

sql
-- Добавление телефонов массивом
ARRAY['+79161234567', '+74951234567']

-- Обновление элемента массива
SET phone[2] = '+79219876543'

-- Удаление из массива
SET phone = array_remove(phone, phone[2])
Лабораторная работа №3 — Продвинутые возможности PostgreSQL
Стек технологий

Наследование таблиц

Секционирование (PARTITION BY RANGE)

Представления (VIEW)

Архивация данных

Основной функционал

Наследование (схема equipment)

Компонент	Назначение
devices (родитель)	Общие поля: инвентарный номер, название, тип, помещение
computers (дочерняя)	Дополнительно: CPU, RAM, storage
printers (дочерняя)	Дополнительно: brand, color, printer_type
Секционирование (схема partitions)

Компонент	Описание
projects (основная)	Секционирована по дате
projects_jan25	Секция за январь 2025
projects_feb25	Секция за февраль 2025
projects_mar25	Секция за март 2025
projects_apr25	Секция за апрель 2025
projects_archive	Архивная таблица
Представления

department_view — для таблицы отделов

first_department_employees — только сотрудники 1-го отдела

WITH CHECK OPTION — защита от вставки несоответствующих строк

Лабораторная работа №4 — Серверное программирование (PL/pgSQL)
Стек технологий

PL/pgSQL

Функции и процедуры

Триггеры

Аудит данных

Основной функционал

1. Функции

Функция	Назначение
check_email_pattern(emails[], pattern)	Валидация массива email'ов
2. Процедуры

Процедура	Функциональность
update_employee_email(emp_id, new_email)	Обновление email с проверками: существование, валидность, уникальность
3. Триггеры

Триггер	Событие	Назначение
check_login_password	BEFORE INSERT/UPDATE	Валидация логина и пароля (длина ≥8, разные, допустимые символы)
salary_before_update	BEFORE UPDATE OF salary	Запрет повышения зарплаты >100%
after_employee_insert	AFTER INSERT	Сохранение в историю при приеме
after_employee_update	AFTER UPDATE	Сохранение при изменении должности/отдела
after_employee_delete	AFTER DELETE	Сохранение при увольнении
4. Аудит изменений

text
Таблица job_history
├── Все поля из EMPLOYEE
├── date_event (TIMESTAMP) — когда произошло изменение
└── type_operation (VARCHAR) — тип: INSERT, UPDATE, DELETE
Запуск проекта (локально)
bash
# Подключение к PostgreSQL
psql -U postgres -d postgres

# Создание базы данных
CREATE DATABASE employee_management;

# Подключение к созданной БД
\c employee_management

# Запуск лабораторных работ (по порядку)
\i Лабораторная_работа_1_Федоренко.sql
\i Лабораторная_работа_2_Федоренко.sql
\i Лабораторная_работа_3_Федоренко.sql
\i Лабораторная_работа_4_Федоренко.sql
Примеры использования
1. Проверка массива email'ов

sql
SELECT check_email_pattern(
    ARRAY['user@mail.ru', 'test@gmail.com'], 
    '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
); -- Вернет TRUE
2. Обновление email сотрудника

sql
CALL update_employee_email(1, 'new.email@company.ru', NULL);
3. Добавление сотрудника с валидацией

sql
INSERT INTO "Persons"."employee" 
(first_name, last_name, gender, login, password, job_id)
VALUES ('Иван', 'Петров', 'М', 'ivan_petrov', 'securePass123', 1);
-- Триггер проверит логин и пароль
4. Просмотр истории изменений

sql
SELECT * FROM "Persons".job_history 
WHERE employee_id = 1 ORDER BY date_event DESC;
