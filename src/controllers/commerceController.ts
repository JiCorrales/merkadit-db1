import type { SettleCommerceResponse } from "../services/commerceService";
import {settleCommerce as settleCommerceService} from "../services/commerceService";



/**
 * This TypeScript function `settleCommerce` calls the `settleCommerceService` function with a payload
 * and returns a `Promise` of `SettleCommerceResponse`.
 * @param {unknown} payload - The `payload` parameter is of type `unknown`, which means it can hold any
 * type of value. It is the data that will be passed to the `settleCommerce` function for processing.
 */
export const settleCommerce = async (payload: unknown): Promise<SettleCommerceResponse> => 
    settleCommerceService(payload)