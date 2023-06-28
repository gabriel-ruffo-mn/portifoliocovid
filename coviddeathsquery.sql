-- Base Completa

SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL

/* 
	Caso queira saber de um país específico,
	basta apagar os dois traços antes do comando AND
	e colocar o nome do país desejado dentro das áspas simples.
	Lembrando que a base de dados está em inglês.
*/

-- Selecionar dados relevantes para a análise

SELECT 
	location, 
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM CovidDeaths cd
WHERE continent IS NOT NULL

-- Analisar Total de Casos x Total de Mortes
-- Probabilidade de morte caso contraia COVID

SELECT 
	location, 
	date,
	total_cases,
	total_deaths,
	(total_deaths * 100.0 / total_cases) AS 'death_percent'
FROM CovidDeaths cd
WHERE continent IS NOT NULL
-- AND location = 'Brazil'

-- Analisar Total de Casos x População
-- Porcentagens da população de cada país que contraiu COVID

SELECT 
	location, 
	date,
	population,
	total_cases,
	(total_cases * 100.0 / population) AS 'contamination_percent'
FROM CovidDeaths cd
WHERE continent IS NOT NULL
-- AND location = 'Brazil'

/*  
	Países com a maior porcentagem de contaminação por população
	em ordem descrescente
*/

SELECT 
	location,
	population,
	MAX(total_cases) AS 'contamination_count',
	MAX((total_cases * 100.0 / population)) AS 'contamination_percent'
FROM CovidDeaths cd
WHERE continent IS NOT NULL
-- AND location = 'Brazil'
GROUP BY location, population
ORDER BY contamination_percent DESC

/*
	Países com a maior taxa de óbito por população
	em ordem descrecente
*/

SELECT 
	location,
	MAX(total_deaths) AS 'total_death_count'
FROM CovidDeaths cd
WHERE continent IS NOT NULL
-- AND location = 'Brazil'
GROUP BY location
ORDER BY total_death_count DESC

-- Agora por continente

SELECT 
	location,
	MAX(total_deaths) AS 'total_death_count'
FROM CovidDeaths cd
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC

-- Números Globais

SELECT
	date,
	SUM(new_cases) as total_cases,
	SUM(new_deaths) as total_deaths,
	CASE 
		WHEN SUM(new_cases) = 0 THEN NULL 
		ELSE (SUM(new_deaths) * 100.0 / NULLIF(SUM(new_cases), 0)) 
	END as mortality_rate
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date


-- CTE
-- Total de Vacinações x População

WITH popxvac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT
        cd.continent,
        cd.location,
        cd.date,
        cd.population,
        cv.new_vaccinations,
        SUM(CAST(cv.new_vaccinations AS bigint)) OVER
        (
            PARTITION BY cd.location
            ORDER BY cd.date
            ROWS UNBOUNDED PRECEDING
        ) AS RollingPeopleVaccinated
    FROM
        CovidDeaths AS cd
    JOIN
        CovidVaccinations AS cv ON cd.location = cv.location
            AND cd.date = cv.date
    WHERE
        cd.continent IS NOT NULL
)
SELECT
    *,
    (RollingPeopleVaccinated / CAST(population AS float)) * 100 AS PercentageVaccinated
FROM
    popxvac;


-- temp table 
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
SELECT
        cd.continent,
        cd.location,
        cd.date,
        cd.population,
        cv.new_vaccinations,
        SUM(CAST(cv.new_vaccinations AS bigint)) OVER
        (
            PARTITION BY cd.location
            ORDER BY cd.date
            ROWS UNBOUNDED PRECEDING
        ) AS RollingPeopleVaccinated
    FROM
        CovidDeaths AS cd
    JOIN
        CovidVaccinations AS cv ON cd.location = cv.location
            AND cd.date = cv.date
--    WHERE cd.continent IS NOT NULL

SELECT
    *,
    (RollingPeopleVaccinated / CAST(population AS float)) * 100 AS PercentageVaccinated
FROM
    #PercentPopulationVaccinated


-- armazenando os dados em uma view para visualização 
CREATE VIEW ProbabilidadeMorte AS
SELECT 
	location, 
	date,
	total_cases,
	total_deaths,
	(total_deaths * 100.0 / total_cases) AS 'death_percent'
FROM CovidDeaths cd
WHERE continent IS NOT NULL

CREATE VIEW CasoxPopulacao AS
SELECT 
	location, 
	date,
	population,
	total_cases,
	(total_cases * 100.0 / population) AS 'contamination_percent'
FROM CovidDeaths cd
WHERE continent IS NOT NULL

CREATE VIEW PorcentagemPopulacao AS
SELECT 
	location, 
	date,
	population,
	total_cases,
	(total_cases * 100.0 / population) AS 'contamination_percent'
FROM CovidDeaths cd
WHERE continent IS NOT NULL

CREATE VIEW PaisesxMortes AS
SELECT 
	location,
	MAX(total_deaths) AS 'total_death_count'
FROM CovidDeaths cd
WHERE continent IS NOT NULL
-- AND location = 'Brazil'
GROUP BY location
 
CREATE VIEW ContinentesxMortes AS
SELECT 
	location,
	MAX(total_deaths) AS 'total_death_count'
FROM CovidDeaths cd
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC

CREATE VIEW NumerosGlobais AS
SELECT
	date,
	SUM(new_cases) as total_cases,
	SUM(new_deaths) as total_deaths,
	CASE 
		WHEN SUM(new_cases) = 0 THEN NULL 
		ELSE (SUM(new_deaths) * 100.0 / NULLIF(SUM(new_cases), 0)) 
	END as mortality_rate
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date