CREATE SCHEMA highschool;

# Create table
drop table if exists Highschooler;
drop table if exists Friend;
drop table if exists Likes;

create table Highschooler(ID int, name text, grade int);
create table Friend(ID1 int, ID2 int);
create table Likes(ID1 int, ID2 int);

insert into Highschooler values (1510, 'Jordan', 9);
insert into Highschooler values (1689, 'Gabriel', 9);
insert into Highschooler values (1381, 'Tiffany', 9);
insert into Highschooler values (1709, 'Cassandra', 9);
insert into Highschooler values (1101, 'Haley', 10);
insert into Highschooler values (1782, 'Andrew', 10);
insert into Highschooler values (1468, 'Kris', 10);
insert into Highschooler values (1641, 'Brittany', 10);
insert into Highschooler values (1247, 'Alexis', 11);
insert into Highschooler values (1316, 'Austin', 11);
insert into Highschooler values (1911, 'Gabriel', 11);
insert into Highschooler values (1501, 'Jessica', 11);
insert into Highschooler values (1304, 'Jordan', 12);
insert into Highschooler values (1025, 'John', 12);
insert into Highschooler values (1934, 'Kyle', 12);
insert into Highschooler values (1661, 'Logan', 12);

insert into Friend values (1510, 1381);
insert into Friend values (1510, 1689);
insert into Friend values (1689, 1709);
insert into Friend values (1381, 1247);
insert into Friend values (1709, 1247);
insert into Friend values (1689, 1782);
insert into Friend values (1782, 1468);
insert into Friend values (1782, 1316);
insert into Friend values (1782, 1304);
insert into Friend values (1468, 1101);
insert into Friend values (1468, 1641);
insert into Friend values (1101, 1641);
insert into Friend values (1247, 1911);
insert into Friend values (1247, 1501);
insert into Friend values (1911, 1501);
insert into Friend values (1501, 1934);
insert into Friend values (1316, 1934);
insert into Friend values (1934, 1304);
insert into Friend values (1304, 1661);
insert into Friend values (1661, 1025);
insert into Friend select ID2, ID1 from Friend;

insert into Likes values(1689, 1709);
insert into Likes values(1709, 1689);
insert into Likes values(1782, 1709);
insert into Likes values(1911, 1247);
insert into Likes values(1247, 1468);
insert into Likes values(1641, 1468);
insert into Likes values(1316, 1304);
insert into Likes values(1501, 1934);
insert into Likes values(1934, 1501);
insert into Likes values(1025, 1101);

-- 1. Find the names of all students who are friends with someone named Gabriel.
WITH cte AS (
	SELECT ID2 AS ID
	FROM Highschooler AS h
	INNER JOIN Friend AS f
	ON h.ID = f.ID1
	WHERE name = "Gabriel"
	UNION
	SELECT ID1 AS ID
	FROM Highschooler AS h
	INNER JOIN Friend AS f
	ON h.ID = f.ID2
	WHERE name = "Gabriel"
)
SELECT name
FROM Highschooler as h
INNER JOIN cte
ON h.ID = cte.ID;

-- 2. For every student who likes someone 2 or more grades younger than themselves, return that student's name and grade, and the name and grade of the student they like.
SELECT h1.name as student_a, h1.grade as grade_a, h2.name AS student_b, h2.grade AS grade_b
FROM Highschooler AS h1, Highschooler AS h2
WHERE (h1.ID, h2.ID) in (
	SELECT ID1, ID2
    FROM likes
)
AND h1.grade - h2.grade >= 2;

-- 3. For every pair of students who both like each other, return the name and grade of both students. Include each pair only once, with the two names in alphabetical order.
SELECT h1.name as student_a, h1.grade as grade_a, h2.name AS student_b, h2.grade AS grade_b
FROM Highschooler AS h1, Highschooler AS h2
WHERE (h1.ID, h2.ID) IN (
	SELECT l1.ID1, l1.ID2
	FROM Likes AS l1, Likes AS l2
	WHERE l1.ID1 = l2.ID2
	AND l1.ID2 = l2.ID1
)
AND h1.name < h2.name;

-- 4. Find all students who do not appear in the Likes table (as a student who likes or is liked) and return their names and grades. Sort by grade, then by name within each grade.
SELECT name, grade
FROM Highschooler
WHERE ID NOT in (
	SELECT ID1
	FROM Likes
	UNION
	SELECT ID2
	FROM Likes
);

-- 5. For every situation where student A likes student B, but we have no information about whom B likes (that is, B does not appear as an ID1 in the Likes table), return A and B's names and grades.
WITH cte AS (
    SELECT h1.name AS student_a, h1.grade as grade_a, h2.name AS student_b, h2.grade as grade_b
    FROM Highschooler AS h1
    INNER JOIN Likes AS l 
    ON h1.ID = l.ID1
    INNER JOIN Highschooler AS h2 
    ON l.ID2 = h2.ID
)
SELECT *
FROM cte
WHERE student_b NOT IN (
    SELECT student_a
    FROM cte
);

