
/*	In this project, we will be looking at Covid data from January 2020 to April 2021.
	We will be doing the following:
		1. Clean and convert data fields of interest
		2. Find the continents with the highest infection rate
		3. Find the continents with the highest Covid mortality rate
		4. Comparison of the top 10 countries with the highest infection rate, Covid moratility rate, Covid hospitalization rate
		   and percentage of severe (ICU) cases vs. total hospitalizations
		5. Find the countries with the highest vaccination rates
		6. Effect of vaccination to the Covid infection and mortality rate in the Philippines
	*/

----------------------------------------------------------------------------------------------------

-- Quick check on the tables

SELECT *
FROM SQLDataExploration..CovidDeaths
ORDER BY 3, 4

SELECT *
FROM SQLDataExploration..CovidVaccinations
ORDER BY 3, 4

----------------------------------------------------------------------------------------------------

-- (1) Clean and convert data fields of interest

---- After checking the columns, we found out that the following data fields of interest are in nvarchar(255) format:
---- total_deaths, new_deaths, icu_patients and hosp_patients columns in CovidDeaths table
---- new_tests, total_tests, total_vaccinations and new_vaccinations columns in CovidVaccinations table
---- We will also convert the date column in both tables to date format since time is irrelevant in our data exploration

ALTER TABLE SQLDataExploration..CovidDeaths ALTER COLUMN total_deaths FLOAT
ALTER TABLE SQLDataExploration..CovidDeaths ALTER COLUMN new_deaths FLOAT
ALTER TABLE SQLDataExploration..CovidDeaths ALTER COLUMN icu_patients FLOAT
ALTER TABLE SQLDataExploration..CovidDeaths ALTER COLUMN hosp_patients FLOAT

ALTER TABLE SQLDataExploration..CovidVaccinations ALTER COLUMN new_tests FLOAT
ALTER TABLE SQLDataExploration..CovidVaccinations ALTER COLUMN total_tests FLOAT
ALTER TABLE SQLDataExploration..CovidVaccinations ALTER COLUMN total_vaccinations FLOAT
ALTER TABLE SQLDataExploration..CovidVaccinations ALTER COLUMN new_vaccinations FLOAT

ALTER TABLE SQLDataExploration..CovidDeaths ALTER COLUMN date DATE

ALTER TABLE SQLDataExploration..CovidVaccinations ALTER COLUMN date DATE

----------------------------------------------------------------------------------------------------

-- (2) Find the continents with the highest infection rate

---- After checking the data, we found out that continents (i.e., Asia, Africa) are also present in the location column
---- Thus, we can do it in two ways: (A) using the location column and (b) using the continents column
---- In computing the infection rate per coninent, we will use the location column

---- Using the location column

SELECT location AS Continent, ROUND((MAX(total_cases)/population) * 100, 2) AS InfectionRate
FROM SQLDataExploration..CovidDeaths
WHERE continent IS NULL		-- continent is null when the location pertains to the continent
GROUP BY location, population
ORDER BY 2 DESC

----------------------------------------------------------------------------------------------------

-- (3) Find the continents with the highest Covid mortality rate

---- Similar above, we can also do this in two ways: (A) using the location column and (b) using the continents column
---- In computing for the continents' mortality rate, we use the continent column

---- Using the continent column

SELECT ConCases.continent AS Continent,
	ROUND((SUM(ConCases.TotalDeaths) / SUM(ConCases.TotalCases)) * 100, 2) AS CovidMortalityRate
FROM (
	SELECT continent, location, MAX(total_cases) AS TotalCases,
		MAX(total_deaths) AS TotalDeaths
	FROM SQLDataExploration..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY continent, location
	) AS ConCases
GROUP BY ConCases.continent
ORDER BY 2 DESC

----------------------------------------------------------------------------------------------------

-- (4) Comparison of the top 10 countries with the highest infection rate, Covid moratility rate, Covid hospitalization rate
--	   and percentage of severe (ICU) cases

SELECT TOP 10
	location AS Country, ROUND(MAX(total_cases) / (MAX(population)) * 100, 2) AS InfectionRate,
	ROUND(MAX(hosp_patients) / (MAX(total_cases)) * 100, 2) AS CovidHospRate,
	ROUND(MAX(icu_patients) / (MAX(total_cases)) * 100, 2) AS PercentSevereCases,
	ROUND(MAX(total_deaths) / (MAX(total_cases)) * 100, 2) AS CovidMortalityRate
FROM SQLDataExploration..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 3 DESC		-- Showing the countries with the highest percentage of severe cases

---- Simply change the value of the order by to show the top 10 countries with the highest infection rate (2),
---- Covid hospitalization rate (3), percentage of severe cases (4) or Covid mortality rate (5)

----------------------------------------------------------------------------------------------------

-- (5) Find the countries with the highest vaccination rates

SELECT CD.location AS Country,-- CD.population AS Population, CV.total_vaccinations AS TotalVacc,
	ROUND((MAX(CV.total_vaccinations) / MAX(CD.population)) * 100, 2) AS VaccRate
FROM SQLDataExploration..CovidDeaths AS CD
JOIN SQLDataExploration..CovidVaccinations AS CV
	ON CD.location = CV.location
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
GROUP BY CD.location
ORDER BY 2 DESC

---- Vaccination rates exceeding 100% might be due to high number of tourists / non-citizens
---- present in these countries

----------------------------------------------------------------------------------------------------

-- (6) Effect of vaccination to the Covid infection and mortality rate in the Philippines

WITH PHVaccData (Date, Population, NewVacc, TotalVacc,
	NewCases, TotalCases, NewDeaths, TotalDeaths)
AS (
SELECT CD.date AS Date, population AS Population, new_vaccinations AS NewVacc,
	SUM(new_vaccinations) OVER
		(PARTITION BY CD.location
		ORDER BY CD.date) AS TotalVacc,
	new_cases AS NewCases,
	SUM(new_cases) OVER
		(PARTITION BY CD.location
		ORDER BY CD.date) AS TotalCases,
	new_deaths AS NewDeaths,
	SUM(new_deaths) OVER
		(PARTITION BY CD.location
		ORDER BY CD.date) AS TotalDeaths
FROM SQLDataExploration..CovidDeaths AS CD
JOIN SQLDataExploration..CovidVaccinations AS CV
	ON CD.location = CV.location AND
	CD.date = CV.date
WHERE CD.location = 'Philippines')

SELECT Date, TotalVacc, ROUND((TotalVacc / population) * 100, 2) AS VaccRate, TotalCases,
	ROUND(((AVG(NewCases) OVER (ORDER BY Date)) / population) * 100, 5) AS AvgDailyInfectionRate,
	TotalDeaths,
	ROUND(((AVG(NewDeaths) OVER (ORDER BY Date)) / population) * 100, 5) AS AvgDailyMortalityRate
FROM PHVaccData
WHERE Date LIKE '2021%'

---- After looking at the Philippine data in 2021, the average daily infection rate and mortality rate
---- did not decrease despite the increase in vaccination efforts. It might be because vaccinations in
---- the Philippines were conducted late. Comparing the data with countries that started mass vaccinations
---- prior 2021 (i.e. U.S.), their average infection and mortality rate decreased with the continued
---- vaccinations efforts

--------------------