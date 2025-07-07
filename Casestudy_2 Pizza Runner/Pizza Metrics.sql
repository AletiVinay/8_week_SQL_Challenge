Case Study #2: Pizza runner - Pizza Metrics
Case Study Questions
1.How many pizzas were ordered?
2.How many unique customer orders were made?
3.How many successful orders were delivered by each runner?
4.How many of each type of pizza was delivered?
5.How many Vegetarian and Meatlovers were ordered by each customer?
6.What was the maximum number of pizzas delivered in a single order?
7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
8.How many pizzas were delivered that had both exclusions and extras?
9.What was the total volume of pizzas ordered for each hour of the day?
10.What was the volume of orders for each day of the week?




SET search_path = pizza_runner;

select * from runners
select * from runner_orders
select * from customer_orders
select * from pizza_names
select * from pizza_recipes
select * from pizza_toppings


update runner_orders
set 
   pickup_time = nullif(trim(lower(pickup_time)),'null'),
   distance = nullif(replace(lower(trim(distance)),'km',''),'null'),
   duration =    nullif(
                    replace(
                      replace(lower(trim(duration)),'minutes',''), 
				    'minute',''),
					'null'),
  cancellation = coalesce(nullif(trim(lower(cancellation)),'null'),'Not Cancelled');


  update customer_orders
  set
      exclusions = nullif(trim(lower(exclusions)),'null'),
	  extras = nullif(trim(lower(exclusions)),'null');
			      
							   



-- 1.How many pizzas were ordered?
   select count(*) as order_count from customer_orders
-- How many unique customer orders were made?
   select count(distinct customer_id) as unique_count from customer_orders
-- How many successful orders were delivered by each runner?
   select runner_id,count(*)from runner_orders where cancellation Ilike 'not cancelled'
   group by runner_id   
-- How many of each type of pizza was delivered?
  select count(pizza_id) from customer_orders c join runner_orders r 
  on c.order_id = r.order_id
  where cancellation ilike 'not cancelled'
  group by pizza_id
    
-- How many Vegetarian and Meatlovers were ordered by each customer?
   select customer_id,count(case when pizza_id =1 then 1 else null end) as Meatlovers,
   count(case when pizza_id =2 then 1 else null end) as Vegetarian from customer_orders 
   group by customer_id 
-- What was the maximum number of pizzas delivered in a single order?
  select max(pizza_count) from  (select c.order_id,count(customer_id) as pizza_count from customer_orders c join runner_orders r on c.order_id=r.order_id
   where cancellation  ilike 'not cancelled'
   group by c.order_id
   order by order_id) as Max_single_order
   
-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
   
   select customer_id,
   sum(case  when exclusions  is not null or extras is not null then 1 else 0 end) as change,
   sum(case  when exclusions is null and extras is null then 1 else 0 end) as No_change
   from customer_orders c  join  runner_orders r on c.order_id=r.order_id
   where cancellation is null
   group by customer_id

-- How many pizzas were delivered that had both exclusions and extras?
   select customer_id,sum(case when exclusions is not null and extras is not null then 1 else 0 end) from customer_orders c join runner_orders r on c.order_id = r.order_id
   where cancellation is null
   group by customer_id
   order by customer_id

-- What was the total volume of pizzas ordered for each hour of the day?
   select extract(hour from order_time) as pizza_hour,count(order_id) as order_count,
   round(100*count(order_id)/sum(count(order_id)) over(),2) as volume_pizze_ordered 
   from customer_orders
   group by 1
   order by 1
   
-- What was the volume of orders for each day of the week?
   select TO_CHAR(order_time,'Day') as pizza_hour,count(order_id) as order_count,
   round(100*count(order_id)/sum(count(order_id)) over(),2) as volume_pizze_ordered 
   from customer_orders
   group by 1
   order by 2 