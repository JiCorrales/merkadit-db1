-- seed_merkadit_data.sql
-- Resets and fills Merkadit database with comprehensive sample data.
-- WARNING: this script truncates existing data in the affected tables.

USE Merkadit;

SET @seed_now := NOW();
SET @month_anchor := DATE_SUB(DATE(@seed_now), INTERVAL DAYOFMONTH(@seed_now) - 1 DAY);

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE mk_transactions;
TRUNCATE TABLE mk_logs;
TRUNCATE TABLE mk_receiptDetails;
TRUNCATE TABLE mk_receipts;
TRUNCATE TABLE mk_payments;
TRUNCATE TABLE mk_inventory;
TRUNCATE TABLE mk_productPrices;
TRUNCATE TABLE mk_products;
TRUNCATE TABLE mk_contractsPerKiosks;
TRUNCATE TABLE mk_contractFees;
TRUNCATE TABLE mk_tenantPerContracts;
TRUNCATE TABLE mk_tenantContactInfo;
TRUNCATE TABLE mk_tenant;
TRUNCATE TABLE mk_contracts;
TRUNCATE TABLE mk_kiosks;
TRUNCATE TABLE mk_kioskStatus;
TRUNCATE TABLE mk_kioskType;
TRUNCATE TABLE mk_locals;
TRUNCATE TABLE mk_markets_per_building;
TRUNCATE TABLE mk_building;
TRUNCATE TABLE mk_markets;
TRUNCATE TABLE mk_marketContactInfo;
TRUNCATE TABLE mk_contactInfoType;
TRUNCATE TABLE mk_addresses;
TRUNCATE TABLE mk_cities;
TRUNCATE TABLE mk_states;
TRUNCATE TABLE mk_countries;
TRUNCATE TABLE mk_productType;
TRUNCATE TABLE mk_clients;
TRUNCATE TABLE mk_clientType;
TRUNCATE TABLE mk_userRoles;
TRUNCATE TABLE mk_roles;
TRUNCATE TABLE mk_users;
TRUNCATE TABLE mk_logLevels;
TRUNCATE TABLE mk_logServices;
TRUNCATE TABLE mk_logTypes;
TRUNCATE TABLE mk_transactionTypes;
SET FOREIGN_KEY_CHECKS = 1;

-- Master data
INSERT INTO mk_countries (countryName) VALUES ('Costa Rica');
SET @country_cr := LAST_INSERT_ID();

INSERT INTO mk_states (stateName, countryID) VALUES ('San Jose', @country_cr), ('Alajuela', @country_cr);

SET @state_sj := (SELECT stateID FROM mk_states WHERE stateName = 'San Jose');
SET @state_al := (SELECT stateID FROM mk_states WHERE stateName = 'Alajuela');

INSERT INTO mk_cities (cityName, stateID) VALUES ('San Jose', @state_sj), ('Escazu', @state_sj), ('Alajuela', @state_al);

SET @city_sj := (SELECT cityID FROM mk_cities WHERE cityName = 'San Jose' LIMIT 1);
SET @city_escazu := (SELECT cityID FROM mk_cities WHERE cityName = 'Escazu' LIMIT 1);
SET @city_alajuela := (SELECT cityID FROM mk_cities WHERE cityName = 'Alajuela' LIMIT 1);

INSERT INTO mk_addresses (address, zipCode, geoLocation, postTime, cityID)
VALUES ('Avenida Central 123', '10101', ST_GeomFromText('POINT(-84.0810 9.9333)', 4326), @seed_now, @city_sj);
SET @addr_market := LAST_INSERT_ID();

INSERT INTO mk_addresses (address, zipCode, geoLocation, postTime, cityID)
VALUES ('Boulevard Comercio 45', '10102', ST_GeomFromText('POINT(-84.0840 9.9400)', 4326), @seed_now, @city_sj);
SET @addr_building_main := LAST_INSERT_ID();

INSERT INTO mk_addresses (address, zipCode, geoLocation, postTime, cityID)
VALUES ('Avenida Innovacion 77', '10103', ST_GeomFromText('POINT(-84.0895 9.9455)', 4326), @seed_now, @city_sj);
SET @addr_building_annex := LAST_INSERT_ID();

INSERT INTO mk_contactInfoType (contactType) VALUES ('PHONE'), ('EMAIL');
SET @contact_phone := (SELECT contactInfoTypeID FROM mk_contactInfoType WHERE contactType = 'PHONE');
SET @contact_email := (SELECT contactInfoTypeID FROM mk_contactInfoType WHERE contactType = 'EMAIL');

