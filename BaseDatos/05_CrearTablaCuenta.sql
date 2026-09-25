USE TareaProgramada2;
GO

CREATE TABLE dbo.Cuenta
(
    id INT IDENTITY(1, 1) NOT NULL,
    idPersona INT NOT NULL,
    idTipoCuentaAhorro INT NOT NULL,
    NumeroCuenta VARCHAR(32) NOT NULL,
    FechaCreacion DATE NOT NULL,
    Saldo MONEY NOT NULL,

    CONSTRAINT PK_Cuenta
        PRIMARY KEY (id),

    CONSTRAINT UQ_Cuenta_NumeroCuenta
        UNIQUE (NumeroCuenta),

    CONSTRAINT FK_Cuenta_Persona
        FOREIGN KEY (idPersona)
        REFERENCES dbo.Persona(id),

    CONSTRAINT FK_Cuenta_TipoCuentaAhorro
        FOREIGN KEY (idTipoCuentaAhorro)
        REFERENCES dbo.TipoCuentaAhorro(id)
);
GO