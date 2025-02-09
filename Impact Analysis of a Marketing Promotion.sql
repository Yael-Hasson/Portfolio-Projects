WITH purchases_data AS (
    -- Count the number of devices purchased per customer with applied filters
    SELECT 
        p.customer_id,
        pr.promotion_id,  
        COUNT(p.device_id) AS num_devices
    FROM purchases p
    LEFT JOIN promotions pr ON p.customer_id = pr.customer_id AND p.order_id = pr.order_id  
    WHERE pr.promotion_id = 'PROMO123'  
    AND p.device_id IN (101, 202, 303, 404)  
    AND p.purchase_date BETWEEN '2024-07-01' AND '2024-09-30'  
    AND p.country = 'USA'  
    GROUP BY p.customer_id, pr.promotion_id
),

aggregated AS (
    -- Calculate key metrics per group (promotion vs. no promotion)
    SELECT 
        CASE 
            WHEN promotion_id IS NOT NULL THEN 'Received Promotion' 
            ELSE 'No Promotion' 
        END AS promo_group,
        COUNT(customer_id) AS num_customers,
        SUM(num_devices) AS total_devices_purchased,
        AVG(num_devices) AS avg_devices_per_customer
    FROM purchases_data
    GROUP BY promo_group
),

summary AS (
    -- Calculate sales percentage contribution and difference between groups
    SELECT 
        a.promo_group,
        a.num_customers,
        a.total_devices_purchased,
        a.avg_devices_per_customer,
        (a.total_devices_purchased * 100.0) / SUM(a.total_devices_purchased) OVER () AS percentage_of_total_sales,
        (SELECT total_devices_purchased FROM aggregated WHERE promo_group = 'Received Promotion') - 
        (SELECT total_devices_purchased FROM aggregated WHERE promo_group = 'No Promotion') AS difference_total_purchases
    FROM aggregated a
)

-- Display final results table with detailed analysis
SELECT * FROM summary;