DROP PROCEDURE IF EXISTS seed_market_and_contact_info;
DELIMITER //
CREATE PROCEDURE seed_market_and_contact_info()
BEGIN
    DECLARE has_market_fk INT DEFAULT 0;
    DECLARE has_contact_fk INT DEFAULT 0;
    DECLARE contact_phone_id INT DEFAULT NULL;
    DECLARE contact_email_id INT DEFAULT NULL;
    DECLARE new_market_id INT DEFAULT NULL;

    SELECT COUNT(*)
      INTO has_market_fk
      FROM information_schema.columns
     WHERE table_schema = DATABASE()
       AND table_name = 'mk_markets'
       AND column_name = 'marketContactInfoID';

    SELECT COUNT(*)
      INTO has_contact_fk
      FROM information_schema.columns
     WHERE table_schema = DATABASE()
       AND table_name = 'mk_marketContactInfo'
       AND column_name = 'marketID';

    IF has_market_fk > 0 THEN
        INSERT INTO mk_marketContactInfo (contact, enabled, lastUpdated, contactInfoTypeID)
        VALUES ('+506-2255-0101', b'1', @seed_now, @contact_phone);
        SET contact_phone_id = LAST_INSERT_ID();

        INSERT INTO mk_marketContactInfo (contact, enabled, lastUpdated, contactInfoTypeID)
        VALUES ('info@merkadit.test', b'1', @seed_now, @contact_email);
        SET contact_email_id = LAST_INSERT_ID();

        INSERT INTO mk_markets (marketName, marketDescription, cedulaJuridica, type, size, enabled, deleted, lastUpdated, legalAddressID, marketContactInfoID)
        VALUES ('Merkadit Central', 'Urban marketplace for local vendors', '301020304001', 'URBANO', 200, b'1', b'0', @seed_now, @addr_market, contact_phone_id);
        SET new_market_id = LAST_INSERT_ID();
    ELSE
        INSERT INTO mk_markets (marketName, marketDescription, cedulaJuridica, type, size, enabled, deleted, lastUpdated, legalAddressID)
        VALUES ('Merkadit Central', 'Urban marketplace for local vendors', '301020304001', 'URBANO', 200, b'1', b'0', @seed_now, @addr_market);
        SET new_market_id = LAST_INSERT_ID();

        INSERT INTO mk_marketContactInfo (contact, enabled, lastUpdated, contactInfoTypeID, marketID)
        VALUES ('+506-2255-0101', b'1', @seed_now, @contact_phone, new_market_id);
        SET contact_phone_id = LAST_INSERT_ID();

        INSERT INTO mk_marketContactInfo (contact, enabled, lastUpdated, contactInfoTypeID, marketID)
        VALUES ('info@merkadit.test', b'1', @seed_now, @contact_email, new_market_id);
        SET contact_email_id = LAST_INSERT_ID();
    END IF;

    SET @market_main = new_market_id;
    SET @market_contact_phone = contact_phone_id;
    SET @market_contact_email = contact_email_id;
END//
DELIMITER ;
CALL seed_market_and_contact_info();
DROP PROCEDURE IF EXISTS seed_market_and_contact_info;

INSERT INTO mk_building (buildingName, addressID) VALUES ('Edificio Central', @addr_building_main), ('Edificio Innovacion', @addr_building_annex);
SET @building_central := (SELECT buildingID FROM mk_building WHERE buildingName = 'Edificio Central' LIMIT 1);
SET @building_innovacion := (SELECT buildingID FROM mk_building WHERE buildingName = 'Edificio Innovacion' LIMIT 1);

INSERT INTO mk_markets_per_building (marketID, buildingID, deleted, postTime)
VALUES
(@market_main, @building_central, b'0', @seed_now),
(@market_main, @building_innovacion, b'0', @seed_now);

INSERT INTO mk_productType (productType, productFee) VALUES ('BEBIDAS', 0.08), ('SNACKS', 0.05), ('COMIDAS', 0.07);

SET @ptype_bebidas := (SELECT productTypeID FROM mk_productType WHERE productType = 'BEBIDAS');
SET @ptype_snacks := (SELECT productTypeID FROM mk_productType WHERE productType = 'SNACKS');
SET @ptype_comidas := (SELECT productTypeID FROM mk_productType WHERE productType = 'COMIDAS');

INSERT INTO mk_kioskType (kioskType) VALUES ('ISLA'), ('CARRETA');
SET @kiosk_type_isla := (SELECT kioskTypeID FROM mk_kioskType WHERE kioskType = 'ISLA');
SET @kiosk_type_carreta := (SELECT kioskTypeID FROM mk_kioskType WHERE kioskType = 'CARRETA');

INSERT INTO mk_kioskStatus (statusName) VALUES ('ACTIVE'), ('MAINTENANCE');
SET @kiosk_status_active := (SELECT statusID FROM mk_kioskStatus WHERE statusName = 'ACTIVE');
SET @kiosk_status_maintenance := (SELECT statusID FROM mk_kioskStatus WHERE statusName = 'MAINTENANCE');

INSERT INTO mk_locals (buildingID, localCode, localName, area_m2)
VALUES
(@building_central, 'L-101', 'Local Central', 85.50),
(@building_innovacion, 'L-201', 'Local Sur', 62.75),
(@building_innovacion, 'L-202', 'Local Este', 58.40);

SET @local_101 := (SELECT localID FROM mk_locals WHERE localCode = 'L-101');
SET @local_201 := (SELECT localID FROM mk_locals WHERE localCode = 'L-201');
SET @local_202 := (SELECT localID FROM mk_locals WHERE localCode = 'L-202');

