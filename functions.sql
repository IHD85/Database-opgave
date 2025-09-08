
DROP FUNCTION IF EXISTS get_student_count() CASCADE;
DROP FUNCTION IF EXISTS get_avg_grade(INT) CASCADE;
DROP FUNCTION IF EXISTS get_students_on_course(INT) CASCADE;


-- 01) Antal studerende

CREATE OR REPLACE FUNCTION get_student_count()
RETURNS INTEGER
LANGUAGE SQL
STABLE
AS $$
  SELECT COUNT(*)::int FROM "Students";
$$;

-- 02) Gennemsnitlig karakter for et program
CREATE OR REPLACE FUNCTION get_avg_grade(programId INT)
RETURNS DOUBLE PRECISION
LANGUAGE SQL
STABLE
AS $$
  SELECT AVG(e.grade)::double precision
  FROM "Exams" e
  WHERE e."programId" = programId;
$$;

-- 03) Studerende på bestemt kursus
CREATE OR REPLACE FUNCTION get_students_on_course(course_id INT)
RETURNS TABLE(name TEXT)
LANGUAGE SQL
STABLE
AS $$
  SELECT s.name
  FROM "Students" s
  JOIN "Enrollments" en
    ON en."studentId" = s.id
  WHERE en."courseId" = course_id
  ORDER BY s.name;
$$;

--tester
SELECT get_student_count();

SELECT get_avg_grade(2);

SELECT * FROM get_students_on_course(1);
