/* Fichero con la población de tablas */

-- CREACIÓN DE TABLAS AUXILIARES
CREATE SEQUENCE secT START WITH 1 INCREMENT BY 1;
CREATE TABLE  tabla_Prov(
    id_Personal NUMBER(10),
    nombre VARCHAR(70),
    genero VARCHAR(1),
    persona_Vac NUMBER(1),
    lugar_Nac  VARCHAR(200),
    bln        NUMBER(1),
    lugar_M VARCHAR(200),
    blm          NUMBER(1),
    fecha_Nac VARCHAR(60),
    bfn          NUMBER(1),
    fecha_M VARCHAR(60),
    bfm          NUMBER(1),
    rol_Personal VARCHAR(30),
    personaje    VARCHAR(100),
    titulo      VARCHAR(200),
    agno_Estreno NUMBER(4),
    tipoDeObra   VARCHAR(20),
    agno_fin_Emision VARCHAR(4),
    titulo_Serie   VARCHAR(200),
    agno_Estreno_Serie NUMBER(4),
    CONSTRAINT tabla_PK PRIMARY KEY(id_Personal)
);  
-- Vista materializada con el nombre de personal referenciando a más de una persona en una obra y la obra
CREATE MATERIALIZED VIEW bipersonas AS
 SELECT DISTINCT d1.title, d1.production_year, d1.kind, d1.name
 FROM datosdb.datospeliculas d1 
      JOIN datosdb.datospeliculas d2 ON(d1.title = d2.title AND d1.production_year=d2.production_year
                                        AND d1.name=d2.name AND d1.kind = d2.kind AND d1.gender = d2.gender)
 WHERE d1.info_context=d2.info_context AND  d1.person_info<>d2.person_info;     
  
-- Insertar en la tabla participaciones de personal en obras donde aparece sin datos
INSERT INTO tabla_Prov
  WITH 
    pers AS(SELECT DISTINCT name, gender, role, role_name, title, production_year, kind, series_years, serie_title, serie_prod_year
            FROM datosdb.datospeliculas
            WHERE info_context IS NULL AND name IS NOT NULL)
  SELECT secT.NEXTVAL, name, gender, 1,NULL,0 , NULL, 0, NULL, 0, NULL, 0, role, role_name, 
         title, production_year, kind, SUBSTR(series_years,6,4), serie_title, serie_prod_year
  FROM pers;

-- Insertar en la tabla participiaciones de personal en obras y sus datos donde aparece con datos 
INSERT INTO tabla_Prov
  WITH
    pers AS(SELECT DISTINCT d.name, d.gender,d.role, role_name, 
                            d.title, d.production_year, kind, series_years, serie_title, serie_prod_year
            FROM datosdb.datospeliculas d
            WHERE d.info_context IS NOT NULL AND d.name IS NOT NULL AND NOT EXISTS
                                                        (SELECT * FROM bipersonas b
                                                         WHERE b.name=d.name AND b.title=d.title AND 
                                                               b.production_year=d.production_year 
                                                               AND b.kind=d.kind))
  SELECT secT.NEXTVAL, name, gender, 0, NULL,0, NULL,0, NULL,0,  NULL,0, role, 
          role_name, title, production_year, kind, SUBSTR(series_years,6,4), serie_title, serie_prod_year 
  FROM pers;
  
-- ACTUALIZAR EL LUGAR DE NACIMIENTO

--  Marcar las filas donde existan datos del lugar de nacimiento
UPDATE tabla_Prov t
SET bln = 1
WHERE persona_Vac = 0 AND EXISTS(SELECT * FROM datosdb.datospeliculas
              WHERE t.nombre=name AND t.titulo=title
                    AND t.agno_Estreno=production_year
                    AND t.tipoDeObra=kind
                    AND info_context='birth notes');
              
-- Almacenar información de esas filas
CREATE MATERIALIZED VIEW ln AS
SELECT DISTINCT name, title, production_year, kind, person_info
FROM datosdb.datospeliculas
WHERE info_context='birth notes';
  
-- Actualizar el lugar de nacimiento en aquellas filas marcadas  
UPDATE tabla_Prov t
  SET lugar_Nac = (SELECT DISTINCT person_info 
                   FROM ln d
                   WHERE t.nombre=d.name AND t.titulo=d.title
                         AND t.agno_Estreno=d.production_year
                         AND t.tipoDeObra=d.kind) 
  WHERE persona_Vac = 0 AND bln = 1 AND NOT EXISTS (SELECT * FROM bipersonas b
                                                    WHERE b.name=nombre AND b.title=titulo AND 
                                                    b.production_year=agno_Estreno 
                                                    AND b.kind=tipoDeObra); 

