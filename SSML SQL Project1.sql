select * from PortfolioProject..CovidDeaths
where continent is not null
order by 3,4

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
where continent is not null
order by 1, 2


--Looking at Total cases VS total Deaths
--Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float))*100 AS death_rate
FROM PortfolioProject..CovidDeaths
where location like '%India%'
and continent is not null
ORDER BY 1, 2;

--Looking at Total Cases VS Population
--Shows what percentage of population got the covid
SELECT location, date, total_cases, population, (CAST(total_cases AS float) / CAST(population AS float)) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
where location like '%India%'
and continent is not null
ORDER BY 1, 2;

--Looking at cuntries with highest infection rate compared with population

SELECT location, population, max(total_cases) as highestInfectionCount, MAX((CAST(total_cases AS float) / CAST(population AS float)))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
where continent is not null
group by location, population
ORDER BY PercentPopulationInfected desc;

-- Looking at countried with highest death counts per population.

SELECT location, max(CAST(total_deaths as int)) as TotDeathCount
FROM PortfolioProject..CovidDeaths
where continent is not null
group by location
ORDER BY TotDeathCount desc;

--Breaking things down by continent

SELECT continent, max(CAST(total_deaths as int)) as TotDeathCount
FROM PortfolioProject..CovidDeaths
where continent is not null
group by continent
ORDER BY TotDeathCount desc;

--GLOBAL Numbers

SELECT date,
       SUM(new_cases) as totalCases,
       SUM(CAST(new_deaths AS int)) as total_deaths,
       CASE 
           WHEN SUM(new_cases) = 0 THEN 0  -- Handle divide by zero scenario
           ELSE (SUM(CAST(new_deaths AS int)) / NULLIF(SUM(new_cases), 0)) * 100 
       END AS death_rate
FROM PortfolioProject..CovidDeaths
--where location like '%states%'
GROUP BY date
ORDER BY 1, 2;

--total global numbers

SELECT
       SUM(new_cases) as totalCases,
       SUM(CAST(new_deaths AS int)) as total_deaths,
       CASE 
           WHEN SUM(new_cases) = 0 THEN 0  -- Handle divide by zero scenario
           ELSE (SUM(CAST(new_deaths AS int)) / NULLIF(SUM(new_cases), 0)) * 100 
       END AS death_rate
FROM PortfolioProject..CovidDeaths
--where location like '%states%'
ORDER BY 1, 2;


--Looking at total population vs vaccination

SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac ON dea.location = vac.location
                                              AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;


--using CTE
with PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as 
(
SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac ON dea.location = vac.location
                                              AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3;
)
select *, (RollingPeopleVaccinated/population)*100
from PopVsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac ON dea.location = vac.location
                                              AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL 
--ORDER BY 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated



-- Creating View to store data for later visualizations
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

select * from PercentPopulationVaccinated

