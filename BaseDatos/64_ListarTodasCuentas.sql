USE TareaProgramada2;
GO

CREATE OR ALTER PROCEDURE dbo.ListarTodasCuentas
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            C.id           AS IdCuenta,
            C.NumeroCuenta,
            P.Nombre       AS Titular,
            TC.Nombre      AS TipoCuenta,
            M.Nombre       AS Moneda,
            C.Saldo
        FROM dbo.Cuenta AS C
        INNER JOIN dbo.Persona AS P           ON P.id  = C.idPersona
        INNER JOIN dbo.TipoCuentaAhorro AS TC ON TC.id = C.idTipoCuentaAhorro
        INNER JOIN dbo.TipoMoneda AS M        ON M.id  = TC.idTipoMoneda
        ORDER BY C.NumeroCuenta;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50005;
    END CATCH;
END;
GO