DROP MATERIALIZED VIEW ln;

-- ACTUALIZAR LUGAR DE MUERTE

--  Marcar las filas donde existan datos del lugar de defunción
UPDATE tabla_Prov t
SET blm = 1
WHERE persona_Vac = 0 AND  EXISTS( SELECT * FROM datosdb.datospeliculas
                                    WHERE t.nombre=name AND t.titulo=title
                                          AND t.agno_Estreno=production_year
                                          AND t.tipoDeObra=kind
                                          AND info_context='death notes');
                    
-- Almacenar información de esas filas
CREATE MATERIALIZED VIEW lm AS
SELECT DISTINCT name, title, production_year, kind, person_info
FROM datosdb.datospeliculas
WHERE info_context='death notes';

-- Actualizar el lugar de defunción en aquellas filas marcadas  
UPDATE tabla_Prov t
  SET lugar_M = (SELECT DISTINCT person_info 
                   FROM lm d
                   WHERE t.nombre=d.name AND t.titulo=d.title
                         AND t.agno_Estreno=d.production_year
                         AND t.tipoDeObra=d.kind) 
  WHERE persona_Vac = 0 AND blm = 1 AND NOT EXISTS (SELECT * FROM bipersonas b
                                                    WHERE b.name=nombre AND b.title=titulo AND 
                                                          b.production_year=agno_Estreno 
                                                           AND b.kind=tipoDeObra); 

DROP MATERIALIZED VIEW lm;

-- ACTUALIZAR FECHA DE NACIMIENTO

--  Marcar las filas donde existan datos de la fecha de nacimiento
UPDATE tabla_Prov t
SET bfn = 1
WHERE persona_Vac = 0 AND EXISTS( SELECT * FROM datosdb.datospeliculas
                                  WHERE t.nombre=name AND t.titulo=title
                                        AND t.agno_Estreno=production_year
                                        AND t.tipoDeObra=kind
                                        AND info_context='birth date');

-- Almacenar información de esas filas                    
CREATE MATERIALIZED VIEW fn AS
SELECT DISTINCT name, title, production_year, kind, person_info
FROM datosdb.datospeliculas
WHERE info_context='birth date';

-- Actualizar la fecha de nacimiento en aquellas filas marcadas    
UPDATE tabla_Prov t
  SET fecha_Nac = (SELECT DISTINCT person_info 
                   FROM fn d
                   WHERE t.nombre=d.name AND t.titulo=d.title
                         AND t.agno_Estreno=d.production_year
                         AND t.tipoDeObra=d.kind) 
  WHERE persona_Vac = 0 AND bfn = 1 AND NOT EXISTS (SELECT * FROM bipersonas b
                                                    WHERE b.name=nombre AND b.title=titulo AND 
                                                          b.production_year=agno_Estreno 
                                                          AND b.kind=tipoDeObra); 

DROP MATERIALIZED VIEW fn;

-- ACTUALIZAR FECHA DE MUERTE

--  Marcar las filas donde existan datos de la fecha de defunción
UPDATE tabla_Prov t
SET bfm = 1
WHERE persona_Vac = 0 AND EXISTS( SELECT * FROM datosdb.datospeliculas
                                  WHERE t.nombre=name AND t.titulo=title
                                        AND t.agno_Estreno=production_year
                                        AND t.tipoDeObra=kind
                                        AND info_context='death date');

-- Almacenar información de esas filas    
CREATE MATERIALIZED VIEW fm AS
SELECT DISTINCT name, title, production_year, kind, person_info
FROM datosdb.datospeliculas
WHERE info_context='death date';

-- Actualizar la fecha de defunción en aquellas filas marcadas   
UPDATE tabla_Prov t
  SET fecha_M = (SELECT DISTINCT person_info 
                   FROM fm d
                   WHERE t.nombre=d.name AND t.titulo=d.title
                         AND t.agno_Estreno=d.production_year
                         AND t.tipoDeObra=d.kind) 
  WHERE persona_Vac = 0 AND bfm = 1 AND NOT EXISTS (SELECT * FROM bipersonas b
                                                    WHERE b.name=nombre AND b.title=titulo AND 
                                                          b.production_year=agno_Estreno 
                                                           AND b.kind=tipoDeObra); 
