/*
SYNTAX_DEMO - SQL SERVER HR SUPPORT DEMONSTRATION

Purpose: Demonstrate selected SQL Server components through a connected HR database scenario.

Execution:
- On first execution, the database is created if missing.
- The complete demonstration must run against a clean Syntax_Demo environment.
- To rerun all blocks, set @confirm_reset to 1.
- Individual analytical blocks can be executed separately without rebuilding the database.

WARNING:
- Reset removes the demonstration tables and their data.
- Use only in a dedicated Syntax_Demo environment.

The business scenario and employee data are simulated.
The SQL implementation is intended for practical execution.
*/

USE [master];
GO

-- 1. Create the demonstration database if it does not exist.
IF DB_ID(N'Syntax_Demo') IS NULL
BEGIN
    CREATE DATABASE [Syntax_Demo];
END;
GO

USE [Syntax_Demo];
GO

-- 2. Optional environment reset.
  -- The reset is disabled by default.
  -- Set @confirm_reset = 1 only when you intentionally want to remove the existing demonstration objects and execute all eight blocks again.
  -- DROP TABLE removes both the table structure and its data. The order accounts for dependencies between objects.

DECLARE @confirm_reset BIT = 0;

IF @confirm_reset = 1
BEGIN
    -- Remove the employee triggers first.
    DROP TRIGGER IF EXISTS dbo.trg_employee_insert;
    DROP TRIGGER IF EXISTS dbo.trg_employee_delete;

    -- Remove dependent tables before departments.
    DROP TABLE IF EXISTS dbo.employee_log;
    DROP TABLE IF EXISTS dbo.employee_delete_log;
    DROP TABLE IF EXISTS dbo.employees;
    DROP TABLE IF EXISTS dbo.departments;

    PRINT 'Syntax_Demo demonstration objects removed.';
END;
GO

/*
BLOCK 1 - DATABASE STRUCTURE & CONSTRAINTS

Purpose: Create the core HR database structure for subsequent SQL demonstrations.

Elements:
CREATE TABLE  - creates database objects.
PRIMARY KEY   - uniquely identifies records.
UNIQUE        - prevents duplicate values.
FOREIGN KEY   - establishes relationships between tables.
DEFAULT       - defines default column values.
ALTER TABLE   - modifies an existing table.
*/

USE [Syntax_Demo];
GO

-- 1. Create the departments table.
CREATE TABLE dbo.departments (
    department_id INT PRIMARY KEY,
    department_name NVARCHAR(100) UNIQUE
);
GO

-- 2. Create the employees table and its relationship with departments.
CREATE TABLE dbo.employees (
    employee_id INT PRIMARY KEY,
    email NVARCHAR(200) UNIQUE,
    department_id INT,
    status NVARCHAR(20) DEFAULT 'active',
    created_at DATETIME2 DEFAULT GETDATE(),
    manager_id INT NULL,
    CONSTRAINT FK_emp_dept
        FOREIGN KEY (department_id)
        REFERENCES dbo.departments(department_id)
);
GO

-- Schema design notes:
  -- The manager_id column represents the employee reporting hierarchy but does not have a self-referencing FOREIGN KEY.
  -- This allows the demonstration to explain how recursive CTEs traverse reporting relationships and why additional hierarchy validation may be necessary.
  -- The status and created_at columns use DEFAULT values.
  -- DEFAULT supplies a value when the column is omitted from an INSERT statement, but does not prohibit explicit NULL.
  -- NOT NULL would be required to enforce mandatory values.
  -- These limitations are retained intentionally to keep the demonstration focused on the requested SQL components.

-- 3. Extend the existing employees table.
ALTER TABLE dbo.employees
ADD salary DECIMAL(10,2) DEFAULT 0;
GO

-- 4. Validate the resulting table structure.
  -- INFORMATION_SCHEMA.COLUMNS is a system view that provides metadata about database table columns, including their names, data types, and NULL constraints.
  -- Unlike SELECT queries against departments or employees, this query inspects the table structure rather than its data.
  -- This allows us to verify that the expected columns were created correctly, even when both tables are empty.
  -- Note: This query does not validate PRIMARY KEY, FOREIGN KEY, UNIQUE, or DEFAULT constraints.

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME IN ('departments', 'employees')
ORDER BY TABLE_NAME, ORDINAL_POSITION;
GO

