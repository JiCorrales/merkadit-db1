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
TRUNCATE TABLE mk_kiosksPerFloors;
TRUNCATE TABLE mk_floors;
TRUNCATE TABLE mk_kiosks;
TRUNCATE TABLE mk_kioskStatus;
TRUNCATE TABLE mk_kioskType;
TRUNCATE TABLE mk_marketsPerBuilding;
TRUNCATE TABLE mk_marketContactInfo;
TRUNCATE TABLE mk_building;
TRUNCATE TABLE mk_markets;
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
TRUNCATE TABLE mk_permissions;
TRUNCATE TABLE permissionsPerRole;
TRUNCATE TABLE permissionsPerUser;
TRUNCATE TABLE mk_logLevels;
TRUNCATE TABLE mk_logServices;
TRUNCATE TABLE mk_logTypes;
TRUNCATE TABLE mk_transactionTypes;
SET FOREIGN_KEY_CHECKS = 1;

-- Geographic base data
INSERT INTO mk_countries (countryName) VALUES ('Costa Rica');
SET @country_cr := LAST_INSERT_ID();

INSERT INTO mk_states (stateName, countryID)
VALUES ('San Jose', @country_cr), ('Alajuela', @country_cr), ('Heredia', @country_cr);

SET @state_sj := (SELECT stateID FROM mk_states WHERE stateName = 'San Jose' LIMIT 1);
SET @state_al := (SELECT stateID FROM mk_states WHERE stateName = 'Alajuela' LIMIT 1);
SET @state_he := (SELECT stateID FROM mk_states WHERE stateName = 'Heredia' LIMIT 1);

INSERT INTO mk_cities (cityName, stateID)
VALUES 
('San Jose', @state_sj), 
('Escazu', @state_sj), 
('Alajuela', @state_al),
('Heredia', @state_he),
('Santa Ana', @state_sj);

SET @city_sanjose := (SELECT cityID FROM mk_cities WHERE cityName = 'San Jose' LIMIT 1);
SET @city_escazu := (SELECT cityID FROM mk_cities WHERE cityName = 'Escazu' LIMIT 1);
SET @city_alajuela := (SELECT cityID FROM mk_cities WHERE cityName = 'Alajuela' LIMIT 1);
SET @city_heredia := (SELECT cityID FROM mk_cities WHERE cityName = 'Heredia' LIMIT 1);
SET @city_santa_ana := (SELECT cityID FROM mk_cities WHERE cityName = 'Santa Ana' LIMIT 1);

-- Addresses for markets and buildings
INSERT INTO mk_addresses (address, zipCode, geoLocation, postTime, cityID)
VALUES
('Oficinas Merkadit Central, Paseo Colon 58', '10105', ST_GeomFromText('POINT(-84.0892 9.9348)', 4326), @seed_now, @city_sanjose);
SET @addr_market_central := LAST_INSERT_ID();

INSERT INTO mk_addresses (address, zipCode, geoLocation, postTime, cityID)
VALUES
('Oficinas Merkadit Plaza, Calle Laureles 14', '10202', ST_GeomFromText('POINT(-84.1098 9.9367)', 4326), @seed_now, @city_escazu);
SET @addr_market_plaza := LAST_INSERT_ID();

INSERT INTO mk_addresses (address, zipCode, geoLocation, postTime, cityID)
VALUES
('Galeria Calderon, Avenida Central 123', '10101', ST_GeomFromText('POINT(-84.0815 9.9338)', 4326), @seed_now, @city_sanjose);
SET @addr_building_central := LAST_INSERT_ID();

INSERT INTO mk_addresses (address, zipCode, geoLocation, postTime, cityID)
VALUES
('Mercado Aurora, Calle 45 220', '10201', ST_GeomFromText('POINT(-84.0990 9.9355)', 4326), @seed_now, @city_escazu);
SET @addr_building_plaza := LAST_INSERT_ID();

INSERT INTO mk_addresses (address, zipCode, geoLocation, postTime, cityID)
VALUES
('Plaza Heredia, Avenida Central 350', '40101', ST_GeomFromText('POINT(-84.1165 9.9985)', 4326), @seed_now, @city_heredia);
SET @addr_building_heredia := LAST_INSERT_ID();

INSERT INTO mk_contactInfoType (contactType) VALUES ('PHONE'), ('EMAIL'), ('WHATSAPP');
SET @contact_phone := (SELECT contactInfoTypeID FROM mk_contactInfoType WHERE contactType = 'PHONE');
SET @contact_email := (SELECT contactInfoTypeID FROM mk_contactInfoType WHERE contactType = 'EMAIL');
SET @contact_whatsapp := (SELECT contactInfoTypeID FROM mk_contactInfoType WHERE contactType = 'WHATSAPP');

-- Markets, buildings, floors, kiosks
INSERT INTO mk_markets (marketName, marketDescription, cedulaJuridica, type, size, enabled, deleted, lastUpdated, legalAddressID)
VALUES
('Merkadit Central', 'Mercado urbano con enfoque en experiencias gastronomicas y productos frescos.', '301020304001', 'URBANO', 220, b'1', b'0', @seed_now, @addr_market_central),
('Merkadit Plaza', 'Plaza comercial con propuestas boutique y artesanales.', '301020304002', 'URBANO', 185, b'1', b'0', @seed_now, @addr_market_plaza),
('Merkadit Heredia', 'Mercado regional con productos locales y artesanias.', '301020304003', 'URBANO', 150, b'1', b'0', @seed_now, @addr_market_plaza);

SET @market_central := (SELECT marketID FROM mk_markets WHERE marketName = 'Merkadit Central' LIMIT 1);
SET @market_plaza := (SELECT marketID FROM mk_markets WHERE marketName = 'Merkadit Plaza' LIMIT 1);
SET @market_heredia := (SELECT marketID FROM mk_markets WHERE marketName = 'Merkadit Heredia' LIMIT 1);

INSERT INTO mk_marketContactInfo (contact, enabled, lastUpdated, contactInfoTypeID, marketID)
VALUES
('+506 2255-0101', b'1', @seed_now, @contact_phone, @market_central),
('info@merkaditcentral.cr', b'1', @seed_now, @contact_email, @market_central),
('+506 2289-4411', b'1', @seed_now, @contact_phone, @market_plaza),
('hola@merkaditplaza.cr', b'1', @seed_now, @contact_email, @market_plaza),
('+506 2260-3322', b'1', @seed_now, @contact_phone, @market_heredia),
('contacto@merkaditheredia.cr', b'1', @seed_now, @contact_email, @market_heredia);

INSERT INTO mk_building (buildingName, addressID)
VALUES 
('Galeria Calderon', @addr_building_central), 
('Mercado Aurora', @addr_building_plaza),
('Plaza Heredia', @addr_building_heredia);

