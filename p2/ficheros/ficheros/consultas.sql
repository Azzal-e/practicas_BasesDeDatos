-- CONSULTA 1

/*
    CONSULTA ORIGINAL: SIN MEJORAS
    
WITH
	-- personal que ha trabajado como director en películas
	director AS(
    	SELECT DISTINCT id_Personal
    	FROM rol  NATURAL JOIN obraCinem
    	WHERE rol = 'director' AND tipoDeObra= 'movie'),
	-- Última participación de directores en películas (no como actores)
	ult_trabajo_dir AS(
    	SELECT id_Personal, MAX(agno_Estreno) agno_Part
    	FROM director NATURAL JOIN participarEn NATURAL JOIN obraCinem
    	WHERE tipoDeObra = 'movie'
    	GROUP BY id_Personal),
	-- última actuacion de directores como actores en películas
	ult_act_dir AS(
    	SELECT id_Personal, MAX(agno_Estreno) agno_Act
    	FROM director NATURAL JOIN actuarEn NATURAL JOIN obraCinem
    	WHERE tipoDeObra = 'movie'
    	GROUP BY id_Personal)
SELECT id_Personal "Directores cuya ultima participacion haya sido como actor/actriz",
   	nombre
FROM ult_act_dir NATURAL JOIN ult_trabajo_dir NATURAL JOIN personal
WHERE agno_Act >= agno_Part
ORDER BY nombre ASC;
*/
-- Consulta con mejoras de rendimiento

WITH 
    -- Última participación @de directores en obras (no como actores)
    ult_trab_dir AS(
        SELECT id_Personal, MAX(agno_Estreno) agno_Trab
        FROM ult_act_dir NATURAL JOIN participarEn NATURAL JOIN obraCinem
        WHERE tipoDeObra = 'movie'
        GROUP BY id_Personal)
SELECT id_Personal "Directores cuya ultima participacion haya sido como actor/actriz",
       nombre 
FROM ult_trab_dir NATURAL JOIN ult_act_dir NATURAL JOIN personal
WHERE agno_Act >= agno_Trab
ORDER BY nombre ASC;

-- CONSULTA 2

/*
    CONSULTA ORIGINAL: SIN MEJORAS
    
WITH
    -- Tamaño de cada serie (saga o subsaga)
    serie_Tam AS(
        SELECT id_Obra_Objeto, (COUNT(*)+1) totalSaga
        FROM relacionPeli
        WHERE tipoRel = 'secuela' OR tipoRel = 'precuela'
        GROUP BY id_Obra_Objeto),
    -- Película central de la saga más larga
    max_Saga AS(
        SELECT id_Obra_Objeto id_Obra
        FROM serie_Tam
        WHERE totalSaga >= (SELECT MAX(totalSaga) FROM serie_Tam)),
    -- Resto de películas de la saga
    saga AS(
        SELECT id_Obra_Sujeto id_Obra
        FROM relacionPeli JOIN max_Saga ON (id_Obra = id_Obra_Objeto)
        WHERE tipoRel = 'secuela' OR tipoRel = 'precuela'),
    -- Saga completa
    saga_completa AS(
        SELECT * FROM max_Saga 
        UNION 
        SELECT * FROM saga)
SELECT titulo, agno_Estreno
FROM saga_completa NATURAL JOIN obraCinem
ORDER BY agno_Estreno ASC;
*/

-- Consulta con mejoras de rendimiento

WITH
    -- Película central de la saga más larga
    max_Saga AS(
        SELECT id_Obra_Objeto id_Obra
        FROM serie_Tam
        WHERE totalSaga >= (SELECT MAX(totalSaga) FROM serie_Tam)),
    -- Resto de películas de la saga
    saga AS(
        SELECT id_Obra_Sujeto id_Obra
        FROM relacionPeli JOIN max_Saga ON (id_Obra = id_Obra_Objeto)
        WHERE tipoRel = 'secuela' OR tipoRel = 'precuela'),
    -- Saga completa
    saga_completa AS(
        SELECT * FROM max_Saga 
        UNION 
        SELECT * FROM saga)
