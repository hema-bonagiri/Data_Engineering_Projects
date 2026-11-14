-- silver_enrollments_clean
CREATE OR REFRESH MATERIALIZED VIEW silver_enrollments_clean
(
    CONSTRAINT valid_progress EXPECT (progress_pct BETWEEN 0 AND 100) ON VIOLATION DROP ROW,
    CONSTRAINT valid_price EXPECT (price_paid >= 0) ON VIOLATION DROP ROW
)
AS
WITH cleaned AS
(
    SELECT DISTINCT
        TRIM(enrollment_id) AS enrollment_id,
        TRIM(learner_id) AS learner_id,
        LOWER(TRIM(learner_email)) AS learner_email,

        COALESCE(
            NULLIF(INITCAP(TRIM(learner_city)), ''),
            'Unknown'
        ) AS learner_city,

        TRIM(age_group) AS age_group,
        TRIM(course_id) AS course_id,
        TRIM(course_name) AS course_name,

        COALESCE(
            NULLIF(INITCAP(TRIM(category)), ''),
            'Unknown'
        ) AS category,

        INITCAP(TRIM(course_level)) AS course_level,
        TRIM(instructor_name) AS instructor_name,
        enrollment_date,

        COALESCE(
            NULLIF(INITCAP(TRIM(enrollment_channel)), ''),
            'Unknown'
        ) AS enrollment_channel,

        list_price,
        COALESCE(discount_amount, 0) AS discount_amount,

        COALESCE(
            price_paid,
            list_price - COALESCE(discount_amount, 0)
        ) AS price_paid,

        TRIM(payment_method) AS payment_method,

        progress_pct,
        hours_watched,
        course_rating,

        TRIM(certificate_issued) AS certificate_issued,

        source_file,
        loaded_at

    FROM bronze_course_enrollments

    WHERE enrollment_id IS NOT NULL
      AND TRIM(enrollment_id) <> ''
)

SELECT
    *,
    CASE
        WHEN progress_pct = 100 THEN 'Completed'
        WHEN progress_pct > 0 THEN 'In Progress'
        ELSE 'Not Started'
    END AS learner_status
FROM cleaned;


-- silver_enrollments_rejected
CREATE OR REFRESH MATERIALIZED VIEW silver_enrollments_rejected
AS
WITH checked AS
(
    SELECT
        *,
        COALESCE(
            price_paid,
            list_price - COALESCE(discount_amount, 0)
        ) AS calculated_price
    FROM bronze_course_enrollments
)

SELECT
    *,
    CASE
        WHEN enrollment_id IS NULL
          OR TRIM(enrollment_id) = ''
            THEN 'Missing enrollment ID'

        WHEN progress_pct < 0 OR progress_pct > 100
            THEN 'Progress is outside 0 to 100'

        WHEN progress_pct IS NULL
            THEN 'Progress is missing'

        WHEN calculated_price < 0
            THEN 'Price paid is negative'

        WHEN calculated_price IS NULL
            THEN 'Price is missing'

    END AS reject_reason
FROM checked
WHERE enrollment_id IS NULL
   OR TRIM(enrollment_id) = ''
   OR progress_pct < 0
   OR progress_pct > 100
   OR progress_pct IS NULL
   OR calculated_price < 0
   OR calculated_price IS NULL;

