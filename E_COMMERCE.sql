--CREATING TABLES AND IMPORTING DATA

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

CREATE TABLE geo_location (
    geolocation_zip_code_prefix INT NOT NULL,
    geolocation_lat DOUBLE PRECISION NOT NULL,
    geolocation_lng DOUBLE PRECISION NOT NULL,
    geolocation_city VARCHAR(100) NOT NULL,
    geolocation_state CHAR(2) NOT NULL
);

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm NUMERIC(10,2),
    product_height_cm NUMERIC(10,2),
    product_width_cm NUMERIC(10,2)
);

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    order_status VARCHAR(20),
    order_purchase_timestamp TEXT,
    order_approved_at TEXT,
    order_delivered_carrier_date TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT,

    CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id VARCHAR(50) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    seller_id VARCHAR(50) NOT NULL,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10,2),
    freight_value NUMERIC(10,2),

    PRIMARY KEY(order_id, order_item_id),

    CONSTRAINT fk_items_order
    FOREIGN KEY(order_id)
    REFERENCES orders(order_id),

    CONSTRAINT fk_items_product
    FOREIGN KEY(product_id)
    REFERENCES products(product_id),

    CONSTRAINT fk_items_seller
    FOREIGN KEY(seller_id)
    REFERENCES sellers(seller_id)
);

CREATE TABLE order_payments (
    order_id VARCHAR(50) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(30) NOT NULL,
    payment_installments INT NOT NULL,
    payment_value NUMERIC(10,2) NOT NULL,

    PRIMARY KEY(order_id,payment_sequential),

    CONSTRAINT fk_payment_order
    FOREIGN KEY(order_id)
    REFERENCES orders(order_id)
);

CREATE TABLE order_reviews (
    review_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    review_score INT NOT NULL,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TEXT,
    review_answer_timestamp TEXT,

    CONSTRAINT fk_review_order
    FOREIGN KEY(order_id)
    REFERENCES orders(order_id)
);

CREATE TABLE product_category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100) NOT NULL
);

--converting some needed column's datatype from text to time stamp.
ALTER TABLE orders
ALTER COLUMN order_purchase_timestamp
TYPE TIMESTAMP
USING order_purchase_timestamp::TIMESTAMP;

ALTER TABLE orders
ALTER COLUMN order_approved_at
TYPE TIMESTAMP
USING order_approved_at::TIMESTAMP;

ALTER TABLE orders
ALTER COLUMN order_delivered_carrier_date
TYPE TIMESTAMP
USING order_delivered_carrier_date::TIMESTAMP;

ALTER TABLE orders
ALTER COLUMN order_delivered_customer_date
TYPE TIMESTAMP
USING order_delivered_customer_date::TIMESTAMP;

ALTER TABLE orders
ALTER COLUMN order_estimated_delivery_date
TYPE TIMESTAMP
USING order_estimated_delivery_date::TIMESTAMP;

-- BASIC EXPLORATION

SELECT COUNT(*) FROM orders;

SELECT COUNT(*) FROM customers;

SELECT DISTINCT order_status
FROM orders;

SELECT DISTINCT payment_type
FROM order_payments;

-- BUSINESS QUESTIONS 

--1...Total orders, customers, sellers and products.
select
	(select count(*) from customers) as total_customers,
	(select count(*) from orders)as total_orders,
	(select count(*) from sellers) as total_sellers,
	(select count(*) from products) as total_products;

--2...List all unique order statuses.
select DISTINCT(order_status) from orders;

--3...Count the number of orders for each order status , highest to lowest.
SELECT order_status, COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

--4...Find the Top 10 most expensive product listings sold in the dataset.
select p.product_id , o.price 
from order_items as o 
join products as p 
on o.product_id = p.product_id
order by o.price desc
limit 10 ;

--5...Find products with missing categories.
select product_id from products
where product_category_name is NULL;

--6...Find the highest and lowest freight charges.
select
max(freight_value) as highest_freight_value ,
min(freight_value) as lowest_freight_value from order_items;

--7...Count how many payment methods exist.
select count(distinct(payment_type)) as payment_methods_count from order_payments;

--8...Find the date range of orders.
SELECT
    MIN(order_purchase_timestamp) AS first_order_date,
    MAX(order_purchase_timestamp) AS last_order_date
FROM orders;

--9...Number of orders by status.
select count(order_id) , order_status from orders
group by order_status ;

--10...Number of products in each category.
select count(product_id) , product_category_name from products
group by product_category_name;

--11...How many reviews are there for each review score (1–5)?
select count(review_id),review_score
from order_reviews
group by review_score
order by review_score asc;

--12...Payment type distribution.
select payment_type , count(*) as number_of_payments
from order_payments
group by payment_type;


--13...Categories having more than X products.
select  product_category_name , count(product_id) as total_products from products
group by product_category_name 
having count(product_id) > 25;

--14...Sellers having more than X orders.
select seller_id , count(order_id) as total_orders from order_items
group by seller_id
having count(order_id) > 25
order by count(order_id) desc;

