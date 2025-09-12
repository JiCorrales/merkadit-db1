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
- **/postman** → Colección de pruebas de Postman para validar los endpoints.  
- **README.md** → Este archivo con instrucciones.  

---

## ⚙️ Requisitos
- **MySQL** 8.x  
- **Node.js + Express** (o la tecnología elegida: Flask, FastAPI, Spring Boot, .NET Core)  
- **Postman** (para pruebas de la API)  

---
