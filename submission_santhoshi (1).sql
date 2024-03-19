/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
  
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/
	SELECT state, COUNT(customer_id) AS customer_count
	FROM customer_t
	GROUP BY 1 order by 2 desc;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. */

WITH Feedback AS (
  SELECT
    quarter_number,
    CASE
      WHEN customer_feedback = 'Very Bad' THEN 1
      WHEN customer_feedback = 'Bad' THEN 2
      WHEN customer_feedback = 'Okay' THEN 3
      WHEN customer_feedback = 'Good' THEN 4
      WHEN customer_feedback = 'Very Good' THEN 5
    END AS CustomerRating
  FROM
    order_t
)

SELECT
  CONCAT('Q', quarter_number) AS Quarter,
  AVG(CustomerRating) AS CustomerAverageRating
FROM
  Feedback
GROUP BY
  quarter_number
ORDER BY
  CustomerAverageRating DESC;
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.*/
      
	  WITH FeedbackSummary AS (
  SELECT
    quarter_number,
    COUNT(CUSTOMER_FEEDBACK) AS TotalFeedback,
    COUNT(CASE WHEN CUSTOMER_FEEDBACK = 'Very Bad' THEN 1 END) AS VeryBadCount,
    COUNT(CASE WHEN CUSTOMER_FEEDBACK = 'Bad' THEN 1 END) AS BadCount,
    COUNT(CASE WHEN CUSTOMER_FEEDBACK = 'Okay' THEN 1 END) AS OkayCount,
    COUNT(CASE WHEN CUSTOMER_FEEDBACK = 'Good' THEN 1 END) AS GoodCount,
    COUNT(CASE WHEN CUSTOMER_FEEDBACK = 'Very Good' THEN 1 END) AS VeryGoodCount
  FROM
    order_t
  GROUP BY
    quarter_number
  ORDER BY
    quarter_number
)

SELECT
  CONCAT('Q', quarter_number) AS "QUARTER",
  (VeryBadCount / TotalFeedback) * 100 AS "VERY_BAD(%)",
  (BadCount / TotalFeedback) * 100 AS "BAD(%)",
  (OkayCount / TotalFeedback) * 100 AS "OKAY(%)",
  (GoodCount / TotalFeedback) * 100 AS "GOOD(%)",
  (VeryGoodCount / TotalFeedback) * 100 AS "VERY_GOOD(%)"
FROM
  FeedbackSummary;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/

SELECT
  p.vehicle_maker as VehicleMaker,
  COUNT(o.customer_id) as NumberOfCustomers
FROM
  order_t o
  JOIN product_t p USING (product_id)
GROUP BY
  VehicleMaker  -- Corrected alias
ORDER BY
  NumberOfCustomers DESC
LIMIT 5;


-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/

WITH RankedVehicleMakes AS (
  SELECT
    c.state,
    vehicle_maker,
    count(c.customer_id) as NUMBER_OF_CUSTOMERS,
    RANK() OVER (PARTITION BY c.state ORDER BY COUNT(customer_id) DESC) AS RANKING
  FROM
    order_t o
    JOIN product_t p USING (product_id)
    JOIN customer_t c USING(customer_id)
  GROUP BY
    state, vehicle_maker
)

SELECT
  state as STATE,
  vehicle_maker AS MOST_PREFERRED_VEHICLE_MAKE,
  NUMBER_OF_CUSTOMERS,
  RANKING
FROM
  RankedVehicleMakes
WHERE
  ranking = 1
ORDER BY
STATE;
-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/

SELECT
  CONCAT('Q', quarter_number) AS Quarter,
  COUNT(order_id) AS NumberOfOrders
FROM
  order_t
GROUP BY
  quarter_number
ORDER BY
  quarter_number ASC;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/
 WITH RevenueSummary AS (
  SELECT
    CONCAT('Q', quarter_number) AS Quarter,
    SUM(vehicle_price * quantity * (1 - discount/100)) AS TotalRevenue
  FROM
    order_t  
  GROUP BY
    quarter_number
)

SELECT
  Quarter,
  TotalRevenue,
  LAG(TotalRevenue) OVER (ORDER BY Quarter) AS PreviousQuarterRevenue,
  ((TotalRevenue - LAG(TotalRevenue) OVER (ORDER BY Quarter)) / LAG(TotalRevenue) OVER (ORDER BY Quarter)) * 100 AS QoQPercentageChange
FROM
  RevenueSummary
ORDER BY
  Quarter;     
      

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/
SELECT
    CONCAT('Q', quarter_number) AS Quarter,
    COUNT(DISTINCT ORDER_ID) AS NUMBER_OF_ORDERS,
    SUM(vehicle_price * quantity * (1 - discount/100)) AS QUARTERLY_REVENUE
FROM
    order_t
GROUP BY
    Quarter
ORDER BY
    Quarter;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

SELECT
    c.credit_card_type,
    AVG(o.discount) AS average_discount
FROM
    order_t o
JOIN
    customer_t c USING(customer_id)
WHERE
    credit_card_type IS NOT NULL
GROUP BY
    credit_card_type
ORDER BY
    average_discount DESC;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/
SELECT 
    CONCAT('Q', quarter_number) AS Quarter, 
    AVG(DATEDIFF(SHIP_DATE,ORDER_DATE)) AS AVERAGE_DAYS_TO_SHIP
FROM order_t
GROUP BY 1
ORDER BY 1;


-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------



