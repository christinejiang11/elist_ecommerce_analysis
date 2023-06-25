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
