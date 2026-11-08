
CREATE OR REFRESH STREAMING TABLE bronze_hotel_bookings
AS
SELECT
    *,
    _metadata.file_name AS source_file,
    CURRENT_TIMESTAMP() AS loaded_at

FROM STREAM read_files(
    '/Volumes/hotel_booking_catalog/default/bookings_volume',
    format => 'csv',
    header => true,
    inferColumnTypes => true
);
