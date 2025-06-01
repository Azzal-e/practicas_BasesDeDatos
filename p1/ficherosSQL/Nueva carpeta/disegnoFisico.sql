/*Diseño físico*/
-- CREATE BITMAP INDEX bitmap_divPart_idx on Partido(divPart);
CREATE INDEX IDX_TEMP_DIV ON Partido(tempPart, divPart);
CREATE INDEX IDX_NOMB_TEMP_DIV ON Partido(tempPart, divPart, nombLocal);