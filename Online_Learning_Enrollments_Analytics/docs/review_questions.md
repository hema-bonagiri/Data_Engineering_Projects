## Review Questions & Answers

### 1. Why do we keep raw data in Bronze instead of cleaning the file directly?

We keep the original data in the Bronze layer to preserve the source data without losing any information. This helps maintain data lineage, traceability, and auditing. If any transformation or cleaning logic is incorrect, we can always refer back to the original data and reprocess it. Cleaning and validation are performed in the Silver layer, while the Gold layer contains business-ready data for reporting and analysis.

### 2. Why do we use LOWER for emails but INITCAP for category names?

We use `LOWER()` for email addresses because email values should be treated consistently regardless of capitalization. For example, `USER@gmail.com` and `user@gmail.com` should be considered the same email during analysis.

We use `INITCAP()` for category names to make them readable and consistent. For example, `data science`, `DATA SCIENCE`, and `Data Science` can be standardized to `Data Science`. This improves the presentation of categories in reports and dashboards.

### 3. How many learners were double-counted before the email fix, and why does it matter?

The difference between the distinct email count before normalization and after normalization represents the reduction in distinct email values caused by standardizing email formats.

This helps identify inconsistencies in learner email data. Without normalization, the same learner may appear as multiple distinct email values, resulting in inaccurate learner counts and potentially misleading business insights.

### 4. Why can enrollment_id find duplicates but learner_email cannot?

`enrollment_id` uniquely identifies an enrollment record, so repeated enrollment IDs indicate duplicate enrollment records.

However, `learner_email` identifies a learner rather than an enrollment. A learner can enroll in multiple courses, so the same email appearing multiple times is not necessarily a duplicate. Therefore, duplicate detection should be based on enrollment identifiers rather than learner emails.

### 5. Why are progress values of 0 and 100 valid, but 120 is rejected?

Progress percentage represents course completion and should fall between 0 and 100.

- `0` means the learner has not started the course.
- `100` means the learner has completed the course.
- `120` is invalid because progress cannot exceed 100%.

We apply this validation rule to maintain data accuracy and prevent incorrect completion-rate calculations.

### 6. Why do we leave a blank rating as NULL instead of replacing it with 0?

A `NULL` rating represents missing or unavailable rating information, whereas `0` represents an actual numerical value.

Replacing missing ratings with zero would incorrectly suggest that the learner gave a zero rating. Keeping `NULL` preserves the original meaning of the data and prevents misleading average-rating calculations.

### 7. Which category earns the most revenue, and which has the best completion rate?

The category with the highest revenue is identified by aggregating `price_paid` across categories and ranking them in descending order.

The category with the best completion rate is identified by calculating the percentage of enrollments with `progress_pct = 100` for each category.

These metrics help understand which course categories generate the most revenue and which categories demonstrate the strongest learner completion performance.

*The actual category names and values are determined from the Gold layer analysis and dashboard results.*

### 8. Which dashboard tool did you choose, and why?

I chose **Databricks AI/BI Dashboards** to visualize the Gold layer data because it integrates directly with Databricks SQL and Unity Catalog.

It allows me to create KPI cards, charts, and interactive filters without moving the data to another platform. This makes it easier to analyze enrollment trends, revenue performance, learner progress, and category-level insights directly within the Databricks environment.

