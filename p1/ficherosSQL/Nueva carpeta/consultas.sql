/* --- Consulta 1. --- */
WITH 
   -- Puntos ganados como local por equipo por temporada de primera
   puntosLocalTemp AS
     (SELECT nombLocal AS equipo, tempPart AS temporada, SUM(puntosLocal) AS puntosLocalTot 
      FROM PARTIDO 
      WHERE divPart = '1'  
      GROUP BY nombLocal, tempPart),
   -- Puntos ganados como visitante por equipo por temporada de primera 
   puntosVisitTemp AS
     (SELECT nombVisit AS equipo, tempPart AS temporada, SUM(puntosVisit) AS puntosVisitTot 
      FROM PARTIDO  
      WHERE divPart = '1'  
      GROUP BY nombVisit, tempPart), 
   -- Puntos totales ganados por equipo por temporada de primera
   puntosEquipoTemp AS
     (SELECT equipo, temporada, (puntosLocalTot + puntosVisitTot) AS puntosTemp 
      FROM puntosLocalTemp NATURAL JOIN puntosVisitTemp),   
   -- Ligas de primera división ganadas por equipo
   eqTempGanadas AS
     (SELECT equipo, COUNT(temporada) tempGanadas 
      FROM PuntosEquipoTemp PT 
      WHERE PT.puntosTemp = (SELECT MAX(puntosTemp) FROM PuntosEquipoTemp
                             WHERE temporada = PT.temporada)
      GROUP BY equipo)
-- Equipo con más ligas de primera ganadas
SELECT equipo "Equipo/s con mas ligas de primera ganadas" 
FROM eqTempGanadas 
WHERE tempGanadas = (SELECT MAX(tempGanadas) FROM eqTempGanadas);

/* --- Consulta2. --- */
WITH 
    -- Composición de cada división para las últimas 10 temporadas
    compUltsTemps AS
     (SELECT DISTINCT nombLocal, divPart, tempPart 
      FROM Partido 
      WHERE tempPart + 10 > (SELECT DISTINCT MAX(tempPart) FROM Partido))
SELECT DISTINCT T1.nombLocal "Equipo/s ascendente-descendentes" 
FROM  compUltsTemps T1 
      JOIN compUltsTemps T2 ON T1.nombLocal = T2.nombLocal
      JOIN compUltsTemps T3 ON T2.nombLocal = T3.nombLocal 
WHERE T1.divPart = '2' AND T2.divPart = '1' AND T3.divPart = '2' 
      AND T2.tempPart = T1.tempPart + 1 AND T3.tempPart = T2.tempPart + 1;
      
/* --- Consulta 3. ---*/
WITH 
    --- Goles totales por jornada de una temporada y división
    golesJornada AS
      (SELECT SUM(golesLocal + golesVisit) AS golesJor, jorPart, tempPart, divPart 
       FROM Partido 
       WHERE (tempPart + 5) > (SELECT DISTINCT MAX(tempPart) FROM Partido)
       GROUP BY jorPart, tempPart, divPart)
SELECT tempPart "Temporada", divPart "Division", jorPart "Jornada Maxima"
FROM golesJornada GJ
WHERE golesJor = (SELECT MAX(golesJor) 
                  FROM golesJornada 
                  WHERE tempPart = GJ.tempPart AND divPart = GJ.divPart)
ORDER BY tempPart Desc, divPart DESC;    