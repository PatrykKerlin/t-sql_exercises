-- Hard

-- 185. Department Top Three Salaries
-- A company's executives are interested in seeing who earns the most money in each of the company's departments.
-- A high earner in a department is an employee who has a salary in the top three unique salaries for that department.
-- Write a solution to find the employees who are high earners in each of the departments.
-- Return the result table in any order.

with max_salaries as (
  select distinct t.departmentId, t.salary
  from (
    select departmentId, salary, dense_rank() over (partition by departmentId order by salary desc) as salary_rank
    from Employee
  ) as t
  where salary_rank <= 3
)
select d.name as Department, e.name as Employee, e.salary as Salary
from Employee as e
inner join max_salaries as ms
on e.departmentId = ms.departmentId and e.salary = ms.salary
inner join Department as d
on e.departmentId = d.id

-- 262. Trips and Users
-- The cancellation rate is computed by dividing the number of canceled (by client or driver) requests
-- with unbanned users by the total number of requests with unbanned users on that day.
-- Write a solution to find the cancellation rate of requests with unbanned users
-- (both client and driver must not be banned) each day between "2013-10-01" and "2013-10-03".
-- Round Cancellation Rate to two decimal points.
-- Return the result table in any order.

with temp as (
  select status, request_at,
  count(*) over (partition by request_at) as total,
  count(iif(status like 'cancelled%' and client_id in (select users_id from Users where banned like 'No'), 1, null)) over (partition by request_at) as cancelled,
  count(iif(client_id in (select users_id from Users where banned like 'Yes') or driver_id in (select users_id from Users where banned like 'Yes'), 1, null)) over (partition by request_at) as banned
  from Trips
  where request_at between '2013-10-01' and '2013-10-03'
)
select distinct request_at as Day,
  round(cancelled / cast((total - banned) as float), 2) as 'Cancellation Rate'
from temp
where total - banned > 0

-- 601. Human Traffic of Stadium
-- Write a solution to display the records with three or more rows with consecutive id's,
-- and the number of people is greater than or equal to 100 for each.
-- Return the result table ordered by visit_date in ascending order.

with temp as(
  select id, visit_date, people,
    lag(people, 1, null) over (order by visit_date) as one_ago,
    lag(people, 2, null) over (order by visit_date) as two_ago,
    lead(people, 1, null) over (order by visit_date) as one_next,
    lead(people, 2, null) over (order by visit_date) as two_next
  from Stadium
)
select id, visit_date, people
from temp
where people >= 100 and ((one_ago >= 100 and two_ago >= 100)
or (one_next >= 100 and two_next >= 100)
or (one_ago >= 100 and one_next >= 100));


-- Medium

-- 176. Second Highest Salary
-- Write a solution to find the second highest salary from the Employee table.
-- If there is no second highest salary, return null.

select max(salary) as SecondHighestSalary
from Employee
where salary < (select max(salary) from Employe)

-- 177. Nth Highest Salary
-- Write a solution to find the nth highest salary from the Employee table.
-- If there is no nth highest salary, return null.

CREATE FUNCTION getNthHighestSalary(N INT) RETURNS INT
BEGIN
    set N = N - 1;
    RETURN (
        select distinct(salary)
        from Employee
        order by salary desc
        limit 1 offset N
    );
END

-- 178. Rank Scores
-- Write a solution to find the rank of the scores. The ranking should be calculated according to the following rules:
-- * The scores should be ranked from the highest to the lowest.
-- * If there is a tie between two scores, both should have the same ranking.
-- * After a tie, the next ranking number should be the next consecutive integer value.
-- In other words, there should be no holes between ranks.
-- Return the result table ordered by score in descending order.

select score, dense_rank() over (order by score desc) as rank
from Scores

-- 180. Consecutive Numbers
-- Find all numbers that appear at least three times consecutively.
-- Return the result table in any order.
with temp as (
  select num,
    lag(num) over (order by id asc) as prev1,
    lag(num, 2) over (order by id asc) as prev2
  from Logs
)
select distinct num as ConsecutiveNums
from temp
where num = prev1
and num = prev2

