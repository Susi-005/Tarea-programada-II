USE TareaProgramada2;
GO

/* =====================================================
   TABLA CATALOGO: TIPO DE MOVIMIENTO
   ===================================================== */

CREATE TABLE dbo.TipoMovimiento
(
    id INT NOT NULL,
    Nombre VARCHAR(64) NOT NULL,
    TipoAccion VARCHAR(8) NOT NULL,
    FlagGeneraComprobante BIT NOT NULL,

    CONSTRAINT PK_TipoMovimiento
        PRIMARY KEY (id),

    CONSTRAINT CK_TipoMovimiento_TipoAccion
        CHECK (TipoAccion IN ('CREDITO', 'DEBITO'))
);
GO

/* =====================================================
   TABLA: COMPROBANTE
   ===================================================== */

CREATE TABLE dbo.Comprobante
(
    id INT IDENTITY(1,1) NOT NULL,
    idCuenta INT NOT NULL,
    Fecha DATETIME NOT NULL,
    Texto VARCHAR(256) NOT NULL,

    CONSTRAINT PK_Comprobante
        PRIMARY KEY (id),

    CONSTRAINT FK_Comprobante_Cuenta
        FOREIGN KEY (idCuenta)
        REFERENCES dbo.Cuenta(id)
);
GO


/* =====================================================
   TABLA: MOVIMIENTO
   ===================================================== */

CREATE TABLE dbo.Movimiento
(
    id INT IDENTITY(1,1) NOT NULL,
    idCuenta INT NOT NULL,
    idTipoMovimiento INT NOT NULL,
    idComprobante INT NULL,
    Fecha DATETIME NOT NULL,
    Monto MONEY NOT NULL,
    Descripcion VARCHAR(256) NOT NULL,
    NuevoSaldo MONEY NOT NULL,

    CONSTRAINT PK_Movimiento
        PRIMARY KEY (id),

    CONSTRAINT FK_Movimiento_Cuenta
        FOREIGN KEY (idCuenta)
        REFERENCES dbo.Cuenta(id),

    CONSTRAINT FK_Movimiento_TipoMovimiento
        FOREIGN KEY (idTipoMovimiento)
        REFERENCES dbo.TipoMovimiento(id),

    CONSTRAINT FK_Movimiento_Comprobante
        FOREIGN KEY (idComprobante)
        REFERENCES dbo.Comprobante(id)
);
GO

/* =====================================================
   AJUSTES A ESTADO DE CUENTA PARA TP3
   ===================================================== */

ALTER TABLE dbo.EstadoCuenta
ADD
    SaldoMinimo MONEY NOT NULL
        CONSTRAINT DF_EstadoCuenta_SaldoMinimo DEFAULT (0),

    CantidadOperacionesATM INT NOT NULL
        CONSTRAINT DF_EstadoCuenta_CantidadOperacionesATM DEFAULT (0),

    CantidadOperacionesHumano INT NOT NULL
        CONSTRAINT DF_EstadoCuenta_CantidadOperacionesHumano DEFAULT (0),

    CantidadOperacionesSinpe INT NOT NULL
        CONSTRAINT DF_EstadoCuenta_CantidadOperacionesSinpe DEFAULT (0);
GO

/* =====================================================
   TABLA DE CONTROL DEL PROCESO MASIVO
   ===================================================== */

CREATE TABLE dbo.ControlProcesoSimulacion
(
    id INT IDENTITY(1,1) NOT NULL,

    FechaOperacion DATE NOT NULL,

    UltimoIdProcesado INT NOT NULL
        CONSTRAINT DF_ControlProceso_UltimoIdProcesado
        DEFAULT (0),

    CantidadProcesar INT NOT NULL
        CONSTRAINT DF_ControlProceso_CantidadProcesar
        DEFAULT (0),

    CantidadProcesada INT NOT NULL
        CONSTRAINT DF_ControlProceso_CantidadProcesada
        DEFAULT (0),

    Finalizado BIT NOT NULL
        CONSTRAINT DF_ControlProceso_Finalizado
        DEFAULT (0),

    FechaHoraInicio DATETIME NOT NULL
        CONSTRAINT DF_ControlProceso_FechaHoraInicio
        DEFAULT (GETDATE()),

    FechaHoraFin DATETIME NULL,

    CONSTRAINT PK_ControlProcesoSimulacion
        PRIMARY KEY (id),

    CONSTRAINT UQ_ControlProcesoSimulacion_FechaOperacion
        UNIQUE (FechaOperacion)
);
GO

/* =====================================================
   VALIDACION DEL MODELO FISICO PARA TP3
   ===================================================== */


/* Revisar TipoCuentaAhorro */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'TipoCuentaAhorro'
ORDER BY ORDINAL_POSITION;
GO


/* Revisar TipoMovimiento */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'TipoMovimiento'
ORDER BY ORDINAL_POSITION;
GO


/* Revisar Comprobante */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Comprobante'
ORDER BY ORDINAL_POSITION;
GO


/* Revisar Movimiento */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Movimiento'
ORDER BY ORDINAL_POSITION;
GO


/* Revisar EstadoCuenta */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'EstadoCuenta'
ORDER BY ORDINAL_POSITION;
GO


/* Revisar ControlProcesoSimulacion */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ControlProcesoSimulacion'
ORDER BY ORDINAL_POSITION;
GO

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'EstadoCuenta'
  AND COLUMN_NAME IN
  (
      'SaldoMinimo',
      'CantidadOperacionesATM',
      'CantidadOperacionesHumano',
      'CantidadOperacionesSinpe'
  )
ORDER BY ORDINAL_POSITION;
GO