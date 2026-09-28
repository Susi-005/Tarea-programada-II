USE TareaProgramada2;
GO

CREATE OR ALTER PROCEDURE dbo.ListarParentescos
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT id, Nombre
        FROM dbo.Parentesco
        ORDER BY id;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50005;
    END CATCH;
END;
GO