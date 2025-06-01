/* Creación de tablas*/

-- Tabla del personal
CREATE SEQUENCE secP START WITH 1 INCREMENT BY 1;
CREATE TABLE personal(
      id_Personal NUMBER(10) PRIMARY KEY,
      nombre VARCHAR(70) NOT NULL,
      genero VARCHAR(1),
      pais_Nac VARCHAR(200),
      CONSTRAINT idPersonal_val CHECK (id_Personal > 0),
      CONSTRAINT genero_Valor CHECK(genero IN ('m', 'f'))
);


-- Tabla de Obras Cinematográficas
CREATE SEQUENCE secO START WITH 1 INCREMENT BY 1;
CREATE TABLE obraCinem(
      id_Obra NUMBER(10) PRIMARY KEY,
      titulo VARCHAR(200) NOT NULL,
      agno_Estreno number(4) NOT NULL,
      tipoDeObra VARCHAR(20) NOT NULL,
      agno_fin_Emision number(4), 
      CONSTRAINT id_Obra_VAL CHECK (id_Obra > 0),
      CONSTRAINT periodoEmision_NULO CHECK((tipoDeObra = 'movie' AND agno_fin_Emision IS NULL) 
                                            OR tipoDeObra = 'tv series'),
      CONSTRAINT agno_fin_Emision_VAL CHECK(agno_fin_Emision IS NULL OR (agno_fin_Emision IS NOT NULL AND
                                            agno_fin_Emision >= agno_Estreno)),
      CONSTRAINT agnoEstreno_VAL CHECK (agno_Estreno >= 1895)
);

-- Tabla de géneros de obras cinematográficas
CREATE TABLE genero(
      genero VARCHAR(20),
      id_Obra NUMBER(10), 
      CONSTRAINT genero_PK PRIMARY KEY (genero, id_Obra),
      CONSTRAINT obraGenero_FK FOREIGN KEY (id_Obra) REFERENCES obraCinem(id_Obra)
                                                     ON DELETE CASCADE
);

-- Tabla de otros trabajos de personal con un rol dado en obras
CREATE TABLE participarEn(
      id_Personal NUMBER(10),
      id_Obra     NUMBER(10),
      CONSTRAINT participarEn_PK PRIMARY KEY (id_personal, id_Obra),
      CONSTRAINT idPersonal_FK FOREIGN KEY (id_Personal) REFERENCES personal(id_Personal),
      CONSTRAINT obra_FK FOREIGN KEY (id_Obra) REFERENCES obraCinem(id_Obra)
);


-- Tabla de roles de una persona en una obra
CREATE TABLE rol(
      rol VARCHAR(30),
      id_Personal NUMBER(10),
      id_Obra     NUMBER(10),
      CONSTRAINT rol_PK PRIMARY KEY (id_personal, rol, id_Obra),
      CONSTRAINT participarEn_FK FOREIGN KEY (id_Personal, id_Obra) 
                                              REFERENCES participarEn(id_Personal, id_Obra),
      CONSTRAINT act_NOVAL CHECK(rol <> 'actor' AND rol <> 'actress')
);
/* NO IMPLEMENTADA POR CUOTA DE ESPACIO
PARTITION BY LIST (rol)
(PARTITION pr1_Director VALUES('director'),
 PARTITION pr2_OtrosRoles VALUES(DEFAULT));*/

-- Tabla de participaciones como actores
CREATE TABLE actuarEn(
      id_Personal NUMBER(10),
      id_Obra     NUMBER(10),
      CONSTRAINT actuarEn_PK PRIMARY KEY (id_personal, id_Obra),
      CONSTRAINT idAct_FK FOREIGN KEY (id_Personal) REFERENCES personal(id_Personal),
      CONSTRAINT obraAct_FK FOREIGN KEY (id_Obra) REFERENCES obraCinem(id_Obra)
);
-- Tabla de personajes
CREATE TABLE  personaje(
      personaje  VARCHAR(100),
      id_Personal NUMBER(10),
      id_Obra NUMBER(10),
      CONSTRAINT personaje_PK PRIMARY KEY (personaje, id_Personal, id_Obra),
      CONSTRAINT actuar_FK FOREIGN KEY (id_Personal, id_Obra)
                             REFERENCES actuarEn(id_Personal, id_Obra)
                             ON DELETE CASCADE
);

-- Tabla de relaciones entre películas
CREATE TABLE RelacionPeli(
      id_Obra_Sujeto NUMBER(10),
      id_Obra_Objeto NUMBER(10),
      tipoRel VARCHAR(10) NOT NULL,
      CONSTRAINT RelacionPeli_PK PRIMARY KEY (id_Obra_Sujeto, id_Obra_Objeto),
      CONSTRAINT peliSujeto_FK FOREIGN KEY (id_Obra_Sujeto)
                               REFERENCES obraCinem(id_Obra),
      CONSTRAINT peliObjeto_FK FOREIGN KEY (id_Obra_Objeto)
                               REFERENCES obraCinem(id_Obra),
      CONSTRAINT relacionPeli_NOREF CHECK (id_Obra_Sujeto <> id_Obra_Objeto),
      CONSTRAINT tpRelacion_VAL CHECK  (tipoRel IN ('remake','secuela','precuela'))
);

-- Tabla de capítulos
CREATE SEQUENCE secC START WITH 1 INCREMENT BY 1;
CREATE TABLE capitulo(
      id_Capitulo NUMBER(5),
      titulo VARCHAR(200) NOT NULL,
      id_Serie NUMBER(10) NOT NULL,
      numCap NUMBER(3),
      numTemp NUMBER(2),
      CONSTRAINT capitulo_PK PRIMARY KEY (id_Capitulo),
      CONSTRAINT serie_FK FOREIGN KEY (id_Serie)
                          REFERENCES obraCinem(id_Obra)
);