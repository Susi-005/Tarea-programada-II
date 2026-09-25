USE TareaProgramada2;
GO

CREATE TABLE dbo.Usuario
(
    id INT IDENTITY(1, 1) NOT NULL,
    NombreUsuario VARCHAR(64) NOT NULL,
    Contrasena VARCHAR(128) NOT NULL,
    EsAdministrador BIT NOT NULL,

    CONSTRAINT PK_Usuario
        PRIMARY KEY (id),

    CONSTRAINT UQ_Usuario_NombreUsuario
        UNIQUE (NombreUsuario)
);
GO