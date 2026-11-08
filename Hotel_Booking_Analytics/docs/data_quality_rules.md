# Data Quality Rules

This document explains the data-quality issues identified in the Hotel Booking Analytics project, how they are handled, and where they are applied in the Medallion Architecture.

**Principle:** Bronze preserves raw data, Silver cleans and validates records, and Gold provides trusted business summaries.

### 1. Known Issues in the Source Data

The source file `hotel_bookings_raw.csv` contains **1,316 rows and 20 columns**.

| # | Issue | Example | Explanation |
|---|---|---|---|
| 1 | Duplicate bookings | Same `booking_id` appears more than once | Duplicate records exist. |
| 2 | Extra spaces / mixed case | `" goa"`, `"DELUXE"` | Text values are not standardized. |
| 3 | Blank city or channel | Empty city or channel | Booking information is missing. |
| 4 | Blank nights | `nights` is empty | Stay duration is missing. |
| 5 | Blank total amount | `total_amount` is empty | Booking amount is missing. |
| 6 | Blank rating or guest ID | Missing `guest_rating` or `guest_id` | Guest information is missing. |
| 7 | Invalid dates or rate | Check-out before check-in; negative room rate | Dates or room rate are invalid. |

### 2. Rules by Layer

#### Bronze – Preserve Raw Data

| Rule ID | Rule | Treatment |
|---|---|---|
| BRZ-01 | Preserve original source values. | No modifications. |
| BRZ-02 | Add ingestion metadata. | Add `source_file` and `loaded_at`. |
| BRZ-03 | Validate source row count. | Verify all 1,316 records. |

#### Silver – Clean, Standardize and Validate

| Rule ID | Dimension | Rule | Action |
|---|---|---|---|
| SLV-01 | Duplicates | Remove duplicates based on `booking_id`. | Remove |
| SLV-02 | Standardization | Remove extra spaces using `TRIM()`. | Fix |
| SLV-03 | Standardization | Standardize text casing using `INITCAP()`. | Fix |
| SLV-04 | Completeness | Replace blank city and channel with `Unknown`. | Fix |
| SLV-05 | Completeness | Calculate missing nights using `DATEDIFF()`. | Fix |
| SLV-06 | Completeness | Calculate missing amount using nights × room rate. | Fix |
| SLV-07 | Completeness | Keep missing guest ID and rating as `NULL`. | Keep |
| SLV-08 | Validity | Reject check-out dates on or before check-in dates. | Reject |
| SLV-09 | Validity | Reject negative room rates. | Reject |
| SLV-10 | Business logic | Retain cancelled bookings in Silver. | Keep |

**Important:** `booking_id` is used for deduplication because one guest can make multiple bookings.

#### Gold – Trusted Business Reporting

| Rule ID | Rule | Treatment |
|---|---|---|
| GLD-01 | Use cleaned Silver records for Gold tables. | Filter |
| GLD-02 | Exclude cancelled bookings from revenue and room-night calculations. | Filter |
| GLD-03 | Calculate booking, cancellation, revenue and room-night metrics. | Aggregate |
| GLD-04 | Verify record reconciliation. | Validate |
| GLD-05 | Report data-quality metrics in `gold_data_quality`. | Report |

### 3. Clean vs. Reject

| Aspect | Clean / Fix | Reject |
|---|---|---|
| Meaning | Records that can be corrected or contain optional missing values. | Records containing invalid data. |
| Examples | Extra spaces, blank city/channel, missing nights and amount, missing rating or guest ID. | Invalid dates and negative room rate. |
| Silver table | `silver_bookings_clean` | `silver_bookings_rejected` |
| Treatment | Correct or retain the records. | Store separately with `reject_reason`. |

**Note:**

- Duplicate bookings are removed from clean Silver.
- Invalid records are stored separately with a `reject_reason`.
- Cancelled bookings are valid business records and are not rejected.

### 4. Important Data Quality Columns

The following columns are important for data quality checks, booking analysis and data ingestion.

#### Source Data Columns

