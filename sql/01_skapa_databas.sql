
DROP DATABASE IF EXISTS HolidayMaker;

CREATE DATABASE IF NOT EXISTS HolidayMaker
    CHARACTER SET utf8mb4;

USE HolidayMaker;

CREATE TABLE Boende (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    Namn VARCHAR(100) NOT NULL,
    Ort VARCHAR(100) NOT NULL,
    Pool BOOLEAN NOT NULL,
    Restaurang BOOLEAN NOT NULL,
    AvstandStrand INT NOT NULL,
    AvstandCentrum INT NOT NULL,
    Omdome DECIMAL(3, 2) NOT NULL,

    CHECK (Pool IN (0, 1)),
    CHECK (Restaurang IN (0, 1)),
    CHECK (AvstandStrand >= 0),
    CHECK (AvstandCentrum >= 0),
    CHECK (Omdome BETWEEN 1 AND 5)
) ENGINE = InnoDB;

CREATE TABLE Rum (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    BoendeId INT NOT NULL,
    Rumsnummer VARCHAR(20) NOT NULL,
    Kapacitet INT NOT NULL,
    PrisPerNatt DECIMAL(10, 2) NOT NULL,

    FOREIGN KEY (BoendeId) REFERENCES Boende(Id),
    UNIQUE (BoendeId, Rumsnummer),

    CHECK (Kapacitet > 0),
    CHECK (PrisPerNatt > 0)
) ENGINE = InnoDB;

CREATE TABLE Kund (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    Namn VARCHAR(100) NOT NULL,
    Epost VARCHAR(254) NOT NULL UNIQUE,
    Telefon VARCHAR(30) NOT NULL
) ENGINE = InnoDB;

-
CREATE TABLE Bokning (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    KundId INT NOT NULL,
    RumId INT NOT NULL,
    Incheckning DATE NOT NULL,
    Utcheckning DATE NOT NULL,
    AntalPersoner INT NOT NULL,

    FOREIGN KEY (KundId) REFERENCES Kund(Id),
    FOREIGN KEY (RumId) REFERENCES Rum(Id),

    CHECK (AntalPersoner > 0),
    CHECK (Utcheckning > Incheckning),
    CHECK (
        Incheckning >= '2026-12-01'
        AND Utcheckning <= '2027-01-01'
    ),

    INDEX ix_bokning_rum_datum (RumId, Incheckning, Utcheckning)
) ENGINE = InnoDB;



INSERT INTO Boende (Namn, Ort, Pool, Restaurang, AvstandStrand, AvstandCentrum, Omdome)
VALUES ('Hotell Strandporten',   'Visby',  TRUE,  TRUE,   150,  600, 4.50),  
       ('Pensionat Rosengården', 'Visby',  FALSE, FALSE,  900,  200, 3.80),  
       ('Havsbadet Resort',      'Båstad', TRUE,  TRUE,    50, 2500, 4.80),  
       ('Båstad Vandrarhem',     'Båstad', FALSE, FALSE, 1200,  300, 2.90),  
       ('Kalmarsund Hotell',     'Kalmar', FALSE, TRUE,   400,  100, 4.10),  
       ('Lilla Sjöboden',        'Kalmar', FALSE, FALSE,   20, 1800, 3.50);  


INSERT INTO Rum (BoendeId, Rumsnummer, Kapacitet, PrisPerNatt)
VALUES (1, '101', 2, 1250.00),   
       (1, '102', 2, 1250.00),   
       (1, '103', 4, 1950.00),   
       (1, '201', 1,  850.00),   
       (1, '202', 3, 1600.00),   

       (2, '1', 2,  790.00),     
       (2, '2', 2,  790.00),     
       (2, '3', 4, 1290.00),     

       (3, '11', 2, 1890.00),    
       (3, '12', 4, 2890.00),    
       (3, '13', 6, 3990.00),    
       (3, '21', 2, 2090.00),    
       (3, '22', 3, 2490.00),    

       (4, 'A', 1,  450.00),     
       (4, 'B', 4,  890.00),     
       (4, 'C', 6, 1190.00),     

       (5, '301', 2, 1390.00),   
       (5, '302', 1,  990.00),   
       (5, '303', 4, 2190.00),   
       (5, '304', 3, 1790.00),   

       (6, 'Stuga 1', 2,  990.00),  
       (6, 'Stuga 2', 4, 1490.00); 


INSERT INTO Kund (Namn, Epost, Telefon)
VALUES ('Anna Lindqvist',   'anna.lindqvist@example.com',   '070-1234567'),  
       ('Johan Berg',       'johan.berg@example.com',       '073-2345678'),  
       ('Sara Ek',          'sara.ek@example.com',          '076-3456789'),  
       ('Mehmet Yilmaz',    'mehmet.yilmaz@example.com',    '072-4567890'),
       ('Lena Holm',        'lena.holm@example.com',        '070-5678901'), 
       ('Adnan Hadžić',     'adnan.hadzic@example.com',     '073-6789012'),  
       ('Emma Sjöström',    'emma.sjostrom@example.com',    '076-7890123'),  
       ('Oskar Nyström',    'oskar.nystrom@example.com',    '072-8901234');  


INSERT INTO Bokning (KundId, RumId, Incheckning, Utcheckning, AntalPersoner)
VALUES (1,  1, '2026-12-10', '2026-12-13', 2),   
       (2,  1, '2026-12-13', '2026-12-16', 2),   
       (3,  1, '2026-12-20', '2026-12-27', 2),  
       (4,  2, '2026-12-01', '2026-12-05', 1),   
       (5,  2, '2026-12-22', '2026-12-29', 2),   
       (6,  3, '2026-12-05', '2026-12-12', 4),   
       (7,  3, '2026-12-18', '2026-12-26', 3),  
       (8,  4, '2026-12-08', '2026-12-09', 1),   
       (1,  5, '2026-12-26', '2027-01-01', 3),  
       (2,  6, '2026-12-03', '2026-12-07', 2),   
       (3,  6, '2026-12-14', '2026-12-17', 1),   
       (4,  7, '2026-12-20', '2026-12-24', 2),   
       (5,  8, '2026-12-10', '2026-12-20', 4), 
       (6,  9, '2026-12-01', '2026-12-03', 2),   
       (7,  9, '2026-12-12', '2026-12-15', 2),   
       (8, 10, '2026-12-15', '2026-12-22', 4),   
       (1, 11, '2026-12-27', '2026-12-31', 6),   
       (2, 12, '2026-12-06', '2026-12-11', 2),   
       (3, 13, '2026-12-02', '2026-12-04', 3),   
       (4, 14, '2026-12-09', '2026-12-11', 1),  
       (5, 15, '2026-12-01', '2026-12-02', 3),   
       (6, 17, '2026-12-19', '2026-12-26', 2),   
       (7, 19, '2026-12-04', '2026-12-08', 4),   
       (8, 20, '2026-12-23', '2026-12-28', 2),   
       (1, 21, '2026-12-20', '2026-12-27', 2),  
       (2, 22, '2026-12-20', '2026-12-27', 4);   
