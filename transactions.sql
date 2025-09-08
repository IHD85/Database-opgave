
DROP TABLE IF EXISTS "transfer_log" CASCADE;
DROP TABLE IF EXISTS "Wallets" CASCADE;

-- 01 Wallets + transfer_log
CREATE TABLE "Wallets" (
  id serial PRIMARY KEY,
  "studentId" INT REFERENCES "Students"(id) ON DELETE CASCADE,
  balance NUMERIC(12,2) NOT NULL CHECK (balance >= 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_wallets_student ON "Wallets"("studentId");

CREATE TABLE "transfer_log" (
  id serial PRIMARY KEY,
  from_wallet INT,
  to_wallet   INT,
  amount      NUMERIC(12,2) NOT NULL,
  status      TEXT NOT NULL,            
  message     TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seed testdata 
INSERT INTO "Wallets"("studentId", balance) VALUES
  (1, 100.00),
  (2,  20.00)
ON CONFLICT DO NOTHING;

-- 01 Wallet transfer procedure

DROP PROCEDURE IF EXISTS wallet_transfer(INT, INT, NUMERIC) CASCADE;
CREATE OR REPLACE PROCEDURE wallet_transfer(
  IN p_from_wallet INT,
  IN p_to_wallet   INT,
  IN p_amount      NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_from_bal NUMERIC;
  v_to_bal   NUMERIC;
  v_err TEXT;
BEGIN
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be positive';
  END IF;

  -- Subtransaction (savepoint) for selve overførslen
  BEGIN
   
    SELECT balance INTO v_from_bal FROM "Wallets" WHERE id = p_from_wallet FOR UPDATE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'From wallet % not found', p_from_wallet;
    END IF;

    SELECT balance INTO v_to_bal FROM "Wallets" WHERE id = p_to_wallet FOR UPDATE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'To wallet % not found', p_to_wallet;
    END IF;

    IF v_from_bal < p_amount THEN
      RAISE EXCEPTION 'INSUFFICIENT_FUNDS: need %, have %', p_amount, v_from_bal;
    END IF;

    UPDATE "Wallets" SET balance = balance - p_amount WHERE id = p_from_wallet;
    UPDATE "Wallets" SET balance = balance + p_amount WHERE id = p_to_wallet;

    INSERT INTO "transfer_log"(from_wallet, to_wallet, amount, status, message)
    VALUES (p_from_wallet, p_to_wallet, p_amount, 'OK', 'Transfer completed');
  EXCEPTION WHEN OTHERS THEN
   
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    INSERT INTO "transfer_log"(from_wallet, to_wallet, amount,
                               status,
                               message)
    VALUES (p_from_wallet, p_to_wallet, p_amount,
            CASE WHEN v_err LIKE 'INSUFFICIENT_FUNDS%' THEN 'INSUFFICIENT_FUNDS' ELSE 'ERROR' END,
            v_err);
    
    RETURN;
  END;
END;
$$;

--  02 Batch-tilmeldinger som stored procedure.
DROP PROCEDURE IF EXISTS enroll_many_on_course(INT, INT[], INT, TEXT) CASCADE;
CREATE OR REPLACE PROCEDURE enroll_many_on_course(
  IN  p_course_id INT,
  IN  p_student_ids INT[],
  OUT inserted_count INT,
  OUT status TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
  sid INT;
BEGIN
  inserted_count := 0;
  status := 'OK';

  BEGIN
    
    PERFORM 1 FROM "Courses" WHERE id = p_course_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Course % does not exist', p_course_id;
    END IF;

    FOREACH sid IN ARRAY p_student_ids LOOP
     
      PERFORM 1 FROM "Students" WHERE id = sid;
      IF NOT FOUND THEN
        RAISE EXCEPTION 'Student % does not exist', sid;
      END IF;

  
      INSERT INTO "Enrollments"("studentId","courseId")
      VALUES (sid, p_course_id);

      inserted_count := inserted_count + 1;
    END LOOP;
  EXCEPTION
    WHEN unique_violation THEN
      status := format('ERROR: duplicate enrollment detected for course %', p_course_id);
      inserted_count := 0;
      RAISE; 
    WHEN foreign_key_violation THEN
      status := 'ERROR: foreign key violation (course or student missing)';
      inserted_count := 0;
      RAISE;
    WHEN OTHERS THEN
      status := 'ERROR: ' || SQLERRM;
      inserted_count := 0;
      RAISE;
  END;
END;
$$;


-- TESTS

BEGIN;
CALL wallet_transfer(1, 2, 50.00);
COMMIT;

SELECT * FROM "Wallets" ORDER BY id;
SELECT id, status, message, amount, created_at FROM "transfer_log" ORDER BY id DESC LIMIT 3;


BEGIN;
CALL wallet_transfer(2, 1, 999.00);
COMMIT;

SELECT * FROM "Wallets" ORDER BY id;  
SELECT id, status, message, amount, created_at FROM "transfer_log" ORDER BY id DESC LIMIT 3;


BEGIN;
CALL enroll_many_on_course(1, ARRAY[1,4,6], NULL, NULL);
COMMIT;

SELECT * FROM "Enrollments" WHERE "courseId" = 1 ORDER BY "studentId";


BEGIN;

CALL enroll_many_on_course(1, ARRAY[1,2], NULL, NULL);
ROLLBACK;

BEGIN;
CALL enroll_many_on_course(1, ARRAY[999,6], NULL, NULL);
ROLLBACK;

