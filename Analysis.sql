-- ========================================
-- General Overview
-- ========================================

-- Total Number of Customers
SELECT COUNT(*) AS total_customers
FROM gold.dim_customer;

-- Total Number of Products
SELECT COUNT(*) AS total_products
FROM gold.dim_product;

-- Total Number of Campaigns
SELECT COUNT(*) AS total_campaigns
FROM gold.dim_campaign;

-- Distinct Marketing Channels Used
SELECT DISTINCT COALESCE(channel_type, 'Unknown') AS channel_type
FROM gold.dim_campaign;

-- ========================================
-- Customer Insights
-- ========================================

-- Top 5 Cities with the Most Customers
SELECT TOP(5)
    city, 
    COUNT(*) AS total_customers
FROM gold.dim_customer
GROUP BY city
ORDER BY total_customers DESC;

-- Age Distribution (Min, Max, and Average Age)
SELECT 
    MIN(age) AS min_age,
    MAX(age) AS max_age,
    AVG(age) AS avg_age
FROM gold.dim_customer;

-- ========================================
-- Product Insights
-- ========================================

-- Products with the Highest Number of Conversions
SELECT TOP(5)
    p.product_name,
    SUM(f.conversions) AS total_conversions
FROM gold.dim_product p
JOIN gold.fact f ON p.product_id = f.product_id
GROUP BY p.product_name
ORDER BY total_conversions DESC;

-- Products with the Lowest Inventory
SELECT TOP(5)
    product_name, 
    SUM(inventory) AS total_inventory
FROM gold.dim_product
GROUP BY product_name
ORDER BY total_inventory ASC;

-- ========================================
-- Campaign Insights
-- ========================================

-- Top 5 Campaigns with the Highest Spend
SELECT TOP(5)
    campaign_name, 
    SUM(f.spend_amount) AS total_spend
FROM gold.fact f
JOIN gold.dim_campaign c ON f.campaign_id = c.campaign_id
GROUP BY campaign_name
ORDER BY total_spend DESC;

-- Top 5 Most Successful Campaigns (Based on Conversions)
SELECT TOP(5)
    campaign_name, 
    SUM(f.conversions) AS total_conversions
FROM gold.fact f
JOIN gold.dim_campaign c ON f.campaign_id = c.campaign_id
GROUP BY campaign_name
ORDER BY total_conversions DESC;

-- Most Used Marketing Channels
SELECT 
    COALESCE(channel_type, 'Unknown') AS channel_type, 
    COUNT(*) AS total_campaigns
FROM gold.dim_campaign
GROUP BY channel_type
ORDER BY total_campaigns DESC;


-- ========================================
-- Advanced Analysis
-- ========================================


-- Product Overview Analysis: This query provides insights into product performance, including total price, spend, inventory, impressions, clicks, conversion rate, and cost per conversion.
SELECT 
    pr.product_name,
	SUM(pr.inventory) AS inventory,
    SUM(pr.price) AS total_price,
    SUM(f.spend_amount) AS total_spend,
	SUM(f.impressions) AS total_impressions,
	SUM(f.clicks) AS total_clicks,
	SUM(f.conversions) AS total_conversions,
    CAST((SUM(f.conversions) * 100.0 / NULLIF(SUM(f.impressions), 0)) AS DECIMAL(18,3)) AS conversion_rate,
	CAST(SUM(CAST(f.spend_amount AS DECIMAL(18,2))) / NULLIF(SUM(CAST(f.conversions AS DECIMAL(18,2))), 0) AS DECIMAL(18,2)) AS cost_per_conversion
FROM 
    gold.dim_product pr
INNER JOIN gold.fact f ON pr.product_id = f.product_id
INNER JOIN gold.dim_campaign c ON f.campaign_id = c.campaign_id
GROUP BY 
    pr.product_name
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

--Customer Engagement & Conversion Analysis by Tenure and Gender: This query performs an analysis of customer engagement and conversion metrics, segmented by both membership tenure and gender

SELECT 
    CASE 
        WHEN DATEDIFF(day, c.join_date, GETDATE()) > 365 AND DATEDIFF(day, c.join_date, GETDATE()) <= 1095 
            THEN 'Mid-Tenure Customer'
        WHEN DATEDIFF(day, c.join_date, GETDATE()) > 1095 
            THEN 'Long-Tenure Customer'
    END AS customer_tenure,  -- Category based on membership duration
    CASE 
        WHEN c.gender = 'F' THEN 'Female'
        WHEN c.gender = 'M' THEN 'Male'
    END AS gender,
    SUM(f.impressions) AS total_impressions,
    SUM(f.conversions) AS total_conversions,
    CAST((SUM(f.conversions) * 100.0 / NULLIF(SUM(f.impressions), 0)) AS DECIMAL(18,3)) AS conversion_rate,
    CAST(SUM(f.clicks) * 100.0 / NULLIF(SUM(f.impressions), 0) AS DECIMAL(18,2)) AS click_through_rate
FROM 
    gold.dim_customer c
INNER JOIN 
    gold.fact f ON c.customer_id = f.customer_id
GROUP BY 
    CASE 
        WHEN DATEDIFF(day, c.join_date, GETDATE()) > 365 AND DATEDIFF(day, c.join_date, GETDATE()) <= 1095 
            THEN 'Mid-Tenure Customer'
        WHEN DATEDIFF(day, c.join_date, GETDATE()) > 1095 
            THEN 'Long-Tenure Customer'
    END, 
    CASE 
        WHEN c.gender = 'F' THEN 'Female'
        WHEN c.gender = 'M' THEN 'Male'
    END
ORDER BY 
    customer_tenure DESC;

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

--Channel:
SELECT 
    COALESCE(channel_type,'Unkown') as channel_type,
    SUM(f.spend_amount) AS total_spend,  -- Total Spend for the campaign
    SUM(f.impressions) AS total_impressions,  -- Total Impressions
    SUM(f.clicks) AS total_clicks,  -- Total Clicks
    SUM(f.conversions) AS total_conversions,  -- Total Conversions
	CAST((SUM(f.conversions) * 100.0 / NULLIF(SUM(f.impressions), 0)) AS DECIMAL(18,3)) AS conversion_rate,
    CAST(SUM(f.clicks) * 100.0 / NULLIF(SUM(f.impressions), 0) AS DECIMAL(18,2)) AS click_through_rate
FROM 
    gold.dim_campaign c  -- Joining campaigns table
INNER JOIN 
    gold.fact f ON c.campaign_id = f.campaign_id  -- Joining fact table for campaign performance data
GROUP BY  
    channel_type
ORDER BY 
    total_conversions DESC;


