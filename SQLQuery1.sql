select *
from Telco_Churn

--TASK 1 – Basic Data Cleaning & Structure Understanding

select Count(*)
from Telco_Churn

--Check for NULLs or Invalids in Key Columns

select CustomerID
from Telco_Churn
where CustomerID is  null

--TotalCharges – May contain blanks or non-numeric values

SELECT *
FROM Telco_Churn
WHERE TRY_CAST(Total_Charges AS FLOAT) IS NULL
  AND Total_Charges IS NOT NULL;

  --tenure and MonthlyCharges – Check for NULLs

  select case when [Tenure Months] is null then 1 else 0 end , case when Monthly_Charges is null then 1 else 0 end
  from Telco_Churn

  -- Clean & Cast TotalCharges

 alter table Telco_Churn
 add CleanTotalCharges float 

update Telco_Churn
set CleanTotalCharges = TRY_CAST(Total_Charges as float)

select Total_Charges , CleanTotalCharges
from Telco_Churn

--Cheking

SELECT COUNT(*) AS ConversionFailures
FROM Telco_Churn
WHERE CleanTotalCharges IS NULL AND Total_Charges IS NOT NULL;

--Feature Engineering: Revenue & Churn Flag

alter table Telco_Churn
add MonthlyRevenue  float , IsChurned   int

update Telco_Churn
set Monthly_Charges = MonthlyRevenue , IsChurned = case when  Churn_Label = 'yes' then 1 else 0  end 

SELECT Churn_Label, IsChurned, COUNT(*) AS Count
FROM Telco_Churn
GROUP BY Churn_Label, IsChurned;

--Calculate Overall Churn Rate

select SUM(IsChurned) * 100.0 / COUNT(IsChurned)
from Telco_Churn
group by IsChurned

-- Monthly Revenue Trend by Tenure

select * from Telco_Churn

select [Tenure Months],Count(*),sum(CleanTotalCharges) as revenue
from Telco_Churn
group by [Tenure Months]
order by 1 asc

--Churn Rate by Contract Type

select distinct Contract , sum(IsChurned) * 100 / Count(IsChurned) as Churnrate
from Telco_Churn
group by Contract
order by 2 desc

--Customer Lifetime Value (LTV)

SELECT 
  CustomerID,
  CleanTotalCharges,
  [Tenure Months] AS Tenure,
  (CleanTotalCharges * [Tenure Months]) AS EstimatedLTV
FROM Telco_Churn
ORDER BY EstimatedLTV DESC;

--Cohort Analysis: Tenure Buckets

select * from Telco_Churn

with MonthSeperation as (
select  CustomerID,
case 
when [Tenure Months] between 1 and 12 then '1-12'
when [Tenure Months] between 13 and 24 then '13-24'
when [Tenure Months] between 25 and 36 then '25-36'
when [Tenure Months] between 37 and 48 then '37-48'
when [Tenure Months] between 49 and 60 then '49-60'
when [Tenure Months] between 61 and 72 then '61-72' 
end as SeparatedMonths
from Telco_Churn
where [Tenure Months] is not null

)

select M.SeparatedMonths ,count(T.CustomerID) TotalCustomer,
sum(T.IsChurned) TotalChurnedCustomer, 
round(sum(T.IsChurned)*100  / count(T.CustomerID),4 )as ChurnedRate
from Telco_Churn T
join MonthSeperation M on  t.CustomerID = M.CustomerID
group by SeparatedMonths 
order by SeparatedMonths asc

-- Advanced Window Function: Running Churn Rate Over Tenure

With RunningTotal as (
select distinct [Tenure Months]  TenureMonths,
count(CustomerID) CountCustomerID,
sum(IsChurned) CountChurned
from Telco_Churn
group by [Tenure Months]
)

select TenureMonths, CountChurned,CountCustomerID,
sum(CountCustomerID) over (order by TenureMonths) as CumulativeCustomer,
sum(CountChurned) over (order by TenureMonths) as CumulativeChurned,
Round(sum(CountChurned) over (order by TenureMonths)  * 100.0 /
nullif(sum(CountCustomerID) over (order by TenureMonths),0),2) as RunningChurnRate
from RunningTotal
order by 1 asc

--Churn Rate by Contract + Internet Service

select distinct Contract , Internet_Service,
round(sum(IsChurned)*100.0/nullif(Count(CustomerID),0),2) as ChurnedRate
from Telco_Churn
group by Contract, Internet_Service
order by 3 desc

-- Flag High-Risk Customers (Rule-Based Churn Prediction)

select CustomerID , Contract, Internet_Service,[Tenure Months] as Tenuremonths , CleanTotalCharges,
case when 
(case when Contract ='Month-to-month' then 1 else 0 end )+
(case when Internet_Service = 'Fiber optic' then 1 else 0 end )+
(case when [Tenure Months] <= 12 then 1 else 0 end)+
(case when CleanTotalCharges >= 80 then 1 else 0 end) >= 2 then 'HighRisk' else 'LowRisk' end as Customerrisk
from Telco_Churn

--Churn Driver Insights (Descriptive Analysis)

select Contract,
Count(CustomerID)TotalCustomer,
sum(IsChurned) TotalCrurnedCustomer , 
round(sum(IsChurned)*100.0/nullif(Count(CustomerID),0),2) As ChurnRate
from Telco_Churn
group by Contract

select Internet_Service , Count(CustomerID)TotalCustomer,sum(IsChurned) TotalCrurnedCustomer ,
round(sum(IsChurned)*100.0/nullif(Count(CustomerID),0),2) As ChurnRate
from Telco_Churn
group by Internet_Service

select Payment_Method , Count(CustomerID)TotalCustomer,sum(IsChurned) TotalCrurnedCustomer ,
round(sum(IsChurned)*100.0/nullif(Count(CustomerID),0),2) As ChurnRate
from Telco_Churn
group by Payment_Method

select Senior_Citizen , Count(CustomerID)TotalCustomer,sum(IsChurned) TotalCrurnedCustomer ,
round(sum(IsChurned)*100.0/nullif(Count(CustomerID),0),2) As ChurnRate
from Telco_Churn
group by Senior_Citizen

--Churn vs Non-Churn Full Comparison Table

select case when IsChurned= 1 then 'Yes' else 'No' end as Churned,count(CustomerID)TotalCustomer, 
round(avg([Tenure Months]),2) as AverageTenure, 
round(avg(Total_Charges),2) AvgTotalCharge,
round(avg(CleanTotalCharges),2) AvgCleancharge
from Telco_Churn
group by IsChurned