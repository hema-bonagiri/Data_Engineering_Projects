CREATE OR REFRESH MATERIALIZED VIEW silver_bookings_clean
(
    CONSTRAINT valid_stay_dates EXPECT (check_out_date > check_in_date) ON VIOLATION DROP ROW,
    CONSTRAINT valid_room_rate EXPECT (room_rate >= 0) ON VIOLATION DROP ROW
)
AS

SELECT DISTINCT

    -- Booking details
    booking_id,guest_id,booking_date,check_in_date,check_out_date,

    -- Calculate missing nights
    COALESCE(nights,DATEDIFF(check_out_date, check_in_date)) AS nights,

    -- Hotel details
    hotel_name,COALESCE(NULLIF(INITCAP(TRIM(city)), ''),'Unknown') AS city,
    region,
    INITCAP(TRIM(room_type)) AS room_type,

    -- Booking details
    COALESCE(NULLIF(INITCAP(TRIM(booking_channel)), ''),'Unknown') AS booking_channel,
    guests,
    room_rate,

    -- Calculate missing total amount
    COALESCE(total_amount,DATEDIFF(check_out_date, check_in_date) * room_rate) AS total_amount,
    discount_amount,

    -- Clean meal plan
    INITCAP(TRIM(meal_plan)) AS meal_plan,

    -- Payment details
    payment_method,
    payment_status,
    booking_status,

    -- Keep missing guest rating as NULL
    guest_rating,

    -- Bronze metadata
    source_file,
    loaded_at
FROM bronze_hotel_bookings;



CREATE OR REFRESH MATERIALIZED VIEW silver_bookings_rejected
AS
SELECT
    *,
    CASE
        WHEN check_out_date <= check_in_date
        THEN 'Check-out is not after check-in'
        ELSE 'Room rate is negative'
    END AS reject_reason

FROM bronze_hotel_bookings
WHERE
    check_out_date <= check_in_date
    OR room_rate < 0;