-- Load data into bronze layer from source files present in the datasets folder.

create or alter procedure bronze.load_data as
begin
	begin try
		print 'Loading data into bronze layer...';
		print 'Loading CRM data...';
		print '> Truncating table: bronze.crm_cust_info';
		truncate table bronze.crm_cust_info;

		print '> Inserting data into: bronze.crm_cust_info';
		bulk insert bronze.crm_cust_info
		from 'D:\Datawarehouse CRM\datasets\source_crm\cust_info.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);

		print '> Truncating table: bronze.crm_prd_info';
		truncate table bronze.crm_prd_info;

		print '> Inserting data into: bronze.crm_prd_info';
		bulk insert bronze.crm_prd_info
		from 'D:\Datawarehouse CRM\datasets\source_crm\prd_info.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);

		print '> Truncating table: bronze.crm_sales_details';
		truncate table bronze.crm_sales_details;

		print '> Inserting data into: bronze.crm_sales_details';
		bulk insert bronze.crm_sales_details
		from 'D:\Datawarehouse CRM\datasets\source_crm\sales_details.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);

		print 'Loading ERP data...';
		print '> Truncating table: bronze.erp_cust_az12';
		truncate table bronze.erp_cust_az12;

		print '> Inserting data into: bronze.erp_cust_az12';
		bulk insert bronze.erp_cust_az12
		from 'D:\Datawarehouse CRM\datasets\source_erp\CUST_AZ12.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);

		print '> Truncating table: bronze.erp_loc_a101';
		truncate table bronze.erp_loc_a101;

		print '> Inserting data into: bronze.erp_loc_a101';
		bulk insert bronze.erp_loc_a101
		from 'D:\Datawarehouse CRM\datasets\source_erp\LOC_A101.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);

		print '> Truncating table: bronze.erp_px_cat_g1v2';
		truncate table bronze.erp_px_cat_g1v2;

		print '> Inserting data into: bronze.erp_px_cat_g1v2';
		bulk insert bronze.erp_px_cat_g1v2
		from 'D:\Datawarehouse CRM\datasets\source_erp\PX_CAT_G1V2.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
	end try
	begin catch
	end catch
		print 'Error occurred while loading data: ' + ERROR_MESSAGE();
end