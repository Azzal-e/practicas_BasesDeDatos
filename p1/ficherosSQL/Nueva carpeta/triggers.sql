/* Creación de triggers*/
-- Trigger para calcular los puntos derivados 
CREATE OR REPLACE TRIGGER Puntos
BEFORE INSERT OR UPDATE ON Partido
FOR EACH ROW
BEGIN
    IF  :NEW.golesLocal > :NEW.golesVisit THEN
       :NEW.puntosLocal := 3;
       :NEW.puntosVisit := 0;
    ELSIF :NEW.golesLocal < :NEW.golesVisit THEN
       :NEW.puntosLocal := 0;
       :NEW.puntosVisit := 3;  
    ELSE
       :NEW.puntosLocal := 1;
       :NEW.puntosVisit := 1;
    END IF;
END;
/
-- Trigger para mantener restricción de que un equipo no puede jugar contra sí mismo
CREATE OR REPLACE TRIGGER reflexPartido
BEFORE INSERT OR UPDATE ON Partido
FOR EACH ROW
WHEN (NEW.nombLocal = NEW.nombVisit)
BEGIN
  raise_application_error(-20200, 'El equipo '|| :NEW.nombLocal||' no puede jugar contra sí mismo');
END;
/

-- Trigger para mantener la restricción de que los goles no pueden ser negativos
CREATE OR REPLACE TRIGGER golesNoNeg
BEFORE INSERT OR UPDATE ON Partido
FOR EACH ROW
BEGIN
IF  :NEW.golesLocal < 0 AND :NEW.golesVisit < 0 THEN
     raise_application_error(-20210, 'Ni los goles del equipo local ni del equipo visitante pueden ser         negativos');
ELSIF :NEW.golesLocal < 0 THEN
    raise_application_error(-20211, 'Los goles del equipo local no 
                          pueden ser negativos');
ELSIF :NEW.golesVisit < 0 THEN
       raise_application_error(-20212, 'Los goles del equipo visitante 
                          no pueden ser negativos');
       END IF;
END;
/

