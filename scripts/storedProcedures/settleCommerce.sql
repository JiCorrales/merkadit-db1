DROP PROCEDURE IF EXISTS settleCommerce;
DELIMITER //
CREATE PROCEDURE settleCommerce(
    IN pTenantName   VARCHAR(60),
    IN pKioskName    VARCHAR(30),
    IN pUserId       INT,
    IN pComputer     VARCHAR(120)
)
BEGIN
    DECLARE vTenantId INT;
    DECLARE vContractId INT;
    DECLARE vKioskId INT;
    DECLARE vMonth INT;
    DECLARE vYear INT;
    DECLARE vTotalSales DECIMAL(14,2);
    DECLARE vFeePct DECIMAL(10,4);
    DECLARE vCommissionAmount DECIMAL(14,2);
    DECLARE vTenantAmount DECIMAL(14,2);
    DECLARE vChecksum VARBINARY(250);
    DECLARE vChecksumText CHAR(64);
    DECLARE vSettlementExists INT;
    DECLARE vErrorMessage VARCHAR(500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 vErrorMessage = MESSAGE_TEXT;
        INSERT INTO mk_logs (
            postTime, description, refID, value, checksum, computer,
            userID, logTypeID, logServiceID, logLevelID
        ) VALUES (
            NOW(),
            'Error en settleCommerce',
            NULL,
            CONCAT('Tenant: ', pTenantName, ', Kiosk: ', pKioskName, ', Error: ', vErrorMessage),
            SHA2(CONCAT('ERROR', NOW(), pTenantName, pKioskName), 256),
            pComputer,
            pUserId,
            (SELECT logTypeID FROM mk_logTypes WHERE logTypeName = 'SETTLEMENT_ERROR'),
            (SELECT logServiceID FROM mk_logServices WHERE logServiceName = 'FINANCIAL'),
            (SELECT logLevelID FROM mk_logLevels WHERE logLevelName = 'ERROR')
        );
        ROLLBACK;
        RESIGNAL;
    END;

    INSERT INTO mk_logTypes (logTypeName)
    SELECT 'SETTLEMENT_ERROR' WHERE NOT EXISTS (SELECT 1 FROM mk_logTypes WHERE logTypeName = 'SETTLEMENT_ERROR');
    INSERT INTO mk_logTypes (logTypeName)
    SELECT 'SETTLEMENT_WARNING' WHERE NOT EXISTS (SELECT 1 FROM mk_logTypes WHERE logTypeName = 'SETTLEMENT_WARNING');
    INSERT INTO mk_logTypes (logTypeName)
    SELECT 'SETTLEMENT_SUCCESS' WHERE NOT EXISTS (SELECT 1 FROM mk_logTypes WHERE logTypeName = 'SETTLEMENT_SUCCESS');
    INSERT INTO mk_logServices (logServiceName)
    SELECT 'FINANCIAL' WHERE NOT EXISTS (SELECT 1 FROM mk_logServices WHERE logServiceName = 'FINANCIAL');
    INSERT INTO mk_logLevels (logLevelName)
    SELECT 'INFO' WHERE NOT EXISTS (SELECT 1 FROM mk_logLevels WHERE logLevelName = 'INFO');
    INSERT INTO mk_logLevels (logLevelName)
    SELECT 'ERROR' WHERE NOT EXISTS (SELECT 1 FROM mk_logLevels WHERE logLevelName = 'ERROR');
    INSERT INTO mk_logLevels (logLevelName)
    SELECT 'WARNING' WHERE NOT EXISTS (SELECT 1 FROM mk_logLevels WHERE logLevelName = 'WARNING');
    INSERT INTO mk_transactionTypes (transactionType)
    SELECT 'COMISION_VENTAS' WHERE NOT EXISTS (SELECT 1 FROM mk_transactionTypes WHERE transactionType = 'COMISION_VENTAS');
    INSERT INTO mk_transactionTypes (transactionType)
    SELECT 'PAGO_ALQUILER' WHERE NOT EXISTS (SELECT 1 FROM mk_transactionTypes WHERE transactionType = 'PAGO_ALQUILER');

    START TRANSACTION;

    SELECT
        t.tenantID,
        c.contractID,
        k.kioskID
    INTO vTenantId, vContractId, vKioskId
    FROM mk_tenant t
    JOIN mk_tenantPerContracts tpc ON tpc.tenantID = t.tenantID AND tpc.deleted = 0
    JOIN mk_contracts c ON c.contractID = tpc.contractID
    JOIN mk_contractsPerKiosks cpk ON cpk.contractID = c.contractID AND cpk.deleted = 0
    JOIN mk_kiosks k ON k.kioskID = cpk.kioskID
    WHERE t.tenantName = pTenantName
      AND k.kioskName = pKioskName
    ORDER BY cpk.startDate DESC
    LIMIT 1;

    IF vTenantId IS NULL OR vContractId IS NULL OR vKioskId IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tenant o kiosk no encontrado';
    END IF;

    SET vMonth = MONTH(CURRENT_DATE());
    SET vYear = YEAR(CURRENT_DATE());

    SELECT COUNT(*) INTO vSettlementExists
    FROM mk_logs l
    WHERE l.refID = vContractId
      AND l.logTypeID = (SELECT logTypeID FROM mk_logTypes WHERE logTypeName = 'SETTLEMENT_SUCCESS')
      AND MONTH(l.postTime) = vMonth
      AND YEAR(l.postTime) = vYear;

    IF vSettlementExists > 0 THEN
        INSERT INTO mk_logs (
            postTime, description, refID, value, checksum, computer,
            userID, logTypeID, logServiceID, logLevelID
        ) VALUES (
            NOW(),
            'Settlement ya fue procesado este mes',
            vContractId,
            CONCAT('Tenant: ', pTenantName, ', Kiosk: ', pKioskName, ', Mes: ', vMonth, '/', vYear),
            SHA2(CONCAT('SETTLEMENT_DUP', NOW(), vContractId), 256),
            pComputer,
            pUserId,
            (SELECT logTypeID FROM mk_logTypes WHERE logTypeName = 'SETTLEMENT_WARNING'),
            (SELECT logServiceID FROM mk_logServices WHERE logServiceName = 'FINANCIAL'),
            (SELECT logLevelID FROM mk_logLevels WHERE logLevelName = 'WARNING')
        );
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Settlement ya fue procesado este mes';
    END IF;

    SELECT COALESCE(SUM(r.total), 0)
    INTO vTotalSales
    FROM mk_receipts r
    WHERE r.kioskID = vKioskId
      AND MONTH(r.postTime) = vMonth
      AND YEAR(r.postTime) = vYear;

    IF vTotalSales <= 0 THEN
        INSERT INTO mk_logs (
            postTime, description, refID, value, checksum, computer,
            userID, logTypeID, logServiceID, logLevelID
        ) VALUES (
            NOW(),
            'Sin ventas para liquidar',
            vContractId,
            CONCAT('Tenant: ', pTenantName, ', Kiosk: ', pKioskName, ', Mes: ', vMonth, '/', vYear),
            SHA2(CONCAT('SETTLEMENT_EMPTY', NOW(), vContractId), 256),
            pComputer,
            pUserId,
            (SELECT logTypeID FROM mk_logTypes WHERE logTypeName = 'SETTLEMENT_WARNING'),
            (SELECT logServiceID FROM mk_logServices WHERE logServiceName = 'FINANCIAL'),
            (SELECT logLevelID FROM mk_logLevels WHERE logLevelName = 'WARNING')
        );
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay ventas registradas para este periodo';
    END IF;

    SELECT feeOnSales INTO vFeePct
    FROM mk_contracts
    WHERE contractID = vContractId;

    IF vFeePct IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contrato sin configuracion de comision';
    END IF;

    SET vCommissionAmount = ROUND(vTotalSales * vFeePct, 2);
    SET vTenantAmount = ROUND(vTotalSales - vCommissionAmount, 2);

    SET vChecksumText = SHA2(CONCAT_WS('|', vContractId, vKioskId, vMonth, vYear, vTotalSales, vCommissionAmount, vTenantAmount), 256);
    SET vChecksum = UNHEX(vChecksumText);

    INSERT INTO mk_transactions (
        amount, transactionDate, transactionDescription, checksum,
        referenceID, transactionStatus, transactionTypeID, userID
    ) VALUES (
        -vCommissionAmount,
        NOW(),
        CONCAT('Comision ventas ', MONTHNAME(CURRENT_DATE()), ' ', vYear),
        vChecksum,
        vContractId,
        'COMPLETED',
        (SELECT transactionTypeID FROM mk_transactionTypes WHERE transactionType = 'COMISION_VENTAS'),
        pUserId
    );

    INSERT INTO mk_transactions (
        amount, transactionDate, transactionDescription, checksum,
        referenceID, transactionStatus, transactionTypeID, userID
    ) VALUES (
        vTenantAmount,
        NOW(),
        CONCAT('Liquidacion ventas ', MONTHNAME(CURRENT_DATE()), ' ', vYear),
        vChecksum,
        vContractId,
        'COMPLETED',
        (SELECT transactionTypeID FROM mk_transactionTypes WHERE transactionType = 'PAGO_ALQUILER'),
        pUserId
    );

    INSERT INTO mk_logs (
        postTime, description, refID, value, checksum, computer,
        userID, logTypeID, logServiceID, logLevelID, oldRow, newRow, actionType
    ) VALUES (
        NOW(),
        'Settlement completado exitosamente',
        vContractId,
        CONCAT('Ventas: ', vTotalSales, ', Comision: ', vCommissionAmount, ', Neto Tenant: ', vTenantAmount),
        vChecksumText,
        pComputer,
        pUserId,
        (SELECT logTypeID FROM mk_logTypes WHERE logTypeName = 'SETTLEMENT_SUCCESS'),
        (SELECT logServiceID FROM mk_logServices WHERE logServiceName = 'FINANCIAL'),
        (SELECT logLevelID FROM mk_logLevels WHERE logLevelName = 'INFO'),
        NULL,
        JSON_OBJECT(
            'tenantId', vTenantId,
            'contractId', vContractId,
            'kioskId', vKioskId,
            'month', vMonth,
            'year', vYear,
            'totalSales', vTotalSales,
            'commissionPct', vFeePct,
            'commissionAmount', vCommissionAmount,
            'tenantAmount', vTenantAmount
        ),
        'SETTLEMENT_COMPLETED'
    );

    COMMIT;

    SELECT
        'Settlement completado exitosamente' AS resultado,
        vTotalSales AS totalVentas,
        vFeePct AS comisionPorcentaje,
        vCommissionAmount AS montoComision,
        vTenantAmount AS montoTenant,
        vMonth AS mes,
        vYear AS anio;
END //
DELIMITER ;
