--OVERALL SALES TRENDS
--start with a simple warm-up query: get order count, total, sales, and aov by quarter
select date_trunc(purchase_ts, quarter) as purchase_month,
  count(distinct id) as order_count,
  sum(usd_price) as total_sales,
  avg(usd_price) as aov
from elist.orders
group by 1
order by 1

--take the last query and group by region: join to customers table, then join to geo lookup table
select date_trunc(orders.purchase_ts, quarter) as purchase_month,
  geo_lookup.region,
  count(distinct orders.id) as order_count,
  sum(orders.usd_price) as total_sales,
  avg(orders.usd_price) as aov
from elist.orders
left join elist.customers
  on orders.customer_id = customers.id
left join elist.geo_lookup
  on customers.country_code = geo_lookup.country
group by 1,2
order by 1,2

--now bring the product into the grouping, and clean up the product name
select date_trunc(orders.purchase_ts, quarter) as purchase_month,
  geo_lookup.region,
  case when orders.product_name = '27in"" 4k gaming monitor' then '27in 4K gaming monitor' else orders.product_name end as product_clean,
  count(distinct orders.id) as order_count,
  sum(orders.usd_price) as total_sales,
  avg(orders.usd_price) as aov
from elist.orders
left join elist.customers
  on orders.customer_id = customers.id
left join elist.geo_lookup
  on customers.country_code = geo_lookup.country
group by 1,2,3
order by 1,2,2

--count the number of refunds per month (non-null refund date) and calculate the refund rate
--refund rate is equal to the total number of refunds divided by the total number of orders
select date_trunc(orders.purchase_ts, month) as month,
    sum(case when refund_ts is not null then 1 else 0 end) as refunds,
    sum(case when refund_ts is not null then 1 else 0 end)/count(distinct orders.id) as refund_rate
from elist.orders
left join elist.order_status
    on orders.id = order_status.id
group by 1
order by 1;

--REFUND ANALYSIS
--count the number of refunds, filtered to 2021
--only include products with 'apple' in the name - use lowercase to account for any differences in capitalization
select date_trunc(order_status.refund_ts, month) as month,
    sum(case when order_status.refund_ts is not null then 1 else 0 end) as refunds
from elist.orders
left join elist.order_status
    on orders.id = order_status.id
where extract(year from order_status.refund_ts) = 2021
and lower(product_name) like '%apple%'
group by 1
order by 1;

--count the number of refunds per month (non-null refund date) and calculate the refund rate
--refund rate is equal to the total number of refunds divided by the total number of orders
select date_trunc(orders.purchase_ts, month) as month,
    sum(case when refund_ts is not null then 1 else 0 end) as refunds,
    sum(case when refund_ts is not null then 1 else 0 end)/count(distinct orders.id) as refund_rate
from elist.orders
left join elist.order_status
    on orders.id = order_status.id
group by 1
order by 1;

--count the number of refunds, filtered to 2021
--only include products with 'apple' in the name - use lowercase to account for any differences in capitalization
select date_trunc(order_status.refund_ts, month) as month,
    sum(case when order_status.refund_ts is not null then 1 else 0 end) as refunds
from elist.orders
left join elist.order_status
    on orders.id = order_status.id
where extract(year from order_status.refund_ts) = 2021
and lower(product_name) like '%apple%'
group by 1
order by 1;

--AOV
--aov and count of new customers by account creation channel in first 2 months of 2022
select customers.account_creation_method,
  avg(usd_price) as aov,
	count(distinct customers.id) as num_customers
from elist.orders
left join elist.customers
on orders.customer_id = customers.id
where created_on between '2022-01-01' and '2022-02-28'
group by 1
order by 3 desc;

--DAYS TO PURCHASE
--calculate days to purchase by taking date difference
--take the average of the number of days to purchase
with days_to_purchase_cte as (
    select customers.id as customer_id, 
    orders.id as order_id,
    customers.created_on,
    orders.purchase_ts, 
    date_diff(orders.purchase_ts, customers.created_on,day) as days_to_purchase
from elist.customers
left join elist.orders
    on customers.id = orders.customer_id
order by 1,2,3)

select avg(days_to_purchase) from days_to_purchase_cte;

--REGISTRATION CHANNELS
--calculate the total number of orders and total sales by region and registration channel
--rank the channels by total sales, and order the dataset by this ranking to surface the top channels per region first
with region_orders as (
    select geo_lookup.region, 
    customers.account_creation_method,
    count(distinct orders.id) as num_orders, 
    sum(orders.usd_price) as total_sales,
    avg(orders.usd_price) as aov
from elist.orders
left join elist.customers
    on orders.customer_id = customers.id
left join elist.geo_lookup
    on customers.country_code = geo_lookup.country
group by 1,2
order by 1,2)

select *, row_number() over (partition by region order by num_orders desc) as ranking
from region_orders
order by 6 asc