/*
BLOCK 2 - HR DATASET INITIALIZATION

Purpose: Populate the HR database with related records that will be used in subsequent SQL demonstrations.

SQL elements demonstrated:
- INSERT INTO: adds new records to a table.
- VALUES: specifies the data to insert.
- SELECT: retrieves stored records.
- LEFT JOIN: combines employees with their departments.

The dataset includes different salary levels, default active employee statuses, and reporting relationships.

These records support subsequent demonstrations of CASE, IF / ELSE, WHILE, and recursive CTEs.

All employees initially receive the default 'active' status. Multiple status values are not required for the current demonstration.
*/

USE [Syntax_Demo];
GO

-- 1. Insert departments before employees to satisfy the FOREIGN KEY relationship.
INSERT INTO dbo.departments
    (department_id, department_name)
VALUES
    (1, 'Engineering'),
    (2, 'Quality Assurance'),
    (3, 'Technical Support'),
    (4, 'Human Resources');
GO

-- 2. Insert employee records.
  -- The department_id values reference existing departments.
  -- The manager_id values establish reporting relationships between employees.
  -- The status and created_at columns are omitted intentionally so SQL Server applies their DEFAULT values.
  -- Salary levels are selected to demonstrate different classification results in the upcoming CASE and IF blocks.

INSERT INTO dbo.employees
    (employee_id, email, department_id, manager_id, salary)
VALUES
    (101, 'alex.morgan@example.com', 1, NULL, 7500.00),
    (102, 'emma.wilson@example.com', 1, 101, 5200.00),
    (103, 'daniel.lee@example.com', 1, 102, 3500.00),
    (104, 'sophia.brown@example.com', 2, 101, 4800.00),
    (105, 'james.taylor@example.com', 2, 104, 2700.00),
    (106, 'olivia.martin@example.com', 3, 101, 5500.00),
    (107, 'noah.anderson@example.com', 3, 106, 3200.00),
    (108, 'mia.thomas@example.com', 3, 107, 2200.00),
    (109, 'liam.jackson@example.com', 4, 101, 4600.00),
    (110, 'ava.white@example.com', 4, 109, 2900.00);
GO

-- 3. Validate the inserted dataset.
  -- SELECT retrieves the actual records stored in employees.
  -- LEFT JOIN connects employees to their departments using department_id. Unlike INNER JOIN, LEFT JOIN preserves employee records even when no matching department exists.
  -- This query also allows us to verify that the DEFAULT values for status and created_at were applied.
  -- The manager_id column will be used later to reconstruct the employee reporting hierarchy through a recursive CTE.

SELECT
    e.employee_id,
    e.email,
    d.department_name,
    e.manager_id,
    e.salary,
    e.status,
    e.created_at
FROM dbo.employees AS e
LEFT JOIN dbo.departments AS d
    ON e.department_id = d.department_id
ORDER BY e.employee_id;
GO

/*
BLOCK 3 - EMPLOYEE SALARY CLASSIFICATION (CASE)

Purpose: Classify employees into salary-based categories using the existing HR dataset.

SQL elements demonstrated:
- SELECT: retrieves employee records.
- CASE: evaluates conditions and returns a corresponding value.
- WHEN / THEN: defines classification conditions and results.
- ELSE: provides a fallback value.
- END: completes the CASE expression.
- ORDER BY: sorts the resulting dataset.

CASE is an expression evaluated within a SQL statement. Unlike procedural IF, it does not control which SQL statements are executed.

The classification is calculated dynamically and does not modify the underlying employee records.
*/

USE [Syntax_Demo];
GO

-- 1. Classify employees based on their salary.

SELECT
    employee_id,
    email,
    salary,
    CASE
        WHEN salary >= 5000 THEN 'Senior'
        WHEN salary >= 3000 THEN 'Middle'
        ELSE 'Junior'
    END AS grade
FROM dbo.employees
ORDER BY salary DESC;
GO

