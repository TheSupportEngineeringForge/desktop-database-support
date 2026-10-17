# SQL Server - Interactive HR Database Demonstration

## Business Request

A software developer who primarily worked with SQL Server through graphical user interfaces requested a practical technical demonstration to better understand how selected SQL Server components work behind the UI.

The customer wanted to explore SQL operations directly, understand their behavior, and gain enough practical knowledge to reproduce the demonstrated scenarios independently.

Rather than presenting isolated SQL examples, the request was to build a **single, interconnected demonstration environment** where each component could be explored within a consistent business context.

The requested scope included database structure and constraints, data manipulation, conditional logic, iterative processing, triggers, Common Table Expressions (CTEs), hierarchical queries, and date/time operations.

## Implemented Solution

To address this request, a dedicated SQL Server database named `Syntax_Demo` was developed around a simulated Human Resources (HR) environment.

The database includes departments, employees, reporting relationships, salary information, and employee activity audit records.

Eight interconnected SQL demonstration blocks were implemented to illustrate how different SQL Server components operate against the same dataset.

Each block contains explanations of its purpose, the SQL components involved, their practical application, and the expected behavior.

The implementation also includes database initialization, a controlled environment reset, and validation queries to support independent reproduction.

## Delivered Outcome

The result is an executable, documented SQL Server demonstration that allows the customer to:

- Explore SQL Server functionality beyond graphical interfaces.
- Understand how individual SQL components behave in practical scenarios.
- Follow the relationships between database structure, data operations, and procedural logic.
- Execute and validate each demonstration independently.
- Rebuild the complete demonstration environment when required.

**The business scenario is simulated. The SQL implementation is real and has been executed and validated in SQL Server.**

---

## Demonstrated SQL Server Components

The demonstration consists of eight interconnected blocks, all operating within the same HR database.

| Block | Component | Demonstrated functionality |
|---|---|---|
| 1 | Database Structure & Constraints | Table creation, primary and foreign keys, unique constraints, default values, and schema inspection |
| 2 | Data Preparation & Relationships | Synthetic HR data, employee-department relationships, and JOIN operations |
| 3 | CASE Expressions | Salary-based employee classification |
| 4 | IF / ELSE | Conditional execution based on an employee's salary |
| 5 | WHILE Loops | Iterative employee processing and result validation |
| 6 | DML Triggers | AFTER INSERT and AFTER DELETE triggers with audit logging |
| 7 | Common Table Expressions | Department-level aggregation and recursive employee hierarchy traversal |
| 8 | Date & Time Operations | Current timestamps, date calculations, rolling time windows, and audit event analysis |

The blocks are arranged sequentially, allowing the same dataset and database relationships to support progressively more complex SQL operations.

## Environment & Prerequisites

**Database engine:** Microsoft SQL Server

**SQL client:** dbForge Studio for SQL Server (used during validation). SQL Server Management Studio (SSMS) or another compatible SQL Server client can also be used.

**Demonstration database:** `Syntax_Demo`

**Source file:** [`Syntax_Demo_Polished.sql`](./Syntax_Demo_Polished.sql)

Requirements:

- Access to a SQL Server instance.
- Permissions to create the demonstration database and its objects.
- A SQL client capable of executing T-SQL scripts containing `GO` batch separators.
- A dedicated demonstration environment. The script must not be executed against production databases.

The demonstration uses synthetic HR records and does not require external datasets or application services.

## Execution & Reproduction

### 1. Prepare the environment

Connect to the target SQL Server instance using a compatible SQL client.

Open `Syntax_Demo_Polished.sql` from this repository.

The script checks whether the `Syntax_Demo` database exists and creates it if necessary.

### 2. Review the reset configuration

Near the beginning of the script, locate:

```sql
DECLARE @confirm_reset BIT = 0;
```

The reset is disabled by default.

For the first complete execution against a clean demonstration environment, keep the value set to `0`.

If the demonstration objects already exist and the complete script must be executed again, change the value to `1`.

**Warning:** Enabling the reset removes the demonstration tables, their existing data, and the associated triggers. Use this option only when intentionally rebuilding the dedicated demonstration environment.

### 3. Execute the demonstration

Execute the complete SQL file in the SQL client.

The script sequentially:

1. Prepares the database structure.
2. Inserts the synthetic HR dataset.
3. Demonstrates conditional SQL expressions and procedural logic.
4. Processes employee records using a loop.
5. Creates and tests employee audit triggers.
6. Executes standard and recursive CTE queries.
7. Demonstrates date/time calculations and filtering.
8. Performs final database-state validation.

Individual analytical queries can also be executed separately after the required database objects and data have been created.

### 4. Review the results

Inspect the query result sets and execution messages.

Compare the returned data with the expected results described below.

The demonstration contains both data-retrieval queries and statements that create or modify database objects. Not every statement produces a tabular result.

## Validation & Expected Results

The complete demonstration was executed in dbForge Studio for SQL Server against a dedicated SQL Server test environment.

The integration run produced 20 query result sets, which were reviewed against the expected demonstration behavior.

### Functional validation

| Area | Expected result | Test outcome |
|---|---|---|
| Database structure | HR tables and required columns available | Passed |
| HR dataset | 4 departments and 10 employees | Passed |
| CASE expression | Employees classified into salary grades | Passed |
| IF / ELSE | Employee 103 classified as Middle | Passed |
| WHILE processing | 10 employees processed and validated | Passed |
| INSERT trigger | Audit entry created for test employee 999 | Passed |
| DELETE trigger | Audit entry created for test employee 999 | Passed |
| Dataset integrity | Original 10 employees retained after trigger tests | Passed |
| Standard CTE | Department-level salary aggregates returned | Passed |
| Recursive CTE | 10 employees returned in the reporting hierarchy | Passed |
| Date/time queries | Date calculations and time-window filters returned expected data | Passed |

### Final database-state validation

The last query checks the expected database state after a clean execution.

| Validation metric | Expected value | Observed value |
|---|---:|---:|
| Departments | 4 | 4 |
| Employees | 10 | 10 |
| INSERT audit records | 1 | 1 |
| DELETE audit records | 1 | 1 |
| Employee audit triggers | 2 | 2 |

**Result:** All five final database-state metrics matched their expected values.

### Validation notes

- The validation results represent the completed integration test in the dedicated test environment.
- Date/time query results depend on the execution timestamp.
- Repeated execution of individual audit-trigger tests may change audit record counts.
- The recursive hierarchy demonstration does not independently enforce referential integrity for `manager_id` or detect every possible hierarchy anomaly.
- A successful demonstration run does not imply that the simplified HR schema is intended for production use.

## Implementation Scope

This case is designed as a reproducible technical demonstration rather than a production-ready HR application.

The HR business context and employee records are simulated. The SQL objects, queries, procedural logic, triggers, and validation steps are implemented as executable T-SQL.

**The business scenario is simulated where necessary. The technical implementation is real.**
