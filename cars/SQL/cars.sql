use car

select * from fact a
inner join accident b on a.AccidentID = b.AccidentID
inner join color c on a.ColorID = c.ColorID
inner join condition d on a.ConditionID = d.ConditionID
inner join fuel_type e on a.Fuel_TypeID = e.Fuel_TypeID
inner join make f on a.Car_MakeID = f.Car_MakeID
inner join model g on a.Car_ModelID = g.Car_ModelID
inner join options h on a.Options_FeaturesID = h.Options_FeaturesID
inner join transmission i on a.TransmissionID = i.TransmissionID
inner join [year] j on a.YearID = j.YearID 

--1) PRICE AND VALUE ANALYTICS
--A) What is the average, median, and max price of cars by make and model?

with stats as ( 
				select b.Car_Make, c.Car_Model, price, percentile_cont(0.5) within group (order by a.price) over (partition by b.car_make, c.car_model) as median
				from fact a
						inner join make b on a.Car_MakeID = b.Car_MakeID
						inner join model c on a.Car_ModelID = c.Car_ModelID
)
select car_make,
		car_model,
		avg(price) as average_price,
		max(price) as maximum_price,
		max(median) as median
from stats
group by car_make, car_model
order by car_make, car_model

--B) How does mileage affect the price?
select b.car_make, avg(a.mileage) as mileage, avg(a.price) as price 
from fact a
	inner join make b on a.Car_MakeID = b.Car_MakeID --we will know more using a visualization technique
	group by b.car_make
	order by mileage asc

--C) What is the average price by fuel type?
select b.fuel_type, round(avg(a.Price),1) as average_price 
from fact a
	inner join fuel_type b on a.Fuel_TypeID = b.Fuel_TypeID
	
	group by b.Fuel_Type
	order by average_price desc

--2) CONDITION AND ACCIDENT INSIGHTS
--A) How do prices compare between used, like new, and brand-new cars?
with comparison as (
					select 
					b.Condition, 
					a.Price,
					percentile_cont(0.5) within group (order by price) over (partition by condition) as median
					from fact a
						inner join condition b on a.ConditionID = b.ConditionID
						
)
select condition,
		avg(price) as average_price,
		min(price) as minimum_price,
		max(price) as maximum_price,
		max(median) as median_price
from comparison
group by condition
order by condition

--B) Do cars with an accident history sell for significantly less?
select b.car_make, c.accident, avg(a.Price) as average_price 
from fact a
		inner join make b on a.Car_MakeID = b.Car_MakeID
		inner join accident c on a.AccidentID = c.AccidentID
	group by b.car_make, c.accident
	order by b.car_make, c.accident asc

--C) What’s the average mileage of cars with and without accidents?
select b.car_make, c.accident, avg(a.mileage) as average_mileage 
from fact a
		inner join make b on a.Car_MakeID = b.Car_MakeID
		inner join accident c on a.AccidentID = c.AccidentID
	group by b.car_make, c.accident
	order by b.car_make, c.accident

--D) TRANSMISSION AND FUEL TYPE TRENDS
--What is the most common transmission type (Manual vs. Automatic)?
select 
		(Number_of_autos/23000.0)*100 as Automatic_percentage,
		(Number_of_manual/23000.0)*100 as Manual_percentage

from (

		select  
				count (case when b.transmission in ('automatic') then 1 end) as Number_of_autos, 
				count (case when b.transmission not in ('automatic') then 1 end) as Number_of_manual,
				count (case when b.transmission not in ('automatic') then 1 else 0 end) as Total_number
		from fact a
		inner join transmission b on a.TransmissionID = b.TransmissionID) as subquery

--E) Which fuel type has the highest average price?
select top 1 b.Fuel_Type, avg(price) as average_price 
from fact a
	inner join fuel_type b on a.Fuel_TypeID = b.Fuel_TypeID
		group by b.Fuel_Type
	order by average_price desc
	
--F) Which combinations of fuel type and transmission appear most often?
select b.fuel_type, c.transmission, count(*) as combination_count 
from fact a
	inner join fuel_type b on a.Fuel_TypeID = b.Fuel_TypeID
	inner join transmission c on a.TransmissionID = c.TransmissionID

	group by b.fuel_type, c.transmission
	order by combination_count desc

--3) MAKE AND MODEL ANALYSIS
--A) Which car appears most frequently?
select top 5 b.car_make, count(*) as car_frequency 
from fact a
		inner join make b on a.Car_MakeID = b.Car_MakeID
	group by b.Car_Make
	order by car_frequency desc

--B) Which make/model combinations are most expensive?
select top 5 b.car_make, c.car_model, sum(a.price) most_expensive_cars 
from fact a
		inner join make b on a.Car_MakeID = b.Car_MakeID
		inner join model c on a.Car_ModelID = c.Car_ModelID
		group by b.car_make,c. car_model
		order by most_expensive_cars desc

--C) Which brands have the highest percentage of electric or hybrid vehicles?
select top 10 b.car_make, c.fuel_type, count(*) as numbers, round(100.0 * count(*) / sum(count(*)) over (), 1) as percentage
from fact a
		inner join make b on a.Car_MakeID = b.Car_MakeID
		inner join fuel_type c on a.Fuel_TypeID = c.Fuel_TypeID
		where c.fuel_type in ('electric', 'hybrid')
		group by b.car_make, c.fuel_type
		order by percentage desc;

--4) FEATURE IMPACT
--A) Which features (e.g., Bluetooth, GPS, Backup Camera) appear most often?
select top 10 b.Options_Features, count(*) as occurence, round(100.0*count(*)/sum(count(*)) over (), 2) as percent_occurence  
from fact a
		inner join options b on a.Options_FeaturesID = b.Options_FeaturesID
		group by b.Options_Features
		order by occurence desc

--B) Is there a noticeable price difference between cars with premium features vs. basic ones?
alter table fact add feature_type varchar(10)
update Fact
	set feature_type = case 
							 when len(options_features) - len(replace(options_features, ',', '')) >= 1 then 'premium'
								else 'basic'
								end 
from fact a
		inner join options b on a.Options_FeaturesID = b.Options_FeaturesID
		

select b.car_make, c.car_model, a.feature_type, avg(a.price) as price 

from fact a
		inner join make b on a.Car_MakeID = b.Car_MakeID
		inner join model c on a.Car_ModelID = c.Car_ModelID


		group by b.car_make, c.car_model, a.feature_type
		order by b.car_make, c.car_model, a.feature_type

--5) COLOUR AND AESTHETICS
--A) Do certain car colors sell for more on average?
with car_colors as (
					select
					b.Color,
					a.price,
					percentile_cont(0.5) within group (order by a.price) over (partition by b.color) as median
					from fact a
						inner join color b on a.ColorID = b.ColorID
						 )
select color, max(median) as price from car_colors
group by color
order by price desc

--B) What are the most and least common car colors?
select b.color, count(*) as Occurence
from fact a
						inner join color b on a.ColorID = b.ColorID
		group by b.color
		order by occurence desc	