create view cda_it_custom.sale_order_tableau_accelerator_sales as (
	SELECT so.so_number,
    so.delivery_date AS order_date,
    'sale_order_tableau_accelerator_sales'::text AS table_names,
    so.item_code AS product_code,
    so.category_level_1 AS product_type,
    so.category_level_3 AS product_category,
    so.item_description AS product,
    NULL::text AS sales_margin,
    so.qty_kg::double precision AS qty_kg,
    so.price_subtotal::double precision AS sales_subtotal_amount,
        CASE
            WHEN so.discount_global_amount IS NULL THEN so.price_total::double precision
            ELSE so.price_total::double precision + so.discount_global_amount::double precision
        END AS sales_amount,
    NULL::text AS sales_margin_target,
    pt.list_price * so.qty * 1.11 AS sales_amount_target,
    pc.name ->> 'en_US'::text AS country,
    so.partner_state AS state,
    so.partner_shipping_city AS city,
    so.customer_id AS client,
    so.qty AS sales_quantity,
    so.customer_name AS customer,
    so.category_level_3 AS product_sub_group,
    so.region,
    so.channel AS sale_channel,
    so.discount_global_amount
   FROM cda_it_custom.sale_order_odoo so
     LEFT JOIN product_product pp ON pp.default_code::text = so.item_code::text
     LEFT JOIN product_template pt ON pp.product_tmpl_id = pt.id
     LEFT JOIN res_partner rp ON so.customer_id::text = rp.ref::text
     LEFT JOIN res_country pc ON rp.country_id = pc.id
  WHERE pp.active = true AND rp.active = true AND pt.active = true AND so.so_date >= '2025-03-01'::date
UNION ALL
 SELECT sale_order_history.order_no AS so_number,
    sale_order_history.ship_date::timestamp without time zone AS order_date,
    sale_order_history.table_names,
    sale_order_history.product_code,
    sale_order_history.product_type,
    sale_order_history.product_category,
    sale_order_history.product,
    sale_order_history.sales_margin,
    sale_order_history.qty_kg,
    sale_order_history.sales_subtotal_amount,
    sale_order_history.sales_amount,
    sale_order_history.sales_margin_target,
    sale_order_history.sales_amount_target::numeric AS sales_amount_target,
    sale_order_history.country,
    sale_order_history.state,
    sale_order_history.city,
    sale_order_history.client,
    sale_order_history.sales_quantity,
    sale_order_history.customer,
    sale_order_history.product_sub_group,
    sale_order_history.region,
    sale_order_history.sale_channel,
    sale_order_history.discount_global AS discount_global_amount
   FROM cda_it_custom.sale_order_history
  ORDER BY 1
)