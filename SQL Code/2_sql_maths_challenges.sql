USE Chinook;


-- 1. What's the difference between the largest and the smallest invoice price?
SELECT MAX(Total) - MIN(Total) AS RangeOfPrice
FROM invoice;

-- 2. What is the difference in length between the longest and shortest track in minutes?
-- There are 1000 milliseconds in a second and 60 seconds in a minute
-- Solution1
SELECT (MAX(Milliseconds) - Min(Milliseconds))/ (1000 * 60)  AS TrackDifference_Minutes
FROM track;

-- Solution2
SELECT 
    MAX(milliseconds) / 60000 - MIN(milliseconds) / 60000 AS TrackDifference_Minutes
FROM
    track;

-- 3. What is the average length of a track in the 'Rock' genre in minutes?
SELECT AVG(Milliseconds) / (1000 * 60) AS AvgTrackLength
FROM track
LEFT JOIN genre AS g USING(GenreId)
WHERE g.name = "Rock";

-- 4. What is the average length of a 'Rock' track in minutes, rounded to 2 decimal places?
SELECT ROUND(AVG(Milliseconds) / (1000 * 60), 2) AS AvgTrackLength
FROM track
LEFT JOIN genre AS g USING(GenreId)
WHERE g.name = "Rock";

-- 5. What is the average length of a 'Rock' track in minutes, rounded down to the nearest integer?
SELECT FLOOR(AVG(Milliseconds) / (1000 * 60)) AS AvgTrackLength
FROM track
LEFT JOIN genre AS g USING(GenreId)
WHERE g.name = "Rock";

-- 6. What is the average length of a 'Rock' track in minutes, rounded up to the nearest integer?
SELECT CEIL(AVG(Milliseconds) / (1000 * 60)) AS AvgTrackLength
FROM track
LEFT JOIN genre AS g USING(GenreId)
WHERE g.name = "Rock";

-- 7. What is the total length of all tracks for each genre in minutes.
-- Order them from largest to smallest length of time.
-- Solution1
SELECT GenreId, g.Name AS GenreName, SUM(t.Milliseconds) / (1000 * 60) AS TotalTrackLength
FROM track AS t
LEFT JOIN genre AS g USING(GenreId)
GROUP BY GenreId
ORDER BY TotalTrackLength DESC;

-- Solution2
SELECT 
    g.name AS GenreName,
    SUM(t.milliseconds) / 60000 AS TotalLengthMinutes
FROM
    track t
        JOIN
    genre g USING (genreid)
GROUP BY g.Name
ORDER BY TotalLengthMinutes DESC;

-- 8. How many tracks have a length between 3 and 5 minutes?
SELECT COUNT(TrackId) AS CountTracks3To5Minutes 
FROM track
WHERE Milliseconds / (1000 * 60)  BETWEEN 3 AND 5;

-- 9. If each song means each track costs $1.27, how much would it cost to buy all the songs in the 'Classical' genre?
SELECT COUNT(TrackId) * 1.27 AS TotalCost
FROM genre as g
JOIN track USING(GenreId)
WHERE g.Name = "Classical";

-- 10. How many more composers are there than artists?
SELECT COUNT(DISTINCT(Composer)) - COUNT(DISTINCT(ArtistId)) AS Difference
FROM artist
JOIN album USING(ArtistId)
JOIN track USING(AlbumId);

-- 11. Which 'Metal' genre albums have an odd number of tracks?
SELECT a.AlbumId, a.Title, COUNT(*) AS Total_Tracks
FROM genre as g
LEFT JOIN track USING(GenreId)
LEFT JOIN album AS a USING(AlbumId)
WHERE g.Name = "Metal"  
GROUP BY AlbumId
HAVING Total_Tracks % 2 != 0;


-- 12. What is the average invoice total rounded to the nearest whole number?
SELECT ROUND(AVG(Total)) AS AvgInvoice
FROM invoice;

-- 13. Classify tracks as 'Short', 'Medium', or 'Long' based on their length.
-- Long is 5 minutes or longer. Short is less than 3 minutes.
SELECT *, Milliseconds / (1000 * 60) AS Minutes,
CASE
	WHEN Milliseconds / (1000 * 60) >= 5  THEN "Long"
    WHEN Milliseconds / (1000 * 60) < 3 THEN "Short"
    ELSE "Medium"
END AS TrackClassification
FROM track;

-- 14. Taking into consideration the unitprice and the quantity sold,
-- rank the songs from highest grossing to lowest.
-- Include the track name and the artist.
SELECT il.TrackId, t.Name AS TrackName, ar.Name AS ArtistName, SUM(il.UnitPrice * il.Quantity) AS TotalSale
FROM invoiceline AS il 
LEFT JOIN track AS t USING(TrackId)
LEFT JOIN album USING(AlbumId)
LEFT JOIN artist AS ar USING(ArtistId)
GROUP BY il.TrackId 
ORDER BY TotalSale DESC;