SET @building_central := (SELECT buildingID FROM mk_building WHERE buildingName = 'Galeria Calderon' LIMIT 1);
SET @building_plaza := (SELECT buildingID FROM mk_building WHERE buildingName = 'Mercado Aurora' LIMIT 1);
SET @building_heredia := (SELECT buildingID FROM mk_building WHERE buildingName = 'Plaza Heredia' LIMIT 1);

INSERT INTO mk_marketsPerBuilding (marketID, buildingID, deleted, postTime)
VALUES
(@market_central, @building_central, b'0', @seed_now),
(@market_plaza, @building_plaza, b'0', @seed_now),
(@market_heredia, @building_heredia, b'0', @seed_now);

INSERT INTO mk_floors (buildingID, floorName)
VALUES
(@building_central, 'Nivel Plaza'),
(@building_plaza, 'Nivel Calle'),
(@building_plaza, 'Terraza Verde'),
(@building_heredia, 'Planta Baja'),
(@building_heredia, 'Primer Piso');

SET @floor_central := (SELECT floorID FROM mk_floors WHERE buildingID = @building_central LIMIT 1);
SET @floor_plaza_calle := (SELECT floorID FROM mk_floors WHERE buildingID = @building_plaza AND floorName = 'Nivel Calle' LIMIT 1);
SET @floor_plaza_terraza := (SELECT floorID FROM mk_floors WHERE buildingID = @building_plaza AND floorName = 'Terraza Verde' LIMIT 1);
SET @floor_heredia_baja := (SELECT floorID FROM mk_floors WHERE buildingID = @building_heredia AND floorName = 'Planta Baja' LIMIT 1);
SET @floor_heredia_primer := (SELECT floorID FROM mk_floors WHERE buildingID = @building_heredia AND floorName = 'Primer Piso' LIMIT 1);

INSERT INTO mk_kioskType (kioskType) VALUES ('LOCAL'), ('ISLA'), ('FOOD_STALL'), ('BOUTIQUE');
SET @kio_type_local := (SELECT kioskTypeID FROM mk_kioskType WHERE kioskType = 'LOCAL' LIMIT 1);
SET @kio_type_food := (SELECT kioskTypeID FROM mk_kioskType WHERE kioskType = 'FOOD_STALL' LIMIT 1);
SET @kio_type_boutique := (SELECT kioskTypeID FROM mk_kioskType WHERE kioskType = 'BOUTIQUE' LIMIT 1);

INSERT INTO mk_kioskStatus (statusName) VALUES ('OCCUPIED'), ('AVAILABLE'), ('MAINTENANCE');
SET @status_occ := (SELECT statusID FROM mk_kioskStatus WHERE statusName = 'OCCUPIED' LIMIT 1);

INSERT INTO mk_kiosks (kioskName, kioskPrice, area_m2, kioskTypeID, statusID, marketID)
VALUES
('Kiosco Calderon Plaza', 680.00, 48.50, @kio_type_local, @status_occ, @market_central),
('Kiosco Aurora Calle', 520.00, 40.10, @kio_type_local, @status_occ, @market_plaza),
('Kiosco Aurora Terraza', 545.00, 36.40, @kio_type_food, @status_occ, @market_plaza),
('Kiosco Heredia Local', 480.00, 32.20, @kio_type_local, @status_occ, @market_heredia),
('Kiosco Heredia Boutique', 620.00, 28.80, @kio_type_boutique, @status_occ, @market_heredia);

SET @kiosk_central := (SELECT kioskID FROM mk_kiosks WHERE kioskName = 'Kiosco Calderon Plaza' LIMIT 1);
SET @kiosk_plaza_calle := (SELECT kioskID FROM mk_kiosks WHERE kioskName = 'Kiosco Aurora Calle' LIMIT 1);
SET @kiosk_plaza_terraza := (SELECT kioskID FROM mk_kiosks WHERE kioskName = 'Kiosco Aurora Terraza' LIMIT 1);
SET @kiosk_heredia_local := (SELECT kioskID FROM mk_kiosks WHERE kioskName = 'Kiosco Heredia Local' LIMIT 1);
SET @kiosk_heredia_boutique := (SELECT kioskID FROM mk_kiosks WHERE kioskName = 'Kiosco Heredia Boutique' LIMIT 1);

INSERT INTO mk_kiosksPerFloors (kioskID, floorID, deleted, postTime)
VALUES
(@kiosk_central, @floor_central, b'0', @seed_now),
(@kiosk_plaza_calle, @floor_plaza_calle, b'0', @seed_now),
(@kiosk_plaza_terraza, @floor_plaza_terraza, b'0', @seed_now),
(@kiosk_heredia_local, @floor_heredia_baja, b'0', @seed_now),
(@kiosk_heredia_boutique, @floor_heredia_primer, b'0', @seed_now);

-- Operational master data
INSERT INTO mk_productType (productType, productFee)
VALUES
('COFFEE', 0.05),
('BAKERY', 0.06),
('ORGANIC', 0.07),
('ARTISANAL', 0.05),
('GOURMET', 0.08),
('FASHION', 0.04),
('TECH_GADGETS', 0.06),
('HOME_DECOR', 0.05),
('HEALTH', 0.03),
('BOOKS', 0.02);

INSERT INTO mk_roles (roleName, enabled) VALUES ('ADMIN', b'1'), ('CASHIER', b'1'), ('SUPPORT', b'1'), ('MANAGER', b'1');
INSERT INTO mk_permissions (permissionName, code, enabled)
VALUES 
('View Sales', 'S001', b'1'), 
('Manage Inventory', 'S002', b'1'), 
('Tenant Contracts', 'S003', b'1'),
('Financial Reports', 'S004', b'1'),
('User Management', 'S005', b'1');

INSERT INTO permissionsPerRole (permissionID, roleID, enabled, postTime)
SELECT p.permissionID, r.roleID, b'1', @seed_now
FROM mk_permissions p
JOIN mk_roles r ON (
    (p.code = 'S001' AND r.roleName IN ('ADMIN','CASHIER','SUPPORT','MANAGER')) OR
    (p.code = 'S002' AND r.roleName IN ('ADMIN','CASHIER','MANAGER')) OR
    (p.code = 'S003' AND r.roleName IN ('ADMIN','MANAGER')) OR
    (p.code = 'S004' AND r.roleName IN ('ADMIN','MANAGER')) OR
    (p.code = 'S005' AND r.roleName = 'ADMIN')
);