INSERT INTO mk_kiosks (kioskPrice, area_m2, kioskTypeID, statusID, localID, marketID)
VALUES
(450.00, 12.50, @kiosk_type_isla, @kiosk_status_active, @local_101, @market_main),
(330.00, 10.80, @kiosk_type_carreta, @kiosk_status_active, @local_201, @market_main),
(310.00, 9.40, @kiosk_type_carreta, @kiosk_status_active, @local_202, @market_main);

DROP TEMPORARY TABLE IF EXISTS tmp_local_kiosk_map;
CREATE TEMPORARY TABLE tmp_local_kiosk_map AS
SELECT localID, kioskID FROM mk_kiosks;

INSERT INTO mk_clientType (clientType) VALUES ('REGULAR'), ('CORPORATE');

INSERT INTO mk_roles (roleName, enabled) VALUES ('ADMIN', b'1'), ('CASHIER', b'1'), ('SUPPORT', b'1');

INSERT INTO mk_logTypes (logTypeName) VALUES ('BUSINESS'), ('SETTLEMENT_ERROR'), ('SETTLEMENT_WARNING'), ('SETTLEMENT_SUCCESS');
INSERT INTO mk_logServices (logServiceName) VALUES ('POS'), ('FINANCIAL');
INSERT INTO mk_logLevels (logLevelName) VALUES ('INFO'), ('ERROR'), ('WARNING');
INSERT INTO mk_transactionTypes (transactionType) VALUES ('SALE_PAYMENT'), ('REFUND'), ('COMISION_VENTAS'), ('PAGO_ALQUILER');

-- Randomized user generation using temporary tables
DROP TEMPORARY TABLE IF EXISTS tmp_user_first_names;
CREATE TEMPORARY TABLE tmp_user_first_names (firstName VARCHAR(15));
INSERT INTO tmp_user_first_names (firstName) VALUES
('Ana'), ('Luis'), ('Maria'), ('Carlos'), ('Sofia'), ('Diego'), ('Elena'), ('Jorge');

DROP TEMPORARY TABLE IF EXISTS tmp_user_last_names;
CREATE TEMPORARY TABLE tmp_user_last_names (lastName VARCHAR(15));
INSERT INTO tmp_user_last_names (lastName) VALUES
('Romero'), ('Mendez'), ('Castro'), ('Flores'), ('Salas'), ('Vega'), ('Campos'), ('Rojas');

DROP TEMPORARY TABLE IF EXISTS tmp_user_pool;
CREATE TEMPORARY TABLE tmp_user_pool AS
SELECT
    ROW_NUMBER() OVER (ORDER BY fn.firstName, ln.lastName) AS rn,
    fn.firstName,
    ln.lastName
FROM tmp_user_first_names fn
CROSS JOIN tmp_user_last_names ln;

INSERT INTO mk_users (name, lastName, password, enabled, createdAt)
SELECT
    up.firstName,
    up.lastName,
    UNHEX(SHA2(CONCAT(up.firstName, ':', up.lastName, '#mk'), 256)),
    b'1',
    DATE_SUB(@seed_now, INTERVAL FLOOR(RAND() * 365) DAY)
FROM tmp_user_pool up
ORDER BY RAND()
LIMIT 6;

DROP TEMPORARY TABLE IF EXISTS tmp_user_ids;
CREATE TEMPORARY TABLE tmp_user_ids AS
SELECT
    u.userID,
    u.name,
    u.lastName,
    ROW_NUMBER() OVER (ORDER BY u.userID) AS seq
FROM mk_users u;

SET @role_admin := (SELECT roleID FROM mk_roles WHERE roleName = 'ADMIN');
SET @role_cashier := (SELECT roleID FROM mk_roles WHERE roleName = 'CASHIER');
SET @role_support := (SELECT roleID FROM mk_roles WHERE roleName = 'SUPPORT');

INSERT INTO mk_userRoles (roleID, userID, enabled, postTime)
SELECT @role_admin, userID, b'1', @seed_now
FROM tmp_user_ids
WHERE seq = 1;

INSERT INTO mk_userRoles (roleID, userID, enabled, postTime)
SELECT @role_cashier, userID, b'1', @seed_now
FROM tmp_user_ids
WHERE seq BETWEEN 2 AND 4;

INSERT INTO mk_userRoles (roleID, userID, enabled, postTime)
SELECT @role_support, userID, b'1', @seed_now
FROM tmp_user_ids
WHERE seq BETWEEN 5 AND 6;

-- Randomized client generation using temporary tables
DROP TEMPORARY TABLE IF EXISTS tmp_client_first_names;
CREATE TEMPORARY TABLE tmp_client_first_names (firstName VARCHAR(20));
INSERT INTO tmp_client_first_names (firstName) VALUES
('Laura'), ('Mateo'), ('Isabel'), ('Ricardo'), ('Daniela'), ('Pedro'), ('Camila'), ('Andres');

DROP TEMPORARY TABLE IF EXISTS tmp_client_last_names;
CREATE TEMPORARY TABLE tmp_client_last_names (lastName VARCHAR(20));
INSERT INTO tmp_client_last_names (lastName) VALUES
('Lopez'), ('Gonzalez'), ('Solano'), ('Aguilar'), ('Rodriguez'), ('Pineda'), ('Soto'), ('Zamora');

