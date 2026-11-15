USE TareaProgramada2;
GO

/* =====================================================
   AJUSTAR TIPO CUENTA AHORRO PARA TP3
   ===================================================== */

IF COL_LENGTH('dbo.TipoCuentaAhorro', 'CargoMensual') IS NULL
BEGIN
    ALTER TABLE dbo.TipoCuentaAhorro
    ADD CargoMensual MONEY NOT NULL
        CONSTRAINT DF_TipoCuentaAhorro_CargoMensual
        DEFAULT (0);
END;
GO


IF COL_LENGTH('dbo.TipoCuentaAhorro', 'MontoMaxSinpeDiario') IS NULL
BEGIN
    ALTER TABLE dbo.TipoCuentaAhorro
    ADD MontoMaxSinpeDiario MONEY NOT NULL
        CONSTRAINT DF_TipoCuentaAhorro_MontoMaxSinpeDiario
        DEFAULT (0);
END;
GO


IF COL_LENGTH('dbo.TipoCuentaAhorro', 'ComisionSinpe') IS NULL
BEGIN
    ALTER TABLE dbo.TipoCuentaAhorro
    ADD ComisionSinpe MONEY NOT NULL
        CONSTRAINT DF_TipoCuentaAhorro_ComisionSinpe
        DEFAULT (0);
END;
GO


IF COL_LENGTH('dbo.TipoCuentaAhorro', 'TasaInteresAnual') IS NULL
BEGIN
    ALTER TABLE dbo.TipoCuentaAhorro
    ADD TasaInteresAnual DECIMAL(5,2) NOT NULL
        CONSTRAINT DF_TipoCuentaAhorro_TasaInteresAnual
        DEFAULT (0);
END;
GO

SELECT
    id,
    Nombre,
    SaldoMinimo,
    MultaSaldoMin,
    CargoMensual,
    NumRetirosHumano,
    NumRetirosAutomatico,
    ComisionHumano,
    ComisionAutomatico,
    MontoMaxSinpeDiario,
    ComisionSinpe,
    TasaInteresAnual
FROM dbo.TipoCuentaAhorro
ORDER BY id;
GO