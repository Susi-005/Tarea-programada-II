USE TareaProgramada2;
GO

CREATE TABLE dbo.Persona
(
    id INT IDENTITY(1, 1) NOT NULL,
    idTipoDocumentoIdentidad INT NOT NULL,
    Nombre VARCHAR(64) NOT NULL,
    ValorDocumentoIdentidad VARCHAR(32) NOT NULL,
    FechaNacimiento DATE NOT NULL,
    Email VARCHAR(128) NOT NULL,

    CONSTRAINT PK_Persona
        PRIMARY KEY (id),

    CONSTRAINT UQ_Persona_ValorDocumentoIdentidad
        UNIQUE (ValorDocumentoIdentidad),

    CONSTRAINT FK_Persona_TipoDocumentoIdentidad
        FOREIGN KEY (idTipoDocumentoIdentidad)
        REFERENCES dbo.TipoDocumentoIdentidad(id)
);
GO