DROP TEMPORARY TABLE IF EXISTS tmp_client_pool;
CREATE TEMPORARY TABLE tmp_client_pool AS
SELECT
    ROW_NUMBER() OVER (ORDER BY fn.firstName, ln.lastName) AS rn,
    CONCAT(fn.firstName, ' ', ln.lastName) AS clientName
FROM tmp_client_first_names fn
CROSS JOIN tmp_client_last_names ln;

INSERT INTO mk_clients (clientCode, clientName, clientTypeID)
SELECT
    CONCAT('CLI-', LPAD(rn, 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')),
    cp.clientName,
    CASE WHEN RAND() < 0.25 THEN (SELECT clientTypeID FROM mk_clientType WHERE clientType = 'CORPORATE')
            ELSE (SELECT clientTypeID FROM mk_clientType WHERE clientType = 'REGULAR') END
FROM tmp_client_pool cp
ORDER BY RAND()
LIMIT 30;

-- Payment methods
INSERT INTO mk_payments (paymentMethodName, paymentConfirmation)
VALUES
('EFECTIVO', 'CASH-INIT-001'),
('TARJETA', 'CARD-INIT-002');

SET @payment_cash := (SELECT paymentID FROM mk_payments WHERE paymentMethodName = 'EFECTIVO');
SET @payment_card := (SELECT paymentID FROM mk_payments WHERE paymentMethodName = 'TARJETA');

SET @client_total := (SELECT COUNT(*) FROM mk_clients);

-- Business seeding per local
DROP TEMPORARY TABLE IF EXISTS tmp_numbers_small;
CREATE TEMPORARY TABLE tmp_numbers_small (num INT);
INSERT INTO tmp_numbers_small (num) VALUES (1),(2),(3),(4),(5),(6),(7);

DROP TEMPORARY TABLE IF EXISTS tmp_local_business_counts;
CREATE TEMPORARY TABLE tmp_local_business_counts AS
SELECT localID, 4 + FLOOR(RAND() * 4) AS tenantCount
FROM mk_locals
WHERE localID IN (@local_101, @local_201, @local_202);

SET @total_businesses := (SELECT SUM(tenantCount) FROM tmp_local_business_counts);

DROP TEMPORARY TABLE IF EXISTS tmp_business_adj;
CREATE TEMPORARY TABLE tmp_business_adj (adj VARCHAR(20));
INSERT INTO tmp_business_adj (adj) VALUES
('Fresco'), ('Sabores'), ('Esencia'), ('Mercado'), ('Delicias'), ('Raices'), ('Fusion'), ('Vital');

DROP TEMPORARY TABLE IF EXISTS tmp_business_noun;
CREATE TEMPORARY TABLE tmp_business_noun (noun VARCHAR(20));
INSERT INTO tmp_business_noun (noun) VALUES
('Andes'), ('Tropico'), ('Sabor'), ('Encanto'), ('Pueblo'), ('Gourmet'), ('Origen'), ('Cocina');

DROP TEMPORARY TABLE IF EXISTS tmp_business_candidates;
CREATE TEMPORARY TABLE tmp_business_candidates AS
SELECT CONCAT(adj.adj, ' ', noun.noun) AS businessBase, RAND() AS randKey
FROM tmp_business_adj adj
CROSS JOIN tmp_business_noun noun;

DROP TEMPORARY TABLE IF EXISTS tmp_business_name_pool;
CREATE TEMPORARY TABLE tmp_business_name_pool AS
SELECT
    pool_seq,
    businessBase,
    CASE ((pool_seq - 1) % 3)
        WHEN 0 THEN 'BEBIDAS'
        WHEN 1 THEN 'SNACKS'
        ELSE 'COMIDAS'
    END AS productTypeKey,
    CASE ((pool_seq - 1) % 4)
        WHEN 0 THEN 'FOOD_SERVICE'
        WHEN 1 THEN 'RETAIL'
        WHEN 2 THEN 'ARTISANAL'
        ELSE 'SPECIALTY'
    END AS businessType,
    CONCAT('Comercial ', LPAD(pool_seq, 3, '0')) AS legalName,
    CONCAT('Local ', LPAD(pool_seq, 3, '0'), ' Comercio Ave') AS addressLine,
    LPAD(10110 + pool_seq, 5, '0') AS zipCode,
    -84.095 + pool_seq * 0.0015 AS geoLon,
    9.935 + pool_seq * 0.001 AS geoLat
FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY randKey) AS pool_seq, businessBase
    FROM tmp_business_candidates
) ordered
WHERE pool_seq <= @total_businesses;

DROP TEMPORARY TABLE IF EXISTS tmp_business_positions;
CREATE TEMPORARY TABLE tmp_business_positions AS
SELECT
    l.localID,
    l.tenantCount,
    n.num AS position,
    ROW_NUMBER() OVER (ORDER BY l.localID, n.num) AS pos_seq
FROM tmp_local_business_counts l
JOIN tmp_numbers_small n ON n.num <= l.tenantCount;

