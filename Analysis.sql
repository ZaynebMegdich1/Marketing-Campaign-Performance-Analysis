-- Product Overview Analysis: This query provides insights into product performance, including total price, spend, inventory, impressions, clicks, conversion rate, and cost per conversion.
SELECT 
	pr.product_name,
	SUM(pr.price) AS total_price,
	SUM(f.spend_amount) AS total_spend,
	pr.inventory AS product_inventory,
	SUM(f.impressions) AS total_impressions,
	SUM(f.clicks) AS total_clicks,
	CAST((SUM(f.conversions) * 100.0 / NULLIF(SUM(f.impressions), 0)) AS DECIMAL(18,2)) AS conversion_rate,
	CAST(SUM(f.spend_amount) / NULLIF(SUM(f.conversions), 0) AS DECIMAL(18,2)) AS cost_per_conversion
FROM 
    gold.dim_product pr
INNER JOIN gold.fact f ON pr.product_id = f.product_id
INNER JOIN gold.dim_campaign c ON f.campaign_id = c.campaign_id
GROUP BY 
    pr.product_name, pr.inventory
ORDER BY 
    conversion_rate DESC;

-- Customer Overview Analysis:This query provides customer details, including full name, gender, age group, membership duration, and total impressions, ordered by membership duration.

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    c.gender,
    CASE 
        WHEN c.age BETWEEN 18 AND 30 THEN '18-30'
        WHEN c.age BETWEEN 31 AND 40 THEN '31-40'
        WHEN c.age BETWEEN 41 AND 50 THEN '41-50'
    END AS age_group,
    DATEDIFF(day, c.join_date, GETDATE()) AS customer_membership_duration,  -- Duration as days
    SUM(f.impressions) AS total_impressions
FROM 
    gold.dim_customer c
INNER JOIN 
    gold.fact f ON c.customer_id = f.customer_id
GROUP BY 
    c.customer_id, c.first_name, c.last_name, c.gender, c.age, c.join_date
ORDER BY 
    customer_membership_duration DESC;

-- Campaign Performance Analysis: -- This query provides campaign performance details, including campaign name, channel type, total spend, total impressions, total clicks, total conversions, conversion rate, and click-through rate (CTR), ordered by total conversions.

SELECT 
    campaign_name,
    COALESCE(channel_type, 'Unknown') AS channel_type,
    SUM(f.spend_amount) AS total_spend,
    SUM(f.impressions) AS total_impressions,
    SUM(f.clicks) AS total_clicks,
    SUM(f.conversions) AS total_conversions,
    CAST((SUM(f.conversions) * 100.0 / NULLIF(SUM(f.impressions), 0)) AS DECIMAL(18,2)) AS conversion_rate,
    CAST((SUM(f.clicks) * 100.0 / NULLIF(SUM(f.impressions), 0)) AS DECIMAL(18,2)) AS ctr
FROM 
    gold.dim_campaign c
INNER JOIN 
    gold.fact f ON c.campaign_id = f.campaign_id
GROUP BY 
    campaign_name, 
    channel_type, 
    c.start_date, 
    c.end_date
ORDER BY 
    total_conversions DESC;


