-- STORED PROCEDURES 

DROP PROCEDURE IF EXISTS list_all_students(refcursor);
DROP PROCEDURE IF EXISTS list_students_by_program(integer, refcursor);
DROP PROCEDURE IF EXISTS add_new_student(varchar, integer, integer);
DROP PROCEDURE IF EXISTS update_student_program(integer, integer);

-- 01 Simpel procedure uden parametre 
CREATE OR REPLACE PROCEDURE list_all_students(INOUT cur refcursor)
LANGUAGE plpgsql
AS $$
BEGIN
  IF cur IS NULL THEN
    cur := 'list_all_students_cur';
  END IF;

  OPEN cur FOR
    SELECT s.name AS student_name, p.name AS program_name
    FROM "Students" s
    JOIN "Programs" p ON p.id = s."programId"
    ORDER BY s.name;
END;
$$;

-- 02 Procedure med 1 parameter (program_id)
CREATE OR REPLACE PROCEDURE list_students_by_program(IN program_id INT, INOUT cur refcursor)
LANGUAGE plpgsql
AS $$
BEGIN
  IF cur IS NULL THEN
    cur := 'list_students_by_program_cur';
  END IF;

  OPEN cur FOR
    SELECT s.name AS student_name
    FROM "Students" s
    WHERE s."programId" = program_id
    ORDER BY s.name;
END;
$$;

-- 03 Procedure med INSERT (returnerer nyt id i OUTT Parameter)
CREATE OR REPLACE PROCEDURE add_new_student(
  IN p_name VARCHAR,
  IN p_program_id INT,
  INOUT new_student_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO "Students"(name, "programId")
  VALUES (p_name, p_program_id)
  RETURNING id INTO new_student_id;

  RAISE NOTICE 'Inserted student % with id % (programId=%)', p_name, new_student_id, p_program_id;
END;
$$;

-- 04) Procedure med UPDATE
CREATE OR REPLACE PROCEDURE update_student_program(
  IN student_id INT,
  IN new_program_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE "Students"
  SET "programId" = new_program_id
  WHERE id = student_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Student with id % not found', student_id;
  ELSE
    RAISE NOTICE 'Updated student % to programId %', student_id, new_program_id;
  END IF;
END;
$$;


-- TESTS 
-- A
BEGIN;
CALL list_all_students('cur1');
FETCH ALL FROM cur1;
COMMIT;

BEGIN;
CALL list_students_by_program(1, 'cur2');  
FETCH ALL FROM cur2;
COMMIT;

-- B
SELECT setval(pg_get_serial_sequence('"Students"', 'id'),
              COALESCE((SELECT MAX(id) FROM "Students"), 0), true);


SELECT setval(pg_get_serial_sequence('"Programs"', 'id'),
              COALESCE((SELECT MAX(id) FROM "Programs"), 0), true);
SELECT setval(pg_get_serial_sequence('"Courses"', 'id'),
              COALESCE((SELECT MAX(id) FROM "Courses"), 0), true);

-- C
CALL add_new_student('Ali Test', 1, NULL);
SELECT * FROM "Students" WHERE name = 'Ali Test' ORDER BY id DESC LIMIT 1;

-- D
BEGIN;
CALL update_student_program(
  (SELECT id FROM "Students" WHERE name = 'Ali Test' ORDER BY id DESC LIMIT 1),
  2
);
COMMIT;

SELECT id, name, "programId"
FROM "Students"
WHERE name = 'Ali Test'
ORDER BY id DESC LIMIT 1;

BEGIN;
CALL update_student_program(
  (SELECT id FROM "Students" WHERE name = 'Ali Test' ORDER BY id DESC LIMIT 1),
  1
);
COMMIT;

SELECT id, name, "programId"
FROM "Students"
WHERE name = 'Ali Test'
ORDER BY id DESC LIMIT 1;
