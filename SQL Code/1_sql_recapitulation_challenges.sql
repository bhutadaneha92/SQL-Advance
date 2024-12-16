USE Chinook;

-- 1. How many artists are in the database?		-- 275 artist
SELECT COUNT(ArtistId)
FROM artist;

-- 2. Create an alphabetised list of the artists.
SELECT * 
FROM artist
ORDER BY Name ASC;

-- 3. Show only the customers from Germany.
SELECT *
FROM customer
WHERE Country = "Germany";

-- 4. Get the full name, customer ID, and country of customers not in the US.
SELECT *
FROM customer;

SELECT CustomerId, CONCAT(FirstName, " ", LastName) AS FullName, Country
FROM customer
WHERE Country != "USA"
ORDER BY Country;

-- 5. Find the track with the longest duration.
SELECT *
FROM track;

SELECT MAX(Milliseconds) -- Solution1
FROM track;

SELECT * -- Solution2
FROM track
ORDER BY Milliseconds DESC
LIMIT 1;

-- 6. Which tracks have 'love' in their title?
SELECT DISTINCT(Name)
FROM track
WHERE Name LIKE "%Love%";

-- 7. What is the difference in days between the earliest and latest invoice?
SELECT DATEDIFF(MAX(InvoiceDate), MIN(InvoiceDate)) AS TotalDays -- Solution1
FROM invoice;

SELECT TIMESTAMPDIFF(DAY, MIN(InvoiceDate), MAX(InvoiceDate)) AS TotalDays -- Solution2
FROM invoice;
   
-- 8. Which genres have more than 100 tracks?
SELECT *
FROM genre;

SELECT GenreId, g.Name AS GenreName, COUNT(TrackId) AS TotalTrackCount  
FROM genre AS g
LEFT JOIN track As t USING(GenreId) -- Here Join genre table with track table
GROUP BY GenreId
HAVING TotalTrackCount > 100; 

SELECT 
    g.`name` AS Genre, COUNT(*) AS TrackCount
FROM
    track t
        JOIN
    genre g ON t.GenreId = g.GenreId
GROUP BY g.`name`
HAVING COUNT(*) > 100;

-- 9. Create a table showing countries alongside how many invoices there are per country.
SELECT BillingCountry, COUNT(InvoiceId) AS Number_of_Invoices
FROM invoice
GROUP BY BillingCountry
ORDER BY Number_of_Invoices DESC;

-- 10. Find the name of the employee who has served the most customers.
SELECT *
FROM employee;
SELECT *
FROM customer; 

-- After looking at both table EmployeeId is connected to SupportRepId. 
SELECT EmployeeId, e.LastName, e.FirstName, COUNT(CustomerId) AS Total_customers
FROM employee AS e
JOIN customer AS c
ON e.EmployeeId = c.SupportRepId
GROUP BY EmployeeId
ORDER BY Total_customers DESC
LIMIT 1;

-- 11. Which customers have a first name that starts with 'A' and is 5 letters long?
SELECT *
FROM customer
WHERE FirstName LIKE "A____";

-- 12. Find the total number of tracks in each playlist.
-- Solution1 
SELECT PlaylistId, p.Name, COUNT(TrackId) AS Total_tracks
FROM playlisttrack
LEFT JOIN playlist AS p USING(PlaylistId)
GROUP BY PlaylistId;

-- Solution2 
SELECT 
    p.`name`, 
    COUNT(*) AS TrackCount
FROM
    playlist p
        JOIN
    playlisttrack pt USING (playlistid)
GROUP BY playlistid;


-- 13. Find the artist that appears in the most playlists.
SELECT ArtistId, COUNT(DISTINCT(PlaylistId)) AS Total_Playlist, ar.Name AS ArtistName
FROM artist AS ar
JOIN album USING(ArtistId)
JOIN track AS t USING(AlbumId)
JOIN playlisttrack USING(TrackId)
GROUP BY ArtistId
ORDER BY Total_Playlist DESC
LIMIT 1;


-- 14. Find the genre with the most tracks.
SELECT GenreId, g.Name, COUNT(TrackId) As Total_Tracks
FROM genre AS g
LEFT JOIN track AS t USING(GenreId)
GROUP BY g.GenreId
ORDER BY Total_Tracks DESC
LIMIT 1;

