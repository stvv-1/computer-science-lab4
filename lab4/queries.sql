-- Лабораторная работа №4, вариант 5
-- СУБД: SQLite. Выполнять запросы по одному в SandboxSQL.

-- Шаг 1. Контроль количества записей
SELECT 'groups' AS table_name, COUNT(*) AS rows_count FROM groups
UNION ALL SELECT 'students', COUNT(*) FROM students
UNION ALL SELECT 'teachers', COUNT(*) FROM teachers
UNION ALL SELECT 'courses', COUNT(*) FROM courses
UNION ALL SELECT 'enrollments', COUNT(*) FROM enrollments
UNION ALL SELECT 'results', COUNT(*) FROM results
ORDER BY table_name;

-- Шаг 2. Просмотр первых строк (выполнять каждый SELECT отдельно)
SELECT * FROM groups LIMIT 5;
SELECT * FROM students LIMIT 5;
SELECT * FROM teachers LIMIT 5;
SELECT * FROM courses LIMIT 5;
SELECT * FROM enrollments LIMIT 5;
SELECT * FROM results LIMIT 5;

-- Шаг 2. Структура и внешние ключи
PRAGMA table_info(enrollments);
PRAGMA foreign_key_list(enrollments);
PRAGMA table_info(results);
PRAGMA foreign_key_list(results);
-- Дополнительная проверка всех внешних ключей
PRAGMA foreign_key_check;

-- Шаг 3. Курсы от 60 часов
SELECT id, course_name, hours
FROM courses
WHERE hours >= 60
ORDER BY hours DESC, course_name ASC;

-- Шаг 3. Первые 10 студентов, поступивших в 2025 году
SELECT id, full_name, admission_year
FROM students
WHERE admission_year = 2025
ORDER BY full_name ASC
LIMIT 10;

-- Шаг 4. Общее количество записей на курсы
SELECT COUNT(*) AS total_enrollments FROM enrollments;

-- Шаг 4. Агрегаты по продолжительности курсов
SELECT MIN(hours) AS min_hours,
       MAX(hours) AS max_hours,
       ROUND(AVG(hours), 2) AS avg_hours,
       SUM(hours) AS total_hours
FROM courses;

-- Шаг 4. Количество записей по статусам: только группы больше 100
SELECT status, COUNT(*) AS total
FROM enrollments
GROUP BY status
HAVING COUNT(*) > 100
ORDER BY total DESC;

-- Шаг 4. Полное распределение записей по статусам (проверочный запрос)
SELECT status, COUNT(*) AS total
FROM enrollments
GROUP BY status
ORDER BY total DESC;

-- Шаг 5. Студенты и учебные группы
SELECT s.id, s.full_name, g.group_name
FROM students AS s
INNER JOIN groups AS g ON g.id = s.group_id
ORDER BY s.id
LIMIT 10;

-- Шаг 5. Курсы и преподаватели
SELECT c.id, c.course_name, t.full_name AS teacher_name
FROM courses AS c
INNER JOIN teachers AS t ON t.id = c.teacher_id
ORDER BY c.id
LIMIT 10;

-- Шаг 5. Все преподаватели и их курсы
SELECT t.id, t.full_name AS teacher_name, c.course_name
FROM teachers AS t
LEFT JOIN courses AS c ON c.teacher_id = t.id
ORDER BY t.id, c.id;

-- Шаг 6. Оценки вне диапазона 0–100 или NULL
SELECT COUNT(*) AS invalid_scores
FROM results
WHERE score < 0 OR score > 100 OR score IS NULL;

-- Шаг 6. Результаты без соответствующей записи на курс
SELECT COUNT(*) AS orphan_results
FROM results AS r
LEFT JOIN enrollments AS e ON e.id = r.enrollment_id
WHERE e.id IS NULL;

-- Шаг 7 / вариант 5. Основной запрос: разброс оценок по всем курсам с результатами
SELECT c.id AS course_id,
       c.course_name,
       COUNT(r.score) AS results_count,
       MIN(r.score) AS min_score,
       MAX(r.score) AS max_score,
       MAX(r.score) - MIN(r.score) AS score_range,
       ROUND(AVG(r.score), 2) AS avg_score
FROM courses AS c
INNER JOIN enrollments AS e ON e.course_id = c.id
INNER JOIN results AS r ON r.enrollment_id = e.id
GROUP BY c.id, c.course_name
ORDER BY score_range DESC, results_count DESC, c.course_name ASC;

-- Шаг 7 / вариант 5. Проверочный запрос: все курсы с максимальным разбросом
WITH course_ranges AS (
    SELECT c.id AS course_id,
           c.course_name,
           COUNT(r.score) AS results_count,
           MIN(r.score) AS min_score,
           MAX(r.score) AS max_score,
           MAX(r.score) - MIN(r.score) AS score_range,
           ROUND(AVG(r.score), 2) AS avg_score
    FROM courses AS c
    INNER JOIN enrollments AS e ON e.course_id = c.id
    INNER JOIN results AS r ON r.enrollment_id = e.id
    GROUP BY c.id, c.course_name
)
SELECT course_id, course_name, results_count, min_score, max_score,
       score_range, avg_score
FROM course_ranges
WHERE score_range = (SELECT MAX(score_range) FROM course_ranges)
ORDER BY course_name;

-- Шаг 7 / вариант 5. Дополнительная проверка: все курсы, даже без результатов
SELECT c.id AS course_id,
       c.course_name,
       COUNT(e.id) AS enrollments_count,
       COUNT(r.id) AS results_count,
       MIN(r.score) AS min_score,
       MAX(r.score) AS max_score
FROM courses AS c
LEFT JOIN enrollments AS e ON e.course_id = c.id
LEFT JOIN results AS r ON r.enrollment_id = e.id
GROUP BY c.id, c.course_name
ORDER BY results_count ASC, c.course_name ASC;
