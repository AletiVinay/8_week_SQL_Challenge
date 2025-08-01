SET search_path = data_mart;

select * from clean_weekly_sales



----------------2. Data Exploration---------------
---1.What day of the week is used for each week_date value?
     select week_date,extract(dow from week_date) as day_num,to_char(week_date,'day') as day_name
	 from clean_weekly_sales
	 
---2.What range of week numbers are missing from the dataset?
     with recursive cte as(
     select 1 as num
	 union all
	 select num+1 from cte 
	 where num<=51
	 ),

	 cte_1 as (
	 select array_agg(num) as total_week_list from cte
	 ),
	 
	 cte_2 as (
	 select extract(year from week_date) as date_year,array_agg(week_num order by week_num) as week_list
	 from clean_weekly_sales 
	 group by extract(year from week_date)
	 )

	 select date_year,array(select unnest(c1.total_week_list) except select unnest(c2.week_list) order by 1) as missing_weeks from cte_2 c2 join cte_1 c1
	 on  true;

	 -- Generate all possible week numbers per year based on actual data
         WITH week_range AS (
    SELECT DISTINCT EXTRACT(YEAR FROM week_date) AS year
    FROM clean_weekly_sales
    ),
   all_weeks AS (
    SELECT year, generate_series(1, 53) AS week_num
    FROM week_range
    ),
  existing_weeks AS (
    SELECT EXTRACT(YEAR FROM week_date) AS year, week_num
    FROM clean_weekly_sales
    ),
   missing_weeks AS (
    SELECT aw.year, aw.week_num
    FROM all_weeks aw
    LEFT JOIN existing_weeks ew
    ON aw.year = ew.year AND aw.week_num = ew.week_num
    WHERE ew.week_num IS NULL
  )
  SELECT year, ARRAY_AGG(week_num ORDER BY week_num) AS missing_week_nums
  FROM missing_weeks
  GROUP BY year
  ORDER BY year;

	 
---3.How many total transactions were there for each year in the dataset?
     select extract(year from week_date),round(sum(transactions)/1000000.0,2) || 'm' as Total_transactions 
	 from clean_weekly_sales
	 group by extract(year from week_date)
	 order by extract(year from week_date)
---4.What is the total sales for each region for each month?
     select region,month_num,round(sum(sales)/1000000.0,2)||'m' as total_sales 
	 from clean_weekly_sales
	 group by region,month_num
	 order by region,month_num
     
---5.What is the total count of transactions for each platform
     select platform,count(transactions) as trans_count from clean_weekly_sales
	 group by platform
---6.What is the percentage of sales for Retail vs Shopify for each month?
     with total_sales as(
	 select extract(year from week_date) as date_year,
	 month_num,platform,sum(sales) as total_sum
	 from clean_weekly_sales
	 group by 1,2,3
	 order by 1,2,3
	 ),
     normal_sales as(
	 select extract(year from week_date ) as date_year,month_num,sum(sales) as actual_sum from clean_weekly_sales 
	 group by 1,2
	 order by 1,2
	 )
	select ts.date_year,ts.month_num,platform,round(total_sum*100.0/actual_sum,2) as platform_percen from total_sales ts
	join normal_sales ns on ts.date_year =ns.date_year and ts.month_num = ns.month_num
	

	 
---7.What is the percentage of sales by demographic for each year in the dataset?
     with cte as(
	 select extract(year from week_date) as year_date,demographic,sum(sales) as demo_sales from 
	 clean_weekly_sales
	 group by 1,2
	 order by 1
	 ),
	 cte_2 as (
     select extract(year from week_date) as year_date,sum(sales) year_wise_sales from
	 clean_weekly_sales
	 group by 1
	 )

	 select c.year_date,demographic,round(demo_sales*100.0/year_wise_sales,2) as demo_percen from 
	 cte c join cte_2 c2 on c.year_date=c2.year_date
     
---8.Which age_band and demographic values contribute the most to Retail sales?
     select age_band,demographic,
	 round(sum(sales)*100.0/(select sum(sales) from clean_weekly_sales where platform='Retail'),2) as age_demo_retail_percen
	 from clean_weekly_sales
	 where platform='Retail'
	 group by 1,2
	 order by 3 desc
---9.Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
     select extract(year from week_date) as year_date,platform,round(sum(sales)*1.0/sum(transactions),2) as without_avg_transc_col,round(avg(avg_transaction),2) as with_avg_transc_col from 
	 clean_weekly_sales
	 group by 1,2
	 order by 1,2


	
	 
