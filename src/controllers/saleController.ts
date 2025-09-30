/**
 * @file saleController.ts
 * Controller Layer (Business Logic Orchestration):
 * @purpose This layer contains the core application logic and acts as a coordinator.
 * @Responsibilities It processes the data received from the handler, makes decisions, validates
 * business rules, and calls the appropriate methods in the service layer. It should not contain 
 * direct data access code.
 */


import type { RegisterSaleResponse } from "../services/saleService";
import {registerSale as registerSaleService} from "../services/saleService";


/**
 * The function `registerSale` in TypeScript exports an asynchronous function that calls
 * `registerSaleService` with a payload and returns a `Promise` of `RegisterSaleResponse`.
 * @param {unknown} payload - The `payload` parameter in the `registerSale` function is of type
 * `unknown`, which means it can be any type of value. It is the data that will be passed to the
 * `registerSaleService` function when registering a sale.
 */

export const registerSale = async (payload: unknown): Promise<RegisterSaleResponse> => 
    registerSaleService(payload)