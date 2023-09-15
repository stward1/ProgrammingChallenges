-- this file has my answers; setup.sql can be ran with SQLite3 for setup

-- BRIEF EXPLORATORY ANALYSIS:
        -- marketing_data doesn't appear to be unique on date/campaign_id
        -- website_revenue isn't unique on date/campaign_id either
        -- this means a row in marketing_data won't relate to one row in website_revenue
        -- as a result, aggregation needs to be done within each table rather than joining first
        -- because marketing_data and website_revenue can't logically be joined together directly
SELECT * from marketing_data order by campaign_id, date;
select * from website_revenue order by campaign_id, date;
select * from campaign_info;

-- Question 1: Write a query to get the sum of impressions by day.
SELECT date, sum(impressions)
FROM marketing_data
GROUP BY date;
-- EXPLANATION: Sums impressions across each date value, assuming each represents a day.

-- Question 2: Write a query to get the top three revenue-generating states in order of best to worst. How much revenue did the third best state generate?
SELECT state, sum(revenue)
FROM website_revenue
GROUP BY state
ORDER BY sum(revenue) DESC
LIMIT 3;
-- EXPLANATION: Sums revenue per state, then sorts by revenue and shows top 3.

SELECT rev_sum
FROM
        (
        SELECT state, sum(revenue) as 'rev_sum'
        FROM website_revenue
        GROUP BY state
        ORDER BY sum(revenue) DESC
        LIMIT 3
        )
LIMIT 1 OFFSET 2;
-- EXPLANATION: Uses question 2 query as a subquery; takes the revenue sum from the third state.
-- ANSWER: $37,577 (Ohio)

-- Question 3: Write a query that shows total cost, impressions, clicks, and revenue of each campaign. Make sure to include the campaign name in the output.
SELECT name, campaign_cost, campaign_impressions, campaign_clicks, campaign_revenue
FROM campaign_info c JOIN
        (
        SELECT campaign_id,
                sum(cost) AS 'campaign_cost',
                sum(impressions) AS 'campaign_impressions',
                sum(clicks) AS 'campaign_clicks'
        FROM marketing_data
        GROUP BY campaign_id
        ) m ON c.id = m.campaign_id JOIN 
        (
        SELECT campaign_id,
                sum(revenue) AS 'campaign_revenue'
        FROM website_revenue
        GROUP BY campaign_id
        ) w ON m.campaign_id = w.campaign_id;
-- EXPLANATION: Because marketing_data and website_revenue aren't unique on date/campaign_id, they can't be joined to each other. Instead, total cost/impressions/clicks is found by summing across marketing_data; the same is done for revenue in website_revenue. Then, the two aggregate queries are joined on campaign_id; this is joined to campaign_info to lookup the name.

-- Question 4: Write a query to get the number of conversions of Campaign5 by state. Which state generated the most conversions for this campaign?
SELECT state, sum(conversions)
FROM campaign_info c JOIN
        (
        SELECT *, substr(geo, -2, 2) AS 'state'
        FROM marketing_data
        ) s ON c.id = s.campaign_id
WHERE name = 'Campaign5'
GROUP BY state;
-- EXPLANATION: Finds the state of each marketing_data row by pull the last two characters of geo; joining this to campaign_info to lookup name. Aggregates conversions across the state column and filters for Campaign5.

SELECT state
FROM
        (
        SELECT state, sum(conversions)
        FROM campaign_info c JOIN
                (
                SELECT *, substr(geo, -2, 2) AS 'state'
                FROM marketing_data
                ) s ON c.id = s.campaign_id
        WHERE name = 'Campaign5'
        GROUP BY state
        ORDER BY sum(conversions) DESC
        )
LIMIT 1;
-- EXPLANATION: Uses the question 4 query as a subquery, except it also orders by sum of conversions (most to least). To find the answer, the state of the first row is taken.
-- ANSWER: Georgia (GA)

-- Question 5: In your opinion, which campaign was the most efficient, and why?
SELECT name, campaign_revenue, campaign_cost,
        (campaign_revenue - campaign_cost) AS 'campaign_profit',
        ((campaign_revenue - campaign_cost) / campaign_cost) AS 'campaign_roi'
FROM campaign_info JOIN
        (
        SELECT campaign_id, sum(revenue) AS 'campaign_revenue'
        FROM website_revenue
        GROUP BY campaign_id
        ) r ON campaign_info.id = r.campaign_id JOIN 
        (
        SELECT campaign_id, sum(cost) AS 'campaign_cost'
        FROM marketing_data
        GROUP BY campaign_id
        ) c ON r.campaign_id = c.campaign_id
ORDER BY campaign_roi DESC;
-- EXPLANATION: As mentioned in question 3, marketing_data and website_revenue can't be joined directly. Instead, cost is aggregated across marketing_data to find campaign cost; the same is done in website_revenue to find campaign revenue. These aggregate queries are joined with campaign_id; they're also joined to campaign_info to show the name of each campaign. Campaign profit is calculated as campaign revenue minus campaign cost; this amount is divided by campaign cost to find the campaign's return on investment (ROI); this isn't in percent terms, it's in dollars (i.e. campaign_roi of 5 means every dollar of cost yielded 5 dollars of profit).
-- ANSWER: Campaign5; this campaign had the highest return on investment, where each dollar spent led to over 77 dollars of profit.

-- Question 6 (Bonus): Write a query that showcases the best day of the week (e.g., Sunday, Monday, Tuesday, etc.) to run ads.
SELECT day_of_week, (sum(conversions) / sum(impressions)) AS 'conversion_rate' 
FROM (
        SELECT *,
                CASE strftime('%w', substr(date,1, 10))
                WHEN '0' THEN 'Sunday'
                WHEN '1' THEN 'Monday'
                WHEN '2' THEN 'Tuesday'
                WHEN '3' THEN 'Wednesday'
                WHEN '4' THEN 'Thursday'
                WHEN '5' THEN 'Friday'
                WHEN '6' THEN 'Saturday'
                ELSE NULL END AS 'day_of_week'
        FROM marketing_data
)
GROUP BY day_of_week
ORDER BY avg(conversions) DESC;
-- EXPLANATION: By extracting the date component of the date column and using %w, the day of the week can be found as 0-6; these are converted into the names of the days. Then, conversions and impressions are summed across day of week in the marketing_data table and divided to find a sort of 'conversion rate'. The highest conversion rate is considered the best day metric (the idea is this is the chance of an impression leading to a conversion on each day); however, ROI could be found like in question 5 if cost was aggregated by day of week, then the process was repeated in website_revenue for revenue (calculating ROI would be the same as in question 5 from there). In this scenario, I deemed conversion rate to be the better metric for deciding campaign timing, as day-of-week ROI may be obfuscated by channel selection, ad spend, etc.
-- ANSWER: Wednesday is the best day to run ads: it has the highest conversion rate.