INSERT INTO mk_logTypes (logTypeName) VALUES ('BUSINESS'), ('SETTLEMENT_ERROR'), ('SETTLEMENT_WARNING'), ('SETTLEMENT_SUCCESS'), ('SECURITY');
INSERT INTO mk_logServices (logServiceName) VALUES ('POS'), ('FINANCIAL'), ('INVENTORY'), ('AUTH');
INSERT INTO mk_logLevels (logLevelName) VALUES ('INFO'), ('ERROR'), ('WARNING'), ('DEBUG');
INSERT INTO mk_transactionTypes (transactionType) VALUES ('SALE_PAYMENT'), ('REFUND'), ('INVENTORY_ADJUSTMENT'), ('RENT_CHARGE'), ('FEE_COLLECTION');

INSERT INTO mk_clientType (clientType) VALUES ('REGULAR'), ('CORPORATE'), ('WHOLESALE'), ('VIP');

-- Users
INSERT INTO mk_users (name, lastName, password, enabled, createdAt)
VALUES
('Ana', 'Romero', UNHEX(SHA2('Ana:Romero#mk', 256)), b'1', DATE_SUB(@seed_now, INTERVAL 250 DAY)),
('Luis', 'Mendez', UNHEX(SHA2('Luis:Mendez#mk', 256)), b'1', DATE_SUB(@seed_now, INTERVAL 210 DAY)),
('Maria', 'Castro', UNHEX(SHA2('Maria:Castro#mk', 256)), b'1', DATE_SUB(@seed_now, INTERVAL 180 DAY)),
('Carlos', 'Flores', UNHEX(SHA2('Carlos:Flores#mk', 256)), b'1', DATE_SUB(@seed_now, INTERVAL 140 DAY)),
('Sofia', 'Salas', UNHEX(SHA2('Sofia:Salas#mk', 256)), b'1', DATE_SUB(@seed_now, INTERVAL 90 DAY)),
('Diego', 'Vega', UNHEX(SHA2('Diego:Vega#mk', 256)), b'1', DATE_SUB(@seed_now, INTERVAL 45 DAY)),
('Elena', 'Rojas', UNHEX(SHA2('Elena:Rojas#mk', 256)), b'1', DATE_SUB(@seed_now, INTERVAL 30 DAY)),
('Javier', 'Campos', UNHEX(SHA2('Javier:Campos#mk', 256)), b'1', DATE_SUB(@seed_now, INTERVAL 15 DAY));

SET @role_admin := (SELECT roleID FROM mk_roles WHERE roleName = 'ADMIN');
SET @role_cashier := (SELECT roleID FROM mk_roles WHERE roleName = 'CASHIER');
SET @role_support := (SELECT roleID FROM mk_roles WHERE roleName = 'SUPPORT');
SET @role_manager := (SELECT roleID FROM mk_roles WHERE roleName = 'MANAGER');

INSERT INTO mk_userRoles (roleID, userID, enabled, postTime)
SELECT @role_admin, userID, b'1', @seed_now FROM mk_users WHERE name = 'Ana';

INSERT INTO mk_userRoles (roleID, userID, enabled, postTime)
SELECT @role_manager, userID, b'1', @seed_now FROM mk_users WHERE name = 'Luis';

INSERT INTO mk_userRoles (roleID, userID, enabled, postTime)
SELECT @role_cashier, userID, b'1', @seed_now FROM mk_users WHERE name IN ('Maria','Carlos','Sofia');

INSERT INTO mk_userRoles (roleID, userID, enabled, postTime)
SELECT @role_support, userID, b'1', @seed_now FROM mk_users WHERE name IN ('Diego','Elena','Javier');

-- Clients
INSERT INTO mk_clients (clientCode, clientName, clientTypeID)
SELECT CONCAT('CLI-', LPAD(ROW_NUMBER() OVER (ORDER BY seq.n),4,'0')), CONCAT(firstName,' ',lastName),
       CASE 
            WHEN seq.n % 12 = 0 THEN (SELECT clientTypeID FROM mk_clientType WHERE clientType = 'CORPORATE' LIMIT 1)
            WHEN seq.n % 8 = 0 THEN (SELECT clientTypeID FROM mk_clientType WHERE clientType = 'WHOLESALE' LIMIT 1)
            WHEN seq.n % 15 = 0 THEN (SELECT clientTypeID FROM mk_clientType WHERE clientType = 'VIP' LIMIT 1)
            ELSE (SELECT clientTypeID FROM mk_clientType WHERE clientType = 'REGULAR' LIMIT 1) 
       END
FROM (
    SELECT 1 AS n, 'Laura' AS firstName, 'Lopez' AS lastName UNION ALL
    SELECT 2, 'Mateo', 'Gonzalez' UNION ALL
    SELECT 3, 'Isabel', 'Solano' UNION ALL
    SELECT 4, 'Ricardo', 'Aguilar' UNION ALL
    SELECT 5, 'Daniela', 'Rodriguez' UNION ALL
    SELECT 6, 'Pedro', 'Pineda' UNION ALL
    SELECT 7, 'Camila', 'Soto' UNION ALL
    SELECT 8, 'Andres', 'Zamora' UNION ALL
    SELECT 9, 'Valeria', 'Jimenez' UNION ALL
    SELECT 10, 'Ernesto', 'Calderon' UNION ALL
    SELECT 11, 'Paula', 'Murillo' UNION ALL
    SELECT 12, 'Sebastian', 'Mora' UNION ALL
    SELECT 13, 'Jimena', 'Barboza' UNION ALL
    SELECT 14, 'Adrian', 'Vargas' UNION ALL
    SELECT 15, 'Lorena', 'Araya' UNION ALL
    SELECT 16, 'Gabriel', 'Campos' UNION ALL
    SELECT 17, 'Monica', 'Solis' UNION ALL
    SELECT 18, 'Felipe', 'Rojas' UNION ALL
    SELECT 19, 'Julieta', 'Paz' UNION ALL
    SELECT 20, 'Rafael', 'Cordero' UNION ALL
    SELECT 21, 'Carmen', 'Villalobos' UNION ALL
    SELECT 22, 'Roberto', 'Mora' UNION ALL
    SELECT 23, 'Patricia', 'Chaves' UNION ALL
    SELECT 24, 'Hector', 'Sanchez' UNION ALL
    SELECT 25, 'Lucia', 'Fernandez' UNION ALL
    SELECT 26, 'Oscar', 'Ramirez' UNION ALL
    SELECT 27, 'Teresa', 'Hernandez' UNION ALL
    SELECT 28, 'Alberto', 'Diaz' UNION ALL
    SELECT 29, 'Silvia', 'Morales' UNION ALL
    SELECT 30, 'Fernando', 'Gutierrez'
) AS seq;

-- Payment methods
INSERT INTO mk_payments (paymentMethodName, paymentConfirmation)
VALUES 
('EFECTIVO', 'CASH-INIT-001'), 
('TARJETA', 'CARD-INIT-002'), 
('SINPE MOVIL', 'SINPE-INIT-003'),
('TRANSFERENCIA', 'TRANSF-INIT-004');

