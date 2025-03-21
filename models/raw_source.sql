{{ config(materialized="view") }}

select *
from {{ ref("data_" + var("start_date") | string) }}