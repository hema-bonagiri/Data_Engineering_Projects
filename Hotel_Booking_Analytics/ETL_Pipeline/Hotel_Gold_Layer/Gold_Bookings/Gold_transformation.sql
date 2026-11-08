-- Gold Monthly Bookings

CREATE OR REFRESH MATERIALIZED VIEW gold_monthly_bookings
COMMENT 'Gold layer: Monthly hotel booking performance including total bookings, cancellations, completed room nights, and net revenue'
AS
SELECT 
    DATE_TRUNC('MONTH', check_in_date) AS stay_month,
    COUNT(*) AS bookings,
    SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_bookings,
    SUM(CASE WHEN booking_status = 'Completed' THEN nights ELSE 0 END) AS room_nights,
    SUM(CASE WHEN booking_status = 'Completed' THEN total_amount - discount_amount ELSE 0 END) AS net_revenue
FROM silver_bookings_clean
GROUP BY DATE_TRUNC('MONTH', check_in_date);

-- Gold Hotel Summary
CREATE OR REFRESH MATERIALIZED VIEW gold_hotel_summary
COMMENT 'Gold layer: Hotel performance metrics by region, city, and hotel, including bookings, room nights, net revenue, and average daily rate'
AS
SELECT
    region,
    city,
    hotel_name,
    COUNT(*) AS bookings,
    SUM(CASE WHEN booking_status = 'Completed' THEN nights ELSE 0 END) AS room_nights,
    SUM(CASE WHEN booking_status = 'Completed' THEN total_amount - discount_amount ELSE 0 END) AS net_revenue,
    CASE
        WHEN SUM(CASE WHEN booking_status = 'Completed' THEN nights ELSE 0 END) = 0 THEN 0
        ELSE
            SUM(CASE WHEN booking_status = 'Completed' THEN total_amount - discount_amount ELSE 0 END) /
            SUM(CASE WHEN booking_status = 'Completed' THEN nights ELSE 0 END)
    END AS avg_daily_rate
FROM silver_bookings_clean
GROUP BY
    region,
    city,
    hotel_name;

-- Gold Room Type Summary
CREATE OR REFRESH MATERIALIZED VIEW gold_room_type_summary
COMMENT 'Gold layer: Room type performance metrics including bookings, completed room nights, net revenue, and average guest rating'
AS
SELECT
    room_type,
    COUNT(*) AS bookings,
    SUM(CASE WHEN booking_status = 'Completed' THEN nights ELSE 0 END) AS room_nights,
    SUM(CASE WHEN booking_status = 'Completed' THEN total_amount - discount_amount ELSE 0 END) AS net_revenue,
    AVG(guest_rating) AS avg_rating
FROM silver_bookings_clean
GROUP BY room_type;

-- Gold Channel Summary
CREATE OR REFRESH MATERIALIZED VIEW gold_channel_summary
COMMENT 'Gold layer: Booking channel performance including total bookings, cancelled bookings, cancellation rate, and net revenue'
AS
SELECT
    booking_channel,
    COUNT(*) AS bookings,
    SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_bookings,
    ROUND(SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS cancellation_rate_pct,
    SUM(CASE WHEN booking_status = 'Completed' THEN total_amount - discount_amount ELSE 0 END) AS net_revenue
FROM silver_bookings_clean
GROUP BY booking_channel;

-- Gold Data Quality and Reconciliation
CREATE OR REFRESH MATERIALIZED VIEW gold_data_quality
COMMENT 'Gold layer: Data quality monitoring and reconciliation across Bronze, Silver Clean, and Silver Rejected layers'
AS
SELECT
    COUNT(*) AS bronze_rows,
    COUNT(*) - COUNT(DISTINCT booking_id) AS duplicate_rows,
    SUM(CASE WHEN check_out_date <= check_in_date THEN 1 ELSE 0 END ) AS invalid_date_rows,
    SUM(CASE WHEN room_rate < 0 THEN 1 ELSE 0 END) AS negative_rate_rows,
    SUM(CASE WHEN city IS NULL OR TRIM(city) = '' THEN 1 ELSE 0 END) AS missing_city_rows,
    SUM(CASE WHEN booking_channel IS NULL OR TRIM(booking_channel) = '' THEN 1 ELSE 0 END) AS missing_channel_rows,
    SUM(CASE WHEN guest_id IS NULL OR TRIM(guest_id) = '' THEN 1 ELSE 0 END) AS missing_guest_id_rows,
    SUM(CASE WHEN nights IS NULL THEN 1 ELSE 0 END) AS missing_nights_rows,
    SUM(CASE WHEN total_amount IS NULL THEN 1 ELSE 0 END) AS missing_amount_rows,
    (
        SELECT COUNT(*) FROM silver_bookings_clean
    ) AS clean_rows,

    (
        SELECT COUNT(*) FROM silver_bookings_rejected
    ) AS rejected_rows,

    (
        COUNT(*) =
        (
            SELECT COUNT(*) FROM silver_bookings_clean
        )
        +
        (
            SELECT COUNT(*) FROM silver_bookings_rejected
        )
        +
        COUNT(*) - COUNT(DISTINCT booking_id)
    ) AS reconciliation_passed

FROM bronze_hotel_bookings;