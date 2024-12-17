USE Chinook;

-- 1. Create a view help your colleagues see which countries have the most invoices

-- Solution 1 with CTE
DROP VIEW MostInvoicesCountries;

CREATE VIEW MostInvoicesCountries AS
WITH CountriesByMostInvoices AS(
	SELECT 
		BillingCountry AS Country, 
		COUNT(InvoiceId) AS TotalInvoices,
		DENSE_RANK() OVER(ORDER BY COUNT(InvoiceId) DESC) AS RankByTotalInvoices
	FROM invoice
	GROUP BY BillingCountry
)
SELECT *
FROM CountriesByMostInvoices
WHERE RankByTotalInvoices = 1;

SELECT *
FROM MostInvoicesCountries;


-- Solution 2
DROP VIEW MostInvoicesCountries;
CREATE VIEW MostInvoicesCountries AS
	SELECT 
		BillingCountry AS Country, 
		COUNT(InvoiceId) AS TotalInvoices,
		DENSE_RANK() OVER(ORDER BY COUNT(InvoiceId) DESC) AS RankByTotalInvoices
	FROM invoice
	GROUP BY BillingCountry;

SELECT *
FROM MostInvoicesCountries;
-- WHERE RankByTotalInvoices = 3;


-- 2. Create a view help your colleagues see which cities have the most valuable customer base
DROP VIEW CitiesWithMostCustomer;

CREATE VIEW CitiesWithMostCustomer AS
SELECT 
	City, 
    Country, 
    SUM(Total) AS TotalSpending,
    DENSE_RANK() OVER(PARTITION BY Country ORDER BY SUM(Total) DESC) AS TopCustomerBySpending
FROM customer
JOIN invoice USING(CustomerId)
GROUP BY City, Country;

SELECT *
FROM CitiesWithMostCustomer
ORDER BY TotalSpending DESC;

-- 3. Create a view to identify the top spending customer in each country. Order the results from highest spent to lowest.
DROP VIEW CustomerBySpending;

CREATE VIEW CustomerBySpending AS
SELECT 
	CustomerId, 
    CONCAT(FirstName, " " , LastName) AS CustomerName, 
    Country, 
    SUM(Total) AS TotalSpending,
    DENSE_RANK() OVER(PARTITION BY Country ORDER BY SUM(Total) DESC) AS TopCustomerBySpending
FROM customer
JOIN invoice USING(CustomerId)
GROUP BY CustomerId;

SELECT *
FROM CustomerBySpending 
WHERE TopCustomerBySpending = 1
ORDER BY TotalSpending DESC;


-- 4. Create a view to show the top 5 selling artists of the top selling genre
-- If there are multiple genres that all sell well, give the top 5 of all top selling genres collectively
DROP VIEW TopRankArtistGenre;

CREATE VIEW TopRankArtistGenre AS
WITH RankedGenres AS (
	SELECT
        g.Name AS Genre,
        SUM(il.Quantity * t.UnitPrice) AS TotalSales,
        RANK() OVER (ORDER BY SUM(il.Quantity * t.UnitPrice) DESC) AS GenreRank
    FROM
        genre g
		JOIN track t USING (GenreId)
		JOIN invoiceline il USING (TrackId)
    GROUP BY g.GenreId
    ),
    RankedTracksOfTopGenre AS(
	SELECT 
		g.Name AS GenreName,
		a.Name AS ArtistName,
		SUM(t.UnitPrice * il.Quantity) AS TotalSales,
		RANK() OVER(ORDER BY SUM(t.UnitPrice * il.Quantity) DESC, g.Name DESC) AS RankByTotalSales
	FROM artist AS a
	JOIN album USING(ArtistId)
	JOIN track AS t USING(AlbumId)
	JOIN invoiceline AS il USING(TrackId)
	JOIN genre AS g USING(GenreId)
    WHERE g.Name = ( SELECT Genre
						FROM RankedGenres
                        WHERE GenreRank = 1 )
	GROUP BY g.Name, a.Name
    )
    SELECT *
    FROM RankedTracksOfTopGenre
    WHERE RankByTotalSales < 6;

SELECT *
FROM TopRankArtistGenre;


-- 5. Create a stored procedure that, when provided with an InvoiceId, 
-- retrieves all orders and corresponding order items acquired by the customer who placed the specified order
DROP PROCEDURE CustomerOrdersByInvoiceId;

DELIMITER $$

CREATE PROCEDURE CustomerOrdersByInvoiceId(IN InputInvoiceId INT)

BEGIN
	SELECT 
		CustomerId, 
        CONCAT(FirstName, " ", LastName) AS CustomerName, 
        InvoiceLineId,
        InvoiceId,
        TrackId, 
        Quantity
	FROM customer
	JOIN invoice USING(CustomerId)
	JOIN invoiceline USING(InvoiceId)
    WHERE CustomerId = (SELECT CustomerId
						FROM invoice
                        WHERE InvoiceId = InputInvoiceId);
END $$

DELIMITER ;

CALL CustomerOrdersByInvoiceId(98);

-- 6. Create a stored procedure to retrieve sales data from a given date range

DROP PROCEDURE SalesByDateRange;
DELIMITER $$

CREATE PROCEDURE SalesByDateRange(IN MinDate DATETIME, IN MaxDate DATETIME)

