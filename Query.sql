-- 
-- Author: Nicolas Nguyen Van Au
-- Date: 2024-01-09
--
-- File name: Query.sql
-- This file is used to run SQL queries for exercises


--Check data base name
SELECT current_database();
-- Export column and name of table
SELECT 
    table_name AS TableName,
    column_name AS ColumnName
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    table_catalog = 'temp' -- Replace with your actual database name
    AND table_schema = 'public' -- You can change 'public' to your specific schema if needed
ORDER BY 
    table_name, column_name;
-- csv data: CSV_DATA\table_column.csv
/* Question 1
We want to understand more about the movies that families are watching. The following categories are considered family movies: Animation, Children, Classics, Comedy, Family and Music.
Create a query that lists each movie, the film category it is classified in, and the number of times it has been rented out.
*/

-- Select movie title, category name, and the number of times the movie has been rented
SELECT 
    f.title AS film_title,   -- Renamed the column to 'film_title'
    cat.name AS category_name,   -- Renamed the column to 'category_name'
    COUNT(r.rental_id) AS count_of_rentals -- Count the number of rentals for each movie
FROM 
    film f -- Table 'film' stores information about movies
JOIN 
    film_category fc ON f.film_id = fc.film_id -- 'film_category' links films to their categories
JOIN 
    category cat ON fc.category_id = cat.category_id -- 'category' stores category details
JOIN 
    inventory inv ON f.film_id = inv.film_id -- 'inventory' tracks the stock of each film
JOIN 
    rental r ON inv.inventory_id = r.inventory_id -- 'rental' logs each rental transaction
WHERE 
    cat.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music') -- Filters to only family-friendly genres
GROUP BY 
    f.title, cat.name -- Groups results by movie title and genre for counting
ORDER BY 
    cat.name, f.title; -- Orders results by genre, then by movie title for readability

-- out put : CSV_DATA\Answer_1.csv

-- Check  Total rentals for each category
SELECT 
    cat.name AS category_name,   -- Category name
    COUNT(r.rental_id) AS count_of_rentals, -- Count of rentals for each movie
    SUM(COUNT(r.rental_id)) OVER (PARTITION BY cat.name) AS total_rentals  -- Total rentals for each category
FROM 
    film f -- The 'film' table stores information about movies
JOIN 
    film_category fc ON f.film_id = fc.film_id -- 'film_category' links films to their categories
JOIN 
    category cat ON fc.category_id = cat.category_id -- 'category' stores category details
JOIN 
    inventory inv ON f.film_id = inv.film_id -- 'inventory' tracks the stock of each film
JOIN 
    rental r ON inv.inventory_id = r.inventory_id -- 'rental' logs each rental transaction
WHERE 
    cat.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music') -- Filters to only family-friendly genres
GROUP BY 
    cat.name -- Groups results by category name
ORDER BY 
    category_name; -- Orders results by category name for readability

--output : 

/*
Question 2
Now we need to know how the length of rental duration of these family-friendly movies compares to the duration that all movies are rented for. Can you provide a table with the movie titles and divide them into 4 levels (first_quarter, second_quarter, third_quarter, and final_quarter) based on the quartiles (25%, 50%, 75%) of the average rental duration(in the number of days) for movies across all categories? Make sure to also indicate the category that these family-friendly movies fall into.
*/

WITH family_movies AS (
    -- Get family-friendly movies and their rental duration
    SELECT 
        f.title AS Movie_Title,
        c.name AS Category_Name,
        f.rental_duration AS Rental_Duration -- Get rental duration for family movies
    FROM 
        film f
    JOIN 
        film_category fc ON f.film_id = fc.film_id
    JOIN 
        category c ON fc.category_id = c.category_id
    WHERE 
        c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music') -- Filter for family-friendly categories
),
rental_quartiles AS (
    -- Calculate the quartiles for rental duration
    SELECT 
        Movie_Title,
        Category_Name,
        Rental_Duration,
        NTILE(4) OVER (ORDER BY Rental_Duration) AS Rental_Duration_Quartile -- Divide rental durations into quartiles
    FROM 
        family_movies
),
quartile_values AS (
    -- Calculate the standard quartiles (Q1, Q2, Q3)
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Rental_Duration) AS Q1,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Rental_Duration) AS Q2,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Rental_Duration) AS Q3
    FROM 
        family_movies
)
-- Final output with movie titles, categories, and their quartile level
SELECT 
    r.Movie_Title,
    r.Category_Name,
    r.Rental_Duration_Quartile,
    CASE 
        WHEN r.Rental_Duration <= q.Q1 THEN 1 -- Assign 1 for Q1
        WHEN r.Rental_Duration <= q.Q2 THEN 2 -- Assign 2 for Q2
        WHEN r.Rental_Duration <= q.Q3 THEN 3 -- Assign 3 for Q3
        ELSE 4 -- Assign 4 for values greater than Q3
    END AS Standard_Quartile -- Compute the standard quartile based on rental duration
