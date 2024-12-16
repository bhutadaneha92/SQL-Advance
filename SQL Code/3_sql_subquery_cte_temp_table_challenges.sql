USE chinook;

-- 1. What is the difference in minutes between the total length of 'Rock' tracks and 'Jazz' tracks?
-- Step 1
SELECT 
    GenreId, SUM(Milliseconds) / 60000 AS TotalMinutes
FROM
    track
GROUP BY GenreId;

-- Step 2 
WITH GenreTrackMinutes AS(
	SELECT GenreId, g.Name, SUM(Milliseconds)/ 60000 AS TotalMinutes
	FROM Genre AS g
	JOIN track AS t USING(GenreId)
	WHERE g.Name IN ("Rock", "Jazz")
	GROUP BY GenreId
)
SELECT MAX(TotalMinutes) - MIN(TotalMinutes) AS TrackLengthDiff
FROM GenreTrackMinutes;

-- Solution 2 with subqueries
SELECT 
    ((SELECT SUM(Milliseconds)
	FROM Track t
	JOIN Genre g ON t.GenreId = g.GenreId
	WHERE g.Name = 'Rock')
	- 
	(SELECT SUM(Milliseconds)
	FROM Track t
	JOIN Genre g ON t.GenreId = g.GenreId
	WHERE g.Name = 'Jazz'))
	/ 60000 AS LengthDifferenceMinutes;
-- ----------------------------------------------------------------------------------------------------------------------------------------------------

-- 2. How many tracks have a length greater than the average track length?
-- Step 1
SELECT *
FROM track;

-- Step 2
SELECT AVG(Milliseconds) AS AvgTrackLength
FROM track;

-- Step 3
SELECT COUNT(trackId) AS TotalTracks
FROM track
WHERE
    Milliseconds > (SELECT 
            AVG(Milliseconds) AS AvgTrackLength
        FROM
            track);
-- ----------------------------------------------------------------------------------------------------------------------------------------------------

-- 3. What is the percentage of tracks sold per genre?
-- Step 1 Total count of track
SELECT COUNT(TrackId) AS TotalTrackId
FROM invoiceline AS il;

-- Step 2  Count of sold track per genre
SELECT g.GenreId, g.Name, COUNT(il.TrackId) AS SoldTrackPerGenre
FROM invoiceline AS il
JOIN track AS t USING(TrackId)
JOIN genre AS g USING(GenreId)
GROUP BY g.GenreId;

-- Step 3 Solution 1
CREATE TEMPORARY TABLE PercentTrackSold (
SELECT g.GenreId, g.Name AS GenreName, COUNT(il.TrackId) / (
	SELECT COUNT(TrackId)
	FROM invoiceline) * 100 AS PercentSold
FROM invoiceline AS il
JOIN track AS t USING(TrackId)
JOIN genre AS g USING(GenreId)
GROUP BY g.GenreId, g.Name
);
-- ----------------------------------------------------------------------------------------------------------------------------------------------------

-- 4. Can you check that the column of percentages adds up to 100%?
SELECT ROUND(SUM(PercentSold),2)
FROM PercentTrackSold;
-- ----------------------------------------------------------------------------------------------------------------------------------------------------

-- 5. What is the difference between the highest number of tracks in a genre and the lowest?
-- Solution 1 using CTE
WITH RangeOfTrack AS(
SELECT GenreId, COUNT(*) AS num_tracks
FROM track
GROUP BY GenreId
)
SELECT MAX(num_tracks) - MIN(num_tracks) AS DiffTrackByGenre
FROM RangeOfTrack;

-- Solution 2 using subqueries
SELECT MAX(NumTracks) - MIN(NumTracks) AS RangeOfTracksByGenre
FROM (
	  SELECT COUNT(*) AS NumTracks 
	  FROM Track
	  GROUP BY GenreId
) AS TrackCounts;
-- ----------------------------------------------------------------------------------------------------------------------------------------------------

-- 6. What is the average value of Chinook customers (total spending)?
-- Step 1 
SELECT CustomerId, SUM(Total) AS TotalSpend
FROM invoice
GROUP BY CustomerId;
-- Solution 1
SELECT SUM(Total) / COUNT(DISTINCT (CustomerId)) AS AvgSpending
FROM invoice;

-- using CTE
WITH TotalSpending AS(
SELECT CustomerId, SUM(Total) AS TotalSpend
FROM invoice
GROUP BY CustomerId
)
SELECT ROUND(AVG(TotalSpend), 2) AS AvgSpending
FROM TotalSpending;

-- Solution 2 using subquries
SELECT ROUND(AVG(TotalSpending), 2) AS AvgLifetimeSpend
FROM (
    SELECT c.CustomerId,
           SUM(i.Total) AS TotalSpending
    FROM Customer c
    JOIN Invoice i USING (CustomerId)
    GROUP BY c.CustomerId
) AS CustomerSpending;
-- ----------------------------------------------------------------------------------------------------------------------------------------------------

-- 7. How many complete albums were sold? Not just tracks from an album, but the whole album bought on one invoice.
-- Step 1
CREATE TEMPORARY TABLE TracksOnAlbum(
SELECT AlbumId, COUNT(DISTINCT(TrackId)) AS AlbumTrackCount
FROM track
GROUP BY AlbumId
);

