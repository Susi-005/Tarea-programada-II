USE TareaProgramada2;
GO

CREATE TABLE dbo.UsuarioCuenta
(
    id INT IDENTITY(1, 1) NOT NULL,
    idUsuario INT NOT NULL,
    idCuenta INT NOT NULL,

    CONSTRAINT PK_UsuarioCuenta
        PRIMARY KEY (id),

    CONSTRAINT UQ_UsuarioCuenta
        UNIQUE (idUsuario, idCuenta),

    CONSTRAINT FK_UsuarioCuenta_Usuario
        FOREIGN KEY (idUsuario)
        REFERENCES dbo.Usuario(id),

    CONSTRAINT FK_UsuarioCuenta_Cuenta
        FOREIGN KEY (idCuenta)
        REFERENCES dbo.Cuenta(id)
);
GO