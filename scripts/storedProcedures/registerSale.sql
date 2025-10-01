
DROP PROCEDURE IF EXISTS registerSale;
DELIMITER //
CREATE PROCEDURE registerSale(
    IN pProductName           VARCHAR(20),
    IN pLocalName             VARCHAR(30),
    IN pQtySold               INT,
    IN pAmountPaid            DECIMAL(10,2),
    IN pPaymentMethod         VARCHAR(100),
    IN pPaymentConfirmations  VARCHAR(255),
    IN pReferenceNumbers      VARCHAR(255),
    IN pInvoiceNumber         INT,
    IN pClientCode            VARCHAR(50),
    IN pDiscountApplied       DECIMAL(10,2),
    IN pUserID                INT
)
BEGIN
    DECLARE vKioskID INT;
    DECLARE vProductID INT;
    DECLARE vProductPriceID INT;
    DECLARE vUnitPrice DECIMAL(10,2);
    DECLARE vSubTotal DECIMAL(10,2);
    DECLARE vTotal DECIMAL(10,2);
    DECLARE vTaxApplied BIT;
    DECLARE vTaxAmount DECIMAL(10,2);

    DECLARE vReceiptID INT;
    DECLARE vPaymentID INT;
    DECLARE vClientID INT;
    DECLARE vNow DATETIME;
    DECLARE vReceiptChecksum VARBINARY(250);
    DECLARE vDetailChecksum VARBINARY(250);
    DECLARE vTxChecksum VARBINARY(250);

    DECLARE vLogTypeID INT;
    DECLARE vLogServiceID INT;
    DECLARE vLogLevelID INT;
    DECLARE vLogLevelErrorID INT;
    DECLARE vTxTypeID INT;

    DECLARE vComputer VARCHAR(120);

    IF pProductName IS NULL
        OR pLocalName IS NULL
        OR pQtySold IS NULL
        OR pAmountPaid IS NULL OR pAmountPaid < 0
        OR pPaymentMethod IS NULL
        OR pInvoiceNumber IS NULL
        OR pClientCode IS NULL
        OR pDiscountApplied IS NULL OR pDiscountApplied < 0
        OR pUserID IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid input parameters';
    END IF;

    SET vNow = NOW();
    SET vComputer = @@hostname;

    START TRANSACTION;

    INSERT INTO mk_logTypes (logTypeName)
    SELECT 'BUSINESS' WHERE NOT EXISTS (SELECT 1 FROM mk_logTypes WHERE logTypeName = 'BUSINESS');

    INSERT INTO mk_logServices (logServiceName)
    SELECT 'POS' WHERE NOT EXISTS (SELECT 1 FROM mk_logServices WHERE logServiceName = 'POS');

    INSERT INTO mk_logLevels (logLevelName)
    SELECT 'INFO' WHERE NOT EXISTS (SELECT 1 FROM mk_logLevels WHERE logLevelName = 'INFO');

    INSERT INTO mk_logLevels (logLevelName)
    SELECT 'ERROR' WHERE NOT EXISTS (SELECT 1 FROM mk_logLevels WHERE logLevelName = 'ERROR');

    INSERT INTO mk_transactionTypes (transactionType)
    SELECT 'SALE_PAYMENT' WHERE NOT EXISTS (SELECT 1 FROM mk_transactionTypes WHERE transactionType = 'SALE_PAYMENT');

    SET vLogTypeID = (SELECT logTypeID FROM mk_logTypes WHERE logTypeName = 'BUSINESS');
    SET vLogServiceID = (SELECT logServiceID FROM mk_logServices WHERE logServiceName = 'POS');
    SET vLogLevelID = (SELECT logLevelID FROM mk_logLevels WHERE logLevelName = 'INFO');
    SET vLogLevelErrorID = (SELECT logLevelID FROM mk_logLevels WHERE logLevelName = 'ERROR');
    SET vTxTypeID = (SELECT transactionTypeID FROM mk_transactionTypes WHERE transactionType = 'SALE_PAYMENT');

    SELECT k.kioskID
    INTO vKioskID
    FROM mk_kiosks k
    WHERE k.kioskName = pLocalName
    LIMIT 1;

    IF vKioskID IS NULL THEN
        INSERT INTO mk_logs (logTypeID, logServiceID, logLevelID, description, postTime, computer, userID, checksum)
        VALUES (
            vLogTypeID,
            vLogServiceID,
            vLogLevelErrorID,
            CONCAT('Invalid kiosk: Name=', pLocalName),
            vNow,
            vComputer,
            pUserID,
            SHA2(CONCAT_WS('|', 'ERROR', vNow, pLocalName), 256)
        );
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid kiosk';
    END IF;

    SELECT p.productID
    INTO vProductID
    FROM mk_products p
    WHERE p.name = pProductName
        AND p.kioskID = vKioskID
    LIMIT 1;

    IF vProductID IS NULL THEN
        INSERT INTO mk_logs (logTypeID, logServiceID, logLevelID, description, postTime, computer, userID, checksum)
        VALUES (
            vLogTypeID,
            vLogServiceID,
            vLogLevelErrorID,
            CONCAT('Product not found: Product=', pProductName),
            vNow,
            vComputer,
            pUserID,
            SHA2(CONCAT_WS('|', 'ERROR', vNow, pProductName), 256)
        );
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found';
    END IF;

    SELECT pp.productPriceID, pp.price
    INTO vProductPriceID, vUnitPrice
    FROM mk_productPrices pp
    WHERE pp.productID = vProductID
        AND pp.currentPrice = 1
    ORDER BY pp.postTime DESC, pp.productPriceID DESC
    LIMIT 1;

    IF vProductPriceID IS NULL THEN
        INSERT INTO mk_logs (logTypeID, logServiceID, logLevelID, description, postTime, computer, userID, checksum)
        VALUES (
            vLogTypeID,
            vLogServiceID,
            vLogLevelErrorID,
            CONCAT('Current price not found: ProductID=', vProductID),
            vNow,
            vComputer,
            pUserID,
            SHA2(CONCAT_WS('|', 'ERROR', vNow, vProductID), 256)
        );
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Current price not found';
    END IF;

    SELECT c.clientID
    INTO vClientID
    FROM mk_clients c
    WHERE c.clientCode = pClientCode
    LIMIT 1;

    IF vClientID IS NULL THEN
        INSERT INTO mk_logs (logTypeID, logServiceID, logLevelID, description, postTime, computer, userID, checksum)
        VALUES (
            vLogTypeID,
            vLogServiceID,
            vLogLevelErrorID,
            CONCAT('Client not found: ClientCode=', pClientCode),
            vNow,
            vComputer,
            pUserID,
            SHA2(CONCAT_WS('|', 'ERROR', vNow, pClientCode), 256)
        );
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Client not found';
    END IF;

    SELECT paymentID
    INTO vPaymentID
    FROM mk_payments
    WHERE paymentConfirmation = pPaymentConfirmations
    LIMIT 1;

    IF vPaymentID IS NULL THEN
        INSERT INTO mk_payments (paymentMethodName, paymentConfirmation)
        VALUES (pPaymentMethod, pPaymentConfirmations);
        SET vPaymentID = LAST_INSERT_ID();
    END IF;

    IF vPaymentID IS NULL THEN
        INSERT INTO mk_logs (logTypeID, logServiceID, logLevelID, description, postTime, computer, userID, checksum)
        VALUES (
            vLogTypeID,
            vLogServiceID,
            vLogLevelErrorID,
            CONCAT('Failed to create or find payment with confirmations=', pPaymentConfirmations),
            vNow,
            vComputer,
            pUserID,
            SHA2(CONCAT_WS('|', 'ERROR', vNow, pPaymentConfirmations), 256)
        );
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Failed to create or find payment';
    END IF;

    SET vSubTotal = vUnitPrice * pQtySold;
    SET vTaxApplied = 1;
    SET vTaxAmount = ROUND(vSubTotal * CAST(0.13 AS DECIMAL(5,4)), 2);
    SET vTotal = ROUND(vSubTotal + vTaxAmount - pDiscountApplied, 2);

    IF vTotal < 0 THEN
        INSERT INTO mk_logs (logTypeID, logServiceID, logLevelID, description, postTime, computer, userID, checksum)
        VALUES (
            vLogTypeID,
            vLogServiceID,
            vLogLevelErrorID,
            CONCAT('Invalid total amount calculated: Total=', vTotal),
            vNow,
            vComputer,
            pUserID,
            SHA2(CONCAT_WS('|', 'ERROR', vNow, vTotal), 256)
        );
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid total amount calculated';
    END IF;

    SET vReceiptChecksum = UNHEX(SHA2(CONCAT_WS('|',
        'R', vKioskID, vClientID, vPaymentID, pInvoiceNumber,
        pDiscountApplied, vTaxApplied, vTaxAmount, vTotal, vComputer, vNow
    ), 256));

    INSERT INTO mk_receipts (
        kioskID, clientID, paymentID, receiptNumber, discount,
        taxApplied, taxAmount, total, checksum, postTime
    ) VALUES (
        vKioskID, vClientID, vPaymentID, pInvoiceNumber, pDiscountApplied,
        vTaxApplied, vTaxAmount, vTotal, vReceiptChecksum, vNow
    );

    SET vReceiptID = LAST_INSERT_ID();

    SET vDetailChecksum = UNHEX(SHA2(CONCAT_WS('|',
        'D', vProductID, vProductPriceID, pQtySold, vUnitPrice,
        vSubTotal, vComputer, vNow
    ), 256));

    INSERT INTO mk_receiptDetails (
        receiptID, productPriceID, productAmount, subTotal, checksum
    ) VALUES (
        vReceiptID, vProductPriceID, pQtySold, vSubTotal, vDetailChecksum
    );

    UPDATE mk_inventory
    SET qty_on_hand = qty_on_hand - pQtySold,
        updatedAt = vNow
    WHERE productID = vProductID
      AND kioskID = vKioskID;

    SET vTxChecksum = UNHEX(SHA2(CONCAT_WS('|', 'T',
        vReceiptChecksum, vDetailChecksum, vComputer, vNow, pUserID, vTxTypeID
    ), 256));

    INSERT INTO mk_transactions (
        amount, transactionDate, transactionDescription, checksum,
        referenceID, transactionStatus, transactionTypeID, userID
    ) VALUES (
        vTotal, vNow,
        CONCAT('Invoice# ', pInvoiceNumber, ' | refs: ', IFNULL(pReferenceNumbers, '')),
        vTxChecksum, vReceiptID,
        'CAPTURED',
        vTxTypeID,
        pUserID
    );

    INSERT INTO mk_logs (
        description, refID, value, checksum, computer,
        logTypeID, logServiceID, logLevelID, oldRow, newRow, actionType, postTime, userID
    ) VALUES (
        CONCAT('registerSale OK - invoice #', pInvoiceNumber),
        vReceiptID,
        CONCAT_WS('|', 'kiosk', pLocalName, 'product', pProductName, 'qty', pQtySold, 'total', vTotal),
        SHA2(CONCAT_WS('|', 'INFO', vNow, pInvoiceNumber, vReceiptID), 256),
        vComputer,
        vLogTypeID, vLogServiceID, vLogLevelID, NULL, NULL, 'INSERT', vNow, pUserID
    );

    COMMIT;
END //
DELIMITER ;