-- Helper sequences
DROP TEMPORARY TABLE IF EXISTS tmp_numbers_small;
CREATE TEMPORARY TABLE tmp_numbers_small (num INT PRIMARY KEY);
INSERT INTO tmp_numbers_small (num) VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10);

DROP TEMPORARY TABLE IF EXISTS tmp_numbers_large;
CREATE TEMPORARY TABLE tmp_numbers_large (num INT PRIMARY KEY);
INSERT INTO tmp_numbers_large (num)
SELECT hundreds.h * 100 + tens.t * 10 + ones.o
FROM (SELECT 0 AS h UNION ALL SELECT 1 UNION ALL SELECT 2) AS hundreds
CROSS JOIN (
    SELECT 0 AS t UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
) AS tens
CROSS JOIN (
    SELECT 0 AS o UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
) AS ones
WHERE hundreds.h * 100 + tens.t * 10 + ones.o BETWEEN 1 AND 250
ORDER BY 1;

-- Store spaces and businesses
DROP TEMPORARY TABLE IF EXISTS tmp_store_spaces;
CREATE TEMPORARY TABLE tmp_store_spaces (
    store_seq INT PRIMARY KEY,
    kioskID INT,
    buildingID INT,
    floorID INT,
    storeCode VARCHAR(10),
    storeLabel VARCHAR(80),
    cityID INT,
    zipCode VARCHAR(8),
    baseRent DECIMAL(10,2),
    area DECIMAL(10,2),
    tenantCount INT
);

INSERT INTO tmp_store_spaces (store_seq, kioskID, buildingID, floorID, storeCode, storeLabel, cityID, zipCode, baseRent, area, tenantCount)
VALUES
(1, @kiosk_central, @building_central, @floor_central, 'LC-101', 'Galeria Calderon - Pasillo Central', @city_sanjose, '10109', 680.00, 48.50, 6),
(2, @kiosk_plaza_calle, @building_plaza, @floor_plaza_calle, 'LP-201', 'Mercado Aurora - Nivel Calle', @city_escazu, '10203', 520.00, 40.10, 8),
(3, @kiosk_plaza_terraza, @building_plaza, @floor_plaza_terraza, 'LP-202', 'Mercado Aurora - Terraza Verde', @city_escazu, '10203', 540.00, 36.40, 5),
(4, @kiosk_heredia_local, @building_heredia, @floor_heredia_baja, 'LH-301', 'Plaza Heredia - Planta Baja', @city_heredia, '40101', 480.00, 32.20, 4),
(5, @kiosk_heredia_boutique, @building_heredia, @floor_heredia_primer, 'LH-302', 'Plaza Heredia - Primer Piso', @city_heredia, '40101', 620.00, 28.80, 3);

DROP TEMPORARY TABLE IF EXISTS tmp_business_seed;
CREATE TEMPORARY TABLE tmp_business_seed (
    tenant_seq INT PRIMARY KEY,
    store_seq INT,
    businessLabel VARCHAR(80),
    legalSuffix VARCHAR(20),
    productTypeKey VARCHAR(20),
    businessType VARCHAR(40),
    emailDomain VARCHAR(60),
    phonePrefix VARCHAR(4),
    baseZip VARCHAR(8),
    geoLon DECIMAL(10,6),
    geoLat DECIMAL(10,6)
);

INSERT INTO tmp_business_seed (tenant_seq, store_seq, businessLabel, legalSuffix, productTypeKey, businessType, emailDomain, phonePrefix, baseZip, geoLon, geoLat)
VALUES
-- Kiosk 1 - Central
(1, 1, 'Cafe Siete Esquinas', 'S.R.L.', 'COFFEE', 'Food & Beverage', 'cafesesquinas.cr', '2247', '10111', -84.083900, 9.933900),
(2, 1, 'Panaderia Bruma', 'Limitada', 'BAKERY', 'Food & Beverage', 'panaderiabruma.cr', '2239', '10112', -84.086200, 9.932800),
(3, 1, 'Cosecha Criolla', 'S.A.', 'ORGANIC', 'Grocery', 'cosechacriolla.cr', '2284', '10113', -84.082900, 9.934300),
(4, 1, 'Joyas del Barrio', 'Limitada', 'FASHION', 'Retail', 'joyasbarrio.cr', '2270', '10114', -84.085500, 9.934600),
(5, 1, 'TecnoRincon', 'S.R.L.', 'TECH_GADGETS', 'Retail', 'tecnorincon.cr', '2280', '10115', -84.084700, 9.935000),
(6, 1, 'Salud Natural', 'S.A.', 'HEALTH', 'Health & Wellness', 'saludnatural.cr', '2292', '10116', -84.083200, 9.935500),

-- Kiosk 2 - Plaza Calle
(7, 2, 'Sabores del Mercado', 'S.A.', 'GOURMET', 'Food & Beverage', 'saboresmercado.cr', '2290', '10205', -84.105500, 9.936800),
(8, 2, 'Taller Ceramico Luna', 'Artesanos', 'ARTISANAL', 'Handcrafted Goods', 'ceramicoluna.cr', '2265', '10206', -84.105900, 9.937200),
(9, 2, 'Nido Verde Plantas', 'S.A.', 'HOME_DECOR', 'Retail', 'nidoverde.cr', '2275', '10207', -84.106200, 9.936500),
(10, 2, 'Verde que Te Quiero Verde', 'Limitada', 'ORGANIC', 'Grocery', 'verdequerido.cr', '2282', '10208', -84.108800, 9.935900),
(11, 2, 'Cafe Matutino', 'S.A.', 'COFFEE', 'Food & Beverage', 'cafematutino.cr', '2285', '10209', -84.109200, 9.936300),
(12, 2, 'Pixel Craft', 'S.R.L.', 'TECH_GADGETS', 'Retail', 'pixelcraft.cr', '2295', '10210', -84.109500, 9.937000),
(13, 2, 'Casa Luz Decor', 'S.A.', 'HOME_DECOR', 'Retail', 'casaluz.cr', '2276', '10211', -84.107900, 9.936600),
(14, 2, 'Libros y Mas', 'S.R.L.', 'BOOKS', 'Retail', 'librosymas.cr', '2298', '10212', -84.108200, 9.937100),

-- Kiosk 3 - Plaza Terraza
(15, 3, 'Pan y Miel', 'S.A.', 'BAKERY', 'Food & Beverage', 'panymiel.cr', '2230', '10212', -84.107100, 9.937400),
(16, 3, 'Sabores del Valle', 'S.A.', 'GOURMET', 'Food & Beverage', 'saboresvalle.cr', '2291', '10213', -84.108000, 9.936800),
(17, 3, 'Casa Achiote', 'Limitada', 'ARTISANAL', 'Handcrafted Goods', 'casaachiote.cr', '2263', '10214', -84.108500, 9.936400),
(18, 3, 'Luna Clara Hogar', 'S.R.L.', 'HOME_DECOR', 'Retail', 'lunaclara.cr', '2277', '10215', -84.108900, 9.935900),
(19, 3, 'Bebidas Tropicales', 'S.A.', 'COFFEE', 'Food & Beverage', 'bebidastropicales.cr', '2288', '10216', -84.107500, 9.936200),

