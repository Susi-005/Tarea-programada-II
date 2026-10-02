USE TareaProgramada2;
GO

CREATE TABLE dbo.Bitacora
(
    id INT IDENTITY(1, 1) NOT NULL,
    idUsuario INT NOT NULL,
    idTipoOperacion INT NOT NULL,
    IP VARCHAR(64) NOT NULL,
    FechaHora DATETIME NOT NULL
        CONSTRAINT DF_Bitacora_FechaHora DEFAULT (GETDATE()),
    DatosAntes VARCHAR(2048) NULL,
    DatosDespues VARCHAR(2048) NULL,

    CONSTRAINT PK_Bitacora PRIMARY KEY (id),

    CONSTRAINT FK_Bitacora_Usuario
        FOREIGN KEY (idUsuario)
        REFERENCES dbo.Usuario(id),

    CONSTRAINT FK_Bitacora_TipoOperacion
        FOREIGN KEY (idTipoOperacion)
        REFERENCES dbo.TipoOperacion(id)
);
GO