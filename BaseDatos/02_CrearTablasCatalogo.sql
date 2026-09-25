USE TareaProgramada2;
GO

CREATE TABLE dbo.TipoDocumentoIdentidad
(
    id INT NOT NULL,
    Nombre VARCHAR(32) NOT NULL,

    CONSTRAINT PK_TipoDocumentoIdentidad
        PRIMARY KEY (id)
);
GO

CREATE TABLE dbo.TipoMoneda
(
    id INT NOT NULL,
    Nombre VARCHAR(32) NOT NULL,
    Simbolo VARCHAR(8) NOT NULL,

    CONSTRAINT PK_TipoMoneda
        PRIMARY KEY (id)
);
GO

CREATE TABLE dbo.Parentesco
(
    id INT NOT NULL,
    Nombre VARCHAR(32) NOT NULL,

    CONSTRAINT PK_Parentesco
        PRIMARY KEY (id)
);
GO

CREATE TABLE dbo.TipoCuentaAhorro
(
    id INT NOT NULL,
    Nombre VARCHAR(32) NOT NULL,
    idTipoMoneda INT NOT NULL,
    SaldoMinimo MONEY NOT NULL,
    MultaSaldoMin MONEY NOT NULL,
    CargoAnual MONEY NOT NULL,
    NumRetirosHumano INT NOT NULL,
    NumRetirosAutomatico INT NOT NULL,
    ComisionHumano MONEY NOT NULL,
    ComisionAutomatico MONEY NOT NULL,
    Interes DECIMAL(5, 2) NOT NULL,

    CONSTRAINT PK_TipoCuentaAhorro
        PRIMARY KEY (id),

    CONSTRAINT FK_TipoCuentaAhorro_TipoMoneda
        FOREIGN KEY (idTipoMoneda)
        REFERENCES dbo.TipoMoneda(id)
);
GO

CREATE TABLE dbo.TipoOperacion
(
    id INT NOT NULL,
    Nombre VARCHAR(64) NOT NULL,

    CONSTRAINT PK_TipoOperacion
        PRIMARY KEY (id)
);
GO