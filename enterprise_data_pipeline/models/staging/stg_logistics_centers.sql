with source as (
    select * from {{ source('raw_data', 'LOGISTICS_CENTERS') }}
),

renamed as (
    select
        try_to_number("CENTER_ID") as center_id,
        "CENTER_NAME" as center_name,
        try_to_double("LATITUDE") as latitude,
        try_to_double("LONGITUDE") as longitude
    from source
)

select * from renamed