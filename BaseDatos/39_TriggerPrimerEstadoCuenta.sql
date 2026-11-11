USE TareaProgramada2;
GO

CREATE OR ALTER TRIGGER dbo.TR_Cuenta_CrearPrimerEstadoCuenta
ON dbo.Cuenta
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.EstadoCuenta
    (
        idCuenta,
        FechaInicio,
        FechaFin,
        SaldoInicial,
        SaldoFinal,
        InteresesAcumulados,
        CantidadRetiros,
        CantidadDepositos,
        SaldoMinimo,
        CantidadOperacionesATM,
        CantidadOperacionesHumano,
        CantidadOperacionesSinpe
    )
    SELECT
        I.id,

        DATEADD
        (
            DAY,
            1,
            I.FechaCreacion
        ),

        DATEADD
        (
            DAY,
            -1,
            DATEADD
            (
                MONTH,
                1,
                DATEADD
                (
                    DAY,
                    1,
                    I.FechaCreacion
                )
            )
        ),

        I.Saldo,
        I.Saldo,
        0,
        0,
        0,
        I.Saldo,
        0,
        0,
        0

    FROM inserted I;
END;
GO