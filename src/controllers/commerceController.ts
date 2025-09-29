import type { SettleCommerceResponse } from "../services/commerceService";
import {settleCommerce as settleCommerceService} from "../services/commerceService";

/**
 * The function `settleCommerce` exports an asynchronous function that calls `settleCommerceService` with a
 * payload and returns a `Promise` of `SettleCommerceResponse`.
 * @param {unknown} payload - The `payload` parameter in the `settleCommerce` function is of type
 * `unknown`, which means it can be any type of value. It is the data that will be passed to the
 * `settleCommerceService` function when processing commerce settlement.
 */

export const settleCommerce = async (payload: unknown): Promise<SettleCommerceResponse> => 
    settleCommerceService(payload)