DROP TEMPORARY TABLE IF EXISTS tmp_business_seed;
CREATE TEMPORARY TABLE tmp_business_seed AS
SELECT
    pos.pos_seq AS seq,
    pos.localID,
    loc.localCode,
    name.businessBase,
    CONCAT(name.businessBase, ' ', loc.localCode) AS tenantName,
    CONCAT(name.legalName, ' ', loc.localCode) AS tenantLegalName,
    300000000 + pos.pos_seq AS tenantLegalID,
    400000000 + pos.pos_seq AS taxID,
    name.businessType,
    name.productTypeKey,
    pt.productTypeID,
    CONCAT(name.addressLine, ' - ', loc.localCode) AS addressLine,
    name.zipCode,
    name.geoLon,
    name.geoLat
FROM tmp_business_positions pos
JOIN mk_locals loc ON loc.localID = pos.localID
JOIN tmp_business_name_pool name ON name.pool_seq = pos.pos_seq
JOIN mk_productType pt ON pt.productType = name.productTypeKey
ORDER BY pos.pos_seq;

INSERT INTO mk_addresses (address, zipCode, geoLocation, postTime, cityID)
SELECT addressLine, zipCode, ST_SRID(POINT(geoLon, geoLat), 4326), @seed_now, @city_sj
FROM tmp_business_seed;

DROP TEMPORARY TABLE IF EXISTS tmp_business_data;
CREATE TEMPORARY TABLE tmp_business_data AS
SELECT
    bs.seq,
    bs.localID,
    bs.localCode,
    bs.tenantName,
    bs.tenantLegalName,
    bs.tenantLegalID,
    bs.taxID,
    bs.businessType,
    bs.productTypeKey,
    bs.productTypeID,
    addr.addressID
FROM tmp_business_seed bs
JOIN mk_addresses addr ON addr.address = bs.addressLine
ORDER BY bs.seq;

INSERT INTO mk_tenant (tenantName, tenantLegalAddressID, tenantLegalID, tenantLegalName, taxID, businessType)
SELECT
    bd.tenantName,
    bd.addressID,
    bd.tenantLegalID,
    CONCAT(bd.tenantLegalName, ' LTDA'),
    bd.taxID,
    bd.businessType
FROM tmp_business_data bd
ORDER BY bd.seq;

DROP TEMPORARY TABLE IF EXISTS tmp_tenant_map;
CREATE TEMPORARY TABLE tmp_tenant_map AS
SELECT
    bd.seq,
    t.tenantID,
    bd.localID,
    bd.productTypeID,
    bd.productTypeKey,
    bd.businessType
FROM tmp_business_data bd
JOIN mk_tenant t ON t.tenantName = bd.tenantName
ORDER BY bd.seq;

DROP TEMPORARY TABLE IF EXISTS tmp_contract_seed;
CREATE TEMPORARY TABLE tmp_contract_seed AS
SELECT
    tm.seq,
    tm.localID,
    tm.productTypeID,
    DATE_SUB(@seed_now, INTERVAL (20 + tm.seq * 5) DAY) AS startDate,
    DATE_ADD(DATE_SUB(@seed_now, INTERVAL (20 + tm.seq * 5) DAY), INTERVAL 1 YEAR) AS expirationDate,
    ROUND(420 + (tm.seq * 23) % 680, 2) AS rentAmount,
    DATE_ADD(@month_anchor, INTERVAL ((tm.seq * 3) % 20) DAY) AS rentDueDay,
    ROUND(0.05 + ((tm.seq % 5)), 2) AS feeOnSales
FROM tmp_tenant_map tm;

INSERT INTO mk_contracts (startDate, expirationDate, rent, rentDueDay, feeOnSales, productTypeID, localID)
SELECT startDate, expirationDate, rentAmount, rentDueDay, feeOnSales, productTypeID, localID
FROM tmp_contract_seed
ORDER BY seq;

DROP TEMPORARY TABLE IF EXISTS tmp_contract_ids;
CREATE TEMPORARY TABLE tmp_contract_ids AS
SELECT
    ROW_NUMBER() OVER (ORDER BY contractID) AS seq,
    contractID,
    startDate
FROM mk_contracts;

INSERT INTO mk_tenantPerContracts (tenantID, contractID, deleted, postTime)
SELECT tm.tenantID, ci.contractID, b'0', @seed_now
FROM tmp_tenant_map tm
JOIN tmp_contract_ids ci ON ci.seq = tm.seq;

INSERT INTO mk_contractsPerKiosks (contractID, kioskID, startDate, endDate)
SELECT ci.contractID, lkm.kioskID, ci.startDate, NULL
FROM tmp_tenant_map tm
JOIN tmp_contract_ids ci ON ci.seq = tm.seq
JOIN tmp_local_kiosk_map lkm ON lkm.localID = tm.localID;

DROP TEMPORARY TABLE IF EXISTS tmp_tenant_min_seq;
CREATE TEMPORARY TABLE tmp_tenant_min_seq AS
SELECT productTypeKey, MIN(seq) AS min_seq
FROM tmp_tenant_map
GROUP BY productTypeKey;

DROP TEMPORARY TABLE IF EXISTS tmp_inventory_businesses;
CREATE TEMPORARY TABLE tmp_inventory_businesses AS
SELECT
    tm.seq,
    tm.tenantID,
    tm.localID,
    tm.productTypeID,
    tm.productTypeKey,
    ci.contractID,
    lkm.kioskID
