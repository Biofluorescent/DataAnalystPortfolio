/*
	COVID-19 Data Exploration
	Data Obtained from: https://ourworldindata.org/covid-deaths

	Skills used: Joins, Aggregate Functions, CTE's, Temp Tables, Creating Views, Windows Functions, Converting Data Types
*/

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Looking at Total Case vs Total Deaths
-- Likelihood of dying if infected with covid for each country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) *100 AS death_pct
FROM CovidProject..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid-19

SELECT location, date, total_cases, population, (total_cases/population) *100 AS PctPopulationInfected
FROM CovidProject..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Looking at Countries with Highest Infection Rate compared to Population

SELECT location, MAX(total_cases) AS HighestInfectionCount, population, (MAX(total_cases)/population) *100 AS PctPopulationInfected
FROM CovidProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PctPopulationInfected DESC


-- Countries with Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC



-- BREAKING DOWN BY CONTINENT

-- Showing continents with Highest Death Count

SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidProject..CovidDeaths$
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Not entirely correct, use above query
SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC



-- Global Numbers

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases) *100 AS death_pct
FROM CovidProject..CovidDeaths$
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1,2


-- Looking at Total Population vs Vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RunningTotalVaccinations
FROM CovidProject..CovidDeaths$ dea
JOIN CovidProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3


-- USE CTE

WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RunningTotalVaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RunningTotalVaccinations
FROM CovidProject..CovidDeaths$ dea
JOIN CovidProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (RunningTotalVaccinations/Population) AS TotalVacPct
FROM PopVsVac
ORDER BY 2, 3



-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RunningTotalVaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RunningTotalVaccinations
FROM CovidProject..CovidDeaths$ dea
JOIN CovidProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3


SELECT *, (RunningTotalVaccinations/Population) AS TotalVacPct
FROM #PercentPopulationVaccinated
ORDER BY 2, 3




-- Creating Views to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RunningTotalVaccinations
FROM CovidProject..CovidDeaths$ dea
JOIN CovidProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL


CREATE VIEW PercentPopulationInfected AS
SELECT location, date, total_cases, population, (total_cases/population) *100 AS PctPopulationInfected
FROM CovidProject..CovidDeaths$
WHERE continent IS NOT NULL
-- ORDER BY location, date


CREATE VIEW CountryDeathCount AS
SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
-- ORDER BY TotalDeathCount DESC

CREATE VIEW CountryInfections AS
SELECT location, MAX(total_cases) AS HighestInfectionCount, population, (MAX(total_cases)/population) *100 AS PctPopulationInfected
FROM CovidProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
--ORDER BY PctPopulationInfected DESC