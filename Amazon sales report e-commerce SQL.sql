select count(*) from amazon_sales_report.shipping;
SELECT * FROM amazon_sales_report.sales;
set global default_mode=non-strict;
set sql_mode = '';


-- To explore the dataset, find the number of distinct cities
select count(distinct shipcity) as total_distinct_cities from shipping;

-- The sales team would like to strategize based on performance.
-- Provide the date that the most complete sales occured on.
-- Filter on the condition where the status is shipped and delivered.
select date, amountofsale from sales where amountofsale = (
select max(amountofsale) from sales
where status = 'Shipped - Delivered to Buyer');

-- The logistics team are interested in knowing the top 5 cities with most packages shipped, 
-- to ensure efficient delivery to high-demand areas.
-- Provide the total sales for each city in descending order.
-- Filter on 'Shipped' packages only.
create view city_sales as
select shipcity, sum(amountofsale) as total_sales from sales as s
left join shipping as sh
on s.index = sh.index
where courierstatus = 'Shipped'
group by ShipCity
order by sum(amountofsale) desc
LIMIT 5;

-- The inventory management team require a rank of the most to least shipped category,
-- to optimise stock levels and ensure adequate supply of the most popular categories.
-- filter on 'Shipped' 
SELECT 
RANK () OVER (ORDER BY sum(Qty) DESC) as quantity_rank, sum(Qty) as total_quantity, category
FROM product as p
LEFT JOIN shipping AS sh
ON p.index = sh.index
where courierstatus = 'Shipped'
group by category;

-- The sales team would like the track performance over time and in different sates
-- Provide the summed amount of sale partiitioned by date and state.
-- Filter on all packages except 'Cancelled'
-- Create this as a view for the business intelligence team to identify trends and help make actionable insights.
create view partitioned_sales as(
select s.date, sh.shipstate, sum(s.amountofsale) over (partition by s.date, sh.shipstate) as state_date_sum
from sales as s
left join shipping as sh
on sh.index = s.index
where status <> 'Cancelled'
order by state_date_sum desc);

-- The marketing team reqire the most popular category for each state to target their promotional efforts effectively and maximise sales oppertunities.
-- Provide the most popular category for each state.
with popular_categories as (
select p.category, sh.shipstate, count(*) as category_count,
row_number()over(partition by sh.shipstate order by count(*)desc) as category_rank
from product as p
left join shipping as sh
on sh.index = p.index
group by sh.shipstate, p.category
)
select pc.shipstate, pc.category as most_popular_category
from popular_categories as pc
where pc.category_rank = 1;


-- Explore the international sales dataset
-- The sales team are interested in the gross sales amount of each customer descending order
-- to tailor their approach and strengthen customer relationships.
-- Group all customer sales by name and order by descending order (most sales to least sales) per customer.
create view international_customersales as (
select customer, sum(gross_sales_amount) as gross_sales from international_sales
group by customer
order by gross_sales desc);

-- The sales team require the sum of sales per month to identify trends and drive growth.
-- The marketing team require this data to plan targeted promotions to maximise sales in peak seasons.
-- Produce the sum of sales per month in descending order.
select month(date) as month, round(sum(amountofsale),2) as sum_saleamount
from sales
group by month
having month IS NOT NULL
order by sum_saleamount desc;

-- The sales team aim to maximise back-to-back sales through repeat business and upselling.
-- The marketing team aim to encourage customer loyalty.
-- Filter for all back-to-back sales and segment each sale
-- Sales above the average amount result in 'Loyal' whereas below the average are 'Regular' sales
SELECT *,
case when amountofsale > 640.5 THEN 'Loyal'
When amountofsale <= 640.5 THEN 'Regular'
End as B2B_segmentation
FROM amazon_sales_report.sales
where b2bsale = 'True';
