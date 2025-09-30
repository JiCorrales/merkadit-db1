import type { PoolConnection, ResultSetHeader, RowDataPacket } from "mysql2/promise";

import pool from "../config/db";

/**
 * The SettleCommerceParams type defines the parameters required to settle a commerce transaction.
 * @property {string} comercioNombre - The property `comercioNombre` represents the name of the
 * commerce or business. It is a string type.
 * @property {string} localNombre - The `localNombre` property in the `SettleCommerceParams` type
 * represents the name of a local business or store associated with a commerce transaction. It is a
 * string type field where you would typically provide the name of the specific location or branch of
 * the commerce entity involved in the transaction.
 * @property {number} usuarioId - The `usuarioId` property in the `SettleCommerceParams` type
 * represents the ID of the user associated with the commerce settlement. It is of type `number`,
 * indicating that it should be a numeric value.
 * @property {string} computadora - The property "computadora" in the SettleCommerceParams type
 * represents the name or identifier of the computer involved in the commerce settlement process. It is
 * likely used to track or identify the specific computer used for the transaction.
 */
export type SettleCommerceParams = {
    comercioNombre: string
    localNombre: string
    usuarioId: number
    computadora: string
}

/**
 * The SettleCommerceResult type defines the structure for a result of a commerce settlement operation.
 * @property {boolean} success - The `success` property in the `SettleCommerceResult` type indicates
 * whether the commerce settlement was successful or not. It is a boolean value, where `true` indicates
 * success and `false` indicates failure.
 * @property {string} message - The `message` property in the `SettleCommerceResult` type is a string
 * that typically contains a description or information related to the result of settling a commerce
 * transaction. It can be used to provide feedback or details about the outcome of the settlement
 * process.
 * @property {number} settlementId - The `settlementId` property in the `SettleCommerceResult` type
 * represents the unique identifier associated with a particular settlement transaction. It is used to
 * track and identify the specific settlement within the system.
 * @property {number} totalVentas - The `totalVentas` property in the `SettleCommerceResult` type
 * represents the total sales amount for a commerce transaction. It likely indicates the total amount
 * of sales made during a specific period or for a particular transaction.
 * @property {number} montoComision - The property "montoComision" represents the commission amount in
 * the SettleCommerceResult type. It likely refers to the amount of commission charged or earned in a
 * commerce transaction.
 * @property {number} montoTenant - The property "montoTenant" in the SettleCommerceResult type
 * represents the amount that is to be settled to the tenant or seller in a commerce transaction. It
 * likely indicates the total amount of money that the tenant or seller is entitled to receive after
 * deducting any applicable fees or commissions.
 */
export type SettleCommerceResult = {
    success: boolean
    message: string
    settlementId?: number
    totalVentas?: number
    montoComision?: number
    montoTenant?: number
}
// Define a union type for the possible results of a CALL statement
type RawCallResult = RowDataPacket[][] | RowDataPacket[] | ResultSetHeader;

/**
 * The function `normalizeResultSets` takes an input array of raw call results and returns an array of
 * row data packets.
 * @param {RawCallResult} rows - The `rows` parameter in the `normalizeResultSets` function is expected
 * to be of type `RawCallResult`, which is essentially an array of arrays of `RowDataPacket` objects.
 * The function checks if the input `rows` is an array, and if it is, it normalizes
 * @returns The `normalizeResultSets` function returns an array of `RowDataPacket` arrays. If the input
 * `rows` is not an array, an empty array is returned. If the input `rows` is an empty array or the
 * first element of `rows` is not an array, then `rows` is converted to a single-element array
 * containing `rows` casted as `RowDataPacket
 */
const normalizeResultSets = (rows: RawCallResult): RowDataPacket[][] => {
    if (!Array.isArray(rows)) {
        return [];
    }

    if (rows.length === 0) {
        return [];
    }

    if (Array.isArray(rows[0])) {
        return (rows as unknown as RowDataPacket[][]).filter((set) => Array.isArray(set));
    }

    return [rows as RowDataPacket[]];
};

/**
 * This TypeScript function calls a stored procedure named `settleCommerce` with specified parameters
 * and returns the normalized result sets.
 * @param {PoolConnection} connection - The `connection` parameter is of type `PoolConnection`, which
 * is likely a connection object used to interact with a database pool. It is used to execute the
 * stored procedure `settleCommerce` with the provided parameters.
 * @param {SettleCommerceParams} params - - comercioNombre: the name of the commerce
 * @returns The function `callSettleCommerce` is returning a Promise that resolves to an array of
 * `RowDataPacket[][]`.
 */
const callSettleCommerce = async (connection: PoolConnection, params: SettleCommerceParams): Promise<RowDataPacket[][]> => {
    const args = [
        params.comercioNombre,
        params.localNombre,
        params.usuarioId,
        params.computadora
    ]

    const [rows] = await connection.query<RawCallResult>("CALL settleCommerce(?, ?, ?, ?)", args);
    return normalizeResultSets(rows)
}
/**
 * The settleCommerceRepository function processes settlement data and returns a result object with
 * relevant information.
 * @param {SettleCommerceParams} params - The `params` object passed to the `settleCommerceRepository`
 * function likely contains information needed to settle a commerce transaction. This could include
 * details such as transaction IDs, amounts, dates, or any other relevant data required for settling
 * the commerce transaction.
 * @returns The `settleCommerceRepository` function returns a Promise that resolves to a
 * `SettleCommerceResult` object. This object contains the following properties:
 */

export const settleCommerceRepository = async (params: SettleCommerceParams): Promise<SettleCommerceResult> => {
    const connection = await pool.getConnection()
    try {
        const resultSets = await callSettleCommerce(connection, params)

        const primarySet = resultSets.find((set) => set.length > 0 && ("resultado" in (set[0] as RowDataPacket))) ?? resultSets[0];

        if (!primarySet || primarySet.length === 0) {
            return {
                success: false,
                message: "Settlement failed to produce a response"
            }
        }

        const row = primarySet[0] as RowDataPacket & {
            resultado?: string
            totalVentas?: number | string
            comisionPorcentaje?: number | string
            montoComision?: number | string
            montoTenant?: number | string
        }

        const message = typeof row.resultado === "string" ? row.resultado : "Settlement completed";
        const success = /settlement/i.test(message) && !/error/i.test(message)

        const toNumber = (value: unknown): number | undefined => {
            if (value === null || value === undefined) {
                return undefined;
            }
            const numeric = Number(value);
            return Number.isNaN(numeric) ? undefined : numeric;
        }

        return {
            success,
            message,
            totalVentas: toNumber(row.totalVentas),
            montoComision: toNumber(row.montoComision),
            montoTenant: toNumber(row.montoTenant)
        }
    } finally {
        connection.release();
    }
}
