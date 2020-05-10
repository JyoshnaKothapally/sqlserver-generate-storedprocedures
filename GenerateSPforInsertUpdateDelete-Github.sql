ALTER PROC GenerateSPforInsertUpdateDelete
    @Schemaname SYSNAME = 'dbo' ,
    @Tablename SYSNAME ,
    @ProcName SYSNAME = '' ,
    @IdentityInsert BIT = 0
AS 
    SET NOCOUNT ON
/*
Parameters
@Schemaname			- SchemaName to which the table belongs to. Default value 'dbo'.
@Tablename			- TableName for which the procs needs to be generated.
@ProcName			- Procedure name. Default is blank and when blank the procedure name generated will be sp_<Tablename>
@IdentityInsert		- Flag to say if the identity insert needs to be done to the table or not if identity column exists in the table.
					  Default value is 0.
					  
*/

    DECLARE @PKTable TABLE
        (
          TableQualifier SYSNAME ,
          TableOwner SYSNAME ,
          TableName SYSNAME ,
          ColumnName SYSNAME ,
          KeySeq INT ,
          PKName SYSNAME
        )


    INSERT  INTO @PKTable
            EXEC sp_pkeys @Tablename, @Schemaname

    --SELECT  *  FROM    @PKTable --SELECT

	DECLARE @IdentityColumnName VARCHAR(MAX)
    DECLARE @columnNames VARCHAR(MAX)
    DECLARE @columnNamesWithDatatypes VARCHAR(MAX)
    DECLARE @InsertcolumnNames VARCHAR(MAX)
    DECLARE @InsertcolumnVariables VARCHAR(MAX)
    DECLARE @UpdatecolumnNames VARCHAR(MAX)
    DECLARE @IdentityExists BIT


	SELECT  @IdentityColumnName=''
    SELECT  @columnNames = ''
    SELECT  @columnNamesWithDatatypes = ''
    SELECT  @InsertcolumnNames = ''
    SELECT  @UpdatecolumnNames = ''
    SELECT  @InsertcolumnVariables = ''
    SELECT  @IdentityExists = 0

    DECLARE @MaxLen INT

    SELECT  @MaxLen = MAX(LEN(SC.NAME))
    FROM    sys.schemas SCH
            JOIN sys.tables ST ON SCH.schema_id = ST.schema_id
            JOIN sys.columns SC ON ST.object_id = SC.object_id
    WHERE   SCH.name = @Schemaname
            AND ST.name = @Tablename
            AND SC.is_identity = CASE WHEN @IdentityInsert = 1
                                      THEN SC.is_identity
                                      ELSE 0
                                 END
            AND SC.is_computed = 0


    SELECT  @columnNames = @columnNames + '[' + SC.name + '],' ,
            @columnNamesWithDatatypes = @columnNamesWithDatatypes + '@'
            + REPLACE(SC.name, ' ', '_') + REPLICATE(' ',
                                                     @MaxLen + 5 - LEN(SC.NAME))
            + STY.name + CASE WHEN STY.NAME IN ( 'Char', 'Varchar' )
                                   AND SC.max_length <> -1
                              THEN '(' + CONVERT(VARCHAR(4), SC.max_length)
                                   + ')'
                              WHEN STY.NAME IN ( 'Nchar', 'Nvarchar' )
                                   AND SC.max_length <> -1
                              THEN '(' + CONVERT(VARCHAR(4), SC.max_length / 2)
                                   + ')'
                              WHEN STY.NAME IN ( 'Char', 'Varchar', 'Nchar',
                                                 'Nvarchar' )
                                   AND SC.max_length = -1 THEN '(Max)'
                              ELSE ''
                         END
            + CASE WHEN NOT EXISTS ( SELECT 1
                                     FROM   @PKTable
                                     WHERE  ColumnName = SC.name )
                   THEN ' = NULL,' + CHAR(13)
                   ELSE ',' + CHAR(13)
              END ,
            @InsertcolumnNames = @InsertcolumnNames
            + CASE WHEN NOT EXISTS ( SELECT 1
                                     FROM   @PKTable
                                     WHERE  ColumnName = SC.name )
                   THEN CASE WHEN @UpdatecolumnNames = '' THEN ''
                             ELSE '       '
                        END + '[' + SC.name + ']' + ',' + CHAR(13)
                   ELSE ''
              END ,
            @InsertcolumnVariables = @InsertcolumnVariables
            + CASE WHEN NOT EXISTS ( SELECT 1
                                     FROM   @PKTable
                                     WHERE  ColumnName = SC.name )
                   THEN CASE WHEN @InsertcolumnVariables = '' THEN ''
                             ELSE '       '
                        END + '@' + REPLACE(SC.name, ' ', '_') + ',' + CHAR(13)
                   ELSE ''
              END ,
            @UpdatecolumnNames = @UpdatecolumnNames
            + CASE WHEN NOT EXISTS ( SELECT 1
                                     FROM   @PKTable
                                     WHERE  ColumnName = SC.name )
                   THEN CASE WHEN @UpdatecolumnNames = '' THEN ''
                             ELSE '       '
                        END + '[' + SC.name + ']' + +REPLICATE(' ',
                                                              @MaxLen + 5
                                                              - LEN(SC.NAME))
                        + '= ' + '@' + REPLACE(SC.name, ' ', '_') + ','
                        + CHAR(13)
                   ELSE ''
              END ,
            @IdentityExists = CASE WHEN SC.is_identity = 1
                                        OR @IdentityExists = 1 THEN 1
                                   ELSE 0
                              END
    FROM    sys.schemas SCH
            JOIN sys.tables ST ON SCH.schema_id = ST.schema_id
            JOIN sys.columns SC ON ST.object_id = SC.object_id
            JOIN sys.types STY ON SC.user_type_id = STY.user_type_id
                                  AND SC.system_type_id = STY.system_type_id
    WHERE   SCH.name = @Schemaname
            AND ST.name = @Tablename
            AND SC.is_computed = 0

    DECLARE @InsertSQL VARCHAR(MAX)
    DECLARE @UpdateSQL VARCHAR(MAX)
    DECLARE @DeleteSQL VARCHAR(MAX)
    DECLARE @PKWhereClause VARCHAR(MAX)
    DECLARE @PKExistsClause VARCHAR(MAX)
	DECLARE @IdentityInsertSQL varchar(max)

    --SELECT  @columnNames as ColumnNames --SELECT

    SELECT  @PKWhereClause = ''

    SELECT  @PKWhereClause = @PKWhereClause + ColumnName + ' = ' + '@'
            + ColumnName + '   AND '
    FROM    @PKTable
    ORDER BY KeySeq

	SELECT @IdentityColumnName='@'+ ColumnName +', '  FROM    @PKTable ORDER BY KeySeq

    SELECT  @columnNames = SUBSTRING(@columnNames, 1, LEN(@columnNames) - 1)

    SELECT  @InsertcolumnNames = SUBSTRING(@InsertcolumnNames, 1, LEN(@InsertcolumnNames) - 2)
    SELECT  @InsertcolumnVariables = SUBSTRING(@InsertcolumnVariables, 1, LEN(@InsertcolumnVariables) - 2)
    SELECT  @UpdatecolumnNames = SUBSTRING(@UpdatecolumnNames, 1,LEN(@UpdatecolumnNames) - 2)
    SELECT  @PKWhereClause = SUBSTRING(@PKWhereClause, 1, LEN(@PKWhereClause) - 5)
    SELECT  @PKExistsClause = 'EXISTS (SELECT 1 FROM ' + @Tablename + ' WHERE ' + @PKWhereClause + ')'
    SELECT  @columnNamesWithDatatypes = SUBSTRING(@columnNamesWithDatatypes, 1,
                                                  LEN(@columnNamesWithDatatypes)
                                                  - 2)
    SELECT  @columnNamesWithDatatypes = @columnNamesWithDatatypes + ','
            + CHAR(13) + '@ActionFlag	 VARCHAR(30)'
	SELECT  @IdentityInsertSQL = 'INSERT INTO ' + @Schemaname + '.' + @Tablename
            + CHAR(13) + CHAR(9) + '(' + @columnNames + ')' + +CHAR(13)
            + CHAR(9) + 'SELECT ' +@IdentityColumnName +  @InsertcolumnVariables 
    SELECT  @InsertSQL = 'INSERT INTO ' + @Schemaname + '.' + @Tablename
            + CHAR(13) + CHAR(9) + '(' + @InsertcolumnNames + ')' + +CHAR(13)
            + CHAR(9) + 'SELECT ' + @InsertcolumnVariables 
    SELECT  @DeleteSQL = 'DELETE FROM ' + @Schemaname + '.' + @Tablename
            + CHAR(13) + +CHAR(9) + ' WHERE ' + @PKWhereClause
    SELECT  @UpdateSQL = 'UPDATE ' + @Schemaname + '.' + @Tablename + CHAR(13)
            + CHAR(9) + 'SET ' + @UpdatecolumnNames + CHAR(13) + CHAR(9)
            + 'WHERE ' + @PKWhereClause

    DECLARE @Proc VARCHAR(MAX)
	SELECT @Proc= ''

	IF LTRIM(RTRIM(@ProcName)) = '' 
        SELECT  @ProcName = 'usp_' + @Tablename	
    SELECT @Proc= @Proc + ' IF OBJECT_ID(''' + @ProcName + ''',''P'') IS NOT NULL' + CHAR(13)+CHAR(10) 
    SELECT @Proc= @Proc + ' DROP PROC ' + @ProcName + CHAR(13)+CHAR(10) 
    SELECT @Proc= @Proc + ' GO' + CHAR(13)+CHAR(10) 
    SELECT @Proc= @Proc + ' CREATE PROCEDURE ' + @ProcName + CHAR(13) + '(' + CHAR(13)+CHAR(10) 
        + @columnNamesWithDatatypes + CHAR(13) + ') AS' + CHAR(13)   
    SELECT @Proc= @Proc + ' BEGIN' + CHAR(13)+CHAR(10) 
    SELECT @Proc= @Proc + ' IF @ActionFlag = ''DELETE''' + CHAR(13)+CHAR(10) 
    SELECT @Proc= @Proc + ' BEGIN' + CHAR(13)+CHAR(10) 
    SELECT @Proc= @Proc + CHAR(9) + @DeleteSQL + CHAR(13)+CHAR(10) 
    SELECT @Proc= @Proc + ' END' + CHAR(13)+CHAR(10) 
    SELECT @Proc= @Proc + ' IF ' + @PKExistsClause + CHAR(13)+CHAR(10) 
    SELECT @Proc= @Proc + ' BEGIN' + CHAR(13)+CHAR(10) 
    SELECT @Proc= @Proc + CHAR(9) + @UpdateSQL + CHAR(13)+CHAR(10) 
    SELECT @Proc= @Proc + ' END' + CHAR(13)+CHAR(10) 
    SELECT @Proc= @Proc + ' ELSE' + CHAR(13)+CHAR(10) 
    SELECT @Proc= @Proc + ' BEGIN' + CHAR(13)+CHAR(10) 
   	IF @IdentityExists = 1 AND @IdentityInsert = 1 
	BEGIN
	SELECT @Proc= @Proc + CHAR(9) + 'SET IDENTITY_INSERT ' + @Schemaname + '.'
            + @Tablename + ' ON ' + CHAR(13)+CHAR(10) 
    SELECT @Proc= @Proc + CHAR(9) + @IdentityInsertSQL + CHAR(13)+CHAR(10) 
	 SELECT @Proc= @Proc + ' SET IDENTITY_INSERT ' + @Schemaname + '.' + @Tablename
            + ' OFF ' + CHAR(13)+CHAR(10) 
	END
	ELSE
	BEGIN
	 SELECT @Proc= @Proc + CHAR(9) + @InsertSQL + CHAR(13)+CHAR(10) 
	END
    SELECT @Proc= @Proc + ' END' + CHAR(13)+CHAR(10) 
    SELECT @Proc= @Proc + ' ' + CHAR(13)+CHAR(10) 
    SELECT @Proc= @Proc + ' END' + CHAR(13)+CHAR(10) 
    SELECT @Proc= @Proc + ' GO' + CHAR(13)+CHAR(10) 

	SELECT @Proc as [Proc]
 
    SET NOCOUNT OFF

go
                          



