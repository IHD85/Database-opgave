-- =========================================
-- SCHEMA + DATA (PostgreSQL)
-- =========================================

drop table if exists "Enrollments";
drop table if exists "Exams";
drop table if exists "Courses";
drop table if exists "Students";
drop table if exists "Programs";

create table "Students" (
  id serial,
  name varchar(200),
  "programId" int
);

create table "Programs" (
  id serial,
  name varchar(200),
  level varchar(100)
);

create table "Enrollments" (
  "studentId" int,
  "courseId" int
);

create table "Exams" (
  "studentId" int,
  "programId" int,
  grade int
);

create table "Courses" (
  id serial,
  name varchar(200),
  "programId" int
);

alter table "Students" add constraint pk_students_id primary key (id);
alter table "Programs" add constraint pk_programs_id primary key (id);
alter table "Enrollments" add constraint pk_composite_studentId_courseId primary key ("studentId", "courseId");
alter table "Exams" add constraint pk_composite_studentId_programId primary key ("studentId", "programId");
alter table "Courses" add constraint pk_courses_id primary key (id);

alter table "Students" add constraint fk_Students_Programs_id foreign key ("programId") references "Programs"(id);
alter table "Enrollments" add constraint fk_Enrollments_Students_id foreign key ("studentId") references "Students"(id);
alter table "Enrollments" add constraint fk_Enrollments_Courses_id foreign key ("courseId") references "Courses"(id);
alter table "Exams" add constraint fk_Exams_Studends_id foreign key ("studentId") references "Students"(id);
alter table "Exams" add constraint fk_Exams_Programs_id foreign key ("programId") references "Programs"(id);
alter table "Courses" add constraint fk_Courses_Programs_id foreign key("programId") references "Programs"(id);

-- DATA
insert into "Programs" (id, name, level) values
  (1, 'Multimediedesigner', 'AP'),
  (2, 'Datamatiker', 'AP'),
  (3, 'Webudvikling', 'Top-op'),
  (4, 'Softwareudvikling', 'Top-op'),
  (5, 'Digital konceptudvikling', 'Top-op');

insert into "Courses" (id, name, "programId") values
  (1, 'Multimedieproduktion 1', 1),
  (2, 'Multimedieproduktion 2', 1),
  (3, 'Programmering 1', 2),
  (4, 'Systemudvikling 1', 2),
  (5, 'Teknologi 1', 2);

insert into "Students" (id, name, "programId") values
  (1, 'Jakob Varring', 1),
  (2, 'John-John', 5),
  (3, 'Kim-Arne', 3),
  (4, 'John Doe', 2),
  (5, 'Jane Doe', 4),
  (6, 'Nalla Eobleh', 1);

insert into "Enrollments" ("studentId", "courseId") values
  (1, 1),
  (1, 2),
  (4, 3),
  (4, 4),
  (6, 1),
  (6, 2);

insert into "Exams" ("studentId", "programId", grade) values
  (1, 1, 2),
  (2, 5, 12),
  (3, 3, 4),
  (4, 2, 10),
  (5, 4, 7),
  (6, 1, 0);

-- =========================================
-- OPGAVER (01–04)
-- =========================================

-- 01) Scalar Subquery
SELECT
  s.id,
  s.name,
  s."programId",
  (SELECT AVG(e.grade) FROM "Exams" e) AS avg_grade_all
FROM "Students" s;

-- 02) Row Subquery (Postgres tuple-compare)
SELECT s.*
FROM "Students" s
WHERE (s.id, s."programId") = (
  SELECT e."studentId", e."programId"
  FROM "Exams" e
  ORDER BY e.grade DESC
  LIMIT 1
);


-- 03) Table Subquery
SELECT s.name
FROM "Students" s
WHERE s.id IN (
  SELECT en."studentId"
  FROM "Enrollments" en
  WHERE en."courseId" IN (
    SELECT c.id
    FROM "Courses" c
    WHERE c."programId" = (
      SELECT p.id FROM "Programs" p
      WHERE p.name = 'Multimediedesigner'
    )
  )
);

-- 04) Correlated Subquery
SELECT
  s.name,
  (
    SELECT MAX(e.grade)
    FROM "Exams" e
    WHERE e."studentId" = s.id
  ) AS best_grade
FROM "Students" s;