--15...Average freight cost by seller.
select seller_id , round(avg(freight_value),3)
from order_items
group by seller_id
order by avg(freight_value);

--16...Display order with customer city.
select o.order_id , c.customer_city 
from orders as o
join customers as c
on o.customer_id = c.customer_id ;

--17...display order , customer city and seller's city.
select o.order_id , c.customer_city , s.seller_city
from orders as o
join customers as c  
on o.customer_id = c.customer_id 
join order_items as a
on o.order_id = a.order_id
join sellers as s
on a.seller_id = s.seller_id;

--18...Display products with English category names.
select p.product_id, o.product_category_name_english from products as p
join product_category_translation as o
on p.product_category_name = o.product_category_name;

--19...Revenue generated by each seller.
select seller_id , sum(price)
from order_items
group by seller_id 
order by sum(price) desc;

--20...Total amount paid for each order.
select order_id , sum(payment_value) as total_pay
from order_payments
group by order_id
order by total_pay desc;

--21...Orders without reviews.
select o.order_id , r.review_score
from orders as o
left join order_reviews as r
on o.order_id = r.order_id
where r.review_score is null;

--22...Customer location for each order.
select order_id , customer_state , customer_city 
from customers as c 
join orders as o 
on c.customer_id = o.customer_id ;

--23...Top selling product categories.
select t.product_category_name, count(o.order_id)
from order_items as o  
join products as p
on o.product_id = p.product_id
join product_category_translation as t
on p.product_category_name = t.product_category_name 
group by t.product_category_name 
order by count(order_id) desc
limit 5;

--24...Top 10 customers by spending.
select c.customer_id , sum(a.payment_value)
from customers as c
join orders as o
on c.customer_id = o.customer_id
join order_payments as a
on o.order_id = a.order_id 
group by c.customer_id
order by sum(a.payment_value) desc
limit 10;

--25...Monthly revenue trend.
select extract(MONTH FROM o.order_purchase_timestamp) , sum(p.payment_value)
from orders as o 
join order_payments as p
on o.order_id = p.order_id
group by extract(MONTH FROM order_purchase_timestamp);

--26...Average delivery time by state.
select c.customer_state , 
round(avg(o.order_delivered_customer_date::Date - o.order_purchase_timestamp::Date),2) as delivery_time
from customers as c
join orders as o
on c.customer_id = o.customer_id
where o.order_delivered_customer_date is not null
group by c.customer_state
order by delivery_time desc;

--27...Classify reviews as Good/Average/Bad.
select review_score , case 
when review_score between 4 and 5 then 'good'
when review_score = 3 then 'average'
when  review_score between 1 and 2 then 'bad'
end as reviews
from order_reviews;

--28...Classify orders as Early/On Time/Late.
select order_delivered_customer_date , order_estimated_delivery_date , case
when order_delivered_customer_date >
    order_estimated_delivery_date  then 'late'
when order_delivered_customer_date <
    order_estimated_delivery_date then 'early'
when order_delivered_customer_date =
    order_estimated_delivery_date then 'on time'
end as delivery_service
from orders ; 

--29...Weekend vs Weekday orders.
with wkdays_vs_wkends as (
select case
when extract(DOW from order_purchase_timestamp) in (0,6) then 'weekend'
else 'weekday'
end as wkdays_vs_wkends from orders
)

select distinct(wkdays_vs_wkends) , count(*) as total_orders from  wkdays_vs_wkends
group by wkdays_vs_wkends;

--30...Products priced above overall average.
select product_id , price from order_items 
where price > (select avg(price) from order_items);

--31...Sellers earning above average revenue.
select seller_id, sum(price) as seller_revenue
from order_items
group by seller_id
having sum(price) >(
select avg(revenue)
from(
select sum(price) as revenue
from order_items
group by seller_id) as x
);

--32...Customers spending above average.
select c.customer_id , sum(p.payment_value) from customers as c
join orders as o
on c.customer_id = o.customer_id
join order_payments as p 
on o.order_id = p.order_id
group by c.customer_id
having sum(p.payment_value) > (select avg(x) from (select sum(p.payment_value) as x
	from order_payments as p 
	join orders as o 
	on p.order_id = o.order_id
	group by o.customer_id));

--33...Top 5 customers in each state.
WITH customer_spending AS (
    SELECT
        c.customer_id,
        c.customer_state,
        SUM(p.payment_value) AS total_spending
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_payments p
        ON o.order_id = p.order_id
    GROUP BY
        c.customer_id,
        c.customer_state
),

ranked_customers AS (
    SELECT
        customer_id,
        customer_state,
        total_spending,
        ROW_NUMBER() OVER(
            PARTITION BY customer_state
            ORDER BY total_spending DESC
        ) AS rn
    FROM customer_spending
)

SELECT
    customer_id,
    customer_state,
    total_spending