BEGIN
	SELECT InvoiceId, SUM(il.UnitPrice * il.Quantity) AS TotalSales
	FROM invoice
	JOIN invoiceline  AS il USING(InvoiceId)
	WHERE InvoiceDate BETWEEN MinDate AND MaxDate
	GROUP BY InvoiceId;
END $$

DELIMITER ;
CALL SalesByDateRange('2022-01-01', '2022-01-31');


-- 7. Create a stored procedure to calculate the average invoice amount for a given country
DROP PROCEDURE AvgSpendingByCountry;
DELIMITER $$

CREATE PROCEDURE AvgSpendingByCountry(IN InputCountry VARCHAR(40))

BEGIN
	SELECT BillingCountry, AVG(Total) AS AvgAmount
	FROM invoice
	WHERE BillingCountry = InputCountry
    GROUP BY BillingCountry;
END $$

DELIMITER ;

CALL AvgSpendingByCountry('Germany');

-- 7. Create a stored function to calculate the average invoice amount for a given country
DROP FUNCTION AvgSpendingByCountryFUNC;

DELIMITER $$

CREATE FUNCTION AvgSpendingByCountryFUNC(InputCountry VARCHAR(40))
RETURNS DECIMAL(10, 2) -- The number has up to 10 digits in total, with 2 digits reserved for fractional values e.g. 123456.34

NOT DETERMINISTIC 
READS SQL DATA

BEGIN
	DECLARE AvgAmount DECIMAL(10, 2);
    
	SELECT AVG(Total) INTO AvgAmount
	FROM invoice
	WHERE BillingCountry = InputCountry;
    
    RETURN AvgAmount;
END $$

DELIMITER ;

SELECT AvgSpendingByCountryFUNC('USA') AS AvgSpendingByCountry;

-- 8. Create a stored function that returns the best-selling artist in a specified genre

DELIMITER $$

CREATE FUNCTION BestSellingArtist(GenreName VARCHAR(120))
RETURNS VARCHAR(255)

NOT DETERMINISTIC
READS SQL DATA

BEGIN

	DECLARE TopArtist VARCHAR(255);
    
		WITH RankGenreArtist AS(
			SELECT 
				a.Name AS ArtistName,
				COUNT(il.TrackId) AS TotalTrack,
				DENSE_RANK() OVER(ORDER BY COUNT(il.TrackId) DESC) AS RankByTotalTrack
			FROM artist AS a
			JOIN album USING(ArtistId)
			JOIN track USING(AlbumId)
			JOIN invoiceline as il USING(TrackId)
			JOIN genre AS g USING(GenreId)
			WHERE g.Name = GenreName
			GROUP BY a.ArtistId
		)
		SELECT 
			ArtistName INTO TopArtist
		FROM RankGenreArtist
		WHERE RankByTotalTrack = 1;
   
	RETURN TopArtist;

END $$

DELIMITER ;

SELECT BestSellingArtist("Alternative") AS TopSellingArtist;

-- 9. Create a stored function to calculate the total amount that customer spent with the company
DELIMITER $$

CREATE FUNCTION AmountpendByCustomer(InputCustomerId INT)
RETURNS DECIMAL(10, 2)

NOT DETERMINISTIC
READS SQL DATA

BEGIN
	DECLARE TotalSpending DECIMAL(10, 2);
    
	SELECT SUM(Total) INTO TotalSpending
	FROM customer
	JOIN invoice USING(CustomerId)
    WHERE CustomerId = InputCustomerId;
    
    RETURN TotalSpending;
END $$

DELIMITER ;

SELECT AmountpendByCustomer(1) AS TotalAmountpend; 

-- 10. Create a stored function to find the average song length for an album
DELIMITER $$

CREATE FUNCTION AvgSongLength(InputAlbumId INT)
RETURNS DECIMAL(10, 2)

NOT DETERMINISTIC
READS SQL DATA

BEGIN
	DECLARE AvgSongLength DECIMAL(10, 2);
	
    SELECT AVG(Milliseconds) INTO AvgSongLength
	FROM track
	JOIN album USING(AlbumId)
	WHERE AlbumId = InputAlbumId;
    
    RETURN AvgSongLength;
    
END $$
DELIMITER ;

SELECT AvgSongLength(1) AS AvgAlbumLength;


-- 11. Create a stored function to return the most popular genre for a given country
DELIMITER $$

CREATE FUNCTION CountryByPopularGenre(CountryName VARCHAR(255))
RETURNS VARCHAR(120)

NOT DETERMINISTIC
READS SQL DATA

BEGIN
	DECLARE TopGenreName VARCHAR(120);
    
	WITH CountryByGenre AS(
		SELECT 
			g.Name AS GenreName,
			COUNT(TrackId),
			RANK() OVER(ORDER BY COUNT(TrackId) DESC) AS RankByTotalTrack
		FROM invoice
		JOIN invoiceline USING(InvoiceId)
		JOIN track USING(TrackId)
		JOIN genre AS g USING(GenreId)
        WHERE BillingCountry = CountryName
		GROUP BY GenreId
		)
		SELECT GenreName INTO TopGenreName
		FROM CountryByGenre
		WHERE RankByTotalTrack = 1;
	RETURN TopGenreName;
END $$

DELIMITER ; 

SELECT CountryByPopularGenre("India") AS TopGenre;