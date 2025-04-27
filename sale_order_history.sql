 WITH rp_filtered AS (
         SELECT DISTINCT ON (rp_1.accurate_id) rp_1.id,
            rp_1.company_id,
            rp_1.create_date,
            rp_1.name,
            rp_1.title,
            rp_1.parent_id,
            rp_1.user_id,
            rp_1.state_id,
            rp_1.country_id,
            rp_1.industry_id,
            rp_1.color,
            rp_1.commercial_partner_id,
            rp_1.create_uid,
            rp_1.write_uid,
            rp_1.complete_name,
            rp_1.ref,
            rp_1.lang,
            rp_1.tz,
            rp_1.vat,
            rp_1.company_registry,
            rp_1.website,
            rp_1.function,
            rp_1.type,
            rp_1.street,
            rp_1.street2,
            rp_1.zip,
            rp_1.city,
            rp_1.email,
            rp_1.phone,
            rp_1.mobile,
            rp_1.commercial_company_name,
            rp_1.company_name,
            rp_1.date,
            rp_1.comment,
            rp_1.partner_latitude,
            rp_1.partner_longitude,
            rp_1.active,
            rp_1.employee,
            rp_1.is_company,
            rp_1.partner_share,
            rp_1.write_date,
            rp_1.contact_address_complete,
            rp_1.message_bounce,
            rp_1.email_normalized,
            rp_1.signup_type,
            rp_1.signup_expiration,
            rp_1.signup_token,
            rp_1.partner_gid,
            rp_1.additional_info,
            rp_1.phone_sanitized,
            rp_1.ocn_token,
            rp_1.supplier_rank,
            rp_1.customer_rank,
            rp_1.invoice_warn,
            rp_1.invoice_warn_msg,
            rp_1.debit_limit,
            rp_1.last_time_entries_checked,
            rp_1.ubl_cii_format,
            rp_1.peppol_endpoint,
            rp_1.peppol_eas,
            rp_1.online_partner_information,
            rp_1.followup_reminder_type,
            rp_1.vies_valid,
            rp_1.l10n_id_nik,
            rp_1.l10n_id_tax_address,
            rp_1.l10n_id_tax_name,
            rp_1.l10n_id_kode_transaksi,
            rp_1.l10n_id_pkp,
            rp_1.team_id,
            rp_1.sale_warn,
            rp_1.sale_warn_msg,
            rp_1.buyer_id,
            rp_1.purchase_warn,
            rp_1.purchase_warn_msg,
            rp_1.picking_warn,
            rp_1.picking_warn_msg,
            rp_1.city_id,
            rp_1.kecamatan_id,
            rp_1.kelurahan_id,
            rp_1.zipcode_id,
            rp_1.is_customer,
            rp_1.cash_discount,
            rp_1.default_warehouse_id,
            rp_1.email_procurement,
            rp_1.cc_procurement,
            rp_1.nik,
            rp_1.name_as_nik,
            rp_1.is_vendor,
            rp_1.accurate_id,
            rp_1.sales_region,
            rp_1.delivery_instruction,
            rp_1.is_kag,
            rp_1.l10n_id_tku,
            rp_1.l10n_id_buyer_document_type,
            rp_1.l10n_id_buyer_document_number
           FROM res_partner rp_1
          WHERE rp_1.active = true AND rp_1.type::text = 'delivery'::text
          ORDER BY rp_1.accurate_id, rp_1.id
        )
 SELECT soa.invoice_no,
    soa.order_no,
    soa.ship_date,
    'sale_order_line_accurate_history'::text AS table_names,
    soa.item_no AS product_code,
    pcl.category_level_1 AS product_type,
    pcl.category_level_3 AS product_category,
    pt.name ->> 'en_US'::text AS product,
    NULL::text AS sales_margin,
    pt.weight::double precision * soa.invoiced_qty AS qty_kg,
    soa.price_subtotal AS sales_subtotal_amount,
        CASE
            WHEN soa.subtotal <> 0::double precision THEN soa.price_subtotal / soa.subtotal * soa.tax_amount
            WHEN soa.subtotal = 0::double precision THEN 0::double precision
            ELSE NULL::double precision
        END AS tax_sol,
        CASE
            WHEN soa.subtotal <> 0::double precision THEN soa.price_subtotal / soa.subtotal * soa.discount
            WHEN soa.subtotal = 0::double precision THEN 0::double precision
            ELSE NULL::double precision
        END AS discount_global,
        CASE
            WHEN soa.subtotal <> 0::double precision AND soa.inclusive_tax = 'Yes'::text THEN soa.price_subtotal - soa.price_subtotal / soa.subtotal * soa.discount
            WHEN soa.subtotal <> 0::double precision AND soa.inclusive_tax = 'No'::text THEN soa.price_subtotal - soa.price_subtotal / soa.subtotal * soa.discount + soa.price_subtotal / soa.subtotal * soa.tax_amount
            WHEN soa.subtotal = 0::double precision THEN 0::double precision
            ELSE NULL::double precision
        END AS sales_amount,
    NULL::text AS sales_margin_target,
    pt.list_price::double precision * soa.invoiced_qty * 1.11::double precision AS sales_amount_target,
    rc.name ->> 'en_US'::text AS country,
    rs.name AS state,
    rci.name AS city,
        CASE
            WHEN rp2.ref IS NULL THEN rp.ref
            ELSE rp2.ref
        END AS client,
    soa.invoiced_qty::numeric AS sales_quantity,
        CASE
            WHEN rp2.name IS NULL THEN rp.name
            ELSE rp2.name
        END AS customer,
    pcl.category_level_3 AS product_sub_group,
    sr.name AS region,
    rpi.name ->> 'en_US'::text AS sale_channel
   FROM cda_it_custom.sale_order_line_accurate_history soa
     LEFT JOIN product_product pp ON pp.default_code::text = soa.item_no
     LEFT JOIN product_template pt ON pt.id = pp.product_tmpl_id
     LEFT JOIN product_category pc ON pc.id = pt.categ_id
     LEFT JOIN cda_it_custom.product_category_levels pcl ON pcl.id = pc.id
     LEFT JOIN rp_filtered rp ON rp.accurate_id::text = soa.customer_no
     LEFT JOIN res_partner rp2 ON rp2.id = rp.parent_id
     LEFT JOIN res_country rc ON rc.id = rp.country_id
     LEFT JOIN res_partner_industry rpi ON rpi.id = rp.industry_id
     LEFT JOIN res_country_state rs ON rs.id = rp.state_id
     LEFT JOIN sale_order_region sr ON sr.id = rp.sales_region
     LEFT JOIN res_city rci ON rci.id = rp2.city_id
  WHERE pp.active = true AND pt.active = true AND rp.active = true AND soa.invoiced_qty > 0::double precision
  ORDER BY soa.order_no;