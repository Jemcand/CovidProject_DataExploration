/*  Covid 19 Data Exploration
Skills to use: Joins, CTE, Temp Table, Creating Views, Partitions, Aggreagate Functions, Order By, Group By, Cast/Convert  */

--Checking the content of the Tables to make sure evetything is there.
SELECT *
FROM PortfolioProject..CovidDeaths2
Order by 3,4

SELECT *
FROM PortfolioProject.dbo.CovidVaccinations
Order by 3,4

-- Double checking the specific tables I'll be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths2
Order by 1,2

--My Father lived in Venezuela and he Died From Covid on September 18th 2020, so he must have been part of the 530 Total_Death reflected on that date.
SELECT Location, cast(date as date) as Date, total_cases, total_deaths, (Cast(total_deaths as float) / NULLIF(CONVERT(float,total_cases),0))*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths2
Where Location like '%zuela%'
Order by 1,2 

--Percentage of People who got Covid at a Global Scale.
SELECT Location, cast(date as date) as Date, total_cases, population, (Cast(total_cases as float) / NULLIF(CONVERT(float,population),0))*100 as PercentPeopleInfected
FROM PortfolioProject..CovidDeaths2
Order by 1,2 

--Percentage of Highest Infection Rate based on Population on a global Scale. 
--MAP Visualization in Tableau.
SELECT Location, Population, MAX(convert(float,total_cases)) AS HighestInfectCount, MAX(Cast(total_cases as float) / NULLIF(CONVERT(float,population),0))*100 as PercentPeopleInfected
FROM PortfolioProject..CovidDeaths2
Group By Location, Population
Order by PercentPeopleInfected desc

--Time Based Increment of Cases by Population.
--Graph Visualization in Tableau.
SELECT Location, Population, cast(date as date) as Date, MAX(convert(float,total_cases)) AS HighestInfectCount, MAX(Cast(total_cases as float) / NULLIF(CONVERT(float,population),0))*100 as PercentPeopleInfected
FROM PortfolioProject..CovidDeaths2
Group By Location, Population, cast(date as date)
Order by PercentPeopleInfected desc

--Total Numbers by Continents
--Bar Chart Visualization in Tableau.
Select continent, SUM(CONVERT(int,new_deaths)) as TotalDeathCount
From PortfolioProject..CovidDeaths2
Where continent is not null
and continent not in (' ')
group by continent
order by TotalDeathCount desc

--Final Numbers by Globe
--Chart Visualization in Tableau.
Select SUM(Convert(float,new_cases)) as Final_Cases, SUM(cast(new_deaths as float)) as Final_Deaths, SUM(cast(new_deaths as float)) / SUM(CONVERT(float,new_cases))*100 as GlobalDeathPercent
From PortfolioProject..CovidDeaths2
Where continent is not null
Order by 1,2

--Daily Accumulative Count of Vaccines per Country.
Select dea.continent, dea.location, convert(date,dea.date) as date, population, vac.new_vaccinations,
	SUM(Convert(int,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, convert(date,dea.date)) as RollingVaccineCount
From PortfolioProject..CovidDeaths2 dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3

--Percentage of RollingVaccineCount with CTE
With PopulationVsVaccines (Continent, Location, Date, Population, New_Vaccinations, RollingVaccineCount)
as
(
Select dea.continent, dea.location, convert(date,dea.date) as date, population, vac.new_vaccinations,
	SUM(Convert(float,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, convert(date,dea.date)) as RollingVaccineCount
From PortfolioProject..CovidDeaths2 dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
)
Select *, (RollingVaccineCount/NULLIF(CONVERT(float,population),0))*100 as PercentageOfRolling
From PopulationVsVaccines

--Percentage of RollingVaccineCount  with Temporary Table
DROP Table if exists #RollingVaccinationsPercentage
Create Table #RollingVaccinationsPercentage
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVaccineCount numeric
)

Insert Into #RollingVaccinationsPercentage
Select dea.continent, dea.location, convert(date,dea.date) as date, convert(float,dea.population), convert(float,vac.new_vaccinations),
	SUM(Convert(float,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, convert(date,dea.date)) as RollingVaccineCount
From PortfolioProject..CovidDeaths2 dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Select *, (RollingVaccineCount/NULLIF(CONVERT(float,population),0))*100 as PercentageOfRolling2
From #RollingVaccinationsPercentage

--Create a View
Create View RollingVaccinationPercentage as
Select dea.continent, dea.location, convert(date,dea.date) as date, convert(float,dea.population) as population, convert(float,vac.new_vaccinations) as new_vaccinations,
	SUM(Convert(float,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, convert(date,dea.date)) as RollingVaccineCount
From PortfolioProject..CovidDeaths2 dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null