DROP MATERIALIZED VIEW fm;

-- Añadir manualmente participaciones de personal que aparecen junto con otra de mismo nombre en una misa obra
INSERT INTO tabla_Prov VALUES (secT.NEXTVAL,'Gonzalez Sinde, Jose Maria', 'm', 0, 'Madrid, Spain', 1, NULL, 0, '18 April 1968', 1, NULL, 0, 'actor', 'Pepito', 'Solos en la madrugada', '1978', 'movie', NULL, NULL, NULL);
INSERT INTO tabla_Prov VALUES (secT.NEXTVAL,'Gonzalez Sinde, Jose Maria', 'm', 0, 'Burgos, Castilla y Leon, Spain', 1,'Madrid, Spain', 1, '1941', 1, '20 December 1992', 1, 'writer', NULL, 'Solos en la madrugada', 
'1978', 'movie', NULL, NULL, NULL);
INSERT INTO tabla_Prov VALUES (secT.NEXTVAL,'Gonzalez Sinde, Jose Maria', 'm', 0, 'Burgos, Castilla y Leon, Spain', 1,
                               'Madrid, Spain', 1, '1941', 1, '20 December 1992', 1, 'producer', NULL, 'Solos en la madrugada', '1978', 'movie', NULL, NULL, NULL);
INSERT INTO tabla_Prov VALUES (secT.NEXTVAL,'Gonzalez Sinde, Jose Maria', 'm', 0, 'Madrid, Spain', 1, NULL, 0, '18 April 1968', 1, NULL, 0, 'actor', 'Child', 'Asignatura pendiente', '1977', 'movie', NULL, NULL, NULL);
INSERT INTO tabla_Prov VALUES (secT.NEXTVAL,'Gonzalez Sinde, Jose Maria', 'm', 0, 'Burgos, Castilla y Leon, Spain', 1,
                               'Madrid, Spain', 1, '1941', 1, '20 December 1992', 1, 'writer', NULL, 
                               'Asignatura pendiente', '1977', 'movie', NULL, NULL, NULL);
INSERT INTO tabla_Prov VALUES (secT.NEXTVAL,'Gonzalez Sinde, Jose Maria', 'm', 0, 'Burgos, Castilla y Leon, Spain', 1,
                               'Madrid, Spain', 1, '1941', 1, '20 December 1992', 1, 'producer', NULL, 
                               'Asignatura pendiente', '1977', 'movie', NULL, NULL, NULL);
INSERT INTO tabla_Prov VALUES (secT.NEXTVAL,'Ponte, Laura', 'f', 0, 'Buenos Aires, Argentina', 1, NULL, 0, '1958', 1,   
                                NULL, 0, 'actress','Paula', 'La rosa de piedra', '1999', 'movie', NULL, NULL, NULL);
INSERT INTO tabla_Prov VALUES (secT.NEXTVAL,'Ponte, Laura', 'f', 0, 'Vigo, Pontevedra, Spain', 1, NULL, 0, '9 June 1973', 
                                1, NULL, 0, 'actress','Paula', 'La rosa de piedra', '1999', 'movie', NULL, NULL, NULL);
INSERT INTO tabla_Prov VALUES (secT.NEXTVAL,'Ulloa, Alejandro', 'm', 0, NULL, 0, 'Barcelona, Spain (complications from a fall)', 1,'22 October 1916', 1, '27 April 2004', 0, 'actor', NULL, 'Romanza final (Gayarre)', '1986',                                 'movie', NULL, NULL, NULL);
INSERT INTO tabla_Prov VALUES(secT.NEXTVAL,'Ulloa, Alejandro', 'm', 0, 'Madrid, Spain', 1, 'Madrid, Spain', 1, '14 September 1926', 1, '14/05/2002', 1, 'cinematographer', NULL, 'Romanza final (Gayarre)', '1986', 'movie', NULL, NULL, NULL);

INSERT INTO tabla_Prov VALUES(secT.NEXTVAL,'Nieto, Jose', 'm', 0, 'Madrid, Spain', 1, NULL, 0, '1 March 1942', 1, NULL, 0, 'composer',NULL, 'Hay que matar a B.', '1975', 'movie', NULL, NULL, NULL);

INSERT INTO tabla_Prov VALUES(secT.NEXTVAL,'Nieto, Jose', 'm', 0, 'Murcia, Murcia, Spain', 1, 'Matalascanas, Huelva, Andalucia', 1,
                              '03/05/2003', 1, '9 August 1982', 1, 'actor',NULL, 'Hay que matar a B.', '1975', 'movie', NULL, NULL, NULL);