-- 184. Department Highest Salary
-- Write a solution to find employees who have the highest salary in each of the departments.
-- Return the result table in any order.

with temp as(
  select d.name as name, d.id as id, max(e.salary) as salary
  from Employee as e
  join Department as d
  on e.departmentId = d.id
  group by d.name
)
select d.name as Department, e.name as Employee, e.salary as Salary
from Employee as e
left join temp as d
on e.departmentId = d.id
where e.salary = d.salary

-- 550. Game Play Analysis IV
-- Write a solution to report the fraction of players that logged in again on the day after the day they first logged in,
-- rounded to 2 decimal places. In other words, you need to count the number of players that logged in
-- for at least two consecutive days starting from their first login date, then divide that number by the total number of players.

with temp as (
  select player_id, event_date,
    iif(datediff(day, min(event_date) over (partition by player_id), lead(event_date, 1, null) over (partition by player_id order by event_date)) = 1, 1, null) as player
  from Activity
)
select round(count(player) / cast((select count(distinct player_id) from Activity) as float), 2) as fraction
from temp
where player is not null

-- 570. Managers with at Least 5 Direct Reports
-- Write a solution to find managers with at least five direct reports.
-- Return the result table in any order.

select name
from  Employee as e
join (
  select distinct managerId, count(managerId) as c
  from Employee
  group by managerId
  having managerId is not null
  and count(managerId) >= 5
) as t
on e.id = t.managerId

-- 585. Investments in 2016
-- Write a solution to report the sum of all total investment values in 2016 tiv_2016, for all policyholders who:
-- * have the same tiv_2015 value as one or more other policyholders, and
-- * are not located in the same city as any other policyholder (i.e., the (lat, lon) attribute pairs must be unique).
-- Round tiv_2016 to two decimal places.

with temp as (
  select pid, tiv_2016,
    count(lat) over (partition by lat, lon) as loc_qty,
    count(tiv_2015) over (partition by tiv_2015) as tiv_qty
  from Insurance
)
select round(sum(tiv_2016), 2) as tiv_2016
from temp
where tiv_qty > 1
  and loc_qty = 1
  
-- 602. Friend Requests II: Who Has the Most Friends
-- Write a solution to find the people who have the most friends and the most friends number.
-- The test cases are generated so that only one person has the most friends.

with temp as (
    select * from (
        select distinct requester_id as id,
            count(requester_id) over (partition by requester_id) as num
        from RequestAccepted
    ) as t1
    union all
    select * from (
        select distinct accepter_id as id,
            count(accepter_id) over (partition by accepter_id) as num
        from RequestAccepted
    ) as t2
)
select top 1 id, sum(num) as num
from temp
group by id
order by sum(num) desc

-- 608. Tree Node
-- Each node in the tree can be one of three types:
-- * "Leaf": if the node is a leaf node.
-- * "Root": if the node is the root of the tree.
-- * "Inner": If the node is neither a leaf node nor a root node.
-- Write a solution to report the type of each node in the tree.
-- Return the result table in any order.

select id,
  case
    when p_id is null then 'Root'
    when id in (select distinct p_id from Tree) then 'Inner'
    else 'Leaf'
  end as [type]
from Tree

-- 626. Exchange Seats
-- Write a solution to swap the seat id of every two consecutive students.
-- If the number of students is odd, the id of the last student is not swapped.
-- Return the result table ordered by id in ascending order.

with temp as (
  select id, student,
    lead(student, 1, null) over (order by id) as [next],
    lag(student, 1, null) over (order by id) as [prev],
    (row_number() over (order by id) - 1) % 2 + 1 as [no]
  from Seat
)
select id,
  case
    when [no] = 1 and [next] is not null then [next]
    when [no] = 2 then [prev]
    else [student]
  end as student
