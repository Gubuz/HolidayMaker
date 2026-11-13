# HolidayMaker

Konsolapp i C# (.NET 10) och MySQL 8 för att boka rum under december 2026.

## Kom igång
1. Starta MySQL (hoppa över om du redan har det):
   ```
   docker run -d --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=mysql123 mysql:8
   ```
2. Kör `sql/01_skapa_databas.sql` i DataGrip eller MySQL Workbench. Skriptet skapar databasen med testdata.
3. Starta appen:
   ```
   dotnet run
   ```

Anslutningssträngen finns högst upp i `Program.cs`. Ändra den om du har en annan användare eller ett annat lösenord.

## Tester
`sql/02_fragor_och_test.sql` innehåller appens SQL-frågor och testfallen T1–T8.

## Databas
Fyra tabeller: `Boende`, `Rum`, `Kund` och `Bokning`.
- Totalpriset räknas fram som antal nätter × pris per natt och lagras inte.
- Databasen kontrollerar giltiga värden med `CHECK`, `UNIQUE` och främmande nycklar.
- Att rummet är ledigt och rymmer alla personer kontrolleras när bokningen sparas.
