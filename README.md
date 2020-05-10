# SQLServer Generate/Automate Stored Procedures for Tables

This project aims to generate scripts to automate the creation of stored procedures for an existing table in SQL Server.

For a given table, the scripts will

- Geneartes the query of the procedure with Insert, Update and Delete for the table.

For instance say we have a table:

```
CREATE TABLE [dbo].Employee (
    [Id] BIGINT NOT NULL PRIMARY KEY IDENTITY(1,1),
    [Firstname] VARCHAR(100) NULL,
    [Initial] CHAR(3) NULL,
    [Surname] VARCHAR(100) NULL,
    [Birthdate] DATETIME NULL
)
INSERT INTO Employee (Firstname, Initial, Surname, Birthdate) VALUES ('Nic', 'C', 'Newdigate',GetDate())

```
## Examples: 

1. GenerateSPforInsertUpdateDelete 'dbo','Employee'
2. GenerateSPforInsertUpdateDelete 'dbo','Employee','Employee_INS_UPD_DEL' 
3. GenerateSPforInsertUpdateDelete 'dbo','Employee','Employee_INS_UPD_DEL','1'
4. GenerateSPforInsertUpdateDelete 'dbo','Employee','','1'


Here is how we would generate storedprocedure with Insert/Update and Delete

```
GenerateSPforInsertUpdateDelete 'SchemaName','TableName','ProcedureName',

Parameters
@Schemaname			- SchemaName to which the table belongs to. Default value 'dbo'.
@Tablename			- TableName for which the procs needs to be generated.
@ProcName			- Procedure name. Default is blank and when blank the procedure name generated will be usp_<Tablename>
@IdentityInsert	                - Flag to say if the identity insert needs to be done to the table or not if identity column exists in the table.
					  Default value is 0.            
           
            
```
Thanks for initial script by Sorna Kumar Muthuraj (http://gallery.technet.microsoft.com/scriptcenter/Generate-Stored-Procedure-17a9007d#content)

