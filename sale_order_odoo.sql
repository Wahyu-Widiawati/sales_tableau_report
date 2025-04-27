 SELECT so.id AS so_id,
    sol.id AS sol_id,
    so.name AS so_number,
    date(so.date_order) AS so_date,
        CASE
            WHEN rp4.ref IS NULL THEN rp3.ref
            ELSE rp4.ref
        END AS customer_id,
        CASE
            WHEN rp4.name IS NULL THEN rp3.name
            ELSE rp4.name
        END AS customer_name,
    rp3.name AS partner_shipping_name,
    rp3.street AS partner_shipping_street,
    rp3.street2 AS partner_shipping_street2,
    rc.name AS partner_shipping_city,
    st.name AS partner_state,
    sr.name AS region,
        CASE
            WHEN (rpi4.name ->> 'en_US'::text) IS NULL THEN rpi3.name ->> 'en_US'::text
            ELSE rpi4.name ->> 'en_US'::text
        END AS channel,
    so.state,
    sw.code AS warehouse_code,
    so.client_order_ref,
    pp.default_code AS item_code,
    pt.name ->> 'en_US'::text AS item_description,
    pcl.category_level_1,
    pcl.category_level_2,
    pcl.category_level_3,
    bc.name AS brand,
    split_part(upper(he.name::text), ' '::text, 1) AS sales_person_first,
    split_part(upper(he.name::text), ' '::text, 2) AS sales_person_last,
    sol.product_uom_qty AS qty,
    round(sol.product_uom_qty * uom_ref.factor / uu.factor * pp.weight, 2) AS qty_kg,
    uu.name ->> 'en_US'::text AS uom,
    sol.price_unit AS unit_price,
    sol.discount,
    dc.discount_global_amount::numeric(16,2) AS discount_global_amount,
    sol.price_subtotal,
    round(atx.amount) AS tax_rate,
    sol.price_tax::numeric(16,2) AS tax,
    sol.price_total,
    so.commitment_date AS delivery_date,
    apt.name ->> 'en_US'::text AS payment_term,
    ai.code AS incoterm,
    regexp_replace(regexp_replace(so.note, '<[^>]+>'::text, ''::text, 'g'::text), '&nbsp;'::text, ' '::text, 'g'::text) AS note,
        CASE
            WHEN atx.price_include = false THEN (
            CASE
                WHEN silir.invoice_line_id IS NOT NULL THEN sol.qty_invoiced
                ELSE sol.product_uom_qty
            END * sol.price_unit)::numeric(16,2)
            ELSE (
            CASE
                WHEN silir.invoice_line_id IS NOT NULL THEN sol.qty_invoiced
                ELSE sol.product_uom_qty
            END * sol.price_unit / 1.11)::numeric(16,2)
        END AS gross_sales,
        CASE
            WHEN sol.coupon_id IS NOT NULL THEN (sol.price_unit * sol.product_uom_qty)::numeric(16,2)
            ELSE 0::numeric(16,2)
        END AS trade_discount,
        CASE
            WHEN sol.discount IS NOT NULL AND sol.coupon_id IS NULL THEN (sol.price_unit * sol.discount / 100::numeric)::numeric(16,2)
            ELSE 0::numeric(16,2)
        END AS line_discount,
        CASE
            WHEN fdc.discount_global_amount IS NOT NULL THEN fdc.discount_global_amount
            ELSE 0::numeric(16,2)
        END AS fixed_discount
   FROM sale_order_line sol
     LEFT JOIN res_partner rp ON sol.order_partner_id = rp.id
     LEFT JOIN res_country_state st ON rp.state_id = st.id
     LEFT JOIN sale_order so ON sol.order_id = so.id
     LEFT JOIN res_partner rp2 ON so.user_id = rp2.id
     LEFT JOIN res_partner rp3 ON so.partner_shipping_id = rp3.id
     LEFT JOIN res_partner rp4 ON rp3.parent_id = rp4.id
     LEFT JOIN product_product pp ON sol.product_id = pp.id
     LEFT JOIN product_template pt ON pp.product_tmpl_id = pt.id
     LEFT JOIN brand bc ON pt.brand_cedea = bc.id
     LEFT JOIN cda_it_custom.product_category_levels pcl ON pcl.id = pt.categ_id
     LEFT JOIN uom_uom uu ON sol.product_uom = uu.id
     LEFT JOIN uom_uom uom_ref ON pt.uom_id = uom_ref.id
     LEFT JOIN account_payment_term apt ON so.payment_term_id = apt.id
     LEFT JOIN account_tax_sale_order_line_rel atsorel ON atsorel.sale_order_line_id = sol.id
     LEFT JOIN account_tax atx ON atsorel.account_tax_id = atx.id
     LEFT JOIN account_incoterms ai ON ai.id = so.incoterm
     LEFT JOIN hr_employee he ON he.user_id = rp2.id
     LEFT JOIN stock_warehouse sw ON so.warehouse_id = sw.id
     LEFT JOIN res_partner_industry rpi3 ON rpi3.id = rp3.industry_id
     LEFT JOIN res_partner_industry rpi4 ON rpi4.id = rp4.industry_id
     LEFT JOIN cda_it_custom.sale_order_line_discount_amount dc ON dc.so_id = so.id AND dc.id = sol.id
     LEFT JOIN sale_order_region sr ON sr.id = rp3.sales_region
     LEFT JOIN res_city rc ON rc.id = rp3.city_id
     LEFT JOIN sale_order_line_invoice_rel silir ON silir.order_line_id = sol.id
     LEFT JOIN cda_it_custom.sales_order_line_fixed_discount fdc ON fdc.so_id = sol.order_id
  WHERE sol.sequence <> 999 AND pp.active = true AND so.state::text = 'sale'::text AND uu.active = true
  ORDER BY sol.order_id, sol.sequence, sol.create_date;