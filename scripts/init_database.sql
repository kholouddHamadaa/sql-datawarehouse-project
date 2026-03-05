/*
=============================================================
Create Data Warehouse Database & Schemas
=============================================================

Description:
This script initializes the Data Warehouse environment by creating 
a database called 'DataWarehouse'. If the database already exists, 
it will be dropped and recreated to ensure a clean setup.

After creating the database, three schemas are created to implement 
the Medallion Architecture:

- bronze : stores raw data from source systems
- silver : stores cleaned and transformed data
- gold   : stores business-ready data for analytics

Warning:
Running this script will remove the existing 'DataWarehouse' database 
(if it exists), which means all stored data will be permanently deleted. 
*/



USE master;
GO

-- Drop and recreate the 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Create the 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
