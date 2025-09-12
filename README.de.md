# 🏪 Merkadit – Fall #1 (Datenbanken 1)

Repository des Projekts **Merkadit**, entwickelt im Rahmen des Kurses **Datenbanken 1 (TEC)**.  
Dieses System zielt darauf ab, die Verwaltung von gastronomischen und Einzelhandelsmärkten zu optimieren und kombiniert sowohl die Finanzverwaltung des Administrators als auch ein **POS-Modul** für die Mieter.

---

## 📌 Projektbeschreibung
**Merkadit** ermöglicht:
- Registrierung und Verwaltung von physischen Flächen (Läden, Kioske, Geschäfte).
- Konfiguration von Mietverträgen mit fixer Miete und umsatzbasierter Provision.
- Kontrolle der Anfangsinvestition und Betriebskosten.
- Bereitstellung von Finanzberichten für den Administrator.
- Bereitstellung eines POS-Moduls für Mieter zur Verwaltung von Inventar und Verkäufen.
- Automatische Berechnung von Miete + Provisionen und Erstellung konsolidierter Berichte.

---

## 📂 Repository-Inhalt
- **/diagrams** → Entity-Relationship-Diagramm (ERD) und relationales Schema im PDF.  
- **/scripts** → SQL-Skripte für:
  - Erstellung der Datenbank und Tabellen.
  - Einfügen von Beispieldaten.
  - Stored Procedures (`registerSale`, `settleCommerce`).
  - Erstellung von Views für Berichte.
- **/api** → Quellcode der REST-API (4-Schichten-Architektur).  
- **/postman_tests** → Postman-Testkollektion zur Validierung der Endpunkte.  
- **README.md** → Hauptdatei mit Anweisungen.  

---

## ⚙️ Anforderungen
- **MySQL** 8.x  
- **Node.js + Express** (oder gewählte Technologie: Flask, FastAPI, Spring Boot, .NET Core)  
- **Postman** (für API-Tests)  

---

## 📄 Projektspezifikation (Permalink)

Die offizielle Spezifikation von **Fall #1 – Merkadit** ist unter folgendem Permalink verfügbar:  

👉 [Spezifikation auf GitHub anzeigen](https://github.com/vsurak/cursostec/blob/abbee4d51385a925771acdd6c8ac0b2c17e498b5/bases%20I/Caso%20%231.md)

---

📚 Verfügbar in anderen Sprachen:  
- [Español](./README.md)  
- [English](./README.en.md)  
