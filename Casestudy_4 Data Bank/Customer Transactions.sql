--B. Customer Transactions
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

create view cus_node_trans as
select
ct.customer_id,
ct.txn_date,
ct.txn_type,
ct.txn_amount,
cn.region_id,
cn.node_id,
cn.start_date,
cn.end_date
from customer_transactions ct
join customer_nodes cn
on ct.customer_id=cn.customer_id


--1.What is the unique count and total amount for each transaction type?
    select txn_type,count(*) as type_count ,sum(txn_amount) as txn_amount from customer_transactions
	group by txn_type
	order by txn_amount desc

--2.What is the average total historical deposit counts and amounts for all customers?
     with cte as(
	 select customer_id,
	 count(*) as deposit_count,
	 sum(txn_amount) as amount 
	 from customer_transactions
	 where txn_type='deposit'
	 group by customer_id

	 )
	 select 
	 round(avg(deposit_count),2) as avg_dipost_count,
	 round(avg(amount),2) as avg_deposit_amount 
	 from cte
	 
	 


--3.For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
  
  with cte as(
   select customer_id,extract(month from txn_date) as month_num,
	  sum(case when txn_type = 'deposit' then 1 else 0 end) as deposit_count,
	  sum(case when txn_type = 'purchase' then 1 else 0 end) as purchase_count,
	  sum(case when txn_type = 'withdrawal' then 1 else 0 end) as withdrawal_count
    from customer_transactions
	group by customer_id,extract(month from txn_date)
	order by customer_id
	)

	select count(distinct customer_id),month_num from cte
	where deposit_count > 1 and (purchase_count = 1 or withdrawal_count =1)
	group by month_num
	
	

--4.What is the closing balance for each customer at the end of the month?

     create view closing_balance_per_month as 
	  with cte as (
       select customer_id,max(extract(month from txn_date)) AS txn_month,
       sum(case when txn_type='deposit' then txn_amount else -txn_amount end) as net_transaction
	   from customer_transactions
	   group by customer_id,extract(month from txn_date)
	   order  by customer_id
	   )
      select customer_id,txn_month,net_transaction,
	  sum(net_transaction) over(partition by customer_id ORDER BY txn_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as closing_balance 
	  from cte

    
--5.What is the percentage of customers who increase their closing balance by more than 5%?
    
	 with open_balance as( 
	 select 
	 customer_id,
	 txn_month,
	 net_transaction,
	 closing_balance,
	 first_value(closing_balance) over(partition by customer_id order by txn_month) as opening_balance,
	 row_number() over(partition by customer_id order by txn_month desc) as rank_n
	 from closing_balance_per_month
	 ),
	
	 perc as (
	 select  customer_id,rank_n,
	 round((closing_balance-opening_balance)*100/nullif(opening_balance,0),2) as balance_diff
	 from  open_balance
	 where rank_n =1
	 
	 ),

	 cte as(
	 select customer_id,balance_diff from perc
	 where balance_diff > 5
	 order by customer_id
	 )

	select 
	round(count(customer_id)*100/(select count(distinct customer_id) from customer_transactions),2) as closing_bal_increase_by_5_perc
	from cte

	 
	 
    
