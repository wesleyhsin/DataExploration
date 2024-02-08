/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Select Data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [coviddata].[dbo].[CovidDeaths]
order by 1, 2


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country (United States in this case)

SELECT location, date, total_cases, total_deaths, (Total_deaths/total_cases)*100 as DeathPercentage
FROM coviddeaths
Where location like '%states%'
order by 1, 2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT location, date, total_cases, population, (total_cases/population)*100 as PercentageInfected
FROM coviddeaths
Where location like '%states%'
order by 1, 2

-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) as  HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM coviddeaths
GROUP BY location, population
order by PercentPopulationInfected DESC


-- Countries with Highest Death Count per Population

SELECT location, MAX(cast(total_deaths as int)) as  HighestDeathCount
FROM coviddeaths
where continent IS NOT NULL
GROUP BY location, population
order by HighestDeathCount DESC


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) as  TotalDeathCount
FROM Coviddeaths
where continent IS NOT NULL
GROUP BY continent
order by TotalDeathCount DESC



-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage -- cast new_death to int as it is nvarchar
FROM coviddeaths
WHERE continent is not null
GRoup BY date
order by 1, 2
-- this gives the total number of new cases of the world in each day


SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage -- cast new_death to int as it is nvarchar
FROM coviddeaths
WHERE continent is not null
order by 1, 2
--Total cases and total death, and deathrate




-- Total Population vs Vaccinations
-- first join the table
-- partition by location to start the count for the sum of each location
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccine vac 
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null
order by 2,3

-- Shows Percentage of Population that has recieved at least one Covid Vaccine

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccine vac 
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null
-- order by 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query
Drop Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations bigint,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccine vac 
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null
order by 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated


Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccine vac 
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null
