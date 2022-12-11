# 1. GLOBAL SITUATION

```sql
CREATE VIEW forestation
AS
SELECT f.country_code AS country_code,
f.country_name AS country_name,
f.year AS forest_year,
l.total_area_sq_mi AS forest_area_sq_mi,
f.forest_area_sqkm AS forest_area_sq_km,
r.region AS r_region,
 (f.forest_area_sqkm/(l.total_area_sq_mi*2.59))*100 AS percentage_forest_sqkm

FROM forest_area f
JOIN land_area l
ON f.country_code=l.country_code
AND f.year=l.year
JOIN regions r
ON l.country_code=r.country_code
ORDER BY 1 DESC;
```


## 1.a  What was the total forest area (in sq km) of the world in 1990? Please keep in mind that you can use the country record denoted as “World" in the region table.  

41282694.9

```sql
SELECT SUM (f.forest_area_sqkm) 
FROM forest_area f
WHERE year= 1990
AND country_name = 'World'
``` 
 
## 1.b. What was the total forest area (in sq km) of the world in 2016? Please keep in mind that you can use the country record in the table is denoted as “World.”


39958245.9


```sql 
SELECT SUM (f.forest_area_sqkm) 
FROM forest_area f
WHERE year= 2016
AND country_name = 'World'
```  

## 1.C What was the change (in sq km) in the forest area of the world from 1990 to 2016?

1324449

```sql
SELECT(
(SELECT SUM (forest_area_sqkm)
 FROM forest_area
WHERE year=1990 AND country_name= 'World') -
(SELECT SUM (forest_area_sqkm) 
FROM forest_area
WHERE year=2016 AND country_name= 'World')
 ) AS Difference
 ```

## 1.D. What was the percent change in forest area of the world between 1990 and 2016?

3.20824258980244 %

```sql
SELECT (((
    (SELECT forest_area_sqkm
      FROM forest_area f
      WHERE country_name = 'World'
      AND year=1990) - (SELECT forest_area_sqkm
      FROM forest_area f
      WHERE country_name = 'World'
      AND year=2016)) / ((SELECT forest_area_sqkm
      FROM forest_area f
      WHERE country_name = 'World'
      AND year=1990))) *100) AS percentage_decrease
FROM forest_area f
LIMIT 1;  
```

## 1E. If you compare the amount of forest area lost between 1990 and 2016, to which country's total area in 2016 is it closest to?

Peru	1279999.9891	44449.0109000001

```sql
SELECT country_name, 
2.59*(total_area_sq_mi) AS sqkm,
ABS (2.59*(total_area_sq_mi) - 1324449) AS difference
FROM land_area
ORDER BY ABS (2.59*(total_area_sq_mi) - 1324449) 
LIMIT 1;
```

#  2. REGIONAL OUTLOOK
## Create a table that shows the Regions and their percent forest area (sum of forest area divided by sum of land area) in 1990 and 2016. (Note that 1 sq mi = 2.59 sq km).

```sql
CREATE TABLE percent2 AS
(SELECT regions.region,
 		forest_area.year,
 		Round(((Sum(forest_area.forest_area_sqkm) / Sum(land_area.total_area_sq_mi*2.59))*100)::Numeric, 2) AS
percent_forest
 FROM regions
 JOIN forest_area 
 ON forest_area.country_code = regions.country_code
 JOIN land_area
 ON land_area.country_code = regions.country_code
 WHERE forest_area.year in ('1990','2016')
 GROUP BY regions.region, forest_area.year
 )
```

## a. What was the percent forest of the entire world in 2016? 

```sql
SELECT * FROM percent2
where year = '2016' 
and region = 'World'
ORDER BY percent_forest
```

31.38


## Which region had the HIGHEST percent forest in 2016, and which had the LOWEST, to 2 decimal places?

Lowest
```sql
SELECT * FROM percent2
where year = '2016' 
ORDER BY percent_forest
limit 1
```

Middle East & North Africa	2016	2.07
Highest
```sql
SELECT * FROM percent2
where year = '2016' 
ORDER BY percent_forest desc
limit 1
```

Latin America & Caribbean	2016	46.14


