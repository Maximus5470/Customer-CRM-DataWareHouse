-- inserting data into silver layer after cleaning and transformation
-- removed null values, only ensured 1 record per cst_id, trimmed spaces from strings, 
-- and converted to upper case for marital status and gender
create or alter procedure silver.clean_and_load_data as
begin
	begin try
		declare @batch_start_time datetime, @batch_end_time datetime, @start_time datetime, @end_time datetime;
		set @batch_start_time = GETDATE();
		set @start_time = GETDATE();
		print 'Loading CRM data...';
		print '> Truncating table: silver.crm_cust_info';
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
		set @end_time = GETDATE();
		print '> Time taken to load crm_cust_info: ' + cast(datediff(second, @start_time, @end_time) as varchar) + ' seconds';

		-- divided prd_key into category id and prd_key, filled prd_cost null values with 0
		-- end date is updated with the next start date - 1
		set @start_time = GETDATE();
		print '> Truncating table: silver.crm_prd_info';
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
			cast(prd_start_dt as date) prd_start_dt,
			cast(dateadd(day, -1, lead(prd_start_dt,1) over (partition by prd_key order by prd_start_dt)) as date) as prd_end_dt
		from bronze.crm_prd_info;
		set @end_time = GETDATE();
		print '> Time taken to load crm_prd_info: ' + cast(datediff(second, @start_time, @end_time) as varchar) + ' seconds';

		-- cleaned dates from int to date format, removed records with invalid dates, 
		-- fixed sales, price and quantity values 
		set @start_time = GETDATE();
		print '> Truncating table: silver.crm_sales_details';
		truncate table silver.crm_sales_details;

		insert into silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		select 
		sls_ord_num, 
		sls_prd_key, 
		sls_cust_id, 
		case 
			when sls_order_dt = 0 or len(sls_order_dt) != 8 then null
			else cast(cast(sls_order_dt as varchar) as date)
		end sls_order_dt, 
		case
			when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then null
			else cast(cast(sls_ship_dt as varchar) as date)
		end sls_ship_dt, 
		case
			when sls_due_dt = 0 or len(sls_due_dt) != 8 then null
			else cast(cast(sls_due_dt as varchar) as date)
		end sls_due_dt, 
		case
			when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity*abs(sls_price) 
				then sls_quantity*abs(sls_price)
			else sls_sales
		end as sls_sales,
		sls_quantity,
		case 
			when sls_price is null or sls_price <=0 
				then sls_sales/nullif(sls_quantity, 0)
			else sls_price
		end as sls_price
		from bronze.crm_sales_details;
		set @end_time = GETDATE();
		print '> Time taken to load crm_sales_details: ' + cast(datediff(second, @start_time, @end_time) as varchar) + ' seconds';

		-- removing unnecessary prefix from cid, uniformity in gender values and 
		-- removing birthdates greater than current date
		set @start_time = GETDATE();
		print '> Truncating table: silver.erp_cust_az12';
		truncate table silver.erp_cust_az12;

		insert into silver.erp_cust_az12 (
			cid, 
			bdate, 
			gen
		)
		select
			case 
				when cid like 'NAS%' then substring(cid, 4, len(cid))
				else cid
			end cid,
			case
				when bdate > GETDATE() then null
				else bdate
			end as bdate,
			case
				when upper(trim(gen)) in ('M', 'Male') then 'Male'
				when upper(trim(gen)) in ('F', 'Female') then 'Female'
				else 'n/a'
			end as gen
		from bronze.erp_cust_az12;
		set @end_time = GETDATE();
		print '> Time taken to load erp_cust_az12: ' + cast(datediff(second, @start_time, @end_time) as varchar) + ' seconds';

		-- removed '-' from cid and uniformity in country values
		set @start_time = GETDATE();
		print '> Truncating table: silver.erp_loc_a101';
		truncate table silver.erp_loc_a101;

		insert into silver.erp_loc_a101 (
			cid, 
			cntry
		)
		select 
			replace(cid, '-', '') as cid,
			case 
				when trim(cntry) = 'DE' then 'Germany'
				when trim(cntry) in ('US', 'USA') then 'United States'
				when trim(cntry) = '' or cntry is null then 'n/a'
				else trim(cntry)
			end as cntry
		from bronze.erp_loc_a101;
		set @end_time = GETDATE();
		print '> Time taken to load erp_loc_a101: ' + cast(datediff(second, @start_time, @end_time) as varchar) + ' seconds';

		-- clean data quality
		set @start_time = GETDATE();
		print '> Truncating table: silver.erp_px_cat_g1v2';
		truncate table silver.erp_px_cat_g1v2

		insert into silver.erp_px_cat_g1v2 (
			id, 
			cat, 
			subcat, 
			maintenance
		)
		select
			id,
			cat,
			subcat,
			maintenance
		from bronze.erp_px_cat_g1v2
		set @end_time = GETDATE();
		print '> Time taken to load erp_px_cat_g1v2: ' + cast(datediff(second, @start_time, @end_time) as varchar) + ' seconds';
		set @batch_end_time = GETDATE();
		print 'Total time taken to load data into silver layer: ' + cast(datediff(second, @batch_start_time, @batch_end_time) as varchar) + ' seconds';
	end try
	begin catch
		print 'Error occurred while loading data into silver layer: ' + ERROR_MESSAGE();
	end catch
end