

USE HolidayMaker;


SET @ort            = 'Visby';
SET @incheckning    = '2026-12-10';
SET @utcheckning    = '2026-12-13';
SET @antalPersoner  = 2;
SET @pool           = FALSE;     
SET @restaurang     = FALSE;     
SET @maxStrand      = NULL;      
SET @maxCentrum     = NULL;      
SET @sortering      = 'pris';    

SET @kundId    = 1;
SET @rumId     = 2;
SET @bokningId = 1;
SET @sok       = 'anna';
SET @namn      = 'Test Testsson';
SET @epost     = 'test.testsson@example.com';
SET @telefon   = '070-0000000';



INSERT INTO Kund (Namn, Epost, Telefon)
VALUES (@namn, @epost, @telefon);

SELECT LAST_INSERT_ID() AS NyttKundId;


SELECT Id, Namn, Epost, Telefon
FROM Kund
ORDER BY Namn;

SELECT Id, Namn, Epost, Telefon
FROM Kund
WHERE Namn LIKE CONCAT('%', @sok, '%')
   OR Epost LIKE CONCAT('%', @sok, '%')
ORDER BY Namn;



SELECT r.Id AS RumId,
       b.Namn AS Boende,
       b.Ort,
       r.Rumsnummer,
       r.Kapacitet,
       r.PrisPerNatt,
       b.Omdome
FROM Rum r
         JOIN Boende b ON b.Id = r.BoendeId
WHERE b.Ort = @ort
  AND r.Kapacitet >= @antalPersoner
  AND (@pool = FALSE OR b.Pool = TRUE)
  AND (@restaurang = FALSE OR b.Restaurang = TRUE)
  AND (@maxStrand IS NULL OR b.AvstandStrand <= @maxStrand)
  AND (@maxCentrum IS NULL OR b.AvstandCentrum <= @maxCentrum)
  AND NOT EXISTS (SELECT 1
                  FROM Bokning bo
                  WHERE bo.RumId = r.Id
                    AND bo.Incheckning < @utcheckning
                    AND bo.Utcheckning > @incheckning)
ORDER BY CASE WHEN @sortering = 'omdome' THEN b.Omdome END DESC,
         r.PrisPerNatt ASC;




INSERT INTO Bokning (KundId, RumId, Incheckning, Utcheckning, AntalPersoner)
SELECT @kundId, r.Id, @incheckning, @utcheckning, @antalPersoner
FROM Rum r
WHERE r.Id = @rumId
  AND r.Kapacitet >= @antalPersoner
  AND NOT EXISTS (SELECT 1
                  FROM Bokning bo
                  WHERE bo.RumId = r.Id
                    AND bo.Incheckning < @utcheckning
                    AND bo.Utcheckning > @incheckning);

SELECT ROW_COUNT() AS SparadeRader, LAST_INSERT_ID() AS NyttBokningsnummer;


SELECT bo.Id AS Bokningsnummer,
       b.Namn AS Boende,
       r.Rumsnummer,
       bo.Incheckning,
       bo.Utcheckning,
       DATEDIFF(bo.Utcheckning, bo.Incheckning)                 AS Natter,
       DATEDIFF(bo.Utcheckning, bo.Incheckning) * r.PrisPerNatt AS Totalpris
FROM Bokning bo
         JOIN Rum r ON r.Id = bo.RumId
         JOIN Boende b ON b.Id = r.BoendeId
WHERE bo.Id = @bokningId;



SELECT bo.Id AS Bokningsnummer,
       b.Namn AS Boende,
       r.Rumsnummer,
       bo.Incheckning,
       bo.Utcheckning,
       bo.AntalPersoner,
       DATEDIFF(bo.Utcheckning, bo.Incheckning) * r.PrisPerNatt AS Totalpris
FROM Bokning bo
         JOIN Rum r ON r.Id = bo.RumId
         JOIN Boende b ON b.Id = r.BoendeId
WHERE bo.KundId = @kundId
ORDER BY bo.Incheckning;



UPDATE Bokning bo
    JOIN Rum r ON r.Id = bo.RumId
SET bo.AntalPersoner = @antalPersoner
WHERE bo.Id = @bokningId
  AND bo.KundId = @kundId
  AND @antalPersoner <= r.Kapacitet;

SELECT ROW_COUNT() AS AndradeRader;



DELETE
FROM Bokning
WHERE Id = @bokningId
  AND KundId = @kundId;

SELECT ROW_COUNT() AS BorttagnaRader;


-