## b. What was the percent forest of the entire world in 1990? 
```sql
SELECT * FROM percent2
where year = '1990' 
and region = 'World'
ORDER BY percent_forest
```
World	1990	32.42

## Which region had the HIGHEST percent forest in 1990, 
```sql
SELECT * FROM percent2
where year = '1990' 
ORDER BY percent_forest
limit 1
```
Middle East & North Africa	1990	1.78


## Which had the LOWEST, to 2 decimal places?
```sql
SELECT * FROM percent2
where year = '1990' 
ORDER BY percent_forest desc
limit 1
```
Latin America & Caribbean	1990	51.08


## c. Based on the table you created, which regions of the world DECREASED in forest area from 1990 to 2016?
```sql
SELECT a.region,
		a.percent_forest as pf_1990,
        b.percent_forest as pf_2016,
       	(a.percent_forest - b.percent_forest) as difference
FROM percent2 a
JOIN percent2 b
	ON a.region = b.region
WHERE a.year = 1990 and b.year = 2016 and
(a.percent_forest - b.percent_forest)> 0
```


# 3. COUNTRY-LEVEL DETAIL


## a. Which 5 countries saw the largest amount decrease in forest area from 1990 to 2016? What was the difference in forest area for each?
```sql
SELECT a.country_name,
		c.region,
		a.forest_area_sqkm as fa_1990,
        b.forest_area_sqkm as fa_2016,
       	(a.forest_area_sqkm - b.forest_area_sqkm) as difference
FROM forest_area a
JOIN forest_area b
	ON a.country_name = b.country_name
JOIN regions c
	ON a.country_name = c.country_name
WHERE a.year = 1990 and b.year = 2016 and a.forest_area_sqkm is not null and b.forest_area_sqkm is not null
order by difference desc
 LIMIT 6;
```
## b. Which 5 countries saw the largest percent decrease in forest area from 1990 to 2016? What was the percent change to 2 decimal places for each?
```sql
SELECT a.country_name,
		c.region,
		a.forest_area_sqkm as fa_1990,
        b.forest_area_sqkm as fa_2016,
       	Round(((a.forest_area_sqkm - b.forest_area_sqkm)*100/a.forest_area_sqkm)::Numeric, 2) AS
percent

FROM forest_area a
JOIN forest_area b
	ON a.country_name = b.country_name
JOIN regions c
	ON a.country_name = c.country_name
WHERE a.year = 1990 and b.year = 2016 and a.forest_area_sqkm is not null and b.forest_area_sqkm is not null
order by percent desc
 LIMIT 5;
```

## c. If countries were grouped by percent forestation in quartiles, which group had the most countries in it in 2016?
```sql
CREATE TABLE percent3 AS
(SELECT regions.region,
        forest_area.country_name,
        forest_area.year,
        Round(((Sum(forest_area.forest_area_sqkm) / Sum(land_area.total_area_sq_mi*2.59))*100)::Numeric, 2) AS percent_forest
 FROM regions
 JOIN forest_area 
 ON forest_area.country_code = regions.country_code
 JOIN land_area
 ON land_area.country_code = regions.country_code
 GROUP BY regions.region, forest_area.country_name, forest_area.year
)

CREATE TABLE quartile AS(
SELECT country_name,
        percent_forest,
        CASE 
        WHEN percent_forest < 25 
        THEN 'Q1'
        WHEN percent_forest > 25 AND percent_forest < 50
        THEN 'Q2'
        WHEN percent_forest > 50 AND percent_forest < 75
        THEN 'Q3'
        ELSE 'Q4'
        END AS Quartile
FROM percent3
WHERE percent_forest IS NOT NULL AND year = 2016 AND country_name != ‘World’)

SELECT Quartile, COUNT (*) FROM quartile GROUP BY Quartile
ORDER BY quartile
```

## d. List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016.
```sql
SELECT * FROM percent3 WHERE percent_forest > 75 AND percent_forest < 100 and year = 2016
```
## e. How many countries had a percent forestation higher than the United States in 2016?

```sql
SELECT COUNT(*) 
FROM percent3 
WHERE percent_forest > (SELECT percent_forest from percent3 where country_name = 'United States' and year = 2016) 
 and year = 2016
```