FROM ranked_customers
WHERE rn <= 5
ORDER BY
    customer_state,
    total_spending DESC;

--34...Monthly revenue with running growth
WITH monthly_revenue AS(
SELECT DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
SUM(p.payment_value) AS revenue
FROM orders o
JOIN order_payments p
ON o.order_id = p.order_id
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp))

SELECT month, revenue,SUM(revenue) OVER(
ORDER BY month) AS running_revenue
FROM monthly_revenue
ORDER BY month;

--35...Top category of every state
with category_sales as(
select c.customer_state,
p.product_category_name,
sum(oi.price) as revenue
from customers c
join orders o on c.customer_id=o.customer_id
join order_items oi on o.order_id=oi.order_id
join products p on oi.product_id=p.product_id
group by c.customer_state,p.product_category_name
),

ranked as(
select *,
rank() over(partition by customer_state order by revenue desc) as rnk
from category_sales
)

select customer_state,product_category_name,revenue
from ranked
where rnk=1;

--36...Rank sellers by revenue
select s.seller_id,
sum(oi.price) as revenue,
rank() over(order by sum(oi.price) desc) as seller_rank
from sellers s
join order_items oi on s.seller_id=oi.seller_id
group by s.seller_id;

--37...Rank products inside each category
select p.product_category_name,
p.product_id,
sum(oi.price) as revenue,
rank() over(partition by p.product_category_name order by sum(oi.price) desc) as product_rank
from products p
join order_items oi on p.product_id=oi.product_id
group by p.product_category_name,p.product_id;

--38...Running monthly revenue
with monthly_sales as(
select date_trunc('month',o.order_purchase_timestamp) as month,
sum(oi.price) as revenue
from orders o
join order_items oi on o.order_id=oi.order_id
group by month
)
select month,
revenue,
sum(revenue) over(order by month) as running_revenue
from monthly_sales;

--39...Month-over-month revenue growth
with monthly_sales as(
select date_trunc('month',o.order_purchase_timestamp) as month,
sum(oi.price) as revenue
from orders o
join order_items oi on o.order_id=oi.order_id
group by month
)
select month,
revenue,
lag(revenue) over(order by month) as previous_month,
revenue-lag(revenue) over(order by month) as growth
from monthly_sales;

--40...Top 3 products of every category
with ranked as(
select p.product_category_name,
p.product_id,
sum(oi.price) as revenue,
row_number() over(partition by p.product_category_name order by sum(oi.price) desc) as rn
from products p
join order_items oi on p.product_id=oi.product_id
group by p.product_category_name,p.product_id
)
select product_category_name,product_id,revenue
from ranked
where rn<=3;

--41...Top 5 customers of every state
with customer_sales as(
select c.customer_state,
c.customer_unique_id,
sum(oi.price) as spending
from customers c
join orders o on c.customer_id=o.customer_id
join order_items oi on o.order_id=oi.order_id
group by c.customer_state,c.customer_unique_id
),
ranked as(
select *,
row_number() over(partition by customer_state order by spending desc) as rn
from customer_sales
)
select customer_state,customer_unique_id,spending
from ranked
where rn<=5;

--42...Create a sales summary view
create view sales_summary as
select date_trunc('month',o.order_purchase_timestamp) as month,
count(distinct o.order_id) as total_orders,
count(distinct o.customer_id) as total_customers,
sum(oi.price) as revenue,
avg(oi.price) as average_order_value
from orders o
join order_items oi on o.order_id=oi.order_id
group by month;

--43...Find repeat customers with increasing spending
with customer_monthly as(
select o.customer_id,
date_trunc('month',o.order_purchase_timestamp) as month,
sum(oi.price) as spending
from orders o
join order_items oi
on o.order_id=oi.order_id
group by o.customer_id,month
),

customer_growth as(
select customer_id,
month,
spending,
lag(spending) over(partition by customer_id order by month) as previous_spending
from customer_monthly
)

select customer_id,
month,
spending,
previous_spending
from customer_growth
where spending>previous_spending;

--44...Customer segmentation report
with customer_sales as(
select o.customer_id,
sum(oi.price) as spending
from orders o
join order_items oi on o.order_id=oi.order_id
group by o.customer_id
)
select customer_id,
spending,
case
when spending>=5000 then 'high value'
when spending>=2000 then 'medium value'
else 'low value'
end as segment
from customer_sales;

--45...Executive sales report
with monthly_sales as(
select date_trunc('month',o.order_purchase_timestamp) as month,
sum(oi.price) as revenue,
count(distinct o.order_id) as total_orders,
count(distinct o.customer_id) as total_customers
from orders o
join order_items oi on o.order_id=oi.order_id
group by month
),
final_report as(
select *,
lag(revenue) over(order by month) as previous_revenue,
sum(revenue) over(order by month) as running_revenue
from monthly_sales
)
select month,
total_orders,
total_customers,
revenue,
previous_revenue,
revenue-previous_revenue as revenue_growth,
running_revenue
from final_report
order by month;


