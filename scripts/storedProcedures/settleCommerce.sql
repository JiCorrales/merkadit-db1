DROP PROCEDURE IF EXISTS settleCommerce;
DELIMITER //

CREATE PROCEDURE settleCommerce(
    IN pComercioNombre VARCHAR(50),
    IN pLocalNombre VARCHAR(45), 
    IN pUsuarioId INT,
    IN pComputadora VARCHAR(120)
)
BEGIN
    DECLARE vTenantId INT;
    DECLARE vLocalId INT;
    DECLARE vContractId INT;
    DECLARE vKioskId INT;
    DECLARE vMesActual INT;
    DECLARE vAnioActual INT;
    DECLARE vTotalVentas DECIMAL(12,2);
    DECLARE vComisionPorcentaje FLOAT;
    DECLARE vMontoComision DECIMAL(12,2);
    DECLARE vMontoTenant DECIMAL(12,2);
    DECLARE vSettlementExists INT;
    DECLARE vChecksum VARBINARY(250);
    DECLARE vTransactionId INT;
    DECLARE vErrorMessage VARCHAR(500);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Obtener el mensaje de error
        GET DIAGNOSTICS CONDITION 1 vErrorMessage = MESSAGE_TEXT;
        
        -- Log del error
        INSERT INTO mk_logs (
            postTime, description, refId, value, checksum, computer, 
            userId, logTypeId, logServiceId, logLevelId
        ) VALUES (
            NOW(), 
            'Error en settleCommerce', 
            NULL,
            CONCAT('Comercio: ', pComercioNombre, ', Local: ', pLocalNombre, ', Error: ', vErrorMessage),
            SHA2(CONCAT(pComercioNombre, pLocalNombre, NOW()), 256),
            pComputadora,
            pUsuarioId,
            (SELECT logTypeId FROM mk_logTypes WHERE logTypeName = 'SETTLEMENT_ERROR'),
            (SELECT logServiceId FROM mk_logServices WHERE logServiceName = 'FINANCIAL'),
            (SELECT logLevelId FROM mk_logLevels WHERE logLevelName = 'ERROR')
        );
        ROLLBACK;
        RESIGNAL;
    END;

    -- Ensure master data for logging and transaction types
    INSERT INTO mk_logTypes (logTypeName)
    SELECT 'SETTLEMENT_ERROR'
    WHERE NOT EXISTS (SELECT 1 FROM mk_logTypes WHERE logTypeName = 'SETTLEMENT_ERROR');

    INSERT INTO mk_logTypes (logTypeName)
    SELECT 'SETTLEMENT_WARNING'
    WHERE NOT EXISTS (SELECT 1 FROM mk_logTypes WHERE logTypeName = 'SETTLEMENT_WARNING');

    INSERT INTO mk_logTypes (logTypeName)
    SELECT 'SETTLEMENT_SUCCESS'
    WHERE NOT EXISTS (SELECT 1 FROM mk_logTypes WHERE logTypeName = 'SETTLEMENT_SUCCESS');

    INSERT INTO mk_logServices (logServiceName)
    SELECT 'FINANCIAL'
    WHERE NOT EXISTS (SELECT 1 FROM mk_logServices WHERE logServiceName = 'FINANCIAL');

    INSERT INTO mk_logLevels (logLevelName)
    SELECT 'INFO'
    WHERE NOT EXISTS (SELECT 1 FROM mk_logLevels WHERE logLevelName = 'INFO');

    INSERT INTO mk_logLevels (logLevelName)
    SELECT 'ERROR'
    WHERE NOT EXISTS (SELECT 1 FROM mk_logLevels WHERE logLevelName = 'ERROR');

    INSERT INTO mk_logLevels (logLevelName)
    SELECT 'WARNING'
    WHERE NOT EXISTS (SELECT 1 FROM mk_logLevels WHERE logLevelName = 'WARNING');

    INSERT INTO mk_transactionTypes (transactionType)
    SELECT 'COMISION_VENTAS'
    WHERE NOT EXISTS (SELECT 1 FROM mk_transactionTypes WHERE transactionType = 'COMISION_VENTAS');

    INSERT INTO mk_transactionTypes (transactionType)
    SELECT 'PAGO_ALQUILER'
    WHERE NOT EXISTS (SELECT 1 FROM mk_transactionTypes WHERE transactionType = 'PAGO_ALQUILER');

    START TRANSACTION;

    -- 1. Obtener IDs del tenant, local y contrato
    SELECT t.tenantId, l.localId, c.contractId, k.kioskId
    INTO vTenantId, vLocalId, vContractId, vKioskId
    FROM mk_tenant t
    JOIN mk_tenantPerContracts tpc ON t.tenantId = tpc.tenantId
    JOIN mk_contracts c ON tpc.contractId = c.contractId  
    JOIN mk_locals l ON c.localId = l.localId
    LEFT JOIN mk_kiosks k ON l.localId = k.localId
    WHERE t.tenantName = pComercioNombre 
      AND l.localName = pLocalNombre
      AND tpc.deleted = 0
    LIMIT 1;

    IF vTenantId IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Comercio o local no encontrado';
    END IF;

    -- 2. Obtener mes/aÃƒÂ±o actual
    SET vMesActual = MONTH(CURRENT_DATE());
    SET vAnioActual = YEAR(CURRENT_DATE());

    -- 3. Verificar si ya se hizo settlement este mes
    SELECT COUNT(*) INTO vSettlementExists
    FROM mk_logs l
    WHERE l.refId = vTenantId
      AND l.description LIKE 'Settlement completado%'
      AND MONTH(l.postTime) = vMesActual
      AND YEAR(l.postTime) = vAnioActual
      AND l.logTypeId = (SELECT logTypeId FROM mk_logTypes WHERE logTypeName = 'SETTLEMENT_SUCCESS');

    IF vSettlementExists > 0 THEN
        INSERT INTO mk_logs (
            postTime, description, refId, value, checksum, computer, 
            userId, logTypeId, logServiceId, logLevelId
        ) VALUES (
            NOW(), 
            'Settlement ya fue procesado este mes', 
            vTenantId,
            CONCAT('Comercio: ', pComercioNombre, ', Local: ', pLocalNombre, ', Mes: ', vMesActual),
            SHA2(CONCAT(pComercioNombre, pLocalNombre, vMesActual, NOW()), 256),
            pComputadora,
            pUsuarioId,
            (SELECT logTypeId FROM mk_logTypes WHERE logTypeName = 'SETTLEMENT_WARNING'),
            (SELECT logServiceId FROM mk_logServices WHERE logServiceName = 'FINANCIAL'),
            (SELECT logLevelId FROM mk_logLevels WHERE logLevelName = 'WARNING')
        );
        
        COMMIT;
        SELECT 'Settlement ya fue procesado para este mes' AS resultado;
    ELSE
        -- 4. Calcular ventas mensuales del kiosko
        SELECT COALESCE(SUM(r.total), 0) INTO vTotalVentas
        FROM mk_receipts r
        WHERE r.kioskId = vKioskId
          AND MONTH(r.postTime) = vMesActual
          AND YEAR(r.postTime) = vAnioActual;

        -- 5. Obtener porcentaje de comisiÃƒÂ³n
        SELECT feeOnSales INTO vComisionPorcentaje
        FROM mk_contracts
        WHERE contractId = vContractId;

        -- 6. Calcular montos
        SET vMontoComision = vTotalVentas * (vComisionPorcentaje / 100);
        SET vMontoTenant = vTotalVentas - vMontoComision;

        -- 7. Generar checksum
        SET vChecksum = SHA2(CONCAT(vTenantId, vLocalId, vTotalVentas, vMontoComision, NOW()), 256);

        -- 8. Registrar transacciÃƒÂ³n de comisiÃƒÂ³n
        INSERT INTO mk_transactions (
            amount, transactionDate, transactionDescription, checksum,
            referenceId, transactionStatus, transactionTypeId, userId
        ) VALUES (
            -vMontoComision, 
            NOW(),
            CONCAT('ComisiÃƒÂ³n ventas ', MONTHNAME(CURRENT_DATE()), ' ', vAnioActual),
            vChecksum, 
            vContractId, 
            'successful',
            (SELECT transactionTypeId FROM mk_transactionTypes WHERE transactionType = 'COMISION_VENTAS'),
            pUsuarioId
        );

        -- 9. Registrar transacciÃƒÂ³n de pago al tenant
        INSERT INTO mk_transactions (
            amount, transactionDate, transactionDescription, checksum,
            referenceId, transactionStatus, transactionTypeId, userId
        ) VALUES (
            vMontoTenant, 
            NOW(),
            CONCAT('Pago ventas ', MONTHNAME(CURRENT_DATE()), ' ', vAnioActual), 
            vChecksum, 
            vContractId, 
            'successful',
            (SELECT transactionTypeId FROM mk_transactionTypes WHERE transactionType = 'PAGO_ALQUILER'),
            pUsuarioId
        );

        -- 10. Registrar log de settlement
        INSERT INTO mk_logs (
            postTime, description, refId, value, checksum, computer,
            userId, logTypeId, logServiceId, logLevelId, oldRow, newRow, actionType
        ) VALUES (
            NOW(), 
            'Settlement completado exitosamente', 
            vTenantId,
            CONCAT('Ventas: $', vTotalVentas, ', ComisiÃƒÂ³n: $', vMontoComision, ', Neto Tenant: $', vMontoTenant),
            vChecksum, 
            pComputadora, 
            pUsuarioId,
            (SELECT logTypeId FROM mk_logTypes WHERE logTypeName = 'SETTLEMENT_SUCCESS'),
            (SELECT logServiceId FROM mk_logServices WHERE logServiceName = 'FINANCIAL'),
            (SELECT logLevelId FROM mk_logLevels WHERE logLevelName = 'INFO'),
            NULL,
            JSON_OBJECT(
                'tenantId', vTenantId, 
                'localId', vLocalId, 
                'contractId', vContractId,
                'kioskId', vKioskId, 
                'totalVentas', vTotalVentas, 
                'comisionPorcentaje', vComisionPorcentaje,
                'montoComision', vMontoComision, 
                'montoTenant', vMontoTenant, 
                'mes', vMesActual, 
                'anio', vAnioActual
            ),
            'SETTLEMENT_COMPLETED'
        );

        COMMIT;

        SELECT 
            'Settlement completado exitosamente' AS resultado,
            vTotalVentas AS totalVentas,
            vComisionPorcentaje AS comisionPorcentaje,
            vMontoComision AS montoComision,
            vMontoTenant AS montoTenant,
            vMesActual AS mes,
            vAnioActual AS anio;
    END IF;

END //

DELIMITER ;


CALL settleCommerce('SuperFoods CR', 'Local Central', 1, 'SERVER01');



SELECT 
    transactionID,
    transactionDate,
    transactionDescription,
    amount,
    transactionStatus,
    transactionTypeID,
    referenceID
FROM mk_transactions 
ORDER BY transactionID DESC;


SELECT 
    logID,
    postTime,
    description,
    refID,
    value,
    logTypeID,
    logServiceID,
    logLevelID,
    actionType
FROM mk_logs 
WHERE description LIKE '%Settlement%'
ORDER BY logID DESC;