from temp

-- 1045. Customers Who Bought All Products
-- Write a solution to report the customer ids from the Customer table that bought all the products in the Product table.
-- Return the result table in any order.

select customer_id
from Customer
group by customer_id
having count(distinct product_key) = (select count(1) from Product)

-- 1070. Product Sales Analysis III
-- Write a solution to select the product id, year, quantity, and price for the first year of every product sold.
-- Return the resulting table in any order.

select product_id, [year] as first_year, quantity, price
from (
    select product_id, [year], quantity, price,
    rank() over (partition by product_id order by year) as [rank]
    from Sales
) as temp
where [rank] = 1

-- 1158. Market Analysis I
-- Write a solution to find for each user, the join date and the number of orders they made as a buyer in 2019.
-- Return the result table in any order.

with qty as (
  select distinct buyer_id, count(buyer_id) over (partition by buyer_id) as orders_in_2019
  from Orders
  where year(order_date) = 2019
)
select u.user_id as buyer_id,
  u.join_date,
  isnull(q.orders_in_2019, 0) as orders_in_2019
from Users as u
left join qty as q
on u.user_id = q.buyer_id

-- 1164. Product Price at a Given Date
-- Write an SQL query to find the prices of all products on 2019-08-16.
-- Assume the price of all products before any change is 10.
-- Return the result table in any order.

with temp as (
  select distinct product_id,
  new_price as price,
  rank() over (partition by product_id order by change_date desc) as [rank]
  from Products
  where change_date <= '2019-08-16'
)
select p.product_id,
  isnull(t.price, 10) as price
from (
  select distinct product_id
  from Products
) as p
left join temp as t
on p.product_id = t.product_id
and t.rank = 1

-- 1174. Immediate Food Delivery II
-- If the customer's preferred delivery date is the same as the order date, then the order is called immediate;
-- otherwise, it is called scheduled.
-- The first order of a customer is the order with the earliest order date that the customer made.
-- It is guaranteed that a customer has precisely one first order.
-- Write a solution to find the percentage of immediate orders in the first orders of all customers,
-- rounded to 2 decimal places.

with temp as (
  select rank() over (partition by customer_id order by order_date) as [rank],
    iif(order_date = customer_pref_delivery_date, 1, 0) as [immediate]
  from Delivery
)
select round((sum([immediate]) * 100) / cast(count(1) as float), 2) as immediate_percentage
from temp
where [rank] = 1

-- 1193. Monthly Transactions I
-- Write an SQL query to find for each month and country, the number of transactions and their total amount,
-- the number of approved transactions and their total amount.
-- Return the result table in any order.

with temp as (
  select format(trans_date, 'yyyy-MM') as [month],
    [country],
    [state],
    [amount]
  from Transactions
)
select [month],
  [country],
  count(1) as trans_count,
  sum(case when [state] = 'approved' then 1 else 0 end) as approved_count,
  sum(amount) as trans_total_amount,
  sum(case when [state] = 'approved' then amount else 0 end) as approved_total_amount
from temp
group by [month], [country]

-- 1204. Last Person to Fit in the Bus
-- There is a queue of people waiting to board a bus. However, the bus has a weight limit of 1000 kilograms,
-- so there may be some people who cannot board.
-- Write a solution to find the person_name of the last person that can fit on the buswithout exceeding the weight limit.
-- The test cases are generated such that the first person does not exceed the weight limit.

select top 1 person_name
from (
  select person_id, person_name, sum([weight]) over (order by turn) as [sum]
  from [Queue]
) as temp
where [sum] <= 1000
order by [sum] desc

-- 1321. Restaurant Growth
-- You are the restaurant owner and you want to analyze a possible expansion (there will be at least one customer every day).
-- Compute the moving average of how much the customer paid in a seven days window (i.e., current day + 6 days before).
-- average_amount should be rounded to two decimal places.
-- Return the result table ordered by visited_on in ascending order.

