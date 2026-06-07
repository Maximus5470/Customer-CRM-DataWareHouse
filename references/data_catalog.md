
  # Data Catalog — Gold Layer

  This document describes the views present in the `gold` layer: `gold.dim_customers`, `gold.dim_products`, and `gold.fact_sales`.

  Overview
  - The `gold` layer contains curated, join-ready views for dimensions and facts used by reporting and BI.

  ## gold.dim_customers

  Description: Dimension of customers sourced from `silver.crm_cust_info` with ERP enrichments.

  Source: `silver.crm_cust_info` (ci), left joins to `silver.erp_cust_az12` (ca) and `silver.erp_loc_a101` (la).

  | Column | Suggested Type | Description |
  |---|---:|---|
  | customer_key | INT | Integer assigned at query time; unique within this view result but not stable across runs. |
  | customer_id | VARCHAR | Alphanumeric CRM identifier for the customer (e.g., numeric or code like C12345). |
  | customer_number | VARCHAR | CRM account/key used for lookups; typically alphanumeric. |
  | first_name | VARCHAR | Person's given name (text). |
  | last_name | VARCHAR | Person's family name (text). |
  | country | VARCHAR | Country value — commonly a 2-letter ISO code (US) or full country name (United States). |
  | marital_status | VARCHAR | Short label for marital status ('Single', 'Married'). |
  | gender | VARCHAR | Short code or label ('Male', 'Female', or 'n/a'). |
  | birth_date | DATE | Date of birth in YYYY-MM-DD format (may be NULL). |
  | create_date | DATETIME | Timestamp when the CRM record was created (ISO datetime format). |

  Notes: Types are suggested and should be validated against the upstream `silver` schemas. `customer_key` is generated at view runtime and can change between executions.

  ## gold.dim_products

  Description: Dimension of active products from CRM, enriched by ERP category metadata.

  Source: `silver.crm_prd_info` (pn), left join to `silver.erp_px_cat_g1v2` (pc). Filter: `pn.prd_end_dt IS NULL`.

  | Column | Suggested Type | Description |
  |---|---:|---|
  | product_key | INT | Integer assigned at query time; unique within the view result but not stable across runs. |
  | product_id | VARCHAR | Alphanumeric product identifier used by CRM. |
  | product_number | VARCHAR | Product key used for system joins (alphanumeric code). |
  | product_name | VARCHAR | Product display name (text). |
  | category_id | VARCHAR | Category identifier or code (may be numeric or alphanumeric). |
  | category | VARCHAR | Category name or label (text). |
  | sub_category | VARCHAR | Sub-category name or label (text). |
  | maintenance | VARCHAR | Small flag or code indicating maintenance status ('Yes'/'No'). |
  | cost | DECIMAL(18,2) | Monetary amount representing cost (decimal, currency). |
  | product_line | VARCHAR | High-level product grouping or line name (text). |
  | start_date | DATE | Date the product became active (YYYY-MM-DD). |

  Notes: `product_number` is the canonical join key used in `fact_sales`. Persist `product_key` if you need stable surrogate keys.

  ## gold.fact_sales

  Description: Sales fact view joining sales transactions to product and customer dimensions.

  Source: `silver.crm_sales_details` (sd), left join to `gold.dim_products` (pr) and `gold.dim_customers` (c).

  | Column | Suggested Type | Description |
  |---|---:|---|
  | order_number | VARCHAR | Order identifier used in sales systems (alphanumeric). |
  | product_key | INT | Product surrogate key from the products view; integer or NULL when no matching product. |
  | customer_key | INT | Customer surrogate key from the customers view; integer or NULL when no matching customer. |
  | order_date | DATE | Timestamp or date when the order was placed (ISO datetime). |
  | shipping_date | DATE | Date/time item was shipped; may be NULL if not shipped yet. |
  | due_date | DATE | Promised delivery or due date; may be NULL. |
  | sales_amount | DECIMAL(18,2) | Line-level monetary amount (decimal, currency). |
  | quantity | INT | Integer count of units sold on this line. |
  | price | DECIMAL(18,2) | Unit price applied to the line (decimal, currency). |

  Notes & cautions:
  - Joins rely on matching formats between `sd.sls_prd_key` -> `pn.prd_key` and `sd.sls_cust_id` -> `ci.cst_id`. Normalize types/leading zeros if necessary.
  - Because dimensions are views (surrogate keys generated at runtime), referential stability is not guaranteed. For reporting or foreign-key constraints consider persisting dimensions as physical tables.

  References
  - View creation SQL: `scripts/gold/creating_views.sql`