FROM tmp_tenant_map tm
JOIN tmp_tenant_min_seq chooser ON chooser.productTypeKey = tm.productTypeKey AND chooser.min_seq = tm.seq
JOIN tmp_contract_ids ci ON ci.seq = tm.seq
JOIN tmp_local_kiosk_map lkm ON lkm.localID = tm.localID
ORDER BY tm.seq;

DROP TEMPORARY TABLE IF EXISTS tmp_tenant_min_seq;
DROP TEMPORARY TABLE IF EXISTS tmp_numbers_three;
CREATE TEMPORARY TABLE tmp_numbers_three (num INT);
INSERT INTO tmp_numbers_three (num) VALUES (1),(2),(3);

DROP TEMPORARY TABLE IF EXISTS tmp_product_catalog;
CREATE TEMPORARY TABLE tmp_product_catalog AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ib.seq, n.num) AS prod_seq,
    ib.tenantID,
    ib.localID,
    ib.productTypeID,
    ib.productTypeKey,
    ib.kioskID,
    CONCAT(ib.productTypeKey, '_', LPAD(n.num, 2, '0'), '_', ib.seq) AS productName,
    CASE ib.productTypeKey
        WHEN 'BEBIDAS' THEN CONCAT('Bebida artesanal mezcla ', n.num)
        WHEN 'SNACKS' THEN CONCAT('Snack gourmet variedad ', n.num)
        ELSE CONCAT('Plato casero especial ', n.num)
    END AS description,
    CASE ib.productTypeKey
        WHEN 'BEBIDAS' THEN 2200.00 + n.num * 180
        WHEN 'SNACKS' THEN 1700.00 + n.num * 140
        ELSE 3200.00 + n.num * 260
    END AS priceAmount,
    CASE ib.productTypeKey
        WHEN 'BEBIDAS' THEN 0
        WHEN 'SNACKS' THEN 0
        ELSE 1
    END AS expiresFlag,
    CASE ib.productTypeKey
        WHEN 'COMIDAS' THEN 5
        ELSE NULL
    END AS shelfLifeDays
FROM tmp_inventory_businesses ib
JOIN tmp_numbers_three n;

INSERT INTO mk_products (name, expirationDate, expires, description, deleted, enabled, productTypeID, kioskID)
SELECT
    pc.productName,
    CASE WHEN pc.expiresFlag = 1 THEN DATE_ADD(@seed_now, INTERVAL pc.shelfLifeDays DAY) ELSE NULL END,
    CASE WHEN pc.expiresFlag = 1 THEN b'1' ELSE b'0' END,
    pc.description,
    b'0',
    b'1',
    pc.productTypeID,
    pc.kioskID
FROM tmp_product_catalog pc;

DROP TEMPORARY TABLE IF EXISTS tmp_product_ids;
CREATE TEMPORARY TABLE tmp_product_ids AS
SELECT
    pc.prod_seq,
    p.productID,
    pc.priceAmount,
    pc.localID,
    pc.kioskID,
    pc.tenantID,
    pc.productTypeKey
FROM mk_products p
JOIN tmp_product_catalog pc ON pc.productName = p.name;

INSERT INTO mk_productPrices (price, currentPrice, postTime, productID)
SELECT
    tp.priceAmount,
    b'1',
    @seed_now,
    tp.productID
FROM tmp_product_ids tp;

DROP TEMPORARY TABLE IF EXISTS tmp_product_price_ids;
CREATE TEMPORARY TABLE tmp_product_price_ids AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pp.productPriceID) AS seq,
    tp.prod_seq,
    tp.productID,
    pp.productPriceID,
    tp.priceAmount,
    tp.kioskID,
    tp.tenantID
FROM mk_productPrices pp
JOIN tmp_product_ids tp ON tp.productID = pp.productID;

DROP TEMPORARY TABLE IF EXISTS tmp_business_products;
CREATE TEMPORARY TABLE tmp_business_products AS
SELECT
    ROW_NUMBER() OVER (PARTITION BY tppi.tenantID ORDER BY tppi.productPriceID) - 1 AS product_idx,
    tppi.tenantID,
    tppi.productID,
    tppi.productPriceID,
    tppi.priceAmount,
    tppi.kioskID
FROM tmp_product_price_ids tppi;

-- Purchase generation (last 4 months, 50-70 purchases per month)
DROP TEMPORARY TABLE IF EXISTS tmp_month_offsets;
CREATE TEMPORARY TABLE tmp_month_offsets (month_index INT);
INSERT INTO tmp_month_offsets (month_index) VALUES (0),(1),(2),(3);

DROP TEMPORARY TABLE IF EXISTS tmp_months;
CREATE TEMPORARY TABLE tmp_months AS
SELECT
    mo.month_index,
    DATE_SUB(@seed_now, INTERVAL mo.month_index MONTH) AS anchor_date,
    DATE_SUB(DATE_SUB(@seed_now, INTERVAL mo.month_index MONTH), INTERVAL DAYOFMONTH(DATE_SUB(@seed_now, INTERVAL mo.month_index MONTH)) - 1 DAY) AS month_start,
    LAST_DAY(DATE_SUB(@seed_now, INTERVAL mo.month_index MONTH)) AS month_end,
    50 + FLOOR(RAND() * 21) AS purchaseCount