-- 2. Implementation notes.
  -- The CASE expression is located directly inside SELECT. SQL Server evaluates the WHEN conditions in order and returns the result of the first matching condition.
  -- For example:
    -- salary = 7500 -> Senior
    -- salary = 3500 -> Middle
    -- salary = 2200 -> Junior
  -- The ELSE branch handles salaries below 3000, as well as NULL salary values if they occur.
  -- The calculated grade exists only in the query result. No UPDATE or other data modification is performed.
  -- Next:
    -- The following block demonstrates procedural IF / ELSE, where conditions determine which SQL statements execute.

/*
BLOCK 4 - PROCEDURAL LOGIC (IF / ELSE)

Purpose: Demonstrate how SQL Server uses conditional branching to control the execution of SQL statements.

SQL elements demonstrated:
- DECLARE: creates local variables.
- SELECT @variable: assigns values from a query.
- IF / ELSE: controls which code branch executes.
- BEGIN / END: groups statements into logical blocks.

Unlike CASE, which evaluates conditions within a query, IF / ELSE controls the execution flow of a SQL batch.

This example retrieves an employee's salary from the existing HR dataset and determines the corresponding salary classification.
*/

USE [Syntax_Demo];
GO

-- Declare variables for the selected employee.
DECLARE @employee_id INT = 103;
DECLARE @salary DECIMAL(10,2);
DECLARE @grade NVARCHAR(20);

-- Retrieve the employee's salary.
SELECT @salary = salary
FROM dbo.employees
WHERE employee_id = @employee_id;

-- Evaluate the salary using IF / ELSE.
  -- The conditions are checked sequentially. BEGIN / END groups the statements belonging to each conditional branch.
  -- Only the matching branch assigns a value to @grade.

IF @salary >= 5000
BEGIN
    SET @grade = 'Senior';
END
ELSE IF @salary >= 3000
BEGIN
    SET @grade = 'Middle';
END
ELSE
BEGIN
    SET @grade = 'Junior';
END;

-- Display the result.
SELECT
    @employee_id AS employee_id,
    @salary AS salary,
    @grade AS grade;
GO

-- Implementation notes:
  -- DECLARE introduces three local variables.
  -- SELECT @salary = salary retrieves a value from the employees table and assigns it to @salary.
  -- IF / ELSE determines which SET statement executes.
  -- The final SELECT returns the calculated classification.
  -- Expected result for employee 103:
    -- salary = 3500.00
    -- grade = Middle
-- Disclaimer - Missing Employee Handling
  -- This demonstration assumes that the specified employee_id exists in the employees table.
  -- If no matching record is found, @salary remains NULL. Since neither IF condition evaluates to TRUE, the ELSE branch assigns 'Junior' to @grade.
  -- This is a limitation of the simplified demonstration, not the expected behavior of production-ready logic.
  -- In a production scenario, missing employees and NULL salary values should be handled explicitly before performing salary classification.
-- Next:
  -- The WHILE block will demonstrate repeated execution of procedural SQL statements across multiple employees.

/*
BLOCK 5 - WHILE LOOP: ITERATIVE EMPLOYEE PROCESSING

Purpose: Demonstrate how SQL Server repeatedly executes procedural statements to process employee records individually.

SQL elements demonstrated:
- DECLARE: creates local variables.
- WHILE: repeats execution while a condition is TRUE.
- BEGIN / END: defines the loop body.
- IF / ELSE: applies conditional logic during each iteration.
- SET: updates variable values.
- CREATE TABLE #temp: creates a local temporary table.
- INSERT INTO: stores the results of each iteration.

Unlike the set-based CASE demonstrated in Block 3, WHILE processes employee records one iteration at a time.

The original employees table remains unchanged.
*/

USE [Syntax_Demo];
GO

-- Create a temporary table to store processing results.
CREATE TABLE #employee_grades (
    employee_id INT,
    salary DECIMAL(10,2),
    grade NVARCHAR(20)
);

-- Declare variables used during iteration.
DECLARE @i INT = 1;
DECLARE @total INT;
DECLARE @employee_id INT;
DECLARE @salary DECIMAL(10,2);
DECLARE @grade NVARCHAR(20);

-- Prepare an ordered list of employees.
SELECT
    ROW_NUMBER() OVER (ORDER BY employee_id) AS row_num,
    employee_id,
    salary
