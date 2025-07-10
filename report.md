# 🚗 Car Price and Feature Analysis

## 📊 Project Overview

This analysis provides a comprehensive look into how different attributes of cars such as make, model, mileage, transmission, condition, accident history, color, and features impact their prices and popularity. The dataset is structured across multiple normalized tables, and insights were extracted using **SQL** for deeper understanding.

---

## 🛠️ Methodology

**Data Source**: The data was collected and normalised into a database with the following key tables:
```
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
```

* `fact` – Core dataset with car listings
* `make`, `model`, `year`, `color`, `condition`, `fuel_type`, `transmission`, `accident`, `options` – Dimensional tables providing attribute information

**Joins**: SQL `INNER JOIN`s were used to merge these tables with `fact`, enabling feature-rich queries.

**Statistical Techniques Used**:

* `AVG()`, `MAX()`, and `MIN()` for aggregations
* `PERCENTILE_CONT()` for calculating medians
* Grouping and filtering to explore feature correlations and trends

---

## 🔍 Key Insights

### 1. 💰 Price & Value Analytics

#### A. Average, Median, and Maximum Price by Make and Model

* Each car make and model was analyzed to determine **average**, **maximum**, and **median** prices.
```
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
order by average_price desc
```
![Image](https://github.com/user-attachments/assets/052a99a5-0201-4856-b934-5e11c1470f98)![Image](https://github.com/user-attachments/assets/fa7b1271-b79d-40ba-8d5f-eef25c50bc49)![Image](https://github.com/user-attachments/assets/50e8a703-fefc-4216-b34c-2ce1891db8c4)![Image](https://github.com/user-attachments/assets/ff529060-b2da-4d8d-8cb4-83b67fe5b93a)![Image](https://github.com/user-attachments/assets/164f09c0-4675-4948-b2e2-6897916c6fed)![Image](https://github.com/user-attachments/assets/edb1fd48-d484-492a-b339-fb21fd0e8d22)![Image](https://github.com/user-attachments/assets/88573ef9-73d0-44d9-b51b-8665c2e90f59)

* Average Price
•	General Range:
o	Most mainstream vehicles: $21,000 – $25,000
o	Luxury brands (Porsche, Tesla, Mercedes-Benz): $80,000 – $100,000
o	Ultra-luxury brands (Bugatti, Bentley, McLaren): $190,000 – $210,000+
* Maximum Price
•	Peak Values:
o	Many luxury and exotic models top out near $299,000
o	Most mainstream brands max around $49,000 – $50,000
* Median Price
•	Typical Midpoints:
o	Mainstream cars: $21,000 – $24,000
o	Mid-luxury cars: $24,000 – $26,000
o	Exotic/luxury brands maintain high medians around $190,000 – $215,000

* Luxury cars (e.g., Bugatti, Aston Martin) dominate the top of all price metrics, Porsche and Tesla show large gaps between average and median, indicating multiple trims from entry-level to premium, Mainstream brands (Toyota, Honda, Hyundai) offer stable, consistent pricing across all metrics. Budget cars (Fiat, Nissan) stay within a tight range with low max and median values.



#### B. Impact of Mileage on Price
```
select b.car_make, avg(a.mileage) as mileage, avg(a.price) as price 
from fact a
	inner join make b on a.Car_MakeID = b.Car_MakeID --we will know more using a visualization technique
	group by b.car_make
	order by mileage asc
```
![Image](https://github.com/user-attachments/assets/808330da-8341-408f-9453-1a6025f5765d)
![Image](https://github.com/user-attachments/assets/a91b2ba9-99f2-4676-ac60-0768ccc27b97)

* Generally, **higher mileage** correlated with **lower average prices**, particularly.
* A clear **inverse relationship** was seen—reinforcing that lower mileage increases resale value.

#### C. Price by Fuel Type
```
select b.fuel_type, round(avg(a.Price),1) as average_price 
from fact a
	inner join fuel_type b on a.Fuel_TypeID = b.Fuel_TypeID
	
	group by b.Fuel_Type
	order by average_price desc
```
![Image](https://github.com/user-attachments/assets/6d452567-56de-410f-9d72-5d7bc94a662c)

* **Petrol** was the most common and showed moderate pricing.
* **Petrol** vehicles have the highest average price by far, Likely due to luxury brands (e.g., Ferrari, McLaren, Bugatti) still using petrol engines. **Electric, Diesel, and Hybrid** cars are priced within a similar mid-range ($45k–$47k). **Gasoline** (likely standard internal combustion) has the lowest average price, around $22,763.

---

### 2. 🔧 Condition & Accident Insights

#### A. Price Differences by Condition
```
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
```
![Image](https://github.com/user-attachments/assets/a3f2d17f-1b61-4088-a504-2783855ee325)

* **Like New cars** have the highest average and median prices, slightly more than both **New and Used cars**, This could reflect a concentration of high-end or luxury models in that category.
* **New cars** have the lowest minimum price, likely from entry-level vehicles or promotional offers.
* **Used cars** have the lowest median price, indicating more affordability and possibly a wider range of older, depreciated models.

#### B. Accident History Impact
```
select b.car_make, c.accident, avg(a.Price) as average_price 
from fact a
		inner join make b on a.Car_MakeID = b.Car_MakeID
		inner join accident c on a.AccidentID = c.AccidentID
	group by b.car_make, c.accident
	order by b.car_make, c.accident asc
```
![Image](https://github.com/user-attachments/assets/e8a25553-a566-4e7a-ae8a-1afd4c78b46f)

* Cars with accident records consistently sold for **less**, sometimes up to **15–20% lower** in price depending on make.

#### C. Mileage vs. Accident History
```
select b.car_make, c.accident, avg(a.mileage) as average_mileage 
from fact a
		inner join make b on a.Car_MakeID = b.Car_MakeID
		inner join accident c on a.AccidentID = c.AccidentID
	group by b.car_make, c.accident
	order by b.car_make, c.accident
```
![Image](https://github.com/user-attachments/assets/712e935e-b25e-47c2-bf0e-480211f3946a)

* Cars **without accidents** had slightly **higher mileage averages**, suggesting more regular use but fewer critical events.

---

### 3. ⚙️ Transmission & Fuel Trends
#### A. Transmission Type Popularity
```
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
```
![Image](https://github.com/user-attachments/assets/24959633-53a8-4ce1-9cdb-314bfd86ffb1)

* Around **50.2% were automatic** and **49.8% manual**.
* Automatic transmissions were more dominant, especially in newer cars.

#### B. Most Expensive Fuel Type
```
select top 1 b.Fuel_Type, avg(price) as average_price 
from fact a
	inner join fuel_type b on a.Fuel_TypeID = b.Fuel_TypeID
		group by b.Fuel_Type
	order by average_price desc
```
![Image](https://github.com/user-attachments/assets/727953cc-ad36-44eb-bf54-6816d705b24e)

* **Petrol vehicles** ranked highest in average pricing.

#### C. Common Fuel & Transmission Combos
```
select b.fuel_type, c.transmission, count(*) as combination_count 
from fact a
	inner join fuel_type b on a.Fuel_TypeID = b.Fuel_TypeID
	inner join transmission c on a.TransmissionID = c.TransmissionID

	group by b.fuel_type, c.transmission
	order by combination_count desc
```

![Image](https://github.com/user-attachments/assets/357e3105-d369-4770-a724-52cd14f8f4d8)

* **Diesel-Automatic** and **Hybrid-Automatic** were the most common pairings.

---

### 4. 🚘 Make & Model Analysis

#### A. Most Frequently Appearing Makes
```
select top 5 b.car_make, count(*) as car_frequency 
from fact a
		inner join make b on a.Car_MakeID = b.Car_MakeID
	group by b.Car_Make
	order by car_frequency desc
```

![Image](https://github.com/user-attachments/assets/3e5951d6-9ed9-4941-818d-81770224a4e5)

* Top brands included **Porsce**, **BMW**, and **Chevy** all with high frequency in listings.

#### B. Most Expensive Make/Model Combos
```
select top 5 b.car_make, c.car_model, sum(a.price) most_expensive_cars 
from fact a
		inner join make b on a.Car_MakeID = b.Car_MakeID
		inner join model c on a.Car_ModelID = c.Car_ModelID
		group by b.car_make,c. car_model
		order by most_expensive_cars desc
```
![Image](https://github.com/user-attachments/assets/82985674-0a7d-458c-b986-d0b8d0cfb391)

* Luxury combinations like **Bugatti-Veyron** and **Bugatti-Chiron** had the highest total listed prices.

#### C. Electric/Hybrid Popularity by Brand
```
select top 10 b.car_make, c.fuel_type, count(*) as numbers, round(100.0 * count(*) / sum(count(*)) over (), 1) as percentage
from fact a
		inner join make b on a.Car_MakeID = b.Car_MakeID
		inner join fuel_type c on a.Fuel_TypeID = c.Fuel_TypeID
		where c.fuel_type in ('electric', 'hybrid')
		group by b.car_make, c.fuel_type
		order by percentage desc;
```
![Image](https://github.com/user-attachments/assets/665f9781-e260-4ac1-b151-4ce017291f2c)

* **Porsche**, **Chrysler**, and **Honda** had the **highest percentage** of electric or hybrid entries.

---

### 5. 🧰 Feature Impact

#### A. Most Common Features
```
select top 10 b.Options_Features, count(*) as occurence, round(100.0*count(*)/sum(count(*)) over (), 2) as percent_occurence  
from fact a
		inner join options b on a.Options_FeaturesID = b.Options_FeaturesID
		group by b.Options_Features
		order by occurence desc
```

* **Bluetooth**, **Backup Camera**, and **GPS** were the most frequent features listed.

#### B. Premium vs. Basic Features
```
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
```

* Cars with **premium features** (defined as 2+ listed options) had significantly **higher average prices**, especially among newer models.

---

### 6. 🎨 Color & Aesthetics

#### A. Price by Car Color
```
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
```

* **Black**, **White**, and **Metallic Grey** fetched **higher median prices**.
* Bright colors like **Yellow** or **Green** had mixed pricing patterns.

#### B. Most and Least Common Colors
```
select b.color, count(*) as Occurence
from fact a
						inner join color b on a.ColorID = b.ColorID
		group by b.color
		order by occurence desc	
```

* **White** was the **most common**, followed by **Silver** and **Black**.
* **Brown** and **Purple** were the least common.

---

## 📌 Recommendations

1. **Dealers** can price inventory more competitively by understanding make/model and condition price patterns.
2. **Buyers** should consider fuel type, transmission, and accident history for cost-efficient choices.
3. **Marketing teams** can use color and feature trends to inform promotion strategies.
4. **Sellers** can increase listing value with verified condition and feature documentation.

---