-- Kiosk 4 - Heredia Local (continuación)
(20, 4, 'Dulces Heredianos', 'S.R.L.', 'GOURMET', 'Food & Beverage', 'dulcesheredi.cr', '2260', '40102', -84.116200, 9.998800),
(21, 4, 'Artesania Local', 'Artesanos', 'ARTISANAL', 'Handcrafted Goods', 'artesanialocal.cr', '2262', '40103', -84.116500, 9.999100),
(22, 4, 'Cafe de Altura', 'S.A.', 'COFFEE', 'Food & Beverage', 'cafedealtura.cr', '2268', '40104', -84.116800, 9.998500),
(23, 4, 'Productos Frescos', 'Limitada', 'ORGANIC', 'Grocery', 'productosfrescos.cr', '2272', '40105', -84.117100, 9.998200),

-- Kiosk 5 - Heredia Boutique
(24, 5, 'Boutique Elegante', 'S.A.', 'FASHION', 'Retail', 'boutiqueelegante.cr', '2289', '40106', -84.115800, 9.999300),
(25, 5, 'Tecnologia Avanzada', 'S.R.L.', 'TECH_GADGETS', 'Retail', 'tecnologiaavanzada.cr', '2293', '40107', -84.115500, 9.999500),
(26, 5, 'Decoracion Sofisticada', 'S.A.', 'HOME_DECOR', 'Retail', 'decoracionsofisticada.cr', '2279', '40108', -84.115200, 9.999700);

-- Tenant addresses and basics
DROP TEMPORARY TABLE IF EXISTS tmp_tenant_addresses;
CREATE TEMPORARY TABLE tmp_tenant_addresses AS
SELECT
    bs.tenant_seq,
    bs.businessLabel AS tenantDisplayName,
    CONCAT(bs.businessLabel, ' ', bs.legalSuffix) AS legalName,
    302010000 + bs.tenant_seq AS legalID,
    402510000 + bs.tenant_seq AS taxID,
    ss.store_seq,
    ss.kioskID,
    ss.buildingID,
    ss.floorID,
    ss.storeCode,
    ss.storeLabel,
    ss.cityID,
    CONCAT(ss.storeLabel, ', Puesto ', LPAD((ROW_NUMBER() OVER (PARTITION BY bs.store_seq ORDER BY bs.tenant_seq)), 2, '0')) AS addressLine,
    bs.baseZip,
    bs.geoLon,
    bs.geoLat,
    bs.productTypeKey,
    bs.businessType,
    bs.emailDomain,
    bs.phonePrefix
FROM tmp_business_seed bs
JOIN tmp_store_spaces ss ON ss.store_seq = bs.store_seq;

INSERT INTO mk_addresses (address, zipCode, geoLocation, postTime, cityID)
SELECT addressLine, baseZip, ST_SRID(POINT(geoLon, geoLat), 4326), @seed_now, cityID
FROM tmp_tenant_addresses;

DROP TEMPORARY TABLE IF EXISTS tmp_tenant_directory;
CREATE TEMPORARY TABLE tmp_tenant_directory AS
SELECT
    taddr.tenant_seq,
    taddr.tenantDisplayName,
    addr.addressID,
    taddr.legalID,
    taddr.legalName,
    taddr.taxID,
    taddr.businessType,
    taddr.productTypeKey,
    taddr.emailDomain,
    taddr.phonePrefix,
    taddr.kioskID,
    taddr.store_seq,
    taddr.storeCode,
    taddr.storeLabel
FROM tmp_tenant_addresses taddr
JOIN mk_addresses addr ON addr.address = taddr.addressLine;

INSERT INTO mk_tenant (tenantName, tenantLegalAddressID, tenantLegalID, tenantLegalName, taxID, businessType)
SELECT tenantDisplayName, addressID, legalID, legalName, taxID, businessType
FROM tmp_tenant_directory
ORDER BY tenant_seq;

DROP TEMPORARY TABLE IF EXISTS tmp_tenant_ids;
CREATE TEMPORARY TABLE tmp_tenant_ids AS
SELECT ROW_NUMBER() OVER (ORDER BY tenantID) AS tenant_seq, tenantID
FROM mk_tenant;

INSERT INTO mk_tenantContactInfo (contact, enabled, lastUpdated, contactInfoTypeID, tenantID)
SELECT CONCAT('+506 ', td.phonePrefix, '-', LPAD(1800 + td.tenant_seq, 4, '0')), b'1', @seed_now, @contact_phone, ti.tenantID
FROM tmp_tenant_directory td
JOIN tmp_tenant_ids ti ON ti.tenant_seq = td.tenant_seq;

INSERT INTO mk_tenantContactInfo (contact, enabled, lastUpdated, contactInfoTypeID, tenantID)
SELECT CONCAT(LOWER(REPLACE(td.tenantDisplayName, ' ', '')), '@', td.emailDomain), b'1', @seed_now, @contact_email, ti.tenantID
FROM tmp_tenant_directory td
JOIN tmp_tenant_ids ti ON ti.tenant_seq = td.tenant_seq;

-- Contracts linking tenants to kiosks
DROP TEMPORARY TABLE IF EXISTS tmp_contract_seed;
CREATE TEMPORARY TABLE tmp_contract_seed AS
SELECT
    td.tenant_seq,
    ti.tenantID,
    td.kioskID,
    pt.productTypeID,
    DATE_SUB(@seed_now, INTERVAL (60 + td.tenant_seq * 3) DAY) AS startDate,
    DATE_ADD(DATE_SUB(@seed_now, INTERVAL (60 + td.tenant_seq * 3) DAY), INTERVAL 18 MONTH) AS expirationDate,
    ROUND(CASE td.store_seq 
        WHEN 1 THEN 680 
        WHEN 2 THEN 520 
        WHEN 3 THEN 540
        WHEN 4 THEN 480
        WHEN 5 THEN 620
        END + (td.tenant_seq % 4) * 25, 2) AS rentAmount,
    DATE_ADD(@month_anchor, INTERVAL ((td.tenant_seq % 7) + 3) DAY) AS rentDueDay,
    0.045 + (td.tenant_seq % 5) * 0.005 AS feeOnSales
FROM tmp_tenant_directory td
JOIN tmp_tenant_ids ti ON ti.tenant_seq = td.tenant_seq
JOIN mk_productType pt ON pt.productType = td.productTypeKey;