INTO #employee_queue
FROM dbo.employees;

-- Determine the number of records to process.
SELECT @total = COUNT(*)
FROM #employee_queue;

-- Execute the WHILE loop.
  -- WHILE @i <= @total controls how many iterations execute.
  -- During each iteration:
    -- SELECT retrieves the current employee.
    -- IF / ELSE determines the salary classification.
    -- INSERT INTO stores the calculated result.
    -- SET increments the loop counter.

-- The SET @i = @i + 1 statement is essential. Without it, the loop condition would remain TRUE, potentially causing an infinite loop.

WHILE @i <= @total
BEGIN
    SELECT
        @employee_id = employee_id,
        @salary = salary
    FROM #employee_queue
    WHERE row_num = @i;

    IF @salary >= 5000
    BEGIN
        SET @grade = 'Senior';
    END
    ELSE IF @salary >= 3000
    BEGIN
        SET @grade = 'Middle';
    END
    ELSE
    BEGIN
        SET @grade = 'Junior';
    END;

    INSERT INTO #employee_grades
        (employee_id, salary, grade)
    VALUES
        (@employee_id, @salary, @grade);

    SET @i = @i + 1;
END;

-- Validate the processing results.
  -- The temporary table contains one record per employee,
  -- including the salary classification calculated during the corresponding WHILE iteration.
  -- The number of processed records should match the number of employees in the original table.

SELECT
    employee_id,
    salary,
    grade
FROM #employee_grades
ORDER BY employee_id;

SELECT
    (SELECT COUNT(*) FROM dbo.employees) AS source_records,
    (SELECT COUNT(*) FROM #employee_grades) AS processed_records;

-- Clean up temporary objects.
  -- Local temporary tables exist within the current session.
  -- DROP TABLE explicitly removes them after the demonstration.

DROP TABLE #employee_grades;
DROP TABLE #employee_queue;
GO

-- Implementation notes:
  -- The WHILE construct is demonstrated in the loop that processes the prepared employee queue.
  -- ROW_NUMBER() creates sequential identifiers used to retrieve employees during individual iterations.
  -- The IF / ELSE branches reuse the classification logic from Block 4.
  -- INSERT INTO stores the result of each iteration in the #employee_grades temporary table.
  -- The loop counter @i is incremented after every iteration, allowing the WHILE condition to eventually become FALSE.
-- Disclaimer:
  -- This implementation demonstrates procedural iteration, not an optimized approach to bulk data processing.
  -- For this particular task, the set-based CASE expression from Block 3 is generally simpler and more efficient.
  -- The temporary tables and their contents are removed at the end of the demonstration.
-- Next:
  -- The following block introduces SQL Server triggers, demonstrating automatic execution of database logic in response to INSERT and DELETE operations.

/*
BLOCK 6 - TRIGGERS: EMPLOYEE ACTIVITY AUDITING

Purpose: Demonstrate how SQL Server automatically executes database logic in response to INSERT and DELETE operations.

SQL elements demonstrated:
- CREATE TABLE: creates audit storage tables.
- CREATE TRIGGER: defines event-driven database logic.
- AFTER INSERT / AFTER DELETE: specifies trigger events.
- inserted / deleted: provides access to affected records.
- SUSER_SNAME(): identifies the SQL execution login.
- APP_NAME(): identifies the client application.
- HOST_NAME(): identifies the client-reported host.
- SYSDATETIME(): records the event timestamp.

The triggers capture employee activity without requiring the application to insert audit records explicitly.
*/

USE [Syntax_Demo];
GO

-- 1. Create audit tables to store employee activity.

CREATE TABLE dbo.employee_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    employee_id INT,
    salary DECIMAL(10,2),
    executed_by NVARCHAR(128),
    application_name NVARCHAR(128),
    host_name NVARCHAR(128),
    event_time DATETIME2
);
GO

CREATE TABLE dbo.employee_delete_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    employee_id INT,
    salary DECIMAL(10,2),
    executed_by NVARCHAR(128),
    application_name NVARCHAR(128),
    host_name NVARCHAR(128),
    event_time DATETIME2
);
GO