FROM tmp_month_offsets mo;

DROP TEMPORARY TABLE IF EXISTS tmp_digits;
CREATE TEMPORARY TABLE tmp_digits (n INT);
INSERT INTO tmp_digits (n) VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

DROP TEMPORARY TABLE IF EXISTS tmp_tens;
CREATE TEMPORARY TABLE tmp_tens (n INT);
INSERT INTO tmp_tens (n) VALUES (0),(1),(2),(3),(4),(5),(6);

DROP TEMPORARY TABLE IF EXISTS tmp_numbers_seventy;
CREATE TEMPORARY TABLE tmp_numbers_seventy AS
SELECT (ones.n + tens.n * 10) + 1 AS num
FROM tmp_digits ones
JOIN tmp_tens tens ON (ones.n + tens.n * 10) < 70;

DROP TEMPORARY TABLE IF EXISTS tmp_purchase_rows;
CREATE TEMPORARY TABLE tmp_purchase_rows AS
SELECT
    ROW_NUMBER() OVER (ORDER BY m.month_index, n.num) AS receipt_seq,
    m.month_index,
    n.num AS position_in_month
FROM tmp_months m
JOIN tmp_numbers_seventy n ON n.num <= m.purchaseCount
ORDER BY m.month_index, n.num;

DROP TEMPORARY TABLE IF EXISTS tmp_inventory_indexed;
CREATE TEMPORARY TABLE tmp_inventory_indexed AS
SELECT
    ROW_NUMBER() OVER (ORDER BY seq) - 1 AS idx,
    seq,
    tenantID,
    localID,
    productTypeID,
    productTypeKey,
    kioskID
FROM tmp_inventory_businesses
ORDER BY seq;

DROP TEMPORARY TABLE IF EXISTS tmp_purchase_assignments;
CREATE TEMPORARY TABLE tmp_purchase_assignments AS
SELECT
    pr.receipt_seq,
    pr.month_index,
    pr.position_in_month,
    m.month_start,
    m.month_end,
    ((pr.receipt_seq + pr.month_index) % 3) AS business_idx,
    pr.receipt_seq + 1000 AS receiptNumber
FROM tmp_purchase_rows pr
JOIN tmp_months m ON m.month_index = pr.month_index;

DROP TEMPORARY TABLE IF EXISTS tmp_client_ids_seed;
CREATE TEMPORARY TABLE tmp_client_ids_seed AS
SELECT ROW_NUMBER() OVER (ORDER BY clientID) AS seq, clientID
FROM mk_clients;

DROP TEMPORARY TABLE IF EXISTS tmp_receipt_seed;
CREATE TEMPORARY TABLE tmp_receipt_seed AS
SELECT
    pa.receipt_seq,
    pa.month_index,
    pa.position_in_month,
    pa.receiptNumber,
    inv.tenantID,
    inv.kioskID,
    bp.productPriceID,
    bp.productID,
    bp.priceAmount,
    ((pa.receipt_seq + pa.position_in_month) % 3) AS product_choice,
    ((pa.receipt_seq + bp.product_idx) % 5) + 1 AS quantity,
    DATE_ADD(pa.month_start, INTERVAL FLOOR(RAND() * (TIMESTAMPDIFF(MINUTE, pa.month_start, (CASE WHEN pa.month_index = 0 THEN @seed_now ELSE DATE_ADD(pa.month_end, INTERVAL 1 DAY) END)))) MINUTE) AS saleDateTime,
    ((pa.receipt_seq - 1) % @client_total) + 1 AS client_seq,
    CASE WHEN pa.receipt_seq % 2 = 0 THEN @payment_cash ELSE @payment_card END AS paymentID
FROM tmp_purchase_assignments pa
JOIN tmp_inventory_indexed inv ON inv.idx = pa.business_idx
JOIN tmp_business_products bp ON bp.tenantID = inv.tenantID AND bp.product_idx = ((pa.receipt_seq + pa.position_in_month) % 3)
ORDER BY pa.receipt_seq;

DROP TEMPORARY TABLE IF EXISTS tmp_receipt_discounts;
CREATE TEMPORARY TABLE tmp_receipt_discounts AS
SELECT
    receipt_seq,
    CASE WHEN receipt_seq % 12 = 0 THEN ROUND(priceAmount * quantity * 0.05, 2) ELSE 0 END AS discountAmount
FROM tmp_receipt_seed;

