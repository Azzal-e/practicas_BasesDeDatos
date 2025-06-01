-- DISEÑO FÍSICO

/* No se pueden implementar por cuota de espacio
CREATE BITMAP INDEX obra_act ON actuarEn(ObraCinem.agno_Estreno)
FROM obraCinem, actuarEn
WHERE obraCinem.id_Obra = actuarEn.id_Obra;

CREATE BITMAP INDEX obra_act ON participarEn(ObraCinem.agno_Estreno)
FROM obraCinem, actuarEn
WHERE obraCinem.id_Obra = participarEn.id_Obra;
*/  
CREATE MATERIALIZED VIEW ult_act_dir AS
WITH 
    -- personal que ha trabajado como director
    director AS(
        SELECT DISTINCT id_Personal
        FROM rol  NATURAL JOIN obraCinem
        WHERE rol = 'director' AND tipoDeObra= 'movie')
SELECT id_Personal, MAX(agno_Estreno) agno_Act
FROM director NATURAL JOIN actuarEn NATURAL JOIN obraCinem
WHERE tipoDeObra = 'movie'
GROUP BY id_Personal;

-- NO CREO QUE TENGA SENTIDO CREATE INDEX agno_Estreno_idx ON obraCinem(agno_Estreno);
CREATE INDEX Personal_participar_idx ON participarEn(id_Personal);

-- Índice sobre el tipo de relaciones entre películas
CREATE INDEX tipoRel_idx ON relacionPeli(tipoRel);
-- Índice sobre id de películas objeto de relación
CREATE INDEX idPeliObjeto_idx ON relacionPeli(id_Obra_Objeto);

-- Vísta materializada para tamaño de series de películas a partir de una dada
CREATE MATERIALIZED VIEW serie_tam AS
    SELECT id_Obra_Objeto, (COUNT(*)+1) totalSaga
    FROM relacionPeli
    WHERE tipoRel = 'secuela' OR tipoRel = 'precuela'
    GROUP BY id_Obra_Objeto;
    
-- índice BITMAP para indexar la columna de género del personal
CREATE BITMAP INDEX generoPersonal_idx ON personal(genero);

-- Vista materializada con las obras válidas para la consulta 3
CREATE MATERIALIZED VIEW obras_val AS
        SELECT id_Obra
        FROM obraCinem
        WHERE agno_Estreno >= 1980 AND agno_Estreno <= 2010
              AND tipoDeObra='movie';