-- 2. Create the AFTER INSERT trigger.
  -- CREATE TRIGGER defines the logic that SQL Server automatically executes after an INSERT operation.
  -- The inserted pseudo-table contains the newly inserted records, allowing the trigger to capture their values.
  -- INSERT INTO ... SELECT processes the entire inserted dataset, including multi-row INSERT operations.
  -- The execution context functions collect additional information about the SQL session.

CREATE TRIGGER dbo.trg_employee_insert
ON dbo.employees
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.employee_log (
        employee_id,
        salary,
        executed_by,
        application_name,
        host_name,
        event_time
    )
    SELECT
        i.employee_id,
        i.salary,
        SUSER_SNAME(),
        APP_NAME(),
        HOST_NAME(),
        SYSDATETIME()
    FROM inserted AS i;
END;
GO

-- 3. Create the AFTER DELETE trigger.
  -- The deleted pseudo-table contains the records affected by a DELETE operation before they are removed.
  -- This allows the trigger to preserve selected information about deleted employees in a separate audit table.
  -- Both triggers use set-based INSERT INTO ... SELECT logic rather than processing affected rows individually.

CREATE TRIGGER dbo.trg_employee_delete
ON dbo.employees
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.employee_delete_log (
        employee_id,
        salary,
        executed_by,
        application_name,
        host_name,
        event_time
    )
    SELECT
        d.employee_id,
        d.salary,
        SUSER_SNAME(),
        APP_NAME(),
        HOST_NAME(),
        SYSDATETIME()
    FROM deleted AS d;
END;
GO

-- 4. Demonstrate trigger execution.
  -- A temporary test employee is inserted and then deleted.
  -- The INSERT automatically activates trg_employee_insert.
  -- The DELETE automatically activates trg_employee_delete.
  -- No direct INSERT statements are executed against the audit tables during this demonstration.
  -- Employee ID 999 is reserved for this test scenario.

INSERT INTO dbo.employees (
    employee_id,
    email,
    department_id,
    manager_id,
    salary
)
VALUES (
    999,
    'trigger.demo@example.com',
    3,
    106,
    4100.00
);
GO

-- Verify that the INSERT event was captured.
SELECT *
FROM dbo.employee_log
WHERE employee_id = 999;
GO

-- Delete the test employee.
DELETE FROM dbo.employees
WHERE employee_id = 999;
GO

-- Verify that the DELETE event was captured.
SELECT *
FROM dbo.employee_delete_log
WHERE employee_id = 999;
GO

-- 5. Validate the final database state.
  -- The original HR dataset should still contain 10 employees.
  -- Both audit tables should contain an entry for the test employee, demonstrating that INSERT and DELETE events were recorded automatically.

SELECT COUNT(*) AS remaining_employees
FROM dbo.employees;

SELECT
    'INSERT' AS event_type,
    employee_id,
    salary,
    executed_by,
    application_name,
    host_name,
    event_time
FROM dbo.employee_log
WHERE employee_id = 999

UNION ALL

SELECT
    'DELETE' AS event_type,
    employee_id,
    salary,
    executed_by,
    application_name,
    host_name,
    event_time
FROM dbo.employee_delete_log
WHERE employee_id = 999;
GO

-- Implementation notes:
  -- CREATE TRIGGER defines the automatic database behavior.
  -- AFTER INSERT and AFTER DELETE specify which operations activate the corresponding triggers.
  -- The inserted and deleted pseudo-tables provide access to the affected rows.
  -- SUSER_SNAME(), APP_NAME(), and HOST_NAME() collect execution-context information, while SYSDATETIME() records the event timestamp.
  -- The triggers operate on sets of affected records, supporting both single-row and multi-row operations.
-- Disclaimer:
  -- This demonstration implements simplified activity auditing.
  -- The execution-context functions identify the SQL login and client-reported application/host information, not necessarily the actual end user of a business application.
  -- Audit records are written within the same transaction as the triggering operation. If that transaction rolls back, the corresponding audit records also roll back.
  -- The audit tables are intentionally not linked to employees through FOREIGN KEY constraints, allowing audit records to remain after an employee is deleted.
  -- This scenario does not implement UPDATE auditing, audit retention policies, or tamper-resistant logging.
  -- The demonstration assumes employee_id 999 is unused.
  -- The setup statements are intended for initial execution; rerunning them requires appropriate cleanup or reset.
