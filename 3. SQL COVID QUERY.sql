
--EXPLORING DATA--
select * 
from dbo.CovidDeaths$
order by 3,4


--select *
--from dbo.CovidVaccinations$
--order by 3,4 


-- SELECTING THE DATA--
select 
location, date, total_cases, total_deaths, population
from dbo.CovidDeaths$
order by 1,2


--CALCULATING TOTAL CASES VS TOTAL DEATHS--
select 
location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from dbo.CovidDeaths$
where location like '%mexico%'
order by 1,2

--By the end of 2021, we could say that mexicans had a likelihood of dying if contracted Covid of 9.25%--

--ANALYZING TOTAL CASES VS POPULATION: This shows what percentage of population was infected with Covid-- 
select 
location, date, total_cases, population,(total_deaths/population)*100 as PopulationPercentage
from dbo.CovidDeaths$
where location like '%mexico%'
order by 1,2


--WHICH COUNTRIES HAD THE HIGHEST INFECTION RATE IN TERMS OF POPULATION?--
select 
location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PopulationInfectedPercentage
from dbo.CovidDeaths$
group by population,location
order by PopulationInfectedPercentage desc


--COUNTRIES WITH THE HIGHEST DEATH COUNT PER POPULATION--
select 
location, MAX(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths$
where continent is not null
group by location
order by TotalDeathCount desc


--CONTINENT WITH THE HIGHEST DEATH COUNT--
select 
continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths$
where continent is not null
group by continent
order by TotalDeathCount desc


--WORLDWIDE COVID STATISTICS BY DATE --
select 
date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast (new_deaths as int))/sum(new_cases)*100 as WorldDeathPercentage
from dbo.CovidDeaths$
where continent is not null
group by date
order by 1,2


--REMOVING DATE TO OBTAIN TOTAL GLOBALLY-- 
select 
sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast (new_deaths as int))/sum(new_cases)*100 as WorldDeathPercentage
from dbo.CovidDeaths$
where continent is not null
--group by date
order by 1,2

--Overall globally, Total Death Percentage was 2.11%. Also a total of 150,574,977 cases and 3,180,206 deaths.

--*COVID VACCINATION*--

Select * from dbo.CovidDeaths$ as dea
join dbo.CovidVaccinations$ as vax
on dea.location = vax.location
and dea.date = vax.date


--TOTAL POPULATION VS VACCINATION-- 
Select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
from dbo.CovidDeaths$ as dea
join dbo.CovidVaccinations$ as vax
  on dea.location = vax.location
  and dea.date = vax.date
where dea.continent is not null
order by 2,3



--ANALYSIS OF POPULATION VACCINATED BY LOCATION --
Select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
SUM(cast(vax.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
-- last line could also be SUM(convert(int,vax.new_vaccinations)) OVER (Partition by dea.location)
from dbo.CovidDeaths$ as dea
join dbo.CovidVaccinations$ as vax
  on dea.location = vax.location
  and dea.date = vax.date
where dea.continent is not null
order by 2,3

--The previos query allows to understand how the vaccination numbers are increasing day by day. So it sums the amount of a certain day,
-- plus the following day to get the rolling amount.



--HOW MANY PEOPLE IN A CERTAIN COUNTRY ARE VACCINATED? ** USE OF CTE ** -- 

--To get table incluiding new column "RollingPeopleVaccinated"--

With PopvsVax (continent,location,date, population,new_vaccinations, RollingPeopleVaccinated) as 
(
Select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
SUM(cast(vax.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
-- last line could also be SUM(convert(int,vax.new_vaccinations)) OVER (Partition by dea.location)
from dbo.CovidDeaths$ as dea
join dbo.CovidVaccinations$ as vax
  on dea.location = vax.location
  and dea.date = vax.date
where dea.continent is not null
--order by 2,3
)
select * 
from PopvsVax


--PERCENTAGE OF ROLLING PEOPLE VACCINATED OVER POPULATION --

With PopvsVax (continent,location,date, population,new_vaccinations, RollingPeopleVaccinated) as 
(
Select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
SUM(cast(vax.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
-- last line could also be SUM(convert(int,vax.new_vaccinations)) OVER (Partition by dea.location)
from dbo.CovidDeaths$ as dea
join dbo.CovidVaccinations$ as vax
  on dea.location = vax.location
  and dea.date = vax.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/Population)*100 as RollingVaccinatedPop
from PopvsVax

--According to the data query, 12% of the population in Albania is vaccinated in the latest date available in the data set -- 



--GLOBAL TOTAL OF ROLLING PEOPLE VACCINATED OVER POPULATION--

WITH PopvsVax (continent, location, population, new_vaccinations, RollingPeopleVaccinated) AS 
(
    SELECT dea.continent, dea.location, dea.population, vax.new_vaccinations,
    SUM(CAST(vax.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location) AS RollingPeopleVaccinated
    FROM dbo.CovidDeaths$ AS dea
    JOIN dbo.CovidVaccinations$ AS vax
    ON dea.location = vax.location
    WHERE dea.continent IS NOT NULL
)
, ContinentPopvsVax AS
(
    SELECT continent, 
           SUM(population) AS TotalPopulation,
           SUM(cast(new_vaccinations as bigint)) AS TotalNewVaccinations,
           SUM(RollingPeopleVaccinated) AS TotalRollingPeopleVaccinated
    FROM PopvsVax
    GROUP BY continent
)
SELECT cpv.*, (cpv.TotalRollingPeopleVaccinated / cpv.TotalPopulation) * 100 AS RollingVaccinatedPop
FROM ContinentPopvsVax cpv;



--TEMP TABLE -- 

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

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
, SUM(CONVERT(int,vax.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeaths$ dea
Join dbo.CovidVaccinations$ vax
	On dea.location = vax.location
	and dea.date = vax.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated



--CREATE VIEW TO STORE DATA FOR VISUALIZATION TOOL--

Create view PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
, SUM(CONVERT(int,vax.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From dbo.CovidDeaths$ dea
Join dbo.CovidVaccinations$ vax
	On dea.location = vax.location
	and dea.date = vax.date
where dea.continent is not null

--VIEW--
Select * 
from PercentPopulationVaccinated
