
--###################################################################################################################################
--                                         Initial Exploration
--####################################################################################################################################
Select *
From PortfolioProject_Covid..CovidDeaths
order by 3,4

Select *
From PortfolioProject_Covid..CovidVaccinations
order by 3,4

Select location, date , total_cases , new_cases , total_deaths , population
From PortfolioProject_Covid..CovidDeaths
order by 1,2

-- total cases total deaths and death percentage Table 1 
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject_Covid..CovidDeaths
where continent is not null 
--Group By date
order by 1,2

--Total Cases vs Total Deaths
-- Shows the Livelyhood Of Dying 
Select location, date , total_cases , total_deaths ,(total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject_Covid..CovidDeaths
where location like '%kingdom%' 
order by 1,2


--Total Cases VS Population
-- Percentage Of Population that has covid 
Select location, date , total_cases , population ,(total_cases/population)*100 as 'Percentage of Population' 
From PortfolioProject_Covid..CovidDeaths
where location like '%kingdom%' 
order by 1,2

--###################################################################################################################################
--                                continent with death count ? Table 2 
--####################################################################################################################################

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject_Covid..CovidDeaths 
Where continent is null 
and location not in ('World', 'European Union', 'International', 'Upper middle income' , 'High income ', 'Lower middle income','Low income')
Group by location
order by TotalDeathCount desc



--###################################################################################################################################
--                            Contries with Highest Infection Rate compared to population ? Table 3 
--####################################################################################################################################

Select location, population , max(total_cases) as Infections ,Max((total_cases/population)*100) as 'Percentage of Population Infected ' 
From PortfolioProject_Covid..CovidDeaths 
Group by location, population
order by 4 Desc

--###################################################################################################################################
--                               Contries with highest population Infected by date  ? Table 4
--####################################################################################################################################

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject_Covid..CovidDeaths 
Group by Location, Population, date
order by PercentPopulationInfected desc


--###################################################################################################################################
--                                countries with highest death count ?
--####################################################################################################################################

Select location , Max(cast(total_deaths as int)) as deaths
From PortfolioProject_Covid..CovidDeaths
where continent is not null
group by location
order by 2 desc



--###################################################################################################################################
--                                Contries with Highest Death count compared to population ?
--####################################################################################################################################

Select location, population , Max(cast(total_deaths  as int)) as Deaths, max(total_deaths/population) as'Death rate' 
From PortfolioProject_Covid..CovidDeaths 
where continent is not null
Group by location, population
order by 4 Desc

--###################################################################################################################################
--                                         Break By Continent
--####################################################################################################################################
-- Break Things Down by Continent (but for this it is important top know that the data has null whenever the location is a continent)

Select location , Max(cast(total_deaths as int))
From PortfolioProject_Covid..CovidDeaths
where continent is null
group by location
order by 2 desc


--Highest Death Counts by Continents 

Select continent , Max(cast(total_deaths as int)) as 'Total Death Count' 
From PortfolioProject_Covid..CovidDeaths
where continent is not null 
group by continent
order by 2 desc

--###################################################################################################################################
--                                         How TO ROllBACK SUM
--####################################################################################################################################
--Joining tables of deaths and Vaccinations and then making a readable table  where 
-- Making Rollinng Count on new Vaccinations 
-- goal is to do a rolling summ of vaccinations in each country 
-- summing over new vaccinations partitioning by location(so that the rolling sum is done 
--exclusively for different countries ) and then ordering the sum by location and date which outputs it as rolling sum. 

Select CD.continent, CD.location , CD.date ,CD.population , CV.new_vaccinations,
Sum(cast(CV.new_vaccinations as bigint)) OVER (Partition by CD.location Order by CD.location, CD.Date) as 'Total Vacinations(Rolling)' 
From PortfolioProject_Covid..CovidDeaths CD 
join PortfolioProject_Covid..CovidVaccinations CV
	on CD.location= CV.location 
	and CD.date = CV.date
where CD.continent is not null
order by 2,3

--###################################################################################################################################
--                    USE ROLLBACK FOR FURTHER CALCULATIONS using CTE or Temp table
--####################################################################################################################################
-- ##################################################
-- CTE Common Table Expression (1 Way )
-- ##################################################
-- we cannot call rolling vaccination directly in the above query because we just created it 
-- we need to project "Total Vaccination" as RollingVaccination and then use it to calculate vaccination percentage.

With CDvsCV(continent , location , date , population , new_vaccinations , RollingVaccinations)
as
(
Select CD.continent, CD.location , CD.date ,CD.population , CV.new_vaccinations,Sum(cast(CV.new_vaccinations as bigint)) OVER (Partition by CD.location Order by CD.location, CD.Date) as 'Total Vacinations' 
From PortfolioProject_Covid..CovidDeaths CD 
join PortfolioProject_Covid..CovidVaccinations CV
	on CD.location= CV.location 
	and CD.date = CV.date
where CD.continent is not null
)

Select * , (RollingVaccinations/population)*100 as " Vacinnation Percentage"
From CDvsCV

-- ##################################################
-- Temprory Table (2nd Way)
-- ##################################################

--Step1: Create a table 
-- Making sure there arnt already table with same name and also if any change is to be done in the table it acts as a clear statement.

Drop TABLE if exists #PercentagePopulationVaccinated  
Create TABLE #PercentagePopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
New_vaccinations numeric,
Rollingpeoplevaccinated numeric
)
--Step 2: Insert values into it as above 
Insert into #PercentagePopulationVaccinated

Select CD.continent, CD.location , CD.date ,CD.population , CV.new_vaccinations,Sum(cast(CV.new_vaccinations as bigint)) OVER (Partition by CD.location Order by CD.location, CD.Date) as 'Total Vacinations' 
From PortfolioProject_Covid..CovidDeaths CD 
join PortfolioProject_Covid..CovidVaccinations CV
	on CD.location= CV.location 
	and CD.date = CV.date
--where CD.continent is not null

-- Step 3: Use the temprary table to calculate vaccination percentage

Select * , (Rollingpeoplevaccinated/population)*100 as " Vacinnation Percentage"
From #PercentagePopulationVaccinated

--###################################################################################################################################
--                                         Creating View 
--####################################################################################################################################

Create View PercentagePopulationVaccinated as
Select CD.continent, CD.location , CD.date ,CD.population , CV.new_vaccinations,Sum(cast(CV.new_vaccinations as bigint)) OVER (Partition by CD.location Order by CD.location, CD.Date) as 'Total Vacinations' 
From PortfolioProject_Covid..CovidDeaths CD 
join PortfolioProject_Covid..CovidVaccinations CV
	on CD.location= CV.location 
	and CD.date = CV.date
where CD.continent is not null

--###########

Select *
From  PercentagePopulationVaccinated