drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'22-09-2017'),
(3,'21-04-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'15-01-2015'),
(3,'11-04-2014');



drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'19-04-2017',2),
(3,'18-12-2019',1),
(2,'20-07-2020',3),
(1,'23-10-2019',2),
(1,'19-03-2018',3),
(3,'20-12-2016',2),
(1,'09-11-2016',1),
(1,'20-05-2016',3),
(2,'24-09-2017',1),
(1,'11-03-2017',2),
(1,'11-03-2016',1),
(3,'10-11-2016',1),
(3,'07-12-2017',2),
(3,'15-12-2016',2),
(2,'08-11-2017',2),
(2,'10-09-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

/**What is the total amount each customer spent on zomato?**/
select userid,sum(price) as total_amount_spent
from sales
join product on product.product_id = sales.product_id
group by userid
order by userid;

/**How many days has each customer visited Zomato?**/
select userid,count(created_date) as count_of_days
from sales
group by userid
order by userid;
/** This metric can be helpful to understand the frequnecy of visit of each customer which can be further
used to plan stratergies for maintaining the same frequnecy for most visting customers and increasing 
the frequency of less frequent customers.**/

/** What was the first product purchased by each customer **/
with cte as(select *,
row_number() over(partition by userid order by created_date) as "row_no"
from sales)
select cte.userid,cte.product_id as first_product_purchased 
from cte
where cte.row_no=1;
/** This metric tells us about the product that customers were attracted to in the begining which made 
them visit our website and buy it. In this case all customers first buyed product 1 so there might be 
possibility that future customers could also b attracted to the same product and must be visiting our website
for buying it hence we should increase its manufacturing.**/

/** What is the most purchased product on the menu and how many times it was purchased by all customers**/
select product_id
from sales
group by product_id
order by count(product_id) desc
limit 1;

select userid,count(product_id) as no_of_times_bought
from sales
where product_id in (select product_id
from sales
group by product_id
order by count(product_id) desc
limit 1)
group by userid
/** This metric will help us identify the most selling product so that we can increase its manufacturing 
as people are buying it. But also understanding how many times it is purchased by each customer helps us put
a limit to its manufacturing beacuse although it is the most selling product not all buyers are interested in 
buying it.This will help prevent over manufacturing of the product.**/

/** Which item was the most popular for each customer**/
with fav_product as (select userid,product_id,count(product_id) as c
from sales
group by 1,2
order by 1,3 desc),
rows_number as(
select *,
ROW_NUMBER() over(partition by fav_product.userid order by fav_product.c desc) as "row_no"
	from fav_product
)
select userid,product_id,c as count
from rows_number
where row_no =1;
/** By knowing the favourite product of each customers we can give special offers for the customers on their
respective favourite product and increase the sales of those products.**/

/** Which item was purchased first by the customers after they became a gold member **/
with cte as (select sales.userid,sales.created_date,sales.product_id,
goldusers_signup.gold_signup_date as
signup_date
from sales
join goldusers_signup
on sales.userid = goldusers_signup.userid
where sales.created_date > goldusers_signup.gold_signup_date),
row_no as (
select *,
row_number() over (partition by cte.userid  order by cte.created_date asc) as rowno
from cte
)
select *
from row_no
where rowno = 1;
/**This metric will help us know about the product for which the users signed up for gold membership. 
So now we can throw similar products to the respective customers and increase their sales. **/

/** What item was purchased just before the customer became a gold member**/
with cte as (select sales.userid,sales.created_date,sales.product_id,goldusers_signup.gold_signup_date
from sales
join goldusers_signup
on sales.userid = goldusers_signup.userid
where sales.created_date < goldusers_signup.gold_signup_date),
rn as(
select *,
row_number() over(partition by cte.userid order by cte.created_date desc)as rrn
from cte
)
select rn.userid,rn.created_date,rn.product_id,rn.gold_signup_date 
from rn
where rrn=1

/** What is the total no of orders and amount spent by each member before they became a gold member **/
select sales.userid,count(sales.product_id) as order_count,sum(product.price) as sumtotal
from goldusers_signup
join sales
on goldusers_signup.userid = sales.userid
join product
on product.product_id = sales.product_id
where sales.created_date<goldusers_signup.gold_signup_date
group by 1
order by sales.userid
/** This metric will help us understand will the customer be a promising gold member by looking
at their total amount spent on our platform before they became a gold member.**/

/**Buying each product generates points eg for products 'p1' 5Rs = 1point, 'p2' 10Rs = 5points ,
'p3' 5Rs = 1point
calculate the total points gained by each customer**/
with cte as (select userid,sales.product_id,sum(price) as costed
from sales
join product 
on sales.product_id = product.product_id
group by 1,2
order by 1,2
),
points as (
select *,
case
when product_id =1 then costed*0.2
when product_id =2 then costed*0.5
when product_id=3 then costed*0.2
end as points_gained
from cte
)
select points.userid,sum(points.points_gained) as total_points_gained
from points
group by 1
order by 1
/** This wil help us know about total zomato points gained by each customer**/

/** In the first year after joining the gold memebership irrespective of which product they buy 
the customer earns 5 zomato points for every 10Rs spent. Find out who earned more points customer 1 or 3**/
select sales.userid,sales.created_date,sales.product_id,
goldusers_signup.gold_signup_date as
signup_date,product.price*0.5 as points_earned
from sales
join goldusers_signup
on sales.userid = goldusers_signup.userid
join product
on sales.product_id = product.product_id
where sales.created_date > goldusers_signup.gold_signup_date
and sales.created_date <= (goldusers_signup.gold_signup_date + int '365')
/**This metric will help us identify the goldcutomers who has spent the most amount of money in the first year of their 
their goldmembership signup.**/

/** rank all the transactions of the customers**/
select *,
rank() over(partition by userid order by created_date)
from 
sales
/** This will give us the purchasing data of individual customer sorted in ascending order of their created 
dates. This will help us easily identify details of the nth transaction of any customer. **/

/**rank all the transactions for each member whenever they are a gold member for every 
non gold memeber transaction mark as 'na' **/
with cte as(select sales.userid,sales.created_date,sales.product_id,goldusers_signup.gold_signup_date
from sales
left join goldusers_signup
on sales.userid = goldusers_signup.userid and sales.created_date> goldusers_signup.gold_signup_date),
ranking as (
select *,
	cast((case 
	when cte.gold_signup_date is null then '0'
	else rank() over(partition by cte.userid order by cte.created_date desc)
	end) as varchar) rnk
	from cte
)
select ranking.userid,ranking.created_date,ranking.product_id,ranking.gold_signup_date,
case 
when rnk = '0' then 'na'
else rnk
end as final_rank
from ranking
/** This metric will help us easily identify the details of the nth transaction after the customers 
become the gold members.**/


