import type { Request, Response } from "express";
import * as commerceController from "../controllers/commerceController";
import { ZodError } from "zod";

/**
 * The function `settleCommerceHandler` handles commerce settlement and returns appropriate responses
 * based on different error scenarios.
 * @param {Request} req - The `req` parameter in the `settleCommerceHandler` function is of type
 * `Request`, which typically represents the HTTP request in Express.js or similar frameworks. It
 * contains information about the incoming request such as headers, parameters, body, etc.
 * @param {Response} res - The `res` parameter in the `settleCommerceHandler` function is an object
 * representing the HTTP response that the server sends back to the client. It allows you to send data
 * back to the client, set status codes, and more.
 * @returns The `settleCommerceHandler` function is returning a response based on the outcome of
 * commerce settlement. If the settlement is successful, it returns a status of 200 (OK)
 * along with the result in JSON format. If an error occurs during the settlement process, it handles
 * different types of errors appropriately.
 */
export const settleCommerceHandler = async (req: Request, res: Response)  => {
    try {
        const result = await commerceController.settleCommerce(req.body);
        res.status(200).json(result)
    } catch (error: any) {
        if (error instanceof ZodError) return res.status(400).json({ message: error.message, errors: error.issues })
        if (error.http) return res.status(error.http.status).json({ message: error.message, code: error.code})
        
        // MySQL SIGNNAL '45000' error
        if (error?.sqlState === "45000" || error?.errno === 1644) {
            return res.status(400).json({ message: error.sqlMessage || "Database validation error" })
        }

        console.error(error);
        res.status(500).json({ message: "Unexpected server error" });
    }
}