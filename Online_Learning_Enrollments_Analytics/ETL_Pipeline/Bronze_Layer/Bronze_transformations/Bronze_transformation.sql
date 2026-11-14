CREATE OR REFRESH STREAMING TABLE bronze_course_enrollments
COMMENT 'Bronze layer: Raw course enrollment data ingested from CSV file'
AS
SELECT
    *,
    _metadata.file_name AS source_file,
    current_timestamp() AS loaded_at
FROM STREAM read_files('/Volumes/edtech_catalog/default/learning_volume',
    format => 'csv',
    header => true
);