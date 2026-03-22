CREATE OR ALTER PROCEDURE dbo.GetFullTableScript
    @TableName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SchemaName NVARCHAR(128);
    DECLARE @SQL NVARCHAR(MAX) = '';

    -- Get schema name
    SELECT TOP 1 @SchemaName = s.name
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = @TableName;

    -- Start CREATE TABLE statement
    SET @SQL = 'CREATE TABLE [' + @SchemaName + '].[' + @TableName + '] (' + CHAR(13);

    -- Add columns
    SELECT @SQL = @SQL + '    [' + c.name + '] ' +
        TYPE_NAME(c.user_type_id) +
        CASE 
            WHEN TYPE_NAME(c.user_type_id) IN ('varchar','char','nvarchar','nchar') 
                THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length AS VARCHAR(10)) END + ')' 
            ELSE '' 
        END +
        CASE WHEN c.is_identity = 1 THEN ' IDENTITY(1,1)' ELSE '' END +
        CASE WHEN c.is_nullable = 1 THEN ' NULL' ELSE ' NOT NULL' END +
        ISNULL(' DEFAULT ' + dc.definition, '') + ',' + CHAR(13)
    FROM sys.columns c
    LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
    JOIN sys.tables t ON c.object_id = t.object_id
    WHERE t.name = @TableName
    ORDER BY c.column_id;

    SET @SQL = LEFT(@SQL, LEN(@SQL) - 3) + CHAR(13) + ');' + CHAR(13) + CHAR(13);

    SELECT @SQL = @SQL + 'ALTER TABLE [' + @SchemaName + '].[' + @TableName + '] ADD CONSTRAINT [' + kc.name + '] PRIMARY KEY (' +
        STUFF((
            SELECT ',' + '[' + c.name + ']'
            FROM sys.index_columns ic
            JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
            WHERE ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
            ORDER BY ic.key_ordinal
            FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'') + ');' + CHAR(13)
    FROM sys.key_constraints kc
    WHERE kc.parent_object_id = OBJECT_ID(@TableName) AND kc.type = 'PK';

    SELECT @SQL = @SQL + 'ALTER TABLE [' + @SchemaName + '].[' + @TableName + '] ADD CONSTRAINT [' + fk.name + '] FOREIGN KEY (' +
        STUFF((
            SELECT ',' + '[' + c.name + ']'
            FROM sys.foreign_key_columns fkc
            JOIN sys.columns c ON fkc.parent_object_id = c.object_id AND fkc.parent_column_id = c.column_id
            WHERE fkc.constraint_object_id = fk.object_id
            ORDER BY fkc.constraint_column_id
            FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'') +
        ') REFERENCES [' + s2.name + '].[' + t2.name + '] (' +
        STUFF((
            SELECT ',' + '[' + c.name + ']'
            FROM sys.foreign_key_columns fkc
            JOIN sys.columns c ON fkc.referenced_object_id = c.object_id AND fkc.referenced_column_id = c.column_id
            WHERE fkc.constraint_object_id = fk.object_id
            ORDER BY fkc.constraint_column_id
            FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'') + ');' + CHAR(13)
    FROM sys.foreign_keys fk
    JOIN sys.tables t2 ON fk.referenced_object_id = t2.object_id
    JOIN sys.schemas s2 ON t2.schema_id = s2.schema_id
    WHERE fk.parent_object_id = OBJECT_ID(@TableName);

    PRINT @SQL;
END