-- Execution note:
  -- The trigger and audit table creation statements are intended for the initial setup of the demonstration.
  -- To rebuild these objects, use the optional reset at the beginning of this SQL file.
  -- Repeated execution of the INSERT / DELETE test scenario without resetting the audit tables will create additional audit records for employee_id 999.
-- Next:
  -- The following block introduces Common Table Expressions (CTE) for structured queries and employee hierarchy analysis.

/*
BLOCK 7 - COMMON TABLE EXPRESSIONS (CTE)

Purpose: Demonstrate how SQL Server uses Common Table Expressions to organize analytical queries and process hierarchical data.

SQL elements demonstrated:
- WITH ... AS: defines a Common Table Expression.
- JOIN: combines employees with their departments.
- GROUP BY: aggregates records by department.
- COUNT / AVG: calculates departmental statistics.
- Recursive CTE: traverses employee reporting relationships.
- UNION ALL: combines anchor and recursive query results.
- MAXRECURSION: limits recursive execution depth.

CTEs provide named result sets that exist within the scope of the immediately following SQL statement.

They do not create permanent tables or modify source data.
*/

USE [Syntax_Demo];
GO

-- 1. Standard CTE - Department Salary Analysis
  -- The WITH clause defines DepartmentSalaryStats, a temporary named result set that aggregates employee information by department.
  -- JOIN connects employees to departments.
  -- GROUP BY organizes records into departmental groups.
  -- COUNT and AVG calculate the employee count and average salary for each department.
  -- The final SELECT retrieves the aggregated results from the CTE and sorts them by average salary.

;WITH DepartmentSalaryStats AS (
    SELECT
        d.department_id,
        d.department_name,
        COUNT(e.employee_id) AS employee_count,
        AVG(e.salary) AS average_salary
    FROM dbo.departments AS d
    LEFT JOIN dbo.employees AS e
        ON d.department_id = e.department_id
    GROUP BY
        d.department_id,
        d.department_name
)
SELECT
    department_name,
    employee_count,
    average_salary
FROM DepartmentSalaryStats
ORDER BY average_salary DESC;
GO

-- 2. Recursive CTE - Employee Reporting Hierarchy
  -- The recursive CTE reconstructs reporting relationships using the manager_id column from the employees table.
  -- The anchor query identifies top-level employees whose manager_id is NULL.
  -- The recursive query joins employees to the previously identified hierarchy members, adding their subordinates at each recursion level.
  -- UNION ALL combines both parts into a single result set.
  -- The hierarchy_level column indicates the employee's position in the reporting structure, starting at 0.
  -- Employee email addresses are used as identifiers because the existing HR schema does not contain a full_name column.

;WITH EmployeeHierarchy AS (

    -- Anchor member: top-level employees.
    SELECT
        employee_id,
        email,
        manager_id,
        department_id,
        0 AS hierarchy_level
    FROM dbo.employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive member: employees reporting to
    -- previously identified hierarchy members.
    SELECT
        e.employee_id,
        e.email,
        e.manager_id,
        e.department_id,
        h.hierarchy_level + 1
    FROM dbo.employees AS e
    INNER JOIN EmployeeHierarchy AS h
        ON e.manager_id = h.employee_id
)
SELECT
    h.employee_id,
    h.email,
    h.manager_id,
    d.department_name,
    h.hierarchy_level
FROM EmployeeHierarchy AS h
LEFT JOIN dbo.departments AS d
    ON h.department_id = d.department_id
ORDER BY
    h.hierarchy_level,
    h.manager_id,
    h.employee_id
OPTION (MAXRECURSION 100);
GO

-- 3. Validate the hierarchy coverage.
  -- This query compares the total number of employees with the number of records returned by the recursive CTE.
  -- Matching counts are expected for the current dataset, where all employees belong to a single valid hierarchy rooted at employee_id 101.
  -- Note: Matching counts alone do not guarantee that every employee appears exactly once. Invalid relationships or cycles may require additional validation.

