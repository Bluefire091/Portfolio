--Dataset sourced from ourworldindata.org/covid-deaths -- AS OF 09/16/21


--VERIFYING BOTH DATASETS WERE IMPORTED
SELECT *
FROM Portfolio.dbo.CovidDeaths

SELECT *
FROM Portfolio.dbo.CovidVaccinations




--ORDER BY FIRST AND SECOND COLUMNS (LOCATION AND DATE)
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio..CovidDeaths
ORDER BY 1,2 DESC




--SELECT COLUMNS + EXCLUDE COLUMNS --found on stackoverflow
SELECT * INTO TempTable
FROM Portfolio.dbo.CovidDeaths
/* Drop the columns that are not needed */
ALTER TABLE TempTable
DROP COLUMN iso_code, weekly_hosp_admissions_per_million, weekly_icu_admissions, weekly_icu_admissions_per_million
/* Get results and drop temp table */
SELECT * FROM TempTable
WHERE location like '%states%'
DROP TABLE TempTable




--TESTING [WHERE ... =] & [WHERE ... like '...']
SELECT continent, location, iso_code, total_deaths
FROM Portfolio..CovidDeaths
WHERE location = 'United States'



SELECT location, total_cases, total_deaths 
FROM Portfolio..CovidDeaths
WHERE location like 'Afg%'




--MS SQL SERVER HAS TOP INSTEAD OF LIMIT
SELECT TOP 5 *
FROM Portfolio..CovidDeaths
WHERE location = 'United States'
ORDER BY date DESC




--CURRENT DEATH RATE FOR COVID FOR THE US POPULATION
SELECT top 1 location, date, population, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM Portfolio..CovidDeaths
WHERE location = 'United States'
AND continent IS NOT NULL
ORDER BY 2 DESC




-- COVID INFECTION RATE FOR THE US POPULATION
SELECT top 1 date, location, population, total_cases, (total_cases/population)*100 AS InfectionRate
FROM Portfolio..CovidDeaths
WHERE location = 'United States'
AND continent IS NOT NULL
ORDER BY 1 DESC




--CHANGING DATA TYPE USING ALTER COLUMN
ALTER TABLE portfolio.dbo.CovidDeaths
ALTER COLUMN total_deaths int




--CHANGE DATA TYPE USING CAST
SELECT location, MAX(cast(total_cases as int)) AS Total_Cases_By_Country, MAX(total_deaths) AS Total_Deaths_By_Country
FROM Portfolio..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 1




-- TOTAL CASES & DEATHS BY COUNTRY
SELECT location, MAX(total_cases) AS Total_Cases_By_Country, MAX(total_deaths) AS Total_Deaths_By_Country
FROM Portfolio..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 1




-- COUNTRY WITH THE HIGHEST NUMBER OF DEATHS
SELECT location, MAX(total_deaths) AS Total_Deaths_By_Country
FROM Portfolio..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Total_Deaths_By_Country DESC




--GLOBAL NUMBERS
SELECT SUM(new_cases) AS total_cases, sum(cast(new_deaths as int)) AS total_deaths, sum(cast(new_deaths as int))/SUM(new_cases)*100 AS Death_Percentage
FROM Portfolio..CovidDeaths
--where location = 'United States'
WHERE continent IS NOT NULL
ORDER BY 1,2




--DEATHS BY CONTINENT
SELECT continent, MAX(cast(total_deaths as int)) AS total_death_count
FROM Portfolio..CovidDeaths
WHERE continent IS NOT NULL AND location NOT IN ('World', 'European Union', 'International')
GROUP BY continent
ORDER BY total_death_count DESC




--USING FULL JOIN
SELECT *
FROM Portfolio..CovidDeaths CD
JOIN Portfolio..CovidVaccinations CV
	ON CD.location = CV.location
	AND CD.date= CV.date




--VACCINATION RATES BY POPULATION
--AND ATERING A COLUMN DATA TYPE USING CONVERT
--USING PARTIION WITHIN A SUM CLAUSE TO CREATE A CUMALATIVE COUNT
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, SUM(CONVERT(INT, CV.new_vaccinations)) OVER (Partition BY CD.location ORDER BY CD.location, CD.date) AS Rolling_Vaccination_Count
FROM Portfolio..CovidDeaths CD 
JOIN Portfolio..CovidVaccinations CV
	ON CD.location = CV.location
	AND CD.date= CV.date
WHERE CD.continent IS NOT NULL
ORDER BY 2,3




--ATTEMPTING A CTE
WITH Pop_vs_Vac (continent, location, date, population, new_vaccinations, rolling_vaccination_count)
AS
(
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, SUM(CONVERT(INT, CV.new_vaccinations)) OVER (Partition BY CD.location ORDER BY CD.location, CD.date) AS rolling_vaccination_count
FROM Portfolio..CovidDeaths CD
JOIN Portfolio..CovidVaccinations CV
	ON CD.location = CV.location
	AND CD.date= CV.date
WHERE CD.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (rolling_vaccination_count/Population)*100 AS vaccinated_percentage
FROM Pop_vs_Vac




--TRYING A TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_vaccination_count numeric
)
INSERT INTO  #PercentPopulationVaccinated
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, SUM(CONVERT(INT, CV.new_vaccinations)) OVER (Partition BY CD.location ORDER BY CD.location, CD.date) AS rolling_vaccination_count
FROM Portfolio..CovidDeaths CD
JOIN Portfolio..CovidVaccinations CV
	ON CD.location = CV.location
	AND CD.date= CV.date
WHERE CD.continent IS NOT NULL
SELECT *, (rolling_vaccination_count/Population)*100 AS vaccinated_percentage
FROM #PercentPopulationVaccinated




--CREATING A VIEW -- MIGHT SHOW UP UNDER VIEWS IN MASTER
CREATE VIEW PercentPopulationVaccinated as
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, SUM(CONVERT(INT, CV.new_vaccinations)) OVER (Partition BY CD.location ORDER BY CD.location, CD.date) AS rolling_vaccination_count
FROM Portfolio..CovidDeaths CD
JOIN Portfolio..CovidVaccinations CV
	ON CD.location = CV.location
	AND CD.date= CV.date
WHERE CD.continent IS NOT NULL

DROP VIEW PercentPopulationVaccinated

--Github -- Bluefire091
