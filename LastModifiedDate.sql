CREATE OR ALTER PROCEDURE SelectByLastModified
    @TableName NVARCHAR(128)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @OrderColumn NVARCHAR(128);

    IF EXISTS (
        SELECT 1
        FROM sys.columns
        WHERE object_id = OBJECT_ID(@TableName)
          AND name = 'LastModifiedDate'
    )
        SET @OrderColumn = 'LastModifiedDate';
    ELSE
        SET @OrderColumn = 'Id';

    SET @sql = '
        SELECT *
        FROM ' + QUOTENAME(@TableName) + '
        ORDER BY ' + QUOTENAME(@OrderColumn) + ' DESC;
    ';

    EXEC sp_executesql @sql;
END
