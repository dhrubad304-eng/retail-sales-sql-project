-- CREATING THE TABLES 
CREATE TABLE category (
    category_id VARCHAR(10) PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL
);


CREATE TABLE products (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category_id VARCHAR(10) NOT NULL,
    launch_date DATE,
    price NUMERIC(10,2),
    FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE RESTRICT
);


CREATE TABLE stores (
    store_id VARCHAR(10) PRIMARY KEY,
    store_name VARCHAR(150) NOT NULL,
    city VARCHAR(100),
    country VARCHAR(100)
);


CREATE TABLE sales (
    sale_id VARCHAR(15) PRIMARY KEY,
    sale_date DATE NOT NULL,
    store_id VARCHAR(10) NOT NULL,
    product_id VARCHAR(10) NOT NULL,
    quantity INT CHECK (quantity > 0),
    FOREIGN KEY (store_id) REFERENCES stores(store_id) ON DELETE RESTRICT,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
);


CREATE TABLE warranty (
    claim_id VARCHAR(10) PRIMARY KEY,
    claim_date DATE NOT NULL,
    sale_id VARCHAR(15),
    repair_status VARCHAR(50),
    FOREIGN KEY (sale_id) REFERENCES sales(sale_id) ON DELETE SET NULL
);



-- EDA 
SELECT * FROM category;
SELECT * FROM products;
SELECT * FROM sales;
SELECT * FROM stores;
select * FROM warranty;

--COUNTING THE ROWS 
SELECT COUNT(*) category;
SELECT COUNT(*) products;
SELECT COUNT(*) sales;
SELECT COUNT(*) stores;
SELECT COUNT(*) warranty;


-------------------------
-- ANALYSIS --
--------------------------

-- Q1. Total sales quantity and total revenue per product

SELECT 
p.product_id,
p.product_name,
SUM(s.quantity) AS total_quantity_sold,
SUM(s.quantity * p.price) AS total_revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC;


--Q.2 Total Sales Per Store

SELECT
st.store_name,
st.city,
st.country,
SUM(s.quantity) AS total_sold
FROM stores AS st
JOIN sales AS S 
ON st.store_id = s.store_id
GROUP BY 1,2,3
ORDER BY total_sold;

-- Q.3 Number of products launched per category

SELECT 
c.category_name,
COUNT(p.product_id) AS total_products
FROM products AS p
JOIN category AS c
ON c.category_id = p.category_id
GROUP BY c.category_name
ORDER BY total_products DESC;

-- Q.4 Average product price per category

SELECT 
p.product_name,
SUM(s.quantity) AS sales_count
FROM products AS p
JOIN sales AS s 
on p.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- Q.5 Top 3 stores by total sales revenue

SELECT 
st.store_name,
SUM (p.price * s.quantity) AS revenue
FROM products AS P
JOIN sales AS s 
ON p.product_id  = s.product_id
JOIN stores AS st
ON st.store_id = s.store_id
GROUP BY 1 
ORDER BY 2 DESC
LIMIT 3;

-- Q.6 Category with most warranty issues

SELECT 
c.category_name,
COUNT(w.claim_id) AS total_count
FROM warranty AS w
JOIN sales AS s
ON w.sale_id = s.sale_id
JOIN products AS p
ON p.product_id = s.product_id
JOIN category AS C
ON p.category_id = c.category_id
GROUP BY 1 
ORDER BY 2 DESC;

-- Q.10 Average time gap between sale and warranty claim

SELECT 
ROUND(AVG(w.claim_date - s.sale_date),2) as avg_time_gap
FROM sales AS s
JOIN warranty AS w 
ON w.sale_id = s.sale_id

-- Q.11 Year-over-year growth in total sales

WITH yearly_sales AS(
SELECT 
EXTRACT(YEAR FROM s.sale_date) AS sales_year,
SUM (p.price * s.quantity) AS total_sales
FROM products as p
JOIN sales AS s
ON 
p.product_id = s.product_id
GROUP BY 1)
SELECT sales_year,
total_sales,
ROUND
((total_sales - LAG(total_sales) OVER(ORDER BY sales_year))/
LAG(total_sales) OVER(ORDER BY sales_year) * 100,2) AS YOY_growth_percentaage
FROM yearly_sales
ORDER BY sales_year DESC;

-- Q.12 Top 3 product categories per store by revenue

WITH store_category_revenue AS (
SELECT
st.store_name,
c.category_name,
SUM(p.price * s.quantity) AS revenue
FROM sales AS s
JOIN products AS p
ON s.product_id = p.product_id
JOIN category AS c
ON p.category_id = c.category_id
JOIN stores AS st
ON s.store_id = st.store_id
GROUP BY st.store_name, c.category_name
),
ranked_categories AS (
SELECT
store_name,
category_name,
revenue,
ROW_NUMBER() OVER (PARTITION BY store_name ORDER BY revenue DESC) AS rank
FROM store_category_revenue
)
SELECT
store_name,
category_name,
revenue
FROM ranked_categories
WHERE rank <= 3
ORDER BY store_name, revenue DESC;

-- Q.14 Store Performance Analysis Including Warranty Impact

WITH category_store_sales AS(
SELECT
c.category_name,
st.store_name,
SUM(p.price*s.quantity) AS total_sales
FROM sales AS s
JOIN products AS p ON p.product_id=s.product_id
JOIN category AS c ON c.category_id=p.category_id
JOIN stores AS st ON st.store_id=s.store_id
GROUP BY c.category_name,st.store_name
),
ranked AS(
SELECT
category_name,
store_name,
total_sales,
RANK()OVER(PARTITION BY category_name ORDER BY total_sales DESC) AS rnk
FROM category_store_sales
)
SELECT
category_name,
store_name,
total_sales
FROM ranked
WHERE rnk=1
ORDER BY total_sales DESC;

/* Q.15 Identify the top 5 countries generating the highest total revenue, 
but only from products whose price is above the overall average product price. */

WITH avg_price AS (
SELECT AVG(price) AS overall_avg
FROM products
),
expensive_products AS (
SELECT p.product_id, p.price
FROM products AS p
JOIN avg_price AS a ON p.price > a.overall_avg
),
country_revenue AS (
SELECT
st.country,
SUM(s.quantity * p.price) AS total_revenue
FROM sales AS s
JOIN expensive_products AS ep ON ep.product_id=s.product_id
JOIN products AS p ON p.product_id=ep.product_id
JOIN stores AS st ON st.store_id=s.store_id
GROUP BY st.country
)
SELECT
country,
total_revenue
FROM country_revenue
ORDER BY total_revenue DESC
LIMIT 5;



