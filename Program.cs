using MySqlConnector;

var conn = new MySqlConnection("Server=localhost;Database=HolidayMaker;User ID=root;Password=mysql123;");
conn.Open();
int kundId = 0;

while (true)
{
    Console.WriteLine();
    Console.WriteLine(kundId == 0 ? "Ingen kund vald" : $"Vald kund: {kundId}");
    Console.WriteLine("1. Registrera kund");
    Console.WriteLine("2. Välj kund");
    Console.WriteLine("3. Sök och boka rum");
    Console.WriteLine("4. Visa mina bokningar");
    Console.WriteLine("5. Ändra antal personer");
    Console.WriteLine("6. Avboka");
    Console.WriteLine("7. Avsluta");
    Console.Write("Välj: ");

    if (!int.TryParse(Console.ReadLine(), out int choice))
    {
        Console.WriteLine("Skriv en siffra mellan 1 och 7.");
        continue;
    }

    if (choice >= 3 && choice <= 6 && kundId == 0)
    {
        Console.WriteLine("Registrera eller välj en kund först.");
        continue;
    }

    try
    {
        if (choice == 1) RegistreraKund();
        else if (choice == 2) ValjKund();
        else if (choice == 3) SokOchBoka();
        else if (choice == 4) VisaBokningar();
        else if (choice == 5) AndraAntal();
        else if (choice == 6) Avboka();
        else if (choice == 7) break;
    }
    catch (MySqlException ex)
    {
        Console.WriteLine("Databasfel: " + ex.Message);
    }
}

void RegistreraKund()
{
    var cmd = new MySqlCommand("INSERT INTO Kund (Namn, Epost, Telefon) VALUES (@namn, @epost, @telefon)", conn);
    cmd.Parameters.AddWithValue("@namn", Fraga("Namn"));
    cmd.Parameters.AddWithValue("@epost", Fraga("E-post"));
    cmd.Parameters.AddWithValue("@telefon", Fraga("Telefon"));
    cmd.ExecuteNonQuery();
    kundId = (int)cmd.LastInsertedId;
    Console.WriteLine($"Kund {kundId} registrerad och vald.");
}

void ValjKund()
{
    var cmd = new MySqlCommand("SELECT Id, Namn, Epost FROM Kund WHERE Namn LIKE @sok OR Epost LIKE @sok ORDER BY Namn", conn);
    cmd.Parameters.AddWithValue("@sok", "%" + Fraga("Sök namn/e-post (Enter = alla)") + "%");

    var idn = new List<int>();
    using (var r = cmd.ExecuteReader())
    {
        while (r.Read())
        {
            idn.Add(r.GetInt32("Id"));
            Console.WriteLine($"{r["Id"]}. {r["Namn"]} ({r["Epost"]})");
        }
    }

    int id = FragaTal("Kundens id");
    if (idn.Contains(id)) kundId = id;
    else Console.WriteLine("Finns inte i listan.");
}

