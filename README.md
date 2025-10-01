# 🏪 Merkadit – Caso #1 (Bases de Datos 1)

Repositorio del proyecto **Merkadit**, desarrollado como parte del curso **Bases de Datos 1 (TEC)**.  
Este sistema busca optimizar la administración de mercados gastronómicos y minoristas, integrando tanto la gestión financiera del administrador como un módulo **POS** para los inquilinos.

---

## 📌 Descripción del Proyecto
**Merkadit** permite:
- Registrar y administrar espacios físicos (locales, kioscos, tiendas).
- Configurar contratos de arrendamiento con renta fija y comisión sobre ventas.
- Controlar la inversión inicial y gastos operativos.
- Proporcionar reportes financieros al administrador.
- Ofrecer un módulo POS para que los inquilinos gestionen inventario y ventas.
- Calcular automáticamente rentas + comisiones y generar reportes consolidados.

---

## 📂 Contenido del Repositorio
- **/diagrams** → Diagrama Entidad-Relación (ERD) y esquema relacional en PDF.  
- **/scripts** → Scripts SQL para:
  - Creación de la base de datos y tablas.
  - Inserción de datos de ejemplo.
  - Procedimientos almacenados (`registerSale`, `settleCommerce`).
  - Creación de vistas para reportes.
- **/api** → Código fuente de la API REST (arquitectura en 4 capas).  
- **/postman_tests** → Colección de pruebas de Postman para validar los endpoints.  
- **README.md** → Este archivo con instrucciones.  

---

## ⚙️ Requisitos
- **MySQL** 8.x  
- **Node.js + Express** (o la tecnología elegida: Flask, FastAPI, Spring Boot, .NET Core)  
- **Postman** (para pruebas de la API)  

---

## 📄 Especificación del Proyecto (Permalink)

La especificación oficial del **Caso #1 – Merkadit** se encuentra en el siguiente permalink:  

👉 [Ver especificación en GitHub](https://github.com/vsurak/cursostec/blob/abbee4d51385a925771acdd6c8ac0b2c17e498b5/bases%20I/Caso%20%231.md)

---

📚 Disponible en otros idiomas:  
- [English](./README.en.md)  
- [Deutsch](./README.de.md) 

---

## Sales Report

En orden para poder correr el reporte y que nos genere un resultado, primero debemos asegurarnos de correr el llenado de la base de datos [fill_2.0.sql](https://github.com/JiCorrales/merkadit-db1/tree/main/scripts/FillData) al contrario la base no tendra nada que retornar a la hora de llamar el vw_salesReport.

Si desea agregar mas datos para ver como cambia el reporte lo puede hacer mediante el SP [registerSale](https://github.com/JiCorrales/merkadit-db1/tree/main/scripts/storedProcedures) en MySql o en postman, de querer hacerlo en postman es necesario iniciar el API con el nmp dev run estando en la carpeta principal.

👉 [Puede encontrar el reporte en](https://github.com/JiCorrales/merkadit-db1/tree/main/scripts)
```SQL
CREATE VIEW vw_salesReport AS	
    SELECT
        t.tenantName AS "Nombre Tienda",
        t.tenantLegalName AS "Nombre Negocio",
        b.buildingName AS Edificio,
        MIN(r.postTime) AS "Fecha primer compra",
        MAX(r.postTime) AS "Fecha ultima compra",
        SUM(rd.productAmount) AS "Productos comprados",
        
        -- Cálculos financieros paso a paso
        SUM(rd.subTotal) AS "Subtotal Ventas",
        SUM(r.discount) AS "Total Descuentos",
        (SUM(rd.subTotal) - SUM(r.discount)) AS "Subtotal Neto",
        SUM(r.taxAmount) AS "Total Impuestos",
        (SUM(rd.subTotal) - SUM(r.discount)) +  SUM(r.taxAmount) AS "Total en ventas",
        c.feeOnSales AS "Porcentaje de comision",
        SUM(r.total) * c.feeOnSales AS "Comision acordada",
        c.rent AS "Renta",
        SUM(r.total) - (SUM(r.total) * c.feeOnSales) AS Ingresos
	
        
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
    LEFT JOIN mk_receipts r ON k.kioskID = r.kioskID
        AND MONTH(r.postTime) = MONTH(CURRENT_DATE())
        AND YEAR(r.postTime) = YEAR(CURRENT_DATE())
    -- Detalles de recibos
    LEFT JOIN mk_receiptDetails rd ON r.receiptID = rd.receiptID
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
    
    
    SELECT * FROM vw_salesReport;

```

Si utilizamos un SELECT para llamar el view se nos mostrara el resultado de este el cual es el siguiente.

# Reporte de Ventas 

| Nombre Tienda | Nombre Negocio | Edificio | Fecha primer compra | Fecha ultima compra | Productos comprados | Total en ventas | Porcentaje de comision | Comision acordada | Renta | Ingresos |
|---------------|----------------|----------|---------------------|---------------------|---------------------|-----------------|------------------------|------------------|-------|----------|
| Tecnologia Avanzada | Tecnologia Avanzada S.R.L. | Plaza Heredia | - | - | - | - | 0.045 | - | 645.00 | - |
| Sabores del Valle | Sabores del Valle S.A. | Mercado Aurora | - | - | - | - | 0.05 | - | 540.00 | - |
| Sabores del Mercado | Sabores del Mercado S.A. | Mercado Aurora | 2025-10-01 01:48:19 | 2025-10-31 08:00:10 | 32 | 416.64 | 0.055 | 22.92 | 595.00 | 393.72 |
| Productos Frescos | Productos Frescos Limitada | Plaza Heredia | - | - | - | - | 0.06 | - | 555.00 | - |
| Pan y Miel | Pan y Miel S.A. | Mercado Aurora | - | - | - | - | 0.045 | - | 615.00 | - |
| Luna Clara Hogar | Luna Clara Hogar S.R.L. | Mercado Aurora | - | - | - | - | 0.06 | - | 590.00 | - |
| Dulces Heredianos | Dulces Heredianos S.R.L. | Plaza Heredia | - | - | - | - | 0.045 | - | 480.00 | - |
| Decoracion Sofisticada | Decoracion Sofisticada S.A. | Plaza Heredia | - | - | - | - | 0.05 | - | 670.00 | - |
| Casa Achiote | Casa Achiote Limitada | Mercado Aurora | - | - | - | - | 0.055 | - | 565.00 | - |
| Cafe Siete Esquinas | Cafe Siete Esquinas S.R.L. | Galeria Calderon | 2025-10-01 08:00:15 | 2025-10-31 08:00:10 | 29 | 270.42 | 0.05 | 13.52 | 705.00 | 256.90 |
| Cafe de Altura | Cafe de Altura S.A. | Plaza Heredia | - | - | - | - | 0.055 | - | 530.00 | - |
| Boutique Elegante | Boutique Elegante S.A. | Plaza Heredia | - | - | - | - | 0.065 | - | 620.00 | - |
| Bebidas Tropicales | Bebidas Tropicales S.A. | Mercado Aurora | - | - | - | - | 0.065 | - | 615.00 | - |
| Artesania Local | Artesania Local Artesanos | Plaza Heredia | - | - | - | - | 0.05 | - | 505.00 | - |