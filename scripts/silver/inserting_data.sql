-- inserting data into silver layer after cleaning and transformation
-- removed null values, only ensured 1 record per cst_id, trimmed spaces from strings, 
-- and converted to upper case for marital status and gender
truncate table silver.crm_cust_info;

insert into silver.crm_cust_info(
	cst_id, 
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date
)
select
	cst_id,
	cst_key,
	trim(cst_firstname) cst_firstname,
	trim(cst_lastname) cst_lastname,
	case 
		when upper(trim(cst_marital_status)) = 'S' then 'Single'
		when upper(trim(cst_marital_status)) = 'M' then 'Married'
		else 'n/a'
	end cst_marital_status,
	case 
		when upper(trim(cst_gndr)) = 'F' then 'Female'
		when upper(trim(cst_gndr)) = 'M' then 'Male'
		else 'n/a'
	end cst_gndr,
	cst_create_date
from (
	select
	*,
	ROW_NUMBER() over (partition by cst_id order by cst_create_date desc) as flag_latest
	from bronze.crm_cust_info
	where cst_id is not null) t
where flag_latest=1;


-- divided prd_key into category id and prd_key, filled prd_cost null values with 0
-- end date is updated with the next start date - 1
truncate table silver.crm_prd_info;

insert into silver.crm_prd_info (
	prd_id,
	cat_id,
	prd_key, 
	prd_nm, 
	prd_cost, 
	prd_line, 
	prd_start_dt, 
	prd_end_dt)

select
	prd_id,
	replace(substring(prd_key, 1, 5), '-', '_') as cat_id,
	substring(prd_key, 7, len(prd_key)) as prd_key,
	prd_nm,
	coalesce(prd_cost,0) as prd_cost,
	case upper(trim(prd_line))
		when 'M' then 'Mountain'
		when 'R' then 'Road'
		when 'S' then 'Other Sales'
		when 'T' then 'Touring'
		else 'n/a'
	end as prd_line,
	prd_start_dt,
	dateadd(day, -1, lead(prd_start_dt,1) over (partition by prd_key order by prd_start_dt)) as prd_end_dt
from bronze.crm_prd_info;