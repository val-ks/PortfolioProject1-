SELECT *
FROM PortfolioProject..covid_deaths$
WHERE continent IS NOT NULL
ORDER BY 3,
         4; 

--select Data that we are going to be using

SELECT LOCATION, date, total_cases_per_million,
                       new_cases_per_million,
                       total_deaths_per_million,
                       population
FROM PortfolioProject..covid_deaths$
WHERE continent IS NOT NULL
ORDER BY 1,
         2;

--looking at total cases per million vs total deaths per million
--shows likelihood of dying if you contract covid in your army

SELECT LOCATION, date, total_cases_per_million,
                       total_deaths_per_million,
                       (replace(convert(nvarchar,total_deaths_per_million), ',', '.')/total_cases_per_million)*100 AS DeathPercentage
FROM PortfolioProject..covid_deaths$
WHERE continent IS NOT NULL
ORDER BY 1,
         2;

--looking at total cases vs population

SELECT LOCATION, date, population,
                       total_cases_per_million*(population/1000000) AS total_cases,
                       (total_cases_per_million*(population/1000000)/population)*100 AS CasesPercentage
FROM PortfolioProject..covid_deaths$
WHERE continent IS NOT NULL 
ORDER BY 1,
         2;

--looking at countries with highest infection rate compared to population

SELECT LOCATION,
       population,
       max(total_cases_per_million*(population/1000000)) AS HighestInfectionCount,
       max((total_cases_per_million*(population/1000000)/population)*100) AS PercentagePopulationInfected
FROM PortfolioProject..covid_deaths$
WHERE continent IS NOT NULL
GROUP BY LOCATION,
         population
ORDER BY PercentagePopulationInfected DESC;

--showing countries with highest death count per population

SELECT LOCATION,
       max(cast(total_deaths AS int)) AS HighestDeathCount
FROM PortfolioProject..covid_deaths$
WHERE continent IS NOT NULL
GROUP BY LOCATION
ORDER BY HighestDeathCount DESC;

--showing continents with the highest death count per population

SELECT continent,
       max(cast(total_deaths AS int)) AS HighestDeathCount
FROM PortfolioProject..covid_deaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HighestDeathCount DESC;

--global numbers

SELECT sum(new_cases) AS NewCases,
       sum(cast(new_deaths AS int)) AS NewDeaths,
       sum(cast(new_deaths AS int))/sum(new_cases)*100 AS NewDeathPercentage
FROM PortfolioProject..covid_deaths$
WHERE continent IS NOT NULL 
ORDER BY 1,
         2;

--looking at total population vs vaccinations

SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       sum(convert(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location
                                                       ORDER BY dea.location,
                                                                dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..covid_deaths$ dea
JOIN PortfolioProject..covid_vaccinations$ vac ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,
         3;

--use cte

 WITH PopvsVac(continent, LOCATION, date, population, New_Vaccinations, RollingPeopleVaccinated) AS
  (SELECT dea.continent,
          dea.location,
          dea.date,
          dea.population,
          vac.new_vaccinations,
          sum(convert(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location
                                                          ORDER BY dea.location,
                                                                   dea.date) AS RollingPeopleVaccinated
   FROM PortfolioProject..covid_deaths$ dea
   JOIN PortfolioProject..covid_vaccinations$ vac ON dea.location = vac.location
   AND dea.date = vac.date
   WHERE dea.continent IS NOT NULL
)
SELECT *,
       (RollingPeopleVaccinated/Population)*100 AS RollingVaccinationPercentage
FROM PopvsVac;

--temp table

CREATE TABLE #PercentPopulationVaccinated (continent nvarchar(255), LOCATION nvarchar(255), date datetime, population numeric, new_vaccinations numeric, RollingPeopleVaccinated numeric)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       sum(convert(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location
                                                       ORDER BY dea.location,
                                                                dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..covid_deaths$ dea
JOIN PortfolioProject..covid_vaccinations$ vac ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *,
       (RollingPeopleVaccinated/Population)*100 AS RollingVaccinationPercentage
FROM #PercentPopulationVaccinated;

--creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       sum(convert(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location
                                                       ORDER BY dea.location,
                                                                dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..covid_deaths$ dea
JOIN PortfolioProject..covid_vaccinations$ vac ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *
FROM PercentPopulationVaccinated;