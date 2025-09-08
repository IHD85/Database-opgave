
DROP VIEW IF EXISTS student_overview CASCADE;
DROP VIEW IF EXISTS failed_exams CASCADE;
DROP VIEW IF EXISTS program_avg_grades CASCADE;
DROP VIEW IF EXISTS course_enrollments CASCADE;
DROP VIEW IF EXISTS active_students CASCADE;

--opgave 1
CREATE OR REPLACE VIEW student_overview AS
SELECT
  s.id              AS student_id,
  s.name            AS student_name,
  p.name            AS program_name,
  p.level           AS program_level
FROM "Students" s
JOIN "Programs" p
  ON p.id = s."programId";

--opgave 2
CREATE OR REPLACE VIEW failed_exams AS
SELECT
  e."studentId"     AS student_id,
  s.name            AS student_name,
  e."programId"     AS program_id,
  p.name            AS program_name,
  e.grade
FROM "Exams" e
JOIN "Students" s ON s.id = e."studentId"
JOIN "Programs" p ON p.id = e."programId"
WHERE e.grade < 2;

--opgave 3
CREATE OR REPLACE VIEW program_avg_grades AS
SELECT
  p.id              AS program_id,
  p.name            AS program_name,
  AVG(e.grade)      AS avg_grade
FROM "Programs" p
JOIN "Exams" e
  ON e."programId" = p.id
GROUP BY p.id, p.name
ORDER BY p.id;

--opgave 4
CREATE OR REPLACE VIEW course_enrollments AS
SELECT
  c.id                    AS course_id,
  c.name                  AS course_name,
  p.name                  AS program_name,
  COUNT(en."studentId")   AS student_count
FROM "Courses" c
JOIN "Programs" p
  ON p.id = c."programId"
LEFT JOIN "Enrollments" en
  ON en."courseId" = c.id
GROUP BY c.id, c.name, p.name
ORDER BY c.id;

--opgave 5
CREATE OR REPLACE VIEW active_students AS
SELECT s.*
FROM "Students" s
WHERE EXISTS (
  SELECT 1
  FROM "Exams" e
  WHERE e."studentId" = s.id
    AND e.grade >= 2
);

--- Test views  
SELECT * FROM student_overview;
SELECT * FROM failed_exams;
SELECT * FROM program_avg_grades;
SELECT * FROM course_enrollments;
SELECT * FROM active_students;
