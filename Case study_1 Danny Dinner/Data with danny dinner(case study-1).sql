-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

select * from sales
select * from menu
select * from members

-- 1. What is the total amount each customer spent at the restaurant?
select customer_id,sum(price) as total_price from sales s join menu m
on s.product_id=m.product_id
group by customer_id
order by customer_id



-- 2. How many days has each customer visited the restaurant?
select  customer_id,count(distinct order_date) as days_count from sales
group by customer_id

-- 3. What was the first item from the menu purchased by each customer?
select customer_id,product_id
from 
(select product_id,customer_id,
row_number() over(partition by customer_id order by order_date) 
as first_item_id
from sales) as rownumber
where first_item_id = 1


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select count(*) as prod_count,product_id from sales
group by product_id
order by count(*) desc

-- 5. Which item was the most popular for each customer?
with popular_product as (
select customer_id,s.product_id,count(s.product_id)as product_count,product_name,
rank() over(partition by customer_id order by count(s.product_id) desc) as rank
from sales s join menu m on s.product_id = m.product_id
group by s.product_id,customer_id,product_name
order by customer_id
)

select customer_id,product_name from popular_product
where rank = 1

-- 6. Which item was purchased first by the customer after they became a member?
select customer_id,product_name from (select s.customer_id,m.product_name,rank() over(partition by s.customer_id order by order_date),order_date,join_date from sales s   join menu m on s.product_id = m.product_id 
join members me on s.customer_id=me.customer_id
where order_date > join_date
order by customer_id) as first_item
where rank = 1

-- 7. Which item was purchased just before the customer became a member?
select customer_id,product_name from (select s.customer_id,m.product_name,rank() over(partition by s.customer_id order by order_date desc) as rank,order_date,join_date from sales s join menu m on s.product_id = m.product_id 
join members me on s.customer_id=me.customer_id
where order_date < join_date
order by customer_id) as first_item
where rank =1


---- 8. What is the total items and amount spent for each member before they became a member?
select sum(price) as amount_spent,count(*) as total_items,s.customer_id from sales s join menu m on s.product_id=m.product_id join members me on s.customer_id = me.customer_id
where order_date < join_date
group by s.customer_id


---9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select customer_id,sum(points) from (select customer_id,price,
(case
    when product_name = 'sushi' then price*20
	else price *10
end) as points
from sales s join menu m on s.product_id = m.product_id) as customer_points
group by customer_id


---10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?  
 
select customer_id,sum(points) from (select s.customer_id,price,
(case
    when order_date between join_date and join_date +  interval '6 days' then price*20
	else 
	case
	    when product_name = 'sushi' then price *20
		else price*10
	end
end) as points
from sales s join menu m on s.product_id = m.product_id join members me on me.customer_id = s.customer_id
where order_date <='2021-01-31') as month_points
group by customer_id

