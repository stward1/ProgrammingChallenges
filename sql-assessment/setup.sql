-- refer to answers.sql for my answers; this is just for setting up in SQLite3

-- SETUP: Making marketing_data, website_revenue, and campaign_info tables
create table marketing_data (
 date datetime,
 campaign_id varchar(50),
 geo varchar(50),
 cost float,
 impressions float,
 clicks float,
 conversions float
);

create table website_revenue (
 date datetime,
 campaign_id varchar(50),
 state varchar(2),
 revenue float
);

-- NOTE: auto_increment was removed because the ID values are given in the CSV
create table campaign_info (
 id int not null primary key,
 name varchar(50),
 status varchar(50),
 last_updated_date datetime
);

-- IMPORT: Importing CSV files into tables (SQLite)
.import 'C:\Users\samth\Desktop\ProgrammingChallenges\sql-assessment\marketing_performance.csv' marketing_data
.import 'C:\Users\samth\Desktop\ProgrammingChallenges\sql-assessment\campaign_info.csv' campaign_info
.import 'C:\Users\samth\Desktop\ProgrammingChallenges\sql-assessment\website_revenue.csv' website_revenue

-- CLEAN UP: Removing header rows if they were inserted as records
delete from marketing_data where date = 'date';
delete from website_revenue where date = 'date';
delete from campaign_info where name = 'name';