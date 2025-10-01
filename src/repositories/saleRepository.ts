/**
 * @file  saleRepository.ts
 * Repository Layer (Data Access):
 * @purpose This is the layer responsible for all direct communication with the database.
 * @Responsibilities t executes SQL queries, calls stored procedures, and maps raw database data 
 * into application objects. It should be the only layer that knows about the database schema and technology.
 */

import type { PoolConnection, RowDataPacket } from "mysql2/promise";

import pool from "../config/db";

/**
 * The type `RegisterSaleParams` defines the parameters required to register a sale transaction.
 * @property {string} productName - The `productName` property in the `RegisterSaleParams` type
 * represents the name of the product being sold.
 * @property {string} localName - The `localName` property in the `RegisterSaleParams` type represents
 * the name of the local store or location where the sale took place.
 * @property {number} qtySold - The `qtySold` property in the `RegisterSaleParams` type represents the
 * quantity of the product that was sold in the sale transaction. It is of type `number`, indicating a
 * numerical value.
 * @property {number} amountPaid - The `amountPaid` property in the `RegisterSaleParams` type
 * represents the total amount paid by the customer for the sale transaction. It is of type `number`,
 * indicating a numerical value.
 * @property {string} paymentMethod - The `paymentMethod` property in the `RegisterSaleParams` type
 * represents the method used for payment during a sale transaction. This could be a string value
 * indicating the payment method chosen by the customer, such as "credit card", "cash", "debit card",
 * "online payment", etc.
 * @property {string} paymentConfirmations - The `paymentConfirmations` property in the
 * `RegisterSaleParams` type represents the confirmation details related to the payment for the sale.
 * It could include information such as transaction IDs, confirmation numbers, or any other relevant
 * details confirming the payment for the sale transaction.
 * @property {string | null} referenceNumbers - The `referenceNumbers` property in the
 * `RegisterSaleParams` type is a string or null type. This means that it can either hold a string
 * value or a null value. It is used to store any reference numbers related to the sale transaction,
 * such as order numbers, tracking numbers, or any
 * @property {number} invoiceNumber - The `invoiceNumber` property in the `RegisterSaleParams` type
 * represents the unique number assigned to the invoice for the sale transaction. It is a numerical
 * value.
 * @property {string} clientCode - The `clientCode` property in the `RegisterSaleParams` type
 * represents the unique code or identifier assigned to the client making the purchase. This code is
 * used to identify and track the client's transactions and interactions with the system.
 * @property {number} discountApplied - The `discountApplied` property in the `RegisterSaleParams`
 * type represents the amount of discount applied to the sale. It is a number type indicating the
 * discount amount in the sale transaction.
 * @property {number} userId - The `userId` property in the `RegisterSaleParams` type represents the
 * unique identifier of the user who is making the sale transaction. It is of type `number` in the
 * interface.
 */
export type RegisterSaleParams = {
    productName: string
    localName: string
    qtySold: number
    amountPaid: number
    paymentMethod: string
    paymentConfirmations: string
    referenceNumbers: string | null
    invoiceNumber: number
    clientCode: string
    discountApplied: number
    userId: number
}

/**
 * The `RegisterSaleResult` type in TypeScript represents the result of registering a sale with
 * properties for receipt ID, invoice number, and total amount.
 * @property {number} receiptId - The `receiptId` property in the `RegisterSaleResult` type represents
 * the unique identifier for the receipt generated for the sale transaction.
 * @property {number} invoiceNumber - The `invoiceNumber` property in the `RegisterSaleResult` type
 * represents the unique number assigned to the invoice generated for the sale transaction.
 * @property {number} total - The `total` property in the `RegisterSaleResult` type represents the
 * total amount of the sale transaction. It typically includes the sum of all items purchased, any
 * applicable taxes, and any discounts applied.
 */
export type RegisterSaleResult = {
    receiptId: number
    invoiceNumber: number
    total: number
}

/* The `receiptLookupQuery` constant in the code snippet is defining a SQL query string that is used to
retrieve specific details of a receipt from the database. Here's a breakdown of what the query is
doing: */
const receiptLookupQuery = [
    "SELECT",
    "    r.receiptID AS receiptId,",
    "    r.receiptNumber AS invoiceNumber,",
    "    r.total AS total",
    "FROM mk_receipts r",
    "    INNER JOIN mk_kiosks k ON k.kioskID = r.kioskID",,
    "WHERE r.receiptNumber = ?",
    "  AND k.kioskName = ?",
    "ORDER BY r.postTime DESC",
    "LIMIT 1;"
].join("\n")

/**
 * The function `callRegisterSale` asynchronously calls a stored procedure `registerSale` with the
 * provided parameters using a database connection.
 * @param {PoolConnection} connection - The `connection` parameter is of type `PoolConnection`, which
 * is likely a connection object used to interact with a database pool. It is used to execute the query
 * to register a sale in the database.
 * @param {RegisterSaleParams} params - - productName: string
 */
const callRegisterSale = async (connection: PoolConnection, params: RegisterSaleParams): Promise<void> => {
    const args = [
        params.productName,
        params.localName,
        params.qtySold,
        params.amountPaid,
        params.paymentMethod,
        params.paymentConfirmations,
        params.referenceNumbers,
        params.invoiceNumber,
        params.clientCode,
        params.discountApplied,
        params.userId
    ]

    await connection.query("CALL registerSale(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", args)
}
/**
 * The function `registerSale` registers a sale, retrieves the receipt, and returns the receipt
 * details.
 * @param {RegisterSaleParams} params - The `params` object in the `registerSale` function likely
 * contains information related to a sale transaction. It seems to include properties such as
 * `invoiceNumber` and `localName`. These parameters are used to register a sale, retrieve the
 * corresponding receipt, and return specific details from the receipt like `
 * @returns The `registerSale` function returns a `Promise` that resolves to a `RegisterSaleResult`
 * object. The `RegisterSaleResult` object contains the `receiptId`, `invoiceNumber`, and `total`
 * properties extracted from the retrieved receipt after registering a sale.
 */

export const registerSale = async (params: RegisterSaleParams): Promise<RegisterSaleResult> => {
    const connection = await pool.getConnection()
    try {
        await callRegisterSale(connection, params)

        const [rows] = await connection.query<RowDataPacket[]>(
            receiptLookupQuery,
            [params.invoiceNumber, params.localName]
        )

        const receipt = rows[0]
        if (!receipt) {
            throw new Error("Failed to retrieve receipt after registering sale")
        }

        return {
            receiptId: Number(receipt.receiptId),
            invoiceNumber: Number(receipt.invoiceNumber),
            total: Number(receipt.total)
        }
    } finally {
        connection.release()
    }
}