;WITH EmployeeHierarchy AS (
    SELECT
        employee_id,
        manager_id
    FROM dbo.employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT
        e.employee_id,
        e.manager_id
    FROM dbo.employees AS e
    INNER JOIN EmployeeHierarchy AS h
        ON e.manager_id = h.employee_id
)
SELECT
    (SELECT COUNT(*) FROM dbo.employees)
        AS total_employees,
    (SELECT COUNT(*) FROM EmployeeHierarchy)
        AS hierarchy_records
OPTION (MAXRECURSION 100);
GO

-- Implementation notes:
  -- Standard CTE:
    -- The WITH DepartmentSalaryStats AS (...) expression defines the named result set used for aggregation.
  -- Recursive CTE:
    -- The WITH EmployeeHierarchy AS (...) expression contains two components:
      -- Anchor member: selects employees without a manager.
      -- Recursive member: retrieves their direct and indirect subordinates.
    -- UNION ALL combines the anchor and recursive members.
    -- The hierarchy_level value increases during recursion, allowing us to identify each employee's reporting depth.
    -- OPTION (MAXRECURSION 100) limits recursive execution to 100 levels to prevent uncontrolled recursion.
-- Disclaimer:
  -- The current HR schema does not enforce manager_id as a FOREIGN KEY referencing employees.employee_id.
  -- Therefore, invalid manager references or circular relationships are not automatically prevented.
  -- MAXRECURSION limits recursion depth but does not validate the logical correctness of the hierarchy.
  -- For this demonstration, the dataset contains a known reporting structure with one root employee.
-- Next:
  -- The following block demonstrates SQL Server date/time functions and date-based filtering using HR records.

/*
BLOCK 8 - DATE & TIME OPERATIONS

Purpose: Demonstrate how SQL Server retrieves, calculates, and filters date/time values using the existing HR dataset.

SQL elements demonstrated:
- GETDATE(): returns the current SQL Server date and time.
- SYSDATETIME(): returns the current date and time with higher fractional-second precision.
- DATEADD(): adds or subtracts a specified time interval.
- DATEDIFF(): counts datepart boundaries between two dates.
- WHERE: filters records by a date/time condition.
- DATETIME2: stores date/time values with configurable precision.

The examples use employee creation timestamps and audit records generated in previous demonstration blocks.

No source data is modified.
*/

USE [Syntax_Demo];
GO

-- 1. Retrieve the current SQL Server date and time.
  -- GETDATE() returns the current database server date/time as DATETIME.
  -- SYSDATETIME() returns the current server date/time as DATETIME2(7), providing higher fractional-second precision.
  -- Both functions use the SQL Server host's system clock, which may differ from the client's local time zone.

SELECT
    GETDATE() AS current_datetime,
    SYSDATETIME() AS current_datetime_precise;
GO

-- 2. Demonstrate date arithmetic.
  -- DATEADD modifies a date/time value by adding or subtracting a specified interval.
  -- DATEDIFF calculates the number of datepart boundaries crossed between two date/time values.
  -- The example calculates:
    -- The date/time seven days ago.
    -- The date/time seven days from now.
    -- The number of days since each employee was created.
  -- DATEDIFF(DAY, ...) does not calculate exact elapsed 24-hour periods; it counts calendar-day boundaries.

SELECT
    GETDATE() AS current_datetime,
    DATEADD(DAY, -7, GETDATE()) AS seven_days_ago,
    DATEADD(DAY, 7, GETDATE()) AS seven_days_from_now;
GO

SELECT
    employee_id,
    email,
    created_at,
    DATEDIFF(DAY, created_at, GETDATE()) AS days_since_creation
FROM dbo.employees
ORDER BY created_at DESC, employee_id;
GO

-- 3. Filter employees created within the last seven days.
  -- WHERE restricts the result set to records whose created_at timestamp falls within the specified period.
  -- DATEADD(DAY, -7, GETDATE()) calculates the lower boundary of the rolling seven-day interval.
  -- GETDATE() provides the upper boundary.
  -- This is a rolling 7-day window (168 hours), rather than a selection of seven complete calendar days.

SELECT
    employee_id,
    email,
    created_at,
    status
