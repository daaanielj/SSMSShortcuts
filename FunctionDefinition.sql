CREATE OR ALTER PROCEDURE dbo.CreateAsFunction
    @FunctionName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);

    SELECT @sql = OBJECT_DEFINITION(OBJECT_ID(@FunctionName));

    IF @sql IS NULL
    BEGIN
        PRINT 'Function not found: ' + @FunctionName;
        RETURN;
    END

    SET @sql = REPLACE(@sql, 'CREATE FUNCTION', 'CREATE OR ALTER FUNCTION');

    PRINT '--- Function Definition ---';
    PRINT @sql;
END;