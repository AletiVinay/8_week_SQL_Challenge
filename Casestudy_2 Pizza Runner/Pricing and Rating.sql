select * from runners
select * from runner_orders
select * from customer_orders
select * from pizza_names
select * from pizza_recipes
select * from pizza_toppings
select c.order_id,runner_id,pizza_id,cancellation from customer_orders c join runner_orders r on c.order_id=r.order_id

SET search_path = pizza_runner;

-- 1.If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far 
-- if there are no delivery fees?
select r.runner_id,sum(case when pizza_name = 'Meatlovers'  then 12 else 10 end) as pizza_amount from runner_orders r 
join customer_orders c on r.order_id = c.order_id 
join pizza_names pn  on pn.pizza_id = c.pizza_id
where cancellation is null
group by r.runner_id
order by r.runner_id

-- 2.What if there was an additional $1 charge for any pizza extras?
--   Add cheese is $1 extra
with cheese as(
select order_id,pizza_id,extras_id,topping_name from (
select order_id,pizza_id,unnest(string_to_array(extras,','))::int as extras_id from customer_orders co
where extras is not null
) t
join pizza_toppings pt on t.extras_id=pt.topping_id
where pt.topping_name = 'Cheese'
),

counts as (
select order_id,count(*) as cheese_count from cheese
group by order_id
),
order_pieces as(
select co.order_id,co.pizza_id,r.runner_id,coalesce(cheese_count,0),
case 
    when pn.pizza_name = 'Meatlovers' then 12+coalesce(cheese_count,0)
	when pn.pizza_name = 'Vegetarian' then 10+coalesce(cheese_count,0)
    else 0
end as amount
from customer_orders co 
join runner_orders r on co.order_id=r.order_id
join pizza_names pn on pn.pizza_id = co.pizza_id
left join counts c on c.order_id = co.order_id
)
select runner_id,sum(amount) from order_pieces
group by runner_id
order by runner_id
   
-- 3.The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this
--   new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
create table runner_ratings
(order_id int,rating int, review varchar(100))  

insert into runner_ratings values
('1','3','Average service'),
('2','2',null),
('3','1','poor delivery'),
('4','5','Excellent Service'),
('5','5','Fast and on time delivery'),
('6','3','ok ok'),
('7','4','good service in reached in given time'),
('8','1','atitiude issue and tossed at door steps'),
('9','5','Excellent delivered it sonner than expected'),
('10','4','Nice service')

select * from runner_ratings


-- 4.Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
--  customer_id
--  order_id
--  runner_id
--  rating
--  order_time
--  pickup_time
--  Time between order and pickup
--  Delivery duration
--  Average speed
--  Total number of pizzas

update runner_orders 
set distance = replace(distance,'km','')


with total_no_of_pizzas as(
select order_id,count(pizza_id) as pizza_count from customer_orders
group by order_id
) 


select customer_id,c.order_id,r.runner_id,rating,order_time,pickup_time, round(EXTRACT(EPOCH FROM (r.pickup_time::timestamp - c.order_time)) / 60,2) AS time_to_pickup,duration,round((distance::numeric*60/duration),2) as avg_speed,pizza_count
from customer_orders c 
join runner_orders r on c.order_id=r.order_id 
join runner_ratings rr on rr.order_id=c.order_id
join total_no_of_pizzas as tnop on tnop.order_id=c.order_id
where cancellation is null


-- 5.If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - 
--   how much money does Pizza Runner have left over after these deliveries?
with pizza_amount as (
select r.runner_id,
sum(case 
when pizza_name = 'Meatlovers' then 12 
when pizza_name = 'Vegetarian' then 10
else 0
end) as amount from customer_orders c
join pizza_names pn on c.pizza_id=pn.pizza_id
join runner_orders r on r.order_id=c.order_id
where cancellation is null
group by r.runner_id),

delivery_amount as (
select runner_id, sum(distance::numeric*0.30) as runner_amount from runner_orders r
where cancellation is null
group by runner_id
)


select amount-runner_amount from pizza_amount p join delivery_amount d
on p.runner_id =d.runner_id