CREATE TEMPORARY TABLE TracksOnInvoice (
SELECT il.InvoiceId, AlbumId, COUNT(DISTINCT(il.TrackId)) AS InvoiceTrackCount
FROM invoiceline AS il
JOIN track AS t USING(TrackId)
GROUP BY il.InvoiceId, AlbumId
);

SELECT COUNT(AlbumTrackCount) AS AlbumSOld
FROM TracksOnInvoice
	LEFT JOIN
		TracksOnAlbum USING (albumid)
WHERE InvoiceTrackCount = AlbumTrackCount;
-- ----------------------------------------------------------------------------------------------------------------------------------------------------

-- 8. What is the maximum spent by a customer in each genre?
-- step 1
WITH CustomerSpendingPerGenre AS (
SELECT g.GenreId, g.Name AS GenreName, CustomerId, SUM(il.UnitPrice * il.Quantity) AS TotalSpend
FROM customer AS c
JOIN invoice USING(CustomerId)
JOIN invoiceline AS il USING(invoiceId)
JOIN track USING(TrackId)
JOIN genre AS g USING(GenreId)
GROUP BY g.GenreId, c.CustomerId
)
SELECT GenreId, GenreName, MAX(TotalSpend) AS MaxSpendPerGenre
FROM CustomerSpendingPerGenre
GROUP BY GenreId
ORDER BY MaxSpendPerGenre DESC;
-- ----------------------------------------------------------------------------------------------------------------------------------------------------	

-- 9. What percentage of customers who made a purchase in 2022 returned to make additional purchases in subsequent years?
-- Step 1
SELECT DISTINCT(CustomerId) 
FROM invoice
WHERE YEAR(InvoiceDate) = 2022;

-- Step 2 percentage of customers who made a purchase in 2022 
SELECT ROUND((COUNT(DISTINCT(CustomerId))/ COUNT(CustomerId)) * 100, 2) AS PercentCustomer2022
FROM invoice
WHERE YEAR(InvoiceDate) = 2022;

-- Step 3 returned to make additional purchases in subsequent years
WITH PastCustomers AS(
SELECT DISTINCT(CustomerId) 
FROM invoice
WHERE YEAR(InvoiceDate) = 2022
)
SELECT COUNT(DISTINCT(CustomerId)) * 100 / (SELECT COUNT(*)
													FROM PastCustomers)  AS PercentageReturning
FROM invoice
WHERE YEAR(InvoiceDate) > 2022 AND CustomerId IN (SELECT CustomerId
														FROM PastCustomers); 

-- ----------------------------------------------------------------------------------------------------------------------------------------------------

-- 10. Which genre is each employee most successful at selling? Most successful is greatest amount of tracks sold.
/*
1. Calculate total tracks sold per employee per genre
2. What is each employee most succeful at? (num of tracks sold)
3. Match the max to the corresponding genre for each employee
*/
DROP TEMPORARY TABLE AmountSoldPerEmployeePerGenre;

CREATE TEMPORARY TABLE AmountSoldPerEmployeePerGenre(
SELECT g.GenreId, g.Name AS GenreName, e.EmployeeId, CONCAT(e.FirstName, " ", e.LastName) AS EmployeeName, SUM(il.quantity) AS QuantitySoldInGenre
FROM employee AS e
JOIN customer AS c ON e.EmployeeId = c.SupportRepId
JOIN invoice USING(CustomerId)
JOIN invoiceline AS il USING(invoiceId)
JOIN track USING(TrackId)
JOIN genre AS g USING(GenreId)
GROUP BY e.EmployeeId, g.GenreId, g.Name
);

CREATE TEMPORARY TABLE MaxSoldPerEmployeePerGenre(
SELECT EmployeeId, EmployeeName, MAX(QuantitySoldInGenre) AS MaxSold
FROM AmountSoldPerEmployeePerGenre
Group BY EmployeeId, EmployeeName
);

SELECT a.EmployeeName, a.GenreName, m.MaxSold
FROM AmountSoldPerEmployeePerGenre AS a
JOIN MaxSoldPerEmployeePerGenre AS m USING(EmployeeId)
WHERE a.QuantitySoldInGenre = m.MaxSold;
-- ----------------------------------------------------------------------------------------------------------------------------------------------------

-- 11. How many customers made a second purchase the month after their first purchase?
-- Step 1 - FInd out 1st purchase
WITH FirstPurchaseTable AS(
SELECT CustomerId, MIN(DATE(InvoiceDate)) AS FirstPurchase
FROM invoice
GROUP BY CustomerId
),
-- Step 2- Find out 2nd Purchase
SecondPurcahseTable AS(
SELECT CustomerId, MIN(DATE(InvoiceDate)) AS SecondPurchase
FROM invoice
JOIN FirstPurchaseTable USING(CustomerId)
WHERE DATE(InvoiceDate) > (FirstPurchase)
GROUP BY CustomerId
),
MonthCount AS(
SELECT TIMESTAMPDIFF(MONTH, FirstPurchase, SecondPurchase) AS MonthDifference
FROM FirstPurchaseTable
JOIN SecondPurcahseTable USING(CustomerId)
)
SELECT COUNT(*) AS Num_Customer_Return
FROM MonthCount
WHERE MonthDifference = 1; 


