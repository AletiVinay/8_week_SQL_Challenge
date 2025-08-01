SET search_path = data_mart;

select * from weekly_sales;


-------------------Data Cleaning Steps ------------------
In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

--Convert the week_date to a DATE format
alter table weekly_sales
alter column week_date type DATE
using to_date(week_date,'dd/mm/yy')
--Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
  alter table weekly_sales
  add column week_num int

  update weekly_sales
  set week_num = extract(week from week_date)
--Add a month_number with the calendar month for each week_date value as the 3rd column
  alter table weekly_sales
  add column month_num int

  update weekly_sales
  set month_num = extract(month from week_date)

--Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
  alter table weekly_sales
  add column calendar_year int

  update weekly_sales
  set calendar_year = extract(year from week_date)

--Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
  alter table weekly_sales
  add column age_band varchar(30)

  update weekly_sales
  set age_band = case  when right(segment,1) = '1' then 'Young Adults' 
                       when right(segment,1) = '2' then 'Middle Aged'
					   when right(segment,1) in ('3','4') then 'Retirees'
					   else 'unknown'
				 end  

segment	age_band
1	Young Adults
2	Middle Aged
3 or 4	Retirees

--Add a new demographic column using the following mapping for the first letter in the segment values:
alter table weekly_sales
add column demographic varchar

update weekly_sales 
set demographic = case when left(segment,1) = 'C' then 'Couples'
                       when left(segment,1) = 'F' then 'Families'
					   else 'unknown'
				  end



segment	demographic
C	Couples
F	Families

--Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
  update weekly_sales
  set segment = 'unknown'
  where segment = null

  alter table weekly_sales
alter column segment type varchar(30)

--Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
  alter table weekly_sales
  add column avg_transaction int

  update weekly_sales
  set avg_transaction = round(sales/transactions,2)

create table clean_weekly_sales as
select week_date,week_num,month_num,calendar_year,region,platform,segment,age_band,demographic,customer_type,transactions,sales,avg_transaction
from weekly_sales

select * from clean_weekly_sales

  