INSERT INTO mk_contracts (startDate, expirationDate, rent, rentDueDay, feeOnSales, productTypeID)
SELECT startDate, expirationDate, rentAmount, rentDueDay, feeOnSales, productTypeID
FROM tmp_contract_seed
ORDER BY tenant_seq;

DROP TEMPORARY TABLE IF EXISTS tmp_contract_ids;
CREATE TEMPORARY TABLE tmp_contract_ids AS
SELECT ROW_NUMBER() OVER (ORDER BY contractID) AS tenant_seq, contractID
FROM mk_contracts;

INSERT INTO mk_tenantPerContracts (tenantID, contractID, deleted, postTime)
SELECT cs.tenantID, ci.contractID, b'0', @seed_now
FROM tmp_contract_seed cs
JOIN tmp_contract_ids ci ON ci.tenant_seq = cs.tenant_seq;

INSERT INTO mk_contractsPerKiosks (contractID, kioskID, startDate, endDate, deleted)
SELECT ci.contractID, cs.kioskID, cs.startDate, NULL, b'0'
FROM tmp_contract_seed cs
JOIN tmp_contract_ids ci ON ci.tenant_seq = cs.tenant_seq;

INSERT INTO mk_contractFees (contractID, productTypeID, feePct, deleted, postTime, feeType, fixedAmount)
SELECT ci.contractID, cs.productTypeID, ROUND(cs.feeOnSales * 100, 2), b'0', @seed_now, 'PERCENTAGE', NULL
FROM tmp_contract_seed cs
JOIN tmp_contract_ids ci ON ci.tenant_seq = cs.tenant_seq;

-- Products and inventory for 3 businesses in DIFFERENT kiosks
DROP TEMPORARY TABLE IF EXISTS tmp_inventory_businesses;
CREATE TEMPORARY TABLE tmp_inventory_businesses AS
SELECT td.tenant_seq, ti.tenantID, td.kioskID, cs.productTypeID, td.productTypeKey, td.tenantDisplayName
FROM tmp_tenant_directory td
JOIN tmp_tenant_ids ti ON ti.tenant_seq = td.tenant_seq
JOIN tmp_contract_seed cs ON cs.tenant_seq = td.tenant_seq
WHERE td.tenant_seq IN (1, 7, 20);  -- 3 negocios en kioskos diferentes

DROP TEMPORARY TABLE IF EXISTS tmp_product_catalog;
CREATE TEMPORARY TABLE tmp_product_catalog (
    tenant_seq INT,
    product_label VARCHAR(80),
    description VARCHAR(200),
    expires BIT,
    shelf_days INT,
    basePrice DECIMAL(10,2),
    category VARCHAR(30)
);

INSERT INTO tmp_product_catalog (tenant_seq, product_label, description, expires, shelf_days, basePrice, category)
VALUES
-- Cafe Siete Esquinas (Kiosk 1)
(1, 'Blend Amanecer', 'Cafe en grano tostado medio, notas a caramelo.', b'0', 0, 8.50, 'COFFEE_BEANS'),
(1, 'Reserva Tarde', 'Cafe especial con notas a cacao y nueces.', b'0', 0, 9.80, 'COFFEE_BEANS'),
(1, 'Cold Brew Matinal', 'Preparado frio embotellado, listo para servir.', b'1', 5, 6.90, 'READY_TO_DRINK'),
(1, 'Expresso Intenso', 'Cafe expresso de tueste oscuro.', b'0', 0, 4.50, 'BREWED_COFFEE'),
(1, 'Cappuccino Clasico', 'Cappuccino tradicional con leche vaporizada.', b'1', 1, 5.20, 'BREWED_COFFEE'),

-- Sabores del Mercado (Kiosk 2)
(7, 'Torta de Chocolate', 'Torta artesanal con chocolate belga.', b'1', 3, 12.50, 'DESSERTS'),
(7, 'Empanadas Gourmet', 'Empanadas rellenas de carne y pollo.', b'1', 2, 8.80, 'SAVORY'),
(7, 'Ensalada Mediterranea', 'Ensalada fresca con aceitunas y queso feta.', b'1', 1, 15.20, 'SALADS'),
(7, 'Sopa del Dia', 'Sopa casera variada diariamente.', b'1', 1, 9.50, 'SOUPS'),
(7, 'Brownie de Nuez', 'Brownie humedo con nueces caramelizadas.', b'1', 4, 7.80, 'DESSERTS'),

-- Dulces Heredianos (Kiosk 4)
(20, 'Cajeta de Leche', 'Dulce tradicional de leche caramelizada.', b'1', 90, 6.20, 'TRADITIONAL'),
(20, 'Rosquillas Artesanales', 'Rosquillas heredianas tradicionales.', b'1', 15, 4.80, 'TRADITIONAL'),
(20, 'Miel de Abeja Pura', 'Miel 100% pura de abejas locales.', b'0', 0, 8.90, 'NATURAL'),
(20, 'Dulce de Coco', 'Dulce de coco rallado con panela.', b'1', 30, 5.50, 'TRADITIONAL'),
(20, 'Chocolate Artesanal', 'Tableta de chocolate 70% cacao.', b'1', 180, 7.20, 'CHOCOLATE');

DROP TEMPORARY TABLE IF EXISTS tmp_business_products;
CREATE TEMPORARY TABLE tmp_business_products AS
SELECT
    ib.tenant_seq,
    ib.tenantID,
    ib.kioskID,
    ib.productTypeID,
    ib.productTypeKey,
    ib.tenantDisplayName,
    pc.product_label,
    pc.description,
    pc.expires,
    pc.shelf_days,
    pc.basePrice,
    pc.category,
    ROW_NUMBER() OVER (PARTITION BY ib.tenant_seq ORDER BY pc.product_label) AS product_rank
FROM tmp_inventory_businesses ib
JOIN tmp_product_catalog pc ON pc.tenant_seq = ib.tenant_seq;

INSERT INTO mk_products (name, expirationDate, expires, description, deleted, enabled, productTypeID, kioskID)
SELECT
    bp.product_label,
    CASE WHEN bp.expires = b'1' THEN DATE_ADD(@seed_now, INTERVAL bp.shelf_days DAY) ELSE NULL END,
    bp.expires,
    bp.description,
    b'0',
    b'1',
    bp.productTypeID,
    bp.kioskID
FROM tmp_business_products bp
ORDER BY bp.tenant_seq, bp.product_rank;

DROP TEMPORARY TABLE IF EXISTS tmp_inserted_products;
CREATE TEMPORARY TABLE tmp_inserted_products AS
SELECT
    bp.tenant_seq,
    bp.tenantDisplayName,
    mp.productID,
    bp.product_label,
    bp.basePrice,
    bp.kioskID,
    ROW_NUMBER() OVER (PARTITION BY bp.tenant_seq ORDER BY mp.productID) AS product_rank
