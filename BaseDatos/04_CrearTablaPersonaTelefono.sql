USE TareaProgramada2;
GO

CREATE TABLE dbo.PersonaTelefono
(
    id INT IDENTITY(1, 1) NOT NULL,
    idPersona INT NOT NULL,
    NumeroTelefono VARCHAR(16) NOT NULL,

    CONSTRAINT PK_PersonaTelefono
        PRIMARY KEY (id),

    CONSTRAINT FK_PersonaTelefono_Persona
        FOREIGN KEY (idPersona)
        REFERENCES dbo.Persona(id)
);
GO