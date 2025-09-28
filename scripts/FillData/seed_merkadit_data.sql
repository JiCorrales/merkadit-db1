-- seed_merkadit_data.sql
-- Resets and fills Merkadit database with sample data for registerSale testing.
-- WARNING: this script truncates existing data in the affected tables.

USE Merkadit;

SET @seed_now := NOW();

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE mk_transactions;
TRUNCATE TABLE mk_logs;
TRUNCATE TABLE mk_receiptDetails;
TRUNCATE TABLE mk_receipts;
TRUNCATE TABLE mk_payments;
TRUNCATE TABLE mk_inventory;
TRUNCATE TABLE mk_productPrices;
TRUNCATE TABLE mk_products;
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

INSERT INTO mk_addresses (address, zipCode, geoLocation, postTime, cityID)
VALUES ('Avenida Central 123', '10101', ST_GeomFromText('POINT(-84.0810 9.9333)', 4326), @seed_now, @city_sj);
SET @addr_market := LAST_INSERT_ID();

INSERT INTO mk_addresses (address, zipCode, geoLocation, postTime, cityID)
VALUES ('Boulevard Comercio 45', '10102', ST_GeomFromText('POINT(-84.0840 9.9400)', 4326), @seed_now, @city_sj);
SET @addr_building := LAST_INSERT_ID();

INSERT INTO mk_addresses (address, zipCode, geoLocation, postTime, cityID)
VALUES ('Ruta 1 Ofibodega 17', '20101', ST_GeomFromText('POINT(-84.2110 10.0200)', 4326), @seed_now, @city_escazu);
SET @addr_secondary := LAST_INSERT_ID();

INSERT INTO mk_contactInfoType (contactType) VALUES ('PHONE'), ('EMAIL');
SET @contact_phone := (SELECT contactInfoTypeID FROM mk_contactInfoType WHERE contactType = 'PHONE');
SET @contact_email := (SELECT contactInfoTypeID FROM mk_contactInfoType WHERE contactType = 'EMAIL');

INSERT INTO mk_marketContactInfo (contact, enabled, lastUpdated, contactInfoTypeID)
VALUES ('+506-2255-0101', b'1', @seed_now, @contact_phone);
SET @market_contact_phone := LAST_INSERT_ID();

INSERT INTO mk_marketContactInfo (contact, enabled, lastUpdated, contactInfoTypeID)
VALUES ('info@merkadit.test', b'1', @seed_now, @contact_email);
SET @market_contact_email := LAST_INSERT_ID();

INSERT INTO mk_markets (marketName, marketDescription, cedulaJuridica, type, size, enabled, deleted, lastUpdated, legalAddressID, marketContactInfoID)
VALUES ('Merkadit Central', 'Urban marketplace for local vendors', '301020304001', 'URBANO', 150, b'1', b'0', @seed_now, @addr_market, @market_contact_phone);
SET @market_main := LAST_INSERT_ID();

INSERT INTO mk_building (buildingName, addressID) VALUES ('Edificio Central', @addr_building);
SET @building_main := LAST_INSERT_ID();

INSERT INTO mk_markets_per_building (marketID, buildingID, deleted, postTime)
VALUES (@market_main, @building_main, b'0', @seed_now);

INSERT INTO mk_productType (productType, productFee) VALUES ('BEBIDAS', 0.08), ('SNACKS', 0.05), ('COMIDAS', 0.07);

INSERT INTO mk_kioskType (kioskType) VALUES ('ISLA'), ('CARRETA');
SET @kiosk_type_isla := (SELECT kioskTypeID FROM mk_kioskType WHERE kioskType = 'ISLA');
SET @kiosk_type_carreta := (SELECT kioskTypeID FROM mk_kioskType WHERE kioskType = 'CARRETA');

INSERT INTO mk_kioskStatus (statusName) VALUES ('ACTIVE'), ('MAINTENANCE');
SET @kiosk_status_active := (SELECT statusID FROM mk_kioskStatus WHERE statusName = 'ACTIVE');
SET @kiosk_status_maintenance := (SELECT statusID FROM mk_kioskStatus WHERE statusName = 'MAINTENANCE');

INSERT INTO mk_locals (buildingID, localCode, localName, area_m2)
VALUES
(@building_main, 'L-101', 'Local Central', 85.50),
(@building_main, 'L-102', 'Local Norte', 62.75);
SET @local_central := (SELECT localID FROM mk_locals WHERE localCode = 'L-101');
SET @local_norte := (SELECT localID FROM mk_locals WHERE localCode = 'L-102');

INSERT INTO mk_kiosks (kioskPrice, area_m2, kioskTypeID, statusID, localID, marketID)
VALUES
(450.00, 12.50, @kiosk_type_isla, @kiosk_status_active, @local_central, @market_main),
(325.00, 10.20, @kiosk_type_carreta, @kiosk_status_active, @local_norte, @market_main);
SET @kiosk_central := (SELECT kioskID FROM mk_kiosks WHERE localID = @local_central LIMIT 1);
SET @kiosk_norte := (SELECT kioskID FROM mk_kiosks WHERE localID = @local_norte LIMIT 1);