with daily_sum as (
  select visited_on,
    sum(amount) as daily_amount
  from Customer
  group by visited_on
)
select ds1.visited_on,
  sum(ds2.daily_amount) as amount,
  round(sum(ds2.daily_amount) / 7.0, 2) as average_amount
from daily_sum as ds1
left join daily_sum as ds2
on ds2.visited_on between dateadd(day, -6, ds1.visited_on) and ds1.visited_on
group by ds1.visited_on
having ds1.visited_on >= dateadd(day, 6, (select min(visited_on) from Customer))

-- 1341. Movie Rating
-- Write a solution to:
-- * Find the name of the user who has rated the greatest number of movies.
--   In case of a tie, return the lexicographically smaller user name.
-- * Find the movie name with the highest average rating in February 2020.
--   In case of a tie, return the lexicographically smaller movie name.

with temp as (
  select u.name, m.title,
  count(mr.user_id) over (partition by mr.user_id) as user_count,
  iif(sum(case when year(mr.created_at) = 2020 and month(mr.created_at) = 2 then 1 else 0 end) over (partition by mr.movie_id) > 0, round(sum(case when year(mr.created_at) = 2020 and month(mr.created_at) = 2 then mr.rating else 0 end) over (partition by mr.movie_id) / cast((sum(case when year(mr.created_at) = 2020 and month(mr.created_at) = 2 then 1 else 0 end) over (partition by mr.movie_id)) as float), 2), null) as avg_rating
from MovieRating as mr
join Movies as m
on mr.movie_id = m. movie_id
join Users as u
on mr.user_id = u.user_id
),
max_user as (
  select top 1 [name] as results
from (
  select distinct [name], user_count
  from temp
) as temp_users
order by user_count desc, [name] asc
),
max_movie as (
select top 1 title as results
from (
  select distinct title, avg_rating
  from temp
) as temp_movies
order by avg_rating desc, title asc
)
select results from max_user
union all
select results from max_movie

-- 1393. Capital Gain/Loss
-- Write a solution to report the Capital gain/loss for each stock.
-- The Capital gain/loss of a stock is the total gain or loss after buying and selling the stock one or many times.
-- Return the result table in any order.

select stock_name,
  sum(iif(operation = 'Buy', price * -1, price)) as capital_gain_loss
from Stocks
group by stock_name

-- 1907. Count Salary Categories
-- Write a solution to calculate the number of bank accounts for each salary category. The salary categories are:
-- * "Low Salary": All the salaries strictly less than $20000.
-- * "Average Salary": All the salaries in the inclusive range [$20000, $50000].
-- * "High Salary": All the salaries strictly greater than $50000.
-- The result table must contain all three categories. If there are no accounts in a category, return 0.
-- Return the result table in any order.

with categories as (
  select 'Low Salary' as category
  union all
    select 'Average Salary'
  union all
    select 'High Salary'
),
categorized as (
  select case
    when income < 20000 then 'Low Salary'
    when income > 50000 then 'High Salary'
    else 'Average Salary'
  end as income_category
  from Accounts
)
select distinct c1.category, count(c2.income_category) as accounts_count
from categories as c1
left join categorized as c2
on c1.category = c2.income_category
group by c1.category

-- 1934. Confirmation Rate
-- The confirmation rate of a user is the number of 'confirmed' messages divided by the total number of requested confirmation messages.
-- The confirmation rate of a user that did not request any confirmation messages is 0. Round the confirmation rate to two decimal places.
-- Write an SQL query to find the confirmation rate of each user.
-- Return the result table in any order.

with temp as (
  select s.user_id,
    count(s.user_id) over (partition by s.user_id) as total,
    sum(case when c.action = 'confirmed' then 1 else 0 end) over (partition by s.user_id) as confirmed
  from Signups as s
  left join Confirmations as c
  on s.user_id = c.user_id
)
select distinct [user_id], round(confirmed / cast(total as float), 2) as confirmation_rate
from temp