INSERT INTO tabla_Prov VALUES(secT.NEXTVAL,'Closas, Alberto', 'm', 0, 'Barcelona, Cataluna, S', 1, 
                               NULL, 0, '1961', 1, NULL, 0, 'actor', NULL, 'La familia, bien, gracias', 
                               '1979', 'movie', NULL, NULL, NULL);

INSERT INTO tabla_Prov VALUES(secT.NEXTVAL,'Closas, Alberto', 'm', 0, 'Barcelona, Barcelona, Catalonia, Spain', 1, 
                              'Madrid, Madrid, Spain (lung cancer)', 1, '3 October 1921', 1, '19 September 1994', 
                               1, 'actor','Carlos', 'La familia, bien, gracias', '1979', 'movie', NULL, NULL, NULL);
                              
-- Crear vista materializada con la informacion detallada del personal y sus identificadores artificiales 
CREATE MATERIALIZED VIEW pers_Ext AS
    WITH
      pers AS(
          SELECT DISTINCT nombre, genero, lugar_Nac, lugar_M, fecha_Nac, fecha_M
          FROM tabla_Prov)
    SELECT secP.NEXTVAL id_Personal, nombre, genero, lugar_Nac, lugar_M, fecha_Nac, fecha_M
    FROM pers;
    

-- POBLACIÓN DE LAS TABLAS EN LA BASE DE DATOS

-- Poblacion del personal
INSERT INTO personal
  WITH 
      -- Personal con país de nacimiento
      pers_con_pais AS(
        SELECT DISTINCT id_Personal, nombre, genero, REGEXP_SUBSTR(REGEXP_SUBSTR(lugar_Nac, '[^,]*$'), '[A-Za-z][A-Za-z ]*[A-Za-z]') pais_Nac
        FROM pers_Ext
        WHERE lugar_Nac IS NOT NULL),
      -- Personal sin país de nacimiento
      pers_sin_pais AS(
        SELECT DISTINCT id_Personal, nombre, genero, lugar_Nac pais_Nac
        FROM pers_Ext
        WHERE lugar_Nac IS NULL)
  SELECT id_Personal, nombre, genero, pais_Nac
  FROM (SELECT * FROM pers_con_pais) UNION (SELECT * FROM pers_sin_pais);

-- Poblacion de obras cinematográficas
-- Población de películas o series que no han terminado de emitirse
INSERT INTO obraCinem
  WITH 
      obra AS( 
        SELECT DISTINCT title, production_year, kind
        FROM datosdb.datospeliculas
        WHERE (kind = 'movie' OR (kind = 'tv series' AND SUBSTR(series_years,6,4)='????'))
              AND title IS NOT NULL AND production_year IS NOT NULL)
  SELECT secO.NEXTVAL, title, production_year, kind, NULL
  FROM obra;
-- Población de series que han terminado de emitirse
INSERT INTO obraCinem
  WITH 
      obra AS( 
        SELECT DISTINCT title, production_year, kind, series_years
        FROM datosdb.datospeliculas
        WHERE (kind = 'tv series' AND SUBSTR(series_years,6,4)<>'????' AND series_years IS NOT NULL)
              AND title IS NOT NULL AND production_year IS NOT NULL)
  SELECT secO.NEXTVAL, title, production_year, kind, TO_NUMBER(SUBSTR(series_years,6,4))
  FROM obra;
 
-- Población de género de obras cinematográficas
INSERT INTO genero 
  WITH 
     obra_ext AS 
       (SELECT *
        FROM datosdb.datospeliculas 
             JOIN obraCinem ON(title = titulo AND agno_Estreno = production_year 
                             AND kind = tipoDeObra AND ((((agno_fin_Emision = SUBSTR(series_years,6,4) AND agno_fin_Emision IS NOT NULL) OR 
                                    (agno_fin_Emision IS NULL AND SUBSTR(series_years,6,4) = '????'))
                             AND kind = 'tv series') OR (kind = 'movie'))))
  SELECT DISTINCT keyword, id_Obra
  FROM obra_ext
  WHERE keyword IS NOT NULL;


