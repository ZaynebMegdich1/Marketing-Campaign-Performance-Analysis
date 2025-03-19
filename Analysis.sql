-- Product Overview Analysis
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