FROM mk_products mp
JOIN tmp_business_products bp ON mp.name = bp.product_label AND mp.kioskID = bp.kioskID
WHERE bp.tenant_seq IN (1, 7, 20);

-- Insert prices for ALL products with realistic variations
INSERT INTO mk_productPrices (price, currentPrice, postTime, productID)
SELECT
    ROUND(bp.basePrice * (1 + ((bp.product_rank - 1) * 0.05)), 2), -- Pequeña variación por producto
    b'1',
    DATE_SUB(@seed_now, INTERVAL bp.product_rank DAY),
    ip.productID
FROM tmp_inserted_products ip
JOIN tmp_business_products bp ON bp.tenant_seq = ip.tenant_seq AND bp.product_rank = ip.product_rank;

-- Insert inventory for ALL 3 businesses
INSERT INTO mk_inventory (productID, kioskID, qty_on_hand, min_stock, updatedAt)
SELECT
    ip.productID,
    bp.kioskID,
    CASE 
        WHEN bp.tenant_seq = 1 THEN 150 + (ip.product_rank * 20)  -- Cafe (más inventario)
        WHEN bp.tenant_seq = 7 THEN 80 + (ip.product_rank * 15)   -- Comida gourmet
        WHEN bp.tenant_seq = 20 THEN 120 + (ip.product_rank * 10) -- Dulces
        ELSE 100
    END AS qty_on_hand,
    CASE 
        WHEN bp.tenant_seq = 1 THEN 25
        WHEN bp.tenant_seq = 7 THEN 15
        WHEN bp.tenant_seq = 20 THEN 20
        ELSE 20
    END AS min_stock,
    DATE_SUB(@seed_now, INTERVAL 2 DAY)
FROM tmp_inserted_products ip
JOIN tmp_business_products bp ON bp.tenant_seq = ip.tenant_seq AND bp.product_rank = ip.product_rank;

-- Sales generation for 2 of the 3 businesses with inventory (Cafe Siete Esquinas y Sabores del Mercado)
DROP TEMPORARY TABLE IF EXISTS tmp_sales_businesses;
CREATE TEMPORARY TABLE tmp_sales_businesses AS
SELECT * FROM tmp_inventory_businesses WHERE tenant_seq IN (1, 7); -- Solo 2 negocios

-- Definir rango de 4 meses
DROP TEMPORARY TABLE IF EXISTS tmp_months;
CREATE TEMPORARY TABLE tmp_months AS
SELECT 0 AS month_index, DATE_SUB(@month_anchor, INTERVAL 3 MONTH) AS month_start, 
       DAY(LAST_DAY(DATE_SUB(@month_anchor, INTERVAL 3 MONTH))) AS days_in_month
UNION ALL SELECT 1, DATE_SUB(@month_anchor, INTERVAL 2 MONTH), DAY(LAST_DAY(DATE_SUB(@month_anchor, INTERVAL 2 MONTH)))
UNION ALL SELECT 2, DATE_SUB(@month_anchor, INTERVAL 1 MONTH), DAY(LAST_DAY(DATE_SUB(@month_anchor, INTERVAL 1 MONTH)))
UNION ALL SELECT 3, @month_anchor, DAY(LAST_DAY(@month_anchor));

-- Generar plan de ventas distribuido en 4 meses
DROP TEMPORARY TABLE IF EXISTS tmp_sales_plan;
CREATE TEMPORARY TABLE tmp_sales_plan AS
SELECT
    sb.tenant_seq,
    sb.tenantID,
    sb.kioskID,
    sb.productTypeID,
    m.month_index,
    m.month_start,
    m.days_in_month,
    -- Distribuir ventas proporcionalmente por mes (más ventas en meses recientes)
    CASE m.month_index
        WHEN 0 THEN 25  -- Mes actual: 25 ventas
        WHEN 1 THEN 20  -- Mes anterior: 20 ventas
        WHEN 2 THEN 15  -- Hace 2 meses: 15 ventas
        WHEN 3 THEN 10  -- Hace 3 meses: 10 ventas
    END AS sales_per_month,
    ROW_NUMBER() OVER (PARTITION BY sb.tenant_seq, m.month_index ORDER BY n.num) AS sale_seq,
    n.num AS raw_seq
FROM tmp_sales_businesses sb
JOIN tmp_months m
JOIN tmp_numbers_large n ON n.num BETWEEN 1 AND 70  -- Suficiente para cubrir todas las ventas
WHERE n.num <= CASE m.month_index
        WHEN 0 THEN 25
        WHEN 1 THEN 20  
        WHEN 2 THEN 15
        WHEN 3 THEN 10
    END;

-- Generar fechas y horas de venta distribuidas en los 4 meses
DROP TEMPORARY TABLE IF EXISTS tmp_sales_lines;
CREATE TEMPORARY TABLE tmp_sales_lines AS
SELECT
    sp.tenant_seq,
    sp.tenantID,
    sp.kioskID,
    sp.productTypeID,
    sp.month_index,
    sp.month_start,
    sp.days_in_month,
    sp.sale_seq,
    sp.raw_seq,
    -- Distribuir las ventas uniformemente a lo largo del mes
    DATE_ADD(sp.month_start, INTERVAL (sp.raw_seq * FLOOR(sp.days_in_month / sp.sales_per_month)) DAY) AS saleDate,
    -- Horarios de venta realistas (8 AM - 8 PM)
    SEC_TO_TIME(28800 + (sp.raw_seq % 43200)) AS saleTime, -- 8:00 AM a 8:00 PM
    -- Cantidades realistas (1-4 unidades por venta)
    (sp.raw_seq % 4) + 1 AS quantity
FROM tmp_sales_plan sp;

-- Enriquecer con información de productos y precios
DROP TEMPORARY TABLE IF EXISTS tmp_sales_enriched;
CREATE TEMPORARY TABLE tmp_sales_enriched AS
SELECT
    sl.*,
    ip.productID,
    pp.price AS priceAmount,
    ROW_NUMBER() OVER (ORDER BY sl.saleDate, sl.tenant_seq, sl.sale_seq) AS global_sale_seq
FROM tmp_sales_lines sl
JOIN tmp_inserted_products ip ON ip.tenant_seq = sl.tenant_seq 
    AND ip.product_rank = ((sl.sale_seq - 1) % 5) + 1  -- Rotar entre los 5 productos
JOIN mk_productPrices pp ON pp.productID = ip.productID AND pp.currentPrice = b'1';

