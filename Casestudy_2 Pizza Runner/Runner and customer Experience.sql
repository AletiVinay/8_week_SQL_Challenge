select * from runners
select * from runner_orders
select * from customer_orders
select * from pizza_names
select * from pizza_recipes
select * from pizza_toppings


SET search_path = pizza_runner;

--(B. Runner and Customer Experience)
-- 1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
   SELECT
  ((registration_date - DATE '2021-01-01')/7) AS week_number,
  COUNT(*) AS runners_signed_up
FROM runners
GROUP BY week_number
ORDER BY week_number;

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
   select runner_id,round(avg(extract(epoch from (pickup_time :: timestamp - order_time))/60),2) from customer_orders c join runner_orders r 
   on c.order_id = r.order_id
   where cancellation is null and pickup_time is not null
   group by runner_id
   
   select * from customer_orders c join runner_orders r on c.order_id = r.order_id

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
   select c.order_id,count(pizza_id),sum(pickup_time::timestamp-order_time) as time_gap from customer_orders c join runner_orders r on c.order_id = r.order_id 
   where pickup_time is not null
   group by 1
   order by 1
    
   
-- What was the average distance travelled for each customer?

   select customer_id,concat(round(avg(distance::numeric),2),'km') as dis_travelled 
   from customer_orders c join runner_orders r 
   on c.order_id=r.order_id
   group by 1
   order by 1
   
-- What was the difference between the longest and shortest delivery times for all orders?
   select max(duration) || 'Min' as max_delivery_time,min(duration) || 'Min' as min_delivery_time, (max(duration)-min(duration))||'Min' delivery_diff_time 
   from customer_orders c join runner_orders r using(order_id)

  
-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
     
	 select runner_id,c.order_id,round(avg(60*(replace(distance,'km','')::numeric)/(duration)),2)
	 from customer_orders c join runner_orders r on c.order_id = r.order_id
	 where cancellation is null
	 group by 1,2
	 order by 1,2
	 
-- What is the successful delivery percentage for each runner?
  select runner_id,count(pickup_time),count(*),round(100*count(pickup_time)/count(*),2)  as delivery_percentage from runner_orders
  group by 1
  order by 1