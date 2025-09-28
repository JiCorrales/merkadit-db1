import type { RegisterSaleResponse } from "../services/saleService";
import {registerSale as registerSaleService} from "../services/saleService";

/**
 * The function `registerSale` exports an asynchronous function that calls `registerSaleService` with a
 * payload and returns a `Promise` of `RegisterSaleResponse`.
 * @param {unknown} payload - The `payload` parameter in the `registerSale` function is of type
 * `unknown`, which means it can be any type of value. It is the data that will be passed to the
 * `registerSaleService` function when registering a sale.
 */

export const registerSale = async (payload: unknown): Promise<RegisterSaleResponse> => 
    registerSaleService(payload)