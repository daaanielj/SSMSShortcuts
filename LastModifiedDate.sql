CREATE PROCEDURE SelectByLastModified
    @TableName NVARCHAR(128)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX)
    SET @sql = 'SELECT * FROM ' + QUOTENAME(@TableName) + ' ORDER BY LastModifiedDate DESC;'
    EXEC sp_executesql @sql
END