USE TareaProgramada2;
GO

CREATE TABLE dbo.Beneficiario
(
    id INT IDENTITY(1, 1) NOT NULL,
    idCuenta INT NOT NULL,
    idPersona INT NOT NULL,
    idParentesco INT NOT NULL,
    Porcentaje INT NOT NULL,
    Enabled BIT NOT NULL
        CONSTRAINT DF_Beneficiario_Enabled DEFAULT (1),
    FechaDesactivacion DATETIME NULL,

    CONSTRAINT PK_Beneficiario
        PRIMARY KEY (id),

    CONSTRAINT FK_Beneficiario_Cuenta
        FOREIGN KEY (idCuenta)
        REFERENCES dbo.Cuenta(id),

    CONSTRAINT FK_Beneficiario_Persona
        FOREIGN KEY (idPersona)
        REFERENCES dbo.Persona(id),

    CONSTRAINT FK_Beneficiario_Parentesco
        FOREIGN KEY (idParentesco)
        REFERENCES dbo.Parentesco(id),

    CONSTRAINT CK_Beneficiario_Porcentaje
        CHECK (Porcentaje >= 0 AND Porcentaje <= 100)
);
GO