## Review Questions and Answers

### 1. Why did you keep raw data in the Bronze layer instead of cleaning it directly?

I kept the raw data in the Bronze layer to preserve the original source data. This helps us maintain the original records, track data changes, identify issues, and reprocess the data whenever required. Data cleaning is performed in the Silver layer.

### 2. Why did you keep cancelled bookings but reject records where check-out date is before check-in date?

Cancelled bookings are valid business records because they help us analyze cancellation trends and cancellation rates. However, if the check-out date is before the check-in date, the stay dates are invalid. Such records are rejected because they cannot be used for accurate stay-duration and revenue analysis.

### 3. Why can `booking_id` be used to find duplicates, but `guest_id` cannot?

`booking_id` uniquely identifies each booking, so duplicate booking IDs can indicate repeated records. However, one guest can make multiple bookings, so the same `guest_id` can appear in multiple valid records. Therefore, we use `booking_id` to identify duplicate bookings, not `guest_id`.

### 4. How does `DATEDIFF` fill blank nights? What happens if the arguments are swapped?

`DATEDIFF` calculates the number of days between two dates. In our project, we use the check-out date and check-in date to calculate the number of nights.

**Example:**

```sql
DATEDIFF(check_out_date, check_in_date)
```

If we swap the arguments, the result becomes negative for a valid stay. Therefore, the order of dates is important.

### 5. Why did you leave a blank guest rating as `NULL` instead of replacing it with 0?

I kept missing guest ratings as `NULL` because it means the rating was not provided. If I replace it with 0, it may be treated as an actual rating and affect the average rating calculation. `NULL` keeps missing information separate from actual ratings.

### 6. What is ADR, and why do you calculate it as Net Revenue divided by Room Nights?

ADR stands for **Average Daily Rate**. It represents the average revenue earned per occupied room night.

**Formula:**

```text
ADR = Net Revenue / Room Nights
```

For example, if net revenue is ₹30,000 and room nights are 10, the ADR is ₹3,000.

It helps compare average room revenue across hotels, room types, and different periods.

### 7. Which booking channel has the highest cancellation rate?

We calculate the cancellation rate for each booking channel using:

**Formula:**

```text
Cancellation Rate = (Cancelled Bookings / Total Bookings) × 100
```

We compare the cancellation rates across all channels to identify which channel has the highest rate. The actual channel name should be taken from our dashboard results.

### 8. Which dashboard tool did you choose and why?

I chose **Databricks AI/BI Dashboard** because my data pipeline is built in Databricks. It allows me to connect directly to the Gold tables and create interactive dashboards without moving the data to another tool.

I used it to display key metrics, monthly booking trends, hotel performance, room-type performance, and booking channel analysis. It also supports filters and visualizations that help users explore the data and understand business performance.