-- 6. Find names and grades of students who only have friends in the same grade. Return the result sorted by grade, then by name within each grade.
WITH cte AS (
    (SELECT ID2 AS O_ID, ID1 AS F_ID, grade as F_grade
    FROM friend AS f
    INNER JOIN Highschooler AS h
    ON f.ID1 = h.ID)
	UNION ALL
	(SELECT ID1 AS O_ID, ID2 AS F_ID, grade as F_grade
    FROM friend AS f
    INNER JOIN Highschooler AS h
    ON f.ID2 = h.ID)
)
SELECT name, grade
FROM Highschooler
WHERE ID IN (
    SELECT O_ID
    FROM cte
    GROUP BY O_ID
    HAVING COUNT(DISTINCT f_grade) = 1
)
ORDER BY grade, name;

-- 7. For each student A who likes a student B where the two are not friends, find if they have a friend C in common (who can introduce them!). For all such trios, return the name and grade of A, B, and C.
SELECT h1.name AS student_a, h1.grade AS grade_a, h2.name AS student_b, h2.grade AS grade_b, h3.name AS student_c, h3.grade AS grade_c
FROM highschooler AS h1, highschooler AS h2, highschooler AS h3
WHERE (h1.ID, h2.ID) IN (
	SELECT *
    FROM likes)
AND (h1.ID, h2.ID) NOT IN (
	SELECT *
    FROM friend)
AND (h1.ID, h3.ID) IN (
	SELECT *
    FROM friend)
AND (h2.ID, h3.ID) IN (
	SELECT *
    FROM friend)
AND h1.name < h2.name;

-- 8. Find the difference between the number of students in the school and the number of different first names.
SELECT COUNT(*) - COUNT(DISTINCT name) AS difference
FROM highschooler;

-- 9. Find the name and grade of all students who are liked by more than one other student.
SELECT name, grade
FROM highschooler
WHERE ID IN (
	SELECT ID2
    FROM likes
    GROUP BY ID2
    HAVING COUNT(*) > 1
);

-- Extra
-- 1. For every situation where student A likes student B, but student B likes a different student C, return the names and grades of A, B, and C.
SELECT h1.name AS student_a, h1.grade AS grade_a, h2.name AS student_b, h2.grade AS grade_b, h3.name AS student_c, h3.grade AS grade_c
FROM highschooler AS h1, highschooler AS h2, highschooler AS h3
WHERE (h1.ID, h2.ID) IN (
	SELECT *
    FROM likes)
AND (h2.ID, h3.ID) IN (
	SELECT *
    FROM likes)
AND h1.ID <> h3.ID;

-- 2. Find those students for whom all of their friends are in different grades from themselves. Return the students' names and grades.
SELECT name, grade
FROM highschooler
WHERE ID NOT IN (
	SELECT ID1
    FROM highschooler AS h1
    INNER JOIN friend AS f
    ON h1.ID = ID1
    INNER JOIN highschooler AS h2
    ON h2.ID = ID2
    WHERE h1.grade = h2.grade
);

-- 3. What is the average number of friends per student? (Your result should be just one number.)
WITH cte as (
	SELECT COUNT(*) as cnt
    FROM friend
	GROUP BY ID1
)
SELECT AVG(cnt)
FROM cte;

-- 4. Find the number of students who are either friends with Cassandra or are friends of friends of Cassandra. Do not count Cassandra, even though technically she is a friend of a friend.
SELECT COUNT(*)
FROM Friend
WHERE ID1 IN (
  SELECT ID2
  FROM Friend
  WHERE ID1 IN (
    SELECT ID
    FROM Highschooler
    WHERE name = 'Cassandra'
  )
);

-- 5. Find the name and grade of the student(s) with the greatest number of friends.
SELECT name, grade
FROM highschooler AS h
INNER JOIN friend AS f
ON h.ID = f.ID1
GROUP BY name, grade
HAVING COUNT(*) = (
	SELECT MAX(count)
    FROM (
		SELECT COUNT(*) AS count
        FROM friend
        GROUP BY ID1
	) AS sub
);

-- Modification Exercises
-- 1. It's time for the seniors to graduate. Remove all 12th graders from Highschooler.
DELETE FROM highschooler
WHERE grade = 12;

-- 2. If two students A and B are friends, and A likes B but not vice-versa, remove the Likes tuple.
DELETE FROM likes
WHERE id1 IN (
	SELECT likes.id1 
	FROM friend join likes using (id1) 
	WHERE friend.id2 = likes.id2
) 
AND id2 NOT IN (
	SELECT likes.id1 
	FROM friend 
    INNER JOIN likes using (id1) 
	WHERE friend.id2 = likes.id2
);

-- 3. For all cases where A is friends with B, and B is friends with C, add a new friendship for the pair A and C. Do not add duplicate friendships, friendships that already exist, or friendships with oneself. (This one is a bit challenging; congratulations if you get it right.)
INSERT INTO friend
SELECT f1.id1, f2.id2
FROM friend AS f1 
INNER JOIN friend AS f2 
ON f1.id2 = f2.id1
WHERE f1.id1 <> f2.id2
EXCEPT
SELECT * FROM friend;
