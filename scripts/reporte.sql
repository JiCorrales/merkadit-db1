SELECT
    t.tenantName AS "Nombre Tienda",
    t.tenantLegalName AS "Nombre Negocio",
    b.buildingName AS Edificio,
    MIN(r.postTime) AS "Fecha primer compra",
    MAX(r.postTime) AS "Fecha ultima compra",
    SUM(rd.productAmount) AS "Productos comprados",
    SUM(r.total) AS "Total en ventas",
    c.feeOnSales AS "Porcentaje de comision",
    SUM(r.total) * (c.feeOnSales / 100) AS "Comision acordada",
    c.rent AS "Renta"
FROM mk_tenant t 
-- Tenant y contratos
JOIN mk_tenantPerContracts tpc ON t.tenantID = tpc.tenantID
JOIN mk_contracts c ON tpc.contractID = c.contractID
-- Contratos y kioskos
JOIN mk_contractsPerKiosks cpk ON c.contractID = cpk.contractID
-- Kioskos
JOIN mk_kiosks k ON cpk.kioskID = k.kioskID
-- Kioskos y edificios (a través de floors)
JOIN mk_kiosksPerFloors kpf ON k.kioskID = kpf.kioskID
JOIN mk_floors f ON kpf.floorID = f.floorID
JOIN mk_building b ON f.buildingID = b.buildingID
-- Recibos
JOIN mk_receipts r ON k.kioskID = r.kioskID
    AND MONTH(r.postTime) = MONTH(CURRENT_DATE())
    AND YEAR(r.postTime) = YEAR(CURRENT_DATE())
-- Detalles de recibos
JOIN mk_receiptDetails rd ON r.receiptID = rd.receiptID
WHERE tpc.deleted = 0 
    AND c.expirationDate >= CURRENT_DATE()
    AND cpk.deleted = 0
    AND kpf.deleted = 0
GROUP BY
    t.tenantID,
    t.tenantName,
    t.tenantLegalName,
    b.buildingName,
    c.feeOnSales,
    c.rent
ORDER BY t.tenantName;