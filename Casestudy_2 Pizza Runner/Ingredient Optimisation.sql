
C. Ingredient Optimisation

select * from runners
select * from runner_orders
select * from customer_orders
select * from pizza_names
select * from pizza_recipes
select * from pizza_toppings


SET search_path = pizza_runner;

-- 1.What are the standard ingredients for each pizza?
  select pr.pizza_id,pn.pizza_name,string_agg(pt.topping_name,',' order by topping_name) as ingredients 
  from pizza_toppings pt
  join pizza_recipes pr on pt.topping_id = any(string_to_array(pr.toppings,',')::int[])  
  join pizza_names pn on pn.pizza_id = pr.pizza_id
  group by 1,2
  order by 1

-- 2.What was the most commonly added extra?
select
topping_name,count(extra_id) as extras_count from(
select customer_id,unnest(string_to_array(extras,',')::int[]) as extra_id from customer_orders
where extras  is not null
) extras
join pizza_toppings pt on pt.topping_id=extras.extra_id
group by 1
order by 2 desc limit 1
 

-- 3.What was the most common exclusion?
 select
 topping_name,count(exclusions_id) as extras_count from(
 select customer_id,unnest(string_to_array(exclusions,',')::int[]) as exclusions_id from customer_orders
 where exclusions  is not null
 ) exclusions
 join pizza_toppings pt on pt.topping_id=exclusions.exclusions_id
 group by 1
 order by 2 desc limit 1
   
-- 4.Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

with extras_names as (
select
order_id,customer_id,count(extra_id) as extras_count,string_agg(pt.topping_name,',') as extra_topping_names from(
select order_id,customer_id,unnest(string_to_array(extras,',')::int[]) as extra_id from customer_orders
where extras  is not null
) extras
join pizza_toppings pt on pt.topping_id=extras.extra_id
group by 1,2
),
exclusions_names as (
select
 order_id,customer_id,count(exclusions_id) as exclusions_count,string_agg(pt.topping_name,',') as exclusions_topping_names from(
 select order_id,customer_id,unnest(string_to_array(exclusions,',')::int[]) as exclusions_id from customer_orders
 where exclusions  is not null
 ) exclusions
 join pizza_toppings pt on pt.topping_id=exclusions.exclusions_id
 group by 1,2
)


select ft.customer_id,ft.order_id,concat(
pizza_name,
case when exclusions is not null then ' -Exclude '||  coalesce(exclusions_topping_names,'') else '' end,
CASE WHEN extras IS NOT NULL THEN ' - Extra ' ||   coalesce(extra_topping_names,'') ELSE '' END
)

from (
select customer_id,order_id,pn.pizza_name,exclusions,extras from customer_orders c join pizza_names pn
on c.pizza_id = pn.pizza_id 
join pizza_recipes pr on pn.pizza_id=pr.pizza_id 
) as ft 
left JOIN extras_names exr ON ft.customer_id = exr.customer_id and exr.order_id=ft.order_id
left JOIN exclusions_names exn ON ft.customer_id = exn.customer_id and exn.order_id=ft.order_id
order by 1,2





-- 5.Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

with all_toppings as (select  order_id,customer_id,unnest(string_to_array(toppings,',')::int[]) as topping_id from customer_orders c join pizza_recipes pr 
on c.pizza_id = pr.pizza_id
union all
select order_id,customer_id,unnest(string_to_array(extras,',')::int[]) as topping_id from customer_orders c
where extras is not null)

select order_id,customer_id,string_agg(out_put,',' order by topping_name) from
(
select order_id,customer_id,topping_name,(case when  duplicate_count > 1 then '2x'|| topping_name else topping_name end) as out_put from (
select topping_name,order_id,customer_id,count(*) as duplicate_count from (
select order_id,customer_id,alt.topping_id,topping_name from all_toppings as alt join pizza_toppings pt on alt.topping_id = pt.topping_id
where alt.topping_id not in (select unnest(string_to_array(exclusions,',')::int[]) from customer_orders 
where exclusions is not null)
) as filtered_topping_names
group by 1,2,3
) as sample
) as final_output
group by 1,2



-- 6.What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
with delivered as (
select c.order_id,c.pizza_id,c.extras from customer_orders c join runner_orders r 
on c.order_id=r.order_id
where cancellation is null
),

base_toppings as(
select d.order_id,d.pizza_id,unnest(string_to_array(toppings,','))::int as topping_id from delivered d join pizza_recipes pr
on d.pizza_id = pr.pizza_id
),
extra_toppings as(
select order_id,pizza_id,unnest(string_to_array(extras,','))::int as topping_id from delivered d
where extras is not null
),

all_toppings as(
select * from base_toppings
union all
select * from extra_toppings
),

topping_count as(
select topping_id,count(*) as total_quantity
from all_toppings
group by topping_id
)

select tc.topping_id,total_quantity from topping_count tc
join pizza_toppings pt on tc.topping_id = pt.topping_id
order by 2 desc






