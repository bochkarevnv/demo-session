# demo-session
Demo dbt+duckdb project for user session computing

## Installation and preparation steps
Install requirements:

`pip install dbt-duckdb~=1.9.2`

Install dbt deps:

`dbt deps`

Load seed data: 

`dbt seed`

## Demo using
Truncate and load first day data:

`dbt run --vars '{"start_date": "2025-01-01"}' --full-refresh`

Run comparison for first day:

`dbt test --vars '{"start_date": "2025-01-01"}'`

Load second day data:

`dbt run --vars '{"start_date": "2025-01-02"}'`

Run comparison for second day:

`dbt test --debug --vars '{"start_date": "2025-01-02"}'`

Also you can open `demo_session.duckdb` with your IDE or CLI tool and query loaded data.