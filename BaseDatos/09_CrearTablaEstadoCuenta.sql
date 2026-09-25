USE TareaProgramada2;
GO

CREATE TABLE dbo.EstadoCuenta
(
    id INT IDENTITY(1, 1) NOT NULL,
    idCuenta INT NOT NULL,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    SaldoInicial MONEY NOT NULL,
    SaldoFinal MONEY NOT NULL,
    InteresesAcumulados MONEY NOT NULL
        CONSTRAINT DF_EstadoCuenta_InteresesAcumulados DEFAULT (0),
    CantidadRetiros INT NOT NULL
        CONSTRAINT DF_EstadoCuenta_CantidadRetiros DEFAULT (0),
    CantidadDepositos INT NOT NULL
        CONSTRAINT DF_EstadoCuenta_CantidadDepositos DEFAULT (0),

    CONSTRAINT PK_EstadoCuenta
        PRIMARY KEY (id),

    CONSTRAINT FK_EstadoCuenta_Cuenta
        FOREIGN KEY (idCuenta)
        REFERENCES dbo.Cuenta(id)
);
GO