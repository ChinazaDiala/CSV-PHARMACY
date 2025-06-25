CREATE TABLE departments(
department_id INT PRIMARY KEY,
department_name VARCHAR(100) NOT NULL
);
SELECT * FROM departments

CREATE TABLE locations (
location_id INT PRIMARY KEY,
location_name VARCHAR(100) NOT NULL
);
SELECT * FROM locations

CREATE TABLE patients (
patient_id INT PRIMARY KEY,
check_in_time TIMESTAMPTZ NOT NULL,
check_out_time TIMESTAMPTZ NOT NULL,
department_id INT NOT NULL REFERENCES departments(department_id),
location_id INT NOT NULL REFERENCES locations(location_id),
CHECK (check_out_time >= check_in_time)
);
SELECT * FROM patients;

--calculate wait time
WITH wait_times AS(
	SELECT
	patient_id,
	department_id,
	location_id,
	ROUND(EXTRACT(EPOCH FROM(check_out_time-check_in_time))/60,2) AS wait_minutes
	FROM patients
	WHERE check_out_time IS NOT NULL AND check_in_time IS NOT NULL
)
SELECT* FROM wait_times;

--calculate average wait time by location

WITH wait_times AS(
	SELECT
	patient_id,
	department_id,
	location_id,
	ROUND(EXTRACT(EPOCH FROM(check_out_time-check_in_time))/60,2) AS wait_minutes
	FROM patients
	WHERE check_out_time IS NOT NULL AND check_in_time IS NOT NULL
	),
	location_avg_waits AS(
		SELECT
		l.location_name,
		ROUND(AVG(w.wait_minutes),2) AS avg_wait_time_minutes
		FROM wait_times w
		JOIN locations l ON w.location_id = l.location_id
		GROUP BY l.location_name)
		SELECT*
		FROM location_avg_waits
		ORDER BY avg_wait_time_minutes DESC;

--identifying problem location with wait time >120 mins
WITH wait_times AS(
	SELECT
	patient_id,
	department_id,
	location_id,
	ROUND(EXTRACT(EPOCH FROM(check_out_time-check_in_time))/60,2) AS wait_minutes
	FROM patients
	WHERE check_out_time IS NOT NULL AND check_in_time IS NOT NULL
	)
	SELECT
		l.location_name,
		ROUND(AVG(w.wait_minutes),2) AS avg_wait_time_minutes
		FROM wait_times w
		JOIN locations l ON w.location_id = l.location_id
		GROUP BY l.location_name
		HAVING AVG(w.wait_minutes)>120
		ORDER BY avg_wait_time_minutes DESC;

--department level bottleneck analysis
		WITH wait_times AS(
	SELECT
	patient_id,
	department_id,
	location_id,
	ROUND(EXTRACT(EPOCH FROM(check_out_time-check_in_time))/60,2) AS wait_minutes
	FROM patients
	WHERE check_out_time IS NOT NULL AND check_in_time IS NOT NULL
	)
	SELECT
		d.department_name,
		ROUND(AVG(w.wait_minutes),2) AS avg_wait_time_minutes
		FROM wait_times w
		JOIN departments d ON w.department_id = d.department_id
		GROUP BY d.department_name
		ORDER BY avg_wait_time_minutes DESC;

--% of location with high wait times
WITH wait_times AS(
	SELECT
	patient_id,
	department_id,
	location_id,
	ROUND(EXTRACT(EPOCH FROM(check_out_time-check_in_time))/60,2) AS wait_minutes
	FROM patients
	WHERE check_out_time IS NOT NULL AND check_in_time IS NOT NULL
	),

	location_avg AS(
SELECT location_id, AVG(wait_minutes) AS avg_wait_time
FROM wait_times
GROUP BY location_id
	)
	SELECT
	COUNT(*) FILTER(WHERE avg_wait_time > 120) AS high_wait_count,
	COUNT(*) AS total_locations,
	ROUND(COUNT(*) FILTER (WHERE avg_wait_time > 120) * 100.0 / COUNT(*),2) AS percent_high_wait
	FROM location_avg;

	--monthly trend of % of high wait locations
	WITH wait_times AS(
	SELECT
	location_id,
	DATE_TRUNC('month', check_in_time) AS month,
	EXTRACT(EPOCH FROM(check_out_time-check_in_time))/60 AS wait_minutes
	FROM patients
	WHERE check_out_time IS NOT NULL AND check_in_time IS NOT NULL
	),
	location_monthly_avg AS(
	SELECT
	location_id,
	month,
	AVG(wait_minutes) AS avg_wait_time
	FROM wait_times
	GROUP BY location_id, month)
	SELECT
	month,
	COUNT(*) FILTER(WHERE avg_wait_time > 120) AS high_wait_count,
	COUNT(*) AS total_locations,
	ROUND(COUNT(*) FILTER (WHERE avg_wait_time > 120) * 100.0 / COUNT(*),2) AS percent_high_wait
	FROM location_monthly_avg
	GROUP BY month
	ORDER BY month;
		
		
	