INSERT INTO mk_clientType (clientType) VALUES ('REGULAR'), ('CORPORATE');

INSERT INTO mk_roles (roleName, enabled) VALUES ('ADMIN', b'1'), ('CASHIER', b'1'), ('SUPPORT', b'1');

INSERT INTO mk_logTypes (logTypeName) VALUES ('BUSINESS');
INSERT INTO mk_logServices (logServiceName) VALUES ('POS');
INSERT INTO mk_logLevels (logLevelName) VALUES ('INFO'), ('ERROR');
INSERT INTO mk_transactionTypes (transactionType) VALUES ('SALE_PAYMENT'), ('REFUND');

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
LIMIT 10;

-- Temporary map of kiosks to human labels for product seeding
DROP TEMPORARY TABLE IF EXISTS tmp_kiosk_map;
CREATE TEMPORARY TABLE tmp_kiosk_map AS
SELECT
    k.kioskID,
    CASE
        WHEN k.kioskID = @kiosk_central THEN 'MAIN'
        ELSE 'SECONDARY'
    END AS kioskLabel,
    k.localID
FROM mk_kiosks k;

-- Product seed data
DROP TEMPORARY TABLE IF EXISTS tmp_product_seed;
CREATE TEMPORARY TABLE tmp_product_seed (
    productName VARCHAR(20),
    productType VARCHAR(20),
    kioskLabel VARCHAR(20),
    description VARCHAR(200),
    price DECIMAL(10,2),
    qty INT,
    minQty INT,
    expires TINYINT,
    shelfLifeDays INT
);

INSERT INTO tmp_product_seed (productName, productType, kioskLabel, description, price, qty, minQty, expires, shelfLifeDays)
VALUES
('CafeChorreado', 'BEBIDAS', 'MAIN', 'Cafe tostado molido 340g', 4500.00, 50, 10, 0, NULL),
('GalletaChoco', 'SNACKS', 'MAIN', 'Galleta con chispas de chocolate', 1200.00, 80, 15, 0, NULL),
('JugoNaranja', 'BEBIDAS', 'SECONDARY', 'Jugo natural de naranja 500ml', 1500.00, 60, 20, 1, 12),
('EmpanadaQueso', 'COMIDAS', 'SECONDARY', 'Empanada rellena de queso', 900.00, 40, 12, 1, 3),
('TeFrutas', 'BEBIDAS', 'SECONDARY', 'Te frio de frutas tropicales', 1300.00, 45, 10, 1, 30);

INSERT INTO mk_products (name, expirationDate, expires, description, deleted, enabled, productTypeID, kioskID)
SELECT
    ps.productName,
    CASE WHEN ps.expires = 1 THEN DATE_ADD(@seed_now, INTERVAL ps.shelfLifeDays DAY) ELSE NULL END,
    CASE WHEN ps.expires = 1 THEN b'1' ELSE b'0' END,
    ps.description,
    b'0',
    b'1',
    pt.productTypeID,
    km.kioskID
FROM tmp_product_seed ps
JOIN mk_productType pt ON pt.productType = ps.productType
JOIN tmp_kiosk_map km ON km.kioskLabel = ps.kioskLabel;

DROP TEMPORARY TABLE IF EXISTS tmp_product_ids;
CREATE TEMPORARY TABLE tmp_product_ids AS
SELECT
    p.productID,
    p.name,
    ps.price,
    ps.qty,
    ps.minQty,
    km.localID,
    p.kioskID
FROM mk_products p
JOIN tmp_product_seed ps ON ps.productName = p.name
JOIN tmp_kiosk_map km ON km.kioskID = p.kioskID;

INSERT INTO mk_productPrices (price, currentPrice, postTime, productID)
SELECT
    tp.price,
    b'1',
    @seed_now,
    tp.productID
FROM tmp_product_ids tp;

INSERT INTO mk_inventory (productID, kioskID, localID, qty_on_hand, min_stock, updatedAt)
SELECT
    tp.productID,
    tp.kioskID,
    tp.localID,
    tp.qty,
    tp.minQty,
    @seed_now
FROM tmp_product_ids tp;

-- Optional seed payments for regression tests
INSERT INTO mk_payments (paymentMethodName, paymentConfirmation)
VALUES
('EFECTIVO', 'CASH-INIT-001'),
('TARJETA', 'CARD-INIT-002');

-- Provide a quick snapshot of seeded data
SELECT 'users' AS entity, COUNT(*) AS total FROM mk_users
UNION ALL
SELECT 'clients', COUNT(*) FROM mk_clients
UNION ALL
SELECT 'products', COUNT(*) FROM mk_products
UNION ALL
SELECT 'inventory', COUNT(*) FROM mk_inventory;