SELECT titulo, agno_Estreno
FROM saga_completa NATURAL JOIN obraCinem
ORDER BY agno_Estreno ASC;

-- CONSULTA 3
/*
      CONSULTA ORIGINAL: SIN MEJORAS

WITH
    -- Obras dentro del rango estipulado
    obras_val AS(
        SELECT id_Obra
        FROM obraCinem
        WHERE agno_Estreno >= 1980 AND agno_Estreno <= 2010
              AND tipoDeObra='movie'),
    -- Actuaciones de actores
    actor_actuacion AS(
        SELECT id_Personal actor, pais_Nac nac_Actor, id_Obra
        FROM  actuarEn NATURAL JOIN personal NATURAL JOIN obras_val
        WHERE genero = 'm' AND pais_Nac IS NOT NULL),
    -- Actuaciones de actrices
    actriz_actuacion AS(
        SELECT id_Personal actriz, pais_Nac nac_Actriz, id_Obra
        FROM actuarEn NATURAL JOIN personal NATURAL JOIN obras_val
        WHERE genero = 'f' AND pais_Nac IS NOT NULL),
    -- Colaboraciones entre actor-actriz
    colab AS(
        SELECT actor, actriz, COUNT(*) part
        FROM actriz_actuacion NATURAL JOIN actor_actuacion
        WHERE nac_actor <> nac_actriz
        GROUP BY actor, actriz),
    -- Parejas actor actriz que hayan colaborado siempre juntos entre 1980 y 2010
    colab_const AS(
        SELECT *
        FROM colab c
        WHERE part = (SELECT COUNT(*) FROM actor_actuacion a1
                      WHERE c.actor = a1.actor)
              AND
              part = (SELECT COUNT(*) FROM actriz_actuacion a1
                      WHERE c.actriz = a1.actriz
                      GROUP BY ACTriz))
SELECT c.actor, p1.nombre nombre_Actor, p1.pais_Nac nac_Actor, c.actriz, p2.nombre nActriz, p2.pais_Nac nac_Actriz, part "colaboraciones juntos"
FROM colab_const c 
     JOIN personal p1 ON(c.actor=p1.id_Personal)
     JOIN personal p2 ON(c.actriz =p2.id_Personal)
ORDER BY part DESC;
*/

-- Consulta con mejoras de rendimiento
WITH
    -- Actuaciones de actores
    actor_actuacion AS(
        SELECT id_Personal actor, pais_Nac nac_Actor, id_Obra
        FROM  actuarEn NATURAL JOIN personal NATURAL JOIN obras_val
        WHERE genero = 'm' AND pais_Nac IS NOT NULL),
    -- Actuaciones de actrices
    actriz_actuacion AS(
        SELECT id_Personal actriz, pais_Nac nac_Actriz, id_Obra
        FROM actuarEn NATURAL JOIN personal NATURAL JOIN obras_val
        WHERE genero = 'f' AND pais_Nac IS NOT NULL),
    -- parejas constantes entre actor-actriz
    parejas_constantes AS(
        SELECT actor, actriz, COUNT(*) part
        FROM actriz_actuacion cf NATURAL JOIN actor_actuacion cm
        WHERE nac_actor <> nac_actriz
        GROUP BY actor, actriz
        HAVING COUNT(*) = (SELECT COUNT(*) FROM actor_actuacion a1
                           WHERE cm.actor = a1.actor)
               AND
               COUNT(*) = (SELECT COUNT(*) FROM actriz_actuacion a2
                           WHERE cf.actriz = a2.actriz
                           GROUP BY ACTriz)) 
SELECT c.actor, p1.nombre nombre_Actor, p1.pais_Nac nac_Actor, c.actriz, p2.nombre nActriz, p2.pais_Nac nac_Actriz, part "colaboraciones juntos"
FROM parejas_constantes c 
     JOIN personal p1 ON(c.actor=p1.id_Personal)
     JOIN personal p2 ON(c.actriz =p2.id_Personal)
ORDER BY part DESC;

