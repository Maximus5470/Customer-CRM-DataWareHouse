use master;
go

-- creating a fresh database for the Customer CRM Data Warehouse. If it already exists, we will drop it and create a new one.
if exists(select * from sys.databases where name = 'CustomerCRM_DWH')
begin
	alter database CustomerCRM_DWH set single_user with rollback immediate;
	drop database CustomerCRM_DWH;
end;
go

create database CustomerCRM_DWH;
go

use CustomerCRM_DWH;
go

-- creating schemas for the data warehouse layers
create schema bronze;
go
create schema silver;
go
create schema gold;
go