-- 15. Which tracks have a composer whose name ends with 'Smith'?
SELECT *
FROM track
WHERE Composer LIKE  '%Smith';

-- 16. Which artists have albums in the 'Rock' or 'Blues' genres?
SELECT DISTINCT(ArtistId), ar.Name AS ArtistName, g.Name AS GenreName
FROM artist AS ar
JOIN album USING(ArtistId)
JOIN track USING(AlbumId)
JOIN genre AS g USING(GenreId)
WHERE g.Name IN ("Rock", "Blues");
-- GROUP BY ArtistId;
    
-- 17. Which tracks are in the 'Rock' or 'Blues' genre and have a name that is exactly 5 characters long?
SELECT *
FROM genre as g
JOIN track as t USING(GenreId)
WHERE g.Name IN ("Rock", "Blues") AND t.Name LIKE "_____";

-- 18. Classify customers as 'Local' if they are from Canada, 'Nearby' if they are from the USA, and 'International' otherwise.
SELECT *,
CASE
	WHEN Country = "Canada" THEN "Local"
    WHEN Country = "USA" THEN "Nearby"
    ELSE "International"
END AS Classify_customers
FROM customer;

-- 19. Find the total invoice amount for each customer.
SELECT CustomerId, CONCAT(FirstName, "", LastName) AS FullName, SUM(Total) AS InvoiceTotal 
FROM customer as c
JOIN invoice USING(CustomerId)
GROUP BY CustomerId;

-- 20. Find the customer who has spent the most on music.
SELECT CustomerId, CONCAT(c.FirstName, "", c.LastName) AS FullName, SUM(Total) AS Total_Spent -- , SUM(il.UnitPrice) -- , p.Name
FROM customer as c
LEFT JOIN invoice USING(CustomerId)
LEFT JOIN invoiceline AS il USING(InvoiceId)
LEFT JOIN track USING(TrackId)
LEFT JOIN playlisttrack USING(TrackId)
LEFT JOIN playlist AS p USING(PlaylistId)
WHERE p.Name LIKE "%Music%"
GROUP BY CustomerId
ORDER BY Total_Spent DESC
LIMIT 1;

SELECT 
    CONCAT(c.firstName, " ", c.lastName) AS Customer,
    SUM(i.total) AS TotalSpent
FROM
    customer c
        JOIN
    invoice i USING (customerid)
GROUP BY c.customerid
ORDER BY TotalSpent DESC
LIMIT 1;

-- 21. How many tracks were sold from each media type?
-- Solution 1
SELECT MediaTypeId, m.Name, COUNT(il.TrackId) AS Total_Track
FROM mediatype As m
LEFT JOIN track USING(MediaTypeId)
LEFT JOIN invoiceline AS il USING(TrackId)
GROUP BY MediaTypeId;

-- Solution2
SELECT 
    mediatype.MediaTypeId, 
    mediatype.`name` AS MediaType,
    COUNT(*) AS NumSold
FROM
    invoiceline
        LEFT JOIN
    track USING (TrackId)
        LEFT JOIN
    mediatype USING (MediaTypeId)
GROUP BY MediaTypeId;

-- 22. Find the total sales per genre. Only include genres with sales between 100 and 500.
SELECT g.GenreId, g.Name, SUM(i.total) AS Total_Sales
FROM genre as g
JOIN track USING(GenreId)
JOIN invoiceline USING(TrackId)
JOIN invoice  AS i USING(InvoiceId)
GROUP BY GenreId
HAVING Total_sales BETWEEN 100 AND 500;

-- 23. Find the total number of tracks sold per artist. 
-- Add an extra column categorising the artists into 'High', 'Medium', 'Low' based on the number of tracks sold.
-- High is more than 100, Low is less than 50.
SELECT ArtistId, COUNT(TrackId) AS Total_Tracks,
CASE
	WHEN COUNT(TrackId) > 100 THEN "High"
    WHEN COUNT(TrackId) <= 50 THEN "Low"
    ELSE "Medium"
END AS Artist_Categorization
FROM artist
JOIN album USING(ArtistId)
JOIN track USING(AlbumId)
JOIN invoiceline AS il USING(Trackid)
GROUP BY ArtistId;