| **Column** | **Data Type** | **Description** |
|---|---|---|
| `booking_id` | STRING | Unique booking identifier used for deduplication. |
| `guest_id` | STRING | Guest identifier. |
| `booking_date` | DATE | Date when the booking was made. |
| `check_in_date` | DATE | Guest check-in date. |
| `check_out_date` | DATE | Guest check-out date. |
| `nights` | DOUBLE | Number of nights; missing values are calculated. |
| `hotel_name` | STRING | Name of the hotel. |
| `city` | STRING | City where the hotel is located. |
| `region` | STRING | Region of the hotel. |
| `room_type` | STRING | Type of room booked. |
| `booking_channel` | STRING | Source through which the booking was made. |
| `guests` | INT | Number of guests per booking. |
| `room_rate` | DOUBLE | Room price per night; used for validation. |
| `total_amount` | DOUBLE | Total booking amount. |
| `discount_amount` | DOUBLE | Discount applied to the booking. |
| `meal_plan` | STRING | Meal plan selected by the guest. |
| `payment_method` | STRING | Method used for payment. |
| `payment_status` | STRING | Payment status of the booking. |
| `booking_status` | STRING | Booking status, such as Confirmed or Cancelled. |
| `guest_rating` | DOUBLE | Guest rating; missing values are retained as NULL. |

#### Ingestion Metadata Columns

| **Column** | **Data Type** | **Description** |
|---|---|---|
| `source_file` | STRING | Source CSV filename added during ingestion. |
| `loaded_at` | TIMESTAMP | Timestamp when the record was ingested. |
| `_rescued_data` | STRING | Stores data that could not be mapped correctly during ingestion, if enabled. |

**Note:** The source data contains 20 columns. The ingestion metadata columns are not part of the original CSV and are added or generated during ingestion, depending on the pipeline configuration.

### 5. Pipeline Expectations (Lakeflow)

The following expectations validate records in the Silver clean pipeline.

```sql
CONSTRAINT valid_stay_dates
EXPECT (check_out_date > check_in_date)
ON VIOLATION DROP ROW,

CONSTRAINT valid_room_rate
EXPECT (room_rate >= 0)
ON VIOLATION DROP ROW
```

| Expectation | Behavior |
|---|---|
| `valid_stay_dates` | Checks whether check-out is after check-in. |
| `valid_room_rate` | Checks whether room rate is non-negative. |
| `ON VIOLATION DROP ROW` | Drops invalid records from the clean output. |
| `reject_reason` | Identifies why an invalid booking was rejected in the rejected table. |

### 6. Tables Created

| Layer | Table Name | Purpose |
|---|---|---|
| Bronze | `bronze_hotel_bookings` | Stores raw hotel booking records. |
| Silver | `silver_bookings_clean` | Stores cleaned and valid records. |
| Silver | `silver_bookings_rejected` | Stores invalid records with rejection reasons. |
| Gold | `gold_monthly_bookings` | Monthly booking and revenue analysis. |
| Gold | `gold_hotel_summary` | Hotel and city performance analysis. |
| Gold | `gold_room_type_summary` | Room type and guest rating analysis. |
| Gold | `gold_channel_summary` | Booking channel and cancellation analysis. |
| Gold | `gold_data_quality` | Data-quality metrics and reconciliation results. |

### 7. Investigating Suspicious Records

For rejected or suspicious hotel booking records:

1. Identify the rejected booking records.
2. Compare the records with the original Bronze data.
3. Check `booking_id` and `guest_id`.
4. Examine `room_rate`, `total_amount` and `discount_amount`.
5. Validate `booking_date`, `check_in_date` and `check_out_date`.
6. Review `booking_status` and `payment_status`.
7. Identify duplicate records and validate the rejection reason.
8. Document the reason for rejection.


#### Pipeline Reconciliation Results

| Metric | Row Count |
|---|---:|
| Bronze records | 1,316 |
| Duplicate records removed | 26 |
| Silver clean records | 1,269 |
| Silver rejected records | 21 |
| Total accounted records | 1,316 |

**Reconciliation Check:**

```text
Bronze = Silver Clean + Silver Rejected + Duplicates Removed

1,316 = 1,269 + 21 + 26
```

**Result: PASSED**

### 8. Assumptions and Decisions

- Bronze data is retained as the raw ingestion layer.
- Silver handles data cleaning and validation.
- Rejected records are stored separately.
- Gold tables support business reporting and dashboard development.
- Duplicate records are identified using `booking_id`.
- Booking status and payment status are treated as separate business attributes.
- Original source data remains available for investigation.
- Missing values are handled according to the cleaning rules.
- Cancelled bookings are retained in Silver but excluded from Gold revenue and room-night calculations.
- Reconciliation ensures all Bronze records are accounted for.