-- Calcular montos financieros
DROP TEMPORARY TABLE IF EXISTS tmp_receipt_financials;
CREATE TEMPORARY TABLE tmp_receipt_financials AS
SELECT
    se.global_sale_seq AS sale_seq,
    se.tenant_seq,
    se.tenantID,
    se.kioskID,
    se.productID,
    se.priceAmount,
    se.quantity,
    TIMESTAMP(se.saleDate, se.saleTime) AS saleDateTime,
    ROUND(se.priceAmount * se.quantity, 2) AS grossSubTotal,
    -- Aplicar descuentos ocasionales (10% cada 15 ventas, 5% cada 10 ventas)
    CASE 
        WHEN se.global_sale_seq % 15 = 0 THEN ROUND(se.priceAmount * se.quantity * 0.10, 2)
        WHEN se.global_sale_seq % 10 = 0 THEN ROUND(se.priceAmount * se.quantity * 0.05, 2)
        ELSE 0 
    END AS discountAmount,
    se.productTypeID
FROM tmp_sales_enriched se;

-- Calcular impuestos y totales
DROP TEMPORARY TABLE IF EXISTS tmp_receipt_financials_ext;
CREATE TEMPORARY TABLE tmp_receipt_financials_ext AS
SELECT
    rf.*,
    ROUND(rf.grossSubTotal - rf.discountAmount, 2) AS netSubTotal,
    ROUND((rf.grossSubTotal - rf.discountAmount) * 0.13, 2) AS taxAmount,
    ROUND((rf.grossSubTotal - rf.discountAmount) * 1.13, 2) AS totalAmount
FROM tmp_receipt_financials rf;

DROP TEMPORARY TABLE IF EXISTS tmp_client_seq;
CREATE TEMPORARY TABLE tmp_client_seq AS
SELECT ROW_NUMBER() OVER (ORDER BY clientID) AS seq, clientID FROM mk_clients;
SET @client_total := (SELECT COUNT(*) FROM tmp_client_seq);

DROP TEMPORARY TABLE IF EXISTS tmp_payment_seq;
CREATE TEMPORARY TABLE tmp_payment_seq AS
SELECT ROW_NUMBER() OVER (ORDER BY paymentID) AS seq, paymentID FROM mk_payments;
SET @payment_total := (SELECT COUNT(*) FROM tmp_payment_seq);

-- Insert receipts
INSERT INTO mk_receipts (kioskID, clientID, paymentID, receiptNumber, discount, taxApplied, taxAmount, total, checksum, postTime)
SELECT
    rf.kioskID,
    cli.clientID,
    pay.paymentID,
    800000 + rf.sale_seq,
    rf.discountAmount,
    b'1',
    rf.taxAmount,
    rf.totalAmount,
    UNHEX(SHA2(CONCAT(800000 + rf.sale_seq, ':', cli.clientID, ':', rf.totalAmount), 256)),
    rf.saleDateTime
FROM tmp_receipt_financials_ext rf
JOIN tmp_client_seq cli ON cli.seq = ((rf.sale_seq - 1) % @client_total) + 1
JOIN tmp_payment_seq pay ON pay.seq = ((rf.sale_seq - 1) % @payment_total) + 1
ORDER BY rf.sale_seq;

DROP TEMPORARY TABLE IF EXISTS tmp_receipt_ids;
CREATE TEMPORARY TABLE tmp_receipt_ids AS
SELECT ROW_NUMBER() OVER (ORDER BY receiptID) AS seq, receiptID
FROM mk_receipts;

-- Insert receipt details
INSERT INTO mk_receiptDetails (receiptID, productPriceID, productAmount, subTotal, checksum)
SELECT
    rid.receiptID,
    ppi.productPriceID,
    rf.quantity,
    rf.grossSubTotal,
    UNHEX(SHA2(CONCAT(rid.receiptID, ':', ppi.productPriceID, ':', rf.quantity), 256))
FROM tmp_receipt_financials_ext rf
JOIN tmp_receipt_ids rid ON rid.seq = rf.sale_seq
JOIN mk_productPrices ppi ON ppi.productID = rf.productID AND ppi.currentPrice = b'1';

-- Update inventory based on sales
DROP TEMPORARY TABLE IF EXISTS tmp_product_sales;
CREATE TEMPORARY TABLE tmp_product_sales AS
SELECT productID, SUM(quantity) AS totalSold
FROM tmp_receipt_financials_ext
GROUP BY productID;

UPDATE mk_inventory inv
JOIN tmp_product_sales ps ON ps.productID = inv.productID
SET inv.qty_on_hand = GREATEST(inv.qty_on_hand - ps.totalSold, 0),
    inv.updatedAt = @seed_now;

-- Insert transactions
DROP TEMPORARY TABLE IF EXISTS tmp_user_seq;
CREATE TEMPORARY TABLE tmp_user_seq AS
SELECT ROW_NUMBER() OVER (ORDER BY userID) AS seq, userID FROM mk_users;
SET @user_total := (SELECT COUNT(*) FROM tmp_user_seq);

INSERT INTO mk_transactions (amount, transactionDate, transactionDescription, checksum, referenceID, transactionStatus, transactionTypeID, userID)
SELECT
    rf.totalAmount,
    rf.saleDateTime,
    CONCAT('Venta recibo ', 800000 + rf.sale_seq, ' - ', 
           CASE rf.tenant_seq 
               WHEN 1 THEN 'Cafe Siete Esquinas' 
               WHEN 7 THEN 'Sabores del Mercado' 
               ELSE 'Otro' 
           END),
    UNHEX(SHA2(CONCAT(800000 + rf.sale_seq, ':', rf.totalAmount, ':', rf.saleDateTime), 256)),
    rid.receiptID,
    'COMPLETED',
    (SELECT transactionTypeID FROM mk_transactionTypes WHERE transactionType = 'SALE_PAYMENT' LIMIT 1),
    usr.userID
FROM tmp_receipt_financials_ext rf
JOIN tmp_receipt_ids rid ON rid.seq = rf.sale_seq
JOIN tmp_user_seq usr ON usr.seq = ((rf.sale_seq - 1) % @user_total) + 1
ORDER BY rid.receiptID;

-- Snapshot summary
SELECT 'buildings' AS entity, COUNT(*) AS total FROM mk_building
UNION ALL SELECT 'kiosks', COUNT(*) FROM mk_kiosks
UNION ALL SELECT 'tenants', COUNT(*) FROM mk_tenant
UNION ALL SELECT 'contracts', COUNT(*) FROM mk_contracts
UNION ALL SELECT 'products', COUNT(*) FROM mk_products
UNION ALL SELECT 'product_prices', COUNT(*) FROM mk_productPrices
UNION ALL SELECT 'inventory', COUNT(*) FROM mk_inventory
UNION ALL SELECT 'receipts', COUNT(*) FROM mk_receipts
UNION ALL SELECT 'receipt_details', COUNT(*) FROM mk_receiptDetails
UNION ALL SELECT 'transactions', COUNT(*) FROM mk_transactions;


UPDATE mk_contractsPerKiosks
SET deleted = 1
WHERE contractID IN (2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13 ,14);