----Case study#4 - Data Bank
CREATE SCHEMA data_bank;
SET search_path = data_bank;

select * from regions
select * from customer_nodes
select * from customer_transactions

create view total_join as
select 
r.region_id,
r.region_name,
cn.customer_id,
cn.node_id,
cn.start_date,
cn.end_date,
ct.txn_date,
ct.txn_type,
ct.txn_amount 
from regions r 
join customer_nodes cn
on r.region_id=cn.region_id 
join customer_transactions ct 
on cn.customer_id=ct.customer_id
order by customer_id,start_date

create view  region_cus_nodes as
select 
r.region_id,
r.region_name,
cn.customer_id,
cn.node_id,
cn.start_date,
cn.end_date 
from regions r 
join customer_nodes cn
on r.region_id=cn.region_id

----------- Customer Nodes Exploration ----------
1.How many unique nodes are there on the Data Bank system?
  select count(distinct node_id) from customer_nodes

  
2.What is the number of nodes per region?
  select cn.region_id,region_name,count(node_id) from customer_nodes cn
  join regions r on cn.region_id=r.region_id
  group by cn.region_id,region_name
  order by cn.region_id
  
  
3.How many customers are allocated to each region?
  select region_id,region_name,count(distinct customer_id) from region_cus_nodes
  group by region_id,region_name


--4.How many days on average are customers reallocated to a different node?
 

with cte as (
select customer_id,start_date,lead(start_date) over(partition by customer_id order by start_date) as next_date from customer_nodes
order by customer_id,node_id
)
select round(avg(next_date-start_date),2) from cte
where next_date is not null


--5.What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
   with cte as(
   select customer_id,region_id,region_name,start_date,
   lead(start_date) over(partition by customer_id order by start_date) as next_date,
   lead(node_id) over(partition by customer_id order by start_date) as next_nodeid
   from region_cus_nodes
   ),

   cte_2 as(
   select customer_id,region_id,region_name,(next_date-start_date) as date_diff from cte
   )
   select region_id,region_name,
   percentile_cont(0.5) within group (order by date_diff),
   percentile_cont(0.80)  within group (order by date_diff),
   percentile_cont(0.95)  within group (order by date_diff)
   from cte_2
   group by region_id,region_name
  
  
  
 
  
  


