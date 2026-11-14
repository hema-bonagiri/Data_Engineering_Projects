-- Monthly Enrollments
CREATE OR REFRESH MATERIALIZED VIEW gold_monthly_enrollments
AS
SELECT
    DATE_TRUNC('MONTH', enrollment_date) AS enrollment_month,
    COUNT(*) AS enrollments,
    COUNT(DISTINCT learner_email) AS unique_learners,
    SUM(price_paid) AS revenue,
    SUM(
        CASE
            WHEN learner_status = 'Completed' THEN 1
            ELSE 0
        END
    ) AS completions,
    SUM(hours_watched) AS hours_watched
FROM silver_enrollments_clean
GROUP BY DATE_TRUNC('MONTH', enrollment_date);

--Gold Category Summary
CREATE OR REFRESH MATERIALIZED VIEW gold_category_summary
AS
SELECT
    category,
    COUNT(*) AS enrollments,
    SUM(price_paid) AS revenue,

    SUM(CASE WHEN learner_status = 'Completed'
        THEN 1 ELSE 0 END) AS completed,

    SUM(CASE WHEN learner_status = 'In Progress'
        THEN 1 ELSE 0 END) AS in_progress,

    SUM(CASE WHEN learner_status = 'Not Started'
        THEN 1 ELSE 0 END) AS not_started,

    ROUND(
        100.0 * SUM(CASE WHEN learner_status = 'Completed'
            THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS completion_rate_pct,

    ROUND(AVG(progress_pct), 2) AS avg_progress_pct
FROM silver_enrollments_clean
GROUP BY category;

--Gold Course Summary
CREATE OR REFRESH MATERIALIZED VIEW gold_course_summary
AS
SELECT
    category,
    course_name,
    course_level,
    instructor_name,
    COUNT(*) AS enrollments,
    SUM(price_paid) AS revenue,

    ROUND(
        100.0 * SUM(CASE WHEN learner_status = 'Completed'
            THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS completion_rate_pct,

    ROUND(AVG(course_rating), 2) AS avg_rating,
    SUM(hours_watched) AS hours_watched
FROM silver_enrollments_clean
GROUP BY
    category,
    course_name,
    course_level,
    instructor_name;

-- Gold Channel Summary
CREATE OR REFRESH MATERIALIZED VIEW gold_channel_summary
AS
SELECT
    enrollment_channel,
    COUNT(*) AS enrollments,
    SUM(price_paid) AS revenue,

    ROUND(
        100.0 * SUM(CASE WHEN learner_status = 'Completed'
            THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS completion_rate_pct

FROM silver_enrollments_clean
GROUP BY enrollment_channel;

-- Data Quality and reconciliation
CREATE OR REFRESH MATERIALIZED VIEW gold_data_quality
AS
SELECT
    COUNT(*) AS bronze_rows,
    COUNT(*) - COUNT(DISTINCT enrollment_id) AS duplicate_enrollment_id_rows,

    SUM(
        CASE
            WHEN progress_pct < 0 OR progress_pct > 100
            THEN 1 ELSE 0
        END
    ) AS invalid_progress_rows,

    SUM(
        CASE
            WHEN price_paid < 0
            THEN 1 ELSE 0
        END
    ) AS negative_price_rows,

    SUM(
        CASE
            WHEN category IS NULL OR TRIM(category) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_category_rows,

    SUM(
        CASE
            WHEN learner_city IS NULL OR TRIM(learner_city) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_city_rows,

    SUM(
        CASE
            WHEN price_paid IS NULL
            THEN 1 ELSE 0
        END
    ) AS missing_price_rows,

    SUM(
        CASE
            WHEN enrollment_id IS NULL OR TRIM(enrollment_id) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_enrollment_id_rows,

    COUNT(DISTINCT learner_email)
        AS learners_before_email_fix,

    COUNT(DISTINCT LOWER(TRIM(learner_email)))
        AS learners_after_email_fix,

    (SELECT COUNT(*)
     FROM silver_enrollments_clean)
        AS clean_rows,

    (SELECT COUNT(*)
     FROM silver_enrollments_rejected)
        AS rejected_rows

FROM bronze_course_enrollments;




