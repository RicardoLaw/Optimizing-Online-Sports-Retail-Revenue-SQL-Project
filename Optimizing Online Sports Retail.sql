
CREATE TABLE info
(product_name VARCHAR(100),
 product_id VARCHAR(11) PRIMARY KEY,
 description VARCHAR(700));



CREATE TABLE finance
(product_id VARCHAR(11) PRIMARY KEY,
listing_price FLOAT,
sale_price FLOAT,
discount FLOAT,
revenue FLOAT);



CREATE TABLE reviews
(product_id VARCHAR(11) PRIMARY KEY,
rating FLOAT,
reviews FLOAT);



CREATE TABLE traffic
(product_id VARCHAR(11) PRIMARY KEY,
last_visited TIMESTAMP);



CREATE TABLE brands
(product_id VARCHAR(11) PRIMARY KEY,
 brand VARCHAR(7));



-- Count all columns as total_rows

SELECT COUNT(*) AS total_rows, 
    COUNT(i.description) AS count_description, 
    COUNT(f.listing_price) AS count_listing_price, 
    COUNT(t.last_visited) AS count_last_visited 
FROM info AS i
INNER JOIN finance AS f
    ON i.product_id = f.product_id
INNER JOIN traffic AS t
    ON t.product_id = f.product_id;

    
-- Select the brand, listing_price as an integer, and a count of all products in finance 

SELECT b.brand, f.listing_price::integer, COUNT(f.*)
FROM finance AS f
INNER JOIN brands AS b 
    ON f.product_id = b.product_id
WHERE listing_price > 0
GROUP BY b.brand, f.listing_price
ORDER BY listing_price DESC;


-- Select the brand, a count of all products in the finance table, and total revenue

SELECT b.brand, COUNT(f.*), SUM(f.revenue) AS total_revenue,

CASE WHEN f.listing_price < 42 THEN 'Budget'
     WHEN f.listing_price >= 42 AND f.listing_price < 74 THEN 'Average'
     WHEN f.listing_price >= 74 AND f.listing_price < 129 THEN 'Expensive'
     ELSE 'Elite' END AS price_category
    
FROM finance AS f 
INNER JOIN brands AS B 
ON f.product_id = b.product_id
WHERE b.brand IS NOT NULL
GROUP BY b.brand, price_category
ORDER BY total_revenue DESC;


-- Select brand and average_discount as a percentage

SELECT b.brand, AVG(f.discount) * 100 AS average_discount
FROM brands AS b
INNER JOIN finance AS f 
    ON b.product_id = f.product_id
GROUP BY b.brand
HAVING b.brand IS NOT NULL
ORDER BY average_discount;


-- Calculate the correlation between reviews and revenue

SELECT corr(r.reviews, f.revenue) AS review_revenue_corr
FROM reviews AS r
INNER JOIN finance AS f 
    ON r.product_id = f.product_id;



-- Calculate description_length
-- Convert rating to a numeric data type and calculate average_rating

SELECT TRUNC(LENGTH(i.description), -2) AS description_length,
    ROUND(AVG(r.rating::numeric), 2) AS average_rating
FROM info AS i
INNER JOIN reviews AS r 
    ON i.product_id = r.product_id
WHERE i.description IS NOT NULL
GROUP BY description_length
ORDER BY description_length;


-- Select brand, month from last_visited, and a count of all products in reviews 

SELECT b.brand, DATE_PART('month', t.last_visited) AS month, COUNT(r.*) AS num_reviews
FROM brands AS b
INNER JOIN traffic AS t 
    ON b.product_id = t.product_id
INNER JOIN reviews AS r 
    ON t.product_id = r.product_id
GROUP BY b.brand, month
HAVING b.brand IS NOT NULL
    AND DATE_PART('month', t.last_visited) IS NOT NULL
ORDER BY b.brand, month;



-- Calculate the number of products and median revenue for footwear products
WITH footwear AS
(SELECT i.description, f.revenue
    FROM info AS i
    INNER JOIN finance AS f 
        ON i.product_id = f.product_id
    WHERE i.description ILIKE '%shoe%'
        OR i.description ILIKE '%trainer%'
        OR i.description ILIKE '%foot%'
        AND i.description IS NOT NULL)

SELECT COUNT(*) AS num_footwear_products, 
    percentile_disc(0.5) WITHIN GROUP (ORDER BY revenue) AS median_footwear_revenue
FROM footwear;



-- Calculate the number of products in info and median revenue from finance

WITH footwear AS
(SELECT i.description, f.revenue
    FROM info AS i
    INNER JOIN finance AS f 
        ON i.product_id = f.product_id
    WHERE i.description ILIKE '%shoe%'
        OR i.description ILIKE '%trainer%'
        OR i.description ILIKE '%foot%'
        AND i.description IS NOT NULL)

SELECT COUNT(i.*) AS num_clothing_products, percentile_disc(0.5) WITHIN GROUP (ORDER BY f.revenue) AS median_clothing_revenue
FROM info AS i
INNER JOIN finance AS f on i.product_id = f.product_id
WHERE i.description NOT IN (SELECT description FROM footwear);


