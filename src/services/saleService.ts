import { z } from "zod";

import {
    registerSale as registerSaleRepository,
    RegisterSaleParams,
    RegisterSaleResult
} from "../repositories/saleRepository";
import { getSalePricing } from "../repositories/pricingRepository";

const TAX_RATE = 0.13;

const registerSaleSchema = z.object({
    productName: z.string().trim().min(1).max(20),
    localName: z.string().trim().min(1).max(20),
    qtySold: z.coerce.number().int().positive(),
    amountPaid: z.coerce.number().min(0),
    paymentMethod: z.string().trim().min(1).max(100),
    paymentConfirmations: z.string().trim().min(1).max(255),
    referenceNumbers: z.string().trim().max(255).nullish(),
    invoiceNumber: z.coerce.number().int().positive(),
    clientCode: z.string().trim().min(1).max(50),
    discountApplied: z.coerce.number().min(0),
    userId: z.coerce.number().int().positive()
});

const toMoney = (value: number): number => Math.round(value * 100) / 100;

export class SaleValidationError extends Error {
    constructor(message: string) {
        super(message);
        this.name = "SaleValidationError";
    }
}

export type RegisterSaleInput = z.infer<typeof registerSaleSchema>;
export type RegisterSaleResponse = RegisterSaleResult & {
    message: string
    amountPaid: number
    change: number
    unitPrice?: number
    subTotal?: number
    taxAmount?: number
    discountApplied?: number
    expectedTotal?: number
};

/**
 * The function `registerSale` processes a sale transaction, calculates pricing, validates the
 * transaction, and registers the sale in a repository.
 * @param {unknown} payload - The `registerSale` function is responsible for registering a sale based
 * on the provided payload. The payload contains information about the sale such as product name,
 * quantity sold, amount paid, payment method, discount applied, and other relevant details.
 * @returns The function `registerSale` is returning a `RegisterSaleResponse` object. This object
 * contains the following properties:
 * - `message`: A string indicating that the sale was registered successfully.
 * - `...result`: Spread operator to include all properties from the `result` object returned by the
 * `registerSaleRepository` function.
 * - `amountPaid`: The amount paid in the sale, converted to a formatted
 */
export const registerSale = async (payload: unknown): Promise<RegisterSaleResponse> => {
    const data = registerSaleSchema.parse(payload)

    const pricing = await getSalePricing(data.localName, data.productName)
    let calculation: {
        unitPrice: number
        subTotal: number
        taxAmount: number
        expectedTotal: number
    } | null = null

    if (pricing) {
        const subTotal = pricing.unitPrice * data.qtySold
        const discountedTotal = subTotal - data.discountApplied
        const taxAmount = discountedTotal * TAX_RATE
        const expectedTotal = discountedTotal + taxAmount

        if (expectedTotal < 0) {
            throw new SaleValidationError("Calculated total is negative; review the discount applied.")
        }

        if (data.amountPaid < expectedTotal) {
            throw new SaleValidationError(`Amount paid (${data.amountPaid}) is insufficient. Expected at least ${expectedTotal}.`)
        }

        calculation = {
            unitPrice: pricing.unitPrice,
            subTotal,
            taxAmount,
            expectedTotal
        }
    }

    const repositoryParams: RegisterSaleParams = {
        productName: data.productName,
        localName: data.localName,
        qtySold: data.qtySold,
        amountPaid: data.amountPaid,
        paymentMethod: data.paymentMethod,
        paymentConfirmations: data.paymentConfirmations,
        referenceNumbers: data.referenceNumbers && data.referenceNumbers.length > 0 ? data.referenceNumbers : null,
        invoiceNumber: data.invoiceNumber,
        clientCode: data.clientCode,
        discountApplied: data.discountApplied,
        userId: data.userId
    }

    const result = await registerSaleRepository(repositoryParams)

    const response: RegisterSaleResponse = {
        message: "Sale registered successfully",
        ...result,
        amountPaid: toMoney(data.amountPaid),
        change: toMoney(data.amountPaid - result.total)
    }

    if (calculation) {
        response.unitPrice = calculation.unitPrice
        response.subTotal = calculation.subTotal
        response.taxAmount = calculation.taxAmount
        response.discountApplied = data.discountApplied
        response.expectedTotal = calculation.expectedTotal
    }

    return response
}

