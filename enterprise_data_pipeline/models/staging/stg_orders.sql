with source as (
    select * from {{ source('raw_data', 'ORDERS') }}
),

renamed as (
    select
        try_to_number("ORDER_ID") as order_id,
        try_to_number("PRODUCT_ID") as product_id,
        try_to_number("QUANTITY") as quantity,
        try_to_double("CUSTOMER_LAT") as customer_lat,
        try_to_double("CUSTOMER_LON") as customer_lon,
        -- Bronze 層は文字列受けなので Silver で型を揃える
        try_to_timestamp_ntz("ORDER_DATE") as ordered_at
    from source
)

select * from renamed