with source as (
    select * from {{ source('raw_data', 'PRODUCTS') }}
),

renamed as (
    select
        try_to_number("PRODUCT_ID") as product_id,
        "PRODUCT_NAME" as product_name,
        try_to_double("WEIGHT_KG") as weight_kg
    from source
)

select * from renamed