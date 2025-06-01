/*Consultas sobre la tabla con datos proporcionada*/
-- Número de equipos que han disputado partidos y que en todos ellos solo aparecen con su nombre corto.
SELECT COUNT(*) FROM datosdb.ligahost WHERE 
  EQUIPO_LOCAL IS NOT NULL AND CLUB IS NULL AND AND NOMBRE IS NULL AND CIUDAD IS NULL AND FUNDACION IS
  NULL AND ESTADIO IS NULL;
-- Equipos cuyo nombre histórico no es único
SELECT DISTINCT CLUB,  NOMBRE FROM datosdb.ligahost D WHERE 
  EXISTS (SELECT CLUB, NOMBRE FROM datosdb.ligahost WHERE 
            D.CLUB != CLUB AND NOMBRE = D.NOMBRE); 
-- Temporadas en las que se repitió un encuentro x-y más de una vez en una división dada.

/* Creación de tablas y restricciones */
CREATE TABLE Estadio (
    nombEstadio VARCHAR(60) CONSTRAINT nombEstadio_PK PRIMARY KEY,
    capacidad NUMBER(8),
    fechInaug NUMBER(4),
    CONSTRAINT fechaInaug_VAL CHECK (fechInaug > 1888),
    CONSTRAINT capacidad_POS  CHECK (capacidad > 0)
);
CREATE TABLE Equipo (
    nombOf    VARCHAR(60) CONSTRAINT nombOf_UN UNIQUE, 
    nombCorto VARCHAR(60) CONSTRAINT nombCorto_PK PRIMARY KEY,
    nombHist  VARCHAR(60), 
    ciudad    VARCHAR(60),
    fechFund    NUMBER(4),
    nombEstadioEq VARCHAR(60), 
    CONSTRAINT  nombEstadioEq_FK FOREIGN KEY (nombEstadioEq) REFERENCES Estadio(nombEstadio),
    CONSTRAINT fechFund_VAL CHECK (fechFund > 1888)
);
CREATE TABLE otrosNombres (
    otroNomb VARCHAR(60),    
    nombEq  VARCHAR(60)  CONSTRAINT nombOfEq_NN  NOT NULL,
    CONSTRAINT nombEq_FK FOREIGN KEY (nombEq) REFERENCES Equipo(nombCorto)
                                                ON DELETE CASCADE,
    CONSTRAINT otrosNombres_PK PRIMARY KEY (otroNomb, nombEq)
);
CREATE TABLE Jornada (
    numJornada  NUMBER(2),
    temporada    NUMBER(4),
    division    VARCHAR(60),
    CONSTRAINT instancia_PK   PRIMARY KEY (numJornada, temporada, division),
    CONSTRAINT numJornada_POS CHECK (numJornada > 0),
    CONSTRAINT temporada_VAL  CHECK (temporada >= 1972)
);
CREATE TABLE Partido (
    golesLocal NUMBER(2) CONSTRAINT golesLocal_NN NOT NULL,
    golesVisit NUMBER(2) CONSTRAINT golesVisit_NN NOT NULL,
    puntosLocal NUMBER(1),
    puntosVisit NUMBER(1),
    nombLocal VARCHAR(60), 
    nombVisit VARCHAR(60)  CONSTRAINT nombVisit_NN NOT NULL,
    jorPart  NUMBER(2),
    tempPart    NUMBER(4),
    divPart    VARCHAR(60),
    CONSTRAINT nombLocal_PK FOREIGN KEY (nombLocal) REFERENCES Equipo(nombCorto)
                            ON DELETE CASCADE,
    CONSTRAINT nombVisit_PK FOREIGN KEY (nombVisit) REFERENCES Equipo(nombCorto)
                            ON DELETE CASCADE,
    CONSTRAINT partInst_FK FOREIGN KEY (JorPart, tempPart, divPart) 
                                      REFERENCES Jornada(numJornada, temporada, division)
                                      ON DELETE CASCADE,
    CONSTRAINT partido_PK PRIMARY KEY (nombLocal, jorPart, tempPart, divPart),
    CONSTRAINT unicidadJor_VIS UNIQUE (nombVisit, jorPart, tempPart, divPart)
);