void SokOchBoka()
{
    string ort = Fraga("Ort");
    DateTime incheckning = FragaDatum("Incheckning (åååå-mm-dd)");
    DateTime utcheckning = FragaDatum("Utcheckning (åååå-mm-dd)");
    int antal = FragaTal("Antal personer");

    if (utcheckning <= incheckning || incheckning < new DateTime(2026, 12, 1) || utcheckning > new DateTime(2027, 1, 1))
    {
        Console.WriteLine("Ogiltiga datum. Bokning går 2026-12-01 – 2027-01-01.");
        return;
    }

    var cmd = new MySqlCommand("""
        SELECT r.Id, b.Namn, b.Ort, r.Rumsnummer, r.Kapacitet, r.PrisPerNatt, b.Omdome
        FROM Rum r JOIN Boende b ON b.Id = r.BoendeId
        WHERE b.Ort = @ort
          AND r.Kapacitet >= @antal
          AND (@pool = FALSE OR b.Pool = TRUE)
          AND (@restaurang = FALSE OR b.Restaurang = TRUE)
          AND (@maxStrand IS NULL OR b.AvstandStrand <= @maxStrand)
          AND (@maxCentrum IS NULL OR b.AvstandCentrum <= @maxCentrum)
          AND NOT EXISTS (SELECT 1 FROM Bokning bo WHERE bo.RumId = r.Id
                          AND bo.Incheckning < @ut AND bo.Utcheckning > @in)
        ORDER BY CASE WHEN @omdome THEN b.Omdome END DESC, r.PrisPerNatt
        """, conn);
    cmd.Parameters.AddWithValue("@ort", ort);
    cmd.Parameters.AddWithValue("@in", incheckning);
    cmd.Parameters.AddWithValue("@ut", utcheckning);
    cmd.Parameters.AddWithValue("@antal", antal);
    cmd.Parameters.AddWithValue("@pool", Fraga("Pool? (j/n)") == "j");
    cmd.Parameters.AddWithValue("@restaurang", Fraga("Restaurang? (j/n)") == "j");
    cmd.Parameters.AddWithValue("@maxStrand", int.TryParse(Fraga("Max meter till strand (Enter = valfritt)"), out int s) ? s : DBNull.Value);
    cmd.Parameters.AddWithValue("@maxCentrum", int.TryParse(Fraga("Max meter till centrum (Enter = valfritt)"), out int c) ? c : DBNull.Value);
    cmd.Parameters.AddWithValue("@omdome", Fraga("Sortera 1 = pris, 2 = omdöme") == "2");

    var priser = new Dictionary<int, decimal>();   // rum-id -> pris per natt
    using (var r = cmd.ExecuteReader())
    {
        while (r.Read())
        {
            priser[r.GetInt32("Id")] = r.GetDecimal("PrisPerNatt");
            Console.WriteLine($"Rum-id {r["Id"]}: {r["Namn"]}, {r["Ort"]}, rum {r["Rumsnummer"]}, {r["Kapacitet"]} pers, {r.GetDecimal("PrisPerNatt"):0} kr/natt, omdöme {r["Omdome"]}");
        }
    }

    int rumId = FragaTal("Rum-id att boka (0 = tillbaka)");
    if (rumId == 0) return;
    if (!priser.ContainsKey(rumId))
    {
        Console.WriteLine("Välj ett rum från listan.");
        return;
    }

    var boka = new MySqlCommand("""
        INSERT INTO Bokning (KundId, RumId, Incheckning, Utcheckning, AntalPersoner)
        SELECT @kund, r.Id, @in, @ut, @antal
        FROM Rum r
        WHERE r.Id = @rum
          AND r.Kapacitet >= @antal
          AND NOT EXISTS (SELECT 1 FROM Bokning bo WHERE bo.RumId = r.Id
                          AND bo.Incheckning < @ut AND bo.Utcheckning > @in)
        """, conn);
    boka.Parameters.AddWithValue("@kund", kundId);
    boka.Parameters.AddWithValue("@rum", rumId);
    boka.Parameters.AddWithValue("@in", incheckning);
    boka.Parameters.AddWithValue("@ut", utcheckning);
    boka.Parameters.AddWithValue("@antal", antal);

    if (boka.ExecuteNonQuery() == 0) Console.WriteLine("Rummet kunde inte bokas.");
    else
    {
        int natter = (utcheckning - incheckning).Days;
        Console.WriteLine($"Bokat! Bokningsnummer: {boka.LastInsertedId}, totalpris: {natter} nätter × {priser[rumId]:0} kr = {natter * priser[rumId]:0} kr");
    }
}

void VisaBokningar()
{
    var cmd = new MySqlCommand("""
        SELECT bo.Id, b.Namn, r.Rumsnummer, bo.Incheckning, bo.Utcheckning, bo.AntalPersoner,
               DATEDIFF(bo.Utcheckning, bo.Incheckning) * r.PrisPerNatt AS Totalpris
        FROM Bokning bo
        JOIN Rum r ON r.Id = bo.RumId
        JOIN Boende b ON b.Id = r.BoendeId
        WHERE bo.KundId = @kund
        ORDER BY bo.Incheckning
        """, conn);
    cmd.Parameters.AddWithValue("@kund", kundId);

    using var r = cmd.ExecuteReader();
    while (r.Read())
        Console.WriteLine($"Bokning {r["Id"]}: {r["Namn"]} rum {r["Rumsnummer"]}, {r.GetDateTime("Incheckning"):yyyy-MM-dd} – {r.GetDateTime("Utcheckning"):yyyy-MM-dd}, {r["AntalPersoner"]} pers, {r.GetDecimal("Totalpris"):0} kr");
}

void AndraAntal()
{
    VisaBokningar();
    var cmd = new MySqlCommand("""
        UPDATE Bokning bo JOIN Rum r ON r.Id = bo.RumId
        SET bo.AntalPersoner = @antal
        WHERE bo.Id = @bokning AND bo.KundId = @kund AND @antal BETWEEN 1 AND r.Kapacitet
        """, conn);
    cmd.Parameters.AddWithValue("@bokning", FragaTal("Bokningsnummer"));
    cmd.Parameters.AddWithValue("@antal", FragaTal("Nytt antal personer"));
    cmd.Parameters.AddWithValue("@kund", kundId);

    Console.WriteLine(cmd.ExecuteNonQuery() > 0 ? "Ändrat." : "Gick inte (fel nummer eller för många personer).");
}

void Avboka()
{
    VisaBokningar();
    var cmd = new MySqlCommand("DELETE FROM Bokning WHERE Id = @bokning AND KundId = @kund", conn);
    cmd.Parameters.AddWithValue("@bokning", FragaTal("Bokningsnummer att avboka"));
    cmd.Parameters.AddWithValue("@kund", kundId);

    Console.WriteLine(cmd.ExecuteNonQuery() > 0 ? "Avbokad." : "Hittade ingen sådan bokning.");
}

string Fraga(string text)
{
    Console.Write(text + ": ");
    return Console.ReadLine() ?? "";
}

int FragaTal(string text)
{
    while (true)
    {
        if (int.TryParse(Fraga(text), out int tal)) return tal;
        Console.WriteLine("Skriv ett heltal.");
    }
}

DateTime FragaDatum(string text)
{
    while (true)
    {
        if (DateTime.TryParse(Fraga(text), out DateTime datum)) return datum;
        Console.WriteLine("Skriv datum som åååå-mm-dd.");
    }
}
