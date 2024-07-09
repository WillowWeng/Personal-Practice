CREATE SCHEMA movierating;

/* Delete the tables if they already exist */
drop table if exists Movie;
drop table if exists Reviewer;
drop table if exists Rating;

/* Create the schema for our tables */
create table Movie(mID int, title text, year int, director text);
create table Reviewer(rID int, name text);
create table Rating(rID int, mID int, stars int, ratingDate date);

/* Populate the tables with our data */
insert into Movie values(101, 'Gone with the Wind', 1939, 'Victor Fleming');
insert into Movie values(102, 'Star Wars', 1977, 'George Lucas');
insert into Movie values(103, 'The Sound of Music', 1965, 'Robert Wise');
insert into Movie values(104, 'E.T.', 1982, 'Steven Spielberg');
insert into Movie values(105, 'Titanic', 1997, 'James Cameron');
insert into Movie values(106, 'Snow White', 1937, null);
insert into Movie values(107, 'Avatar', 2009, 'James Cameron');
insert into Movie values(108, 'Raiders of the Lost Ark', 1981, 'Steven Spielberg');

insert into Reviewer values(201, 'Sarah Martinez');
insert into Reviewer values(202, 'Daniel Lewis');
insert into Reviewer values(203, 'Brittany Harris');
insert into Reviewer values(204, 'Mike Anderson');
insert into Reviewer values(205, 'Chris Jackson');
insert into Reviewer values(206, 'Elizabeth Thomas');
insert into Reviewer values(207, 'James Cameron');
insert into Reviewer values(208, 'Ashley White');

insert into Rating values(201, 101, 2, '2011-01-22');
insert into Rating values(201, 101, 4, '2011-01-27');
insert into Rating values(202, 106, 4, null);
insert into Rating values(203, 103, 2, '2011-01-20');
insert into Rating values(203, 108, 4, '2011-01-12');
insert into Rating values(203, 108, 2, '2011-01-30');
insert into Rating values(204, 101, 3, '2011-01-09');
insert into Rating values(205, 103, 3, '2011-01-27');
insert into Rating values(205, 104, 2, '2011-01-22');
insert into Rating values(205, 108, 4, null);
insert into Rating values(206, 107, 3, '2011-01-15');
insert into Rating values(206, 106, 5, '2011-01-19');
insert into Rating values(207, 107, 5, '2011-01-20');
insert into Rating values(208, 104, 3, '2011-01-02');

-- 1. Find the titles of all movies directed by Steven Spielberg.
SELECT title
FROM Movie
WHERE director LIKE "Steven Spie%";

-- 2. Find all years that have a movie that received a rating of 4 or 5, and sort them in increasing order.
SELECT DISTINCT year
FROM Movie AS m
INNER JOIN Rating AS r
ON m.mID = r.mID
WHERE stars >= 4
ORDER BY year ASC;

-- 3. Find the titles of all movies that have no ratings.
SELECT title
FROM Movie
WHERE mID NOT IN (
	SELECT mID
	FROM Rating);
    
-- 4. Some reviewers didn't provide a date with their rating. Find the names of all reviewers who have ratings with a NULL value for the date.
SELECT DISTINCT name
FROM Reviewer AS re
INNER JOIN Rating AS ra
ON re.rID = ra.rID
WHERE ratingDate IS NULL;

-- 5. Write a query to return the ratings data in a more readable format: reviewer name, movie title, stars, and ratingDate. Also, sort the data, first by reviewer name, then by movie title, and lastly by number of stars.
SELECT name, title, stars, ratingDate
FROM Movie AS m
INNER JOIN Rating AS ra
ON m.mID = ra.mID
INNER JOIN Reviewer AS re
ON re.rID = ra.rID
ORDER BY name ASC, title ASC, stars ASC;

