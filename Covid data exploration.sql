---View the Data---
SELECT *
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

UPDATE dbo.CovidDeaths
SET Date_New = TRY_CONVERT(DATE, [date], 105);
SELECT TOP 20
    [date],
    Date_New
FROM dbo.CovidDeaths;
UPDATE dbo.CovidVaccinations
SET Date_New = TRY_CONVERT(DATE, [date], 105);
SELECT TOP 20
    [date],
    Date_New
FROM dbo.CovidVaccinations;

---Select Requried Columns---
SELECT  location,Date_New,total_cases,new_cases,total_deaths,population
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

----- Total_cases vs total_deaths-----
SELECT location,Date_New,total_cases,total_deaths,
(total_deaths/total_cases)*100 as Deathpercentage
FROM dbo.CovidDeaths
WHERE location like 'in%' and continent IS NOT NULL
ORDER BY 1,2;

------ Total_cases vs Population -----
SELECT location,Date_New,total_cases,population,
(total_cases/population)*100 as infectedpercentage
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

----- Countries with highest infected rate compared to population ----
SELECT location,population,max(total_cases) as highestinfectedcount,
max(total_cases/population)*100 as infectedpercentage
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY  location,population
ORDER BY infectedpercentage desc;

----- Countries with highest death rate -------
SELECT location,max(total_deaths) as highestdeathcount
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY  location
ORDER BY highestdeathcount desc;

----- Continent with highest death rate -------
SELECT continent,max(total_deaths) as highestdeathcount
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY  continent
ORDER BY highestdeathcount desc;

----- Globalnumbers -------
SELECT Date_New,sum(new_cases) as total_cases,sum(new_deaths) as total_deaths,
sum(new_deaths)/sum(new_cases)*100 as deathpercentage
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Date_New
ORDER BY 1,2;

------ Total population vs Vaccinations ---------
SELECT dea.continent,dea.location,dea.Date_New,dea.population,vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.Date_New)
as Rollingpeoplevacinated
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.Date_New = vac.Date_New
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

------ Use CTE -----------
WITH PopvsVac (continent,location,Date_New,population,new_vaccinations,RollingPeopleVaccinated)
as
(
SELECT dea.continent,dea.location,dea.Date_New,dea.population,vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.Date_New)
as Rollingpeoplevacinated
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.Date_New = vac.Date_New
WHERE dea.continent IS NOT NULL
)
SELECT *,
       CAST(RollingPeopleVaccinated AS FLOAT) / population * 100 AS PercentVaccinated
FROM PopvsVac;

------- Temp Table -------
CREATE TABLE peoplevaccinated
(
    Continent NVARCHAR(50),
    Location NVARCHAR(100),
    Date_New DATE,
    Population BIGINT,
    New_Vaccinations FLOAT,
    RollingPeopleVaccinated FLOAT
);
INSERT INTO peoplevaccinated
SELECT
dea.continent,
dea.location,
dea.Date_New,
dea.population,
vac.new_vaccinations,
SUM(vac.new_vaccinations)
OVER(PARTITION BY dea.location ORDER BY dea.Date_New)
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac
ON dea.location = vac.location
AND dea.Date_New = vac.Date_New;

SELECT *
FROM peoplevaccinated;

SELECT
MAX(RollingPeopleVaccinated)
FROM peoplevaccinated;

DROP TABLE peoplevaccinated;

----- Creating View for Visualization --------
CREATE VIEW Populationvaccinated AS
SELECT
    dea.continent,
    dea.location,
    dea.Date_New,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations)
        OVER
        (
            PARTITION BY dea.location
            ORDER BY dea.Date_New
        ) AS RollingPeopleVaccinated
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.Date_New = vac.Date_New
WHERE dea.continent IS NOT NULL;
select * from Populationvaccinated;