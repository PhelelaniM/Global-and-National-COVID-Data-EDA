SELECT * 
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT null
order by location,date


--Select Data that we are going to be using for visualization
SELECT Location,date,total_cases,new_cases,total_deaths,population
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT null
order by location, date


--Looking at the Total Cases vs Total Deaths then determine how many cases and how many deaths for every case per country
SELECT Location,date,total_cases,total_deaths,((total_deaths/total_cases)*100) AS Death_Percentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT null
order by location, date


--Looking at the Total Cases vs Population i.e., What percentage of the population per country have been infected before
SELECT Location,date,population, total_cases,((total_cases/population)*100) AS InfectedPopulationPercentage
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%South Africa%'
WHERE continent IS NOT null
order by location, date


-- Which countries have the highest infection rates compared relative to their population
SELECT Location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)*100) AS InfectedPopulationPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT null
GROUP BY location,population
ORDER BY InfectedPopulationPercentage desc


--Which country has the Highest Death Count relative to its Population
SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount, MAX((total_deaths/population)*100) AS TotalDeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT null
GROUP BY location
order by TotalDeathCount desc


--Lets break things down by continent, so we can have the ability to drill down in our visualizations...
--Which continent has the highest number of deaths
SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount, MAX((total_deaths/population)*100) AS TotalDeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS null
GROUP BY location
order by TotalDeathCount desc


--Which country has the highest death count per population percentage
SELECT location, MAX((total_deaths/population)*100) AS TotalDeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS null
GROUP BY location
order by TotalDeathPercentage desc



--GLOBAL PERSPECTIVE: Global view of all the COVID numbers

--What is the total death percentage relative to the population of the whole world
SELECT SUM(new_cases) AS Total_Cases,SUM(cast (new_deaths as int)) AS Total_Deaths,SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS Death_Percentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT null
order by 1,2


--What is the total number of people in the world who have been vaccinated
SELECT DEA.continent,DEA.location,dea.date, dea.population, vac.new_vaccinations, SUM(cast(new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) 
AS Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths$ AS DEA
JOIN PortfolioProject..CovidVaccinations$ AS VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date
WHERE dea.continent IS NOT null
ORDER BY 2,3

--What is the percentage of people vaccinated per country of the Rolling numbers of people vaccinated 
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_People_Vaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT DEA.continent,DEA.location,dea.date, dea.population, vac.new_vaccinations, SUM(cast(new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) 
AS Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths$ AS DEA
JOIN PortfolioProject..CovidVaccinations$ AS VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date
WHERE dea.continent IS NOT null

SELECT *,(Rolling_People_Vaccinated/population)*100
FROM #PercentPopulationVaccinated


--Creating a view to store data for visualization purposes
Create view PercentPopulationVaccinated as 
SELECT DEA.continent,DEA.location,dea.date, dea.population, vac.new_vaccinations, SUM(cast(new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) 
AS Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths$ AS DEA
JOIN PortfolioProject..CovidVaccinations$ AS VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date
WHERE dea.continent IS NOT null

SELECT * FROM PercentPopulationVaccinated