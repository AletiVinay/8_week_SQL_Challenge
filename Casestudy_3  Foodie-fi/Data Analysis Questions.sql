select * from plans
select * from subscriptions
select * from details

create view  details  as
select customer_id,s.plan_id,start_date,plan_name,price
from subscriptions s join plans p
on s.plan_id = p.plan_id
order by customer_id,start_date


select customer_id,start_date,plan_id from details d
where plan_id=0

---1000 customer started with trial plan

we randomly check the customers data there plan_id and whether upgraded or downgraded and start_date

--customer_id-1

select * from details
where customer_id = 1

--customer_id-97
select * from details
where customer_id = 97

--customer_id-209
select * from details
where customer_id = 209

--customer_id-264
select * from details
where customer_id = 264


---Data Analysis questions
--1.How many customers has Foodie-Fi ever had?

  select count(distinct customer_id) from subscriptions

--2.What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

   with start_date as 
   (select plan_id,customer_id,date(date_trunc('month',start_Date)) as month_start_date
   from subscriptions)

   select month_start_date,count(distinct customer_id) from start_date
   where plan_id = 0
   group by month_start_date
   order by month_start_date
   

--3.What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
  with start_date as 
   (select plan_name,plan_id,customer_id,date(date_trunc('month',start_Date)) as month_start_date
   from details)

   select plan_name,count(distinct customer_id) from start_date
   where extract(year from month_start_date) > 2020
   group by plan_name
   order by plan_name

--4.What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
    select plan_name,count(distinct customer_id),round(count(distinct customer_id)*100/(select count(distinct customer_id) from subscriptions),2) as plan_percn
	from plans p join subscriptions s
	on p.plan_id=s.plan_id
	group by plan_name
--5.How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
    
   with next_id as (
   select customer_id,plan_id,lead(plan_id) over(order by customer_id) as churn_id from details
   ),

   churn_after_trail_count as (
   select count(distinct customer_id) as churn_after_trail from next_id
   where churn_id = 4 and plan_id =0)

   select churn_after_trail,
   round((churn_after_trail)*100.0/(select count(distinct customer_id) from details))  as churn_after_trail_perc
   from churn_after_trail_count
	



	
--6.What is the number and percentage of customer plans after their initial free trial?
   select plan_name,count(distinct customer_id),round(count(distinct customer_id)*100.0/(select count(distinct customer_id) from details),2) from details
   where plan_id > 0
   group by plan_name
   
   
--7.What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

with latest_dates as(
   select *,
   row_number() over(partition by customer_id order by start_date desc) as latest_date 
   from details
   where start_date <= '2020-12-31'
   )
   
   select plan_name,count(distinct customer_id) as customer_count,
   round(count(distinct customer_id)*100.0/(select count(distinct customer_id) from details),2) as perc
   from latest_dates
   where latest_date = 1
   group by plan_name
   
--8.How many customers have upgraded to an annual plan in 2020?
    select count(customer_id) as annual_count from details
	where plan_id = 3 and extract(year from start_date) = 2020
	
--9.How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
  with trial_dates as (
  select * from details
  where plan_id = 0),

  annual_dates as (
  select * from details
  where plan_id = 3
  )
  select round(avg(ad.start_date - td.start_date),2) as date_diff 
  from trial_dates td 
  join annual_dates ad using(customer_id)
  
  
--10.Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
  with trial_dates as (
  select * from details
  where plan_id = 0),

  annual_dates as (
  select * from details
  where plan_id = 3
  ),
 date_diff as (select customer_id,(ad.start_date-td.start_date) as date_dif
  from trial_dates td 
  join annual_dates ad using(customer_id)
  order by customer_id)

  select
  (case
      when date_dif between 0 and 30 then '0-30 days'
	  when date_dif between 31 and 60 then '31-60 days'
	  when date_dif between 61 and 90 then '61-90 days'
	  when date_dif between 91 and 120 then '91-120 days'
	  else '120+ days'
  end) as further_count,count(*) as customer_count from date_diffn 
  group by further_count
  
 
--11.How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
  with downgraded as(
   select customer_id,plan_id,next_planid from  (
   select *,lead(plan_id) over(partition by customer_id order by start_date) as next_planid from details
   where extract(year from start_date) =2020
   order by customer_id
   ) as sample
   where plan_id =2 and next_planid = 1
   )

   select count(customer_id) from downgraded

	
	
     