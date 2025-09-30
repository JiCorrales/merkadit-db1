import type { RowDataPacket } from "mysql2/promise";

import pool from "../config/db";

/**
 * The SalePricing type defines the pricing details for a product sale including local and kiosk IDs,
 * product ID, price ID, and unit price.
 * @property {number} localId - The `localId` property in the `SalePricing` type represents the unique
 * identifier for a specific sale pricing entry.
 * @property {number} kioskId - The `kioskId` property in the `SalePricing` type represents the unique
 * identifier of the kiosk where the sale pricing information is associated. It is a number type in the
 * `SalePricing` type definition.
 * @property {number} productId - The `productId` property in the `SalePricing` type represents the
 * unique identifier of the product being sold. It is a number type within the `SalePricing` type
 * definition.
 * @property {number} productPriceId - The `productPriceId` property in the `SalePricing` type
 * represents the unique identifier for the price of a specific product. It is used to identify the
 * pricing information associated with a particular product in a sales transaction.
 * @property {number} unitPrice - The `unitPrice` property in the `SalePricing` type represents the
 * price of a single unit of a product being sold.
 */
export type SalePricing = {
    localId: number;
    kioskId: number;
    productId: number;
    productPriceId: number;
    unitPrice: number;
}

/* The `pricingLookupQuery` constant in the TypeScript code snippet is a SQL query string that is used
to retrieve sale pricing information based on specific criteria. Here's a breakdown of what the
query is doing: */
const pricingLookupQuery = [
    "SELECT",
    "    l.localID AS localId,",
    "    k.kioskID AS kioskId,",
    "    p.productID AS productId,",
    "    pp.productPriceID AS productPriceId,",
    "    pp.price AS unitPrice",
    "FROM mk_locals l",
    "    INNER JOIN mk_kiosks k ON k.localID = l.localID",
    "    INNER JOIN mk_products p ON p.kioskID = k.kioskID",
    "    INNER JOIN mk_productPrices pp ON pp.productID = p.productID",
    "WHERE l.localName = ?",
    "  AND p.name = ?",
    "  AND pp.currentPrice = 1",
    "ORDER BY pp.postTime DESC, pp.productPriceID DESC",
    "LIMIT 1;"
].join("\n")


/**
 * The function `getSalePricing` retrieves sale pricing information for a specific product at a given
 * location.
 * @param {string} localName - The `localName` parameter is a string that represents the name of the
 * local store where the product is being sold.
 * @param {string} productName - The `productName` parameter in the `getSalePricing` function is a
 * string that represents the name of the product for which you want to retrieve the sale pricing
 * information. It is used as a filter criteria to look up the pricing details for a specific product.
 * @returns The `getSalePricing` function returns a `Promise` that resolves to a `SalePricing` object
 * or `null`. The `SalePricing` object contains properties such as `localId`, `kioskId`, `productId`,
 * `productPriceId`, and `unitPrice`, all of which are numbers. If the pricing information is not found
 * in the database, the function returns
 */
export const getSalePricing = async (localName: string, productName: string): Promise<SalePricing | null> => {
    const [rows] = await pool.query<RowDataPacket[]>(pricingLookupQuery, [localName, productName]);
    const pricing = rows[0];
    if (!pricing) {
        return null
    }

    return {
        localId: Number(pricing.localId),
        kioskId: Number(pricing.kioskId),
        productId: Number(pricing.productId),
        productPriceId: Number(pricing.productPriceId),
        unitPrice: Number(pricing.unitPrice)
    }
}
/**
 * The function `getUnitPrice` retrieves the unit price of a product for a specific location
 * asynchronously.
 * @param {string} localName - The `localName` parameter in the `getUnitPrice` function represents the
 * location or store where the product is being sold. It is a string value that specifies the name of
 * the local store.
 * @param {string} productName - The `productName` parameter in the `getUnitPrice` function is a string
 * that represents the name of the product for which you want to retrieve the unit price.
 * @returns The `getUnitPrice` function is returning the unit price of a product for a specific
 * location. It first calls the `getSalePricing` function to retrieve pricing information for the given
 * `localName` and `productName`. If pricing information is available, it returns the `unitPrice` from
 * the pricing object. If pricing information is not available, it returns `null`.
 */


export const getUnitPrice = async (localName: string, productName: string): Promise<number | null> => {
    const pricing = await getSalePricing(localName, productName)
    return pricing ? pricing.unitPrice : null
}
