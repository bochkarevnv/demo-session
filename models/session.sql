{{
    config(
        materialized="incremental",
        incremental_strategy="delete+insert",
        unique_key=["user_id", "event_id", "timestamp", "product_code", "dt"],
        partition_by="dt",
    )
}}

with
    all_data as (
        select
            user_id,
            event_id,
            timestamp,
            product_code,
            timestamp::date as dt,
            null::timestamp as old_session_start_ts
        from {{ ref("raw_source") }}
        {% if is_incremental() %}
            union all
            select
                user_id,
                event_id,
                timestamp,
                product_code,
                dt,
                session_start_ts as old_session_start_ts
            from {{ this }}
            where
                dt >= '{{ var("start_date") | string}}'::date - {{ var("raw_data_delay") }}
        {% endif %}
    ),
    splited as (
        select
            *,
            if(
                event_id in ({{ var("user_event_filter") }}), timestamp, null
            ) as user_act_ts,
            lag(user_act_ts ignore nulls) over (
                partition by user_id, product_code
                order by timestamp, user_act_ts nulls last
            ) as prev_user_act_ts,
            case
                when
                    epoch(timestamp) - epoch(prev_user_act_ts)
                    > {{ var("user_activity_delay") }}
                    or prev_user_act_ts is null
                then 1
                else 0
            end as new_sess_start
        from all_data
    ),
    sessions as (
        select
            *,
            sum(new_sess_start) over (
                partition by user_id, product_code
                order by timestamp, user_act_ts nulls last
            ) as session_num
        from splited
    )
select
    user_id,
    event_id,
    timestamp,
    product_code,
    dt,
    first_value(coalesce(old_session_start_ts, user_act_ts)) over (
        partition by user_id, product_code, session_num
        order by timestamp, user_act_ts nulls last
    ) as session_start_ts,
    user_id
    || '#'
    || product_code
    || '#'
    || epoch(session_start_ts)::int::string as session_id
from sessions
