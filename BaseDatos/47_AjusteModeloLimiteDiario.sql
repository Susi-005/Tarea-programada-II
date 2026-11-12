USE TareaProgramada2;
GO

ALTER TABLE dbo.TipoCuentaAhorro
ADD
    LimiteDiarioSinpe MONEY NOT NULL
        CONSTRAINT DF_TipoCuentaAhorro_LimiteDiarioSinpe
        DEFAULT (100000),

    ComisionSinpe MONEY NOT NULL
        CONSTRAINT DF_TipoCuentaAhorro_ComisionSinpe
        DEFAULT (0);
GO