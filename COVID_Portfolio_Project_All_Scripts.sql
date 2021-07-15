Select *
FROM CovidProject..CovidDeaths$
ORDER BY 3,4

--Select *
--FROM CovidProject..CovidVaccinations$
--ORDER BY 3,4

-- Select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths$
ORDER BY 1,2

-- Looking at total cases vs total deaths
-- Shows the liklihood of dying if you contract covid in your contry
SELECT location, date, total_cases, total_deaths, population, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM CovidProject..CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2


-- Looking at the total cases vs the population
-- Shows what percentage of population got Covid
SELECT location, date, population, total_cases, (total_cases / population) * 100 AS ContractionPercentage
FROM CovidProject..CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2


-- Looking at countries with Highest Infection Rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentePopulationInfected
FROM CovidProject..CovidDeaths$
--WHERE location like '%states%'
GROUP BY population, location
ORDER BY PercentePopulationInfected DESC


-- Showing the countries with the highest death count per population
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidProject..CovidDeaths$
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC


-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidProject..CovidDeaths$
--WHERE location like '%states%'
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Global Numbers
SELECT date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidProject..CovidDeaths$
--WHERE location LIKE '%state%'
where continent is not null
GROUP BY date
ORDER BY 1,2


-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
FROM CovidProject..CovidDeaths$ dea
	JOIN CovidProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- Use CTE

WITH PopVsVac (Continent, Location, Date, Population, NewVaccinations, RollingTotalVaccinations)
AS
(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
	FROM CovidProject..CovidDeaths$ dea
		JOIN CovidProject..CovidVaccinations$ vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent is not null
	--ORDER BY 2,3
)
SELECT *, (RollingTotalVaccinations/Population)*100 AS RollingPopVacPercent
FROM PopVsVac
ORDER BY Location



-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
NewVaccinations numeric,
RollingTotalVaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
	FROM CovidProject..CovidDeaths$ dea
		JOIN CovidProject..CovidVaccinations$ vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent is not null
	--ORDER BY 2,3

SELECT *, (RollingTotalVaccinations/Population)*100 AS RollingPopVacPercent
FROM #PercentPopulationVaccinated
ORDER BY Location



-- Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
	FROM CovidProject..CovidDeaths$ dea
		JOIN CovidProject..CovidVaccinations$ vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent is not null
	--ORDER BY 2,3


SELECT *
FROM PercentPopulationVaccinated