-- Vista materializada para asociar los identificadores artificiales con las obras y personal de la tabla original
CREATE MATERIALIZED VIEW fila_ext AS
  SELECT DISTINCT p.id_Personal, o.id_Obra, t.rol_Personal, t.personaje
  FROM tabla_Prov t
      JOIN obraCinem o ON(t.titulo=o.titulo AND o.agno_Estreno = t.agno_Estreno 
                             AND t.tipoDeObra = o.tipoDeObra AND ((((o.agno_fin_Emision = t.agno_fin_Emision AND 
                                 o.agno_fin_Emision IS NOT NULL) OR (o.agno_fin_Emision IS NULL AND t.agno_fin_Emision = '????')) 
                             AND t.tipoDeObra = 'tv series') OR (t.tipoDeObra='movie'))
                             OR
                             (t.titulo_Serie = o.titulo AND o.agno_Estreno = t.agno_Estreno_Serie
                              AND t.tipoDeObra = 'episode' AND o.tipoDeObra = 'tv series'))
      JOIN pers_Ext p ON (p.nombre = t.nombre AND (p.genero = t.genero OR (t.genero IS NULL AND 
                          p.genero IS NULL)) 
                            AND ((p.lugar_Nac = t.lugar_Nac) OR (p.lugar_Nac IS NULL AND t.lugar_Nac IS 
                                  NULL))
                            AND ((p.lugar_M = t.lugar_M) OR (p.lugar_M IS NULL AND t.lugar_M IS NULL))
                            AND ((p.fecha_Nac = t.fecha_Nac) OR (p.fecha_Nac IS NULL AND t.fecha_Nac IS 
                                  NULL))
                            AND ((p.fecha_M = t.fecha_M) OR (p.fecha_M IS NULL AND t.fecha_M IS NULL)));

-- Insertar participaciones en películas (que no actuaciones)                            
INSERT INTO participarEn
    SELECT DISTINCT id_Personal, id_Obra
    FROM fila_ext
    WHERE rol_Personal<>'actor' AND rol_Personal<>'actress';
    
-- Insertar actuaciones en películas
INSERT INTO actuarEn
    SELECT DISTINCT id_Personal, id_Obra
    FROM fila_ext
    WHERE rol_Personal='actor' OR rol_Personal='actress';
        
-- Población de roles de participaciones
INSERT INTO rol
  SELECT rol_Personal, id_Personal, id_Obra
  FROM fila_ext
  WHERE rol_Personal<>'actor' AND rol_Personal<>'actress';
  
-- Población de personajes en películas
INSERT INTO personaje
    SELECT DISTINCT personaje, id_Personal, id_obra
    FROM fila_ext
    WHERE personaje IS NOT NULL AND (rol_Personal = 'actor' OR rol_Personal = 'actress');

-- Vista materializada para asociar los identificadores artificiales con las obras relacionadas de la tabla original
CREATE MATERIALIZED VIEW link_ext AS
  SELECT DISTINCT obSuj.id_Obra id_ObraSuj, obObj.id_Obra id_ObraObj, link
  FROM datosdb.datospeliculas db 
       JOIN obraCinem obSuj ON(db.title = obSuj.titulo AND obSuj.agno_Estreno = db.production_year 
                               AND db.kind = obSuj.tipoDeObra AND db.kind = 'movie')
       JOIN obraCinem obObj ON(db.titlelink = obObj.titulo 
                               AND obObj.agno_Estreno = db.productionyearlink
                               AND obObj.tipoDeObra = 'movie');
                               
-- Población de ralaciones entre películas
INSERT INTO RelacionPeli 
  SELECT id_ObraSuj, id_ObraObj, 'remake'
  FROM link_ext
  WHERE link = 'remake of';
INSERT INTO RelacionPeli
  SELECT id_ObraSuj, id_ObraObj, 'secuela'
  FROM link_ext
  WHERE link = 'follows';
  
-- Población  de capítulos
INSERT INTO capitulo
  WITH
    cap AS(  
      SELECT DISTINCT title, id_obra, season_nr, episode_nr
      FROM datosdb.datospeliculas 
           JOIN obraCinem ON (serie_title = titulo AND agno_Estreno = serie_prod_year
                              AND kind = 'episode' AND tipoDeObra = 'tv series'))
  SELECT secC.NEXTVAL, title, id_obra, season_nr, episode_nr
  FROM cap;
  
-- Eliminar elementos auxiliares
DROP MATERIALIZED VIEW fila_ext;
DROP MATERIALIZED VIEW link_ext;
DROP MATERIALIZED VIEW pers_Ext;
DROP MATERIALIZED VIEW bipersonas;
DROP TABLE tabla_Prov;
DROP SEQUENCE secT;

COMMIT;