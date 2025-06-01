-- TRIGGER 1: comprobar que una serie no puede tener dos capítulos en la misma posición
CREATE OR REPLACE TRIGGER capitulos_Orden
AFTER INSERT OR UPDATE ON  capitulo
DECLARE
      caps_Repetidos NUMBER;
BEGIN
    -- Contar el número de pareja de capítulos distintos de una serie        
    -- con mismo número de capítulo y de temporada 
    SELECT COUNT(*) INTO caps_Repetidos
    FROM capitulo c1 
         JOIN capitulo c2 ON (c1.id_Serie=c2.id_Serie AND c1.id_Capitulo > c2.id_Capitulo)
    WHERE c1.numCap = c2.numCap AND c1.numTemp = c2.numTemp;
    -- Si existe más de una pareja mostrar error
    IF caps_Repetidos > 0 THEN
        raise_application_error(-20200, 'ERROR. Hay ' || caps_Repetidos || 
                                'parejas de capitulos con mismo numero
                                de capitulo y de temporada.');
    END IF;
END;
/

-- TRIGGER 2: mantener la consistencia de películas de la tabla relacionPeli
CREATE OR REPLACE TRIGGER relPeli
BEFORE INSERT OR UPDATE ON relacionPeli
FOR EACH ROW
DECLARE
      -- Variable para almacenar el número de obras (0-2) que no son películas
      ObraSerie NUMBER(1);  
BEGIN
    -- Contar número de obras de la relación que son películas
    SELECT COUNT(*) INTO ObraSerie
    FROM obraCinem
    WHERE (id_Obra = :NEW.id_Obra_Sujeto
           OR id_Obra = :NEW.id_Obra_Objeto)
           AND tipoDeObra = 'movie';
    -- Si alguna (o ambas) no son películas mostrar error
    IF ObraSerie < 2 THEN
        raise_application_error(-20200, 'La relacion ('||:NEW.id_Obra_Sujeto || ') y (' 
                                ||:NEW.id_Obra_Objeto||' - '|| ') no esta definida sobre peliculas.');
    END IF;
END;
/

-- TRIGGER 3: Restringir que una película tenga relación con otra anterior
CREATE OR REPLACE TRIGGER agno_Estreno_Rel_Pelis
BEFORE INSERT OR UPDATE ON relacionPeli
FOR EACH ROW
DECLARE
      -- Variable para almacenar el agno de estreno de la película sujeto
      agno_Peli_Sujeto NUMBER;
      -- Variable para almacenar el agno de estreno de la película objeto
      agno_Peli_Objeto NUMBER;
BEGIN
     -- Seleccionar agno de estreno de la película sujeto
     SELECT DISTINCT agno_Estreno INTO agno_Peli_Sujeto
     FROM obraCinem
     WHERE id_Obra = :NEW.id_Obra_Sujeto;
     -- Seleccionar agno de estreno de la película objeto
     SELECT DISTINCT agno_Estreno INTO agno_Peli_Objeto
     FROM obraCinem
     WHERE id_Obra = :NEW.id_Obra_Objeto;
     -- Mostrar error si la película sujeto se estreno con anterioridad
     IF agno_Peli_Sujeto < agno_Peli_Objeto THEN
         raise_application_error(-20210, 'La obra identificada por ' || :NEW.id_Obra_Sujeto || 
                                 ' no puede haberse estrenado con anterioridad a la obra 
                                 relacionada identificada por ' || :NEW.id_Obra_Objeto);
     END IF;
END;
/