FROM 
    rental_quartiles r
CROSS JOIN 
    quartile_values q -- Join with quartile values to use for standard quartile calculation
ORDER BY 
    r.Category_Name, r.Movie_Title; -- Order the final output


-- out put : CSV_DATA\Answer_2.csv
/*
Question 3
Finally, provide a table with the family-friendly film category, each of the quartiles, and the corresponding count of movies within each combination of film category for each corresponding rental duration category. The resulting table should have three columns:

Category
Rental length category
Count
*/
WITH family_movies AS (
    -- Get family-friendly movies
    SELECT 
        f.title AS Movie_Title,
        c.name AS Category_Name,
        f.rental_duration AS Rental_Duration -- Get rental duration for family movies
    FROM 
        film f
    JOIN 
        film_category fc ON f.film_id = fc.film_id
    JOIN 
        category c ON fc.category_id = c.category_id
    WHERE 
        c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music') -- Filter for family-friendly categories
),
quartile_values AS (
    -- Calculate the standard quartiles (Q1, Q2, Q3)
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Rental_Duration) AS Q1,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Rental_Duration) AS Q2,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Rental_Duration) AS Q3
    FROM 
        family_movies
),
rental_length_categories AS (
    -- Classify rental duration into categories based on quartiles
    SELECT 
        f.Category_Name,
        CASE 
            WHEN f.Rental_Duration <= q.Q1 THEN 1 -- Assign 1 for Q1
            WHEN f.Rental_Duration <= q.Q2 THEN 2 -- Assign 2 for Q2
            WHEN f.Rental_Duration <= q.Q3 THEN 3 -- Assign 3 for Q3
            ELSE 4 -- Assign 4 for values greater than Q3
        END AS Standard_Quartile
    FROM 
        family_movies f
    CROSS JOIN 
        quartile_values q -- Join with quartile values to classify rental durations
)
-- Count the number of movies in each category and standard quartile
SELECT 
    Category_Name AS Category,
    Standard_Quartile,
    COUNT(*) AS Count
FROM 
    rental_length_categories
GROUP BY 
    Category_Name, Standard_Quartile
ORDER BY 
    Category_Name, Standard_Quartile; -- Order the final output

--out put: CSV_DATA\Answer_3.csv


/*
Question 4
What is the Revenue Generated by Each Film Category from 2005 to 2007?
*/
SELECT 
    c.name AS category_name,
    EXTRACT(YEAR FROM r.rental_date) AS rental_year,
    SUM(p.amount) AS total_revenue
FROM 
    category c
JOIN 
    film_category fc ON c.category_id = fc.category_id
JOIN 
    film f ON fc.film_id = f.film_id
JOIN 
    inventory i ON f.film_id = i.film_id
JOIN 
    rental r ON i.inventory_id = r.inventory_id
JOIN 
    payment p ON r.rental_id = p.rental_id
WHERE 
    r.rental_date BETWEEN '2005-01-01' AND '2007-12-31'  -- limit 2005 to 2007
GROUP BY 
    c.name, rental_year
ORDER BY 
    category_name, rental_year;

--out put: CSV_DATA\Answer_4.csv


/*
Question 5
What is the Percentage of Films Viewed Based on Rental Duration?
*/
WITH rental_duration_revenue AS (
    SELECT 
        f.title AS film_title,
        SUM(p.amount) AS total_revenue
    FROM 
        payment p
    JOIN 
        rental r ON p.rental_id = r.rental_id
    JOIN 
        inventory i ON r.inventory_id = i.inventory_id
    JOIN 
        film f ON i.film_id = f.film_id
    WHERE 
        EXTRACT(YEAR FROM p.payment_date) BETWEEN 2005 AND 2007
    GROUP BY 
        f.title
),
total_revenue AS (
    SELECT 
        SUM(total_revenue) AS grand_total_revenue
    FROM 
        rental_duration_revenue
)
SELECT 
    r.film_title,
    r.total_revenue,
    ROUND((r.total_revenue / tr.grand_total_revenue) * 100, 2) AS percentage_viewed
FROM 
    rental_duration_revenue r
CROSS JOIN 
    total_revenue tr
ORDER BY 
    r.total_revenue DESC  -- Sắp xếp theo doanh thu từ cao đến thấp
LIMIT 5;  -- Lấy 5 kết quả hàng đầu
--out put: CSV_DATA\Answer_5.csv