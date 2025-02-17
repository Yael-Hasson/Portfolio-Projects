-- We create a table to store the data
CREATE TABLE ab_test_targeted_customers (
    customer_id BIGINT PRIMARY KEY,
    country VARCHAR(10),
    group_assignment VARCHAR(15),  -- Treatment, Control, Holdout
    assigned_date DATE
);

INSERT INTO ab_test_targeted_customers
SELECT 
    c.customer_id,
    c.country,
    CASE 
        WHEN NTILE(3) OVER (PARTITION BY c.country ORDER BY RANDOM()) = 1 THEN 'Treatment'  -- 20% Off
        WHEN NTILE(3) OVER (PARTITION BY c.country ORDER BY RANDOM()) = 2 THEN 'Control'    -- 10% Off
        ELSE 'Holdout'  -- 0% Off
    END AS group_assignment
    current_date -- to track when we targeted the customers
  
FROM customers c
INNER JOIN orders o 
    ON c.customer_id = o.customer_id 
     AND o.order_date >= CURRENT_DATE - INTERVAL '2 years' -- Last purchase in the last 2 years
INNER JOIN products p 
    ON o.product_id = p.product_id
  
WHERE c.country IN ('US', 'UK')
    AND p.category = 'Fire Tablets'; -- Only clients who purchased a Fire Tablet
