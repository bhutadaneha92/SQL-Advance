USE Chinook;


-- 1. Rank the customers by total sales
SELECT 
	i.CustomerId,
    CONCAT(FirstName, " ", LastName) AS FullName,
	SUM(i.Total) AS TotalSales, 
    RANK() OVER (ORDER BY SUM(i.Total) DESC) AS RankCustomer
FROM invoice AS i
JOIN Customer AS c USING(CustomerId)
GROUP BY i.CustomerId;

-- 2. Select only the top 10 ranked customer from the previous question
WITH RankedCustomer AS(
SELECT 
	i.CustomerId,
    CONCAT(FirstName, " ", LastName) AS FullName,
	SUM(i.Total) AS TotalSales, 
    RANK() OVER (ORDER BY SUM(i.Total) DESC) AS RankCustomer
FROM invoice AS i
JOIN Customer AS c USING(CustomerId)
GROUP BY i.CustomerId
)
SELECT *
FROM RankedCustomer
WHERE RankCustomer <= 10;


-- 3. Rank albums based on the total number of tracks sold.
WITH SoldTrackCount AS(
SELECT a.AlbumId, a.Title, SUM(Quantity) AS Track_Sold_Count
FROM album AS a
JOIN track USING(AlbumId)
JOIN invoiceline USING(TrackId)
GROUP BY AlbumId
)
SELECT 
	*,
    DENSE_RANK() OVER (ORDER BY Track_Sold_Count DESC) AS Rank_albums	
FROM SoldTrackCount;

-- 4. Do music preferences vary by country? What are the top 3 genres for each country?
DROP TEMPORARY TABLE CountryGenre;

CREATE TEMPORARY TABLE CountryGenre(
SELECT 
	Country, 
	GenreId, 
	g.Name AS GenreName, 
    Count(il.TrackId) AS Total_Track
FROM genre AS g
JOIN track  AS t USING(GenreId)
JOIN invoiceline AS il USING(TrackId)
JOIN invoice USING(InvoiceId)
JOIN Customer USING(CustomerId)
GROUP BY Country, GenreId, g.Name
);

WITH Top3Genre AS(
SELECT 
	*, 
    RANK() OVER (PARTITION BY Country ORDER BY Total_Track DESC) AS Rank_Genre -- Order in decreasing rank
FROM CountryGenre
)
SELECT
	*
FROM Top3Genre
WHERE Rank_Genre <= 3;

    
-- 5. In which countries is Blues the least popular genre?
SELECT *
FROM CountryGenre;
WITH LeastPopularBluesGenre AS(
SELECT 
	*, 
    RANK() OVER (PARTITION BY Country ORDER BY Total_Track ASC) AS Rank_Genre -- order in increasing rank
FROM CountryGenre
)
SELECT
	*
FROM LeastPopularBluesGenre
HAVING Rank_Genre <= 1 AND GenreName = "Blues";

-- 6. Has there been year on year growth? By how much have sales increased per year?
WITH YearSales AS(
SELECT 
	YEAR(InvoiceDate) AS OrderYear, 
	SUM(Total) AS CurrentYearSales,
    LAG(SUM(Total)) OVER (ORDER BY YEAR(InvoiceDate)) AS PreviousYearSales
FROM invoice
GROUP BY YEAR(InvoiceDate)
)
SELECT 
	*,
    CurrentYearSales - PreviousYearSales AS DifferenceSales
FROM YearSales;

    
-- 7. How do the sales vary month-to-month as a percentage? 
DROP TEMPORARY TABLE MonthlySales;

CREATE TEMPORARY TABLE MonthlySales AS(
WITH OrderMonthSales AS(
SELECT 
	YEAR(InvoiceDate) AS OrderYear,
    MONTH(InvoiceDate) AS OrderMonth, 
	SUM(Total) AS CurrentMonthSales,
    LAG(SUM(Total)) OVER (ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate)) AS PreviousMonthSales
FROM invoice
GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
)
SELECT 
	*,
    CurrentMonthSales - PreviousMonthSales AS DifferenceSales,
    ROUND(((CurrentMonthSales - PreviousMonthSales)/ PreviousMonthSales) * 100, 2) AS PercentageDifference
FROM OrderMonthSales
);

SELECT *
FROM MonthlySales; 

-- 8. What is the monthly sales growth, categorised by whether it was an increase or decrease compared to the previous month?
SELECT *,
CASE
	WHEN PercentageDifference > 0 THEN "Increase"
    WHEN PercentageDifference < 0 THEN "Decrease"
    ELSE "No Change"
END AS SalesEffect
FROM MonthlySales;

-- 9. How many months in the data showed an increase in sales compared to the previous month?
SELECT Count(OrderMonth) AS NumMonthsIncreaseSales
FROM MonthlySales
WHERE PercentageDifference > 0.00;

-- 10. As a percentage of all months in the dataset, how many months in the data showed an increase in sales compared to the previous month?
-- Solution1 using subqueries
SELECT 100 * SUM(CASE WHEN PercentageDifference > 0.00 THEN 1 ELSE 0 END) / COUNT(*) AS PercentOfMonthsWithIncrease
FROM MonthlySales;

-- Solution2 using CTE
WITH TotalCounts AS (
    SELECT COUNT(*) AS TotalCount,
           SUM(CASE WHEN PercentageDifference > 0 THEN 1 ELSE 0 END) AS PositiveCount
    FROM MonthlySales
)
SELECT 100 * (PositiveCount / TotalCount) AS PercentOfMonthsWithIncrease
FROM TotalCounts;

-- 11. How have purchases of rock music changed quarterly? Show the quarterly change in the amount of tracks sold

WITH TrackGenreInvoice AS(
SELECT 
	YEAR(InvoiceDate) AS OrderYear, 
    Quarter(InvoiceDate) AS OrderQuarter, 
    COUNT(il.TrackId) AS NumTrackSoldOverQuarter,
    LAG(COUNT(TrackId)) OVER (ORDER BY YEAR(InvoiceDate), Quarter(InvoiceDate)) AS NumTrackSoldOverPreviousQuarter
FROM genre AS g
JOIN track  AS t USING(GenreId)
JOIN invoiceline AS il USING(TrackId)
JOIN invoice USING(InvoiceId)
JOIN Customer USING(CustomerId)
WHERE g.Name = "Rock"
GROUP BY YEAR(InvoiceDate), Quarter(InvoiceDate)
)
SELECT 
	*,
    NumTrackSoldOverQuarter - NumTrackSoldOverPreviousQuarter AS Difference
FROM TrackGenreInvoice;


-- 12. Determine the average time between purchases for each customer.
WITH CustomerOrderDate AS(
SELECT 
	CustomerId, 
    CONCAT(FirstName,  " " , LastName) AS CustomerName, 
    InvoiceDate,
    LAG(InvoiceDate) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate) AS PreviousPurchaseDate
FROM customer
JOIN invoice USING(CustomerId)
)
SELECT 
	CustomerId, 
    CustomerName,
    ROUND(AVG(TIMESTAMPDIFF(DAY, PreviousPurchaseDate, InvoiceDate)), 2) AS DaysDifference
FROM CustomerOrderDate
GROUP BY CustomerId;