-- 6. For all cases where the same reviewer rated the same movie twice and gave it a higher rating the second time, return the reviewer's name and the title of the movie.
WITH cte AS (
	SELECT name, title, stars, LEAD(stars) OVER (PARTITION BY name, title ORDER BY ratingDate ASC) AS next_stars
	FROM movie AS m
	INNER JOIN rating AS ra
	ON m.mID = ra.mID
	INNER JOIN Reviewer AS re
	ON re.rID = ra.rID
)
SELECT name, title
FROM cte
where next_stars > stars;

-- 7. For each movie that has at least one rating, find the highest number of stars that movie received. Return the movie title and number of stars. Sort by movie title.
SELECT title, MAX(stars) as max_stars
FROM movie AS m
INNER JOIN rating AS r
ON m.mID = r.mID
GROUP BY title
HAVING COUNT(*) > 1;

-- 8. For each movie, return the title and the 'rating spread', that is, the difference between highest and lowest ratings given to that movie. Sort by rating spread from highest to lowest, then by movie title.
SELECT title, MAX(stars) - MIN(stars) AS difference
FROM Movie AS m
INNER JOIN Rating AS r
ON m.mID = r.mID
GROUP BY title
ORDER BY difference DESC, title ASC;

-- 9. Find the difference between the average rating of movies released before 1980 and the average rating of movies released after 1980. 
-- (Make sure to calculate the average rating for each movie, then the average of those averages for movies before 1980 and movies after. Don't just calculate the overall average rating before and after 1980.)
SELECT AVG(s1.avg) - AVG(s2.avg) AS avg_dif
FROM (
  SELECT AVG(stars) AS avg
  FROM Movie
  INNER JOIN Rating USING(mId)
  WHERE year < 1980
  GROUP BY mId
) AS s1, 
(
  SELECT AVG(stars) AS avg
  FROM Movie
  INNER JOIN Rating USING(mId)
  WHERE year > 1980
  GROUP BY mId
) AS s2;

-- Extras
-- 1. Find the names of all reviewers who rated Gone with the Wind.
SELECT DISTINCT name
FROM Movie as m
INNER JOIN Rating as ra
on m.mID = ra.mID
INNER JOIN Reviewer as re
on ra.rID = re.rID
WHERE title = "Gone with the Wind";

-- 2. For any rating where the reviewer is the same as the director of the movie, return the reviewer name, movie title, and number of stars.
SELECT name, title, stars
FROM Movie AS m
INNER JOIN Rating AS ra
ON m.mID = ra.mID
INNER JOIN Reviewer AS re
ON ra.rID = re.rID
WHERE name IN (
	SELECT director
	FROM Movie);
    
-- 3. Return all reviewer names and movie names together in a single list, alphabetized. (Sorting by the first name of the reviewer and first word in the title is fine; no need for special processing on last names or removing "The".)
SELECT title FROM Movie
UNION
SELECT name FROM Reviewer
ORDER BY name, title;

-- 4. Find the titles of all movies not reviewed by Chris Jackson.
SELECT title
FROM Movie
WHERE title NOT IN (
	SELECT title
	FROM Movie AS m
	INNER JOIN Rating AS ra
	ON m.mID = ra.mID
	INNER JOIN Reviewer AS re
	ON ra.rID = re.rID
	where name = "Chris Jackson");
    
-- 5. For all pairs of reviewers such that both reviewers gave a rating to the same movie, return the names of both reviewers. Eliminate duplicates, don't pair reviewers with themselves, and include each pair only once. For each pair, return the names in the pair in alphabetical order.
WITH cte AS (
	SELECT DISTINCT mID, name
	FROM Rating AS ra
	INNER JOIN Reviewer AS re
	ON ra.rID = re.rID
)
SELECT DISTINCT cte1.name, cte2.name
FROM cte AS cte1, cte AS cte2
WHERE cte1.name < cte2.name
AND cte1.mID = cte2.mID
ORDER BY cte1.name;

-- 6. For each rating that is the lowest (fewest stars) currently in the database, return the reviewer name, movie title, and number of stars.
SELECT name, title, stars
FROM Movie
INNER JOIN Rating USING(mId)
INNER JOIN Reviewer USING(rId)
WHERE stars = (SELECT MIN(stars) FROM Rating);

-- 7. List movie titles and average ratings, from highest-rated to lowest-rated. If two or more movies have the same average rating, list them in alphabetical order.
SELECT title, AVG(stars) AS average
FROM Movie AS m
INNER JOIN Rating AS r
ON m.mId = r.mID
GROUP BY title
ORDER BY average DESC, title ASC;

-- 8. Find the names of all reviewers who have contributed three or more ratings.
SELECT name
FROM Reviewer
WHERE (
	SELECT COUNT(*) 
    FROM Rating
    WHERE Rating.rId = Reviewer.rId
) >= 3;

SELECT name
FROM reviewer AS r1
INNER JOIN rating AS r2
ON r1.rID = r2.rID
GROUP BY name
HAVING COUNT(*) >= 3;

-- 9. Some directors directed more than one movie. For all such directors, return the titles of all movies directed by them, along with the director name. Sort by director name, then movie title.
SELECT title, director
FROM Movie AS m1
WHERE (
	SELECT COUNT(*) 
    FROM Movie AS m2 
    WHERE m1.director = m2.director) > 1
ORDER BY director, title;

SELECT title, director
FROM movie
WHERE director IN (
	SELECT director
    FROM movie
    GROUP BY director
    HAVING COUNT(*) > 1
)
ORDER BY director, title;

-- 10. Find the movie(s) with the highest average rating. Return the movie title(s) and average rating. 
-- (Hint: This query is more difficult to write in SQLite than other systems; you might think of it as finding the highest average rating and then choosing the movie(s) with that average rating.)
SELECT title, AVG(stars) AS average
FROM Movie
INNER JOIN Rating USING(mId)
GROUP BY title
HAVING average = (
  SELECT MAX(average_stars)
  FROM (
    SELECT title, AVG(stars) AS average_stars
    FROM Movie
    INNER JOIN Rating USING(mId)
    GROUP BY title
  ) AS sub
);

-- 11. Find the movie(s) with the lowest average rating. Return the movie title(s) and average rating. 
-- (Hint: This query may be more difficult to write in SQLite than other systems; you might think of it as finding the lowest average rating and then choosing the movie(s) with that average rating.)
SELECT title, AVG(stars) AS average
FROM Movie
INNER JOIN Rating USING(mId)
GROUP BY title
HAVING average = (
  SELECT MIN(average_stars)
  FROM (
    SELECT title, AVG(stars) AS average_stars
    FROM Movie
    INNER JOIN Rating USING(mId)
    GROUP BY title
  ) AS sub
);

-- 12. For each director, return the director's name together with the title(s) of the movie(s) they directed that received the highest rating among all of their movies, and the value of that rating. Ignore movies whose director is NULL.
WITH cte AS (
	SELECT DISTINCT director, title, stars, rank() OVER (PARTITION BY director ORDER BY stars DESC, title DESC) AS ranking
	FROM Movie
	INNER JOIN Rating USING(mId)
	WHERE director IS NOT NULL
)
SELECT director, title, stars
FROM cte
WHERE ranking = 1;

-- Modification Exercises
-- 1. Add the reviewer Roger Ebert to your database, with an rID of 209.
insert into Reviewer values (209, 'Roger Ebert');

-- 2. For all movies that have an average rating of 4 stars or higher, add 25 to the release year. (Update the existing tuples; don't insert new tuples.)
SET SQL_SAFE_UPDATES = 0;
UPDATE movie
SET year = year + 25
WHERE mID IN (
    SELECT mID
    FROM rating
    GROUP BY mID
    HAVING AVG(stars) >= 4
);

-- 3. Remove all ratings where the movie's year is before 1970 or after 2000, and the rating is fewer than 4 stars.
DELETE FROM rating
WHERE mID IN (
	SELECT mID FROM movie 
    WHERE year <1970 or year > 2000)
AND stars < 4;