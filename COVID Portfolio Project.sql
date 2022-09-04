SELECT * 
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT null
order by location,date

--SELECT * 
--FROM PortfolioProject..CovidVaccinations$
--order by 3,4

--Select Data that we are going to be using

SELECT Location,date,total_cases,new_cases,total_deaths,population
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT null
order by location, date

-- Looking at the TOTAL CASES vs Total Deaths.

--How many cases and how many deaths for every cases
--% of death of those who had a case.
--Shows likelihood of death aas a result from COVID in 2021 in South Africa

SELECT Location,date,total_cases,total_deaths,((total_deaths/total_cases)*100) AS Death_Percentage
FROM PortfolioProject..CovidDeaths$
WHERE location like '%South Africa%' AND continent IS NOT null
order by location, date

-- Looking at the TOTAL CASES vs Population i.e., How much of the population has had COVID so far or before..

SELECT Location,date,population, total_cases,((total_cases/population)*100) AS InfectedPopulationPercentage
FROM PortfolioProject..CovidDeaths$
WHERE location like '%South Africa%'
AND continent IS NOT null
order by location, date

-- Which countries have the highest infection rates compared to the population
SELECT Location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)*100) AS InfectedPopulationPercentage
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%South Africa%'
GROUP BY location,population
order by InfectedPopulationPercentage desc


--Showing Countries with Highest Death Count Per Population
SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount, MAX((total_deaths/population)*100) AS TotalDeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT null
--WHERE location like '%South Africa%'
GROUP BY location
order by TotalDeathCount desc


--LETS BREAK THINGS DOWN BY CONTINENT - SO WE CAN DRILL DOWN IN OUR VISUALIZATION
SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount, MAX((total_deaths/population)*100) AS TotalDeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS null
--WHERE location like '%South Africa%'
GROUP BY continent
order by TotalDeathCount desc

--LETS BREAK THINGS DOWN BY CONTINENT - DATA WAS WONKEY ...HERE IS THE CORRECT DATA FOR FACTUAL PURPOSES...
SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount, MAX((total_deaths/population)*100) AS TotalDeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS null
--WHERE location like '%South Africa%'
GROUP BY location
order by TotalDeathCount desc


--SHOW CONTINENTS WITH HIGHEST DEATH COUNT PER POPULATION PERCENTAGE
SELECT continent, MAX((total_deaths/population)*100) AS TotalDeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS not null
--WHERE location like '%South Africa%'
GROUP BY continent
order by TotalDeathPercentage desc


--GLOBAL NUMBERS -> Across the world these were the figures

SELECT SUM(new_cases) AS Total_Cases,SUM(cast (new_deaths as int)) AS Total_Deaths,SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS Death_Percentage
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%South Africa%' 
WHERE continent IS NOT null
--GROUP BY date
order by 1,2


-- All deaths across the world as a percentage of world population
SELECT SUM(new_cases) AS Total_Cases,SUM(cast (new_deaths as int)) AS Total_Deaths,SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS Death_Percentage
FROM PortfolioProject..CovidDeaths$
--WHERE location like '%South Africa%' 
WHERE continent IS NOT null
--GROUP BY date
order by 1,2


--We are first joining the tbls together using then location and date columns
--What is the total number of people in the world who have been vaccinated
SELECT * 
FROM PortfolioProject..CovidDeaths$ AS DEA
JOIN PortfolioProject..CovidVaccinations$ AS VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date

--What is the total number of people in the world who have been vaccinated - Showing new vaccinations per day!
SELECT DEA.continent,DEA.location,dea.date, dea.population, vac.new_vaccinations, SUM(cast(new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) 
AS Rolling_People_Vaccinated
-- basically it will count up / incrementally add until each location..when it changes it starts again
,--(Rolling_People_Vaccinared\population)*100 #YOU CANT CALCULATE FROM A COLUMN YOU JUST MADE!!
FROM PortfolioProject..CovidDeaths$ AS DEA
JOIN PortfolioProject..CovidVaccinations$ AS VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date
WHERE dea.continent IS NOT null
--GROUP BY date
ORDER BY 2,3

-- WE WANT TO USE THE NUMBER WE JUST CALCULATED I.E., ROLLING_PEOPLE_VACCINATED TO CALCULATE HOW MANY ARE VACCINATED IN THAT COUNTRY AS AN OUTPUT AS WELL...
--SO WE MAKE A CTE OR A TEMP TABLE TO BE ABLE TO DO THAT...

--MAKE CTE FIRST..

With PopvsVac (Continent,location,date,population,new_vaccinations, Rolling_People_Vaccinated) as -- the columns up here must match with those inside the CTE or subquery

(SELECT DEA.continent,DEA.location,dea.date, dea.population, vac.new_vaccinations, SUM(cast(new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) 
AS Rolling_People_Vaccinated
-- basically it will count up / incrementally add until each location..when it changes it starts again
--Rolling_People_Vaccinated/Population)*100
FROM PortfolioProject..CovidDeaths$ AS DEA
JOIN PortfolioProject..CovidVaccinations$ AS VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date
WHERE dea.continent IS NOT null
--GROUP BY date
--ORDER BY 2,3) THIS SHOULD NOT BE IN HERE
)
SELECT * , (Rolling_People_Vaccinated/population)*100
FROM PopvsVac

-- FROM HERE WE CAN GO FURTHER AND CALCULATE THE PERCENTAGES FDROM THE CALCULATED COLUMN 'Rolling_People_Vaccinated'



--TEMP TABLE
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
-- basically it will count up / incrementally add until each location..when it changes it starts again
--Rolling_People_Vaccinated/Population)*100
FROM PortfolioProject..CovidDeaths$ AS DEA
JOIN PortfolioProject..CovidVaccinations$ AS VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date
WHERE dea.continent IS NOT null
--GROUP BY date
--ORDER BY 2,3) THIS SHOULD NOT BE IN HERE

SELECT *,(Rolling_People_Vaccinated/population)*100
FROM #PercentPopulationVaccinated


--CREATING A VIEW TO STORE DATA FOR LATER VISUALISATION

Create view PercentPopulationVaccinated as 
SELECT DEA.continent,DEA.location,dea.date, dea.population, vac.new_vaccinations, SUM(cast(new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) 
AS Rolling_People_Vaccinated
-- basically it will count up / incrementally add until each location..when it changes it starts again
--Rolling_People_Vaccinated/Population)*100
FROM PortfolioProject..CovidDeaths$ AS DEA
JOIN PortfolioProject..CovidVaccinations$ AS VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date
WHERE dea.continent IS NOT null

--ORDER BY 2,3)

SELECT * FROM PercentPopulationVaccinated