FROM dbo.employees
WHERE created_at >= DATEADD(DAY, -7, GETDATE())
  AND created_at <= GETDATE()
ORDER BY created_at DESC, employee_id;
GO

-- 4. Analyze audit event timestamps.
  -- The employee_log and employee_delete_log tables were created in Block 6 to record INSERT and DELETE events.
  -- UNION ALL combines both audit datasets without removing duplicate records.
  -- DATEDIFF calculates the elapsed time in seconds between each recorded event and the current server time.
  -- The event_type column identifies the source operation.

SELECT
    'INSERT' AS event_type,
    employee_id,
    event_time,
    DATEDIFF(SECOND, event_time, SYSDATETIME())
        AS seconds_since_event
FROM dbo.employee_log

UNION ALL

SELECT
    'DELETE' AS event_type,
    employee_id,
    event_time,
    DATEDIFF(SECOND, event_time, SYSDATETIME())
        AS seconds_since_event
FROM dbo.employee_delete_log

ORDER BY event_time DESC;
GO

-- 5. Filter audit records within a specific time range.
  -- The following example retrieves audit events recorded during the last 24 hours.
  -- The time boundaries are calculated dynamically, so the query can be executed again without modifying hardcoded date values.
  -- A half-open interval (>= start, < end) avoids overlap between adjacent reporting periods.

DECLARE @period_end DATETIME2 = SYSDATETIME();
DECLARE @period_start DATETIME2 =
    DATEADD(HOUR, -24, @period_end);

SELECT
    'INSERT' AS event_type,
    employee_id,
    event_time
FROM dbo.employee_log
WHERE event_time >= @period_start
  AND event_time < @period_end

UNION ALL

SELECT
    'DELETE' AS event_type,
    employee_id,
    event_time
FROM dbo.employee_delete_log
WHERE event_time >= @period_start
  AND event_time < @period_end

ORDER BY event_time DESC;
GO

-- Implementation notes:
  -- Section 1:
    -- GETDATE() and SYSDATETIME() retrieve the current server date/time with different data types and precision.
  -- Section 2:
    -- DATEADD calculates relative date/time values.
    -- DATEDIFF counts boundaries between two timestamps.
  -- Section 3:
    -- WHERE filters employee records using a rolling seven-day time window.
  -- Section 4:
    -- UNION ALL combines INSERT and DELETE audit records.
    -- DATEDIFF calculates the age of each audit event.
  -- Section 5:
    -- DECLARE stores the time boundaries in local variables.
    -- The half-open interval filters events within the last 24 hours.
-- Disclaimer:
  -- The demonstration uses the SQL Server host's local date/time values without explicit time zone conversion.
  -- For systems operating across multiple time zones, UTC timestamps and a consistent time zone strategy are generally preferable.
  -- The date filters are dynamic. Their results depend on when the demonstration is executed.
  -- DATEDIFF counts datepart boundaries, not necessarily complete elapsed units.
-- Next:
  -- The functional SQL demonstration is complete.
  -- The final stage is to validate the overall database state and prepare the reproducible technical case.

/*
FINAL VALIDATION - DATABASE STATE

Purpose: Verify that the demonstration database retains its expected structure and original employee dataset.

This query checks:
- Number of departments.
- Number of employees.
- Number of audit records.
- Presence of both employee triggers.

Expected results after a clean execution:
- departments = 4
- employees = 10
- insert_audit_records = 1
- delete_audit_records = 1
- employee_triggers = 2

Audit counts may be higher if the trigger demonstration was executed multiple times without resetting the tables.
*/

USE [Syntax_Demo];
GO

SELECT
    (SELECT COUNT(*) FROM dbo.departments)
        AS departments,
    (SELECT COUNT(*) FROM dbo.employees)
        AS employees,
    (SELECT COUNT(*) FROM dbo.employee_log)
        AS insert_audit_records,
    (SELECT COUNT(*) FROM dbo.employee_delete_log)
        AS delete_audit_records,
    (
        SELECT COUNT(*)
        FROM sys.triggers
        WHERE parent_id = OBJECT_ID(N'dbo.employees')
          AND name IN (
              N'trg_employee_insert',
              N'trg_employee_delete'
          )
    ) AS employee_triggers;
GO