DROP TEMPORARY TABLE IF EXISTS tmp_receipt_financials;
CREATE TEMPORARY TABLE tmp_receipt_financials AS
SELECT
    rs.receipt_seq,
    rs.month_index,
    rs.position_in_month,
    rs.receiptNumber,
    rs.tenantID,
    rs.kioskID,
    rs.productPriceID,
    rs.productID,
    rs.priceAmount,
    rs.quantity,
    rs.saleDateTime,
    rs.paymentID,
    cli.clientID,
    ROUND(rs.priceAmount * rs.quantity, 2) AS grossSubTotal,
    disc.discountAmount,
    ROUND(ROUND(rs.priceAmount * rs.quantity, 2) - disc.discountAmount, 2) AS netSubTotal,
    ROUND((ROUND(rs.priceAmount * rs.quantity, 2) - disc.discountAmount) * 0.13, 2) AS taxAmount,
    ROUND((ROUND(rs.priceAmount * rs.quantity, 2) - disc.discountAmount) * 1.13, 2) AS totalAmount
FROM tmp_receipt_seed rs
JOIN tmp_client_ids_seed cli ON cli.seq = rs.client_seq
JOIN tmp_receipt_discounts disc ON disc.receipt_seq = rs.receipt_seq;

DROP TEMPORARY TABLE IF EXISTS tmp_receipt_discounts;

INSERT INTO mk_receipts (kioskID, clientID, paymentID, receiptNumber, discount, taxApplied, taxAmount, total, checksum, postTime)
SELECT
    rf.kioskID,
    rf.clientID,
    rf.paymentID,
    rf.receiptNumber,
    rf.discountAmount,
    b'1',
    rf.taxAmount,
    rf.totalAmount,
    UNHEX(SHA2(CONCAT(rf.receiptNumber, ':', rf.clientID, ':', rf.totalAmount), 256)),
    rf.saleDateTime
FROM tmp_receipt_financials rf
ORDER BY rf.receipt_seq;

DROP TEMPORARY TABLE IF EXISTS tmp_receipt_ids;
CREATE TEMPORARY TABLE tmp_receipt_ids AS
SELECT ROW_NUMBER() OVER (ORDER BY receiptID) AS seq, receiptID
FROM mk_receipts;

INSERT INTO mk_receiptDetails (receiptID, productPriceID, productAmount, subTotal, checksum)
SELECT
    rid.receiptID,
    rf.productPriceID,
    rf.quantity,
    rf.grossSubTotal,
    UNHEX(SHA2(CONCAT(rid.receiptID, ':', rf.productPriceID, ':', rf.quantity), 256))
FROM tmp_receipt_financials rf
JOIN tmp_receipt_ids rid ON rid.seq = rf.receipt_seq
ORDER BY rid.receiptID;

DROP TEMPORARY TABLE IF EXISTS tmp_product_sales;
CREATE TEMPORARY TABLE tmp_product_sales AS
SELECT productID, SUM(quantity) AS total_sold
FROM tmp_receipt_financials
GROUP BY productID;

INSERT INTO mk_inventory (productID, kioskID, localID, qty_on_hand, min_stock, updatedAt)
SELECT
    tpi.productID,
    tpi.kioskID,
    ib.localID,
    COALESCE(ps.total_sold, 0) + 40,
    15,
    @seed_now
FROM tmp_product_ids tpi
JOIN tmp_inventory_businesses ib ON ib.kioskID = tpi.kioskID
LEFT JOIN tmp_product_sales ps ON ps.productID = tpi.productID;

UPDATE mk_inventory inv
JOIN tmp_product_sales ps ON ps.productID = inv.productID
SET inv.qty_on_hand = inv.qty_on_hand - ps.total_sold,
    inv.updatedAt = @seed_now;

DROP TEMPORARY TABLE IF EXISTS tmp_user_for_transactions;
CREATE TEMPORARY TABLE tmp_user_for_transactions AS
SELECT ROW_NUMBER() OVER (ORDER BY userID) AS seq, userID
FROM mk_users;

SET @user_total := (SELECT COUNT(*) FROM tmp_user_for_transactions);
SET @transaction_sale := (SELECT transactionTypeID FROM mk_transactionTypes WHERE transactionType = 'SALE_PAYMENT');

INSERT INTO mk_transactions (amount, transactionDate, transactionDescription, checksum, referenceID, transactionStatus, transactionTypeID, userID)
SELECT
    rf.totalAmount,
    rf.saleDateTime,
    CONCAT('Sale receipt ', rf.receiptNumber),
    UNHEX(SHA2(CONCAT(rf.receiptNumber, ':', rf.totalAmount, ':', rf.saleDateTime), 256)),
    rid.receiptID,
    'COMPLETED',
    @transaction_sale,
    tuf.userID
FROM tmp_receipt_financials rf
JOIN tmp_receipt_ids rid ON rid.seq = rf.receipt_seq
JOIN tmp_user_for_transactions tuf ON tuf.seq = ((rf.receipt_seq - 1) % @user_total) + 1;

-- Provide a snapshot of seeded data
SELECT 'buildings' AS entity, COUNT(*) AS total FROM mk_building
UNION ALL SELECT 'locals', COUNT(*) FROM mk_locals
UNION ALL SELECT 'tenants', COUNT(*) FROM mk_tenant
UNION ALL SELECT 'contracts', COUNT(*) FROM mk_contracts
UNION ALL SELECT 'products', COUNT(*) FROM mk_products
UNION ALL SELECT 'inventory', COUNT(*) FROM mk_inventory
UNION ALL SELECT 'receipts', COUNT(*) FROM mk_receipts;






