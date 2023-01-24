#Raw Capita Data: state, pop
#Raw Customers Data: cust_id, state
 
CREATE TABLE dim.customers AS (

SELECT
  customers.cust_id
  ,customers.state
  ,capita.pop
FROM raw.customers
  LEFT JOIN raw.capita ON customers.state = capita.state
 )
  
 #Dim Customer Data: cust_id, state, pop
 #Raw Orders Data: order_id, cust_id, type, date, price, qty
 
 CREATE TABLE dim.orders AS (
 SELECT
  orders.order_id
  ,orders.cust_id
  ,orders.type
  ,orders.date
  ,orders.price
  ,orders.qty
  ,customers.state
  ,customers.pop
FROM raw.orders
  LEFT JOIN dim.customers ON orders.cust_id = customers.cust_id
)

#Perform row counts, null handling, data types, invalid data, etc. to then include any cleaning transformations on this table level.

#Dim Orders will now be divided into two materialized views that will be loaded into the reporting dashboard with required indexing and ordering steps performed to increase speed, 
#like keeping duplicate state data near each other with the qty numbers used for ORDER or SORT DESC

#Top Seller Materialized View

CREATE MATERIALIZED VIEW top_seller AS (
SELECT
  sum(qty) as total
  ,type
  ,state
FROM dim.orders
ORDER BY total, state DESC
)

CREATE INDEX top_seller_state_idx ON top_seller (state);

#Last Year Materialized View

CREATE MATERIALIZED VIEW last_year AS (
SELECT
  sum(qty) as total
  ,sum(price) as usd
  ,(sum(price)/pop) * 100000 as capita
  ,count(distinct cust_id) as customers
  ,type
  ,state
FROM dim.orders
WHERE date >= DATEADD(month,-12,GETDATE())
ORDER BY total, state DESC
)

CREATE INDEX last_year_state_idx ON last_year (state);


#Reporting queries
#State is selected in drop down and populates the WHERE queries below:
#Question 1:

SELECT
  total
  ,type
FROM top_seller
WHERE state = [selected state]
LIMIT 3
#WITH(INDEX(top_seller_state_idx))

#Question 2
SELECT
  total
  ,type
FROM last_year
WHERE state = [selected state]
#WITH(INDEX(last_year_state_idx))

#Question 3
SELECT
  usd
  ,type
FROM last_year
WHERE state = [selected state]
#WITH(INDEX(last_year_state_idx))

#Question 4
SELECT
  capita
  ,type
FROM last_year
WHERE state = [selected state]
#WITH(INDEX(last_year_state_idx))

#Question 5
SELECT
  customers
  ,type
FROM last_year
WHERE state = [selected state]
#WITH(INDEX(last_year_state_idx))

